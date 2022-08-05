function require {
    parameter name.
    runPath("0:/" + name + ".ks").
}

function requireOnce {
    parameter name.
    runOncePath("0:/" + name + ".ks").
}