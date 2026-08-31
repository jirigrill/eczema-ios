# CLAUDE.md

Guidance for AI agents working in this repository.

## Project Overview

A native iOS app for recording a breastfed infant's atopic eczema — meals eaten and per-region skin observations with photos. English-language, single child, one user (the mother), her phone plus her iCloud account.

**Status: docs only.** No Xcode project, no Swift, no CI, no `justfile` — `git ls-files` shows `CLAUDE.md`, `README.md`, `.gitignore` and `docs/`, nothing else. The behavior spec is being authored in `docs/spec/` ahead of the Apple Developer Program enrolment, so the spec does not wait on a payment.

**Tense rule for this file, because it will keep describing not-yet-built things.** Present indicative is reserved for what a `git ls-files` would show. Anything decided but unbuilt is written in the imperative or with **must** — never as an accomplished fact. Stating a safeguard already exists is what stops the next agent creating it.

**This is not a 1:1 port.** It is a new English-language product that uses a working Czech SvelteKit PWA as its behavior reference. "1:1" applies to **domain rules and invariants only** — never to code, strings, catalog, or UX. Do not port TypeScript idioms, Czech display text, or web layout.

## The frozen reference repo

The PWA lives at [`jirigrill/eczema-helper`](https://github.com/jirigrill/eczema-helper) and is **frozen** — stable history, no further code commits (docs commits stay permitted there). Do not open code PRs against it; the research merge exception ([#695](https://github.com/jirigrill/eczema-helper/issues/695)) is closed and done.

**Reference it by pointer; never copy from it.** A regulatory finding or invariant duplicated across two repos is a finding that goes stale in one of them.

**One exception, and it is deliberate: [`docs/spec/DECISIONS.md`](docs/spec/DECISIONS.md).** The six decisions that shape the whole product are stated there in full — self-contained, readable without opening a single issue link — because this repo must stand on its own. Its links are provenance, never the content. Read it before proposing any change that a rule appears to invite; it will usually tell you why the obvious improvement was already rejected. It is not authoritative on behavior (the spec rules are), and it is **not** an ADR series or a decisions log — both were considered and declined ([#721](https://github.com/jirigrill/eczema-helper/issues/721)), so **do not create `docs/adr/` here.**

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

The chosen stack, none of it yet wired up: SwiftUI · SwiftData · CloudKit private database · Swift Testing / XCTest · `just` as the sole command interface.

**Xcode 27.0 (beta until ~2026-09-14 GM). Install exactly one Xcode** — with 26 and 27 co-installed, XcodeBuildMCP opens the beta-only Device Hub even when `DEVELOPER_DIR` selects stable.

### iOS 26 is the floor, and the compiler is the only thing that catches a violation

Set `IPHONEOS_DEPLOYMENT_TARGET = 26.0` in the first commit that creates the project — nothing sets it today. iOS 26 is on 79% of all devices; an iOS 27 floor would ship to almost nobody.

**The Xcode 27 SDK exposes iOS 27 APIs.** An unguarded iOS 27 call is a compile error, occasionally a runtime crash — and it is the single most likely mistake an agent will make here, because it is a platform error the owner is not positioned to catch in review. Never reach for an API newer than iOS 26 without an availability guard. Build before you claim a change works.

## Project Structure

**None of this exists yet** — it is the decided shape for the scaffolding work ([#699](https://github.com/jirigrill/eczema-helper/issues/699)), not a description of the tree.

Build a **thin committed `.xcodeproj` with filesystem-synchronized groups; all real code in local SwiftPM packages.** No project generator (XcodeGen cannot read Xcode 26+'s `objectVersion = 100`; Tuist is more apparatus than this needs).

**Keep the app shell thin — permanently.** It is what makes both the editor path and the package test loop work; logic in a fat app target would make the effectively-unmaintained `xcode-build-server` a hard dependency.

Two structural constraints to hold while scaffolding: avoid per-file exclusions and multi-target folder sharing. Both re-introduce explicit file enumeration in the `pbxproj` and defeat the point of synchronized groups. One small static exception for `Config/*.xcconfig` is fine (no `Config/` directory exists yet).

## Commands

There is **no `justfile` yet** — none of these recipes run today. They land with the Xcode project, and these are the names to use when they do:

```bash
just build     # build for the iOS Simulator
just check     # build + type check
just test      # swift test on the packages
```

Run `just` for the full recipe list once it exists.

**Never pipe agent-facing build output through `xcbeautify`.** It is regex-based and fails *silently* — lines quietly stop being recognized, so you read a truncated failure as a pass and report success on a broken build. Read raw `xcodebuild` output or the `.xcresult`. `xcbeautify` is for human eyes only.

## Verification

The owner has **no iOS experience**, and reads Swift but is not an iOS reviewer — a platform mistake will not reliably be caught by reading your diff ([#702](https://github.com/jirigrill/eczema-helper/issues/702) Q13 overturned the earlier "cannot review Swift"; code review is available, and the catalog sign-off depends on it). That shapes everything:

1. **Spec-derived tests are the durable layer.** Every spec rule should fall out as a test.
2. **UI automation with per-step screenshots is the evidence layer** — for mechanical claims, e.g. a CTA label chain.
3. **The simulator build must be required for merge** once CI exists — it is the only automated proof a change compiles against the real iOS SDK. No branch protection is configured yet.
4. **A manual acceptance pass judging feel is a required layer**, alongside — not instead of — code review.

UI automation must never be the *only* gate: it leans on private frameworks and has broken across an Xcode major before. Losing it must degrade to unit tests, not to nothing.

**Report honestly.** If a build fails, say so with the output. If you skipped a step, say that. A confident wrong "it works" is worse here than in a repo whose owner reads the code.

## CI

Two jobs on `pull_request` — neither exists yet; there is no workflow file. Scaffold them with `permissions: contents: read`, and **no secrets in the repo at all** (which structurally rules out fork-PR secret exposure):

1. `packages` — `swift test` on the SwiftPM packages.
2. `app` — build for the iOS Simulator with `CODE_SIGNING_ALLOWED=NO`. **Required for merge.**

**Pin the runner image.** `macos-latest` currently maps to macOS 15, not 26 — start on `macos-26`. **Never use a `-large`/`-xlarge` runner:** standard runners are free and unlimited on public repos, larger ones are always billed, public repo or not.

**Once the project exists**, assert its format rather than assuming it — these are acceptance checks for the scaffolding work and for CI thereafter. They do not pass today, because there is no `project.pbxproj` to read:

```bash
grep -c 'in Sources' project.pbxproj    # must be 0
grep -c fileSystemSynchronized          # must be > 0
```

## Agent Tooling

**XcodeBuildMCP, pinned to `2.7.0`** — not `@latest`, which has shipped a breaking schema bump; unannounced breakage in a loop nobody can code-review is a bad failure mode. Upgrade deliberately.

Enable exactly the `simulator` and `ui-automation` workflows (~6k context). Set `configuration: 'Debug'` explicitly. **The committed config must opt telemetry out** as hygiene — no such config exists yet, so this is a scaffolding requirement, not a safeguard already in place.

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
