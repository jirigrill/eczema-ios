// The probe↔test contract, in one place rather than restated on each side. The modes were once raw
// strings at the call sites and the exit-code/marker pairing was written out three times across two
// targets, so changing a code meant three edits and nothing would have caught a missed one.
// `EczemaCoreTests` imports this target, so both ends read these values.

/// Which schema the probe loads. Fixture schemas are in `Fixtures.swift`.
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

/// What the probe reports: this raw value is the last line of stdout, paired with an exit code. Both
/// are emitted and `read` requires them to agree — they can only disagree if the process died
/// somewhere other than `finish` (a crash, a signal), and calling that a schema verdict would be a
/// lie in whichever direction happened to be convenient.
enum ProbeReport: String, CaseIterable {
    /// The schema opened with mirroring enabled.
    case ok = "SCHEMA-LOAD-OK"

    /// It did not. The error's description follows the marker.
    case failed = "SCHEMA-LOAD-FAILED:"

    /// No models yet, so nothing was loaded. Not a verdict on the schema.
    case empty = "SCHEMA-LOAD-EMPTY"

    /// The probe was invoked wrongly. Never a verdict on the schema either.
    case usage = "SCHEMA-PROBE-USAGE:"

    var exitCode: Int32 {
        switch self {
        case .ok: 0
        case .failed: 2
        case .empty: 3
        case .usage: 4
        }
    }

    /// `nil` means unrecognised: the exit code and the marker do not name the same report. The two
    /// that carry detail end in `:`, so markers are matched as prefixes.
    static func read(exitCode: Int32, lastLine: String) -> Self? {
        allCases.first { $0.exitCode == exitCode && lastLine.hasPrefix($0.rawValue) }
    }
}
