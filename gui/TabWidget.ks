@lazyGlobal off.

requireOnce("lib/logging").
local logger is logging:getLogger("gui/TabWidget").

local SKIN_TAB is "TabWidget/Tab".
local SKIN_PANEL is "TabWidget/Panel".

function TabWidget
{
    parameter box.

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

    local self is lexicon().
    local tabs is lexicon().  // name -> {tab, panel}

    local layout is box:addVLayout().
    local tabsLayout is layout:addHLayout().
    local panelsLayout is layout:addStack().

    local function tab
    {
        parameter name.

        if not tabs:hasKey(name) {
            // Add another panel, style it correctly
            local panel is panelsLayout:addVBox().
            set panel:style to panel:gui:skin:get(SKIN_PANEL).

            // Add another tab, style it correctly
            local t is tabsLayout:addButton(name).
            set t:style to t:gui:skin:get(SKIN_TAB).

            // Set the tab button to be exclusive - when
            // one tab goes up, the others go down.
            set t:toggle to true.
            set t:exclusive to true.

            // If this is the first tab, make it start already shown (make the tab presssed)
            // Otherwise, we hide it (even though the STACK will only show the first anyway,
            // but by keeping everything "correct", we can be a little more efficient later.
            if panelsLayout:widgets:length = 1 {
                set t:pressed to true.
                panelsLayout:showonly(panel).
            } else {
                panelLayout:hide().
            }

            // Handle changes to the tab state, whether initiated by a user click or by a program.
            set t:onToggle to {
                parameter val.
                if val {
                    panelsLayout:showonly(panel).
                }
            }.

            // Add the tab and its corresponding panel to global variables,
            // in order to handle interaction later.
            tabs:add(name, lexicon(
                "tab", t,
                "panel", panel
            )).
        }

        return tabs[name]:panel.
    }
    self:add("tab", tab@).

    local function activate
    {
            parameter name.

            if not tabs:hasKey(name) {
                logger:error("TabWidget:activateTab: No tab named '" + name + "'").
                return.
            }
            set tabs[name]:tab:pressed to true.
    }
    self:add("activate", activate@).

    return self.
}

