// SchemaLoadProbe — loads a schema with CloudKit mirroring enabled and reports whether it opened.
//
// It is a separate executable for one measured reason, recorded because none of it is guessable:
// mirroring validation runs *inside* `ModelContainer.init`, and leaving a failed init the framework
// tears down a delegate that registers with PushKit, which asserts on a non-nil
// `Bundle.main.bundleIdentifier`. Under `swift test` the main bundle is swiftpm's test helper, which
// has none — so a *failing* schema SIGABRTs the whole test process before `catch` runs. (Swizzling
// an identifier in only moves the abort to the next thing an app-less host lacks.) Here the test can
// wrap the process in a minimal `.app`, and a failure becomes an ordinary exit code.
//
// The contract with the test — modes in, exit code and stdout marker out — is `ProbeContract.swift`,
// imported by the test target so neither end can hold a stale copy. Fixture schemas are
// `Fixtures.swift`.
//
// The thrown error is only ever `loadIssueModelContainer`, with no explanation. CoreData writes the
// *useful* text ("CloudKit integration does not support unique constraints. The following entities
// are constrained: …") to stderr; that is where the test's naming of model and property comes from.

import EczemaPersistence
import Foundation
import SwiftData

func finish(_ report: ProbeReport, detail: String = "") -> Never {
    print(report.rawValue + detail)
    fflush(stdout)
    // `exit` would run the same teardown described above and abort on the way out even on success,
    // turning a passing probe into a crashing one.
    _exit(report.exitCode)
}

let arguments = CommandLine.arguments.dropFirst()
guard arguments.count == 1, let mode = ProbeMode(rawValue: arguments[arguments.startIndex]) else {
    let modes = ProbeMode.allCases.map(\.rawValue).joined(separator: ", ")
    finish(.usage, detail: " expected exactly one mode, one of: \(modes)")
}

// An empty schema is not a loadable one — the store rejects it with "the configuration named
// 'default' does not contain any entities" — and reporting that as a schema violation would be a
// false alarm while the models are still on a spec deadline. Its own verdict, so the test can say
// plainly that it verified nothing rather than pass quietly.
guard !mode.models.isEmpty else {
    finish(.empty)
}

do {
    // Every mode, fixtures included, goes through `AppSchema.configuration`: it is the only thing
    // that enables mirroring, so it cannot be weakened for the app while the fixtures keep failing
    // against a stronger configuration assembled here and reporting a safety that no longer holds.
    let schema = Schema(mode.models)
    _ = try ModelContainer(for: schema, configurations: AppSchema.configuration(for: schema, inMemory: true))
    finish(.ok)
} catch {
    finish(.failed, detail: " \(error)")
}
