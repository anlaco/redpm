Red [
    Title:   "Red Package Manager"
    Author:  "ANLACO"
    File:    %redpm.red
    Version: 0.1.1
    Purpose: {
        Simple package manager for Red.
        Manages dependencies from Git repositories.
    }
]

#include %src/package.red
#include %src/logger.red
#include %src/git-client.red
#include %src/registry.red
#include %src/filesystem.red
#include %src/validator.red
#include %src/manager.red


;-- Commands
cmd-install: func [] [
    manager/install-all
]

cmd-update: func [] [
    manager/update-all
]

cmd-remove: func [name /local] [
    either name [
        manager/remove-by-name name
    ][
        logger/log-error "Usage: redpm remove <package-name>"
    ]
]

cmd-list: func [] [
    manager/list
]

cmd-init: func [] [
    manager/init
]

cmd-help: does [
    print ""
    print "redpm - Red Package Manager v0.1.1"
    print "=================================="
    print ""
    print "Usage: ./redpm <command> [args]"
    print ""
    print "Commands:"
    print "  init      Create a new deps.red file"
    print "  install   Install all dependencies from deps.red"
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
        unless git-client/git-available? [quit]
        
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
