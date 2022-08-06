@lazyGlobal off.
requireOnce("lib/unittest").

if not (defined DataListingWidget) {
    global DataListingWidget is lexicon(
        "create", createDataListingWidget@
    ).
}

local SKIN_LABEL_KEY is "DataListingWidget/LabelKey".
local SKIN_LABEL_VALUE is "DataListingWidget/LabelValue".

local function createDataListingWidget {
    parameter box.
    parameter updateInterval is 0.5.
    local lastUpdate is timestamp(0).

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

    local self is lexicon(
        "__box", box,
        "__vbox", box:addVBox(),
        "__entries", list()  // List of {key, value, keyLabel, valueLabel} lexicons. Value may be a primitive, or a delegate with zero arguments.
    ).
    self:add("set", set@:bind(self)).

    when time - updateInterval > lastUpdate then {
        set lastUpdate to time.
        update(self).
        preserve.
    }

    return self.
}

local function set {
    parameter self.  // DataListingWidget
    parameter key.
    parameter value.

    for entry in self:__entries {
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
    local hbox is self:__vbox:addHLayout().

    local keyLabel is hbox:addLabel("<b>" + key + "</b>").
    set keyLabel:style to self:__box:gui:skin:get(SKIN_LABEL_KEY).

    local valueLabel is hbox:addLabel().
    if value:isType("delegate") {
        set valueLabel:text to value().
    } else {
        set valueLabel:text to value.
    }
    set valueLabel:style to self:__box:gui:skin:get(SKIN_LABEL_VALUE).

    self:__entries:add(lexicon(
        "key", key,
        "value", value,
        "keyLabel", keyLabel,
        "valueLabel", valueLabel
    )).
}

local function update {
    // Update labels whose values were provided as delegates.
    // Labels with static values are only updated in :set().
    parameter self.  // DataListingWidget

    for entry in self:__entries {
        if entry:value:isType("delegate") {
            set entry:valueLabel:text to entry:value().
        }
    }
}

TestCase("DataListingWidget", {
    parameter t.

    local g is gui(200).
    local w is DataListingWidget:create(g).

    w:set("key1", "value1").
    t:assertEquals(w:__entries[0]:key, "key1").
    t:assertEquals(w:__entries[0]:value, "value1").
    t:assertEquals(w:__entries[0]:keyLabel:text, "<b>key1</b>").
    t:assertEquals(w:__entries[0]:valueLabel:text, "value1").

    w:set("key1", "value2").
    t:assertEquals(w:__entries[0]:key, "key1").
    t:assertEquals(w:__entries[0]:value, "value2").
    t:assertEquals(w:__entries[0]:keyLabel:text, "<b>key1</b>").
    t:assertEquals(w:__entries[0]:valueLabel:text, "value2").

    g:dispose().
}).