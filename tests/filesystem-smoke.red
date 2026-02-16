Red [
    Title:   "Filesystem smoke test"
    File:    %tests/filesystem-smoke.red
    Purpose: {Verify filesystem helpers ensure-dir, remove-dir, dir-exists?}
]

#include %../src/filesystem.red
#include %../src/logger.red

print "Running filesystem smoke test..."

tmp: %tmp-filesystem-test/
if filesystem/dir-exists? tmp [filesystem/remove-dir tmp]

either filesystem/ensure-dir tmp [
    logger/log-info "created tmp dir"
][
    logger/log-error "failed to create tmp dir"
    quit 1
]

unless filesystem/dir-exists? tmp [logger/log-error "dir not present after ensure-dir" quit 2]

rval: filesystem/remove-dir tmp
print rejoin ["filesystem/remove-dir returned: " to-string rval]
print rejoin ["dir-exists? after remove-dir: " to-string filesystem/dir-exists? tmp]
unless not filesystem/dir-exists? tmp [logger/log-error "dir still present after remove-dir" quit 3]

print "FILESYSTEM smoke test: OK"
quit 0
