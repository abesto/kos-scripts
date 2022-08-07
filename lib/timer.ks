@lazyGlobal off.

function timer {
    parameter intervalSeconds.
    local self is lexicon("tick", 0).
    local running is true.
    local nextTick is time + intervalSeconds.

    when running and time > nextTick then {
        set self:tick to self:tick + 1.
        set nextTick to time + intervalSeconds.
        if running {
            preserve.
        }
    }

    self:add("cancel", { set running to false. }).
    return self.
}