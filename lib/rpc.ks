@lazyGlobal off.
requireOnce("lib/logging").
requireOnce("lib/comm").
requireOnce("lib/uuid").

local logger is logging:getLogger("lib/rpc").

function RpcClient {
    parameter thing.
    local logger is logging:getLogger("lib/rpc/" + getCommUID(thing)).

    local self is lexicon().
    local isServerLocal is thing:isType("kOSProcessor").
    local myCommClient is CommClient(thing).
    local myCommServer is CommServer(choose core if isServerLocal else vessel).

    local function send {
        parameter name, params.
        myCommClient:send("rpc/v1/request", lexicon(
            "name", name,
            "params", params,
            "responseUUID", false
        )).
    }
    self:add("send", send@).

    local function sendWait {
        parameter name, params.
        local uuid is newUUID().

        local done is false.
        local response is false.
        myCommServer:once("rpc/v1/response/" + uuid, {
            parameter _response.
            set response to _response.
            set done to true.
        }).

        myCommClient:send("rpc/v1/request", lexicon(
            "name", name,
            "params", params,
            "responseUUID", uuid,
            "client", choose getCommUID(core) if isServerLocal else false
        )).
        wait until done.

        return response:content:data.
    }
    self:add("sendWait", sendWait@).

    return self.
}

if not (defined __rpc_servers) {
    global __rpc_servers is lexicon().
}

local function findProcessor {
    parameter uid.
    for processor in ship:modulesNamed("kOSProcessor") {
        if processor:part:uid = uid {
            return processor.
        }
    }
}

function RpcServer {
    parameter thing.  // kOSProcessor or Vessel
    local commUID is getCommUID(thing).
    if __rpc_servers:hasKey(commUID) {
        return __rpc_servers[commUID].
    }

    local self is lexicon().
    __rpc_servers:add(commUID, self).
    local functions is lexicon().

    function registerFunction {
        parameter name, fn.
        functions:add(name, fn).
    }
    self:add("registerFunction", registerFunction@).

    CommServer(thing):only("rpc/v1/request", {
        parameter message.
        local request is message:content:data.

        if not functions:hasKey(request:name) {
            logger:warning("RPC server: no function registered for `{}`", list(request:name)).
            return.
        }
        local result is functions[request:name](request:params).
        if request:responseUUID {
            local sender is choose message:sender if request:client = false else findProcessor(request:client).
            CommClient(sender):send("rpc/v1/response/" + request:responseUUID, result).
        }
    }).

    return self.
}

test("rpc", {
    parameter t.

    local client is RpcClient(core).
    local server is RpcServer(core).
    
    server:registerFunction("add", {
        parameter params.
        return params[0] + params[1].
    }).

    t:assertEquals(client:sendWait("add", list(1, 2)), 3).
}).