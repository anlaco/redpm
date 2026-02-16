Red [
    Title:   "Package ADT for redpm"
    Author:  "ANLACO"
    File:    %src/package.red
    Purpose: {ADT and accessors to represent packages within redpm}
]

;-- Constructor + accessors for the `package` ADT
package: context [

    ;-- Create a package object (url is optional)
    make-package: func [
        name [string!]
        url  [url!] /optional
    ][
        ;-- Avoid collision: initialize fields then assign externally
        obj: make object! [
            name:    none
            url:     none
            version: "latest"
            status:  'missing
            path:    none
        ]
        obj/name: to-string name
        if url [obj/url: url]
        obj
    ]

    ;-- Accessors (read-only)
    get-name: func [pkg [object!]] [pkg/name]
    get-url:  func [pkg [object!]] [pkg/url]
    get-version: func [pkg [object!]] [pkg/version]
    get-status:  func [pkg [object!]] [pkg/status]
    get-path:    func [pkg [object!]] [pkg/path]

    ;-- Simple mutators
    set-path: func [pkg [object!] p [file!]] [pkg/path: p pkg]
    set-status: func [pkg [object!] s [word!]] [pkg/status: s pkg]

    ;-- Predicates
    installed?: func [pkg [object!]] [
        all [
            pkg/path not none
            either dir? pkg/path [true] [exists? pkg/path]
        ]
    ]
]
