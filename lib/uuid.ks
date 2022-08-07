@lazyGlobal off.
requireOnce("lib/fmt").
requireOnce("lib/test").


function newUUID {
    parameter key is false, t is false.

    // Two random integers together get us 2*53 = 106 bits
    local n1 is randomInt(key).
    local n2 is randomInt(key).
    // We need a total of 122 bits. Pseudo-random numbers are meh, se we'll take 16 bits from the current in-game timestamp.
    local n3 is lowBits(round(choose t if t <> false else time:seconds), 16).

    // ________-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx
    local n is lowBits(n1, 32).
    set n1 to bitShiftRight(n1, 32).  // Remaining bits in n1: 53 - 32 = 21
    local s is fmt:hex(n):padLeft(8):replace(" ", "0") + "-".

    // xxxxxxxx-____-Mxxx-Nxxx-xxxxxxxxxxxx
    set n to lowBits(n1, 16).
    set n1 to bitShiftRight(n1, 16).  // Remaining bits in n1: 21 - 16 = 5
    set s to s + fmt:hex(n):padLeft(4):replace(" ", "0") + "-".

    // xxxxxxxx-xxxx-M___-Nxxx-xxxxxxxxxxxx
    set n to bitShiftLeft(n1, 7) + lowBits(n2, 7).  // Take the remaining 5 bits from n1, plus (12-5)=7 bits from n2
    set n2 to bitShiftRight(n2, 7).  // Remaining bits in n2: 53 - 7 = 46
    // This is UUID version 4, I guess? Kinda? Just salted with the time.
    set s to s + "4" + fmt:hex(n):padLeft(3):replace(" ", "0") + "-".

    // Variant(M): variant 1: 10xx
    set n to 2^3 + lowBits(n2, 2).
    set n2 to bitShiftRight(n2, 2).  // Remaining bits in n2: 46 - 2 = 44

    // xxxxxxxx-xxxx-Mxxx-N___-xxxxxxxxxxxx
    set n to bitShiftLeft(n, 12) + lowBits(n2, 12).
    set n2 to bitShiftRight(n2, 12).  // Remaining bits in n2: 44 - 12 = 32
    set s to s + fmt:hex(n) + "-".

    // xxxxxxxx-xxxx-Mxxx-Nxxx-____________
    set s to s + fmt:hex(bitShiftLeft(n2, 16) + n3):padLeft(12):replace(" ", "0").

    return s.
}

test("uuid", {
    parameter t.
    randomSeed("uuid-test", 4242).
    t:assertEquals(newUUID("uuid-test", 12345), "5236aeeb-5775-4dc6-aff8-7fc5183e3039").
}).