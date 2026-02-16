Red [
    Title:   "Manager for redpm (business logic)"
    Author:  "ANLACO"
    File:    %src/manager.red
    Purpose: {Orchestrates install/update/remove/list using lower-level contexts}
]

manager: context [

    ;-- Initialize project: create default deps.red via registry
    init: func [] [
        registry/create-default-config
    ]

    ;-- Install a single package (uses registry/filesystem/git-client)
    install-single: func [pkg [object!] /local name url target] [
        name: package/get-name pkg
        url:  package/get-url pkg

        unless validator/valid-package-name? name [
            logger/log-error rejoin [name " is not a valid package name"]
            return false
        ]
        unless validator/valid-url? url [
            logger/log-error rejoin [to-string url " is not a valid URL"]
            return false
        ]

        target: to file! rejoin [to-string registry/deps-dir "/" name "/"]
        filesystem/ensure-dir registry/deps-dir

        logger/log-info rejoin ["Installing " name "..."]
        unless git-client/clone-repo url target /shallow [
            logger/log-error rejoin ["Failed to install " name]
            return false
        ]

        package/set-path pkg target
        package/set-status pkg 'installed
        logger/log-ok rejoin [name " installed"]
        true
    ]

    ;-- Install all packages declared in deps.red
    install-all: func [/local pkgs pkg] [
        pkgs: registry/load-packages
        unless pkgs [
            logger/log-warn "No dependencies declared"
            return false
        ]
        filesystem/ensure-dir registry/deps-dir
        foreach pkg pkgs [
            either package/installed? pkg [
                logger/log-info rejoin [package/get-name pkg " already installed"]
            ][
                install-single pkg
            ]
        ]
        ;-- Optionally create/update lockfile here
        true
    ]

    ;-- Update a single package
    update-single: func [pkg [object!] /local name target result] [
        name: package/get-name pkg
        target: package/get-path pkg
        unless target [target: to file! rejoin [to-string registry/deps-dir "/" name "/"]]
        unless filesystem/dir-exists? target [
            logger/log-error rejoin [name " not installed"]
            return false
        ]
        result: git-client/pull-repo target
        unless result [
            logger/log-error rejoin ["Failed to pull " name]
            return false
        ]
        either find result "Already up to date" [
            logger/log-ok rejoin [name " already up to date"]
        ][
            logger/log-ok rejoin [name " updated"]
        ]
        true
    ]

    ;-- Update all packages
    update-all: func [/local pkgs pkg] [
        pkgs: registry/load-packages
        unless pkgs [
            logger/log-warn "No dependencies declared"
            return false
        ]
        foreach pkg pkgs [
            update-single pkg
        ]
        true
    ]

    ;-- Remove a single package
    remove-single: func [pkg [object!] /local name target] [
        name: package/get-name pkg
        target: either package/get-path pkg [package/get-path pkg][to file! rejoin [to-string registry/deps-dir "/" name "/"]]
        unless filesystem/dir-exists? target [
            logger/log-error rejoin [name " not installed"]
            return false
        ]
        logger/log-info rejoin ["Removing " name "..."]
        unless filesystem/remove-dir target [
            logger/log-error rejoin ["Failed to remove " name]
            return false
        ]
        logger/log-ok rejoin [name " removed"]
        true
    ]

    ;-- Remove by name (looks in registry first)
    remove-by-name: func [name [string!] /local pkgs found pkg] [
        pkgs: registry/load-packages
        unless pkgs [
            ; if no deps declared, still try to remove by path
            pkg: package/make-package name
            package/set-path pkg to file! rejoin [to-string registry/deps-dir "/" name "/"]
            return remove-single pkg
        ]
        found: none
        foreach p pkgs [if package/get-name p = name [found: p break]]
        if found [remove-single found][
            pkg: package/make-package name
            package/set-path pkg to file! rejoin [to-string registry/deps-dir "/" name "/"]
            remove-single pkg
        ]
    ]

    ;-- List declared dependencies (simple wrapper)
    list: func [/local pkgs pkg] [
        pkgs: registry/load-packages
        unless pkgs [
            logger/log-info "No dependencies declared"
            return false
        ]
        foreach pkg pkgs [
            either package/installed? pkg [
                logger/log-info rejoin ["  " package/get-name pkg " (installed)"]
            ][
                logger/log-info rejoin ["  " package/get-name pkg " (not installed)"]
            ]
        ]
        true
    ]
]
