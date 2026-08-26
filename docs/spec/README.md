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
| [`day-view.md`](day-view.md) | Written; 1 **OPEN** rule — time zones ([#728](https://github.com/jirigrill/eczema-helper/issues/728)). The photo group is fully settled: placement ([#727](https://github.com/jirigrill/eczema-helper/issues/727)), grid growth ([#738](https://github.com/jirigrill/eczema-helper/issues/738)), per-entry indicator ([#739](https://github.com/jirigrill/eczema-helper/issues/739)) and thumbnail tap ([#740](https://github.com/jirigrill/eczema-helper/issues/740)) |
| First run and feeding stage | [`first-run.md`](first-run.md) — written; 1 **OPEN** rule — whether the app announces a changed privacy notice (`RUN-CONSENT-4`, shared with `settings.md` `SET-PRIVACY-14`). Awaiting owner confirmation on two points: the copy branch (`RUN-COPY-2`) and the degraded-state warning (`RUN-ICLOUD-2`) — [#729](https://github.com/jirigrill/eczema-helper/issues/729) |
| [`settings.md`](settings.md) | Written — [#716](https://github.com/jirigrill/eczema-helper/issues/716) |
| [`consent.md`](consent.md) | Written — [#737](https://github.com/jirigrill/eczema-helper/issues/737); no **OPEN** rules, but the consent copy is the owner's to draft and five questions are tabled for [#694](https://github.com/jirigrill/eczema-helper/issues/694)'s lawyer review |
| Persistence model (SwiftData + CloudKit) | [`persistence-model.md`](persistence-model.md) — written; [#730](https://github.com/jirigrill/eczema-helper/issues/730). Carries the schema deadlines |

The meal editor is the one area extracted **before** the template existed, and it lives on the
frozen PWA repo beside the code it was read out of:
[`docs/spec/meal-editor-state-machine.md`](https://github.com/jirigrill/eczema-helper/blob/main/docs/spec/meal-editor-state-machine.md).
It documents three cooperating state machines, maps every rule to its current TypeScript test, and
lists its own open questions. Reference it; do not copy it here. It predates this format — it has no
rule ids, no strength marks and no disposition table, and five of its open questions were answered
afterwards by [#690](https://github.com/jirigrill/eczema-helper/issues/690). Reformatting it is
worthwhile but is nobody's task yet.

## Open questions live on the map

Anything undecided belongs on the [Wayfinder map](https://github.com/jirigrill/eczema-helper/issues/672),
not here — except as an **OPEN** rule plus a paragraph in a section's own open-questions list, which
is how a section records that it deliberately did not guess.
