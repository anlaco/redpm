Red [
    Title:   "Filesystem utilities for redpm"
    Author:  "ANLACO"
    File:    %src/filesystem.red
    Purpose: {Cross-platform directory and file helpers}
]

#include %logger.red

filesystem: context [

    ;-- Ensure directory exists (create parents when needed)
    ;-- Use `exists?` to check the filesystem, not `dir?` (which only
    ;-- indicates a directory `file!` format). Returns true on success.
    ensure-dir: func [path [file!]] [
        either exists? path [true][
            attempt [make-dir path]
            exists? path
        ]
    ]

    ;-- Remove directory recursively (absorbs Red-Utils/delete-dir behavior)
    remove-dir: func [path [file!] /local contents] [
        ;-- Normalize and debug (debug-level only)
        logger/log-debug rejoin ["remove-dir called on: " to-string path " exists?: " to-string exists? path]
        if not exists? path [path: append path #"/"]

        ;-- Read directory contents (may return none for empty dirs)
        contents: attempt [read path]
        if none? contents [contents: copy []]

        attempt [
            foreach item contents [
                either dir? path/:item [filesystem/remove-dir path/:item][delete path/:item]
            ]
            delete path
        ]

        ;-- Final check: success if directory no longer exists
        not exists? path
    ]

    ;-- Check directory existence (checks the real filesystem)
    dir-exists?: func [path [file!]] [exists? path]

    ;-- List subdirectories (returns block!)
    ;-- Detect directories by attempting to `read` each entry; `read` on a
    ;-- directory returns a block, on a file returns a string.
    list-subdirs: func [path [file!] /local blk contents cand r] [
        blk: copy []
        contents: attempt [read path]
        if none? contents [return copy []]
        foreach item contents [
            cand: path/:item
            r: attempt [read cand]
            if block? r [append blk item]
        ]
        blk
    ]
]
