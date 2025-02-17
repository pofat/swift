// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend-emit-module -emit-module-path %t/FakeDistributedActorSystems.swiftmodule -module-name FakeDistributedActorSystems -disable-availability-checking %S/../Inputs/FakeDistributedActorSystems.swift
// RUN: %target-swift-frontend -module-name remoteCall -primary-file %s -emit-sil -enable-experimental-distributed -disable-availability-checking -I %t | %FileCheck %s --enable-var-scope --color --dump-input=always
// REQUIRES: concurrency
// REQUIRES: distributed

import _Distributed
import FakeDistributedActorSystems

typealias DefaultDistributedActorSystem = FakeActorSystem

distributed actor MyDistActor {
  distributed func test() {}
}

// TODO(distributed): very naive test, SIL for discussion and cleanup

// CHECK: // MyDistActor.test()
// CHECK: sil hidden [thunk] [distributed] @$s10remoteCall11MyDistActorC4testyyFTE : $@convention(method) @async (@guaranteed MyDistActor) -> @error Error {
// CHECK: // %0 "self" // users: %34, %28, %7, %40, %39, %1
// CHECK: bb0(%0 : $MyDistActor):
// CHECK:  %1 = init_existential_ref %0 : $MyDistActor : $MyDistActor, $AnyObject // user: %3
// CHECK:  // function_ref swift_distributed_actor_is_remote
// CHECK:  %2 = function_ref @swift_distributed_actor_is_remote : $@convention(thin) (@guaranteed AnyObject) -> Bool // user: %3
// CHECK:  %3 = apply %2(%1) : $@convention(thin) (@guaranteed AnyObject) -> Bool // user: %4
// CHECK:  %4 = struct_extract %3 : $Bool, #Bool._value // user: %5
// CHECK:  cond_br %4, bb1, bb4 // id: %5

// CHECK: bb1: // Preds: bb0
// CHECK:  %6 = alloc_stack $FakeInvocation // users: %13, %60, %53, %37, %14
// CHECK:  %7 = ref_element_addr %0 : $MyDistActor, #MyDistActor.actorSystem // user: %8
// CHECK:  %8 = load %7 : $*FakeActorSystem // users: %12, %11, %9
// CHECK:  retain_value %8 : $FakeActorSystem // id: %9
// CHECK:  // function_ref FakeActorSystem.makeInvocationEncoder()
// CHECK:  %10 = function_ref @$s27FakeDistributedActorSystems0aC6SystemV21makeInvocationEncoderAA0aG0VyF : $@convention(method) (@guaranteed FakeActorSystem) -> FakeInvocation // user: %11
// CHECK:  %11 = apply %10(%8) : $@convention(method) (@guaranteed FakeActorSystem) -> FakeInvocation // user: %13
// CHECK:  release_value %8 : $FakeActorSystem // id: %12
// CHECK:  store %11 to %6 : $*FakeInvocation // id: %13
// CHECK:  %14 = begin_access [modify] [static] %6 : $*FakeInvocation // users: %56, %50, %34, %36, %16
// CHECK:  // function_ref FakeInvocation.doneRecording()
// CHECK:  %15 = function_ref @$s27FakeDistributedActorSystems0A10InvocationV13doneRecordingyyKF : $@convention(method) (@inout FakeInvocation) -> @error Error // user: %16
// CHECK:  try_apply %15(%14) : $@convention(method) (@inout FakeInvocation) -> @error Error, normal bb2, error bb3 // id: %16

// CHECK: bb2(%17 : $()): // Preds: bb1
// CHECK:  %18 = alloc_stack $RemoteCallTarget // users: %59, %58, %52, %51, %34, %27
// CHECK:  %19 = metatype $@thin RemoteCallTarget.Type // user: %27
// CHECK:  %20 = string_literal utf8 "$s10remoteCall11MyDistActorC4testyyFTE" // user: %25
// CHECK:  %21 = integer_literal $Builtin.Word, 38 // user: %25
// CHECK:  %22 = integer_literal $Builtin.Int1, -1 // user: %25
// CHECK:  %23 = metatype $@thin String.Type // user: %25
// CHECK:  // function_ref String.init(_builtinStringLiteral:utf8CodeUnitCount:isASCII:)
// CHECK:  %24 = function_ref @$sSS21_builtinStringLiteral17utf8CodeUnitCount7isASCIISSBp_BwBi1_tcfC : $@convention(method) (Builtin.RawPointer, Builtin.Word, Builtin.Int1, @thin String.Type) -> @owned String // user: %25
// CHECK:  %25 = apply %24(%20, %21, %22, %23) : $@convention(method) (Builtin.RawPointer, Builtin.Word, Builtin.Int1, @thin String.Type) -> @owned String // user: %27
// CHECK:  // function_ref RemoteCallTarget.init(_mangledName:)
// CHECK:  %26 = function_ref @$s12_Distributed16RemoteCallTargetV12_mangledNameACSS_tcfC : $@convention(method) (@owned String, @thin RemoteCallTarget.Type) -> @out RemoteCallTarget // user: %27
// CHECK:  %27 = apply %26(%18, %25, %19) : $@convention(method) (@owned String, @thin RemoteCallTarget.Type) -> @out RemoteCallTarget
// CHECK:  %28 = ref_element_addr %0 : $MyDistActor, #MyDistActor.actorSystem // user: %29
// CHECK:  %29 = load %28 : $*FakeActorSystem // users: %57, %49, %34, %30
// CHECK:  retain_value %29 : $FakeActorSystem // id: %30
// CHECK:  %31 = metatype $@thick Never.Type // user: %34
// CHECK:  %32 = metatype $@thick ().Type
// CHECK:  // function_ref FakeActorSystem.remoteCallVoid<A, B>(on:target:invocation:throwing:)
// CHECK:  %33 = function_ref @$s27FakeDistributedActorSystems0aC6SystemV14remoteCallVoid2on6target10invocation8throwingyx_01_B006RemoteG6TargetVAA0A10InvocationVzq_mtYaKAI0bC0Rzs5ErrorR_AA0C7AddressV2IDRtzr0_lF : $@convention(method) @async <τ_0_0, τ_0_1 where τ_0_0 : DistributedActor, τ_0_1 : Error, τ_0_0.ID == ActorAddress> (@guaranteed τ_0_0, @in_guaranteed RemoteCallTarget, @inout FakeInvocation, @thick τ_0_1.Type, @guaranteed FakeActorSystem) -> @error Error // user: %34
// CHECK:  try_apply %33<MyDistActor, Never>(%0, %18, %14, %31, %29) : $@convention(method) @async <τ_0_0, τ_0_1 where τ_0_0 : DistributedActor, τ_0_1 : Error, τ_0_0.ID == ActorAddress> (@guaranteed τ_0_0, @in_guaranteed RemoteCallTarget, @inout FakeInvocation, @thick τ_0_1.Type, @guaranteed FakeActorSystem) -> @error Error, normal bb8, error bb9 // id: %34

// CHECK: // %35 // user: %38
// CHECK: bb3(%35 : $Error): // Preds: bb1
// CHECK:  end_access %14 : $*FakeInvocation // id: %36
// CHECK:  dealloc_stack %6 : $*FakeInvocation // id: %37
// CHECK:  br bb7(%35 : $Error) // id: %38

// CHECK: bb4: // Preds: bb0
// CHECK:  %39 = class_method %0 : $MyDistActor, #MyDistActor.test : (isolated MyDistActor) -> () -> (), $@convention(method) (@guaranteed MyDistActor) -> () // user: %40
// CHECK:  %40 = apply %39(%0) : $@convention(method) (@guaranteed MyDistActor) -> () // user: %42
// CHECK:  br bb5 // id: %41

// CHECK: bb5: // Preds: bb4
// CHECK:  br bb6(%40 : $()) // id: %42

// CHECK: // %43 // user: %44
// CHECK: bb6(%43 : $()): // Preds: bb8 bb5
// CHECK:  return %43 : $() // id: %44

// CHECK: // %45 // user: %46
// CHECK: bb7(%45 : $Error): // Preds: bb9 bb3
// CHECK:  throw %45 : $Error // id: %46

// CHECK: bb8(%47 : $()): // Preds: bb2
// CHECK:  %48 = tuple () // user: %54
// CHECK:  release_value %29 : $FakeActorSystem // id: %49
// CHECK:  end_access %14 : $*FakeInvocation // id: %50
// CHECK:  destroy_addr %18 : $*RemoteCallTarget // id: %51
// CHECK:  dealloc_stack %18 : $*RemoteCallTarget // id: %52
// CHECK:  dealloc_stack %6 : $*FakeInvocation // id: %53
// CHECK:  br bb6(%48 : $()) // id: %54

// CHECK: // %55 // user: %61
// CHECK: bb9(%55 : $Error): // Preds: bb2
// CHECK:  end_access %14 : $*FakeInvocation // id: %56
// CHECK:  release_value %29 : $FakeActorSystem // id: %57
// CHECK:  destroy_addr %18 : $*RemoteCallTarget // id: %58
// CHECK:  dealloc_stack %18 : $*RemoteCallTarget // id: %59
// CHECK:  dealloc_stack %6 : $*FakeInvocation // id: %60
// CHECK:  br bb7(%55 : $Error) // id: %61
// CHECK: } // end sil function '$s10remoteCall11MyDistActorC4testyyFTE'
