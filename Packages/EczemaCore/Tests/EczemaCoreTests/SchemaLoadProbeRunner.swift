// Runs `SchemaLoadProbe` and reads its verdict. Harness only — the assertions are in
// `SchemaLoadTests.swift`.

import Foundation

@testable import SchemaLoadProbe

/// Builds the `.app` wrapper the probe needs and runs it.
enum SchemaLoadProbeRunner {
    struct Result {
        /// `nil` is unrecognised: exit code and stdout marker do not name the same report, so the
        /// probe died somewhere other than `finish`. See `ProbeReport.read`.
        var report: ProbeReport?
        var exitCode: Int32
        var standardOutput: String
        var standardError: String

        /// stderr matters more than the thrown error: `SwiftDataError error 1` carries no
        /// explanation, and CoreData logs the text naming the entity and property to stderr instead.
        var transcript: String {
            var lines = ["exit code: \(exitCode)", "stdout:", standardOutput]
            if !standardError.isEmpty {
                lines.append(contentsOf: ["stderr:", standardError])
            }
            return lines.joined(separator: "\n")
        }

        /// The one place wording matters more than the assertion — which is why it must not name a
        /// schema failure that did not happen. Anything other than `.failed` says the *harness*
        /// malfunctioned; reporting those as a bad schema would send the reader after a defect that
        /// is not there, the exact false attribution `ProbeReport.read` exists to make visible.
        var diagnosis: String {
            report == .failed ? schemaFailureDiagnosis : harnessFailureDiagnosis
        }

        private var harnessFailureDiagnosis: String {
            """
            The schema-load probe returned no verdict, so DATA-ARRIVE-10 was not checked on this \
            run. **This says nothing about the schema** — the probe itself did not report properly.

            Either it was invoked wrongly (SCHEMA-PROBE-USAGE), or its exit code and its stdout \
            marker disagree, meaning it died somewhere other than its own exit path — a crash or a \
            signal. Fix the harness, then read the schema verdict.

            \(transcript)
            """
        }

        private var schemaFailureDiagnosis: String {
            """
            The SwiftData schema failed to load with CloudKit mirroring enabled.

            This is a launch-time total failure: the app will not start, and the error names \
            neither the offending model nor the offending property. Every constraint below is \
            breachable with no compile-time warning. Check the schema against all four \
            (docs/spec/persistence-model.md, DATA-ARRIVE-9):

              1. no uniqueness constraint;
              2. no refusing delete rule — rejected local-only too, so it cannot be
                 escaped by unmirroring the type that carries it;
              3. no required relationship — every one optional or defaulted, to-many
                 included;
              4. no attribute that is neither optional nor defaulted. This one is
                 observed behavior only, not vendor-documented (DATA-ARRIVE-9's note).

            The stderr transcript below usually names the entity and property. Read it first — it \
            is the only diagnostic the platform gives.

            \(transcript)
            """
        }
    }

    static func run(mode: ProbeMode) throws -> Result {
        try run(rawMode: mode.rawValue)
    }

    /// Only `unknownModeIsAUsageErrorRatherThanAVerdict` passes a raw string, and that is the point:
    /// every other caller goes through `ProbeMode`, so a mode cannot be mistyped unwatched.
    static func run(rawMode mode: String) throws -> Result {
        let scratch = URL(fileURLWithPath: NSTemporaryDirectory())
            .appending(path: "schema-load-probe-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scratch) }

        let outputURL = scratch.appending(path: "stdout")
        let errorURL = scratch.appending(path: "stderr")

        let process = Process()
        process.executableURL = try wrappedProbeExecutableURL(inside: scratch)
        process.arguments = [mode]
        // Files rather than pipes, and not as a style choice: reading one pipe to EOF blocks until
        // the child exits, and CoreData's mirroring diagnostics on the *other* stream are large
        // enough to fill its buffer — measured, the child then blocks writing stderr while the
        // parent blocks reading stdout, and neither returns. Concurrent reads would also work;
        // files are simpler and the transcripts are small.
        process.standardOutput = try FileHandle(forWritingTo: emptyFile(at: outputURL))
        process.standardError = try FileHandle(forWritingTo: emptyFile(at: errorURL))

        try process.run()
        process.waitUntilExit()

        let standardOutput = try text(at: outputURL)
        return try Result(
            report: ProbeReport.read(
                exitCode: process.terminationStatus,
                lastLine: lastLine(of: standardOutput)
            ),
            exitCode: process.terminationStatus,
            standardOutput: standardOutput,
            standardError: text(at: errorURL)
        )
    }

    private static func emptyFile(at url: URL) throws -> URL {
        try Data().write(to: url)
        return url
    }

    /// Undecodable bytes become a note rather than an error: losing the CoreData stderr text is the
    /// one thing that would leave a failure unreadable.
    private static func text(at url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return String(bytes: data, encoding: .utf8) ?? "<\(data.count) bytes, not valid UTF-8>"
    }

    /// The marker is the *last* line, since CoreData may have written to stdout before it.
    private static func lastLine(of standardOutput: String) -> String {
        standardOutput.split(separator: "\n", omittingEmptySubsequences: true).last.map(String.init) ?? ""
    }

    // MARK: The .app wrapper

    /// The probe binary inside a minimal `.app`, which is what gives it the non-nil
    /// `Bundle.main.bundleIdentifier` the mirroring teardown asserts on — see `main.swift`'s header
    /// for the abort this avoids. One plist and one symlink, built fresh in the caller's own scratch
    /// directory: these tests run in parallel, and one shared wrapper path had them racing to
    /// create the same symlink.
    private static func wrappedProbeExecutableURL(inside scratch: URL) throws -> URL {
        let productsDirectory = URL(fileURLWithPath: Bundle(for: BundleAnchor.self).bundlePath)
            .deletingLastPathComponent()
        let probeBinary = productsDirectory.appending(path: executableName)

        guard FileManager.default.fileExists(atPath: probeBinary.path) else {
            throw ProbeUnavailable(
                """
                The SchemaLoadProbe executable is missing from \(productsDirectory.path). It is an \
                executableTarget in Packages/EczemaCore/Package.swift that this target depends on, \
                so `swift test` should have built it.
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

    /// `CFBundleIdentifier` is the only key that matters — it is what PushKit asserts on, and any
    /// non-nil string satisfies it. Deliberately unrelated to the app's identifier and to the
    /// CloudKit container's: this bundle is a test harness, it reaches no container, and a name
    /// borrowed from either would suggest it does.
    private static let bundleIdentifier = "test.eczema.SchemaLoadProbe"

    private static let infoPlist = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>CFBundleIdentifier</key>
        <string>\(bundleIdentifier)</string>
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

/// Objective-C class purely so `Bundle(for:)` can locate the test bundle, and through it the build
/// directory the probe was written to. SwiftPM offers no `Bundle.module` to a test target without
/// resources, and the environment carries no build path.
private final class BundleAnchor: NSObject {}
