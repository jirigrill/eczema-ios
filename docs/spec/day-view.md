# Day view — behavior specification

**Status:** owner-confirmed. Written against the format settled by
[#682](https://github.com/jirigrill/eczema-helper/issues/682) — see
[`TEMPLATE.md`](TEMPLATE.md) for the rules, and
[`skin-observation.md`](skin-observation.md) for the worked example.
**Behavior reference:** `jirigrill/eczema-helper` @ `582f662` (frozen PWA),
`src/routes/day/[date]/`, `src/lib/components/MealCard.svelte`,
`src/lib/components/DayStrip/`, `src/lib/components/SkinObservationCard.svelte`.
**Resolves:** [#715](https://github.com/jirigrill/eczema-helper/issues/715) on the transition map
[#672](https://github.com/jirigrill/eczema-helper/issues/672).

## Overview

The day view is what the mother opens. It is the app's home screen and its only navigation root:
it shows one day at a time — the meals logged against that day and the skin observations recorded
on it — and every other screen in the app is entered from here and returns here.

It is also the screen where a diary would most easily start reading like an assessment. It is the
only place that sees a whole day at once, so it is the only place that could count, average, grade
or congratulate. It does none of those things, and that is a rule with an id rather than an
omission ([INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11)).

This document states what the screen does, in English, without reference to Swift, SwiftUI,
SwiftData, Svelte, Dexie, or the Czech interface. Swift tests are derived from the numbered rules;
the owner's acceptance pass is derived from §9.

Three things are worth knowing before the rules make sense:

1. **The day is a calendar date, not a span of time.** Meals are day-granular with no user-facing
   times ([INV-3](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-3)), and a
   record's date is fixed when it is written. Observations do carry a time, because a day holds
   many of them.
2. **The screen shows what she recorded, never what she may record.** The meal rows are built
   from the union of the currently-eligible actors and the actors actually present in the day's
   meals — not from the eligible set alone. This is the difference between a screen that can
   hide her records and one that cannot (§3, Divergence 1).
3. **It displays nothing derived.** Not a severity, not a count, not a streak. §6 states this as a
   blanket prohibition rather than leaving it to the absence of features. What the screen *does*
   show is the content of her records — a time, a region, a note, and whether an entry has photos
   (`DAY-SKIN-9`) — which is not a derivation, however small; §4 draws that line where #739 settled
   it.

**How to read this document:** see
[`skin-observation.md` § How to read this document](skin-observation.md#how-to-read-this-document).
Rule ids here are `DAY-<group>-<n>`, permanent identity, never renumbered or reused.

### Invariant dispositions

Invariants are cited, never restated. [#691](https://github.com/jirigrill/eczema-helper/issues/691)
classified all fourteen; the ones this section touches carry their disposition here so a bare
citation cannot import a contradiction.

| Ref | Leading phrase | Disposition here |
| --- | --- | --- |
| [INV-1](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-1) | _Single device, no sync_ | **Void for iOS.** Sync is mandatory and always on ([#705](https://github.com/jirigrill/eczema-helper/issues/705)). Directly load-bearing here: it is what makes `DAY-LIVE-1` and `DAY-STAGE-3` necessary. |
| [INV-2](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-2) | _No backup mechanism exists_ | **Void for iOS.** Sync carries durability ([#683](https://github.com/jirigrill/eczema-helper/issues/683)). Still no *rollback*, which is why `DAY-MEAL-10` keeps delete off this screen. |
| [INV-3](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-3) | _Meals are day-granular; no user-facing meal times_ | **Holds unchanged.** Why a meal row shows no time (`DAY-MEAL-6`) while an observation entry does. |
| [INV-4](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-4) | _One meal per date+mealType+actor slot_ | **Enforcement moved.** CloudKit cannot enforce uniqueness ([#679](https://github.com/jirigrill/eczema-helper/issues/679), and the composite id does **not** self-enforce under mirroring — #691's correction). The day view is where a duplicate would become visible; §3.5. |
| [INV-6](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-6) | _Per-region severity set; a `max(regions)` day-overall severity is defined_ | **Holds, minus the derivation.** The day-overall concept is dropped outright — `SKIN-VIEW-5`, Divergence 13, settled by [#717](https://github.com/jirigrill/eczema-helper/issues/717). Governs `DAY-DERIVE-2`. |
| [INV-7](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-7) | _Calm regions persist as positive evidence_ | **Holds unchanged.** Its day-view consequence is `SKIN-VIEW-3`: a day with no observation must look different from a day with an all-calm one. |
| [INV-8](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-8) | _`id` and `createdAt` immutable across edit, delete, undo_ | **Holds unchanged.** It is what makes ordering observations by `createdAt` stable across edits (`SKIN-VIEW-1`). |
| [INV-10](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-10) | _Dexie/IndexedDB; reactive UI via `liveQuery`_ | **Void for iOS** as to storage; the *reactivity* it describes is retained as behavior in `DAY-LIVE-1`. |
| [INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11) | _The app is a Logging Tool_ | **Holds**, and is the governing invariant of this section. All of §6, and the unmarked-row rule `DAY-MEAL-3`. |
| [INV-12](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-12) | _Records carry types, not display strings_ | **Holds.** The day view resolves every label at render; note the PWA's `MealItem.name` violation ([#677](https://github.com/jirigrill/eczema-helper/issues/677)) must not be inherited by the row rendering in `DAY-MEAL-6`. |
| [INV-14](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-14) | _Every meal has an eligible actor_ | **Holds, and is read precisely.** It binds **at log time**. That is exactly what licenses `DAY-MEAL-2`/`-3`: a later stage change does not retro-invalidate a meal, so the day view must still show it. |

`CONTEXT.md` also holds invariant-shaped rules **unnumbered**, in glossary prose. Two bear on this
screen and are cited by heading: _Actor_ (the stage → actors mapping) and the _Copy Meal_ flow
rules (both under § _Glossary_).

### Divergences from the PWA

This is not a 1:1 port. Per [#690](https://github.com/jirigrill/eczema-helper/issues/690),
**coherence is presumed right**: where the reference implementation does two different things, the
port takes the coherent rule, and *keeping* a wart needs a named reason. There are **eight**,
marked inline and indexed in §8. Two of them fix defects that are live in the shipped PWA today.

---

## 1. Vocabulary

| Term | Meaning |
| --- | --- |
| **Day shown** | The single calendar date the screen is currently displaying. Exactly one at a time. |
| **Date selector** | The horizontal run of day cells by which she moves between days. |
| **Back edge** | The oldest date the date selector reaches. |
| **Slot** | One `(day, meal type)` pair — the unit the meal section is built from. |
| **Actor row** | One row inside a slot, belonging to one actor (`mother` or `baby`). |
| **Recorded actors** | The actors of meals that actually exist in a slot, whatever the stage is now. |
| **Union rows** | Eligible actors ∪ recorded actors. What the slot actually renders (§3). |
| **Observation entry** | One row in the skin section, representing one saved observation. |
| **Add control** | The always-available control for starting a new record on the day shown. |

Three terms this section uses are shared with other areas and defined in
[`GLOSSARY.md`](GLOSSARY.md): **feeding stage** and **eligible actors** (shared with settings), and
the **photo viewer** (shared with the skin screen, and specified in `skin-observation.md` §5.5).
*Recorded actors* above is
this section's own — no other area reads it — and the gap between the two is what §3.2's union rule
exists to render.

---

## 2. Date navigation

**`DAY-NAV-1` (MUST)** — Launching the app opens **today**. The day last viewed is never restored.

**`DAY-NAV-2` (MUST)** — Exactly one day is shown at a time, identified by a calendar date.

**`DAY-NAV-3` (MUST NOT)** — No day **after** today is reachable. The date selector's forward edge
is today, and no interaction reaches a future date.

> **⚠ Divergence 1.** *PWA:* the selector always renders seven future cells, every one tappable and
> loggable; the layout comments *"No day is suppressed: every day in range is loggable"*
> (`+layout.svelte:29-33`, `day-strip.ts:21,52-55`). *iOS:* future days are unreachable. *Why:*
> owner's call. This is a record of what happened; a tomorrow row is an invitation to a mis-dated
> meal, and mis-dating is the one error class the app cannot detect and — with no export
> ([#683](https://github.com/jirigrill/eczema-helper/issues/683)) — cannot repair. The cost
> accepted: no planning-ahead use, which is elimination-protocol thinking and is parked anyway.

**`DAY-NAV-4` (MUST)** — Every day from the back edge to today is reachable. The back edge is the
earlier of *today minus seven days* and *the date of the earliest record she has* — meals and
observations both count.

**`DAY-NAV-5` (MUST)** — The date selector centres the day shown whenever the selection changes.

**`DAY-NAV-6` (MUST)** — Today is marked in the selector even when another day is selected, and
the mark says only *this is today* — never anything about that day's contents.

**`DAY-NAV-7` (MUST NOT)** — A selector cell never indicates whether that day holds records. No
dot, no fill, no count, no shading.

The reference implementation once had this and it was deliberately removed: the today-ring is
documented in place as state-free, and a `data-recorded` attribute is asserted **absent** by a
regression test (`page.test.ts:298-321`). Dots on a row of days become a completeness score, which
is the parked daily-completeness counter returning by a side door — the same edge as §6.

**`DAY-NAV-8` (MUST)** — When a day other than today is shown, a control returns to today and
recentres the selector.

**`DAY-NAV-9` (MUST)** — A record's calendar date is **fixed at log time and never recomputed**. It
is the local calendar date where she was standing when she wrote it, and crossing a time zone does
not move any existing record to a different day. `today` is re-resolved from the device's current
zone, so where she is decides which day opens — but never what day a record already written belongs
to.

Resolved by prototype → [#728](https://github.com/jirigrill/eczema-helper/issues/728) (built and
handed over by [#742](https://github.com/jirigrill/eczema-helper/issues/742)); the recommendation
this rule previously recorded, now asserted. **No schema change** — `persistence-model.md`
`DATA-MEAL-3` already stores the day as a calendar-day label rather than an instant, and Divergence 2
there was written *because* the deferral needed that field not to be an instant. This resolution is
what that typing was holding open.

**What was rejected, and what the prototype measured.** The alternative was to recompute every
record's day from its `createdAt` instant in the zone the phone is in now. Over a six-leg
Prague → Auckland → Honolulu → Prague fixture, recomputation moved records on **every leg away from
home**, and — the finding that decided it — **did not unwind on return**: back in Prague, five
records still read under a different date than she filed them, in both directions. A dinner logged at
23:00 in Prague lands on a **day she never lived** when read in Auckland. Fixing the date at log time
moves nothing, ever.

**The cost, accepted knowingly: an honest empty day.** A date she skipped by flying over it — `2026-05-15`
in the fixture — shows as a day with records either side and nothing in it. That is not a gap in her
record-keeping and the app must not imply it is (`DAY-DERIVE-1` already bars any completeness
reading, and `DAY-NAV-7` bars the selector from marking which days hold records, so nothing renders
the emptiness as a lapse). The rejected policy hid that day only while she was abroad, by relabelling
the Prague records onto it, and the hole reappeared once she was home — so the choice was an honest
empty day, always, over a filled one that empties later.

**`DAY-NAV-9a` (MUST)** — A **newly written** record is filed under the device's local calendar date
at the moment of writing. This half was never in dispute — all three prototype policies answered it
identically — and it is stated rather than left implied, because a rule about dates that only
describes reading invites the reader to assume writing is the interesting half. It is not: writing is
settled, and only reading was ever the question.

**`DAY-NAV-9b` (MUST NOT)** — No record's stored calendar date is ever rewritten in response to a
zone change, on read or on any later edit. There is no migration, no backfill, and no
convergence pass that restamps a day — `persistence-model.md` `DATA-CONV-3` already forbids
restamping `createdAt`, and the calendar day is under the same prohibition for the same reason.

**`DAY-NAV-9c` (MUST)** — A record's **time of day** is rendered in the device's **current** zone,
from the stored instant. No record stores the zone it was written in, and none needs to.

This is the second axis the decision had to answer, and it is answered the same way for the same
reason: the app holds an instant and a calendar day, and renders both from what it has. The rejected
alternative kept the date fixed but rendered each record's clock in the zone it was *logged* in, so a
caption read the clock she actually saw.

**The cost, stated because it is real and visible.** `DAY-SKIN-10` derives the caption's time at
render, so an observation written at 22:50 in Prague reads **8:50** when that day is viewed from
Auckland — an evening entry captioned as morning, under a date that correctly stays 14 May. The
rejected alternative would have shown 22:50 from anywhere. It was declined because it **costs a
schema field**: `persistence-model.md` `DATA-MEAL-3` fixes that reading the day "never involves a time
zone", nothing in the record shape carries a zone, and adding one to improve a caption is a
persistence change in service of a cosmetic gain. Fixing the date is what protects her data; fixing
the caption only protects its phrasing.

**This is the reversible half.** Changing it later needs a stored zone on new records and a decision
about what to show for records written before the field existed — additive under
`persistence-model.md`'s promotion rule, and no existing date moves. Reversing `DAY-NAV-9` itself
would move every record; reversing this moves nothing.

**Two things a reader will expect these rules to cover, and they do not.** Both are ways a record can
end up somewhere these rules do not reach, and each has its own id or ticket:

- **A record dated after today** — answered by `DAY-NAV-13`, not here. Fixing the date at log time is
  what *creates* the state: a record keeps the date she filed it under, so a device whose today is
  behind that date holds a record it cannot reach.
  [#743](https://github.com/jirigrill/eczema-helper/issues/743) settled what happens (nothing — it is
  unreachable and unsurfaced until today reaches its date) and corrected the framing this rule would
  otherwise have implied: **travel is not the trigger**. With sync mandatory, the common path has no
  traveller in the reading device's frame at all — she logs a meal abroad and the phone at home is
  still a day behind. The gap is also **at most one day**, since zone offsets span at most ~26 hours.
- **Two breakfasts on one calendar date.** Living one date twice means a second meal wanting a slot
  the first already holds, and `INV-4`'s upsert key means the second overwrites the first with no
  trace. This is a **write**-side collision, so every policy above suffers it equally and none of
  these rules prevents it. → [#744](https://github.com/jirigrill/eczema-helper/issues/744), §3.5 and
  the persistence section.

**Not tested by the prototype: daylight saving.** No leg of the fixture crosses a DST transition (all
three zones hold a constant offset across the journey), so what these rules are measured against is
the date-line effect alone. Nothing here should be read as evidence about a one-hour shift.


**`DAY-NAV-10` (MUST)** — Crossing local midnight while the view is open does **not** change the
day shown. The day is re-resolved to today on the next foreground.

A screen that silently changes date under a mother who is about to tap *log dinner* produces the
same mis-dated meal `DAY-NAV-3` exists to prevent, arriving by a different door.

**`DAY-NAV-11` (MUST NOT)** — There is no date picker and no jump-to-arbitrary-date. The selector
is the only way to change the day shown.

With an unbounded past and a single child, the realistic reach is a few weeks of scrolling. A
picker is the surface that later grows a range, and a range is the surface that later grows a
summary of that range.

**`DAY-NAV-12` (MUST)** — On today, the header names the day as *Today*, without the date. On any
other day it shows the date, exactly once.

**`DAY-NAV-13` (MUST)** — A record dated **after today** is stored, synced and complete, and is
**not reachable and not surfaced anywhere** until today reaches its date. `DAY-NAV-3` holds without
exception: the forward edge does not bend for a record, no cell is added, no mark or message appears
on any screen, and nothing distinguishes the app's state from having no such record at all. When
today advances to that date, the record appears as an ordinary record on an ordinary day.

This is the decision to do nothing, recorded because it is otherwise the default nobody picked —
and the day view's back edge already bends for records (`DAY-NAV-4`), so a reader is entitled to ask
why the forward edge does not.

**Where the record lives: nowhere special.** There is no quarantine, no holding area, no pending
state, and no field marking it. `DATA-MEAL-3` stores the calendar date as a **calendar-day label**
whose reading "never involves a time zone", so the record is written under its date and stays there;
`DATA-ARRIVE-7` makes it fully recorded the moment it is saved. Unreachability is a property of the
**selector's range** (`DAY-NAV-4`), not of the record: the range is recomputed against today, and it
simply does not include that date yet. Nothing releases the record when today advances — the range
grows to meet it. This is why the resolution costs no schema change, and it is stated because an
implementer must know the write path needs no special case.

It is **not *pending work*** ([`GLOSSARY.md`](GLOSSARY.md)). That term asks whether leaving a screen
would lose something she did — work not yet in storage. This record is entirely in storage. The two
questions have different answers here, and borrowing the term would misfile a saved record as an
unsaved one.

**Nothing surfaces it, and that is part of the rule rather than an omission.** Every candidate
surface is already prohibited: a selector cell indicating contents is `DAY-NAV-7`, "1 record ahead"
is a count under `DAY-DERIVE-1`, and there is no date picker to reach it with (`DAY-NAV-11`). So the
prohibition is not a new cost — no compliant surface exists to be given up. What makes the silence
acceptable is the bound below, not the absence of a place to put a message.

**The gap is at most one day, and it closes by itself.** Zone offsets span at most ~26 hours, so two
local calendar dates can differ by at most one; under `DATA-MEAL-3`'s fixed label no record can ever
be more than one day ahead of any device's today. The record becomes reachable when today ticks
over, whatever the traveller does next.

**This is not a travel rule, and must not be narrowed into one.** The rule is phrased over *a record
dated after today* because the likeliest path involves no traveller at all in the reading device's
frame: `INV-1` is void for iOS and sync is mandatory
([#705](https://github.com/jirigrill/eczema-helper/issues/705)), so a meal logged abroad on the 18th
arrives on a phone at home whose today is still the 17th. A westward flight departing after local
midnight reaches the same state without crossing the date line, and a date-line crossing is the
rarest of the three, not the defining one.

The two shapes rejected, both against a one-day self-healing gap. **Bending the forward edge to the
latest record**, mirroring `DAY-NAV-4`: the cell it creates is tappable and loggable unless
separately suppressed, which is the mis-dated meal `DAY-NAV-3` exists to prevent — reintroduced to
show a record that will arrive tomorrow anyway. **Reachable but not loggable**: a third day state
the screen has nowhere else, its own empty-state and write-refusal behaviour, for the same one day.

**Independent of [#728](https://github.com/jirigrill/eczema-helper/issues/728).** The spike measured
this state under the fixed policy *and* the fixed-plus-zone policy; it is a property of the pair
(`DAY-NAV-3`, a backwards-moving today) rather than of date resolution. The reinterpret policy avoids
it only by moving records instead, trading an unreachable record for a silently relocated one. So
`DAY-NAV-9` may resolve either way without disturbing this rule.

**No new divergence.** The PWA has no such state to diverge from — its forward edge renders seven
future cells, so a record dated ahead is reachable there by construction. That is **Divergence 1**
already, and this rule is its consequence rather than a thirteenth entry.

**Not the twice-lived date.** A date lived twice puts two real meals in one slot, which is a write
problem this rule does not touch —
[#744](https://github.com/jirigrill/eczema-helper/issues/744)'s. `DAY-NAV-13` governs only whether a
stored record's day can be *reached*, and it neither creates nor resolves a collision.

---

## 3. Meals

### 3.1 The slots

**`DAY-MEAL-1` (MUST)** — All four meal types appear on every day, in the fixed order breakfast,
lunch, snack, dinner, whether or not anything is logged in them.

**`DAY-MEAL-11` (MUST)** — A row indicates whether it currently holds a meal, and the indication is
about the row, not about her day (see `DAY-DERIVE-3`).

### 3.2 Actor rows — the union rule

**`DAY-MEAL-2` (MUST)** — The rows in a slot are the **union** of the eligible actors for the
current feeding stage and the actors of meals actually recorded in that slot.

**`DAY-MEAL-3` (MUST)** — A meal whose actor is not currently eligible renders as a **normal row,
unmarked**, and remains editable. It is not flagged, greyed, badged or explained.

**`DAY-MEAL-4` (MUST)** — Union rows are ordered canonically — `mother` before `baby` — regardless
of which of them hold meals or which are eligible.

> **⚠ Divergence 2.** *PWA:* rows are built by mapping over the **eligible** actor set alone
> (`day/[date]/+page.svelte:36` → `MealCard.svelte:36`), so a meal by an actor the current stage
> does not permit **is not rendered at all**. *iOS:* rows are the union, and a now-ineligible
> actor's meal renders normally. *Why:* inherited from
> [#712](https://github.com/jirigrill/eczema-helper/issues/712) as a required divergence with a
> data-loss cause. #712 keeps onboarding on the reinstall path, and first run pre-selects
> `breastfed`, whose eligible set is `[mother]` — so a mother on `solids` who taps through the
> default would see **none of her `baby` meals**: apparent total data loss, on a screen shown
> *because* her records had not arrived yet. Rendering by recorded actor is what makes the re-ask
> harmless. It is observable only at `breastfed` and `solids`; at `mixed` both actors are eligible,
> so nothing was ever hidden. The row is unmarked because the app records and does not judge
> ([INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11)) — marking it
> would imply the *record* was wrong, when it was the *stage* that changed. Class: **settled by
> #712**.

**`DAY-MEAL-5` (MUST)** — When a slot shows more than one actor row, each row names its actor.
When it shows one, it does not.

> **⚠ Divergence 3.** *PWA:* stacked actor rows are distinguished by **icon only** — the actor
> labels exist in the strings file and are never rendered (`MealCard.svelte:140`). *iOS:* rows are
> labelled whenever there is more than one. *Why:* the icon was legible while a second row existed
> only because she had chosen a stage that produces two. Under Divergence 2 a `baby` row can now
> appear for a mother on `breastfed` — a row she has never seen before, in a context she did not
> choose — and a row that appears because of an old record has to say whose it is. Class: **forced
> by Divergence 2**.

### 3.3 What a row shows

**`DAY-MEAL-6` (MUST)** — A row holding a meal shows the recorded food names and nothing else: no
amounts, no preparations, no times, no notes, no photos.

Preparation is a food-level property ([ADR-0028](https://github.com/jirigrill/eczema-helper/blob/main/docs/adr/0028-food-level-preparations.md))
and is therefore available to display; it is deliberately not displayed. It matters while she is
*recording*; on the day view it doubles the row height for a detail one tap away. Note also that
the reference implementation persists Czech display text onto `MealItem.name` — a violation of
[INV-12](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-12) identified by
[#677](https://github.com/jirigrill/eczema-helper/issues/677). This row must resolve names from
the catalog at render, never from a string stored on the record.

### 3.4 Entering the editor

**`DAY-MEAL-7` (MUST)** — A row holding no meal is tappable and opens the meal editor in **compose**
for the day shown, that meal type, and that row's actor.

**`DAY-MEAL-8` (MUST)** — A row holding a meal opens the meal editor in **edit** for that meal.

**`DAY-MEAL-9` (MUST)** — Every entry into the editor supplies the day shown as the editor's return
destination.

The editor itself is specified by
[`meal-editor-state-machine.md`](https://github.com/jirigrill/eczema-helper/blob/main/docs/spec/meal-editor-state-machine.md); its §1.1 fixes meal type and date
at entry and defines the `returnTo` contract this rule satisfies. This section owns the *list*, not
the editor.

**`DAY-MEAL-10` (MUST NOT)** — No meal can be deleted from the day view. Deletion is reachable only
from inside the editor that owns the record.

Undo is a single-slot, in-memory, short-lived buffer with no trash behind it
([#687](https://github.com/jirigrill/eczema-helper/issues/687)). A swipe-to-delete on a list is the
gesture most likely to fire unnoticed, and here an unnoticed delete is unrecoverable.

### 3.5 Duplicates

[INV-4](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-4) makes a slot hold at
most one meal per actor, but CloudKit cannot enforce it and the composite id does not self-enforce
under mirroring ([#691](https://github.com/jirigrill/eczema-helper/issues/691)'s correction). The
observable failure of that gap is a **visible duplicate row** on this screen, not silent loss.
Dedupe is the persistence section's obligation; this section records only that the day view is
where it would surface, and that nothing here should hide it.

---

## 4. Skin observations

**`DAY-SKIN-1` (MUST)** — The observation list conforms to `SKIN-VIEW-1` through `SKIN-VIEW-4` in
[`skin-observation.md`](skin-observation.md#9-how-the-observation-appears-elsewhere): one entry per
observation, ordered by `createdAt` ascending, each with its time; each showing the regions above
`Calm` in canonical order; an all-calm observation shown as an explicit entry; and tapping an entry
opening the skin screen in edit mode, returning here on exit. Those rules are **not restated here**.

**`DAY-SKIN-2` (MUST)** — An entry shows the observation's note, if it has one.

It is the only free text in the app, and the only thing that records *why* a day looked the way it
did. How it is truncated is a layout matter this document does not own.

**`DAY-SKIN-3` (MUST)** — The skin section appears above the meal section.

**`DAY-SKIN-4` (MUST)** — When the day shown has no observations, the section offers a control that
opens the skin screen in compose for **that day**.

**~~`DAY-SKIN-5`~~ (RETIRED)** — Retired by
[#727](https://github.com/jirigrill/eczema-helper/issues/727). It prohibited any photo indicator on
an observation entry *until `DAY-SKIN-6` was resolved*, and existed only to stop an indicator
pre-empting the prototype. With placement decided the prohibition has no subject left; the question
it was holding open became `DAY-SKIN-9`, and
[#739](https://github.com/jirigrill/eczema-helper/issues/739) has since answered it the other way —
an entry **does** mark that it has photos. The id is **not reused**.

**`DAY-SKIN-6` (MUST)** — A day's photos appear in a **day-level photo card below the observation
list**: a three-column grid of every photo recorded that day, in chronological order, each thumbnail
square and captioned `region · time`.

Resolved by prototype → [#727](https://github.com/jirigrill/eczema-helper/issues/727) — this rule's
original question answered, not a new rule. The PWA's shape carries over, chosen on a phone with all
three candidates side by side. Two consequences follow, and both are decisions rather than layout
details: the unit shown to her is **the day**, not the observation — so `SKIN-VIEW-2`'s per-entry
unit does **not** extend to photos — and the photos appear **somewhere**, closing the "if anywhere"
limb.

**`DAY-SKIN-7` (MUST)** — The caption reads `region · time`, where the time is the parent
observation's, and it is **required**: it is the only thing re-attaching a photo to the record it
came from once the grid has separated them.

Verified legible rather than assumed: white on a 45%-black scrim measures **8.76:1**, against WCAG
AA's 4.5:1 for small text. The time is **not** stored on the photo — see `DAY-SKIN-10`.

**`DAY-SKIN-8` (MUST)** — The grid shows at most **two rows** — six thumbnails — and when more
photos exist that day it carries a control revealing the rest in place. The control names **no
quantity**: expanded and collapsed labels only, and it toggles both ways.

Resolved by prototype → [#738](https://github.com/jirigrill/eczema-helper/issues/738); this rule's
original question answered, not a new rule. Decided on a phone with all four candidates at five
photo volumes, which is what made it unanswerable on paper.

**`DAY-SKIN-8a` (MUST NOT)** — The reveal control never displays how many photos are hidden, or how
many exist. `DAY-DERIVE-1` prohibits it, and the prototype measured that the prohibition is **free**:
a count-bearing cap and a countless cap produce identical geometry at every volume, collapsed and
expanded, so the count buys no space and no compactness. It buys only the knowledge it is prohibited
from giving.

**`DAY-SKIN-8b` (MUST)** — The collapsed grid shows the day's **first** six photos in the
chronological order `DAY-SKIN-6` fixes. It does not select, rank, or prefer any photo.

Any other choice would be a derived judgement about which photos matter (`DAY-DERIVE-2`), and nothing
on this screen is allowed to make one.

**The cost this rule accepts.** From the collapsed state she **cannot tell whether one photo is
hidden or forty**. That is the direct consequence of `DAY-SKIN-8a`, and it is not a defect to be fixed
later by softening the prohibition — `DAY-DERIVE-1` is a blanket rule, and the count is the one number
#715 already dropped from this exact card. The mitigation available is the control's own presence: it
appears **only** when something is hidden, so its existence is a *presence* mark rather than a
quantity — the distinction `DAY-DERIVE-3` permits, because whether this grid is withholding something
is a fact about the control she is looking at.

> **Narrowed by [#739](https://github.com/jirigrill/eczema-helper/issues/739).** This passage
> originally added "the same distinction `DAY-SKIN-9` must work within". That extension does not
> hold: the entry's photo glyph is **record content**, not a mark about the screen, so it sits
> outside `DAY-DERIVE-3` entirely and never needed the presence-vs-quantity exemption. The claim
> above stands for *this* control, which is genuinely a screen mark.

**Why a cap, and why this one.** The grid's height is **unbounded** — photos are per *frame* with no
cap ([#684](https://github.com/jirigrill/eczema-helper/issues/684)) — so growth is the whole problem.
Measured on the #738 prototype (iPhone 17 Pro, 402×874 pt, 724 pt viewport, spike chrome excluded).
Every figure is the offset at which the meal section's header lands in the scroll content, so lower is
better:

| Photos | Uncapped | Capped, collapsed | Capped, expanded | Inner-scroll card |
| --- | --- | --- | --- | --- |
| 8 | 687 ✅ | 623 ✅ | 741 | 687 ✅ |
| 10 | 805 | 623 ✅ | 859 | 701 ✅ |
| 14 | 923 | 623 ✅ | 977 | 701 ✅ |
| 27 | 1395 | 623 ✅ | 1449 | 701 ✅ |
| 60 | 2693 | 623 ✅ | 2747 | 701 ✅ |

✅ = the meal header is above the fold without scrolling.

Four findings, each of which constrains something:

- **The crossover is between 8 and 10 photos** — one 118 pt row, exactly the estimate #727 handed
  forward. Uncapped, the meal section leaves the screen at the **4th row**, which is a plausible day
  rather than a pathological one. This is what makes a cap worth its cost.
- **Content exceeds the viewport in every configuration measured** — all 30 cells, including capped,
  collapsed, 8 photos (853 pt against 724 pt). The skin card alone already overflows. So the cap
  decides **how far down meals land, never whether she scrolls**, and no rule here should be read as
  promising a single-screen day.
- **`DAY-DERIVE-1` costs nothing here**, which `DAY-SKIN-8a` records.
- **An expanded cap is 54 pt worse than never capping** (741 vs 687 at 8 photos; 2747 vs 2693 at 60)
  — the 44 pt tap target plus spacing. A cap she expands on every visit is paid for twice. This is
  the cap's real risk, and it is a usage question the simulator cannot answer.

**The two candidates that lost.** *No cap* was measured and rejected: it is the only candidate whose
cost grows without bound, and it fails at a volume a single bad day reaches. *A card of bounded
height that scrolls internally* held meals at 701 pt even at 60 photos — the **best** number in the
table — and was still declined: it nests a scroll view inside a scroll view and leaves the grid with
no edge to reach. That is a feel judgement, made on the phone, and it is the reason the decision
needed a device rather than this table.

**What the cap does not settle.** The volumes above are stated as counts, not as evidence about real
days: 8 is #727's fixture and 60 is chosen to show the shape a year of scrolling must survive.
**Nobody has photographed a flare-up day** — the app has no users — so how often the reveal is tapped
is unmeasured, and that frequency is what decides whether the 54 pt is well spent. Worth revisiting
from real use rather than re-deciding on a simulator.

**Two rows, not three.** Two rows put the meal header at 623 pt against a 724 pt viewport, leaving
about 100 pt of the meal card on screen — enough that the section reads as present rather than as an
edge. A third row costs 118 pt and would place the header at 741 pt, below the fold, which defeats
the cap's only purpose.

> **⚠ Divergence 9.** *PWA:* the grid is **uncapped** and has no reveal control — every photo of the
> day renders (`SkinPhotoCard.svelte:47-70`), which is how the meal section comes to be cut at the
> bottom edge on an eight-photo day. *iOS:* two rows with a countless in-place reveal. *Why:* chosen
> by prototype ([#738](https://github.com/jirigrill/eczema-helper/issues/738)) over no cap and over an
> internally-scrolling card. Class: **resolved by #738**. Note this is the second thing the PWA's
> photo card loses on the way across, after the count (Divergence 8) — and that the two are the same
> rule twice: the card heads with `snimkyCs(photos.length)`, and a `+N more` reveal would have
> reintroduced exactly that quantity under a different name.

**`DAY-SKIN-9` (MUST)** — An observation entry that has photos shows a **single glyph** marking that
it does. One mark per entry, whatever the number of photos or of photographed regions, and it reads
as "photo" without prior learning — camera-like rather than an abstract dot or hairline.

Resolved by grilling → [#739](https://github.com/jirigrill/eczema-helper/issues/739); this rule's
original question answered, not a new rule. The exact icon is layout's, as with `DAY-MEAL-11`'s row
indication and `DAY-SKIN-2`'s note truncation. What the rule fixes is what she must be able to infer
without being taught, because a bare dot marks the row without saying why.

**Photo-presence is record content, and `DAY-DERIVE-1` does not reach it.** This rule was framed as
in tension with that prohibition, resolvable only as a presence mark rather than a quantity. **That
framing was wrong.** `DAY-SKIN-2` already displays the observation's *note* — content the record
holds, rendered as-is, and never called derived. Photo-presence is the same class: the record either
has photos attached or it does not. So an entry shows four kinds of record content — the time, the
region chips, the note, and photo-presence.

`DAY-DERIVE-1` bans *statements about her day synthesised from her records*: counts, totals, streaks,
days-since, badges, grading. `DAY-DERIVE-3` permits *marks about the screen* ("this slot is empty").
This is **neither**, and it is why `DAY-DERIVE-3` is **not amended** — adding photo-presence to its
enumeration would miscategorise it as chrome. The count remains prohibited by `DAY-DERIVE-1` alone,
which is why `DAY-SKIN-9a` does not restate it.

**Why a mark at all**, when the grid sits directly below on the same screen and this screen shows
only what she entered:

- **`SKIN-PHOTO-4`'s all-calm entry.** `SKIN-VIEW-2` insists an all-calm observation is an *explicit*
  entry, never an omission. Insisting an entry exist and then hiding what it holds is incoherent —
  and that entry is exactly the one the day-level grid detached from its photo.
- **The entry is the only route to editing or deleting a photo.** In the reference, tapping an entry
  opens the skin screen in edit mode, which loads the persisted photos and offers per-photo delete
  (`skin/+page.svelte:63-92`); `PhotoLightbox` is view-only, `onClose` its only handler. An entry
  giving no hint it holds photos is the entry she has no reason to open. This held however
  `DAY-SKIN-11` resolved, and it still holds now that it has: the viewer that tap opens deletes
  nothing (`SKIN-PHOTO-30`), so the entry — reachable from the viewer's own edit control
  (`DAY-SKIN-11c`) or directly — remains the only route to removing a photo.

`DAY-SKIN-7`'s caption already carries photo → entry. This rule closes the missing direction.

**Why the entry and not the region chip.** Photos attach to a *region* (`SKIN-PHOTO-3`), so marking
the chip would say *which* region was photographed — more information for the same pixels, and
rejected twice over: an all-calm entry has no region chips at all, so `SKIN-PHOTO-4`'s photo would
have to hang off the all-calm chip or vanish, breaking the case that motivated the rule; and two
photographed regions would show two marks, which reads as a quantity. One mark per entry cannot be
misread as a count, and the grid's caption names the region anyway.

**`DAY-SKIN-9a` (MUST NOT)** — The mark never renders photo content: not a thumbnail, not a crop, not
a blurred or shrunken frame.

This is the scope boundary of `DAY-SKIN-6`, stated as a rule so it is not rediscovered. Thumbnails
inside the entry are the shape #727 measured at 642 pt against the grid's 615 pt and **rejected on a
phone**; reaching them through an "indicator" would reopen settled placement. The line is drawn at
whether the mark shows photo pixels rather than at a size threshold, so it cannot be gamed by
shrinking: a 16 pt thumbnail is the worst case available — thumbnail-class conceptually, yet too small
to show a rash, paying the cost for none of the benefit.

**`DAY-SKIN-9b` (MUST NOT)** — The mark is not a tap target of its own.

The entry is already one tap target opening the skin screen in edit mode (`SKIN-VIEW-4`), which is
where photos are edited and deleted. A tappable glyph jumping to the photo in the grid would have
decided `DAY-SKIN-11` sideways; the mark is decoration inside the existing target, and `SKIN-VIEW-4`
remains the only tap behaviour on an entry. `DAY-SKIN-11`'s resolution does not disturb this — the
viewer is reached by tapping a **thumbnail in the grid**, never by tapping an entry or its mark.

> **⚠ Divergence 10.** *PWA:* no photo indicator on an observation entry —
> `SkinObservationCard.svelte` contains **zero** photo references, so a note-only entry and an
> all-calm-with-photo entry render identically in the shipped app, not merely in this spec.
> Photo-presence surfaces only in the day grid (with the count Divergence 8 drops), in the editor's
> gallery *after* the entry is opened, and in the view-only lightbox — so her answer to "does this
> entry have photos?" is *open it and see*. *iOS:* a single glyph on the entry. *Why:* the day-level
> grid ([#727](https://github.com/jirigrill/eczema-helper/issues/727)) detached photos from their
> entries, which made the gap a decision rather than an omission; settled by
> [#739](https://github.com/jirigrill/eczema-helper/issues/739). Class: **new behaviour** — this is
> the first rule in this section the reference does not implement in any form. Note there is no
> photo-marker idiom to inherit: `DESIGN.md`'s one parenthetical mention of "photo markers" is a
> corner-radius rule with no component behind it, so the glyph is chosen rather than matched.


**`DAY-SKIN-10` (MUST)** — The caption's time is **derived at render** from the photo's parent
observation, not stored on the photo record. A photo whose parent cannot be resolved renders its
region without a time, and never a broken or empty caption.

Inherited deliberately with the grid. The PWA builds an `observationId → H:MM` map on the page
(`day/[date]/+page.svelte:28-30`) and `SkinPhotoCard.svelte:11-19` documents the degradation:
orphans "shouldn't happen given the FK relationship, but we degrade silently rather than showing a
broken pill." Specified rather than left to be rediscovered, because on iOS the parent is resolved
through a SwiftData relationship and CloudKit **cannot enforce cascade delete**
([#679](https://github.com/jirigrill/eczema-helper/issues/679)) — so an orphan is reachable here in a
way it was not in the single-device PWA.

**`DAY-SKIN-11` (MUST)** — Tapping a thumbnail opens the **photo viewer** — a full-screen surface that
**pages through the day's photos**, flat and chronological, in the same order the grid shows them. The
tapped photo is where it opens. Its shared behavior is specified in
[`skin-observation.md` §5.5](skin-observation.md#55-the-photo-viewer); this rule fixes only what is
particular to the day view: the sequence is **the day**, and it is a single flat sequence rather than
one per observation.

Resolved by grilling → [#740](https://github.com/jirigrill/eczema-helper/issues/740); this rule's
original question answered, not a new rule. The PWA opens a full-screen lightbox showing **one** photo
with no paging (`PhotoLightbox.svelte`), and #727 was a placement prototype that never put tap
behaviour on a phone — so the PWA's answer was recorded as description, not requirement, and paging is
the part that is genuinely new.

**Why the day and not the observation.** The alternative was a pager scoped to the photos of the
observation the tapped photo belongs to. It was rejected because **the group boundaries are invisible in
the grid**: nothing on a thumbnail says where one observation's photos end, so paging would stop for a
reason she cannot see. The day-level sequence matches the surface she tapped from, which is the
governing principle for the pager's order throughout (`SKIN-PHOTO-24`).

**Why not region-grouped.** A third candidate grouped the sequence by region, so a region photographed
three times in a day would page as a series — the intra-day progression view. Declined here: it would
have the pager disagree with the grid's chronological order (`DAY-SKIN-6`), so the sequence she walks
would not be the one she just looked at. Region-major progression is a real idea with a real prior
effort behind it — map [#656](https://github.com/jirigrill/eczema-helper/issues/656) chartered a 2D
viewer with regions on one axis and each region's history on the other, and was **parked** with its
coordinate model never worked (see §10) — and it deserves its own surface, not a reinterpretation of
this grid's order.

**`DAY-SKIN-11a` (MUST)** — The viewer's sequence is **every photo of the day**, including photos
`DAY-SKIN-8`'s cap is not currently showing. Paging is not limited to the six visible thumbnails, and
its reach does not change according to whether the grid is expanded.

**This amends `DAY-SKIN-8a`'s stated cost, and does not violate it.** That rule accepts as a knowing
cost that from the collapsed grid "she cannot tell whether one photo is hidden or forty". She still
cannot — nothing anywhere reports the quantity (`DAY-SKIN-11b`) — but she can now **reach** the fortieth
by paging. The distinction is the same one `DAY-DERIVE-1` turns on: what is prohibited is a *number
rendered on a control*, because that is what "acquires a meaning she never recorded". Walking through
her own photographs one at a time is not a derived statement about her day; it is the record itself,
shown one item at a time.

The alternative — a pager reaching only what the grid currently shows — was rejected for a worse
failure than the disclosure it prevents: the same tap on the same thumbnail would page differently
depending on the grid's expansion state, which is invisible from inside the viewer.

**`DAY-SKIN-11b` (MUST NOT)** — The viewer displays no position and no extent. No "3 of 40", no page
dots, no scroll indicator that reveals the sequence's length.

**`DAY-DERIVE-1` reaches inside the viewer.** This is stated because it is not obvious: that rule is
written about the day view, and this is a full-screen surface covering it. The viewer is not a separate
product surface — it renders her records, is launched from the governed screen, and shows nothing the
day view could not. The rule's blanket form exists precisely so that "the first count is always the
reasonable one" is refused, and a position indicator is exactly that first reasonable count.

**Dots are the case worth naming**, because they look like an exemption and are not: forty dots *is* the
quantity `DAY-SKIN-8a` refuses, drawn rather than written. At the volumes this grid must survive they
are also illegible, so they would disclose the count without conveying the position.

Paired with `DAY-SKIN-11a`, the result is deliberate: **she can reach every photo and is never told how
many there are.** `SKIN-PHOTO-29`'s end-stop is what tells her a sequence has ended, and it is the only
signal of extent anywhere in the viewer.

**`DAY-SKIN-11c` (MUST)** — The viewer offers a control opening the tapped photo's observation in edit
mode, replacing the viewer. That editor returns to the **day view**, not to the viewer.

**Why an edit route exists here at all**, when `SKIN-VIEW-4` already makes the entry the way into the
editor: the prior design work on this screen recorded direct feedback from the primary user that she
**goes straight to the photo section on the day view and ignores the observation entries' chip list
entirely**. If that holds, the entry-only route sends her through a list she does not read. One control
is cheap, and this is the surface she is actually on.

**Where that claim comes from, and how far it reaches.** It is recorded in
`docs/design/HANDOFF-photo-surfacing.md` on the frozen repo's **unmerged** branch
`docs/photo-surfacing-handoff` (tip `76eca5d`), and restated in the body of
[#416](https://github.com/jirigrill/eczema-helper/issues/416), which is closed and postponed. Two
cautions, because this is the one rule in the group resting on reported behaviour rather than on a
prototype: the observation is about the **chip list** specifically, not the entry row as a whole, and
the handoff itself framed the consequence conditionally — the photo card is "possibly" the sole skin
surface, not demonstrably. It is enough to justify *adding one control* and would not be enough to
justify removing `SKIN-VIEW-4`'s route, which is why `DAY-SKIN-9`'s glyph and the entry tap both stay.
The branch is unmerged, so like #658's research it is **lost if pruned** (§10).

**Why it returns to the day view.** `DAY-ROOT-5` requires every editor to return to the day it was
opened from, and honouring it literally also avoids a three-deep stack — day → viewer → editor → viewer
— whose back behaviour nobody could predict. The viewer is transient; the day view is the root.

**The control is absent, not inert, for an orphan photo** (`DAY-SKIN-10`) — a photo whose parent cannot
be resolved has no observation to open. Nothing explains its absence: an explanation would be a sentence
about sync internals, and `settings.md` `SET-SYNC-1` sets the standing posture that the app does not
narrate healthy sync.

**Tapping the caption never navigates.** The caption is a label (`DAY-SKIN-7`); overloading it would make
an accidental tap move her, the class of mistake `skin-observation.md` `SKIN-INT-2`'s activate-then-cycle
rule exists to prevent.

**`DAY-SKIN-11d` (MUST)** — The viewer's sequence is **fixed when it opens**. A photo arriving from sync
while the viewer is open does not enter the sequence, re-sort it, or move her position; it appears in the
grid once she closes.

`DAY-LIVE-1` makes the grid live and `DAY-LIVE-2` promises that an arriving record "never moves her
position within it". A live sequence would break that promise in a way peculiar to paging: a photo
arriving at position 1 silently changes what a swipe means and how far the end is, so the sequence she is
walking stops being the one she started. Freezing also makes `SKIN-PHOTO-29`'s end-stop honest — the end
does not move while she is reaching for it. The staleness is transient and self-correcting, because
`DAY-LIVE-1` governs the grid, which is current the moment she returns to it.

> **⚠ Divergence 11.** *PWA:* tapping a thumbnail opens a single-photo lightbox — no paging, no zoom, no
> route onward; dismissed by an `×` or a backdrop tap (`SkinPhotoCard.svelte:74-80`,
> `PhotoLightbox.svelte`). *iOS:* a pager across the day's photos, with pinch-to-zoom, an edit route, and
> swipe-down dismissal. *Why:* the owner's call, against a recommendation to port the lightbox as-is
> view-only. The reasoning for the smaller option is recorded on
> [#740](https://github.com/jirigrill/eczema-helper/issues/740); what carried the day is that the grid
> shrinks a photograph to a thumbnail and the viewer is where the evidence is actually read, so reaching
> the next photo should not cost a round trip through the grid. Class: **resolved by #740**.

> **⚠ Divergence 12.** *PWA:* the day's photos are **not sorted** — `skin-photo-session.ts:23` returns
> `db.photos.where('observationId').anyOf(observationIds).toArray()`, which yields rows in index order,
> i.e. grouped by the parent's UUID rather than by time. *iOS:* chronological, as `DAY-SKIN-6` already
> requires. *Why:* **live defect in the shipped PWA.** `DAY-SKIN-6` was written as a `MUST` from the
> card's visual shape and the reference does not honour it; nothing tests the order. It is cosmetic in a
> grid and load-bearing in a pager, because paging *asserts* a sequence — `DAY-SKIN-11` and
> `SKIN-PHOTO-24` both rest on the grid's order being real. Class: **defect fixed**.

> **⚠ Divergence 4.** *PWA:* a day-level photo card below the observation list — a three-column grid
> of every photo taken that day, each captioned `region · time`, the time re-derived at render from
> an `id → time` map built on the page (`day/[date]/+page.svelte:28-30`,
> `SkinPhotoCard.svelte:65-69`). *iOS:* **the same shape**, minus the count. *Why:* chosen by
> prototype ([#727](https://github.com/jirigrill/eczema-helper/issues/727)) over the alternative of
> folding thumbnails into each entry. The pre-decision note recorded here — that the grid detaches a
> photo from its record and then spends a derived map re-attaching it, while `SKIN-VIEW-2` already
> makes the entry the unit she reads — was put to the phone and **did not win**; the derived map is
> accepted as the cost of the day-level view (`DAY-SKIN-10`). The measured alternative was also
> *taller*: folding eight thumbnails into entries grew the skin card to 642 pt against the grid's
> combined 615 pt. Class: **resolved by #727**. The count remains dropped (`DAY-DERIVE-1`,
> Divergence 8).

---

## 5. Empty states

**`DAY-EMPTY-1` (MUST)** — There is exactly one empty state per section. The app never distinguishes
*nothing logged* from *before the record began*.

It cannot. There is no install date, no onboarding-complete marker, and no first-set timestamp on
the feeding stage — [#712](https://github.com/jirigrill/eczema-helper/issues/712) established that
every candidate local marker either dies with the container on deletion or survives a backup restore
and lies. Introducing one to render different prose would add a durability-sensitive record for a
cosmetic distinction.

**`DAY-EMPTY-2` (MUST)** — Empty-state text names the **day shown**. It never says "today"
unconditionally.

> **⚠ Divergence 5.** *PWA:* both empty strings hardcode *today* — `"No record for today yet"` and
> `"No photo for today."` (`common.ts:39-40,51`) — and render unchanged on every past day, so the
> copy is simply false on any day but one. Nothing tests either string. *iOS:* the copy names the
> day shown. *Why:* defect. Class: **defect fixed**.

**`DAY-EMPTY-3` (MUST NOT)** — The meal section has no empty-state sentence. The four empty slots
*are* its empty state.

This is deliberate in the reference implementation too, and asserted by a regression test
(`page.test.ts:427`). Four tappable empty slots make an empty day actionable; a sentence saying
nothing is logged makes it blank.

**`DAY-EMPTY-4` (MUST NOT)** — There is no permanent instructional hint on the day view.

> **⚠ Divergence 6.** *PWA:* a hint reading *"Record everything via + : photo · meal · status"* is
> pinned to the bottom of the screen on every day, logged or not (`+page.svelte:134`). *iOS:* it is
> removed entirely — not made conditional on an empty day. *Why:* owner's call. A permanent
> instruction on a screen opened daily is read once and then occupies a line forever. The cost
> accepted knowingly: the add control (§7) explains itself or it does not get explained. Class:
> **owner's call, #715**.

---

## 6. The feeding stage, and what is derived

**`DAY-STAGE-1` (MUST NOT)** — The feeding stage is not displayed on the day view. No label, no
banner, no chip.

**`DAY-STAGE-2` (MUST NOT)** — The feeding stage cannot be changed from the day view. Settings owns
it.

The stage governs what may be **created**, never what is **shown**. Displaying it here would invite
reading a `baby` row that appeared under Divergence 2 as an inconsistency to be fixed — which is the
one reaction that turns a harmless re-ask into a lost record.

**`DAY-STAGE-3` (MUST)** — Records are never withheld, blanked, or replaced by empty slots because
the feeding stage is not yet known. The day view renders what it has.

> **⚠ Divergence 7.** *PWA:* a null stage yields an empty eligible-actor set, and because rows are
> mapped over that set (Divergence 2) every slot collapses to the empty state — so a fully logged
> day flashes blank on the first tick; separately, an unseeded read forces the header to today
> regardless of the date requested (`domain/day-view.ts:26-28`). *iOS:* rendering never waits on the
> stage. *Why:* defect, and the union rule makes it free to fix — under `DAY-MEAL-2` the stage is no
> longer an input to whether a meal renders at all. This is the same failure #712 exists to prevent:
> an empty screen that is really a not-yet-loaded screen. Class: **defect fixed**.

**`DAY-DERIVE-1` (MUST NOT)** — Nothing derived from her records is displayed on the day view. No
counts, no totals, no streaks, no days-since, no badges, no grading or colouring of days, and no
ordering by anything other than time and the fixed meal-type order.

**`DAY-DERIVE-2` (MUST NOT)** — No day-level severity is displayed, per `SKIN-VIEW-5` and
Divergence 13 in [`skin-observation.md`](skin-observation.md). The concept does not exist in this
product.

> **⚠ Divergence 8.** *PWA:* the photo card header renders a pluralised count of the day's photos
> (`SkinPhotoCard.svelte:38-44`) — the only count anywhere in the app. *iOS:* dropped. *Why:*
> `DAY-DERIVE-1`, and it survives in the reference only as a heading for the grid Divergence 4
> removes. Class: **settled by #715**.

**`DAY-DERIVE-3` (MUST)** — Marks that describe the *screen* rather than her records are not
"derived" in the sense of `DAY-DERIVE-1`, and are permitted: whether a row currently holds a meal
(`DAY-MEAL-11`), the add control's marking of meal types already logged that day (`DAY-ROOT-2`), and
the photo grid's reveal control, which appears only when the grid is hiding something (`DAY-SKIN-8`).

The distinction is what the mark is *about*. "This slot is empty" is a fact about the control she is
looking at. "You logged three meals today" is a statement about her day, and the moment a number
appears it acquires a meaning she never recorded. `DAY-DERIVE-1` is the blanket rule because the
first count is always the reasonable one.

The photo entry is the one that shows where the line actually falls. "There is more below" is about
the grid; "there are 34 more" is about her day — and the two differ by nothing but a number, which is
why `DAY-SKIN-8a` states the prohibition at the control rather than relying on this rule to imply it.

**`DAY-SKIN-9` is deliberately not in the list above**, and the omission is the point. The entry's
photo glyph is **record content** — the same class as the note (`DAY-SKIN-2`), the time and the region
chips — not a mark about the screen, so it needs no exemption from `DAY-DERIVE-1` and belongs in
neither rule. Settled by [#739](https://github.com/jirigrill/eczema-helper/issues/739), which found
the two-category framing (derived vs screen-mark) incomplete rather than the glyph borderline: there
are **three** kinds of thing on this screen, and only the first is prohibited. Adding the glyph here
would file her data as chrome.
Third entry added by [#738](https://github.com/jirigrill/eczema-helper/issues/738); the enumeration is
closed, so a fourth mark needs a decision, not an inference.

---

## 7. Navigation root

**`DAY-ROOT-1` (MUST)** — The day view is the app's home screen and its only navigation root. Every
other screen is entered from it and returns to it.

**`DAY-ROOT-2` (MUST)** — An add control on the day view offers exactly two things, both scoped to
the day shown: record a meal (choosing a meal type), and record a skin observation. Meal types
already logged on that day are marked as such.

**`DAY-ROOT-3` (MUST NOT)** — The add control is not offered on the editor screens themselves.

**`DAY-ROOT-4` (MUST)** — Settings is reached from the day view, and from nowhere else.

**`DAY-ROOT-5` (MUST)** — Every editor returns to the day it was opened from — not to today, and not
to the day it happens to have written to.

**`DAY-ROOT-6` (MUST)** — A meal copied to another day returns to the **destination** day, so that
the copy and its undo are both visible on the day they affected. See `CONTEXT.md` § _Copy Meal_ and
[`meal-editor-state-machine.md`](https://github.com/jirigrill/eczema-helper/blob/main/docs/spec/meal-editor-state-machine.md).

**`DAY-ROOT-7` (MUST)** — The undo affordance for a deletion performed inside an editor appears on
the day view, since that is where the editor returns to. Its mechanism — single-slot, in-memory,
short-lived, no trash — is settled by
[#687](https://github.com/jirigrill/eczema-helper/issues/687) and not reopened here.

**`DAY-LIVE-1` (MUST)** — The day view reflects records as they arrive, including records arriving
from sync, without any user action.

**`DAY-LIVE-2` (MUST)** — An arriving record never changes the day shown and never moves her
position within it.

`DAY-LIVE-1` also has a navigation consequence: the back edge in `DAY-NAV-4` is derived from the
earliest record she has, so it extends backwards on its own as older records arrive from sync.

---

## 8. Divergence index

| # | Section | Summary | Class |
| --- | --- | --- | --- |
| 1 | §2 `DAY-NAV-3` | Future days are unreachable; the PWA renders and logs seven of them. | Owner's call, #715 |
| 2 | §3.2 `DAY-MEAL-2/3` | Meal rows are the union of eligible and recorded actors; the PWA filters by eligible actors alone and hides the rest. | Settled by #712 |
| 3 | §3.2 `DAY-MEAL-5` | Actor rows are labelled when there is more than one; the PWA uses icons only. | Forced by Divergence 2 |
| 4 | §4 `DAY-SKIN-6` | The day-level photo grid carries over from the PWA, minus the count. | Resolved by #727 |
| 5 | §5 `DAY-EMPTY-2` | Empty-state copy names the day shown; the PWA says "today" on every day. | Defect fixed |
| 6 | §5 `DAY-EMPTY-4` | The permanent bottom hint is removed. | Owner's call, #715 |
| 7 | §6 `DAY-STAGE-3` | Records are never blanked while the stage is unknown; the PWA flashes a logged day empty. | Defect fixed |
| 8 | §6 `DAY-DERIVE-1` | The photo count is dropped — the app's only count. | Settled by #715 |
| 9 | §4 `DAY-SKIN-8` | The photo grid caps at two rows with a countless reveal; the PWA's grid is uncapped. | Resolved by #738 |
| 10 | §4 `DAY-SKIN-9` | An observation entry shows a glyph when it has photos; the PWA shows nothing. | New behaviour, #739 |
| 11 | §4 `DAY-SKIN-11` | Tapping a thumbnail opens a paging, zoomable viewer; the PWA's lightbox shows one photo. | Resolved by #740 |
| 12 | §4 `DAY-SKIN-6` | The day's photos are chronological; the PWA does not sort them at all. | Defect fixed |

Twelve divergences, of which three (5, 7 and 12) are live defects in the shipped PWA and one (2) is a
data-loss fix inherited from #712.

**`DAY-NAV-9`..`-9c` add no divergence, and that is worth saying.** Every other resolved rule in this
section changed something: the time-zone resolution is the one that ratifies the reference's existing
behaviour instead. The PWA already fixes the calendar date at log time and renders times in the
current zone — see `todayIso()` (`src/lib/utils/date.ts:14-16`) and `formatObservationTime`
(`:72-75`) — so `DAY-NAV-9` is a **port**, not a change. What differs is only that the behaviour is
now decided and stated rather than falling out of the fact that the date field happens to be a string,
which is why §9 lists it as *re-derive* with nothing to translate.

**Divergence 12 is the one a reader should not skim.** `DAY-SKIN-6` has required chronological order
since #715, and the reference has never honoured it: `skin-photo-session.ts:23` fetches the day's photos
with `anyOf(observationIds)`, which returns rows in the index's order — grouped by the parent's UUID.
Nothing tests the order, which is how a `MUST` came to be written from a card's appearance rather than
its behavior. It was cosmetic while the grid was the only surface; #740 made it load-bearing, because a
pager **asserts** a sequence and both `DAY-SKIN-11` and `SKIN-PHOTO-24` rest on the grid's order being
real rather than incidental.

---

## 9. Verification

### Where each rule is verified today

| Rules | Existing TypeScript tests | Verdict |
| --- | --- | --- |
| `DAY-NAV-1`, `-2` | none at page level; the redirect lives in `+layout.svelte:109-113` | **re-derive** |
| `DAY-NAV-3` | `page.test.ts:259-286` asserts a future date renders **without** redirect — i.e. it pins the behavior being diverged from | **do not translate** |
| `DAY-NAV-4`, `-5` | `day-strip.test.ts` (window computation, earliest-logged extension, no cap), `DayStrip.test.ts` (centring) | **translate** the window rules; **re-derive** the forward edge, which Divergence 1 changes |
| `DAY-NAV-6`, `-7` | `page.test.ts:298-321` (today ring carries no `data-recorded`) | **translate** — it is a regression guard against exactly the feature §2 prohibits |
| `DAY-NAV-8` | `page.test.ts:166-205` (chip presence, absence on today, navigation, recentre signal) | **translate**, minus the store-counter assertion, which is an implementation detail with no DOM consequence |
| `DAY-NAV-9`, `-9a`, `-9b`, `-9c` | **nothing** — no test in the reference ever reads a record from a second zone | **re-derive.** The PWA's dates survive a zone change only because the field is a string, so there is no behavioural test to translate; see §9's *Rules nothing verifies today*, which carries the two guards worth writing |
| `DAY-NAV-10`, `-11`, `-12` | `-12` only, via the header de-duplication tests `page.test.ts:207-257` | **translate** `-12`; `-10` and `-11` are **re-derive** |
| `DAY-NAV-13` | none — the reference renders seven future cells, so a record dated after today is reachable there by construction and there is no unreachable state to assert | **re-derive** entirely. Three assertions, all new and all cheap because none needs a zone change: with a record written one day ahead, the selector's forward edge is still today and no cell exists for that date; no screen shows any mark, count or message about it; and advancing today to that date makes it render as an ordinary record. The second is the regression guard — it is what keeps a "1 record ahead" courtesy out |
| `DAY-MEAL-1`, `-11` | `MealCard.test.ts:220` (all four types always render), `page.test.ts:398-428` | **translate** |
| `DAY-MEAL-2`, `-3`, `-4` | `page.test.ts:432-574` pins the **opposite** rule — breastfed collapses to one row, solids to a baby-only row | **do not translate**; re-derive against the union rule, and keep the `mixed` cases, which still hold |
| `DAY-MEAL-5` | none — the actor labels are never rendered, so nothing asserts them | **re-derive** |
| `DAY-MEAL-6` | `MealCard.test.ts:163,262` (no portion or preparation text on any logged row) | **translate** |
| `DAY-MEAL-7`, `-8`, `-9` | `page.test.ts:432-574` (hrefs carry type, date, actor, `returnTo`) | **translate** the parameter contract; the URL form itself is web-specific |
| `DAY-MEAL-10` | `MealCard.test.ts:130` (no swipe or long-press handlers) | **translate** as an absence check |
| `DAY-SKIN-1`..`-4` | `SkinObservationCard.test.ts`; ordering, chips, all-calm chip, absence of a count at `:244` | **translate** — but see `skin-observation.md` §11, which owns these |
| `DAY-SKIN-6`, `-7`, `-10` | `SkinPhotoCard.test.ts` — grid presence `:48`, one image per photo `:34`, the `region · time` caption `:101`, distinct times for two photos of one region `:114`, and **both** orphan paths `:132,146` | **translate** the grid, the caption format and the orphan degradation — `-10`'s rule is directly pinned. **Do not translate** the object-URL lifecycle or the count test `:80`, which asserts the count `DAY-DERIVE-1` drops. **`-6`'s ordering clause is verified by nothing and the reference violates it** (Divergence 12) — a fresh test, and a prerequisite for the pager |
| `DAY-SKIN-8`, `-8a`, `-8b` | none — the reference grid is uncapped, so there is no cap, no reveal control and no collapsed state to assert | **re-derive** entirely. Three assertions have no reference equivalent: that a 7th photo is not rendered collapsed, that the collapsed six are the chronologically **first** six (`-8b`), and that no numeral appears in the control's label in either state (`-8a`) — the last is the regression guard that keeps `+N more` from returning |
| `DAY-SKIN-9`, `-9a`, `-9b` | none — and the reference asserts the **opposite** by omission: `SkinObservationCard.test.ts` covers ordering, chips, the all-calm chip and the note without ever asserting a photo mark, because the component has none | **re-derive** entirely. Four assertions, all new: that an entry with photos shows the mark and one without does not; that an **all-calm** entry with a photo shows it (`SKIN-PHOTO-4`, the case the rule exists for); that an entry with many photos across several regions shows **exactly one** mark (the count guard); and that the mark renders no image and carries no tap handler (`-9a`, `-9b`) |
| `DAY-SKIN-11`, `-11a`..`-11d` | `SkinPhotoCard.test.ts:159-208` (lightbox open, × close, backdrop close) | **Do not translate.** These pin the single-photo lightbox Divergence 11 replaces — the backdrop-close test asserts a mechanism `SKIN-PHOTO-27` removes. Re-derive; `skin-observation.md` §5.5 owns the shared behavior, and four assertions are particular to this caller: the sequence spans the **day** (`-11`), it reaches photos the cap is hiding (`-11a`), no position or extent is shown in either orientation (`-11b`), and an arriving photo does not enter an open sequence (`-11d`). The last needs a sync double, and `-11b` is the regression guard that keeps "3 of 40" from arriving as a courtesy |
| `DAY-EMPTY-3` | `page.test.ts:427`, `MealCard.test.ts:31` (the empty sentence is asserted absent) | **translate** |
| `DAY-DERIVE-1` | `page.test.ts:290-296` (`task-counter` absent, "parked: daily-completeness") | **translate** — the single most valuable guard on this screen |
| `DAY-DERIVE-2` | none here; `skin-observation.md` owns it | **translate** from there |
| `DAY-ROOT-1`..`-7` | none at page level — the add control and the undo toast are layout-owned and are not rendered in the day view's tests at all | **re-derive** |
| `DAY-LIVE-1`, `-2` | `page.test.ts:398-428` drives a `liveQuery` meal into the page | **do not translate** as written — it asserts a Dexie reactivity guarantee; re-derive against sync arrival |

### Rules nothing verifies today

This is the honest list, and it is long for this screen.

- **Both empty-state strings.** Neither is asserted anywhere, which is how the "today" defect
  (Divergence 5) survived in shipped code. `DAY-EMPTY-2` is the first test either has ever had.
- **The stage-unknown path.** The page tests always reset settings to seeded/`breastfed`, so the
  null-stage branch — the one that blanks a logged day (Divergence 7) — is never exercised through
  the component at all.
- **The date selector as the page sees it.** Cell count, back-edge extension and forward edge are
  tested in the strip's own unit tests; the page never asserts what it computed, and tapping a cell
  from the page is untested.
- **Midnight rollover** (`DAY-NAV-10`) and **time zones** (`DAY-NAV-9`, `-9a`, `-9b`, `-9c`) —
  nothing anywhere. Both are **re-derive**, and the time-zone rules are the more urgent of the two:
  the PWA has no test that reads a record from a second zone at all, which is how a `MUST` about
  dates came to rest entirely on the fact that its date field happens to be a string. Two guards are
  cheap and pin the decision rather than the implementation: a record written in one zone reads under
  the **same** calendar date after the zone changes (`DAY-NAV-9`, `-9b`), and the same record's
  **time of day** re-renders in the new zone (`-9c`). The prototype drives the real zone via
  `SIMCTL_CHILD_TZ`, so this is testable on a simulator without a plane.
- **Records dated after today** (`DAY-NAV-13`) — nothing, and nothing could: the reference's forward
  edge renders seven future cells, so the state the rule governs does not exist there. Worth
  separating from `DAY-NAV-9` above, because unlike the time-zone question this one is testable
  **without** a zone change at all — a record written a day ahead reaches the same state.
- **The add control** (`DAY-ROOT-2`, `-3`) — layout-owned and absent from the day view's test file.
- **The observation entry's return destination** and **notes on entries** (`DAY-SKIN-2`).
- **Shape-valid impossible dates.** The reference's date validation is a regex, so `2025-02-31`
  passes and renders a day. iOS date types make this unrepresentable — which is the preferred
  resolution, not a test.

### Acceptance pass

Instructions for a person holding a phone. Steps marked **✗ PWA** are expected to fail on the
reference implementation — those are the divergences, and they are what prove the port did
something.

1. Launch the app cold. It opens **today**, and the header says *Today* without a date
   (`DAY-NAV-1`, `-12`).
2. Move back a few days, then force-quit and relaunch. It opens today again, not the day you were
   on (`DAY-NAV-1`).
3. Try to reach tomorrow. You cannot — there is no cell past today and no gesture that gets there
   (`DAY-NAV-3`). **✗ PWA**
4. Scroll the selector back as far as it goes. It stops at the earlier of a week ago and your
   oldest record, and there is no date picker anywhere (`DAY-NAV-4`, `-11`).
5. Look at the selector cells: no cell tells you whether that day has anything in it, including
   today's (`DAY-NAV-7`).
6. Move to an older day, then use the return-to-today control (`DAY-NAV-8`).
7. On a day with nothing logged: all four meal slots are present and tappable, there is **no**
   sentence saying nothing is logged, and there is **no** permanent hint at the bottom of the
   screen (`DAY-MEAL-1`, `DAY-EMPTY-3`, `-4`). **✗ PWA** on the hint.
8. On that same empty day, read the skin section's empty text: it names **that day**, not "today"
   (`DAY-EMPTY-2`). **✗ PWA**
9. Log a meal from an empty slot. You return to **the day you were on**, not today
   (`DAY-MEAL-7`, `DAY-ROOT-5`).
10. Look at the logged row: food names only — no amounts, no preparation, no time (`DAY-MEAL-6`).
11. In Settings, set the stage to `mixed` and log a meal for the baby. Return to the day view: two
    actor rows, each **labelled** with whose it is (`DAY-MEAL-5`). **✗ PWA** — the reference shows
    icons only.
12. Now set the stage to `breastfed` and return to that day. The baby's meal is **still there**,
    rendered as an ordinary row with no marking, and still opens for editing (`DAY-MEAL-2`, `-3`).
    **✗ PWA** — the reference hides it entirely.
13. Delete the app, reinstall, and tap through onboarding accepting the default stage. Once your
    records arrive, every meal is visible regardless of which actor logged it, and nothing on the
    screen blanks while the stage is resolving (`DAY-STAGE-3`). **✗ PWA**
14. Record two skin observations on one day, one all-calm. Both appear as separate entries, in time
    order, and the all-calm one is visibly an entry rather than an omission
    (`DAY-SKIN-1`).
15. Attach a photo to an observation. It appears in the photo card **below** the observation list,
    in a three-column grid, captioned with its region and the observation's time (`DAY-SKIN-6`,
    `-7`). Confirm **no** count of photos appears anywhere on the day view (`DAY-DERIVE-1`,
    Divergence 8). **✗ PWA**
16. Record seven or more photos across the day. The grid shows **six**, in two rows, and a control
    offering the rest. Read that control closely: it names **no number** (`DAY-SKIN-8`, `-8a`).
    **✗ PWA** — the reference shows every photo and has no control at all.
17. Tap it. The rest appear in place, and the control now offers to collapse again; tap it and you are
    back to six. Confirm the six shown collapsed are the **earliest** six of the day, not a selection
    (`DAY-SKIN-8b`).
18. On that same heavy day, confirm the meal section is reachable by scrolling, and note that it is
    below the fold — the cap shortens the day, it does not fit it on one screen.
19. Still on that day, tap the **first** thumbnail. It fills the screen showing its region and the
    parent observation's time (`DAY-SKIN-11`, `SKIN-PHOTO-26`). Swipe sideways all the way to the
    right: you reach photos the collapsed grid was **not** showing, and the grid's expansion state
    made no difference to how far you got (`DAY-SKIN-11a`). **✗ PWA** — the reference lightbox shows
    one photo and does not page (Divergence 11).
20. In that viewer, look for anything telling you where you are or how many there are: no "3 of 40",
    no dots, no scroll bar. There is none, in either orientation (`DAY-SKIN-11b`) — this is the guard
    that keeps a helpful count from arriving later.
21. Use the viewer's control to open the photo's observation. It replaces the viewer, and when you
    leave the editor you land on the **day view**, not back in the viewer (`DAY-SKIN-11c`,
    `DAY-ROOT-5`). **✗ PWA**
22. With the viewer open on today, add a photo from a second device. Your position does not move and
    the new photo does not join the sequence; close the viewer and it is in the grid
    (`DAY-SKIN-11d`).
23. Look at the observation list on a day where one entry has photos and another does not: the one
    with photos carries a small mark, the one without carries none, and you can tell which is which
    without opening either (`DAY-SKIN-9`). The mark shows **no** picture and **no** number, and
    tapping it does the same thing as tapping the row — it opens the observation for editing
    (`DAY-SKIN-9a`, `-9b`). **✗ PWA** — the reference marks nothing.
24. Attach a photo to an **all-calm** observation and look at its entry. It carries the mark too
    (`SKIN-PHOTO-4`) — this is the case the rule exists for, and the one that is invisible without
    it. Then attach several photos across two regions to one observation and confirm the entry still
    shows **exactly one** mark (`DAY-SKIN-9`). **✗ PWA**
25. Read the entire screen and confirm there is no number on it that you did not enter yourself: no
    meal count, no streak, no severity for the day, no completeness indicator (`DAY-DERIVE-1`,
    `-2`).
26. Confirm the feeding stage appears nowhere on this screen and cannot be changed from it
    (`DAY-STAGE-1`, `-2`).
27. Delete a meal from inside the editor. You return to the day view and the undo appears there
    (`DAY-ROOT-7`). Confirm you cannot delete anything by swiping on the day view itself
    (`DAY-MEAL-10`).
28. Copy a meal to another day. You land on the **destination** day (`DAY-ROOT-6`).
29. With the app open on today, add a record from a second device (or wait for one to arrive).
    It appears without you doing anything, and your position on the screen does not move
    (`DAY-LIVE-1`, `-2`).
30. On a second device, set the clock forward a day, log a meal there, and let it sync. On **this**
    phone the selector's forward edge is still today, there is no cell for tomorrow, and nothing
    anywhere — selector, meal section, skin section, settings — hints that a record exists ahead
    (`DAY-NAV-13`, `DAY-NAV-3`, `DAY-NAV-7`). Then set **this** phone forward a day: the meal is
    there, on an ordinary day, indistinguishable from any other record. **✗ PWA** — the reference
    renders and logs seven future cells, so the record was reachable all along (Divergence 1).
31. **The zone change.** Log a meal and an observation, noting the day they land on and the time the
    observation's entry shows. Then move the device to a zone far enough east or west to change the
    calendar date — Settings › General › Date & Time with *Set Automatically* off, or a simulator
    launched under `SIMCTL_CHILD_TZ`. Reopen the app: **both records are still on the day you logged
    them**, and neither has moved to a neighbouring day (`DAY-NAV-9`, `-9b`). The observation's
    **time of day** has re-rendered to the new zone, so an evening entry may now read as a morning
    one (`DAY-NAV-9c`) — this is intended, and it is the cost that rule records.
32. Still in the far zone, log something new. It files under **that** zone's calendar date, not your
    home zone's (`DAY-NAV-9a`). Then return the device to your home zone and confirm the record from
    step 31 has **not** moved back, forward, or anywhere at all (`DAY-NAV-9b`) — a policy that looks
    correct while travelling and rewrites history on return is exactly what
    [#728](https://github.com/jirigrill/eczema-helper/issues/728) rejected.
33. If crossing the date line for real, expect a day you flew over to show as **empty** with records
    either side (`DAY-NAV-9`), and expect nothing on the screen to characterise that emptiness as a
    lapse (`DAY-DERIVE-1`, `DAY-NAV-7`). Travelling **west** can also strand a record ahead of today,
    which step 30 covers by clock instead (`DAY-NAV-13`). One further effect is **out of scope here**
    and tracked separately: a second breakfast silently overwriting the first on a twice-lived date
    ([#744](https://github.com/jirigrill/eczema-helper/issues/744)).

---

## 10. Open questions

**~~`DAY-SKIN-6` — where photos appear on the day view.~~ Closed by
[#727](https://github.com/jirigrill/eczema-helper/issues/727): the PWA's day-level grid carries
over.** Decided on a phone with all three candidates side by side, which is what made it unanswerable
on paper. `DAY-SKIN-5` is retired with it — the prohibition it held existed only to keep the
prototype unprejudiced. **Three questions opened in its place**, none of which the placement
prototype tested: whether the uncapped grid limits its visible rows (~~`DAY-SKIN-8`~~ → **closed by
[#738](https://github.com/jirigrill/eczema-helper/issues/738): two rows, countless reveal**), whether an
entry indicates it carries photos (~~`DAY-SKIN-9`~~ → **closed by
[#739](https://github.com/jirigrill/eczema-helper/issues/739): a single glyph, no photo content, not a
tap target**), and what a tap
does (~~`DAY-SKIN-11`~~ → **closed by
[#740](https://github.com/jirigrill/eczema-helper/issues/740): a viewer paging the day's photos, no
position indicator, an edit route, no deletion**). None was schema deadlined; all read records that
already exist. **All three are now settled, so the group #727 opened is closed.** Two findings from
those resolutions outlive them: #739 established that photo-presence is *record content* rather than a
derivation — so `DAY-DERIVE-1` constrains neither the glyph nor anything else in the group beyond the
count it already banned — and #740 established that the same rule reaches inside a full-screen surface
launched from this screen, which is why the viewer shows no "3 of 40".

**~~`DAY-NAV-9` — time zones.~~ Closed by
[#728](https://github.com/jirigrill/eczema-helper/issues/728): the calendar date is fixed at log time
and never recomputed; time of day renders in the current zone.** Settled by prototype rather than by
argument — built and handed over by
[#742](https://github.com/jirigrill/eczema-helper/issues/742), which is also where the numbers behind
it are computed. It did **not** need the iOS app to exist, which is the one thing this entry got
wrong: `SIMCTL_CHILD_TZ` makes a simulator report any zone, so the question was decidable without
carrying a phone across a boundary. The rest held — it was not schema-deadlined, and the resolution
confirms why: `persistence-model.md` `DATA-MEAL-3`'s calendar-day label is exactly the shape the
answer needed, so nothing in the schema moved.

Two neighbouring effects are **not** closed by it. A record dated after today is **now settled
separately** as `DAY-NAV-13` ([#743](https://github.com/jirigrill/eczema-helper/issues/743), the entry
directly below), and it is worth knowing the two resolutions landed independently and agree: fixing
the date at log time is what creates the stranded state, and `DAY-NAV-13` is what says the app does
nothing about it. Still ticketed and unwritten: the meal-slot collision on a twice-lived date
([#744](https://github.com/jirigrill/eczema-helper/issues/744), §3.5 and the persistence section), a
**write**-side `INV-4` upsert that no date-resolution rule touches. **Daylight saving is untested** by
the prototype, whose fixture crosses no DST transition.

**~~What happens to a record dated after today.~~ Closed by
[#743](https://github.com/jirigrill/eczema-helper/issues/743): nothing — it is unreachable and
unsurfaced until today reaches its date (`DAY-NAV-13`).** Found by #728's spike and named by none of
its cases. It is independent of `DAY-NAV-9`: the state appears under two of the three date policies
and is a property of `DAY-NAV-3` meeting a backwards-moving today, so #728 may resolve either way
without reopening it. Two findings from that resolution outlive it. The trigger is **not** travel —
under mandatory sync a second device in another zone reaches the state with nobody crossing anything
(#705), which is why the rule is phrased over the record's date rather than over a journey. And the
gap is bounded at **one day** by the ~26-hour span of zone offsets, which is what makes the silence
`DAY-NAV-7` and `DAY-DERIVE-1` already required acceptable rather than merely unavoidable.

**~~Where a sync-health indicator would live.~~ Closed by
[#723](https://github.com/jirigrill/eczema-helper/issues/723): no positive indicator exists, on any
screen.** `settings.md` `SET-SYNC-1` makes it a prohibition rather than an absence — no API can report
that the store is synchronised, so a "synced" mark would assert what cannot be known. The day view is
therefore **not** a host for one, and `DAY-DERIVE-3`'s enumeration of permitted marks gained nothing
from #723. (It has since gained a third entry from
[#738](https://github.com/jirigrill/eczema-helper/issues/738) — the photo grid's reveal control — which
does not disturb this: a sync mark is still prohibited, and for a different reason, that it would
assert what cannot be known rather than what she did not record.)
What can reach this screen is a **failure** banner, and only under two conditions: a persistent upload
failure (`SET-SYNC-5`), or a failed download while the store is empty (`SET-SYNC-6`) — the
[#712](https://github.com/jirigrill/eczema-helper/issues/712) case where an empty screen reads as total
data loss. Neither is a mark about her records, so neither touches `DAY-DERIVE-1`.

**Duplicate rows under sync.** §3.5 records that the day view is where a CloudKit-side duplicate
would become visible. Whether anything on this screen should *react* to one — merge, flag, or simply
show both — is the persistence section's question, not this one's.

**A region-major progression viewer, and the parked map behind it.** `DAY-SKIN-11`'s viewer pages the
day flat and chronological. It deliberately does **not** answer "how has this elbow changed over
weeks", which is a different surface with its own charted effort:
[#656](https://github.com/jirigrill/eczema-helper/issues/656) specified a 2D viewer — regions across
one axis, each region's history down the other — and was **parked** on 2026-08-11 with its children
closed as *not planned* rather than resolved. Its one genuinely resolved ticket,
[#658](https://github.com/jirigrill/eczema-helper/issues/658), surveyed prior art and found that no
mainstream viewer commits to a true 2D gesture grid, and that the derm apps closest to this data model
answer the comparison question with an explicit **two-up compare** rather than a browse grid — pushback
on the 2D premise that was never addressed, because the coordinate model
([#657](https://github.com/jirigrill/eczema-helper/issues/657)) was never worked.

Two things about it matter for iOS. Its findings on mechanism are **web-specific** and do not carry:
scroll-snap, transform paging, `100svh`, `role="grid"`. Its findings on *what people actually do with
serial skin photographs* are platform-independent and are the best available input if this is ever
resumed. And #658's artifact is at risk: `docs/research/photo-2d-nav.md` exists only on the unmerged
throwaway branch `research/photo-2d-nav` (commit `a584d9f`) in the frozen repo — **the only record
outside the tracker, lost if that branch is pruned.**

Nothing in `DAY-SKIN-11` forecloses this. A flat day pager and a region-major history viewer can
coexist; what the spec refuses is making *this* grid's tap mean the second thing (see §4).

---

## 11. Appendix: what this section does not contain

- **The meal editor.** Fixed-at-entry parameters, the three state machines, dirtiness, save, delete,
  undo and copy all belong to [`meal-editor-state-machine.md`](https://github.com/jirigrill/eczema-helper/blob/main/docs/spec/meal-editor-state-machine.md). That
  document was extracted **before** this format existed, so it has no rule ids, no strength marks
  and no invariant disposition table; cross-references to it are by section number.
- **The skin observation screen.** [`skin-observation.md`](skin-observation.md) owns it, including
  the `SKIN-VIEW-1..5` rules this section cites without restating.
- **First run and the feeding stage picker.** Owned by the first-run section; the day view's only
  relationship to the stage is stated in §6.
- **Settings.** Owned by the settings section; §7 records only that the day view is the way in.
- **The persistence model** — schema, sync configuration, dedupe, and the account-state model.
- **Layout, colour, typography, component names, and the shape of the date selector as a control.**
  Rules here constrain which days are reachable and what is shown, never how it looks.
- **Invariant text.** Cited by anchor, never copied.

**On the design prototype:** `redesign-prototype.html` in the frozen repo depicts a day view, and
for this screen it is **partly stale** — it still shows the pre-descaling protocol surfaces
(programme timeline, conflict detection) that were removed, and its photo section is a historical
placeholder. The live variant for this screen is the shipped route at `582f662`, not the prototype.
Do not consult the prototype for the meal rows, the date selector, or anything photo-related.
