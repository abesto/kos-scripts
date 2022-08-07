@lazyGlobal off.

// random() in kOS generates a double. In theory that should have 53 significant bits.
// This roughly lines up with kOS docs saying you can have at most 15 decimal places in a number.
local doubleSigBitsMult is 2^53.
function randomInt {
    parameter key is false.
    local float is choose random() if key = false else random(key).
    return round(float * doubleSigBitsMult).
}

function bitShiftRight {
    parameter n, count.
    return floor(n / 2^count).
}

function bitShiftLeft {
    parameter n, count.
    return n * 2^count.
}

function lowBits {
    parameter n, count.
    return mod(n, 2^count).
}