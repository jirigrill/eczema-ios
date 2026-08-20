# Shared spec vocabulary

Terms that belong to **more than one** behavior area, so no single section owns them.

Everything else stays local: each section's own §1 Vocabulary table holds the terms that section
owns, and links here for the shared ones. A term earns a place in this file by being used across
sections — not by being important.

**This is not a port of the Czech `UBIQUITOUS_LANGUAGE.md`**, which freezes in the reference repo
([#677](https://github.com/jirigrill/eczema-helper/issues/677)). That file is 696 lines of a
different product's vocabulary. This one starts small and grows only when a second section reaches
for the same word — the four entries below each earned their place that way, and two of them
(*feeding stage*, *eligible actors*) were found by applying the rule to sections already written.

**Domain invariants are not vocabulary.** `INV-1..14` live in
[`CONTEXT.md`](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md) and are cited by
anchor, never restated here — see [`TEMPLATE.md`](TEMPLATE.md).

---

## Feeding stage

One of `breastfed`, `mixed`, `solids`. It determines which actors may log a meal, per the
unnumbered *Actor* rule in
[`CONTEXT.md`](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md) § _Glossary_ — cited
by heading, because that rule is deliberately unnumbered.

It is a **single app-wide value**, not a per-record one: exactly one stage is in force at a time, and
changing it does not rewrite meals already recorded under the previous stage. That is what makes
*eligible actors* below a question about *now* rather than about the record.

Where it is set and how it persists is `settings.md` §2. Which rows a day renders under it is
`day-view.md` §3. The skin section does not read it.

## Eligible actors

The actors the current *feeding stage* permits — a function of the stage alone, evaluated for the
stage in force now.

The term earns its place here by being the join between two sections that state **different halves**
of it: settings owns the stage that determines the set, and the day view owns what the set does to a
slot. Neither half is usable without the other, and the day view needs the contrast — eligible actors
are not *recorded actors*, the actors of meals that actually exist, which is a per-slot term the day
view owns (`day-view.md` §1) because no other section reads it.

That gap is deliberate and load-bearing: a stage change alters the eligible set while recorded meals
stay exactly as they were, so the two can disagree for any day. The day view's union rule
(`day-view.md` §3.2) exists to render both.

## Pending work

**Would leaving here lose something the mother did?**

The question every editing screen must answer before she navigates away. When the answer is yes,
leaving records an **undoable action** (below) so the work is recoverable; when it is no, leaving is
silent.

Pending work counts **in-progress** work, not just finishable work — anything she has done in this
visit that is not yet in storage. It is deliberately **not** the same question as *can this be
saved*, and the two have different answers on purpose: a meal holding only a half-picked food is
pending work that cannot yet be saved. Conflating them is the defect
[#690](https://github.com/jirigrill/eczema-helper/issues/690) split apart and
[#707](https://github.com/jirigrill/eczema-helper/issues/707) named.

The definition is one question; **what counts as work is per area**, stated by each section:

| Area | Pending work means |
| --- | --- |
| Skin observation | Any region above `Calm`, any note text, or any staged photo (`SKIN-UNDO-6`). |
| Meal editor | Any food she has started picking or has picked, or any note text. |

Two rules hold across every area:

- **Compose and edit answer it identically.** A fresh record with work in it is as recoverable as a
  modified one. The reference implementation protects one and abandons the other in *both* screens,
  in opposite directions — the largest divergence in the skin section
  (`skin-observation.md` Divergence 8) and #690's finding 2 in the meal editor.
- **Typed text is work in its own right.** A note with nothing else alongside it counts. Under
  mandatory sync with no export ([#683](https://github.com/jirigrill/eczema-helper/issues/683)) a
  lost note is unrecoverable, and a note is often the whole record — *"refused lunch, very itchy
  after"*.

Areas with no editing visit have no pending work: settings changes take effect on selection with no
save step (`settings.md` `SET-STAGE-3`), and the day view does not edit.

## Undoable action

The application-wide, **single-slot** holder for "the thing that just happened and can be reversed."
Recording a new one destroys the previous. It knows what it reverses and where reversing it lands,
and it belongs to a screen only if it identifies the same record that screen is opening.

Shared by the skin screen and the meal editor; **owned by neither**. Specified in
`skin-observation.md` §8.1 (`SKIN-UNDO-1` … `-3`), which is where the rules live until the meal
editor section is written against this format.

Its entry condition is *pending work* above — one buffer, one question deciding when to write to it.
In the reference implementation the buffer is already shared while three independently-written
predicates decide when to fill it, and they disagree; that split is what these two entries exist to
close.
