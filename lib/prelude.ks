requireOnce("lib/math").
requireOnce("lib/logging").
requireOnce("lib/fmt").

local logger is logging:getLogger("lib/prelude").
//set logging:level to logging:LEVEL_DEBUG.

if not (defined __prelude_loaded) {
    global __prelude_loaded is true.
    core:messages:clear().
    logger:info("Loaded").
}
