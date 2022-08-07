@lazyGlobal off.
requireOnce("lib/logging").
requireOnce("lib/uuid").
requireOnce("lib/test").

local logger is logging:getLogger("lib/comm").
local commVersion is "1".

if not (defined __comm_servers) {
    global __comm_servers is lexicon().
}

function getCommUID {
    parameter thing.
    if thing:isType("kOSProcessor") {
        return thing:part:uid.
    } else if thing:isType("Vessel") {
        return thing:rootpart:uid.
    } else if thing:isType("Part") {
        return thing:uid.
    } else {
        logger:fatal("commUID: Unknown type: " + thing:typename).
    }
}

function CommServer {
    parameter thing.  // kOSProcessor or Vessel
    local commUID is getCommUID(thing).
    if __comm_servers:hasKey(commUID) {
        return __comm_servers[commUID].
    }
    local self is lexicon().
    __comm_servers:add(commUID, self).

    local logger is logging:getLogger("lib/comm/server/" + commUID).

    local handlers is lexicon().  // name -> [{uuid, once: bool, fn: function(message)}]

    function handleMessage {
        parameter message.  // {version, name, data}

        local content is message:content.
        logger:debug("handleMessage: `{}` data: `{}`", list(content:name, content:data)).

        if content:version <> commVersion {
            logger:error("version mismatch: expected `{}` found `{}`",  list(commVersion, content:version)).
            return.
        }

        if (not handlers:hasKey(content:name)) or handlers[content:name]:empty {
            logger:warning("No handlers for message type: `{}`", list(content:name)).
            return.
        }

        local toRemove is list().
        logger:debug("handlers: `{}`", list(handlers[content:name])).
        for handler in handlers[content:name] {
            logger:debug("Executing handler `{}`", list(handler:uuid)).
            handler:fn(message).
            if handler:once {
                toRemove:add(handler:uuid).
            }
        }
        for uuid in toRemove {
            removeHandler(content:name, uuid).
        }
    }

    function addHandler {
        parameter once, name, fn.
        local handler is lexicon(
            "once", once,
            "fn", fn,
            "uuid", newUUID()
        ).
        if handlers:hasKey(name) {
            handlers[name]:add(handler).
        } else {
            handlers:add(name, list(handler)).
        }
        logger:debug("addHandler({}) -> {} (have {})", list(name, handler:uuid, handlers[name]:length)).
        return handler:uuid.
    }
    self:add("on", addHandler@:bind(false)).
    self:add("once", addHandler@:bind(true)).
    self:add("only", {
        parameter name, fn.
        if handlers:hasKey(name) {
            logger:fatal("Handler already exists for `{}`", list(name)).
        }
        addHandler(false, name, fn).
    }).

    function removeHandler {
        parameter name, uuid is false.

        if not handlers:hasKey(name) {
            logger:debug("removeHandler: No handlers for message type: `{}`", list(name)).
            return.
        }

        if uuid = false {
            handlers:remove(name).
            return.
        }

        from { local i is 0. } until i = handlers[name]:length step { set i to i + 1. } do {
            local handler is handlers[name][i].
            if handler:uuid = uuid {
                handlers[name]:remove(i).
                return.
            }
        }

        logger:warning("removeHandler: No handler for message `{}` with uuid `{}`", list(name, uuid)).
    }
    self:add("off", removeHandler@).
    self:add("clearHandlers", { handlers:clear(). }).

    when not thing:messages:empty then {
        until thing:messages:empty {
            handleMessage(thing:messages:pop()).
        }
        preserve.
    }

    return self.
}

function CommClient {
    parameter thing.
    local logger is logging:getLogger("lib/comm/client/" + getCommUID(thing)).
    local connection is thing:connection.

    local self is lexicon().

    function send {
        parameter name, data is lexicon().
        local message is lexicon("version", commVersion, "name", name, "data", data).
        logger:debug("Sending to `{}`: `{}` data `{}`", list(connection:destination:name, name, data)).
        local success is connection:sendMessage(message).
        if not success {
            logger:error("Failed to send to " + connection:destination + ": " + message).
        }
        return success.
    }
    self:add("send", send@).

    return self.
}

local function test_sendWait {
    parameter server, client, name, data is false.
    local done is false.
    server:once(name, {parameter _. set done to true. }).
    local success is client:send(name, data).
    if success {
        wait until done.
    }
    return success.
}

test("comm/simple", {
    parameter t.
    //set logging:level to logging:LEVEL_DEBUG.

    local server is CommServer(core).
    local client is CommClient(core).
    local sendWait is test_sendWait@:bind(server, client).
    local received is 0.

    server:clearHandlers().
    server:once("testMsg", { parameter msg. set received to msg:content:data. }).
    sendWait("testMsg", 1).
    t:assertEquals(received, 1, "once executed").

    sendWait("testMsg", 2).
    t:assertEquals(received, 1, "once removed after execution").

    server:on("testMsg", { parameter msg. set received to msg:content:data. }).
    sendWait("testMsg", 3).
    t:assertEquals(received, 3, "on executed").

    sendWait("testMsg", 4).
    t:assertEquals(received, 4, "on executed again").
}).

test("comm/off()", {
    parameter t.

    local server is CommServer(core).
    local client is CommClient(core).
    local sendWait is test_sendWait@:bind(server, client).

    local count is 0.

    server:clearHandlers().
    server:on("testMsg", { parameter data. set count to count + 1. }).
    server:on("testMsg", { parameter data. set count to count + 1. }).
    sendWait("testMsg", "comm/off()/0").
    t:assertEquals(count, 2).

    server:off("testMsg").
    sendWait("testMsg", "comm/off()/1").
    t:assertEquals(count, 2).
}).

test("comm/off(uuid)", {
    parameter t.

    local server is CommServer(core).
    local client is CommClient(core).
    local sendWait is test_sendWait@:bind(server, client).

    local count is 0.

    server:clearHandlers().
    local uuid is server:on("testMsg", { parameter data. set count to count + 1. }).
    server:on("testMsg", { parameter data. set count to count + 1. }).
    sendWait("testMsg").
    t:assertEquals(count, 2).

    server:off("testMsg", uuid).
    sendWait("testMsg").
    t:assertEquals(count, 3).
}).