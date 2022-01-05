// RUN: %empty-directory(%t)
// RUN: mkdir -p %t
// RUN: cd %t
// RUN: cp %s .
// RUN: %target-swift-frontend -g \
// RUN:   -wmo -c -debug-compilation-dir path/to \
// RUN:   debug_compilation_dir_rel.swift -o - -emit-ir | %FileCheck %s

func foo() {}

// CHECK: !DIFile(filename: "debug_compilation_dir_rel.swift", directory: "path/to")