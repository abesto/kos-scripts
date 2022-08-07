@lazyGlobal off.
requireOnce("lib/fmt").

if not (defined test) {
    global defaultTestSuite is TestSuite().
    global test is defaultTestSuite:TestCase@.
    global printTestReport is defaultTestSuite:printReport@.
}

local OUTCOME_PASS is "PASS".
local OUTCOME_FAIL is "FAIL".

function TestSuite {
    local suite is lexicon().
    local results is list().

    function TestCase {
        parameter name.
        parameter testFunction.
        local case is lexicon().

        local function assert {
            parameter bool, description, extra is "".
            results:add(lexicon(
                "testName", name,
                "description", choose description if extra = "" else fmt:format("{} ({})", list(description, extra)),
                "outcome", choose OUTCOME_PASS if bool else OUTCOME_FAIL
            )).
        }
        case:add("assert", assert@).

        local function assertEquals {
            parameter lhs, rhs, extra is "".
            case:assert(lhs = rhs,  lhs + " = " + rhs, extra).
        }
        case:add("assertEquals", assertEquals@).

        print(fmt:format("Starting test suite: `{}`", list(name))).
        testFunction(case).
        print(fmt:format("Finished test suite: `{}`", list(name))).
    }
    suite:add("TestCase", TestCase@).

    function printReport {
        local passCount is 0.
        local fails is list().

        for result in results {
            if result:outcome = OUTCOME_PASS {
                set passCount to passCount + 1.
            } else {
                fails:add("[" + result:outcome + "] " + result:testName + ": " + result:description).
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
    suite:add("printReport", printReport@).

    return suite.
}