import Foundation
import Testing

@testable import EczemaPersistence

/// `DATA-ARRIVE-10` — the real schema loads with CloudKit mirroring enabled.
///
/// The failure this guards is total and undiagnosable: a schema that breaches one of
/// mirroring's constraints throws `SwiftDataError error 1` at container initialisation, so the
/// app does not launch and the error names neither the model nor the property. There is no
/// compile-time check for any of the constraints. Validation happens before any network
/// contact, so this needs no account, no container and no connection.
///
/// The load runs in a child process, and `SchemaLoadProbe/main.swift` records the measurement
/// that forces it to. Two suites here rather than one: `SchemaLoad` is the guard, and
/// `SchemaLoadProbeItself` proves the guard can fail — a test that cannot fail reports safety
/// that was never checked.
@Suite struct SchemaLoad {
    @Test func realSchemaLoadsWithMirroringEnabled() throws {
        let result = try SchemaLoadProbeRunner.run(mode: "app")

        switch result.verdict {
        case .ok:
            break

        case .empty:
            // Not a pass and not a failure of the schema: `AppSchema.models` is still empty
            // while the models are on a spec deadline. Recorded as a known issue so the run
            // states out loud that it verified nothing — a silent green here is exactly the
            // "test over three of four models" failure this test exists to avoid.
            withKnownIssue("AppSchema.models is empty — no schema was verified") {
                Issue.record(
                    """
                    AppSchema.models holds no models yet, so nothing was loaded and \
                    DATA-ARRIVE-10 is not yet being enforced. This stops being a known issue \
                    the moment the first @Model is added to \
                    Sources/EczemaPersistence/AppSchema.swift — no change is needed here.
                    """
                )
            }

        case .failed, .usage, .unrecognised:
            Issue.record(Comment(rawValue: result.diagnosis(loading: "the app's real schema")))
        }
    }
}

@Suite struct SchemaLoadProbeItself {
    /// Both fixtures breach a `DATA-ARRIVE-9` limb the vendor documents. If either stops
    /// failing, the probe has stopped detecting violations and `realSchemaLoadsWithMirroringEnabled`
    /// has become decoration.
    @Test(arguments: ["fixture-unique-attribute", "fixture-required-relationship"])
    func deliberatelyInvalidSchemaIsRejected(mode: String) throws {
        let result = try SchemaLoadProbeRunner.run(mode: mode)

        #expect(
            result.verdict == .failed,
            """
            The probe accepted a schema that must be rejected under CloudKit mirroring \
            (\(mode)). Either mirroring is not actually enabled in the probe's \
            ModelConfiguration, or the constraint has changed. Until this fails as expected, \
            SchemaLoad proves nothing.

            \(result.transcript)
            """
        )
    }

    /// The probe must never answer a malformed invocation with a schema verdict — a typo'd mode
    /// silently reported as OK is the one way this whole harness could pass while testing nothing.
    @Test func unknownModeIsAUsageErrorRatherThanAVerdict() throws {
        let result = try SchemaLoadProbeRunner.run(mode: "not-a-mode")
        #expect(result.verdict == .usage, "\n\(result.transcript)")
    }
}

// MARK: - Running the probe

/// Builds the `.app` wrapper the probe needs and runs it.
enum SchemaLoadProbeRunner {
    enum Verdict: Equatable {
        case ok
        case empty
        case failed
        case usage
        case unrecognised
    }

    struct Result {
        var verdict: Verdict
        var exitCode: Int32
        var standardOutput: String
        var standardError: String

        /// stderr matters more than the thrown error here: `SwiftDataError error 1` carries no
        /// explanation, and CoreData logs the text naming the offending entity and property to
        /// stderr instead.
        var transcript: String {
            var lines = ["exit code: \(exitCode)", "stdout:", standardOutput]
            if !standardError.isEmpty {
                lines.append(contentsOf: ["stderr:", standardError])
            }
            return lines.joined(separator: "\n")
        }

        /// The one place in this file where the wording matters more than the assertion.
        func diagnosis(loading subject: String) -> String {
            """
            The SwiftData schema failed to load with CloudKit mirroring enabled, loading \
            \(subject).

            This is a launch-time total failure: the app will not start, and the error names \
            neither the offending model nor the offending property. Every constraint below is \
            breachable without any compile-time warning. Check the schema against all four \
            (docs/spec/persistence-model.md, DATA-ARRIVE-9):

              1. no uniqueness constraint;
              2. no refusing delete rule — rejected local-only too, so it cannot be
                 escaped by unmirroring the type that carries it;
              3. no required relationship — every one optional or defaulted, to-many
                 included;
              4. no attribute that is neither optional nor defaulted. This one is
                 observed behavior only, not vendor-documented (DATA-ARRIVE-9's note).

            The stderr transcript below usually names the entity and property. Read it first — \
            it is the only diagnostic the platform gives.

            \(transcript)
            """
        }
    }

    static func run(mode: String) throws -> Result {
        let scratch = URL(fileURLWithPath: NSTemporaryDirectory())
            .appending(path: "schema-load-probe-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scratch) }

        let outputURL = scratch.appending(path: "stdout")
        let errorURL = scratch.appending(path: "stderr")

        let process = Process()
        process.executableURL = try wrappedProbeExecutableURL(inside: scratch)
        process.arguments = [mode]
        // Files rather than pipes, and this is not a style choice: reading one pipe to EOF
        // blocks until the child exits, and CoreData's mirroring diagnostics on the *other*
        // stream are large enough to fill its buffer — measured, the child then blocks in
        // `write` on stderr while the parent blocks reading stdout, and neither ever returns.
        // Concurrent reads would also work; files are simpler and the transcripts are small.
        process.standardOutput = try FileHandle(forWritingTo: created(outputURL))
        process.standardError = try FileHandle(forWritingTo: created(errorURL))

        try process.run()
        process.waitUntilExit()

        let standardOutput = try text(at: outputURL)
        return try Result(
            verdict: verdict(fromExitCode: process.terminationStatus, standardOutput: standardOutput),
            exitCode: process.terminationStatus,
            standardOutput: standardOutput,
            standardError: text(at: errorURL)
        )
    }

    private static func created(_ url: URL) throws -> URL {
        try Data().write(to: url)
        return url
    }

    /// Undecodable bytes become a note rather than an error: these transcripts are diagnostics,
    /// and losing the CoreData stderr text is the one thing that would leave a failure unreadable.
    private static func text(at url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return String(bytes: data, encoding: .utf8)
            ?? "<\(data.count) bytes, not valid UTF-8>"
    }

    /// The exit code and the stdout marker must agree. They can only disagree if the process
    /// died somewhere other than `finish` — a crash, a signal — and calling that a schema
    /// verdict would be a lie in whichever direction happened to be convenient.
    private static func verdict(fromExitCode code: Int32, standardOutput: String) -> Verdict {
        let marker = standardOutput
            .split(separator: "\n", omittingEmptySubsequences: true)
            .last
            .map(String.init) ?? ""

        switch (code, marker) {
        case (0, "SCHEMA-LOAD-OK"): return .ok
        case (3, "SCHEMA-LOAD-EMPTY"): return .empty
        case let (2, text) where text.hasPrefix("SCHEMA-LOAD-FAILED:"): return .failed
        case let (4, text) where text.hasPrefix("SCHEMA-PROBE-USAGE:"): return .usage
        default: return .unrecognised
        }
    }

    // MARK: The .app wrapper

    /// The probe binary, inside a minimal `.app` bundle.
    ///
    /// A bare SwiftPM executable has no `Bundle.main.bundleIdentifier`, and the mirroring
    /// teardown path asserts on exactly that — so without this wrapper a *failing* schema
    /// aborts the probe with SIGABRT and the error is never returned. The wrapper is one plist
    /// and one symlink, built fresh in the caller's own scratch directory: the tests here run in
    /// parallel, and a single shared wrapper path had them racing to create the same symlink.
    private static func wrappedProbeExecutableURL(inside scratch: URL) throws -> URL {
        let productsDirectory = URL(fileURLWithPath: Bundle(for: BundleAnchor.self).bundlePath)
            .deletingLastPathComponent()
        let probeBinary = productsDirectory.appending(path: executableName)

        guard FileManager.default.fileExists(atPath: probeBinary.path) else {
            throw ProbeUnavailable(
                """
                The SchemaLoadProbe executable is missing from \(productsDirectory.path). It is \
                declared as an executableTarget in Packages/EczemaCore/Package.swift and the \
                test target depends on it, so `swift test` should have built it.
                """
            )
        }

        let app = scratch.appending(path: "\(executableName).app")
        let macOS = app.appending(path: "Contents/MacOS")
        try FileManager.default.createDirectory(at: macOS, withIntermediateDirectories: true)

        try Data(infoPlist.utf8).write(to: app.appending(path: "Contents/Info.plist"))

        // A symlink rather than a copy, so the wrapper cannot go stale against a rebuilt binary.
        let wrapped = macOS.appending(path: executableName)
        try FileManager.default.createSymbolicLink(at: wrapped, withDestinationURL: probeBinary)

        return wrapped
    }

    private static let executableName = "SchemaLoadProbe"

    /// `CFBundleIdentifier` is the only key that matters — it is what PushKit asserts on. It is
    /// deliberately not the app's own identifier: this bundle is a test harness and must never
    /// be mistaken for the shipping app.
    private static let infoPlist = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>CFBundleIdentifier</key>
        <string>\(AppSchema.cloudKitContainerIdentifier).SchemaLoadProbe</string>
        <key>CFBundleExecutable</key>
        <string>\(executableName)</string>
        <key>CFBundleName</key>
        <string>\(executableName)</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
    </dict>
    </plist>
    """

    struct ProbeUnavailable: Error, CustomStringConvertible {
        var description: String
        init(_ description: String) {
            self.description = description
        }
    }
}

/// Objective-C class purely so `Bundle(for:)` can locate the test bundle, and through it the
/// build directory the probe was written to. SwiftPM offers no `Bundle.module` to a test target
/// without resources, and the environment carries no build path.
private final class BundleAnchor: NSObject {}
