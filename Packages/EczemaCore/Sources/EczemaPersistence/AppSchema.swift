import SwiftData

/// The app's one and only `Schema`, and the `ModelConfiguration` that mirrors it.
///
/// Everything that opens the store goes through here, so that the schema loaded by
/// `DATA-ARRIVE-10`'s test and the schema loaded on her phone cannot be two different
/// things. A test over a hand-assembled list of models is a test of the list.
public enum AppSchema {
    /// Every model type the store holds — `DATA-SCOPE-1`'s four and nothing else: meal, meal item,
    /// skin observation, skin photo.
    ///
    /// **Empty on purpose.** The schema is additive-only once the CloudKit schema is promoted, so
    /// the first `@Model` here is close to irreversible and waits on
    /// `docs/spec/persistence-model.md`'s deadlines. Append each model as it lands; `SchemaLoad`
    /// then covers it with no further wiring.
    public static let models: [any PersistentModel.Type] = []

    /// The CloudKit container the private database mirrors into.
    ///
    /// **Named literally because `.automatic` is measurably unsafe here.** `.automatic` reads the
    /// container from the entitlements — tidier, one home for the string — but where there is no
    /// entitlement to read it disables mirroring *silently*: with it in place every invalid fixture
    /// loaded without complaint, so `DATA-ARRIVE-10` passed having validated nothing. A guard that
    /// reports unchecked safety is the worst outcome available, so the duplication with
    /// `Config/Eczema.entitlements` is the accepted lesser cost.
    ///
    /// **Recorded breach, not a settled question.** `CLAUDE.md`'s "no container identifiers in
    /// committed files. Ever." reads absolutely, and this contradicts it — as the entitlements and
    /// `docs/setup/signing-and-container.md` already do. It is an address rather than a credential
    /// (it grants nothing, and ships in every build's code signature regardless), but amending the
    /// rule is the owner's call: [#53](https://github.com/jirigrill/eczema-ios/issues/53).
    public static let cloudKitContainerIdentifier = "iCloud.jirigrill.eczema"

    public static var schema: Schema {
        Schema(models)
    }

    /// The one place mirroring is switched on, for every caller including the probe's fixtures.
    /// `schema` and `inMemory` are all a caller may vary, so nothing can exercise a lookalike
    /// configuration — turn mirroring off here and `SchemaLoadProbeItself` fails immediately.
    public static func configuration(for schema: Schema, inMemory: Bool) -> ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .private(cloudKitContainerIdentifier)
        )
    }
}
