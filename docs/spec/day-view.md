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
   blanket prohibition rather than leaving it to the absence of features.

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

Two terms this section uses are shared with settings and defined in
[`GLOSSARY.md`](GLOSSARY.md): **feeding stage** and **eligible actors**. *Recorded actors* above is
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

**`DAY-NAV-9` (OPEN)** — What the day view does when she crosses a time zone is undecided →
[#728](https://github.com/jirigrill/eczema-helper/issues/728). The recommendation recorded there,
not asserted here: dates are calendar dates fixed at log time, never instants, never recomputed in
a later zone. **No schema deadline** — the record already carries both a calendar date and a
`createdAt` instant, so either resolution is expressible in the shape that ships.

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

**`DAY-SKIN-5` (MUST NOT)** — Until `DAY-SKIN-6` is resolved, an observation entry shows no photo
indicator of any kind — no thumbnail, no glyph, no count.

An indicator is the smallest possible version of the decision `DAY-SKIN-6` defers, and shipping one
would pre-empt the prototype.

**`DAY-SKIN-6` (OPEN)** — Where a day's photos appear on the day view, if anywhere, is undecided →
[#727](https://github.com/jirigrill/eczema-helper/issues/727). To be settled **by prototype, once
the iOS app exists** — the two candidate shapes (a separate day-level grid as the PWA has, or
thumbnails folded into the observation entry) differ in a way that is judged by looking, not by
argument. **No schema deadline**; both read the same records.

> **⚠ Divergence 4.** *PWA:* a separate day-level photo card below the observation list — a
> three-column grid of every photo taken that day, each captioned `region · time`, where the time is
> re-derived at render from an `id → time` map built on the page
> (`day/[date]/+page.svelte:28-30`, `SkinPhotoCard.svelte:65-69`). *iOS:* nothing ships until
> #727 resolves. *Why:* the owner declined to settle it on paper. Recorded for whoever runs the
> prototype: the grid detaches a photo from the record it belongs to and then spends a derived map
> re-attaching it, while `SKIN-VIEW-2` already makes the observation entry the unit she reads.
> Class: **deferred to #727**.

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
(`DAY-MEAL-11`), and the add control's marking of meal types already logged that day (`DAY-ROOT-2`).

The distinction is what the mark is *about*. "This slot is empty" is a fact about the control she is
looking at. "You logged three meals today" is a statement about her day, and the moment a number
appears it acquires a meaning she never recorded. `DAY-DERIVE-1` is the blanket rule because the
first count is always the reasonable one.

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
| 4 | §4 `DAY-SKIN-5/6` | No day-level photo grid ships; display deferred to prototype. | Deferred to #727 |
| 5 | §5 `DAY-EMPTY-2` | Empty-state copy names the day shown; the PWA says "today" on every day. | Defect fixed |
| 6 | §5 `DAY-EMPTY-4` | The permanent bottom hint is removed. | Owner's call, #715 |
| 7 | §6 `DAY-STAGE-3` | Records are never blanked while the stage is unknown; the PWA flashes a logged day empty. | Defect fixed |
| 8 | §6 `DAY-DERIVE-1` | The photo count is dropped — the app's only count. | Settled by #715 |

Eight divergences, of which two (5 and 7) are live defects in the shipped PWA and one (2) is a
data-loss fix inherited from #712.

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
| `DAY-NAV-10`, `-11`, `-12` | `-12` only, via the header de-duplication tests `page.test.ts:207-257` | **translate** `-12`; `-10` and `-11` are **re-derive** |
| `DAY-MEAL-1`, `-11` | `MealCard.test.ts:220` (all four types always render), `page.test.ts:398-428` | **translate** |
| `DAY-MEAL-2`, `-3`, `-4` | `page.test.ts:432-574` pins the **opposite** rule — breastfed collapses to one row, solids to a baby-only row | **do not translate**; re-derive against the union rule, and keep the `mixed` cases, which still hold |
| `DAY-MEAL-5` | none — the actor labels are never rendered, so nothing asserts them | **re-derive** |
| `DAY-MEAL-6` | `MealCard.test.ts:163,262` (no portion or preparation text on any logged row) | **translate** |
| `DAY-MEAL-7`, `-8`, `-9` | `page.test.ts:432-574` (hrefs carry type, date, actor, `returnTo`) | **translate** the parameter contract; the URL form itself is web-specific |
| `DAY-MEAL-10` | `MealCard.test.ts:130` (no swipe or long-press handlers) | **translate** as an absence check |
| `DAY-SKIN-1`..`-4` | `SkinObservationCard.test.ts`; ordering, chips, all-calm chip, absence of a count at `:244` | **translate** — but see `skin-observation.md` §11, which owns these |
| `DAY-SKIN-5`, `-6` | none | **re-derive** once #727 resolves |
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
- **Midnight rollover** (`DAY-NAV-10`) and **time zones** (`DAY-NAV-9`) — nothing anywhere.
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
    (`DAY-SKIN-1`). Confirm no photo indicator appears on either entry (`DAY-SKIN-5`).
15. Attach a photo to an observation. Confirm **no** count of photos appears anywhere on the day
    view (`DAY-DERIVE-1`, Divergence 8). **✗ PWA**
16. Read the entire screen and confirm there is no number on it that you did not enter yourself: no
    meal count, no streak, no severity for the day, no completeness indicator (`DAY-DERIVE-1`,
    `-2`).
17. Confirm the feeding stage appears nowhere on this screen and cannot be changed from it
    (`DAY-STAGE-1`, `-2`).
18. Delete a meal from inside the editor. You return to the day view and the undo appears there
    (`DAY-ROOT-7`). Confirm you cannot delete anything by swiping on the day view itself
    (`DAY-MEAL-10`).
19. Copy a meal to another day. You land on the **destination** day (`DAY-ROOT-6`).
20. With the app open on today, add a record from a second device (or wait for one to arrive).
    It appears without you doing anything, and your position on the screen does not move
    (`DAY-LIVE-1`, `-2`).

---

## 10. Open questions

**`DAY-SKIN-6` — where photos appear on the day view.**
[#727](https://github.com/jirigrill/eczema-helper/issues/727). Not answerable on paper: the two
candidate shapes differ in how a photo relates to the record it came from, which is judged by
looking. **To be prototyped once the iOS app exists**, not before. Nothing depends on it except
`DAY-SKIN-5`, which holds the placeholder open by shipping no indicator at all. **No schema
deadline** — both shapes read records that already exist.

**`DAY-NAV-9` — time zones.**
[#728](https://github.com/jirigrill/eczema-helper/issues/728). Also a prototype, and also **once the
iOS app exists**: it is judged by carrying a phone across a boundary. Worth stating explicitly that
this is **not** schema-deadlined, because an open question about dates reads like one under #679's
additive-only promotion rule — the record already carries both a calendar date and a `createdAt`
instant, so either resolution is expressible in the shape that ships.

**Where a sync-health indicator would live.**
[#723](https://github.com/jirigrill/eczema-helper/issues/723) owns whether one exists at all, and
inherits a hard constraint (a verdict only when an event has ended, or it cries wolf on every
launch). If one ships, the day view is its most likely host, being the only screen she reliably
opens. This section does not reserve a place for it and does not assume one is coming.

**Duplicate rows under sync.** §3.5 records that the day view is where a CloudKit-side duplicate
would become visible. Whether anything on this screen should *react* to one — merge, flag, or simply
show both — is the persistence section's question, not this one's.

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
