// RUN: %target-run-simple-swift(-Xfrontend -enable-experimental-distributed -Xfrontend -disable-availability-checking -parse-as-library) | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: concurrency
// REQUIRES: distributed

// rdar://76038845
// UNSUPPORTED: use_os_stdlib
// UNSUPPORTED: back_deployment_runtime

import _Distributed

distributed actor SomeSpecificDistributedActor {

  distributed func hello() async throws {
     print("hello from \(self.id)")
  }

  distributed func echo(int: Int) async throws -> Int {
    int
  }
}

// ==== Execute ----------------------------------------------------------------

@_silgen_name("swift_distributed_actor_is_remote")
func __isRemoteActor(_ actor: AnyObject) -> Bool

func __isLocalActor(_ actor: AnyObject) -> Bool {
  return !__isRemoteActor(actor)
}

// ==== Fake Transport ---------------------------------------------------------

struct ActorAddress: Sendable, Hashable, Codable {
  let address: String
  init(parse address : String) {
    self.address = address
  }
}

struct FakeActorSystem: DistributedActorSystem {
  typealias ActorID = ActorAddress
  typealias InvocationDecoder = FakeInvocation
  typealias InvocationEncoder = FakeInvocation
  typealias SerializationRequirement = Codable

  func resolve<Act>(id: ActorID, as actorType: Act.Type) throws -> Act?
      where Act: DistributedActor,
            Act.ID == ActorID {
    return nil
  }

  func assignID<Act>(_ actorType: Act.Type) -> ActorID
      where Act: DistributedActor,
            Act.ID == ActorID {
    ActorAddress(parse: "")
  }

  func actorReady<Act>(_ actor: Act)
      where Act: DistributedActor,
            Act.ID == ActorID {
    print("\(#function):\(actor)")
  }

  func resignID(_ id: ActorID) {}

  func makeInvocationEncoder() -> InvocationEncoder {
    .init()
  }

  func remoteCall<Act, Err, Res>(
    on actor: Act,
    target: RemoteCallTarget,
    invocation invocationEncoder: inout InvocationEncoder,
    throwing: Err.Type,
    returning: Res.Type
  ) async throws -> Res
    where Act: DistributedActor,
//          Act.ID == ActorID,
    Err: Error,
    Res: SerializationRequirement {
    return "remoteCall: \(target.mangledName)" as! Res
  }

  func remoteCallVoid<Act, Err>(
    on actor: Act,
    target: RemoteCallTarget,
    invocation invocationEncoder: inout InvocationEncoder,
    throwing: Err.Type
  ) async throws
    where Act: DistributedActor,
//          Act.ID == ActorID,
    Err: Error {
    fatalError("not implemented \(#function)")
  }

}

struct FakeInvocation: DistributedTargetInvocationEncoder, DistributedTargetInvocationDecoder {
  typealias SerializationRequirement = Codable

  mutating func recordGenericSubstitution<T>(_ type: T.Type) throws {}
  mutating func recordArgument<Argument: SerializationRequirement>(_ argument: Argument) throws {}
  mutating func recordReturnType<R: SerializationRequirement>(_ type: R.Type) throws {}
  mutating func recordErrorType<E: Error>(_ type: E.Type) throws {}
  mutating func doneRecording() throws {}

  // === Receiving / decoding -------------------------------------------------

  func decodeGenericSubstitutions() throws -> [Any.Type] { [] }
  mutating func decodeNextArgument<Argument>(
    _ argumentType: Argument.Type,
    into pointer: UnsafeMutablePointer<Argument> // pointer to our hbuffer
  ) throws { /* ... */ }
  func decodeReturnType() throws -> Any.Type? { nil }
  func decodeErrorType() throws -> Any.Type? { nil }

  struct FakeArgumentDecoder: DistributedTargetInvocationArgumentDecoder {
    typealias SerializationRequirement = Codable
  }
}

typealias DefaultDistributedActorSystem = FakeActorSystem

// ==== Execute ----------------------------------------------------------------

func test_initializers() {
  let address = ActorAddress(parse: "")
  let system = DefaultDistributedActorSystem()

  _ = SomeSpecificDistributedActor(system: system)
  _ = try! SomeSpecificDistributedActor.resolve(id: address, using: system)
}

func test_address() {
  let system = DefaultDistributedActorSystem()

  let actor = SomeSpecificDistributedActor(system: system)
  _ = actor.id
}

func test_run(system: FakeActorSystem) async {
  let actor = SomeSpecificDistributedActor(system: system)

  print("before") // CHECK: before
  try! await actor.hello()
  print("after") // CHECK: after
}

func test_echo(system: FakeActorSystem) async {
  let actor = SomeSpecificDistributedActor(system: system)

  let echo = try! await actor.echo(int: 42)
  print("echo: \(echo)") // CHECK: echo: 42
}

@main struct Main {
  static func main() async {
    await test_run(system: FakeActorSystem())
    await test_echo(system: FakeActorSystem())
  }
}
