@lazyGlobal off.

requireOnce("lib/fmt").
requireOnce("gui/TabWidget").
requireOnce("gui/DataListingWidget").
requireOnce("lib/rpc").

local logger is logging:getLogger("lv1").

// Launch script for LV-1 launch vehicle. It gets the payload to a suborbital trajectory with apoapsis ~100km, then returns to Kerbin.

local function unwarp {
    // TODO move to a library
    if warp > 0 {
        logger:info("Stopping warp...").
        set warp to 0.
    }
}

local function doWarp {
    if warp < 3 {
        logger:info("Warping").
        set warp to 3.
    }
}

local function ascent {
    parameter readout, payloadClient, onFinished.

    function status {
        parameter msg.
        readout:set("Status", msg).
        logger:info(msg).
    }


    lock grav to body:mu / (ship:altitude + body:radius)^2.
    lock steering to heading(90,90).
    stage.
    lock throttle to 1.5 * Ship:Mass * grav / Ship:AvailableThrust.
    when maxthrust < 5 then {
        logger:info("!!OUT OF dV!!").
    }.

    when ship:verticalspeed > 0 then {
        status("Liftoff").
    }

    wait until ship:verticalspeed > 30.
    doWarp().
    wait until ship:velocity:surface:mag > 100.
    unwarp().

    lock steering to heading(90, 85).
    status("Pitching to 85").
    wait until ship:angularvel:mag < 0.1.

    doWarp().
    wait until 90 - vang(ship:srfprograde:vector, up:vector) <= 85.
    unwarp().

    lock steering to heading(90, 90 - vang(ship:srfprograde:vector, up:vector)).
    status("Gravity turn").

    when ship:velocity:orbit:mag > 800 then {
        logger:info("Switched from surface to orbital prograde").
        unwarp().
        lock steering to heading(90, 90 - vang(ship:prograde:vector, up:vector)).
        doWarp().
    }

    when ship:altitude > 40000 then {
        logger:info("40km altitude, enabling RCS, max throttle").
        unwarp().
        rcs on.
        wait 0.
        lock throttle to 1.0.
        wait 0.
        doWarp().
    }

    doWarp().
    wait until ship:orbit:apoapsis > 100000.
    unwarp().

    lock throttle to 0.0.
    unlock throttle.
    status("Coasting to edge of atmosphere").

    doWarp().
    wait until ship:altitude > 70000.
    unwarp().


    logger:info("LV-1 ascent complete, payload detached, distancing from payload.").
    readout:set("Status", "Payload separation").
    payloadClient:send("separation-start", 10).
    stage.
    readout:set("Payload", "Separated").
    wait 3.
    set ship:control:fore to -1.0.
    wait 5.
    set ship:control:fore to 0.0.
    set ship:control:neutralize to true.
    wait 0.

    status("Turning retrograde").
    lock steering to retrograde.
    wait 3.  // It'll take at least this long to turn, and it gives angular velocity to go up so that the next wait can be meaningful
    wait until ship:angularMomentum:mag < 1.

    status("Guidance finished").
    onFinished().
}

function twr {
    local thrust is 0.
    local engines is list().
    list engines in engines.
    for engine in engines {
        set thrust to thrust + engine:thrust.
    }
    local g is body:mu / (ship:altitude + body:radius)^2.
    return round((thrust / (ship:mass * g)) * 100) / 100.
}

function main {
    local finished is false.

    clearGuis().

    local g is gui(300).
    set g:x to 0.

    local tabs is TabWidget(g).
    local t is tabs:tab("LV-1").

    local readout is DataListingWidget(t).
    readout:set("Vessel Name", ship:name).
    readout:set("Status", "Waiting for launch").
    readout:set("Altitude", { return fmt:altitude(ship:altitude). }).
    readout:set("Apoapsis", { return fmt:altitude(ship:orbit:apoapsis). }).
    readout:set("Prograde pitch", { return round(90 - vang(ship:srfprograde:vector, up:vector)):toString. }).
    readout:set("TWR", { return twr():toString. }).
    readout:set("Time", { return time:full. }).
    readout:set("Warp", { return warp:toString. }).

    local payloadClient is false.
    local rpcServer is RpcServer(core).
    local payloadReady is false.
    rpcServer:registerFunction("payload-hello", {
        parameter payloadCoreUID.
        for proc in ship:modulesNamed("kOSProcessor") {
            if proc:part:uid = payloadCoreUID {
                set payloadClient to RpcClient(proc).
                set payloadReady to true.
                return true.
            }
        }
        logger:error("No payload processor found with UID " + payloadCoreUID).
    }).
    rpcServer:registerFunction("payload-status", readout:set@:bind("Payload")).
    rpcServer:registerFunction("payload-ping", readout:set@:bind("Last payload ping")).

    local rebootButton is t:addButton("Reboot").
    local exitButton is t:addButton("Exit").

    set rebootButton:onClick to {
        reboot.
    }.

    set exitButton:onClick to {
        set finished to true.
    }.

    wait until payloadReady.
    local started is false.
    local launchButton is t:addButton("Launch!").
    set launchButton:onClick to {
        launchButton:dispose().
        rebootButton:dispose().

        local revertButton is t:addButton("Revert to Launch").
        set revertButton:onClick to {
            kuniverse:revertToLaunch().
        }.

        set started to true.
    }.

    g:show().
    logger:info("Boot sequence complete").
    wait until started or finished.
    if not finished {
        ascent(readout, payloadClient, { set finished to true. }).
    }
    wait until finished.
}