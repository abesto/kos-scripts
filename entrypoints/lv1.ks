requireOnce("gui/TabWidget").
requireOnce("gui/DataListingWidget").

local logger is logging:getLogger("lv1").

// Launch script for LV-1 launch vehicle. It gets the payload to a suborbital trajectory with apoapsis ~100km, then returns to Kerbin.

local function unwarp {
    // TODO move to a library
    if warp > 0 {
        info("Stopping warp...").
        set warp to 0.
        wait until warp = 0.
        wait 2.
    }
}

local function skipFrame {
    wait 0.
    return.
    // TODO if this implementation works, then inline it
    local now to time.
    wait until time > now.
}

local function ascent {
    // TODO redesign this to be (altitude, surface-velocity-pitch) targets
    // Tuples of (speed, pitch): at `speed`, pitch to `pitch`
    local curve is queue(
        list(100, 80),
        list(200, 70),
        list(300, 60),
        list(400, 50),
        list(500, 40),
        list(600, 30),
        list(700, 20),
        list(800, 10)
    ).

    when maxthrust = 0 then {
        logger:info("!!OUT OF dV!!").
    }.

    // TODO maintain twr=1.3
    lock throttle to 1.0.
    when ship:verticalspeed > 0 then {
        logger:info("Liftoff").
    }
    when ship:altitude > 40000 then {
        logger:info("40km altitude, enabling RCS").
        rcs on.
    }

    // TODO limit AoA
    local mysteer is heading(90,90).
    lock steering to mysteer.

    until ship:apoapsis > 100000 or curve:empty() {
        if curve:peek()[0] < ship:velocity:surface:mag {
            local pitch to curve:pop()[1].
            set mysteer to heading(90, pitch).
            logger:info("Pitching to " + pitch).
        }
    }.

    logger:info("Pitching done, now burning prograde").
    unwarp().
    unlock steering.
    sas on.
    skipFrame().
    set sasmode to "prograde".
    wait until ship:apoapsis > 100000.
    lock throttle to 0.0.

    logger:info("Coasting to edge of atmosphere").
    wait until ship:altitude > 70000.

    // Tell other CPUs on the vessel that ascent is done. They should wait a few seconds, then initiate circularization.
    list processors in all_processors.
    for processor in all_processors {
        processor:connection:sendMessage("ascent_done").
    }
    skipFrame().
    stage.

    unwarp().
    logger:info("LV-1 ascent complete, payload detached, distancing from payload.").
    set ship:control:fore to -1.0.
    wait 5.
    set ship:control:fore to 0.0.

    logger:info("Turning retrograde.").
    sas on.
    skipFrame().
    set sasmode to "retrograde".
    wait until ship:angularmomentum:mag < 0.1.

    logger:info("Burning.").
    lock throttle to 1.0.
    wait until ship:altitude < 60000.
}

function main {
    print("LV-1 launch script loaded. Stage to launch.").

    clearGuis().
    local g is gui(400).
    local tabs is TabWidget:create(g).
    local t is tabs:tab("LV-1").
    tabs:tab("Test"):addLabel("TEST TEST TEST").
    t:addLabel("LV-1 testing").
    local readout is DataListingWidget:create(t).
    readout:set("Status", "Waiting for launch").
    readout:set("Vessel name", ship:name).
    readout:set("Altitude", ship:altitude).
    g:show().

    local initialStage to stage:number.
    //wait until stage:number < initialStage.
    //ascent().
}