// RUN: %target-swiftc_driver -g \
// RUN:   -wmo -c -debug-compilation-dir /path/to \
// RUN:   %s -o - -emit-ir | %FileCheck %s

func foo() {}

// CHECK: !DIFile(filename: "{{.*}}/debug_compilation_dir.swift", directory: "/path/to")
