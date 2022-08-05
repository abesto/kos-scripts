@lazyGlobal off.

if not (defined DataListingWidget) {
    global DataListingWidget is lexicon(
        "create", createDataListingWidget@
    ).
}

local SKIN_LABEL is "DataListingWidget/Label".

local function createDataListingWidget {
    parameter box.

    if not box:gui:skin:has(SKIN_LABEL) {
        local style is box:gui:skin:add(SKIN_LABEL, box:gui:skin:label).
        set style:margin:v to 0.
        set style:padding:v to 0.
        set style:font to "Source Code Pro".
    }

    local self is lexicon(
        "__box", box,
        "__vbox", box:addVBox(),
        "__entries", list(),  // list of (name, value) tuples
        "__labels", list()  // Labels
    ).
    self:add("set", set@:bind(self)).

    return self.
}

local function set {
    parameter self.  // DataListingWidget
    parameter key.
    parameter value.

    for entry in self:__entries {
        if entry[0] = key {
            if not entry[1] = value {
                set entry[1] to value.
                update(self).
            }
            return.
        }
    }
    self:__entries:add(list("<b>" + key + "</b>", value:toString)).

    local label is self:__vbox:addLabel().
    set label:style to self:__box:gui:skin:get(SKIN_LABEL).
    self:__labels:add(label).

    update(self).
}

local function update {
    parameter self.  // DataListingWidget

    local tabulated is tabulate(self:__entries).
    from { local row is 0. } until row = self:__entries:length step { set row to row + 1. } do {
        set self:__labels[row]:text to tabulated[row].
    }
}