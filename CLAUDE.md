# CLAUDE.md

Guidance for AI agents working in this repository.

## Project Overview

A native iOS app for recording a breastfed infant's atopic eczema — meals eaten and per-region skin observations with photos. English-language, single child, one user (the mother), her phone plus her iCloud account.

**Status: scaffolded, no behavior.** The project builds and the test loop runs; nothing is implemented. `git ls-files` shows the `Eczema.xcodeproj`, `App/`, `Config/`, `Packages/`, `Justfile`, `.github/` and `.mcp.json` alongside the docs. Every package target is empty on purpose — no domain models, no SwiftData schema, no views. The behavior spec is being authored in `docs/spec/` ahead of the Apple Developer Program enrolment, so the spec does not wait on a payment.

**Tense rule for this file, because it will keep describing not-yet-built things.** Present indicative is reserved for what a `git ls-files` would show. Anything decided but unbuilt is written in the imperative or with **must** — never as an accomplished fact. Stating a safeguard already exists is what stops the next agent creating it.

**This is not a 1:1 port.** It is a new English-language product that uses a working Czech SvelteKit PWA as its behavior reference. "1:1" applies to **domain rules and invariants only** — never to code, strings, catalog, or UX. Do not port TypeScript idioms, Czech display text, or web layout.

## The frozen reference repo

The PWA lives at [`jirigrill/eczema-helper`](https://github.com/jirigrill/eczema-helper) and is **frozen** — stable history, no further code commits (docs commits stay permitted there). Do not open code PRs against it; the research merge exception ([#695](https://github.com/jirigrill/eczema-helper/issues/695)) is closed and done.

**Reference it by pointer; never copy from it.** A regulatory finding or invariant duplicated across two repos is a finding that goes stale in one of them.

**One exception, and it is deliberate: [`docs/spec/DECISIONS.md`](docs/spec/DECISIONS.md).** The nine decisions that shape the whole product are stated there in full — self-contained, readable without opening a single issue link — because this repo must stand on its own. Its links are provenance, never the content. Read it before proposing any change that a rule appears to invite; it will usually tell you why the obvious improvement was already rejected. It is not authoritative on behavior (the spec rules are), and it is **not** an ADR series or a decisions log — both were considered and declined ([#721](https://github.com/jirigrill/eczema-helper/issues/721)), so **do not create `docs/adr/` here.**

| What you need | Where it is |
|---|---|
| Domain invariants | `CONTEXT.md` in that repo — numbered `INV-1..14`, permanently stable ids with explicit HTML anchors. Cite as [`CONTEXT.md#inv-4`](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-4). Never restate an invariant's text. |
| Invariant-shaped rules with no number | ~15 more live in `CONTEXT.md` glossary prose (the `MealEditor` trio, Copy Meal's merge rules, `SkinObservation` identity, the catalog Principles) — deliberately unnumbered. Cite those **by heading**. |
| Live domain decision | `docs/adr/0028` (food-level preparations) — a domain rule the platform change does not touch, so it **ports intact**: preparation applicability lives on the food record, not on a coarse form bucket. Cite it from the catalog spec section. Not an invariant and deliberately not numbered — it is a food attribute. |
| **PWA-scoped history — reasoning only, never guidance** | `docs/adr/0001` (single-device) and `docs/adr/0029` (no crypto / no backup). Both remain **true of the PWA** and both were decided **the other way here**: this product syncs through a CloudKit private database, and CloudKit field encryption is available and cheap (`@Attribute(.allowsCloudEncryption)`, iOS 17+ — [#693](https://github.com/jirigrill/eczema-helper/issues/693)). Read them for the trade-offs they record; never as a constraint on this app. Each carries a `**Scope:**` line saying so ([#688](https://github.com/jirigrill/eczema-helper/issues/688)). The one limb that *does* still hold: no file export or import in v1 ([#683](https://github.com/jirigrill/eczema-helper/issues/683)) — same conclusion, different reason. |
| Meal-editor behavior | `docs/spec/meal-editor-state-machine.md` — already extracted; three cooperating state machines, not one |
| Regulatory + platform research | `docs/research/` — App Review 5.1.3(ii), CloudKit photo limits, CloudKit-unavailable behavior, DPIA, Art. 9 lawful basis, insurance, English catalog sources |
| Czech vocabulary | `UBIQUITOUS_LANGUAGE.md` — **not ported.** It freezes there. This repo has its own [`docs/spec/GLOSSARY.md`](docs/spec/GLOSSARY.md), holding only terms used by more than one spec section; area-local terms live in each section's §1. It is **not** seeded from `INV-1..14` — invariants are cited by anchor, not restated as vocabulary ([#707](https://github.com/jirigrill/eczema-helper/issues/707)). |

**Planning happens on the map, not here:** [Map: PWA → native iOS](https://github.com/jirigrill/eczema-helper/issues/672). File new planning tickets there as children of that map. Read the map before working — it carries every settled decision and its reasoning.

## Tech Stack

SwiftUI · SwiftData · CloudKit private database · Swift Testing / XCTest · `just` as the sole command interface. The project and the `just` interface are wired up; SwiftData and CloudKit are chosen but not yet used by any code.

**Xcode 27.0 (beta until ~2026-09-14 GM). Install exactly one Xcode** — with 26 and 27 co-installed, XcodeBuildMCP opens the beta-only Device Hub even when `DEVELOPER_DIR` selects stable.

### iOS 26 is the floor, and the compiler is the only thing that catches a violation

`IPHONEOS_DEPLOYMENT_TARGET = 26.0` is set in `Config/Base.xcconfig`, and the packages declare `.iOS(.v26)`. Never raise either to reach an API. iOS 26 is on 79% of all devices; an iOS 27 floor would ship to almost nobody.

**The Xcode 27 SDK exposes iOS 27 APIs.** An unguarded iOS 27 call is a compile error, occasionally a runtime crash — and it is the single most likely mistake an agent will make here, because it is a platform error the owner is not positioned to catch in review. Never reach for an API newer than iOS 26 without an availability guard. Build before you claim a change works.

## Project Structure

A **thin committed `Eczema.xcodeproj`** (`objectVersion = 100`) with filesystem-synchronized groups; all real code in local SwiftPM packages ([#699](https://github.com/jirigrill/eczema-helper/issues/699)). No project generator — XcodeGen cannot read Xcode 26+'s `objectVersion = 100`, and Tuist is more apparatus than this needs.

```
App/          the app target's synchronized group — one file, and it should stay that way
Config/       Base/Debug/Release .xcconfig + entitlements; the one static exception
Packages/     EczemaCore (Domain, Catalog, Persistence) and EczemaUI — see Packages/README.md
```

**Keep the app shell thin — permanently.** It is what makes both the editor path and the package test loop work; logic in a fat app target would make the effectively-unmaintained `xcode-build-server` a hard dependency.

Two structural constraints that must hold: avoid per-file exclusions and multi-target folder sharing. Both re-introduce explicit file enumeration in the `pbxproj` and defeat the point of synchronized groups — `just verify-project` asserts this and CI runs it. `Config/` is the one small static exception, because a build configuration has to name its `.xcconfig`. This is also why the app's `Info.plist` is generated (`GENERATE_INFOPLIST_FILE = YES`) and the entitlements live in `Config/` rather than `App/`: either one sitting inside the synchronized group would need a per-file membership exception.

## Commands

```bash
just build           # build the app for the iOS Simulator
just test            # swift test on the packages — no simulator boot, this is the fast loop
just verify-project  # assert the pbxproj is still filesystem-synchronized
just check           # all three, cheapest first. Run this before pushing.
```

CI runs the same recipes, but split across its two jobs rather than calling `just check`.

Run `just` for the full recipe list.

**Never pipe agent-facing build output through `xcbeautify`.** It is regex-based and fails *silently* — lines quietly stop being recognized, so you read a truncated failure as a pass and report success on a broken build. Read raw `xcodebuild` output or the `.xcresult`. `xcbeautify` is for human eyes only.

## Verification

The owner has **no iOS experience**, and reads Swift but is not an iOS reviewer — a platform mistake will not reliably be caught by reading your diff ([#702](https://github.com/jirigrill/eczema-helper/issues/702) Q13 overturned the earlier "cannot review Swift"; code review is available, and the catalog sign-off depends on it). That shapes everything:

1. **Spec-derived tests are the durable layer.** Every spec rule should fall out as a test.
2. **UI automation with per-step screenshots is the evidence layer** — for mechanical claims, e.g. a CTA label chain.
3. **The simulator build is required for merge** — it is the only automated proof a change compiles against the real iOS SDK. The `app` job runs it, and branch protection on `main` enforces it.
4. **A manual acceptance pass judging feel is a required layer**, alongside — not instead of — code review.

UI automation must never be the *only* gate: it leans on private frameworks and has broken across an Xcode major before. Losing it must degrade to unit tests, not to nothing.

**Report honestly.** If a build fails, say so with the output. If you skipped a step, say that. A confident wrong "it works" is worse here than in a repo whose owner reads the code.

## CI

`.github/workflows/ci.yml` runs two jobs, on `pull_request` and on `push` to `main`, with `permissions: contents: read` and **no secrets in the repo at all** (which structurally rules out fork-PR secret exposure):

1. `packages` — `swift test` on the SwiftPM packages.
2. `app` — asserts the project format, then builds for the iOS Simulator with `CODE_SIGNING_ALLOWED=NO`.

**Branch protection on `main` requires both jobs**, with `strict` (the branch must be up to date before merging). Force pushes and branch deletion are blocked; linear history is **not** required, so merge commits stay allowed. `enforce_admins` is off, so the owner keeps an override — treat using it as a decision, not a shortcut.

**The runner image is `xcode-27`** — macOS 26 with Xcode 27.0 as default, which is what gives machine/CI parity. The plain `macos-26` image carries only Xcode 26.0.1–26.6 (measured 2026-09-02) and cannot. `xcode-27` is a **preview** image ([actions/runner-images#14404](https://github.com/actions/runner-images/issues/14404)): it may queue longer and be less stable. **Never move to a `-large`/`-xlarge` runner**, `xcode-27-xlarge` included: standard runners are free and unlimited on public repos, larger ones are always billed, public repo or not.

`.github/scripts/select-xcode.sh` selects Xcode 27 and **warns loudly, rather than failing, when the runner image has no 27.** If that warning ever appears, read a green `app` job as weaker evidence: it means the build did not run against the pinned SDK, which is the whole reason 27 is pinned.

One measured consequence of running an older toolchain, kept because the fallback can still hit it: SwiftPM 6.3.3 (Xcode 26.6) *copies* a `.xcstrings` resource where Xcode 27 *compiles* it, so a localized key resolves to itself under `swift test`. Do not write a host test that asserts rendered localized text — that encodes a toolchain version rather than a property of the code.

The format assertions live in `just verify-project`. They are what keeps the project agent-editable:

```bash
grep -c 'in Sources' project.pbxproj    # must be 0
grep -c fileSystemSynchronized          # must be > 0
```

## Agent Tooling

**XcodeBuildMCP, pinned to `2.7.0`** — not `@latest`, which has shipped a breaking schema bump; unannounced breakage in a loop nobody can code-review is a bad failure mode. Upgrade deliberately.

`.mcp.json` pins it and enables exactly the `simulator` and `ui-automation` workflows (~6k context), sets `XCODEBUILDMCP_CONFIGURATION=Debug`, and opts telemetry out with `XCODEBUILDMCP_SENTRY_DISABLED=true`. It also presets `XCODEBUILDMCP_PROJECT_PATH` and `XCODEBUILDMCP_SCHEME` so tool calls need not repeat them. The pin, the two workflows, the `Debug` configuration and the telemetry opt-out must all survive any edit to that file.

## This repo is public

- **No credentials, container identifiers, team ids, or provisioning profiles in committed files.** Ever.
- The regulatory research is published verbatim by design — including a **known-open** compliance question (whether App Store 5.1.3(ii) reaches an app's own CloudKit private database; Apple has never answered it, see [#685](https://github.com/jirigrill/eczema-helper/issues/685)). Do not paper over it in docs; it is recorded as open on purpose.
- The README is marketing surface for regulatory purposes. The recording-not-finding rule applies to it verbatim.

## Data and Privacy

The app handles an **infant's health data**. Everything below is a constraint, not a preference.

- Records live in the mother's **CloudKit private database**. We have no backend and no access to her data.
- **CloudKit is sync, not backup.** It delivers delete-and-reinstall; it has no rollback. A deletion by user or bug propagates everywhere.
- **No export, no import, no PDF in v1** — decided knowingly, with the exposure accepted. Durability rests entirely on sync.
- **iCloud gates writing, never reading.** No record is created that CloudKit has not seen, but records already on the phone stay readable in every degraded state. The gate fires only on `noAccount`/`restricted` — never on `temporarilyUnavailable`/`couldNotDetermine`, so airplane mode and basements still log and upload on reconnect.
- Account state is **five-valued** (`CKAccountStatus`), not a boolean. Conflating the middle states is exactly what produces an airplane-mode wall.
- **CloudKit cannot enforce `@Attribute(.unique)` or cascade-delete**, and an app cannot supply its own `CKRecord` name. Uniqueness and cascades are application-layer obligations; two devices writing one logical slot produce **two records**, and the visible failure is a duplicate.
- **The schema is additive-only once the CloudKit schema is promoted.** A field never recorded cannot be backfilled. Weigh record shape carefully before the first release.
- **Never write a destructive migration.** The PWA wiped rows in four separate upgrade hooks. That policy does not carry over.

## The Food Catalog

No catalog exists in this repo yet; the decided shape is bundled static data **outside** the SwiftData store — no `@Model` for foods, no seeding, no reconcile-on-launch. `MealItem.foodId` must be the only catalog value the schema holds, and is therefore the only part on the schema deadline; every other catalog field stays revisable in any later release.

Ids must be **English kebab-case slugs** (`cow-milk`) because a human authors them and a reviewer must be able to check `cow-milk → [dairy]`. User records get UUIDs.

**Catalog and regulatory claims require primary sources — cite or don't claim.** The Czech catalog's provenance cannot be inherited (32 free-text comments, one reading `// no source for shellfish - ai generated only?`, and the cited PDFs are absent from git). The English catalog is a **fresh derivation with citations attached at authoring time**, never a review pass over the existing mappings.

## Conventions

- **English only**, but structured — a string catalog from commit one.
- **No UI display text on domain records.** The PWA persisted Czech labels onto records and fed them into a dirtiness key; do not repeat it.
- Skin levels are `Calm` / `Mild` / `Moderate` / `Severe`. *Witnessed* is a spec-only term for "she looked" — not a UI string.
- Human-only setup steps (accounts, payments, dashboards) get an **interactive wizard**, never prose instructions.

## When Modifying This Repo

Keep `docs/README.md` and this file accurate. When a decision is settled on the map, record it on its ticket — then reference it here by pointer if an agent needs it to work correctly.
