@LAZYGLOBAL off.
clearScreen.
wait until ship:unpacked.

print("Autoboot starts").
copyPath("0:/lib/require.ks", "lib/require.ks").
runOncePath("lib/require").
require("lib/prelude").

local logger is logging:getLogger("autoboot").

if core:tag:length = 0 {
    logger:fatal("kOS core has no tag set; exiting").
} else {
    logger:debug("kOS core has tag: " + core:tag).

    if exists("0:/entrypoints/" + core:tag) {
        logger:debug("Loading entrypoint: " + core:tag).
        copyPath("0:/entrypoints/" + core:tag, "").
        copyPath("0:/boot/autoboot.ks", "").

        requireOnce("lib/test").
        runPath(core:tag).
        if not printTestReport() {
            logger:fatal("Test suite failed; exiting").
        } else {
            logger:debug("Test suite passed").
            main().
        }
    } else {
        logger:fatal("No entrypoint found for tag: " + core:tag + "; exiting").
    }
}

logger:info("Exiting").