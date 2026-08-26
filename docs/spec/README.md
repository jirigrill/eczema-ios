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

## Sections

| Section | Status |
| --- | --- |
| [`skin-observation.md`](skin-observation.md) | Written — the template section |
| [`day-view.md`](day-view.md) | Written; **no OPEN rules**. Time zones settled by [#728](https://github.com/jirigrill/eczema-helper/issues/728) — the calendar date is fixed at log time and never recomputed (`DAY-NAV-9`..`-9c`); a record dated after today is unreachable and unsurfaced until today reaches it (`DAY-NAV-13`, [#743](https://github.com/jirigrill/eczema-helper/issues/743)). The photo group is fully settled: placement ([#727](https://github.com/jirigrill/eczema-helper/issues/727)), grid growth ([#738](https://github.com/jirigrill/eczema-helper/issues/738)), per-entry indicator ([#739](https://github.com/jirigrill/eczema-helper/issues/739)) and thumbnail tap ([#740](https://github.com/jirigrill/eczema-helper/issues/740)). One neighbouring question is still open elsewhere: the meal-slot collision on a twice-lived date ([#744](https://github.com/jirigrill/eczema-helper/issues/744)), which lands in `persistence-model.md` |
| First run and feeding stage | [`first-run.md`](first-run.md) — written; 1 **OPEN** rule — whether the app announces a changed privacy notice (`RUN-CONSENT-4`, shared with `settings.md` `SET-PRIVACY-14`). Awaiting owner confirmation on two points: the copy branch (`RUN-COPY-2`) and the degraded-state warning (`RUN-ICLOUD-2`) — [#729](https://github.com/jirigrill/eczema-helper/issues/729) |
| [`settings.md`](settings.md) | Written — [#716](https://github.com/jirigrill/eczema-helper/issues/716) |
| [`consent.md`](consent.md) | Written — [#737](https://github.com/jirigrill/eczema-helper/issues/737); no **OPEN** rules, but the consent copy is the owner's to draft and five questions are tabled for [#694](https://github.com/jirigrill/eczema-helper/issues/694)'s lawyer review |
| Persistence model (SwiftData + CloudKit) | [`persistence-model.md`](persistence-model.md) — written; [#730](https://github.com/jirigrill/eczema-helper/issues/730). Carries the schema deadlines |

The meal editor is the one area extracted **before** the template existed, and it lives on the
frozen PWA repo beside the code it was read out of:
[`docs/spec/meal-editor-state-machine.md`](https://github.com/jirigrill/eczema-helper/blob/main/docs/spec/meal-editor-state-machine.md).
It documents three cooperating state machines, maps every rule to its current TypeScript test, and
lists its own open questions. Reference it; do not copy it here. It predates this format — it has no
rule ids, no strength marks and no disposition table.

> **Read it as a description of the PWA, not as instruction to the port.** Because it has no
> strength marks, nothing in its prose distinguishes a live requirement from one that was
> reversed — and **six of its behaviors were overturned** by
> [#690](https://github.com/jirigrill/eczema-helper/issues/690) (undone-delete timestamps,
> unconfirmed-food dirtiness, outside-click, buffer ownership, failed-delete undo invalidation,
> and the post-remount "done" state). Each is now corrected in place and marked as a **Port
> rule** block at §3.3, §3.4, §4.4, §6.1, §9.3 and §9.5, and seven of its sixteen open questions
> are struck through. Treat any wart it records *without* a Port rule block as **undecided** —
> #690's coherence default governs it, but nobody has adjudicated it.

Reformatting it into this format — rule ids, strength marks, disposition table, divergence index,
verification verdicts — is worthwhile but is nobody's task yet
([#731](https://github.com/jirigrill/eczema-helper/issues/731)).


## Open questions live on the map

Anything undecided belongs on the [Wayfinder map](https://github.com/jirigrill/eczema-helper/issues/672),
not here — except as an **OPEN** rule plus a paragraph in a section's own open-questions list, which
is how a section records that it deliberately did not guess.
