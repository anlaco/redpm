Red [
    Title:   "Logger for redpm"
    Author:  "ANLACO"
    File:    %src/logger.red
    Version: 0.1.0
    Purpose: {Encapsulates user output (colors and levels)}
]

logger: context [

    ;-- Color constants (exposed publicly for convenience)
    green:  "^[[32m"
    red:    "^[[31m"
    yellow: "^[[33m"
    cyan:   "^[[36m"
    reset:  "^[[0m"

    ;-- Quick check for --verbose / -v flag
    verbose?: func [] [any [find system/options/args "--verbose" find system/options/args "-v"]]

    ;-- Messaging: preserve existing visual prefixes
    log-ok: func [msg [string!]] [print rejoin [green "✓ " reset msg]]
    log-error: func [msg [string!]] [print rejoin [red "✗ " reset msg]]
    log-info: func [msg [string!]] [print rejoin [cyan "→ " reset msg]]
    log-warn: func [msg [string!]] [print rejoin [yellow "! " reset msg]]

    ;-- Only prints when the user requests verbose output
    log-debug: func [msg [string!]] [if verbose? [print rejoin [cyan "DBG " reset msg]]]

    ;-- Initializer (no-op for now; reserved for OS detection)
    init: func [] [true]
]
