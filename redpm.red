Red [
    Title:   "Red Package Manager"
    Author:  "ANLACO"
    File:    %redpm.red
    Version: 0.1.0
    Purpose: {
        Simple package manager for Red.
        Manages dependencies from Git repositories.
    }
]

#include %deps/Red-Utils/Red-Utils.red

;-- Configuration
deps-dir: %deps/
deps-file: %package.red

;-- Colors (ANSI)
green: "^[[32m"
red: "^[[31m"
yellow: "^[[33m"
cyan: "^[[36m"
reset: "^[[0m"

;-- Helper functions
print-ok: func [msg] [print rejoin [green "✓ " reset msg]]
print-err: func [msg] [print rejoin [red "✗ " reset msg]]
print-info: func [msg] [print rejoin [cyan "→ " reset msg]]
print-warn: func [msg] [print rejoin [yellow "! " reset msg]]

;-- Check if git is available
check-git: does [
    result: ""
    call/output "git --version" result
    either find result "git version" [true][
        print-err "Git not found. Please install git."
        false
    ]
]

;-- Load dependencies file
load-deps: func [/local data] [
    unless exists? deps-file [
        print-err rejoin ["Dependencies file not found: " deps-file]
        print-info "Create a package.red file with your dependencies"
        print ""
        print "Example package.red:"
        print "["
        print {    Red-Utils "https://github.com/ANLACO/Red-Utils"}
        print "]]"
        return none
    ]
    attempt [load deps-file]
]

;-- Parse dependencies into pairs [name url ...]
parse-deps: func [deps /local result name url] [
    result: copy []
    foreach [name url] deps [
        append result reduce [to-string name url]
    ]
    result
]

;-- Install a single package
install-package: func [name url /local target cmd] [
    target: deps-dir/:name/(#"/")
    
    either exists? target [
        print-warn rejoin [name " already installed, skipping"]
        return true
    ][
        print-info rejoin ["Installing " name "..."]
        cmd: rejoin ["git clone --depth 1 " url " " to-string target " 2>&1"]
        call/wait/shell cmd
        
        either exists? target [
            print-ok rejoin [name " installed"]
            true
        ][
            print-err rejoin ["Failed to install " name]
            false
        ]
    ]
]

;-- Update a single package
update-package: func [name /local target cmd result] [
    target: deps-dir/:name/(#"/")
    
    unless exists? target [
        print-err rejoin [name " not installed"]
        return false
    ]
    
    print-info rejoin ["Updating " name "..."]
    cmd: rejoin ["cd " to-string target " && git pull 2>&1"]
    result: ""
    call/output/shell cmd result
    
    either find result "Already up to date" [
        print-ok rejoin [name " already up to date"]
    ][
        print-ok rejoin [name " updated"]
    ]
    true
]

;-- Remove a single package
remove-package: func [name /local target cmd] [
    target: deps-dir/:name/(#"/")
    unless exists? target [
        print-err rejoin [name " not installed"]
        return false
    ]
    
    print-info rejoin ["Removing " name "..."]
    
    attempt [
        delete-dir target
    ]
    either all [
        exists? target
        (length? read target) > 1
    ][
        print-err rejoin ["Failed to remove " name]
        false
    ][
        print-ok rejoin [name " removed"]
        true
    ]
]

;-- Commands
cmd-install: func [/local deps pairs] [
    print "Installing dependencies..."
    print ""
    
    deps: load-deps
    unless deps [quit]
    
    unless exists? deps-dir [
        call/wait/shell rejoin ["mkdir -p " to-string deps-dir]
    ]
    
    pairs: parse-deps deps
    foreach [name url] pairs [
        install-package name url
    ]
    
    print ""
    print-ok "Done!"
]

cmd-update: func [/local deps pairs] [
    print "Updating dependencies..."
    print ""
    
    deps: load-deps
    unless deps [quit]
    
    pairs: parse-deps deps
    foreach [name url] pairs [
        update-package name
    ]
    
    print ""
    print-ok "Done!"
]

cmd-remove: func [name /local] [
    probe name
    either name [
        remove-package name
    ][
        print-err "Usage: redpm remove <package-name>"
    ]
]

cmd-list: func [/local deps pairs target] [
    deps: load-deps
    unless deps [quit]
    
    print "Dependencies:"
    print ""
    
    pairs: parse-deps deps
    foreach [name url] pairs [
        target: deps-dir/:name/(#"/")
        either exists? target [
            print rejoin ["  " green "●" reset " " name " (" url ")"]
        ][
            print rejoin ["  " red "○" reset " " name " (not installed)"]
        ]
    ]
    print ""
]

cmd-init: func [] [
    either exists? deps-file [
        print-warn "package.red already exists"
    ][
        write deps-file {[
    ;-- Add your dependencies here
    ;-- Format: PackageName "https://github.com/user/repo"
    
    ;-- Example:
    Red-Utils "https://github.com/ANLACO/Red-Utils"
]}
        print-ok "Created package.red"
        print-info "Edit package.red to add your dependencies"
    ]
]

cmd-help: does [
    print ""
    print "redpm - Red Package Manager v0.1.0"
    print "=================================="
    print ""
    print "Usage: ./redpm <command> [args]"
    print ""
    print "Commands:"
    print "  init      Create a new package.red file"
    print "  install   Install all dependencies from package.red"
    print "  update    Update all installed dependencies"
    print "  remove    Remove a specific package"
    print "  list      List all dependencies and their status"
    print "  help      Show this help message"
    print ""
    print "Example workflow:"
    print "  1. ./redpm init              # Create deps.red"
    print "  2. Edit deps.red             # Add dependencies"
    print "  3. ./redpm install           # Install them"
    print ""
]

;-- Main
main: func [/local args cmd] [
    args: system/options/args
    
    either empty? args [
        cmd-help
    ][
        unless check-git [quit]
        
        cmd: first args
        
        switch cmd [
            "init"    [cmd-init]
            "install" [cmd-install]
            "update"  [cmd-update]
            "remove"  [cmd-remove pick args 2]
            "list"    [cmd-list]
            "help"    [cmd-help]
            "--help"  [cmd-help]
            "-h"      [cmd-help]
        ]
    ]
]

main
