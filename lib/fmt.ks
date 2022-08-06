@lazyGlobal off.
requireOnce("lib/test").

if not (defined fmt) {
    global fmt is lexicon(
        "format", format@,
        "tabulate", tabulate@,
        "altitude", formatAltitude@
    ).
}

local function format {
    parameter s.
    parameter args.

    for arg in args {
        local index is s:find("{}").
        if index = -1 {
            die("Too many arguments passed to fmt").
        }
        set s to s:remove(index, 2):insert(index, arg).
    }

    return s.
}

local function tabulate {
    parameter input.  // list of lists of strings
    local output is list().  // Returns a list of strings, one per row, with columns tabulated.

    local widths is list().

    for row in input {
        from { local col is 0. } until col = row:length step { set col to col + 1. } do {
            until widths:length > col {
                widths:add(0).
            }
            local width is row[col]:length + 1.
            if width > widths[col] {
                set widths[col] to width.
            }
        }
    }

    for row in input {
        local s is "".
        from { local col is 0. } until col = row:length step { set col to col + 1. } do {
            set s to s + row[col]:padRight(widths[col]).
        }
        output:add(s:trim()).
    }

    return output.
}

local function formatAltitude {
    parameter input.

    if input < 5000 {
        return round(input) + "m".
    } else {
        return round(input / 100) / 10 + "km".
    }
}

test("format", {
    parameter t.
    t:assertEquals(fmt:format("foo {} {}", list("bar", "baz")), "foo bar baz").
}).

test("tabulate", {
    parameter t.
    t:assertEquals(
        fmt:tabulate(list(list("longfoo", "bar"), list("baz", "qux"))):join("\n"),
        list(
            "longfoo bar",
            "baz     qux"
        ):join("\n")
    ).
}).

test("altitude", {
    parameter t.
    t:assertEquals(fmt:altitude(3000.1111), "3000m").
    t:assertEquals(fmt:altitude(200), "200m").
    t:assertEquals(fmt:altitude(7100), "7.1km").
}).