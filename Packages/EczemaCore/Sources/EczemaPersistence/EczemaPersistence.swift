// EczemaPersistence — the SwiftData store and the CloudKit account gate.
//
// Deliberately empty. The schema is additive-only once the CloudKit schema is promoted,
// so the first `@Model` written here is close to irreversible. It waits on the spec.
//
// Two constraints that shape this target when it is filled in:
//   - iCloud gates writing, never reading. The gate fires on `noAccount`/`restricted`
//     only — never on `temporarilyUnavailable`/`couldNotDetermine`.
//   - `CKAccountStatus` is five-valued. Collapsing it to a Bool is what produces an
//     airplane-mode wall.
