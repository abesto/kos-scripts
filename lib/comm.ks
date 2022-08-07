@lazyGlobal off.
requireOnce("lib/logging").
requireOnce("lib/uuid").
requireOnce("lib/test").

local logger is logging:getLogger("lib/comm").
local commVersion is "1".

local anyRunning is false.

function CommServer {
    parameter messageQueue.

    local self is lexicon().
    local handlers is lexicon().  // name -> [{uuid, once: bool, fn: function(message)}]
    local running is false.

    function handleMessage {
        parameter message.  // {version, name, params}

        local content is message:content.
        logger:debug("handleMessage: `{}` params: `{}`", list(content:name, content:params)).

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
            handler:fn(content:params).
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

    function withRunning {
        parameter fn.
        if anyRunning {
            die("Tried to start a CommServer while another one is already running.").
        }
        set running to true.
        set anyRunning to true.
        fn().
        set running to false.
        set anyRunning to false.
    }
    self:add("withRunning", withRunning@).

    when running and not messageQueue:empty then {
        handleMessage(messageQueue:pop()).
        preserve.
    }

    return self.
}

function CommClient {
    parameter connection.

    local self is lexicon().

    function send {
        parameter name, params is lexicon().
        local message is lexicon("version", commVersion, "name", name, "params", params).
        logger:debug("Sending to `{}`: `{}` params `{}`", list(connection:destination:name, name, params)).
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
    parameter server, client, name, params is false.
    local done is false.
    server:once(name, {parameter _. set done to true. }).
    local success is client:send(name, params).
    if success {
        wait until done.
    }
    return success.
}

test("comm/simple", {
    parameter t.
    //set logging:level to logging:LEVEL_DEBUG.

    local server is CommServer(core:messages).
    local client is CommClient(core:connection).
    local sendWait is test_sendWait@:bind(server, client).
    local received is 0.

    server:withRunning({
        server:once("testMsg", { parameter n. set received to n. }).
        sendWait("testMsg", 1).
        t:assertEquals(received, 1, "once executed").

        sendWait("testMsg", 2).
        t:assertEquals(received, 1, "once removed after execution").

        server:on("testMsg", { parameter n. set received to n. }).
        sendWait("testMsg", 3).
        t:assertEquals(received, 3, "on executed").

        sendWait("testMsg", 4).
        t:assertEquals(received, 4, "on executed again").
    }).
}).

test("comm/off()", {
    parameter t.

    local server is CommServer(core:messages).
    local client is CommClient(core:connection).
    local sendWait is test_sendWait@:bind(server, client).

    server:withRunning({
        local count is 0.

        server:on("testMsg", { parameter params. set count to count + 1. }).
        server:on("testMsg", { parameter params. set count to count + 1. }).
        sendWait("testMsg", "comm/off()/0").
        t:assertEquals(count, 2).

        server:off("testMsg").
        sendWait("testMsg", "comm/off()/1").
        t:assertEquals(count, 2).
    }).
}).

test("comm/off(uuid)", {
    parameter t.

    local server is CommServer(core:messages).
    local client is CommClient(core:connection).
    local sendWait is test_sendWait@:bind(server, client).

    server:withRunning({
        local count is 0.

        local uuid is server:on("testMsg", { parameter params. set count to count + 1. }).
        server:on("testMsg", { parameter params. set count to count + 1. }).
        sendWait("testMsg").
        t:assertEquals(count, 2).

        server:off("testMsg", uuid).
        sendWait("testMsg").
        t:assertEquals(count, 3).
    }).
}).