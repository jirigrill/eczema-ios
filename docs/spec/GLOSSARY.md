# Shared spec vocabulary

Terms that belong to **more than one** behavior area, so no single section owns them.

Everything else stays local: each section's own §1 Vocabulary table holds the terms that section
owns, and links here for the shared ones. A term earns a place in this file by being used across
sections — not by being important.

**This is not a port of the Czech `UBIQUITOUS_LANGUAGE.md`**, which freezes in the reference repo
([#677](https://github.com/jirigrill/eczema-helper/issues/677)). That file is 696 lines of a
different product's vocabulary. This one starts small and grows only when a second section reaches
for the same word — the six entries below each earned their place that way, and two of them
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

## Photo viewer

The full-screen surface that shows one skin photo at a time and **pages** between photos. Reached by
tapping a thumbnail, from either of the two thumbnail surfaces in the app: the day view's photo grid
(`day-view.md` `DAY-SKIN-11`) and the skin screen's gallery (`skin-observation.md` `SKIN-PHOTO-24`).

It earns its place here the same way *undoable action* does — **one** surface with two callers, owned
by neither. Its shared behavior is specified once, in `skin-observation.md` §5.5 (`SKIN-PHOTO-24` …
`-31`), because that section owns photos; the day view's rules add only what is particular to being
launched from a day.

**What each caller fixes is the sequence**, and the governing principle is that the pager's order is
always the order of the surface it was launched from: the day's photos chronologically from the grid,
one observation's photos in gallery order from the gallery. The only other difference between the two
is that the day view's viewer offers a route into the observation (`DAY-SKIN-11c`) while the gallery's
does not (`SKIN-PHOTO-31`) — the observation is already open there.

Two prohibitions travel with the term wherever it appears: it **deletes nothing**
(`SKIN-PHOTO-30`), and it shows **no position and no extent** — no "3 of 40", no dots
(`DAY-SKIN-11b`). Both are settled by
[#740](https://github.com/jirigrill/eczema-helper/issues/740).

## Calendar date, and instant

The pair the app's whole treatment of time rests on, and they are **not interchangeable**.

A **calendar date** is a day label — `2026-05-14` — with no time and no zone. It answers *which day
does this belong to*. An **instant** is a fixed point in time, the same moment everywhere, which
renders as a different wall clock in every zone. It answers *when exactly did this happen*.

A record carries **both**, and they are set from the same moment but are not derived from each other
afterwards. The calendar date is the day the mother filed the record under — the local date where she
was standing when she wrote it — and it is a stored label, never recomputed
(`day-view.md` `DAY-NAV-9`, `persistence-model.md` `DATA-MEAL-3`). The creation instant is a real
instant (`DATA-MEAL-4`), immutable per
[INV-8](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-8).

**Why the distinction is load-bearing.** Storing the day as an instant would make the day a record
appears under depend on the reader's zone, so a meal logged at 23:00 in Prague would move to the next
day when read in Auckland — a day she may never have lived. That is the failure
[#728](https://github.com/jirigrill/eczema-helper/issues/728) measured and rejected. The consequence
runs the other way too: because the date is a label rather than a derivation, a **time of day** is
rendered from the instant in the current zone (`DAY-NAV-9c`), so the same entry can show a different
clock while showing the same day. Both halves are deliberate.

Three sections reach for the pair: `day-view.md` §2 (which day a record shows under),
`persistence-model.md` §5 (how each is stored and typed) and `skin-observation.md` (an observation's
date and its time). None owns it.
