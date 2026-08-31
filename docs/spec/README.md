# Behavior spec

The behavior spec for the iOS app: platform-neutral, owner-confirmed, and complete enough that a
Swift developer or agent can build the port and derive tests from it without further discovery.

## The format is settled

Read [`TEMPLATE.md`](TEMPLATE.md) before writing or extending a section. It states the conventions;
[`skin-observation.md`](skin-observation.md) is the worked example that demonstrates them and was
written as the template.

In short: one file per behavior area, rules with permanent `<AREA>-<GROUP>-<n>` ids, an explicit
strength mark on every rule (**MUST** / **MUST NOT** / **SHOULD** / **PWA** / **OPEN**), invariants
cited by anchor and never restated but always given a **disposition**, divergences from the PWA
marked inline *and* indexed, and every section ending in a verification table, an on-device
acceptance pass, and its open questions.

[`GLOSSARY.md`](GLOSSARY.md) holds the terms used by **more than one** section, so no single section
owns them. Area-local terms stay in each section's own §1 Vocabulary table.

## Read the shaping decisions first

[`DECISIONS.md`](DECISIONS.md) states, in six entries and without requiring a single link, the
decisions that shape the whole product: sync is mandatory, every encryptable field is encrypted,
nothing is exported, refusing consent is terminal, nothing is derived, and photographs still reach the
camera roll. Each says what it cost and what undoing it would take.

It is **not** authoritative on behavior — the rules are. Read it to understand why a section reads the
way it does, and before proposing a change that a rule appears to invite.

## Sections

| Section | Status |
| --- | --- |
| [`skin-observation.md`](skin-observation.md) | Written — the template section; **no OPEN rules** |
| [`day-view.md`](day-view.md) | Written; **no OPEN rules**. Time zones settled by [#728](https://github.com/jirigrill/eczema-helper/issues/728) — the calendar date is fixed at log time and never recomputed (`DAY-NAV-9`..`-9c`); a record dated after today is unreachable and unsurfaced until today reaches it (`DAY-NAV-13`, [#743](https://github.com/jirigrill/eczema-helper/issues/743)). The photo group is fully settled: placement ([#727](https://github.com/jirigrill/eczema-helper/issues/727)), grid growth ([#738](https://github.com/jirigrill/eczema-helper/issues/738)), per-entry indicator ([#739](https://github.com/jirigrill/eczema-helper/issues/739)) and thumbnail tap ([#740](https://github.com/jirigrill/eczema-helper/issues/740)). One neighbouring question is settled elsewhere: the meal-slot collision on a twice-lived date ([#744](https://github.com/jirigrill/eczema-helper/issues/744)), which landed in `persistence-model.md` §4.1 — the second breakfast opens the first in edit, so one slot holds one meal |
| First run and feeding stage | [`first-run.md`](first-run.md) — written; 1 **OPEN** rule — whether the app announces a changed privacy notice (`RUN-CONSENT-4`, shared with `settings.md` `SET-PRIVACY-14`). Awaiting owner confirmation on two points: the copy branch (`RUN-COPY-2`) and the degraded-state warning (`RUN-ICLOUD-2`) — [#729](https://github.com/jirigrill/eczema-helper/issues/729) |
| [`settings.md`](settings.md) | Written — [#716](https://github.com/jirigrill/eczema-helper/issues/716); 1 **OPEN** rule — whether the app announces a changed privacy notice (`SET-PRIVACY-14`, the same question as `first-run.md` `RUN-CONSENT-4`). Sync health is settled here (§4.1, `SET-SYNC-1`..`-12`, [#723](https://github.com/jirigrill/eczema-helper/issues/723)): the app is silent while sync is healthy and speaks only on failure |
| [`consent.md`](consent.md) | Written — [#737](https://github.com/jirigrill/eczema-helper/issues/737); no **OPEN** rules, but the consent copy is the owner's to draft and five questions are tabled for [#694](https://github.com/jirigrill/eczema-helper/issues/694)'s lawyer review |
| Persistence model (SwiftData + CloudKit) | [`persistence-model.md`](persistence-model.md) — written; **no OPEN rules**; [#730](https://github.com/jirigrill/eczema-helper/issues/730). Carries the schema deadlines |
| Food catalog | [`catalog.md`](catalog.md) — written; **70 rules, the largest section, no OPEN rules**; [#734](https://github.com/jirigrill/eczema-helper/issues/734). Two groups are what a reader most needs routing to: the **sign-off gate** (`CAT-SIGN-1`..`-6`) — the owner reviews the English catalog source itself, provenance lives in comments beside the data and on no field, and a change to a food's allergen ids needs her sign-off because resolution is live and therefore retroactive; and the `CAT-DERIVE-*` **display prohibition** — the allergen level ships fully populated and entirely unrendered, and no screen names a trigger, an allergen, or a food as safe or risky |
| [`meal-editor.md`](meal-editor.md) | Written — [#753](https://github.com/jirigrill/eczema-helper/issues/753); **1 OPEN rule** (`MEAL-DEG-4`, what the screen tells her about a food the catalog no longer knows) and **13 divergences, eleven of them defects fixed** — the largest divergence index in the spec, because this is the app's most-iterated screen. Two of those are data loss in the PWA: an in-progress food dropped without undo when a saved meal is left ([#690](https://github.com/jirigrill/eczema-helper/issues/690) §2), and one discarded by the actor-swap autosave. The section splits the one predicate the PWA used for two questions — *can this be saved* counts only finished foods, *would leaving lose something* counts started ones too (§3.3, §3.4). Supersedes, for the port, the pre-template `meal-editor-state-machine.md` on the frozen repo, and adjudicates its nine surviving open questions in §13 |

The meal editor's pre-template extraction still lives on the frozen PWA repo as
[`meal-editor-state-machine.md`](https://github.com/jirigrill/eczema-helper/blob/main/docs/spec/meal-editor-state-machine.md).
[`meal-editor.md`](meal-editor.md) **supersedes it for the port** and carries everything it
established. Read the old document only as a line-by-line description of what the TypeScript did —
its value from here is archaeological, and it has no rule ids, no strength marks and no disposition
table ([#731](https://github.com/jirigrill/eczema-helper/issues/731) is closed by that supersession).


## Open questions live on the map

Anything undecided belongs on the [Wayfinder map](https://github.com/jirigrill/eczema-helper/issues/672),
not here — except as an **OPEN** rule plus a paragraph in a section's own open-questions list, which
is how a section records that it deliberately did not guess.
