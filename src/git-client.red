Red [
    Title:   "Git client wrapper for redpm"
    Author:  "ANLACO"
    File:    %src/git-client.red
    Purpose: {Encapsulate git calls so other modules don't call shell directly}
]

git-client: context [

    ;-- Return true if `git` executable is available on PATH
    git-available?: does [
        out: ""
        call/output "git --version" out
        find out "git version"
    ]

    ;-- Clone a repo into `target` (shallow by default)
    ;-- Returns: true on success, false on failure
    clone-repo: func [
        url [string!]
        target [file!]
        /shallow
    ][
        cmd: rejoin ["git clone " (either shallow ["--depth 1 "] [""]) url " " to-string target " 2>&1"]
        ;-- Use call/wait/shell to allow interactive output if necessary
        call/wait/shell cmd
        exists? target
    ]

    ;-- Pull in an existing repo. Returns stdout (string) or none on failure
    pull-repo: func [path [file!]] [
        out: ""
        cmd: rejoin ["cd " to-string path " && git pull 2>&1"]
        attempt [call/output/shell cmd out]
        either out [out][none]
    ]

    ;-- Checkout a tag/branch/commit in an existing repo. Returns true/false
    checkout-version: func [path [file!] ref [string!]] [
        out: ""
        cmd: rejoin ["cd " to-string path " && git checkout " ref " 2>&1"]
        attempt [call/output/shell cmd out]
        not none? out
    ]

    ;-- Get current commit SHA (short). Returns string or none
    get-current-sha: func [path [file!]] [
        out: ""
        cmd: rejoin ["cd " to-string path " && git rev-parse --short HEAD 2>&1"]
        attempt [call/output/shell cmd out]
        either find out "fatal" [none][trim out]
    ]

    ;-- Return true if repo has uncommitted changes
    repo-has-changes?: func [path [file!]] [
        out: ""
        cmd: rejoin ["cd " to-string path " && git status --porcelain 2>&1"]
        attempt [call/output/shell cmd out]
        not empty? trim out
    ]
]
