Red [
    Title:   "Validator (barricade) for redpm"
    Author:  "ANLACO"
    File:    %src/validator.red
    Purpose: {Sanitize and validate external inputs}
]

validator: context [

    ;-- Return true if value can be treated as a url!
    valid-url?: func [val [string! url!] /local res] [
        either url? val [true][
            res: attempt [to url! val]
            not none? res
        ]
    ]

    ;-- Basic package name validation: non-empty, no path traversal
    valid-package-name?: func [name [string!] /local s] [
        s: trim name
        if empty? s [return false]
        if find s ".." [return false]
        if find s "/" [return false]
        true
    ]

    ;-- Very small version-spec validator (tag/branch/commit)
    valid-version-spec?: func [v [string!]] [
        not empty? trim v
    ]

    ;-- Sanitize a path string to a file! (remove '..')
    sanitize-path: func [p [string!] /local s] [
        s: copy p
        replace/all s ".." ""
        to file! trim s
    ]
]
