# Packages

All real code lives here. The app target is a `WindowGroup` and nothing else, permanently.

## The split, and why it is drawn here

[#699](https://github.com/jirigrill/eczema-helper/issues/699) settled *that* code lives in
local packages, not *which* packages. This is the proposal.

| Package | Targets | Ships to |
| --- | --- | --- |
| `EczemaCore` | `EczemaDomain`, `EczemaCatalog`, `EczemaPersistence` | iOS + host |
| `EczemaUI` | `EczemaUI` | iOS |

`EczemaCore` holds one further target, `SchemaLoadProbe`, which ships nowhere: it is an
`executableTarget` and deliberately **not** a product, so nothing outside the package can build
it and the app cannot link it. It exists because `DATA-ARRIVE-10`'s schema-load test has to run
the mirroring-enabled `ModelContainer.init` in a *child process* — a failing schema aborts the
whole test process rather than throwing, and `Sources/SchemaLoadProbe/main.swift` records the
measurement behind that. Treat it as test apparatus that happens to need its own target.

**The seam is drawn where the verification strategy changes, not per feature.**

Everything in `EczemaCore` is verifiable by `swift test` on the host in seconds, with no
simulator boot: domain rules are pure, the catalog is static bundled data, and SwiftData
runs against an in-memory container. That is the loop that spec-derived tests live in, and
spec-derived tests are the durable verification layer here — the owner has no iOS
experience, so a test that only a human could have caught is a test that will not catch it.

`EczemaUI` is verified differently: by the simulator build, by UI automation with
per-step screenshots, and by a manual pass judging feel. Keeping it in a separate package
makes that a structural fact rather than a convention. The dependency arrow only ever
points `EczemaUI → EczemaCore`, and the package graph enforces it — `EczemaCore` cannot
import a view even by accident.

A feature-per-package split (`DayView`, `MealEditor`, `SkinObservation`, …) was rejected
for now. The spec sections are not yet confirmed, so those boundaries would be guesses,
and a wrong package boundary is considerably more expensive to move than a wrong folder.
Split further when a target gets painful, not before.

### Why `EczemaCore` declares macOS

So `swift test` runs on the host without a simulator. **iOS 26 is the only shipping
floor**; nothing may depend on macOS at runtime. `EczemaUI` declares it for the same
reason and no other — if a view there ever needs `#if os(iOS)` to compile, read that as
the signal that the logic under it belongs in `EczemaCore`, not as an invitation to
start supporting macOS.

### Strict settings

Every target in both packages is built with `strictSettings`. Swift 6 language mode — and
with it complete strict concurrency — already comes from `swift-tools-version: 6.2`, so
the list holds only the one thing that does not follow from the tools version:
`ExistentialAny`.

SwiftPM manifests cannot share code, so the declaration is repeated verbatim in both
`Package.swift` files. That repetition is the mechanism's, not a choice — but keep the
reasoning here only, so the two copies cannot drift into disagreeing about why they exist.
The app target gets the same settings a different way, through `Config/Base.xcconfig`;
`SWIFT_VERSION = 6.0` there is the language mode, which matches. Nothing enforces that
these three places agree, so **a new target starts by copying `strictSettings`.**

### No protocol seams

There are none, deliberately. Whether protocol DI is warranted *within* a package is
[explicitly still open on the map](https://github.com/jirigrill/eczema-helper/issues/672),
and the PWA's four ports each ended up with exactly one adapter — a seam the map records
as having been hypothetical there. Introduce one when a second implementation or an
untestable dependency actually shows up.

## The targets are still empty of behavior

No domain models, no views. `EczemaPersistence` holds `AppSchema` — the one place the schema
and its mirrored `ModelConfiguration` are declared — but `AppSchema.models` is an empty list, so
there is no schema yet either; the schema-load test reports that as a known issue rather than a
pass. `docs/spec/persistence-model.md` carries 80 `DATA-*` rules and the schema deadlines, and
[#767](https://github.com/jirigrill/eczema-helper/issues/767) collects the owner
confirmations still outstanding. The schema is **additive-only** once the CloudKit schema
is promoted, so the first `@Model` written here is close to irreversible.

Each target holds one file explaining what belongs in it and what must not.
