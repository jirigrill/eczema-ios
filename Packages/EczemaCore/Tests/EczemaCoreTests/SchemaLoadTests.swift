import Testing

@testable import EczemaPersistence
@testable import SchemaLoadProbe

/// `DATA-ARRIVE-10` — the real schema loads with CloudKit mirroring enabled.
///
/// The failure this guards is total and undiagnosable: a schema breaching one of mirroring's
/// constraints throws `SwiftDataError error 1` at container initialisation, so the app does not
/// launch, and the error names neither the model nor the property. No constraint is checked at
/// compile time. Validation precedes any network contact, so this needs no account, container or
/// connection.
///
/// The load runs in a child process for a measured reason recorded in `SchemaLoadProbe/main.swift`.
/// Two suites rather than one: `SchemaLoad` is the guard, and `SchemaLoadProbeItself` proves the
/// guard can fail — a test that cannot fail reports safety that was never checked.
@Suite struct SchemaLoad {
    @Test func realSchemaLoadsWithMirroringEnabled() throws {
        let result = try SchemaLoadProbeRunner.run(mode: .app)

        switch result.report {
        case .ok:
            break

        case .empty:
            // Neither a pass nor a schema failure: `AppSchema.models` is empty while the models are
            // on a spec deadline. Recorded so the run states out loud that it verified nothing — a
            // silent green here is the "test over three of four models" failure this test exists to
            // avoid. It clears itself when the first @Model is added; no change is needed here.
            withKnownIssue("AppSchema.models is empty — no schema was verified") {
                Issue.record("DATA-ARRIVE-10 is not yet being enforced: there is nothing to load.")
            }

        case .failed, .usage, .none:
            Issue.record(Comment(rawValue: result.diagnosis))
        }
    }

    /// `DATA-SCOPE-1` — the store holds exactly four record types. Loading "the schema" is only
    /// worth anything if the schema is the whole schema; a hand-assembled list that has drifted to
    /// three passes the load and still fails to launch the app. Dormant while the list is empty, and
    /// self-activating on the first `@Model` alongside the guard above.
    @Test func schemaHoldsEveryRecordTypeOrNoneYet() {
        #expect(
            AppSchema.models.isEmpty || AppSchema.models.count == 4,
            """
            AppSchema.models holds \(AppSchema.models.count) model(s). DATA-SCOPE-1 requires \
            exactly four — meal, meal item, skin observation, skin photo — so this list has either \
            dropped one, in which case SchemaLoad is verifying a schema the app does not use, or \
            gained a record type the spec does not allow.
            """
        )
    }
}

@Suite struct SchemaLoadProbeItself {
    /// One fixture per limb of `DATA-ARRIVE-9`, each breaching exactly that limb. If any stops
    /// failing, the probe has stopped detecting that class of violation and
    /// `realSchemaLoadsWithMirroringEnabled` is decoration for it. #28's acceptance asked for one
    /// deliberate breach "then revert"; keeping all four permanently is a deliberate step past that,
    /// since the reverted version only ever proves the guard worked once.
    @Test(arguments: ProbeMode.fixtures)
    func deliberatelyInvalidSchemaIsRejected(mode: ProbeMode) throws {
        let result = try SchemaLoadProbeRunner.run(mode: mode)

        #expect(
            result.report == .failed,
            """
            The probe accepted a schema that must be rejected under CloudKit mirroring \
            (\(mode.rawValue)). Either mirroring is no longer enabled by \
            AppSchema.configuration — which every mode here shares with the app — or the \
            constraint has changed. Until this fails as expected, SchemaLoad proves nothing.

            \(result.transcript)
            """
        )
    }

    /// The probe must never answer a malformed invocation with a schema verdict — a typo'd mode
    /// silently reported as OK is the one way this whole harness could pass while testing nothing.
    @Test func unknownModeIsAUsageErrorRatherThanAVerdict() throws {
        let result = try SchemaLoadProbeRunner.run(rawMode: "not-a-mode")
        #expect(result.report == .usage, "\n\(result.transcript)")
    }
}
