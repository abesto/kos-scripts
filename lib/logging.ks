@lazyGlobal off.

if not (defined logging) {
    global logging is lexicon(
        // Log levels
        "LEVEL_FATAL", 50,
        "LEVEL_ERROR", 40,
        "LEVEL_WARNING", 30,
        "LEVEL_INFO", 20,
        "LEVEL_DEBUG", 10
    ).

    logging:add("level", logging:LEVEL_INFO).
    logging:add("setLevel", { parameter level. set logging:level to level. }).
    logging:add("getLogger", getLogger@).
}

local function levelName {
    parameter level.

    if level = logging:LEVEL_FATAL {
        return "FATAL".
    } else if level = logging:LEVEL_ERROR {
        return "ERROR".
    } else if level = logging:LEVEL_WARNING {
        return "WARNING".
    } else if level = logging:LEVEL_INFO {
        return "INFO".
    } else if level = logging:LEVEL_DEBUG {
        return "DEBUG".
    }
    return level.
}

local function getLogger {
    parameter name.

    return lexicon(
        "name", name,
        "fatal", doLog@:bind(logging:LEVEL_FATAL, name),
        "error", doLog@:bind(logging:LEVEL_ERROR, name),
        "warning", doLog@:bind(logging:LEVEL_WARNING, name),
        "info", doLog@:bind(logging:LEVEL_INFO, name),
        "debug", doLog@:bind(logging:LEVEL_DEBUG, name)
    ).
}

local function doLog {
    parameter level.
    parameter loggerName.
    parameter message.

    if level < logging:level {
        return.
    }

    local timePart is "[" + timeSpan(missionTime):full:padRight(14) + "] ".
    local levelPart is levelName(level):padRight(8).
    local loggerPart is "(" + loggerName + ") ".
    print(timePart + levelPart + loggerPart + message).
}

function die {
    parameter message.

    logging:fatal(message).
    return 1/0.
}