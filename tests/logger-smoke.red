Red [
    Title:   "Logger smoke test"
    File:    %tests/logger-smoke.red
    Purpose: {Verifies that `src/logger.red` exports the public functions}
]

#include %../src/logger.red

print "Running logger smoke test..."

;-- Calls must not raise errors
logger/log-ok "ok message"
logger/log-error "error message"
logger/log-info "info message"
logger/log-warn "warn message"
logger/log-debug "debug message (visible only with --verbose)"

;-- Verify public constants
print rejoin ["colors: " logger/green "●" logger/reset]

print "LOGGER smoke test: OK"
quit 0
