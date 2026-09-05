// Deliberately invalid schemas — one per limb of `DATA-ARRIVE-9`, each breaching exactly its own
// limb. They are how `SchemaLoadProbeItself` proves the probe can still fail, so a green
// `SchemaLoad` is evidence rather than an assumption. Each carries the framework's measured
// rejection message, since none of these is caught at compile time.

import EczemaPersistence
import SwiftData

extension ProbeMode {
    /// The schema this mode loads. `app` is the real one; the rest must be rejected.
    var models: [any PersistentModel.Type] {
        switch self {
        case .app: AppSchema.models
        case .fixtureUniqueAttribute: [FixtureUnique.self]
        case .fixtureRequiredRelationship: [FixtureParent.self, FixtureChild.self]
        case .fixtureRefusingDeleteRule: [FixtureDenyParent.self, FixtureDenyChild.self]
        case .fixtureRequiredAttribute: [FixtureRequiredAttribute.self]
        }
    }
}

/// "CloudKit integration does not support unique constraints."
@Model final class FixtureUnique {
    @Attribute(.unique) var slug: String = ""
    init() {}
}

/// Non-optional to-many: "CloudKit integration requires that all relationships be optional".
@Model final class FixtureParent {
    @Relationship(deleteRule: .cascade) var children: [FixtureChild] = []
    init() {}
}

@Model final class FixtureChild {
    var parent: FixtureParent?
    init() {}
}

/// Optional to-many, so the delete rule is the only limb breached: "The following relationships are
/// configured with unsupported delete rules: FixtureDenyParent:children - Deny". `.deny` is rejected
/// local-only as well, which is why unmirroring the type cannot escape it.
@Model final class FixtureDenyParent {
    @Relationship(deleteRule: .deny) var children: [FixtureDenyChild]?
    init() {}
}

@Model final class FixtureDenyChild {
    var parent: FixtureDenyParent?
    init() {}
}

/// Neither optional nor defaulted. `DATA-ARRIVE-9` lists this limb last because it is observed
/// behavior only, with no vendor document behind it — which is exactly why it needs a fixture.
/// The framework attributes it to mirroring itself: "CloudKit integration requires that all
/// attributes be optional, or have a default value set. The following attributes are marked
/// non-optional but do not have a default value: FixtureRequiredAttribute: slug". A runtime message
/// is not a primary source, so the spec's caution stands — but the limb is measured here now rather
/// than inherited.
@Model final class FixtureRequiredAttribute {
    var slug: String
    init(slug: String) {
        self.slug = slug
    }
}
