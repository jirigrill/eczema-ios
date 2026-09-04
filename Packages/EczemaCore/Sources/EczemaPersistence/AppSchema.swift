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

    /// The CloudKit container the private database is mirrored into. It is a public
    /// identifier, not a credential — the same string is in `Config/Eczema.entitlements`.
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
