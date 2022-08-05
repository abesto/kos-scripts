@lazyGlobal off.
requireOnce("lib/unittest").

function fmt {
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

function tabulate {
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

TestCase("fmt", {
    parameter t.
    t:assertEquals(fmt("foo {} {}", list("bar", "baz")), "foo bar baz").
}).

TestCase("tabulate", {
    parameter t.
    t:assertEquals(
        tabulate(list(list("longfoo", "bar"), list("baz", "qux"))):join("\n"),
        list(
            "longfoo bar",
            "baz     qux"
        ):join("\n")
    ).
}).