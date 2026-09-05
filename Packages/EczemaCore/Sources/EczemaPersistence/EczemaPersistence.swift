// EczemaPersistence — the SwiftData store and the CloudKit account gate.
//
// Empty of behavior. `AppSchema.swift` is the one thing here so far: the single place the schema
// and its mirrored `ModelConfiguration` are declared, so the schema `DATA-ARRIVE-10`'s test loads
// and the schema on her phone cannot be two different things. `AppSchema.models` is still an empty
// list — the schema is additive-only once the CloudKit schema is promoted, so the first `@Model`
// written there is close to irreversible. It waits on the spec.
//
// Two constraints that shape this target when it is filled in:
//   - iCloud gates writing, never reading. The gate fires on `noAccount`/`restricted`
//     only — never on `temporarilyUnavailable`/`couldNotDetermine`.
//   - `CKAccountStatus` is five-valued. Collapsing it to a Bool is what produces an
//     airplane-mode wall.
