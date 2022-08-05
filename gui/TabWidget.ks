@lazyGlobal off.

if not (defined TabWidget) {
    global TabWidget is lexicon(
        "create", createTabWidget@
    ).
}

local SKIN_TAB is "TabWidget/Tab".
local SKIN_PANEL is "TabWidget/Panel".

local function createTabWidget
{
    parameter box.

    local self is lexicon(
        "widgets", lexicon(
            "box", box
        ),
        "tabs", lexicon(),
        "panels", lexicon()
    ).

    if not box:gui:skin:has(SKIN_TAB) {
        local style is box:gui:skin:add(SKIN_TAB, box:gui:skin:button).

        // Images are stored alongside the code.
        set style:bg to "gui/TabWidget/images/back".
        set style:on:bg to "gui/TabWidget/images/front".

        // Tweak the style.
        set style:textcolor to rgba(0.7,0.75,0.7,1).
        set style:hover:bg to "".
        set style:hover_on:bg to "".
        set style:margin:h to 0.
        set style:margin:bottom to 0.
    }
    IF not box:gui:skin:has(SKIN_PANEL) {
        locaL style is box:gui:skin:add(SKIN_PANEL,box:gui:skin:window).
        set style:bg to "gui/TabWidget/images/panel".
        set style:padding:top to 0.
    }

    // Add a vlayout (in case the box is a HBOX, for example),
    // then add a hlayout for the tabs and a stack to hols all the panels.
    self:widgets:add("vbox", self:widgets:box:addVLayout()).
    self:widgets:add("tabs", self:widgets:vbox:addHLayout()).
    self:widgets:add("panels", self:widgets:vbox:addStack()).

    // Bind instance methods
    self:add("tab", getOrCreateTab@:bind(self)).
    self:add("activate", activateTab@:bind(self)).

    // Return the empty Tabself.
    RETURN self.
}

local function getOrCreateTab
{
    parameter self.
    parameter name.

    if self:tabs:hasKey(name) {
        return self:tabs[name].
    }

    // Add another panel, style it correctly
    local panel is self:widgets:panels:addVBox().
    set panel:style to panel:gui:skin:get(SKIN_PANEL).

    // Add another tab, style it correctly
    local tab is self:widgets:tabs:addButton(name).
    set tab:style to tab:gui:skin:get(SKIN_TAB).

    // Set the tab button to be exclusive - when
    // one tab goes up, the others go down.
    set tab:toggle to true.
    set tab:exclusive to true.

    // If this is the first tab, make it start already shown (make the tab presssed)
    // Otherwise, we hide it (even though the STACK will only show the first anyway,
    // but by keeping everything "correct", we can be a little more efficient later.
    if self:widgets:panels:widgets:length = 1 {
        set tab:pressed to true.
        self:widgets:panels:showonly(panel).
    } else {
        panel:hide().
    }

    // Handle changes to the tab state, whether initiated by a user click or by a program.
    set tab:onToggle to {
        parameter val.
        if val {
            self:widgets:panels:showonly(panel).
        }
    }.

    // Add the tab and its corresponding panel to global variables,
    // in order to handle interaction later.
    self:tabs:add(name, tab).
    self:panels:add(name, panel).

    return panel.
}

local function activateTab
{
        parameter self.
        parameter name.

        if not self:tabs:hasKey(name) {
            error("TabWidget:activateTab: No tab named '" + name + "'").
            return.
        }
        set self:tabs[name]:pressed to true.
}