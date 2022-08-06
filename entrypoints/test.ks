requireOnce("gui/TabWidget").

function main {
    local logger is logging:getLogger("test").

    logger:info("Test entrypoint here, hi!").
    logger:info("Waiting for messages.").

    wait until not core:messages:empty.

    set received to core:messages:pop.
    if received:content = "ascent_done" {
        logger:info("ascent_done received, now would be a good time to circularize.").
    } else {
        logger:info("Received: " + received).
    }

    wait 5.
    lock steering to ship:prograde.
    wait 60.
}