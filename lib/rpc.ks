@lazyGlobal off.
requireOnce("lib/logging").

local logger is logging:getLogger("lib/rpc").

local function _Rpc {
    local self is lexicon().

    local function method {
        parameter name, send, receive.

        self:add(name, lexicon(
            "send": send,
            "receive": receive
        )).
    }
    self:add("method", method@).

    local function send {
        parameter methodName, connection, params, cb is false.

        connection:sendMessage(lexicon(
            "version": version,
            "method": methodName,
            "params": params
        )).
    }

    return self.
}