// SchemaLoadProbe — loads a schema with CloudKit mirroring enabled and reports whether it
// opened. It exists as a separate executable for one measured reason, recorded here because
// nothing about it is guessable from the code:
//
// Mirroring validation runs *inside* `ModelContainer.init`, and on the way out of a failed
// init the framework tears down a mirroring delegate that registers with PushKit. PushKit
// asserts on `Bundle.main.bundleIdentifier != nil`. Under `swift test` the main bundle is
// swiftpm's own test helper, which has no identifier, so a *failing* schema aborts the whole
// test process (SIGABRT) instead of throwing an error a test could catch — the error is
// raised, then the teardown kills the process before `catch` runs. Swizzling the identifier
// in was tried and only moves the abort to the next thing the app-less host lacks.
//
// So the init happens here, in a process the test wraps in a minimal `.app` bundle so that
// `Bundle.main.bundleIdentifier` is a real string. Then a failure is an ordinary caught error
// and an exit code, and the abort cannot take the test runner with it.
//
// The contract with the test is stdout's last line and the exit status:
//   0 / SCHEMA-LOAD-OK        the schema opened with mirroring enabled
//   2 / SCHEMA-LOAD-FAILED:   it did not, with the error's description appended
//   3 / SCHEMA-LOAD-EMPTY     the schema holds no models yet, so there was nothing to load
//   4 / SCHEMA-PROBE-USAGE:   the probe was invoked wrongly — never a schema verdict
//
// CoreData writes the *useful* diagnostic ("CloudKit integration does not support unique
// constraints. The following entities are constrained: …") to stderr, not into the thrown
// error, which is only ever `loadIssueModelContainer` with no explanation. The test captures
// stderr and puts it in the failure message; that is where the naming of the offending model
// and property comes from.

import EczemaPersistence
import Foundation
import SwiftData

/// Which schema to load. The fixtures are deliberately invalid under mirroring: they are how
/// the test proves the probe can fail, so a green run is evidence rather than an assumption.
enum ProbeMode: String, CaseIterable {
    /// The real thing — `AppSchema.models`, whatever it currently holds.
    case app

    /// Breaches `DATA-ARRIVE-9`'s "no uniqueness constraint" limb.
    case fixtureUniqueAttribute = "fixture-unique-attribute"

    /// Breaches its "no required relationship" limb.
    case fixtureRequiredRelationship = "fixture-required-relationship"
}

@Model final class FixtureUnique {
    @Attribute(.unique) var slug: String = ""
    init() {}
}

@Model final class FixtureParent {
    // Non-optional to-many: rejected with "CloudKit integration requires that all
    // relationships be optional".
    @Relationship(deleteRule: .cascade) var children: [FixtureChild] = []
    init() {}
}

@Model final class FixtureChild {
    var parent: FixtureParent?
    init() {}
}

func finish(_ line: String, code: Int32) -> Never {
    print(line)
    fflush(stdout)
    // `exit` would run the same teardown the comment above describes and abort on the way
    // out even in the success case, turning a passing probe into a crashing one.
    _exit(code)
}

let arguments = CommandLine.arguments.dropFirst()
guard arguments.count == 1, let mode = ProbeMode(rawValue: arguments[arguments.startIndex]) else {
    let modes = ProbeMode.allCases.map(\.rawValue).joined(separator: ", ")
    finish("SCHEMA-PROBE-USAGE: expected exactly one mode, one of: \(modes)", code: 4)
}

let models: [any PersistentModel.Type] = switch mode {
case .app: AppSchema.models
case .fixtureUniqueAttribute: [FixtureUnique.self]
case .fixtureRequiredRelationship: [FixtureParent.self, FixtureChild.self]
}

// An empty schema is not a loadable one — the store rejects it with "the configuration named
// 'default' does not contain any entities" — and reporting that as a schema violation would be
// a false alarm for as long as the models are still on a spec deadline. It is reported as its
// own verdict so the test can say plainly that it verified nothing, rather than pass quietly.
guard !models.isEmpty else {
    finish("SCHEMA-LOAD-EMPTY", code: 3)
}

do {
    // `AppSchema.configuration` rather than a ModelConfiguration assembled here, so that a
    // change to how the app enables mirroring cannot leave this probe testing the old shape.
    // The fixtures need their own, since their models are not in AppSchema.
    let schema = Schema(models)
    let configuration = mode == .app
        ? AppSchema.configuration(inMemory: true)
        : ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .private(AppSchema.cloudKitContainerIdentifier)
        )
    _ = try ModelContainer(for: schema, configurations: configuration)
    finish("SCHEMA-LOAD-OK", code: 0)
} catch {
    finish("SCHEMA-LOAD-FAILED: \(error)", code: 2)
}
