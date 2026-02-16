Red [
    Title:   "Package ADT smoke test"
    Author:  "ANLACO"
    File:    %tests/package-smoke.red
    Purpose: {Smoke test for src/package.red (ADT and accesors)}
]

#include %../src/package.red

print "Running package ADT smoke test..."

pkg: package/make-package "Red-Utils" "https://github.com/ANLACO/Red-Utils"
print rejoin ["name: " package/get-name pkg]
print rejoin ["url: " package/get-url pkg]
print rejoin ["version: " package/get-version pkg]

if package/installed? pkg [
    print "ERROR: package reported installed before path set"
    quit 1
]

;-- Use existing folder in repo for installed? check
package/set-path pkg %deps/Red-Utils/
print rejoin ["path set to: " to-string package/get-path pkg]
print rejoin ["mold path: " mold package/get-path pkg]
print rejoin ["exists?: " to-string exists? package/get-path pkg]
print rejoin ["dir?: " to-string dir? package/get-path pkg]

unless package/installed? pkg [
    print "ERROR: package/installed? returned false after setting existing path"
    quit 2
]

print "PACKAGE ADT smoke test: OK"
quit 0
