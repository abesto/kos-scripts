require("lib/logging").
require("lib/fmt").

local logger is logging:getLogger("prelude").

if not (defined __prelude_loaded) {
    set terminal:width to 120.
    set terminal:height to 40.
    global __prelude_loaded is true.
    logger:info("Loaded").
}
