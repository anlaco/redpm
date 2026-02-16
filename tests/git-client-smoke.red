Red [
    Title:   "Git-client smoke test"
    File:    %tests/git-client-smoke.red
    Purpose: {Basic smoke test for src/git-client.red}
]

#include %../src/git-client.red
#include %../src/logger.red
#include %../src/filesystem.red

print "Running git-client smoke test..."

unless git-client/git-available? [
    logger/log-error "git is not available on PATH — cannot run git-client smoke test"
    quit 1
]

;-- Clone a small repo into a temporary folder and verify it exists
tmp: %tmp-git-client-test/
if filesystem/dir-exists? tmp [filesystem/remove-dir tmp]

ok: git-client/clone-repo (to url! "https://github.com/ANLACO/Red-Utils") tmp
unless ok [
    logger/log-error "git-client/clone-repo failed (network or remote unavailable)"
    quit 2
]

either git-client/get-current-sha tmp [
    logger/log-info rejoin ["cloned repo sha: " git-client/get-current-sha tmp]
][
    logger/log-warn "could not read sha from cloned repo"
]

;-- Clean up
attempt [filesystem/remove-dir tmp]

print "GIT-CLIENT smoke test: OK"
quit 0
