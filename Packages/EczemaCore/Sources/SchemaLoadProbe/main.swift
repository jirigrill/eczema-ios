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
// The contract with the test — the modes it may ask for, and the exit code and stdout marker it
// gets back — is `ProbeContract.swift`, which the test target imports. It is stated there once so
// that neither end can hold a stale copy of it.
//
// CoreData writes the *useful* diagnostic ("CloudKit integration does not support unique
// constraints. The following entities are constrained: …") to stderr, not into the thrown
// error, which is only ever `loadIssueModelContainer` with no explanation. The test captures
// stderr and puts it in the failure message; that is where the naming of the offending model
// and property comes from.

import EczemaPersistence
import Foundation
import SwiftData

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

@Model final class FixtureDenyParent {
    // Optional to-many, so the only limb this fixture breaches is the delete rule: `.deny` is
    // rejected local-only as well, which is why it cannot be escaped by unmirroring the type.
    // Measured message: "The following relationships are configured with unsupported delete
    // rules: FixtureDenyParent:children - Deny".
    @Relationship(deleteRule: .deny) var children: [FixtureDenyChild]?
    init() {}
}

@Model final class FixtureDenyChild {
    var parent: FixtureDenyParent?
    init() {}
}

@Model final class FixtureRequiredAttribute {
    // Neither optional nor defaulted. DATA-ARRIVE-9 lists this limb last because it is observed
    // behavior only — no vendor *document* states it — which is exactly why it needs a fixture.
    // Measured here, the framework itself attributes it to mirroring: "CloudKit integration
    // requires that all attributes be optional, or have a default value set. The following
    // attributes are marked non-optional but do not have a default value: FixtureRequiredAttribute:
    // slug". That is a runtime message, not a primary source, so DATA-ARRIVE-9's caution stands —
    // but the limb is now measured in this repo rather than inherited.
    var slug: String
    init(slug: String) {
        self.slug = slug
    }
}

func finish(_ report: ProbeReport, detail: String = "") -> Never {
    print(report.marker + detail)
    fflush(stdout)
    // `exit` would run the same teardown the comment above describes and abort on the way
    // out even in the success case, turning a passing probe into a crashing one.
    _exit(report.exitCode)
}

let arguments = CommandLine.arguments.dropFirst()
guard arguments.count == 1, let mode = ProbeMode(rawValue: arguments[arguments.startIndex]) else {
    let modes = ProbeMode.allCases.map(\.rawValue).joined(separator: ", ")
    finish(.usage, detail: " expected exactly one mode, one of: \(modes)")
}

let models: [any PersistentModel.Type] = switch mode {
case .app: AppSchema.models
case .fixtureUniqueAttribute: [FixtureUnique.self]
case .fixtureRequiredRelationship: [FixtureParent.self, FixtureChild.self]
case .fixtureRefusingDeleteRule: [FixtureDenyParent.self, FixtureDenyChild.self]
case .fixtureRequiredAttribute: [FixtureRequiredAttribute.self]
}

// An empty schema is not a loadable one — the store rejects it with "the configuration named
// 'default' does not contain any entities" — and reporting that as a schema violation would be
// a false alarm for as long as the models are still on a spec deadline. It is reported as its
// own verdict so the test can say plainly that it verified nothing, rather than pass quietly.
guard !models.isEmpty else {
    finish(.empty)
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
    finish(.ok)
} catch {
    finish(.failed, detail: " \(error)")
}
