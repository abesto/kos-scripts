@lazyGlobal off.

if not (defined __unittest_results) {
    global __unittest_results is list().
}

local PASS is "PASS".
local FAIL is "FAIL".

function testReport {
    local passCount is 0.
    local fails is list().

    for result in __unittest_results {
        if result:outcome = PASS {
            set passCount to passCount + 1.
        } else {
            fails:add("[" + result:outcome + "] " + result:testName + ": " + result:assertion).
        }
    }

    print "=== TEST REPORT ===".
    print "PASS: " + passCount + " FAIL: " + fails:length.
    for fail in fails {
        print fail.
    }
    print "=== END TEST REPORT ===".

    if fails:length > 0 {
        return false.
    } else {
        return true.
    }
}

function TestCase {
    parameter name.
    parameter test.

    local api is NewApi(name).
    test(api).
    for result in api:__results {
        __unittest_results:add(result).
    }
}

local function NewApi {
    parameter name.

    local self is lexicon(
        "__name", name,
        "__results", list()
    ).

    self:add("assert", assert@:bind(self)).
    self:add("assertEquals", assertEquals@:bind(self)).

    return self.
}

local function NewResult {
    parameter testName.
    parameter assertion.
    parameter outcome.  // PASS / FAIL

    return lexicon(
        "testName", testName,
        "assertion", assertion,
        "outcome", outcome
    ).
}

local function assert {
    parameter self.  // Api
    parameter bool.
    parameter description.

    local outcome is PASS.
    if not bool {
        set outcome to FAIL.
    }

    self:__results:add(NewResult(self:__name, description, outcome)).
}

local function assertEquals {
    parameter self.  // Api
    parameter lhs.
    parameter rhs.

    local equals is false.
    if lhs = rhs {
        set equals to true.
    }
    self:assert(equals,  lhs + " = " + rhs).
}