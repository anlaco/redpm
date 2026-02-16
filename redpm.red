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
#include %src/package.red
#include %src/logger.red

;-- Configuration
deps-dir: %deps/
deps-file: %deps.red

;-- Check if git is available
check-git: does [
    result: ""
    call/output "git --version" result
    either find result "git version" [true][
        logger/log-error "Git not found. Please install git."
        false
    ]
]

;-- Load dependencies file
load-deps: func [/local data] [
    unless exists? deps-file [
        logger/log-error rejoin ["Dependencies file not found: " deps-file]
        logger/log-info "Create a deps.red file with your dependencies"
        print ""
        print "Example deps.red:"
        print "["
        print {    Red-Utils "https://github.com/ANLACO/Red-Utils"}
        print "]]"
        return none
    ]
    attempt [load deps-file]
]

;-- Parse dependencies into package objects (ADT `package!`)
parse-deps: func [deps /local result name url pkg] [
    result: copy []
    foreach [name url] deps [
        pkg: package/make-package to-string name to-string url
        append result pkg
    ]
    result
]

;-- Install a single package (accepts package object)
install-package: func [pkg [object!] /local name url target cmd] [
    name: package/get-name pkg
    url:  package/get-url pkg
    target: deps-dir/:name/(#"/")
    
    either exists? target [
        logger/log-warn rejoin [name " already installed, skipping"]
        return true
    ][
        logger/log-info rejoin ["Installing " name "..."]
        cmd: rejoin ["git clone --depth 1 " url " " to-string target " 2>&1"]
        call/wait/shell cmd
        
        either exists? target [
            logger/log-ok rejoin [name " installed"]
            ;-- set path/status in ADT
            package/set-path pkg target
            package/set-status pkg 'installed
            true
        ][
            logger/log-error rejoin ["Failed to install " name]
            false
        ]
    ]
]

;-- Update a single package (accepts package object)
update-package: func [pkg [object!] /local name target cmd result] [
    name: package/get-name pkg
    target: deps-dir/:name/(#"/")
    
    unless exists? target [
        logger/log-error rejoin [name " not installed"]
        return false
    ]
    
    logger/log-info rejoin ["Updating " name "..."]
    cmd: rejoin ["cd " to-string target " && git pull 2>&1"]
    result: ""
    call/output/shell cmd result
    
    either find result "Already up to date" [
        logger/log-ok rejoin [name " already up to date"]
    ][
        logger/log-ok rejoin [name " updated"]
    ]
    true
]

;-- Remove a single package (accepts package object)
remove-package: func [pkg [object!] /local name target] [
    name: package/get-name pkg
    target: either package/get-path pkg [package/get-path pkg][deps-dir/:name/(#"/")]
    unless exists? target [
        logger/log-error rejoin [name " not installed"]
        return false
    ]
    
    logger/log-info rejoin ["Removing " name "..."]
    attempt [
        delete-dir target
    ]
    either all [
        exists? target
        (length? read target) > 1
    ][
        logger/log-error rejoin ["Failed to remove " name]
        false
    ][
        logger/log-ok rejoin [name " removed"]
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
        attempt [make-dir deps-dir]
    ]
    
    packages: parse-deps deps
    foreach pkg packages [
        install-package pkg
    ]
    
    print ""
    logger/log-ok "Done!"
]

cmd-update: func [/local deps pairs] [
    print "Updating dependencies..."
    print ""
    
    deps: load-deps
    unless deps [quit]
    
    packages: parse-deps deps
    foreach pkg packages [
        update-package pkg
    ]
    
    print ""
    logger/log-ok "Done!"
]

cmd-remove: func [name /local packages pkg found] [
    ;-- Verificar si se proporcionó un nombre de paquete
    either name [
        packages: load-deps
        unless packages [quit]
        packages: parse-deps packages
        ;-- Buscar el package declarado
        found: none
        foreach p packages [
            if package/get-name p = name [found: p break]
        ]
        if found [
            remove-package found
        ][
            ;-- No declarado: construir paquete temporal que apunte a deps/<name>/
            pkg: package/make-package to-string name
            package/set-path pkg deps-dir/:name/(#"/")
            remove-package pkg
        ]
    ][
        ;-- Si no se proporcionó, mostrar mensaje de uso
        logger/log-error "Usage: redpm remove <package-name>"
    ]
]

cmd-list: func [/local deps pairs target] [
    deps: load-deps
    unless deps [quit]
    
    print "Dependencies:"
    print ""
    
    packages: parse-deps deps
    foreach pkg packages [
        name: package/get-name pkg
        url:  package/get-url pkg
        target: deps-dir/:name/(#"/")
        either exists? target [
            print rejoin ["  " logger/green "●" logger/reset " " name " (" url ")"]
        ][
            print rejoin ["  " logger/red "○" logger/reset " " name " (not installed)"]
        ]
    ]
    print ""
]

cmd-init: func [] [
    either exists? deps-file [
        logger/log-warn "deps.red already exists"
    ][
        write deps-file {[
    ;-- Add your dependencies here
    ;-- Format: PackageName "https://github.com/user/repo"
    
    ;-- Example:
    Red-Utils "https://github.com/ANLACO/Red-Utils"
]}
        logger/log-ok "Created deps.red"
        logger/log-info "Edit deps.red to add your dependencies"
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
