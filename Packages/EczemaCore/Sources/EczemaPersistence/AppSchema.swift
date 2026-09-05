import SwiftData

/// The app's one and only `Schema`, and the `ModelConfiguration` that mirrors it.
///
/// Everything that opens the store goes through here, so that the schema loaded by
/// `DATA-ARRIVE-10`'s test and the schema loaded on her phone cannot be two different
/// things. A test over a hand-assembled list of models is a test of the list.
public enum AppSchema {
    /// Every model type the store holds — `DATA-SCOPE-1`: meal, meal item, skin
    /// observation, skin photo, and nothing else.
    ///
    /// **Empty on purpose.** The schema is additive-only once the CloudKit schema is
    /// promoted, so the first `@Model` written here is close to irreversible and waits on
    /// `docs/spec/persistence-model.md`'s deadlines. Add each model to this list as it
    /// lands; `SchemaLoad` then covers it with no further wiring.
    public static let models: [any PersistentModel.Type] = []

    /// The CloudKit container the private database is mirrored into. It is an address, not a
    /// credential — the same string is in `Config/Eczema.entitlements`, it grants access to
    /// nothing, and it ships inside the code signature of every build regardless.
    ///
    /// `CLAUDE.md`'s "no container identifiers in committed files. Ever." reads absolutely and
    /// this contradicts it, as `Config/Eczema.entitlements` and `docs/setup/signing-and-container.md`
    /// already do. Amending the rule is the owner's call, tracked in
    /// [#53](https://github.com/jirigrill/eczema-ios/issues/53) — this comment records the breach
    /// rather than settling it.
    ///
    /// **Naming it here is deliberate, and `.automatic` is not an option.** `.automatic`
    /// reads the container from the entitlements, which looks like the tidier choice — one
    /// authoritative home for the string. Measured, it silently disables mirroring wherever
    /// there is no entitlement to read: with `.automatic` in place, both deliberately invalid
    /// fixtures *loaded without complaint*, and a schema breaching a documented mirroring
    /// constraint was accepted. That turns `DATA-ARRIVE-10` into decoration — the worst
    /// available outcome, a guard that reports safety it never checked. The duplication with
    /// the entitlement is the lesser cost, and `SchemaLoadProbeItself` is what would catch
    /// the two drifting apart.
    public static let cloudKitContainerIdentifier = "iCloud.jirigrill.eczema"

    public static var schema: Schema {
        Schema(models)
    }

    /// The real configuration, with mirroring enabled. `inMemory` is the only thing the
    /// schema-load test changes about it, so the test exercises the configuration the app
    /// ships rather than a lookalike.
    public static func configuration(inMemory: Bool) -> ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .private(cloudKitContainerIdentifier)
        )
    }
}
