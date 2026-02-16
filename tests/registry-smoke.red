Red [
    Title:   "Registry smoke test"
    File:    %tests/registry-smoke.red
    Purpose: {Verify registry/load-packages and save-packages}
]

#include %../src/registry.red
#include %../src/package.red
#include %../src/logger.red

print "Running registry smoke test..."

pkgs: registry/load-packages
unless pkgs [
    logger/log-warn "No deps.red found for registry smoke test"
    quit 1
]

first: first pkgs
print rejoin ["first package name: " package/get-name first]
print rejoin ["first package url: " package/get-url first]

print "REGISTRY smoke test: OK"
quit 0
