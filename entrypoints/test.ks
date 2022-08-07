requireOnce("lib/rpc").
requireOnce("lib/timer").

function main {
    local logger is logging:getLogger("test").

    wait 3.  // Give LV-1 CPU time to start
    local lv is ship:partsTagged("lv1")[0]:getModule("kOSProcessor").
    local lvClient is RpcClient(lv).
    if not lvClient:sendWait("payload-hello", core:part:uid) {
        logger:fatal("Failed to connect to LV-1").
    }
    lvClient:send("payload-status", "Awaiting ascent").

    local updateTimer is timer(0.5).
    on updateTimer:tick {
        lvClient:send("payload-ping", time:full).
        preserve.
    }

    logger:info("Boot sequence finished").

    local separationStarted is false.
    local separationLength is 0.
    local rpcServer is RpcServer(core).
    rpcServer:registerFunction("separation-start", {
        parameter n.
        set separationLength to n.
        set separationStarted to true.
        logger:info("Awaiting separation").
        updateTimer:cancel().
    }).

    wait until separationStarted.
    lvClient:send("payload-status", "Awaiting separation").
    logger:info("Waiting {} seconds for separation.", separationLength).
    wait separationLength.
    logger:info("Initiating guidance").

    rcs on.
    lock steering to ship:prograde.
    wait 60.
}