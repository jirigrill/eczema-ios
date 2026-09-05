// The contract between the probe and the test that runs it, in one place rather than restated on
// each side. Previously the modes were raw strings at the call sites and the exit-code/marker
// pairing was written out three times — the header comment, the `finish` calls, and the test's
// reader — so changing a code meant three edits in two targets and nothing would have caught a
// missed one. `EczemaCoreTests` imports this target, so both ends now read the same values.

/// Which schema the probe loads. The fixtures are deliberately invalid under mirroring: they are
/// how the test proves the probe can still fail, so a green run is evidence rather than an
/// assumption. One per limb of `DATA-ARRIVE-9`, all four measured as rejected at load.
enum ProbeMode: String, CaseIterable {
    /// The real thing — `AppSchema.models`, whatever it currently holds.
    case app

    /// Breaches `DATA-ARRIVE-9`'s "no uniqueness constraint" limb.
    case fixtureUniqueAttribute = "fixture-unique-attribute"

    /// Breaches its "no required relationship" limb.
    case fixtureRequiredRelationship = "fixture-required-relationship"

    /// Breaches its "no refusing delete rule" limb.
    case fixtureRefusingDeleteRule = "fixture-refusing-delete-rule"

    /// Breaches its "no attribute that is neither optional nor defaulted" limb.
    case fixtureRequiredAttribute = "fixture-required-attribute"

    /// The modes that must fail. `app` is the one that must not.
    static var fixtures: [Self] {
        allCases.filter { $0 != .app }
    }
}

/// What the probe reports, as an exit code and the last line of stdout. Both are emitted, and the
/// reader requires them to agree: they can only disagree if the process died somewhere other than
/// `finish` — a crash, a signal — and calling that a schema verdict would be a lie in whichever
/// direction happened to be convenient.
enum ProbeReport: String, CaseIterable {
    /// The schema opened with mirroring enabled.
    case ok = "SCHEMA-LOAD-OK"

    /// It did not. The error's description follows the marker.
    case failed = "SCHEMA-LOAD-FAILED:"

    /// The schema holds no models yet, so there was nothing to load. Not a verdict on the schema.
    case empty = "SCHEMA-LOAD-EMPTY"

    /// The probe was invoked wrongly. Never a verdict on the schema either.
    case usage = "SCHEMA-PROBE-USAGE:"

    /// The marker the probe prints. The two that carry detail end in `:` and are read as prefixes.
    var marker: String {
        rawValue
    }

    var exitCode: Int32 {
        switch self {
        case .ok: 0
        case .failed: 2
        case .empty: 3
        case .usage: 4
        }
    }

    /// `nil` means unrecognised — the exit code and the marker do not name the same report.
    static func read(exitCode: Int32, lastLine: String) -> Self? {
        allCases.first { $0.exitCode == exitCode && lastLine.hasPrefix($0.marker) }
    }
}
