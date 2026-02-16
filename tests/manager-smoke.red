Red [
    Title:   "Manager smoke test"
    File:    %tests/manager-smoke.red
    Purpose: {Basic checks for manager functions (list, init)}
]

#include %../src/manager.red
#include %../src/registry.red
#include %../src/logger.red

print "Running manager smoke test..."

;-- manager/list should not crash
either manager/list [print "manager/list ran"] [print "manager/list: no deps declared"]

;-- manager/init should create deps.red if absent (we won't overwrite existing)
if not exists? registry/deps-file [
    manager/init
    unless exists? registry/deps-file [logger/log-error "manager/init failed" quit 1]
    logger/log-info "manager/init created deps.red"
    ; cleanup the created file for the smoke test
    attempt [delete registry/deps-file]
]

print "MANAGER smoke test: OK"
quit 0
