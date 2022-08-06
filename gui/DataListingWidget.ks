@lazyGlobal off.
requireOnce("lib/test").

local SKIN_LABEL_KEY is "DataListingWidget/LabelKey".
local SKIN_LABEL_VALUE is "DataListingWidget/LabelValue".

function DataListingWidget {
    parameter box.
    parameter updateInterval is 0.5.

    if not box:gui:skin:has(SKIN_LABEL_KEY) {
        local style is box:gui:skin:add(SKIN_LABEL_KEY, box:gui:skin:label).
        set style:margin:v to 0.
        set style:padding:v to 0.
    }
    if not box:gui:skin:has(SKIN_LABEL_VALUE) {
        local style is box:gui:skin:add(SKIN_LABEL_VALUE, box:gui:skin:label).
        set style:margin:v to 0.
        set style:padding:v to 0.
        //set style:hStretch to true.
        set style:align to "right".
    }

    local self is lexicon().
    local vbox is box:addVBox().
    local entries is list().  // List of {key, value, keyLabel, valueLabel} lexicons. Value may be a primitive, or a delegate with zero arguments.

    local function set {
        parameter key.
        parameter value.

        for entry in entries {
            if entry:key = key {
                if entry:value <> value {
                    set entry:value to value.
                    if not value:isType("delegate") {
                        set entry:valueLabel:text to value.
                    }
                }
                return.
            }
        }
        local hbox is vbox:addHLayout().

        local keyLabel is hbox:addLabel("<b>" + key + "</b>").
        set keyLabel:style to box:gui:skin:get(SKIN_LABEL_KEY).

        local valueLabel is hbox:addLabel(
            choose value() if value:isType("delegate") else value
        ).
        set valueLabel:style to box:gui:skin:get(SKIN_LABEL_VALUE).

        entries:add(lexicon(
            "key", key,
            "value", value,
            "keyLabel", keyLabel,
            "valueLabel", valueLabel
        )).
    }
    self:add("set", set@).

    local function get {
        parameter name.

        for entry in entries {
            if entry:key = name {
                return entry:value.
            }
        }
    }
    self:add("get", get@).

    local function update {
        // Update labels whose values were provided as delegates.
        // Labels with static values are only updated in :set().
        for entry in entries {
            if entry:value:isType("delegate") {
                set entry:valueLabel:text to entry:value().
            }
        }
    }
    local nextUpdate is time + updateInterval.
    when time > nextUpdate then {
        update().
        set nextUpdate to time + updateInterval.
        preserve.
    }

    return self.
}

test("DataListingWidget", {
    parameter t.

    local g is gui(200).
    local w is DataListingWidget(g).

    w:set("key1", "value1").
    t:assertEquals(w:get("key1"), "value1").

    w:set("key1", "value2").
    t:assertEquals(w:get("key1"), "value2").

    g:dispose().
}).