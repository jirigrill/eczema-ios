# Meal editor — behavior specification

**Status:** written to the settled format ([`TEMPLATE.md`](TEMPLATE.md)). Not yet owner-confirmed;
the adjudications in §13 are the agent's under [#690](https://github.com/jirigrill/eczema-helper/issues/690)'s
coherence default, not the owner's answers to questions put to him.
**Behavior reference:** `jirigrill/eczema-helper` @ `449019e` (frozen PWA) —
`src/lib/domain/working-meal.ts`, `src/lib/domain/meal-dirtiness.ts`,
`src/lib/stores/meal-editor.svelte.ts`, `src/routes/meal/`.
**Resolves:** [#753](https://github.com/jirigrill/eczema-helper/issues/753) on the transition map
[#672](https://github.com/jirigrill/eczema-helper/issues/672). Supersedes, for the port,
[`meal-editor-state-machine.md`](https://github.com/jirigrill/eczema-helper/blob/main/docs/spec/meal-editor-state-machine.md)
on the frozen repo — see *What happened to the other document* below.

## Overview

The meal editor is the screen on which one meal is composed or edited. It is the app's primary write
path and the largest behavior surface in the product: the mother picks foods from a bundled catalog,
gives each an amount and an optional preparation, optionally writes a note, and saves. That is the
whole feature. Nothing is derived from it
([INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11)).

This document states what the screen does, in English, without reference to Swift, SwiftUI,
SwiftData, Svelte, Dexie, or the Czech interface. Swift tests are derived from the numbered rules;
the owner's acceptance pass is derived from §12.1.

Four things about this screen are worth knowing before the rules make sense:

1. **Three state machines cooperate, and they are separate on purpose.** A *per-food* machine
   decides what one food in the draft is doing (§2). A *visit* machine decides whether this is a
   new meal or a change to a saved one (§4). An *exit* machine decides what happens when she leaves
   (§9). Most of the reference implementation's defects were one machine reaching into another's
   question.
2. **Nothing reaches storage until she saves.** Every transition in §2 and §3 rewrites an in-memory
   draft. There is exactly one write path (§7), which is what makes the exit rules in §9 the only
   place data can be lost.
3. **Two questions look identical and are not.** *Can this be saved?* counts only foods she
   finished picking. *Would leaving lose something she did?* — [`GLOSSARY.md`](GLOSSARY.md)'s
   **pending work** — counts what she started too. The reference implementation asked one question
   where there are two, and that conflation is the single largest correction in this document (§3.3,
   §3.4).
4. **A meal is identified by its slot, not by its contents.** One meal per day, meal type and actor
   ([INV-4](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-4)); the slot is
   fixed when the screen opens and only the actor can move (§1.1, §6). She never chooses between two
   meals in one slot, and never sees a save that could overwrite one.

### How to read this document

Every rule has a **stable id** — `MEAL-<group>-<n>` — and states a single testable claim. Ids are
permanent identity, never renumbered or reused; a new rule appends the next unused number in its
group. Cite them from code comments, tests, and commit messages. **Rule strength** is marked on
every rule, on [`TEMPLATE.md`](TEMPLATE.md)'s five-mark scale — **MUST**, **MUST NOT**, **SHOULD**,
**PWA**, **OPEN** — whose meanings are stated in
[`skin-observation.md`](skin-observation.md#how-to-read-this-document) and are not restated here.

An **OPEN** rule is never silently resolved by an implementer. **This section has one**
(`MEAL-DEG-4`), and it is listed in §13 with what it waits on.

### What happened to the other document

This section replaces
[`meal-editor-state-machine.md`](https://github.com/jirigrill/eczema-helper/blob/main/docs/spec/meal-editor-state-machine.md),
which was extracted by [#674](https://github.com/jirigrill/eczema-helper/issues/674) **before** the
spec format existed and therefore carried no rule ids, no strength marks, no disposition table, no
divergence index and no verification verdicts. It lived on the frozen repo and was reachable only by
hyperlink, which [#721](https://github.com/jirigrill/eczema-helper/issues/721)'s self-sustaining rule
forbids for a spec section.

**Read that document only as a description of the reference implementation.** Everything it
established is carried here: its three-machine framing, its per-food transition table, its
persistence boundary, its label chain, and its sixteen open questions — of which seven were struck
by [#689](https://github.com/jirigrill/eczema-helper/issues/689) and
[#690](https://github.com/jirigrill/eczema-helper/issues/690), and **the remaining nine are
adjudicated in §13 of this document**. Its fifteen `Port rule` blocks
([#746](https://github.com/jirigrill/eczema-helper/issues/746)) are now ordinary rules with ids and
marks, at §3.3, §3.4, §4.4, §6.1, §9.3 and §9.5 there.

Its value from here on is **archaeological**: it records what the TypeScript did, line by line, and
is the thing to consult when a rule here looks arbitrary and the question is *what was it before*.

### Invariant dispositions

Invariants are **cited, never restated** — the numbered `INV-n` list in the frozen repo's
`CONTEXT.md` is their single home. But four are deliberately false for iOS, so a bare citation could
import a contradiction. [#691](https://github.com/jirigrill/eczema-helper/issues/691) classified all
fourteen; the ones this section touches carry an explicit disposition.

| Ref | Leading phrase | Disposition here |
| --- | --- | --- |
| [INV-3](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-3) | _Meals are day-granular_ | **Holds unchanged.** No meal records a time of day, and none is displayed (`MEAL-ENTRY-2`). It never promised to separate two meals inside one slot — see `DATA-ID-2`. |
| [INV-4](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-4) | _One `Meal` per date+mealType+actor slot_ | **Enforcement moved.** The store no longer guarantees it; the app converges on it (`persistence-model.md` §4). For *this* screen nothing changes: `DAY-MEAL-8` opens every occupied slot in edit, so no interface path writes a second meal into a slot (`MEAL-ENTRY-1`). The invariant's own "upserted, not appended" wording stays PWA-accurate deliberately. |
| [INV-8](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-8) | _`id` and `createdAt` immutable across edit, delete, undo_ | **Holds unchanged, and is extended to meals.** The reference honoured it for observations only; `MEAL-UNDO-8` makes an undone meal delete preserve its creation instant, which is [#690](https://github.com/jirigrill/eczema-helper/issues/690) §1's correction. |
| [INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11) | _The app is a Logging Tool_ | **Holds**, and constrains this screen twice: the editor computes no risk, score or warning from what she picks (`MEAL-CAT-1`), and the catalog's allergen tier is never surfaced here. |
| [INV-12](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-12) | _Records carry types, not display strings_ | **Holds, and is tightened.** `DATA-ITEM-2` drops `MealItem.name`; `MEAL-DIRT-2` therefore removes it from the dirtiness key, which [#703](https://github.com/jirigrill/eczema-helper/issues/703) required be specified rather than ported. |
| [INV-13](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-13) | _Catalog is data-first and bundled_ | **Holds.** The picker reads bundled data; the catalog is outside the store ([#686](https://github.com/jirigrill/eczema-helper/issues/686)), so a food id is the only catalog value a meal holds. |
| [INV-14](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-14) | _Every meal has an eligible actor_ | **Holds as a rule; its input moved.** Eligibility derives from the feeding stage, read live (`MEAL-ACTOR-1`); the actor is stored on the meal, so a meal stays self-describing even after a stage change (`SET-STAGE-5`). |

`CONTEXT.md` also holds roughly fifteen invariant-shaped rules **unnumbered**, in glossary prose.
Three bear on this screen and are cited by heading: _MealEditor_, _Commit-Gate_ and _Copy Meal_.

### Divergences from the PWA

This is not a 1:1 port. Per [#690](https://github.com/jirigrill/eczema-helper/issues/690),
**coherence is presumed right**: where the reference does two different things, the port picks the
coherent rule, and *keeping* a wart needs a named reason.

Every divergence is marked inline as **⚠ Divergence** with what the PWA does, what the iOS app does,
and why. There are eighteen, indexed in §11. Six of them are #690's own findings, now stated as
rules; nine come from adjudicating the questions the reference document left open (§13).

---
## 1. Vocabulary

| Term | Meaning |
| --- | --- |
| **Slot** | The triple *(calendar date, meal type, actor)*. Exactly one meal per slot ([INV-4](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-4)). |
| **Draft** | The in-memory meal being composed or changed: families, each holding foods, plus a note. Never persisted directly; only §7 writes. |
| **Draft food** | One catalog food inside the draft: its food id, its per-food state (§2), and a remembered amount and preparation. |
| **Picked** | A draft food she has finished choosing — it has an amount and is part of the meal. The only state that persists. |
| **Being picked** | The one draft food whose amount and preparation she is adjusting right now. |
| **Remembered choice** | The amount and preparation a food had the last time it was picked. Survives the food leaving the meal, so re-picking it restores what it had. |
| **Load baseline** | A comparable projection of the draft *as loaded*, used only to answer whether the visit is dirty (§3.3). Absent in a compose visit. |
| **Visit** | One stay on the editor screen, from open to leave. |
| **Family grid** | The screen's top level: the catalog's families as tiles, the meal's current foods as a working list, and the note field. |
| **Drill-in** | One family's foods, with the picker for whichever food is being picked. |

Four terms this section uses are shared and defined in [`GLOSSARY.md`](GLOSSARY.md): **feeding
stage** and **eligible actors** (which actors a meal may be logged for, §5), **pending work** (§3.4
states what counts as work here), and **undoable action** (whose rules are `SKIN-UNDO-1`..`-3` in
[`skin-observation.md`](skin-observation.md) §8.1; §9 states this screen's use of it). **Calendar
date** and **instant** are also shared, and the distinction matters here: a meal's date is a label,
never recomputed (`DATA-MEAL-3`).

**On the reference document's words.** It called the draft a *working meal*, a picked food
*confirmed*, and the remembered choice a *cache*. Those names describe the TypeScript and are recorded
here — draft, picked, remembered choice — so the two documents can be read together, but they are not
this section's
vocabulary: *confirmed* invites a confirmation dialog that does not exist, and *cache* names an
implementation technique rather than the thing she experiences, which is the app remembering what she
chose.

### 1.1 Fixed at entry

**`MEAL-ENTRY-1` (MUST)** — The entry point supplies a **meal type**, a **calendar date**, a return
destination, and optionally an **actor**. The day view supplies all four (`DAY-MEAL-7`, `-8`, `-9`).

**`MEAL-ENTRY-2` (MUST NOT)** — Neither the meal type nor the date changes during a visit. Only the
actor may move, and only by §6's deliberate swap. No meal records or displays a time of day.

**`MEAL-ENTRY-3` (MUST)** — A missing date means today. A missing return destination means the day
view for the resolved date.

**`MEAL-ENTRY-4` (MUST)** — A missing or unrecognised meal type is **not recoverable**: the screen
does not open, and she is returned to the day view without a step to undo. There is no default meal
type, because every one of the four is a real answer and guessing would file her food under the wrong
one.

**`MEAL-ENTRY-5` (MUST)** — A missing or unrecognised actor resolves to the feeding stage's implicit
actor (`MEAL-ACTOR-3`), and an actor the live stage does not permit is corrected by `MEAL-ACTOR-4`.

**`MEAL-ENTRY-6` (MUST NOT)** — No date after today is accepted. `DAY-NAV-3` makes future days
unreachable, so a future date can only arrive from a stale destination; it resolves to today rather
than opening.

> **⚠ Divergence 1.** *PWA:* future dates are ordinary loggable days, and the editor opens on any
> date it is handed. *iOS:* future days are unreachable and a future date is not honoured. *Why:*
> `DAY-NAV-3`, already Divergence 1 of `day-view.md` — a tomorrow row is an invitation to a mis-dated
> meal, which is the one error class the app cannot detect and, with no export
> ([#683](https://github.com/jirigrill/eczema-helper/issues/683)), cannot repair. Stated here as well
> because the editor is the write path and must refuse independently of how it was reached. Class:
> **settled by [#743](https://github.com/jirigrill/eczema-helper/issues/743)**.

Fixing the slot at entry is what makes a collision on save impossible *by construction* rather than
by a guard: a draft and a saved meal can never contend for one slot, because the draft's slot is the
one it was opened on. Together with `DAY-MEAL-8` — every occupied row opens in edit — this is why
`DATA-ID-2` can say that no interface path writes a second meal into an occupied slot, and why a
confirm-the-overwrite prompt would fire only on ordinary re-editing
([#744](https://github.com/jirigrill/eczema-helper/issues/744)).

### 1.2 Opening a meal the catalog cannot fully resolve

`DAY-MEAL-15` routes a meal holding one or more unresolvable food ids into this editor and states
that the refusal is the editor's. These rules are that refusal.

**`MEAL-DEG-1` (MUST)** — A saved meal holding an item whose food id is not in the bundled catalog
**opens**. The visit is an ordinary edit visit in every respect except `MEAL-DEG-2`.

**`MEAL-DEG-2` (MUST NOT)** — A degraded visit cannot be saved and cannot be deleted. Every write
path is unavailable: the primary action, the delete action, the copy action, and the actor swap's
autosave (§6), which would otherwise write on her behalf without her asking.

**`MEAL-DEG-3` (MUST)** — The unresolvable items are **shown as absent, not as placeholders**: the
draft holds the items it could resolve, and she sees a meal with fewer foods than she logged.

**`MEAL-DEG-4` (OPEN)** — What the screen tells her while degraded is **not decided**. `DAY-MEAL-14`
forbids the day view any marker, and #703's Q5/Q7 declined to state a reason there, twice, the second
time against a recommendation. Whether the *editor* — where she has actively tried to change
something and found she cannot — says anything at all is a separate question that no ticket has put
to the owner. §13.10 records it.

**`MEAL-DEG-5` (MUST NOT)** — A degraded visit never silently drops the unresolvable items by saving
without them. That is what `MEAL-DEG-2` exists to prevent: the meal she logged is still intact in
storage, and the only way to keep it that way is to refuse the write.

> **⚠ Divergence 2.** *PWA:* rehydration **throws** on an unknown food id
> (`working-meal.ts:337-343`), so the meal cannot be opened at all. *iOS:* it opens and degrades.
> *Why:* the throw was tenable only because it was unreachable — `atopic-db.ts` v12's upgrade hook
> bulk-deleted every meal holding a stale id, so the wipe guaranteed the throw never fired. The wipe
> policy does not carry over, and under CloudKit there is no migration hook to hang it on. Porting
> the throw alone ships the guard without the thing that made it safe. Class: **settled by
> [#703](https://github.com/jirigrill/eczema-helper/issues/703)**.

Retiring a catalog food id is therefore a **migration-requiring change**, not a rename — the same
conclusion the reference document reached, arrived at from the opposite direction. `CAT-VER-*` owns
what the catalog may and may not do between versions; this rule owns what the editor does when it
has already happened.

---
## 2. What one food is doing

### 2.1 The four states

**`MEAL-FOOD-1` (MUST)** — Every food in the draft is in exactly one of four states: **absent from
the meal but present in the draft**, **being picked**, **picked**, or **held** because another food
is being picked.

**`MEAL-FOOD-2` (MUST)** — Only **picked** foods persist (§3.1). The other three states exist only
during the visit.

**`MEAL-FOOD-3` (MUST)** — A held food records what it will return to — picked or not-in-the-meal —
because the two are shown differently (`MEAL-GRID-7`) and released differently
(`MEAL-FOOD-8`). A held food is not merely flagged.

**`MEAL-FOOD-4` (MUST)** — Every draft food carries a **remembered choice**: the amount and
preparation from the last time it was picked. It is not a state and survives state changes.

### 2.2 The transitions

Each transition is a pure function of *(draft, family, food)* producing a new draft, and each touches
**only foods inside the named family** (§2.3 says why that matters).

**`MEAL-FOOD-5` (MUST)** — **Start picking.** The tapped food becomes *being picked*. If it is not
yet in the draft it is added first, **appended**; order is the order she added foods and is never
re-sorted.

**`MEAL-FOOD-6` (MUST)** — A food entering *being picked* always carries a concrete amount: its
remembered amount if it has one, otherwise the default portion (`MEAL-AMT-2`). There is no
no-amount-yet state, so she can always finish in one tap.

**`MEAL-FOOD-7` (MUST)** — Starting to pick a food **holds** every other food in that family.

**`MEAL-FOOD-8` (MUST)** — **Finish picking.** The food being picked becomes *picked* with the amount
and preparation it has, and **its remembered choice is updated to those values**. Every held food in
the family is released: back to *picked* if that is what it was, otherwise to not-in-the-meal.

**`MEAL-FOOD-9` (MUST)** — **Abandon picking.** The food being picked returns to not-in-the-meal and
**its remembered choice is not updated**. Held foods are released exactly as in `MEAL-FOOD-8`.

**`MEAL-FOOD-10` (MUST)** — **Unpick.** A picked food she taps to remove from the meal returns to
not-in-the-meal and **its remembered choice is cleared**, so re-picking it starts from the default
portion (`MEAL-AMT-2`) rather than restoring the amount and preparation it had.

> **Both verbs that remove a food forget, and that is deliberate.** Abandoning an unfinished pick
> (`MEAL-FOOD-9`) and unpicking a finished one (`MEAL-FOOD-10`) both return the food to
> not-in-the-meal remembering nothing, so re-picking either starts from the default. Only
> `MEAL-FOOD-8` — finishing a pick — writes a remembered choice. A remembered amount on a food she
> removed is a guess about an intention she reversed, and re-offering it silently re-asserts a number
> she rejected. The one thing that survives removal is nothing: `MEAL-FOOD-13`'s remove is the same
> answer by a third route.

> **⚠ Divergence 3.** *PWA:* `deselectFood` returns the food to *idle* and leaves its cached amount
> and preparation intact (`working-meal.ts:196-201`), so re-picking restores them
> (`startEditing:113`). *iOS:* unpicking clears the remembered choice. *Why:* coherence default — the
> PWA's own two removal verbs disagree, and a remembered amount on a food she removed re-asserts a
> number she rejected. Adjudicated as §13 Q1 under
> [#753](https://github.com/jirigrill/eczema-helper/issues/753)'s coherence default, not the owner's
> answer, and confirmed by owner ruling on
> [#772](https://github.com/jirigrill/eczema-helper/issues/772). Class: **defect fixed**.

**`MEAL-FOOD-11` (MUST)** — Unpicking **releases held foods too**, on `MEAL-FOOD-8`'s rule.

> **⚠ Divergence 14.** *PWA:* `deselectFood` is the one exit from a food's active state that does
> **not** release locks (reference §2.1, its open question 6). *iOS:* it releases them like every
> other exit. *Why:* coherence default — four transitions release, one does not, and nothing records
> why. The asymmetry is currently *sound but unreachable*: unpick is only reachable when nothing is
> held, so releasing nothing is what the rule does today either way. That is exactly why it should be
> made uniform now rather than preserved: it costs nothing to fix while it is unobservable, and it
> becomes a real bug the moment the holding scope changes (a two-family drill-in, a picker that shows
> the whole working list). Class: **defect fixed (latent)**.

**`MEAL-FOOD-12` (MUST NOT)** — Adjusting an amount or a preparation does anything unless that food
is *being picked*. There is no path by which a picked food's amount changes without her picking it
again.

**`MEAL-FOOD-13` (MUST)** — **Remove.** Deleting a row from the working list removes the food from
the draft entirely, remembered choice and all. If the removed food was being picked, held siblings are
released on `MEAL-FOOD-8`'s rule.

**`MEAL-FOOD-14` (MUST)** — Removing a food that is not in the draft does nothing, silently. It is
distinct from `MEAL-DEG-1`'s unknown *catalog* id: an absent draft food means there is nothing to
remove; an unresolvable catalog id means the stored data and the app disagree.

**`MEAL-FOOD-15` (MUST)** — **Leaving a family** drops every food in it that is neither picked nor
being picked, remembered choices included. It is a compaction of the draft, not a state change, and
it is what keeps an abandoned browse from leaving debris behind.

**`MEAL-FOOD-16` (MUST NOT)** — Leaving a family does not touch a picked food's remembered choice.

> **⚠ Divergence 4.** *PWA:* the code filters and nothing else — but its doc comment claims it also
> *"reset[s] confirmed foods' caches so the slot is clean for a future edit"* (reference §2.1, its
> open question 4). The code and its tests agree with each other; the comment is simply false.
> *iOS:* `MEAL-FOOD-16` states the code's behavior as the rule. *Why:* the comment describes worse
> behavior, not merely different behavior — resetting the memory of a food she has already picked
> would make re-entering a family forget her own choice, which is the exact thing `MEAL-FOOD-4`
> exists to prevent. This is the same class as `catalog.md`'s Divergence on a comment describing a
> sort the code does not perform: a port built by reading comments diverges. Class: **defect fixed
> (documentation)**.

**`MEAL-FOOD-17` (MUST NOT)** — Two foods are never being picked at once, in the whole screen.
Holding is the mechanism (`MEAL-FOOD-7`), and every exit releases (`MEAL-FOOD-8`, `-9`, `-11`, `-13`).

**`MEAL-FOOD-18` (MUST NOT)** — Starting to pick a food never displaces another food that is already
being picked. `MEAL-FOOD-17` makes the situation unrepresentable; where the platform cannot express
that, the transition is refused rather than performed.

> **⚠ Divergence 5.** *PWA:* `startEditing` will hold a sibling that is *already* being picked, and
> records it as returning to not-in-the-meal — silently discarding the fact that she was mid-pick,
> and with it the amount she had set (reference §2.1, its open question 5). It is unreachable given
> the one-at-a-time rule and no test pins it. *iOS:* made unrepresentable. *Why:* the reference
> document's own recommendation was *"either make it unrepresentable or assert it"*, and between
> those two, unrepresentable is strictly better here — the encoded behavior is data loss, so a test
> asserting it would be a test pinning a defect in place. The coherence default decides the rest:
> nothing named a reason to keep a reachable-by-refactor path that throws away her work. Class:
> **defect fixed (made unrepresentable)**.

### 2.3 Why the family scope is load-bearing

**`MEAL-FOOD-19` (MUST)** — Every food belongs to exactly one family
([INV-13](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-13)), so a food id
determines its family. The same food never appears in two families.

The one-at-a-time rule (`MEAL-FOOD-7`) is enforced **per family** by the transitions, and extended to
the whole screen by the screen: the drill-in shows one family at a time, and the working list's rules
(`MEAL-GRID-4`) re-impose it across families. **A presentation that showed two families' foods at once
would lose the guarantee unless it re-imposed it** — worth stating because `CAT-SHAPE-8` puts the
picker's presentation in this section, so this document is where such a change would be made.

### 2.4 What the screen reads

**`MEAL-FOOD-20` (MUST)** — Foods read back in the order she added them, and families in the order
she first reached them. Nothing re-sorts either.

**`MEAL-FOOD-21` (MUST)** — *Is there anything in this meal* counts a food that is **being picked**
as well as one that is **picked**. *Can this be saved* counts only picked foods. The two questions
have different answers on purpose, and §3.4 is where that difference does its work.

---
## 3. The boundary between the draft and the record

### 3.1 Draft to record

**`MEAL-PROJ-1` (MUST)** — Only **picked** foods become items. A food being picked is not saved.

**`MEAL-PROJ-2` (MUST)** — Each item carries a food id, an amount, and an optional preparation, and
nothing else (`DATA-ITEM-2`). No display name is stored
([INV-12](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-12)) and items have no
identity of their own (`DATA-ITEM-1`).

**`MEAL-PROJ-3` (MUST)** — Item order is the order she added the foods, and it is preserved
(`DATA-ITEM-3`).

**`MEAL-PROJ-4` (MUST)** — The note is trimmed, and a note that is empty or only whitespace is stored
as **absent**, never as an empty string (`DATA-MEAL-7`).

**`MEAL-PROJ-5` (MUST)** — A compose visit stamps a creation instant and **no** last-edit instant. An
edit visit preserves the creation instant it loaded and stamps a last-edit instant (`DATA-MEAL-5`,
`-6`).

**`MEAL-PROJ-6` (MUST)** — A draft with no picked foods yields **no record**, not an empty one. What
happens then is §7.2, and it depends on whether a meal was loaded.

### 3.2 Record to draft

**`MEAL-PROJ-7` (MUST)** — Every stored item is loaded as a **picked** food with its remembered
choice pre-filled from the stored amount and preparation, placed in the family its food id belongs to.

**`MEAL-PROJ-8` (MUST)** — A food's display name is resolved from the catalog at render time, never
read from the record (`DAY-MEAL-6`, `DATA-ITEM-2`).

**`MEAL-PROJ-9` (MUST)** — An item whose food id the catalog cannot resolve degrades the visit per
§1.2 rather than being dropped or replaced.

### 3.3 Is there something to save?

**`MEAL-DIRT-1` (MUST)** — A **compose** visit can be saved when at least one food is picked. An
**edit** visit can be saved when its draft differs from the load baseline — *including* when she has
emptied the meal, because emptying is a legitimate way to delete it (§7.2).

**`MEAL-DIRT-2` (MUST)** — The comparison is over picked items reduced to **food id, amount and
preparation**, plus the trimmed note. It includes **no display name** and **no item identifier**.

> **⚠ Divergence 6.** *PWA:* the key is `foodId` + `name` + `amount` + `preparationMethod`
> (`meal-dirtiness.ts:29`). *iOS:* `name` is not part of it. *Why:* the record no longer holds a name
> to compare (`DATA-ITEM-2`), so including one would mean re-deriving a display string purely to
> compare it against itself. In the reference it was harmless only because the catalog is immutable at
> runtime; the moment a catalog version renames a food, every meal holding it reads as dirty against
> itself. [#703](https://github.com/jirigrill/eczema-helper/issues/703) required this be **specified
> without the name** rather than ported as written. Class: **settled by #703**.

**`MEAL-DIRT-3` (MUST NOT)** — Item identifiers take part in the comparison. In the reference they are
minted fresh on every projection, so including them would make every meal read as dirty against
itself; on iOS items have no identifier at all.

**`MEAL-DIRT-4` (MUST)** — An **absent** preparation and an **explicitly cleared** preparation compare
**equal**. Toggling a preparation on and off again leaves the visit clean.

**`MEAL-DIRT-5` (MUST)** — Clearing a preparation that was **stored** *is* a change.

`MEAL-DIRT-4` and `-5` are not in tension, and the pair is the reason a structural
serialize-and-compare implementation gets this wrong: what matters is the preparation's **value**, and
absent and cleared are the same value — no preparation. `-5` differs because the stored value was a
real preparation, so the value changed.

**`MEAL-DIRT-6` (MUST)** — Comparison is **order-independent**: two drafts holding the same items in
different orders are equal, because picking reorders foods and reordering is not a change. It compares
**multiplicities**, not sets — though duplicates cannot arise, since a food appears once in a draft.

**`MEAL-DIRT-7` (MUST)** — Whitespace-only changes to the note never make a visit dirty.

**`MEAL-DIRT-8` (MUST)** — Adding a food and removing it again leaves the visit clean, and so does
changing an amount and changing it back.

**`MEAL-DIRT-9` (MUST NOT)** — A food that is only **being picked** contributes to this comparison.
The save question is picked-only in **both** visit modes.

### 3.4 The question the reference asked once and should have asked twice

**`MEAL-DIRT-10` (MUST)** — *Would leaving lose something she did?* — [`GLOSSARY.md`](GLOSSARY.md)'s
**pending work** — is a **separate question** from `MEAL-DIRT-1`, with its own answer.

**`MEAL-DIRT-11` (MUST)** — Pending work here means **any food she has started picking or has picked,
or any note text**. It counts in-progress work, not just savable work.

**`MEAL-DIRT-12` (MUST)** — Pending work is asked **identically in compose and edit**. A new meal with
work in it is exactly as recoverable as a change to a saved one.

> **⚠ Divergence 7.** *PWA:* the dirtiness predicate answers both questions at once, and the
> in-progress food is counted **only in compose** — so a mother who opens a saved meal, taps a new
> food, sets its amount and backs out without finishing loses that food **with no undo at all**,
> because the visit reads as clean. In compose the same sequence buffers and offers an undo. *iOS:*
> the predicate is **split**; both modes answer both questions. *Why:*
> [#690](https://github.com/jirigrill/eczema-helper/issues/690) §2, named by
> [#707](https://github.com/jirigrill/eczema-helper/issues/707). Class: **defect fixed (largest in
> this section)**.

> **The trap this avoids, stated because merging is the obvious shortcut.** The tempting fix is
> "make an in-progress food count as dirty" — one predicate, one change. It is wrong, and
> destructively so: in an edit visit the dirtiness answer *also* gates the save action
> (`MEAL-DIRT-1`), and saving drops unfinished foods (`MEAL-PROJ-1`). So the merged predicate would
> enable a save that **silently loses the very food that enabled it**. Two questions, two answers.

**`MEAL-DIRT-13` (MUST)** — Typed text is work in its own right. A note with nothing else alongside
it is pending work, in both modes. Under mandatory sync with no export
([#683](https://github.com/jirigrill/eczema-helper/issues/683)) a lost note is unrecoverable, and a
note is often the whole record — *"refused lunch, very itchy after"*.

---
## 4. The visit

### 4.1 Opening

**`MEAL-VISIT-1` (MUST)** — Opening on an **occupied** slot is an **edit** visit: the draft is loaded
from the saved meal including its note, the loaded creation instant is kept, and the load baseline is
a projection of what was just loaded.

**`MEAL-VISIT-2` (MUST)** — Opening on an **empty** slot is a **compose** visit: empty draft, empty
note, no load baseline, no loaded creation instant.

**`MEAL-VISIT-3` (MUST)** — The **presence of a load baseline** is what distinguishes the two modes.
No separate flag decides it, so the two cannot disagree.

**`MEAL-VISIT-4` (MUST)** — An edit visit also retains a copy of the meal **as loaded**, separately
from the live draft. §9.1 is why: an undo of an emptied-meal delete has to restore the foods she
deleted, and by then the live draft no longer holds them.

**`MEAL-VISIT-5` (MUST)** — Existence is decided by **awaiting the read**, never by a timer. A visit
opens as edit or compose only once a completed read has answered; while it is in flight the screen
shows a loading state, not an empty compose form.

> **⚠ Divergence 8.** *PWA:* the mode is decided from a reactive query that may not have emitted yet,
> and the skin screen — the same pattern — waits a fixed 500 ms before giving up. *iOS:* await the
> read. *Why:* the same reasoning as `SKIN-ENTRY-4`/`-5` (`skin-observation.md` Divergence 14), and
> the consequence here is worse than a spurious bounce: deciding *compose* for a slot that is
> actually occupied means her next save is a fresh record written over a meal she already logged.
> Class: **defect fixed**.

### 4.2 Leaving the screen

**`MEAL-VISIT-6` (MUST)** — Every exit resolves to exactly one of: **saved**, **deleted**,
**recoverable-discard**, or **nothing happened**. §9 states which exit produces which.

**`MEAL-VISIT-7` (MUST NOT)** — More than one of those fires for a single departure. The reference
implementation needed a gate between its back control and its history handler to hold this; on iOS
the rule is stated so the gate cannot be forgotten.

### 4.3 What the screen presents

`CAT-SHAPE-8` puts the food picker's presentation in this section: the family grid, the drill-in, tile
order, grouping and sort are the meal editor's, not the catalog's.

**`MEAL-GRID-1` (MUST)** — The screen has three mutually exclusive presentations: the **family grid**,
a **drill-in** into one family, and the grid with **one working-list row open** for picking.

**`MEAL-GRID-2` (MUST NOT)** — A drill-in and an open grid row are never both present. Entering a
drill-in is refused while a grid row is open.

**`MEAL-GRID-3` (MUST)** — Tapping a family tile enters that family's drill-in — unless a grid row is
open, in which case the tap does nothing.

**`MEAL-GRID-4` (MUST)** — Tapping a working-list row: if it is the open one, finish picking it and
close it; otherwise finish picking whatever row was open, then start picking the tapped one. This is
what extends `MEAL-FOOD-17` across families, since two rows may belong to different families.

**`MEAL-GRID-5` (MUST)** — Removing a working-list row that is currently open closes it first, then
removes.

**`MEAL-GRID-6` (MUST)** — The working list shows every food that is **picked**, **being picked**, or
**held-from-picked**, in family-then-insertion order. Foods that are not in the meal, and
held-from-not-in-the-meal foods, are hidden. This is why opening one row's picker does not visually
drop the other rows.

**`MEAL-GRID-7` (MUST)** — A held food that will return to *picked* stays visible and filled; one that
will return to not-in-the-meal is merely dimmed. This is the rule `MEAL-FOOD-3` exists to serve.

**`MEAL-GRID-8` (MUST)** — A row's summary shows its amount and preparation when picked, its
**remembered** amount and preparation when held, and nothing while it is being picked — its picker is
open and showing them.

**`MEAL-GRID-9` (MUST NOT)** — A family tile shows per-food state. What is picked is visible inside
the drill-in and in the working list, nowhere else.

**`MEAL-GRID-10` (MUST)** — Tapping a food in a drill-in: if it is being picked → finish picking it;
if picked → unpick it; if held → nothing; otherwise → start picking it.

**`MEAL-GRID-11` (MUST)** — Tapping **outside** a food, in the drill-in and on the grid alike,
**finishes** the pick.

> **⚠ Divergence 9.** *PWA:* tapping outside **cancels** in the drill-in but **confirms** on the
> grid — the same gesture, opposite meanings, both pinned by tests and therefore both intended.
> *iOS:* confirm everywhere. *Why:* [#690](https://github.com/jirigrill/eczema-helper/issues/690) §5,
> for two reasons worth carrying: destructive-by-default on an ambiguous gesture is the wrong side to
> err on, especially one-handed with a baby in the other arm; and on iOS it is not even the same
> primitive, since a tap outside a sheet *dismisses* it, so cancel would read as "dismiss the family"
> rather than "throw away the amount I just set". If cancelling matters it earns a visible control,
> not the absence of one. Class: **settled by #690**.

**`MEAL-GRID-12` (MUST)** — A family is presented **grouped** exactly when `CAT-SRC-4` says its data
supports it — at least five foods and an authored source structure — and **flat** otherwise, with the
catch-all group rendered last (`CAT-SRC-5`).

**`MEAL-GRID-13` (MUST)** — Group order is the family's authored order (`CAT-SRC-3`), which is
editorial rather than alphabetical. Food order **within** a group is **alphabetical by the food's
displayed name**, collated for the display locale. Nothing on this screen re-sorts the groups.

> **⚠ Divergence 15.** *PWA:* foods are sorted alphabetically by resolved name in both the flat and
> the grouped rendering (`FamilyDrillIn.svelte:49,62,67`), pinned group by group by 10 tests, while
> the surrounding code comment claims only the groups keep their curated order. *iOS:* the same —
> alphabetical within the group. *Why:* owner's call on
> [#772](https://github.com/jirigrill/eczema-helper/issues/772). This rule previously required the
> catalog's authored order for foods too, which contradicted the reference and every test pinning it;
> the sweep found the contradiction and the owner ruled for alphabetical. A family's foods are a set
> she scans by name, not a sequence anyone authored a meaning into — unlike the groups, whose order
> is editorial and is preserved. Class: **owner's call**.
>
> **Collation is a display concern, not a data one.** The reference collates for Czech
> (`localeCompare(…, 'cs')`); the port collates for its own display locale, so the order of two foods
> may differ between the reference and the port without either being wrong. The catalog stores no
> ordering for foods and none is inferred from row position (`CAT-SHAPE-5`).

**`MEAL-GRID-14` (MUST NOT)** — A group that would render with no foods in it is rendered at all. The
catalog does not author empty groups (`CAT-SRC-8`), and the renderer does not invent them.

> **⚠ Divergence 10.** *PWA:* the renderer is lenient where the data model is strict — it will render
> a group heading for a source group whose foods have all been filtered out, and the reference's
> grouping helper and its consumer disagree about whether an eliminated group survives. *iOS:*
> `MEAL-GRID-14` states the strict behavior for the renderer too. *Why:*
> [#734](https://github.com/jirigrill/eczema-helper/issues/734)'s Divergence 9 pairs a lenient
> renderer with a strict rehydrator, and **both halves port or neither** — porting the lenient half
> alone leaves a heading with nothing under it, which reads as missing food rather than as an absent
> group. Class: **settled by #734**.

**`MEAL-GRID-15` (MUST)** — Leaving a drill-in — by its back control or by finishing with the family —
returns to the grid without growing the navigation history, and a cold start opens on the grid rather
than restoring a drill-in.

> **⚠ Divergence 11.** *PWA:* the drill-in is a **history entry**, so the platform back gesture pops
> it; that also makes the buffer write on back-out timing-sensitive, since committing a family pops an
> entry and a navigation issued before it settles makes the pop handler observe a stale flag and skip
> writing the discard buffer entirely — a silent loss of the undo, which the end-to-end tests work
> around with an explicit wait. *iOS:* the drill-in is **view state**, not a history entry. *Why:* it
> is not a destination; it is a level of the same screen, and modelling it as view state removes the
> hazard outright rather than timing around it. Class: **defect fixed (drift source)**.

### 4.4 What the primary action says

The screen has **one** primary action whose label names what a tap will do. The ladder is not cosmetic:
the same button finishes a food, finishes a family, saves the meal, or exits, and the label is the only
thing distinguishing them.

**`MEAL-CTA-1` (MUST)** — There is exactly **one** primary action, in one place, in every presentation.

**`MEAL-CTA-2` (MUST)** — While a food is open for picking — in the drill-in or as a working-list row —
the action reads *save `<food name>`* and finishing that food is what it does.

**`MEAL-CTA-3` (MUST)** — Inside a drill-in with no food open, it reads *save `<family name>`* and
finishing with the family is what it does.

**`MEAL-CTA-4` (MUST)** — On the grid in a **compose** visit it reads *save `<meal type>`* once at least
one food is picked.

**`MEAL-CTA-5` (MUST)** — On the grid in an **edit** visit it reads *save changes* — naming the change,
not the meal type, so an update does not read as creating a second meal.

**`MEAL-CTA-6` (MUST)** — In the forward-exit state (§8.3) it reads *done* and only navigates.

**`MEAL-CTA-7` (MUST)** — It is **unavailable** exactly when there is nothing to save (`MEAL-DIRT-1`): a
compose visit with no food picked, or a clean edit. A sub-action — a food or family open — always makes it
available, because finishing is always possible.

**`MEAL-CTA-8` (MUST NOT)** — A tap on the unavailable action does anything.

---
## 5. Amounts, preparations, and who the meal is for

### 5.1 What she can set on a food

**`MEAL-AMT-1` (MUST)** — An amount is one of a **fixed, closed set** of portion sizes. It is never a
number she types, never a weight, and never free text.

**`MEAL-AMT-2` (MUST)** — One member of that set is the **default**, used by `MEAL-FOOD-6` when a food
has no remembered amount.

**`MEAL-AMT-3` (MUST)** — Every picked food has an amount. There is no unspecified amount.

**`MEAL-AMT-4` (MUST)** — A preparation is **optional**, and is one of the preparations the catalog
authors **for that food** (`CAT-PREP-1`, `-2`), offered in the catalog's order.

**`MEAL-AMT-5` (MUST)** — A food whose authored preparation list is **empty** shows **no preparation
control at all** — not an empty row, not a disabled one. An empty list is an ordinary authored state
meaning the food takes no preparation choice (`CAT-PREP-3`); 37 of the reference's 160 foods are in it.

**`MEAL-AMT-6` (MUST)** — What the catalog authors gates only **what is offered**. A stored preparation
the current catalog no longer offers still reads back as she recorded it (`CAT-PREP-4`).

**`MEAL-CAT-1` (MUST NOT)** — The editor computes, displays or implies anything about risk,
allergenicity or suitability from what she picks — no score, no warning, no ordering by danger, no
highlight ([INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11)). The
catalog's allergen tier is not surfaced on this screen
([#686](https://github.com/jirigrill/eczema-helper/issues/686) ships it undisplayed), and the picker's
grouping axis is *where a food comes from*, never *how risky it is* (`CAT-SRC-6`).

### 5.2 Eligible actors

**`MEAL-ACTOR-1` (MUST)** — Which actors a meal may be logged for is a function of the **feeding stage
in force now** ([`GLOSSARY.md`](GLOSSARY.md)), read live rather than from the meal.

**`MEAL-ACTOR-2` (MUST)** — `breastfed` permits the **mother** only; `mixed` permits **mother then
baby**, in that order; `solids` permits the **baby** only.

**`MEAL-ACTOR-3` (MUST)** — The first eligible actor is the stage's **implicit actor**.

**`MEAL-ACTOR-4` (MUST)** — An actor the live stage does not permit — a stale destination carrying
`mother` while the stage is `solids` — makes the screen **snap to the implicit actor and open on that
slot instead**.

**`MEAL-ACTOR-5` (MUST NOT)** — That correction autosaves the departing actor. It is not a swap: she
never chose that actor and has no work there to preserve.

**`MEAL-ACTOR-6` (MUST)** — The actor control appears **only when more than one actor is eligible** —
in practice only at `mixed`. At a single-actor stage the actor is implicit and no control is shown.

**`MEAL-ACTOR-7` (MUST)** — The actor control is hidden while she is drilled into a family, so it does
not compete with the drill-in.

**`MEAL-ACTOR-8` (MUST)** — `MEAL-ACTOR-4` is re-evaluated when the stage becomes known, not only when
the screen mounts. The stage may resolve after the screen appears.

**`MEAL-ACTOR-9` (MUST)** — A meal keeps the actor it was recorded under, whatever the stage becomes
later (`SET-STAGE-5`,
[INV-14](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-14)). The day view renders
such a row normally (`DAY-MEAL-3`); this screen opens it normally too.

The rationale, which drives the whole actor model and should survive any rewording: a breastfed
newborn's intake **is** the mother's diet, so at that stage the mother is the subject of the record;
once the child eats independently, the child is.

---
## 6. Changing the actor mid-visit

Reachable only at `mixed`, where both actors are eligible.

**`MEAL-SWAP-1` (MUST NOT)** — Tapping the already-selected actor does anything.

**`MEAL-SWAP-2` (MUST)** — Swapping **finalizes the departing actor's visit first** (§7), with ordinary
semantics: picked foods and the note are written, an empty compose visit writes nothing, and an
**emptied existing meal is deleted** (§7.2).

**`MEAL-SWAP-3` (MUST)** — **If that write fails, the swap is abandoned.** The departing actor stays
selected, its draft is preserved intact, and the failure is surfaced through the same channel a manual
save uses. This is the one genuine data-loss path in the screen and must never proceed silently.

**`MEAL-SWAP-4` (MUST)** — On success the editor **re-opens on the target actor's slot** by reading
storage, which is authoritative; the selection flips only then.

**`MEAL-SWAP-5` (MUST NOT)** — A swap records an undoable action. Nothing was discarded — the work was
**saved** — so there is nothing to undo, and offering one would invite her to undo a save. Swapping
back is the recovery.

**`MEAL-SWAP-6` (MUST NOT)** — A swap silently drops a food she was mid-pick. It **finishes** the pick
first, so the food she had started is part of what gets written.

> **⚠ Divergence 12.** *PWA:* the autosave writes picked foods only, so a food left mid-pick is
> **discarded silently — no warning, no undo**. It is the one place in the editor that throws away her
> input without telling her, and it is pinned by a test, so it was intended. *iOS:* finish the pick,
> then write. *Why:* `MEAL-DIRT-11` makes an in-progress food *pending work*, and pending work is never
> lost silently — that is the whole content of Divergence 7. Keeping this case would reintroduce the
> loss #690 §2 removed, by a worse door: the swap writes on her behalf, so she has not even left the
> screen, and she has no exit to be warned at. Finishing the pick is also what she meant, since the
> food already carries a concrete amount (`MEAL-FOOD-6`). Class: **defect fixed** (extends #690 §2 to a
> case it did not name).

### 6.1 Remembering that a swap saved something

**`MEAL-SWAP-7` (MUST)** — The screen records, **per actor**, whether that actor's real work was written
by a swap during this visit. An actor is recorded when she swaps **away** from it while it had something
to write.

**`MEAL-SWAP-8` (MUST)** — The record is per-actor, not a visit-wide flag: cycling between two
already-clean saved meals writes nothing, records nobody, and leaves an untouched actor showing the
ordinary unavailable save.

**`MEAL-SWAP-9` (MUST)** — An actor drops out of it the moment its meal is edited again, because §8.3's
condition also requires nothing left to write. Without this, the forward exit would navigate away over a
dirty edit and drop the change — precisely the loss the autosave exists to prevent.

**`MEAL-SWAP-10` (MUST)** — The record is **screen-local and in-memory** and does not survive a remount.
It is a statement about *this visit*, not a property of the data.

**`MEAL-SWAP-11` (MUST NOT)** — Any stored field exists to keep it alive across a remount. Inventing a
persisted "was autosaved" fact to preserve a label is not warranted.

**`MEAL-SWAP-12` (MUST)** — After a remount the screen must not read as though her work was lost.
`MEAL-SWAP-10` leaves a truthful clean-edit state behind, and a bare unavailable *save changes* reads as
*"your work didn't take"* — the exact confusion §8.3 exists to prevent.

> **⚠ Divergence 13.** *PWA:* reaching the done state, backing out and undoing back in returns a
> **silently unavailable save action**. *iOS:* the ephemerality stays (`MEAL-SWAP-10`) and the
> presentation is the port's to solve (`MEAL-SWAP-12`). *Why:*
> [#690](https://github.com/jirigrill/eczema-helper/issues/690) §6 — the ephemerality is correct and the
> disabled action is the defect. This is the one of #690's six that is **specified rather than
> repaired**: no journal data is at risk either way, since the autosave already happened. Class:
> **settled by #690 (presentation deferred)**.

---
## 7. Finalizing

### 7.1 Writing the meal

**`MEAL-FIN-1` (MUST)** — Finalizing projects the draft to a record (§3.1) and writes it: a **compose**
visit mints a new meal for the slot; an **edit** visit updates the loaded meal in place, keeping its
identity and its entry date (`MEAL-PROJ-5`).

**`MEAL-FIN-2` (MUST)** — Finalizing is the only thing that writes a meal for this slot, apart from the
swap autosave (§6), which finalizes on her behalf.

**`MEAL-FIN-3` (MUST)** — A **failed** write leaves her **on the screen** with the draft intact and the
failure surfaced. It never navigates away — navigating would evict the draft, and the draft is the only
copy of her work.

**`MEAL-FIN-4` (MUST)** — A **successful** write returns her to the day she came from (§4.2).

**`MEAL-FIN-5` (MUST)** — Foods still **being picked** are not written (`MEAL-PROJ-1`); this is why
`MEAL-DIRT-11` counts them as pending work and §6 finishes them before a swap.

### 7.2 Emptying is deleting

**`MEAL-DEL-1` (MUST)** — Finalizing an **edit** visit whose draft holds no foods **deletes** the meal
rather than writing an empty one.

**`MEAL-DEL-2` (MUST)** — Emptying an existing meal and **leaving without finalizing** also deletes it.
The two exits agree; emptying is the decision, and which exit she then uses is not.

**`MEAL-DEL-3` (MUST)** — Either deletion is **undoable** by the ordinary mechanism (§8.2), which
restores the meal with its foods and its note.

**`MEAL-DEL-4` (MUST)** — A meal she has emptied says so **before** she commits: the screen states that
saving or leaving now removes the meal. A delete she did not know she was making is not a decision.

**`MEAL-DEL-5` (MUST)** — There is also an **explicit** delete action for an existing meal, reached
through the screen's overflow, and it **confirms** before deleting.

**`MEAL-DEL-6` (MUST)** — The explicit delete is undoable on the same terms as `MEAL-DEL-3`.

**`MEAL-DEL-7` (MUST NOT)** — A **compose** visit can delete anything. There is nothing there to delete;
an empty compose visit simply writes nothing (`MEAL-VISIT-5`).

**`MEAL-DEL-8` (MUST)** — A note with no foods is **not** a meal: the note alone does not keep an emptied
meal alive. A note is an annotation on foods, and `MEAL-DIRT-13`'s protection of typed text is about not
losing it *silently* — the undo satisfies that.

Emptying-is-deleting exists because the alternative is a slot that reads as logged on the day view and
holds nothing. The mother's question of that screen is *what did she eat*, and a meal with no foods
answers it misleadingly rather than emptily.

---
## 8. Leaving, and taking it back

### 8.1 The exits

**`MEAL-EXIT-1` (MUST)** — The screen has exactly **three** exits: finalize (§7), leave without
finalizing, and the forward *done* exit (§8.3). Every one of them lands on the day she came from.

**`MEAL-EXIT-2` (MUST)** — Leaving without finalizing behaves **identically** however she does it — the
screen's own back affordance, the system back gesture, or a hardware back. An exit path that skips the
undo buffer is a data-loss bug, and in the reference it was one.

**`MEAL-EXIT-3` (MUST)** — Leaving is written to the buffer **exactly once** per departure, never twice.

**`MEAL-EXIT-4` (MUST)** — Backing out of a **drill-in** is not an exit (`MEAL-GRID-15`): it returns to the
grid and buffers nothing.

### 8.2 The undo buffer

**`MEAL-UNDO-1` (MUST)** — Leaving with **pending work** (`MEAL-DIRT-11`) buffers what she was doing and
offers her to take it back from the day she lands on.

**`MEAL-UNDO-2` (MUST)** — Leaving with **no** pending work buffers nothing and offers nothing.

**`MEAL-UNDO-3` (MUST)** — Accepting the undo re-opens the screen **on the same slot** — same date, same
meal type, same actor — with the draft she left, including foods that were only being picked.

**`MEAL-UNDO-4` (MUST)** — A restored **edit** draft still reads as **dirty against the stored record**,
so its save stays available and a second departure buffers again rather than dropping the restored work.

**`MEAL-UNDO-5` (MUST)** — A restored draft whose meal was **deleted** on the way out (`MEAL-DEL-2`,
`-5`) re-opens as a **compose** visit, because there is no longer a record to update; finalizing mints a
new one.

**`MEAL-UNDO-6` (MUST)** — The buffer holds **one** thing. A newer buffered action replaces the older,
and there is no undo history.

**`MEAL-UNDO-7` (MUST)** — The buffer is consumed on restore and does not survive being used twice.

**`MEAL-UNDO-8` (MUST)** — A buffer is restored **only** onto the slot it was captured for. Landing on a
different slot leaves it alone.

**`MEAL-UNDO-9` (MUST)** — Restoring happens **once** per opening, and no later store update overwrites a
just-restored draft with what storage holds.

**`MEAL-UNDO-10` (MUST)** — A **copy** into a slot (`MEAL-COPY-*`) is undoable on the same one-slot
buffer, and its undo removes **only what the copy added**, leaving what was already there.

**`MEAL-UNDO-11` (MUST)** — A copy's undo is **invalidated** the moment she edits, deletes, or re-copies
into the destination slot by hand. Without this, undoing a copy could remove food she added herself
afterwards.

**`MEAL-UNDO-12` (MUST)** — The buffer is **in memory** and does not survive the app being killed. It is
a second chance at the last action, not a journal.

**`MEAL-UNDO-13` (MUST)** — The **offer** and the **buffer** have different lifetimes. Dismissing the
offer, or letting it time out, hides the offer and **does not discard the buffer**. The offer's
disappearance is never a destructive commit.

**`MEAL-UNDO-14` (MUST)** — The buffer is discarded exactly when one of these happens: a newer buffered
action replaces it (`MEAL-UNDO-6`), it is consumed by a restore (`MEAL-UNDO-7`), it is invalidated by a
hand edit to its slot (`MEAL-UNDO-11`), she leaves the screen the offer was made on, or the app
terminates (`MEAL-UNDO-12`). Nothing else discards it, and no timer does.

**`MEAL-UNDO-15` (SHOULD)** — The offer's own visible duration is a presentation choice and is
deliberately not fixed here (§13), but it is long enough to satisfy `MEAL-A11Y-14` — reachable by focus
after the announcement it follows has finished.

> **⚠ Divergence 16.** *PWA:* the buffer's lifetime **is** the toast's. `Toast.svelte:7` auto-dismisses
> at 5,000 ms and `+layout.svelte:76` calls `clearBuffer()` on close unless undo fired, so letting the
> banner lapse — or dismissing it by hand — discards a dirty draft and makes a delete permanent. *iOS:*
> the buffer outlives the offer and dies only on `MEAL-UNDO-14`'s list. *Why:* owner's call on
> [#772](https://github.com/jirigrill/eczema-helper/issues/772). This is the product's **only** recovery
> path — there is no trash behind a delete (`SET-DELETE-9`) — and tying it to a five-second banner makes
> a VoiceOver user structurally less able to recover a meal than a sighted one, because the
> announcement must finish before the control can be reached. iOS also has no system snackbar to
> inherit the convention from: `UndoManager` scopes undo to an editing context, never to a view's
> visibility, and Apple's own destructive-action pattern buys time rather than a banner (Undo Send's
> fixed window, Recently Deleted's thirty days). Cost accepted: undo stays available briefly with no
> visible offer, which is mildly surprising to anyone who shakes to undo after the banner has gone.
> Class: **owner's call**.

### 8.3 The forward exit

**`MEAL-EXIT-5` (MUST)** — When the selected actor's meal is **saved and clean** and a swap autosaved
that actor's work this visit (`MEAL-SWAP-7`), the screen's primary action is a **forward exit** to the
day view instead of an unavailable save.

**`MEAL-EXIT-6` (MUST)** — It requires all of: this actor recorded by `MEAL-SWAP-7`, the visit an edit,
nothing left to write, at least one food present, and no food or family currently open.

**`MEAL-EXIT-7` (MUST NOT)** — It appears for a plain clean edit opened straight from the day view. There
the back affordance is the exit and nothing was autosaved.

**`MEAL-EXIT-8` (MUST)** — Taking it navigates only. It writes nothing, because there is nothing to
write.

**`MEAL-EXIT-9` (MUST)** — An **empty** meal falls through to `MEAL-DEL-4`'s statement rather than to
this exit.

The whole reason this exit exists: after a swap has silently written her work, an unavailable *save
changes* is the screen's only remaining statement about that work, and it reads as a refusal. The forward
exit says *this is saved, you can go*.

---
## 9. Copying a meal to another day

The mother eats the same lunch four days running. Re-picking it costs the same taps every time, and the
taps are the reason a day goes unlogged.

**`MEAL-COPY-1` (MUST)** — Copying is offered only for an **existing** meal that holds **at least one
food**. A meal with no foods has nothing to copy.

**`MEAL-COPY-2` (MUST)** — Copying is reached from the same overflow as the explicit delete, never as a
primary action. It is a convenience, not part of logging.

**`MEAL-COPY-3` (MUST)** — She chooses a **destination day and meal type**. The picker opens on the
**source slot**, so the common case — same meal type, adjacent day — is one change.

**`MEAL-COPY-4` (MUST)** — Every day the picker offers is a legal destination, **including future days**.
The picker's range is the day view's range (`DAY-STRIP-*`) and it is the only gate; there is no separate
window check.

**`MEAL-COPY-5` (MUST)** — The **actor is fixed** to the source meal's actor and is not choosable. The
other actor's meal in the same visual cell is a different meal and is untouched.

**`MEAL-COPY-6` (MUST)** — Copying onto an **empty** destination creates a meal there with the source's
foods, each with its amount and preparation.

**`MEAL-COPY-7` (MUST NOT)** — A copy carries the source's **note**. A note is about that day —
*"refused lunch, very itchy after"* — and reproducing it on another day would put an observation she never
made into the journal.

**`MEAL-COPY-8` (MUST)** — Copying onto an **occupied** destination **merges**: foods the destination does
not already have are added, and the destination keeps its own identity, its note, and its existing foods
unchanged.

**`MEAL-COPY-9` (MUST)** — A food the destination already holds is **skipped entirely** — its amount and
preparation are the destination's, not the source's. `DATA-ITEM-1`'s one-item-per-food rule leaves no
other coherent merge, and silently overwriting the amount she recorded on that day would be a worse
answer than skipping.

**`MEAL-COPY-10` (MUST)** — A copy that would add **nothing** — a self-copy, or a destination that already
holds every source food — writes nothing, navigates nowhere, and says nothing. It is not an error; there
is simply no change to report.

**`MEAL-COPY-11` (MUST)** — A successful copy lands her on the **destination day**, so she sees the result
in the journal rather than being told about it.

**`MEAL-COPY-12` (MUST)** — The confirmation and its undo are raised **after** she arrives, so they belong
to the destination day and not to the screen she left.

**`MEAL-COPY-13` (MUST)** — A **failed** copy keeps her where she is with the failure surfaced, and does
not navigate.

**`MEAL-COPY-14` (MUST)** — A copy's undo removes only what that copy added (`MEAL-UNDO-10`) and is
invalidated by a manual change to the destination (`MEAL-UNDO-11`).

---
## 9a. Accessibility

This is the most interactive screen in the app: a food tile carries four states (§2), the primary action
relabels five ways (`MEAL-CTA-*`), and two of its rules are *invisible unless announced* — the
emptied-meal warning (`MEAL-DEL-4`) and the swap autosave (§6). Under VoiceOver, all three of the
screen's data-loss protections are announcement-only.

### VoiceOver labels and traits

**`MEAL-A11Y-1` (MUST)** — Every food tile is a **button** whose label reads its **food name**, and whose
**state is announced as value, not left to colour or border** — picked, being picked, or unavailable
(§2.1). Its accessibility state must distinguish all four states of `MEAL-FOOD-*`.

**`MEAL-A11Y-2` (MUST)** — An **unavailable** tile (`locked`) is announced as **not enabled**, so its
unavailability is reachable without sight of the visual treatment.

**`MEAL-A11Y-3` (MUST)** — A family tile is a **button** labelled with the **family name**, and announces
**how many of its foods this meal holds** when that count is non-zero. The visual badge that carries this
on the grid is otherwise invisible.

**`MEAL-A11Y-4` (MUST)** — The primary action's label is announced as it **reads at that moment**
(`MEAL-CTA-2`, `-5`, `-6`) — *save `<food>`*, *save `<family>`*, *save `<meal type>`*, *save changes*, or
the forward *done*. A single static label would make the action ambiguous in exactly the states where the
ladder exists to disambiguate it.

**`MEAL-A11Y-5` (MUST)** — When the primary action is **unavailable**, it is announced as **not enabled**
and the reason is available — the emptied-meal statement (`MEAL-DEL-4`) or the nothing-picked-yet state.
An unlabelled disabled button is the screen's worst VoiceOver failure, because it is where she is stuck.

**`MEAL-A11Y-6` (MUST)** — The amount control announces the **selected portion** as its value, and the
preparation control announces the **selected preparation** or that none is set. A food whose preparation
list is empty (`MEAL-AMT-5`) exposes **no preparation control** to assistive technology either — not a
disabled one.

**`MEAL-A11Y-7` (MUST)** — The actor control announces **which actor is selected**, and it is absent from
the accessibility tree exactly when it is absent visually (`MEAL-ACTOR-6`, `-7`).

**`MEAL-A11Y-8` (MUST)** — The overflow affordance carries a **descriptive label**, not a punctuation
character. Its two actions announce as *copy* and *delete*, and delete carries its **destructive** trait.

**`MEAL-A11Y-9` (MUST NOT)** — Any label, value, hint, trait or announcement on this screen conveys risk,
allergenicity or suitability. `MEAL-CAT-1` is a prohibition on **conveying**, and a label is a conveyance
channel — the hole this rule closes is the same one [`catalog.md`](catalog.md) `CAT-DERIVE-6` closes for
the allergen mapping.

### Announcements

**`MEAL-A11Y-10` (MUST)** — Entering and leaving a **drill-in** moves VoiceOver focus and announces the
family, because `MEAL-GRID-1` changes the whole content of the screen without changing the screen.

**`MEAL-A11Y-11` (MUST)** — The **emptied-meal** statement (`MEAL-DEL-4`) is **announced when it appears**,
not merely present in the tree. It is a warning about the next tap; discovering it after the delete is
worthless.

**`MEAL-A11Y-12` (MUST)** — A **swap** announces that the departing actor's meal was saved and which actor
is now selected (§6). Sighted or not, the autosave is invisible; unannounced, a swap is indistinguishable
from losing the work.

**`MEAL-A11Y-13` (MUST)** — A **failed** write (`MEAL-FIN-3`, `MEAL-SWAP-3`, `MEAL-COPY-13`) is announced.
A silent failure plus an intact draft looks exactly like success.

**`MEAL-A11Y-14` (MUST)** — An **undo** offer (§8.2) is announced and its action is **reachable by focus**,
with enough time to reach it. An undo that is only reachable visually does not exist for a VoiceOver user,
and `MEAL-UNDO-*` is the screen's whole answer to accidental loss.

### Dynamic Type

**`MEAL-A11Y-15` (MUST)** — At the largest accessibility sizes, **food and family names never truncate**.
A truncated food name is the difference between *mléko kravské* and *mléko kozí* — the record's meaning,
not its presentation. Tiles reflow, grow, or wrap; they do not clip their names.

**`MEAL-A11Y-16` (MUST)** — The **primary action's label never truncates**, since `MEAL-CTA-2`'s whole
purpose is naming what a tap will save.

**`MEAL-A11Y-17` (MUST)** — The **emptied-meal statement never truncates** (`MEAL-DEL-4`).

**`MEAL-A11Y-18` (SHOULD)** — The **note field** grows with the text size and stays scrollable rather than
clipping. A note may be the whole record (`MEAL-DIRT-13`).

**`MEAL-A11Y-19` (MUST)** — The **date** in the header may truncate or abbreviate; the **meal type** in the
header may not. Which slot she is editing is load-bearing; the date is confirmable elsewhere.

### Colour alone

**`MEAL-A11Y-20` (MUST)** — No rule in this section conveys meaning by colour alone. The four food states
carry a **second channel** — the announced state of `MEAL-A11Y-1` and a non-colour visual difference
(mark, border, or shape).

**`MEAL-A11Y-21` (MUST)** — The **destructive** delete is identified by its label and trait, not by being
red.

### Focus order and grouping

**`MEAL-A11Y-22` (MUST)** — A food tile with its amount and preparation controls open is **several
elements**, in the order: the food, then amount, then preparation. She adjusts them, so they must each be
reachable.

**`MEAL-A11Y-23` (MUST)** — A **working-list row** is **one element** for reading with its remove action as
a separate one. She is reading the list to check what is in the meal, not operating each row.

**`MEAL-A11Y-24` (MUST)** — Focus order follows the visual order: header, then the grid or the family's
foods, then the note, then the primary action.

**`MEAL-A11Y-25` (MUST)** — When a food opens for picking, focus moves to it — otherwise the controls that
just appeared are somewhere behind the current position.

### Reduce Motion

**`MEAL-A11Y-26` (MUST)** — Under Reduce Motion, the drill-in and drill-out transitions and the
expand-a-food animation are replaced by an **immediate change of content**. Nothing in §2 or §4.3 depends
on a transition being seen — the transitions are affordance, and every one of them has a non-animated
equivalent.

**`MEAL-A11Y-27` (MUST NOT)** — Reduce Motion suppresses an **announcement** or shortens the time an undo
offer stays reachable. Reduce Motion is about motion; `MEAL-A11Y-14` is not.

---
## 10. What this section does not contain

### 10.1 Prohibitions

These are rules, not routing. Each names a surface the reference implementation does **not** have and
an implementer would reasonably add, so each would be a silent addition rather than a decision. The
scope list in §10.2 answers a different question — *which document owns this*.

**`MEAL-ABSENT-1` (MUST NOT)** — There is no search, filter, or type-ahead over foods. The catalog is
reached by family and by picking, and by nothing else.

The PWA has no search field (`src/routes/meal/+page.svelte` — its only `searchParams` use is reading
the meal type from the URL), and `catalog.md` `CAT-ABSENT-4` already deletes the `aliases` field that
existed to serve one. A search box is the single most obvious "improvement" to a grid of families, and
it changes what the screen is: `MEAL-GRID-*` makes the family the unit of navigation because the family
scope is load-bearing (§2.3). Reintroducing search re-raises a decision already taken.

**`MEAL-ABSENT-2` (MUST NOT)** — No meal carries a **time of day**, and no editor offers one — not a
time picker, not a defaulted timestamp, not an "as of" line.

[INV-3](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-3): meals are day-granular.
`MEAL-ENTRY-2` states it as a property of the visit; this states it as a prohibition on the surface,
because a time field is what an implementer adds when two meals land in one slot. `DATA-ID-2` is the
answer to that case instead.

**`MEAL-ABSENT-3` (MUST NOT)** — No photograph is attached to a meal, and no camera or library control
appears on this screen. Photographs belong to skin observations alone
([`skin-observation.md`](skin-observation.md) §5).

**`MEAL-ABSENT-4` (MUST NOT)** — There is no recents list, no favourites, no frequently-used tier, and
no suggestion of what to pick — including anything derived from what she logged before.

Two reasons, and the second is the load-bearing one. The *Dříve zadané* surface was removed from the
PWA by [#662](https://github.com/jirigrill/eczema-helper/issues/662) along with custom foods, so it is
already gone. But a frequency-ordered tier is also a claim the app must not make: it ranks foods using
her own record, which is the shape of a derived insight
([INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11)), and on an
elimination diet a prominent food reads as an endorsement of it. `MEAL-GRID-13`'s alphabetical order is
the whole ordering story.

**`MEAL-ABSENT-5` (MUST NOT)** — No food, family, or amount carries a warning, a hazard mark, a
severity tint, or any indication that a choice is risky. Nothing on this screen frames a food as a
suspect or a cause.

`DECISIONS.md` §7 removed the hazard axis product-wide; this is its statement on the screen where the
temptation is greatest, since the editor is the one place the mother is choosing a food and an
implementer has an allergen record in hand while rendering it.

**`MEAL-ABSENT-6` (MUST NOT)** — A food tile carries no swipe, long-press, or context-menu affordance.
Everything a food can do, it does through the states in §2.

The reference has none (no swipe, long-press or context handler exists in `FoodTile.svelte` or the meal
route), and `DAY-MEAL-10` already forbids the same on the day view's rows — verified there as an
absence check. A hidden gesture is also unreachable by VoiceOver unless separately exposed, so adding
one silently creates the accessibility gap §9a is written to prevent.

### 10.2 Owned elsewhere

- **Platform types and storage.** Field types, identity, migrations and sync are
  [`persistence-model.md`](persistence-model.md)'s; this section cites `DATA-*` and never restates it.
- **Layout and visual design.** No sizes, colours, spacing or component names — §9a specifies what must
  be *announced*, *readable* and *reachable*, never how it looks.
- **Invariant text.** Cited by id from `CONTEXT.md`, never copied (see the disposition table).
- **The catalog itself.** Which foods exist, their families, their authored preparations and their
  ordering are [`catalog.md`](catalog.md)'s; this section consumes them.
- **The day view.** How a saved meal renders in the journal, the day strip's range, and the entry points
  into this screen are [`day-view.md`](day-view.md)'s.
- **The feeding stage.** How it is chosen and changed is [`settings.md`](settings.md)'s and
  [`first-run.md`](first-run.md)'s; this section only reads it (§5.2).
- **Derived insight.** Nothing here computes a pattern, a correlation or a recommendation
  ([INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11)).
- **The design prototype's meal screens.** `redesign-prototype.html` still shows the custom-food
  surfaces removed by [#662](https://github.com/jirigrill/eczema-helper/issues/662) — the `➕ Vlastní`
  tile, free-text entry and *Dříve zadané*. The live variant is the catalog-only grid this section
  specifies. Do not cite the prototype for this area without that caveat.

---
## 11. Divergence index

| # | Where | Summary | Class |
| --- | --- | --- | --- |
| 1 | §1.1 | Future days are loggable and openable here, matching the day view's range | settled by [#654](https://github.com/jirigrill/eczema-helper/issues/654) |
| 2 | §1.2 | An unknown food id is dropped and reported, never thrown | defect fixed |
| 3 | §2.2 | Un-picking a food clears its remembered amount instead of keeping it | defect fixed |
| 4 | §2.2 | Availability filtering is described as what it is; no claimed side effect | documentation defect |
| 5 | §2.2 | Starting a food finishes the sibling being picked rather than holding both | defect fixed |
| 6 | §3.3 | The dirtiness key drops the display name | settled by [#703](https://github.com/jirigrill/eczema-helper/issues/703) |
| 7 | §3.4 | Savability and pending work are two questions; both asked in both modes | defect fixed (largest here) |
| 8 | §4.1 | The visit mode is decided from a settled read, never a not-yet-emitted query | defect fixed |
| 9 | §4.3 | Tapping outside resolves a food the same way in the grid and the drill-in | defect fixed (incoherence) |
| 10 | §4.3 | The renderer is as strict as the model: one row per food | defect fixed (drift source) |
| 11 | §4.3 | The drill-in is view state, not a history entry | defect fixed (drift source) |
| 12 | §6 | A swap finishes the food being picked before writing, rather than dropping it | defect fixed |
| 13 | §6.1 | The post-autosave state is not a silently unavailable save | settled by [#690](https://github.com/jirigrill/eczema-helper/issues/690) (presentation deferred) |
| 14 | §2.2 | Un-picking releases held foods, like every other exit from a food's active state | defect fixed (latent) |
| 15 | §4.3 | Foods are ordered alphabetically within their group, matching the reference | owner's call — [#772](https://github.com/jirigrill/eczema-helper/issues/772) |
| 16 | §8 | An undo offer's disappearance hides the offer without discarding the buffer | owner's call — [#772](https://github.com/jirigrill/eczema-helper/issues/772) |
| 17 | §10.1 | Six absences become numbered prohibitions (`MEAL-ABSENT-1`..`-6`) rather than features that merely do not exist | settled by [#772](https://github.com/jirigrill/eczema-helper/issues/772) |

Twelve of the seventeen are **defects fixed**, which is the honest measure of this area: it is the app's
most-iterated screen, and iteration left it incoherent in ways only a full read surfaces. Two —
Divergences 7 and 12 — are **data loss** in the reference. Divergences 3 and 14 were **one index row
until [#772](https://github.com/jirigrill/eczema-helper/issues/772)**, which found the row describing
the cleared amount while the inline block beside it described the lock release: two changes sharing
one slot, so the amount change had no entry of its own.

**Divergence 17 is not a change in behaviour**, and is listed because a reviewer checking for drift
needs to find it: `MEAL-ABSENT-1`..`-6` all describe what the reference already does — nothing — and
the port matches it. What changed is that six absences now have ids, so each reaches the verification
table as a check rather than existing only as the fact that nobody built the feature.


---
## 12. Verification

### Where each rule is verified today

The reference's coverage of this area is unusually good — roughly 1,900 lines across four files — which
is exactly why the *nothing verifies* list below matters: it is short, and everything on it is real.

| Rule group | Verified today by | Verdict |
| --- | --- | --- |
| `MEAL-FOOD-*`, `MEAL-GRID-*` (§2) | `src/lib/domain/working-meal.test.ts` (727 lines) | **translate** — pure state machine, ports directly |
| `MEAL-PROJ-*` (§3.1–3.2) | `working-meal.test.ts` projection and rehydration cases | **translate**, minus the throw (Divergence 2) |
| `MEAL-DIRT-1..9` (§3.3) | `src/lib/domain/meal-dirtiness.test.ts` (174 lines) | **translate**, minus the display name (Divergence 6) |
| `MEAL-DIRT-10..13` (§3.4) | partially — the compose-only behaviour is pinned, i.e. the defect is pinned | **re-derive** — the existing assertion encodes Divergence 7's wrong side |
| `MEAL-VISIT-*`, `MEAL-GRID-*`, `MEAL-CTA-*` (§4) | `src/routes/meal/page.test.ts` (997 lines) | **re-derive** — DOM-level, and Divergences 8–11 change the model |
| `MEAL-GRID-12`, `-13` (§4.3 ordering) | `src/lib/components/FamilyDrillIn.test.ts` — 10 tests pinning per-group food sequences, plus one pinning authored group order | **translate** the *shape* of the assertion, **re-derive** the sequences — the reference collates for Czech and the port collates for its own locale (Divergence 15) |
| `MEAL-AMT-*` (§5.1) | `src/lib/domain/preparation-rules.test.ts` | **translate** |
| `MEAL-ACTOR-*` (§5.2) | `page.test.ts` eligibility and snap cases | **translate** as logic, **re-derive** the presentation |
| `MEAL-SWAP-*` (§6) | `src/lib/stores/meal-editor.test.ts` (908 lines) + `page.test.ts` | **translate**, minus the mid-pick drop (Divergence 12) |
| `MEAL-FIN-*`, `MEAL-DEL-*` (§7) | `meal-editor.test.ts` finalize and empty-delete cases | **translate** |
| `MEAL-UNDO-*` (§8.2) | `src/lib/stores/discard-buffer.test.ts` | **translate** as behaviour; the buffer's *shape* is a PWA type |
| `MEAL-COPY-*` (§9) | `working-meal.test.ts` `copyMealInto` cases + `page.test.ts` picker cases | **translate** |
| `MEAL-ABSENT-1`..`-6` (§10.1) | almost nothing by design; the nearest is `FoodTile.test.ts`, which drives tap only, and `MealCard.test.ts:130`, the day view's equivalent gesture check | **re-derive** as absence checks. Three are worth writing and three are not: `-1` (no search field on the screen), `-4` (no tier of foods is ordered by anything but name — the guard against a frequency list arriving as a courtesy) and `-6` (a food tile exposes exactly one action). `-2`, `-3` and `-5` are already guarded by rules with tests elsewhere (`MEAL-ENTRY-2`, the photo rules in `skin-observation.md`, `CAT-DERIVE-*`) and need no second assertion here. |
| Dexie transaction and `liveQuery` assertions | `src/lib/adapters/dexie-meal-repository.test.ts` | **do not translate** — asserts a storage guarantee iOS does not have |

### Rules nothing verifies today

- **The whole of §9a.** Not one accessibility rule has a test, a label, or an announcement behind it. This
  is why the block exists ([#755](https://github.com/jirigrill/eczema-helper/issues/755)) and it is the
  largest unverified surface in the section.
- **`MEAL-ACTOR-8`** — the stage resolving *after* mount. The reference has the effect but no test drives
  the late-resolution path, which is the one that produces a wrong open.
- **`MEAL-SWAP-3`** — the swap-write failure. The abandon-the-swap branch is the section's only genuine
  data-loss path and nothing exercises it.
- **`MEAL-SWAP-9`** — an autosaved actor dropping out of the record when edited again. Reasoned from the
  condition, never asserted.
- **`MEAL-UNDO-9`** — that no later store emission overwrites a just-restored draft. Guarded by a mount
  flag with no test on the race.
- **`MEAL-COPY-7`** — that a copy does not carry the note. It follows from the code writing `undefined`,
  and no test says it is intended.
- **`MEAL-DEL-8`** — a note with no foods not keeping a meal alive.
- **`MEAL-EXIT-2`** — exit-path equivalence across the back affordance and the system gesture. The
  reference tests them separately; nothing asserts they agree, which is how the hole appeared.

### Acceptance pass

Do these on a device, in order. Each names the rules it exercises. Steps marked **⚠ fails on the PWA**
are the divergences — they are the steps that prove the port did something.

**Setup.** Set the feeding stage to *mixed*, so both actors are eligible and §6 is reachable.

1. From today's day view, open an **empty** lunch slot. It opens on the family grid with nothing picked
   and the primary action unavailable. — `MEAL-VISIT-2`, `MEAL-CTA-7`, `MEAL-CTA-7`
2. Drill into a family. Tap a food. Its amount appears with a default already set; set an amount and
   confirm it. The food now reads as picked. — `MEAL-FOOD-2`, `MEAL-FOOD-6`, `MEAL-AMT-2`
3. While that food is being picked, tap a **second** food in the same family. The first food is
   **finished, not abandoned** — it stays picked. — `MEAL-FOOD-7`, **⚠ fails on the PWA** (Divergence 5)
4. Find a food with **no** preparations offered (37 of the reference's foods). It shows **no preparation
   control at all** — not an empty one. — `MEAL-AMT-5`
5. Un-pick a picked food, then pick it again. Its amount is back to the **default**, not the amount you
   had set. — `MEAL-FOOD-10`, **⚠ fails on the PWA** (Divergence 3)
6. Back out of the family to the grid. Now use the **system back gesture** from the grid — you leave the
   screen, and you are offered to take the work back. Take it: the same foods are there, including one you
   left mid-pick. — `MEAL-GRID-15`, `MEAL-EXIT-2`, `MEAL-UNDO-1`, `MEAL-UNDO-3`
7. Drill in again and use the **system back gesture** from inside the family. You return to the grid and
   **stay on the screen**. — `MEAL-GRID-15`, **⚠ fails on the PWA differently** (Divergence 11 — the PWA
   reaches the grid too, but by popping a history entry)
8. Write a note. Save. The meal appears on the day view. — `MEAL-FIN-1`, `MEAL-FIN-4`
9. Re-open it. It opens as an **edit** with your foods and note, and the primary action reads *save
   changes* and is **unavailable** until you change something. — `MEAL-VISIT-1`, `MEAL-CTA-5`,
   `MEAL-DIRT-1`
10. Change an amount, then change it back. The action goes unavailable again. Add a trailing space to the
    note — nothing becomes savable. — `MEAL-DIRT-7`, `MEAL-DIRT-8`
11. Turn a preparation on and off. Nothing becomes savable. Now **clear a preparation that was stored** —
    that *is* a change. — `MEAL-DIRT-4`, `MEAL-DIRT-5`
12. In this **saved** meal, tap a **new** food, set its amount, and **leave without confirming it**. You
    are offered to take it back, and taking it restores that food. — `MEAL-DIRT-11`, `MEAL-DIRT-12`,
    **⚠ fails on the PWA** (Divergence 7 — the food is lost with no undo at all)
13. Remove every food from the saved meal. The screen **says** that saving or leaving now removes the
    meal. Leave. It is gone from the day view, and you are offered to take it back. Take it — the meal
    returns with its foods and note. — `MEAL-DEL-2`, `MEAL-DEL-3`, `MEAL-DEL-4`, `MEAL-UNDO-5`
14. Open the overflow, delete the meal explicitly, and confirm. It is gone and undoable. — `MEAL-DEL-5`,
    `MEAL-DEL-6`
15. With foods picked and unsaved, **switch actor**. Your work is **saved** for the departing actor and
    the screen re-opens on the other actor's slot. — `MEAL-SWAP-2`, `MEAL-SWAP-4`
16. Repeat, but leave a food **mid-pick** when you switch. That food is part of what gets saved. —
    `MEAL-SWAP-6`, **⚠ fails on the PWA** (Divergence 12 — silently discarded)
17. Switch **back** to the first actor. Its meal is there and clean, and the primary action offers a
    **forward exit**, not an unavailable save. — `MEAL-EXIT-5`, `MEAL-SWAP-7`
18. Now cycle between two **already-saved, unedited** actors. No forward exit appears — the ordinary
    unavailable save does. — `MEAL-SWAP-8`, `MEAL-EXIT-7`
19. Edit the autosaved actor's meal again. The action routes back through **save**, not the forward exit.
    — `MEAL-SWAP-9`
20. Open a saved meal, overflow, **copy** it to **tomorrow**'s same slot. You land on tomorrow and see it
    there — **without** the source's note. — `MEAL-COPY-3`, `MEAL-COPY-4`, `MEAL-COPY-6`, `MEAL-COPY-7`,
    `MEAL-COPY-11`
21. Copy the same meal onto a slot that already holds **one of its foods** with a **different amount**.
    That food is untouched — its amount is the destination's — and the others are added. —
    `MEAL-COPY-8`, `MEAL-COPY-9`
22. Copy a meal onto a slot that already holds **all** of its foods. Nothing happens: no write, no
    navigation, no message. — `MEAL-COPY-10`
23. Copy into a slot, then **edit that slot by hand**, then try the copy's undo. It is gone — your manual
    change is not at risk. — `MEAL-UNDO-11`
24. Set the stage to **solids** and open a meal from a day logged for the **mother**. It still reads as
    the mother's meal on the day view and opens normally. — `MEAL-ACTOR-9`
25. Turn on **VoiceOver** and repeat steps 1–2, 13 and 15. Every food announces its **state**; the
    unavailable primary action announces **why**; the emptied-meal warning is **announced when it
    appears**; the swap **announces that it saved**. — §9a, **⚠ fails on the PWA entirely** (nothing in
    §9a is implemented)
26. Set text size to the **largest accessibility size**. No food name, no family name, no primary-action
    label and no emptied-meal statement is cut off. — `MEAL-A11Y-15`, `-16`, `-17`

---
## 13. Open questions and adjudications

### The one OPEN rule

**`MEAL-DEG-4`** — what the screen does when a stored meal references a food the current catalog no longer
knows (§1.2). This section fixes that the food is **dropped and reported, never thrown** (Divergence 2),
which is enough to build the screen. What is **open** is whether the mother is *told* — an inline note on
the meal, a one-time notice, or nothing — and that depends on whether the catalog can lose a food at all
under mandatory sync, which [`catalog.md`](catalog.md) owns and has not settled. It carries **no schema
deadline**: the record already holds the food id, so nothing is unrecorded either way.

### The nine questions carried from the state-machine document

[`meal-editor-state-machine.md`](https://github.com/jirigrill/eczema-helper/blob/main/docs/spec/meal-editor-state-machine.md)
recorded sixteen open questions. Seven were struck by
[#689](https://github.com/jirigrill/eczema-helper/issues/689) and
[#690](https://github.com/jirigrill/eczema-helper/issues/690). The remaining nine are adjudicated here —
**by the agent, under #690's coherence default, not by the owner**. Each is a rule above, and each is the
kind of question the owner may overturn cheaply, because none of them changes what is recorded.

| # | Question | Adjudication | Rule |
| --- | --- | --- | --- |
| 1 | Does un-picking a food keep its amount for a later re-pick? | **No.** A remembered amount on a food she removed is a guess about an intention she reversed. | `MEAL-FOOD-10` |
| 2 | May two foods in one family be mid-pick at once? | **No.** Starting one finishes the other. | `MEAL-FOOD-7` |
| 3 | Does tapping outside a food-edit row confirm or cancel? | **Confirm**, in both the grid and the drill-in. The PWA does both, and confirm is the answer that cannot lose the amount she just set. | `MEAL-GRID-11` |
| 4 | Is the drill-in a navigation destination? | **No** — view state. | `MEAL-GRID-1` |
| 5 | Does a swap finish a mid-pick food or drop it? | **Finish it.** Pending work is never lost silently. | `MEAL-SWAP-6` |
| 6 | Is the post-autosave clean state a disabled save? | **No** — a forward exit. | `MEAL-EXIT-5` |
| 7 | Does a copy carry the source's note? | **No.** A note is about that day. | `MEAL-COPY-7` |
| 8 | On a merge, whose amount wins for a food both meals hold? | **The destination's.** The copy skips the food entirely rather than overwriting an amount she recorded on that day. | `MEAL-COPY-9` |
| 9 | Does a note with no foods keep a meal alive? | **No.** A note annotates foods; the undo is what protects it from silent loss. | `MEAL-DEL-8` |

### Questions this section raises and does not answer

- **Whether an undo offer's reachable time is long enough for a VoiceOver user.** `MEAL-A11Y-14` requires
  *enough time to reach it* and does not say how long, because the duration is an iOS UI decision and the
  right answer depends on the announcement it follows. Flagged as the one accessibility rule that is
  specified as an intent rather than a threshold.
- **What the swap announcement says, verbatim.** `MEAL-A11Y-12` fixes that it announces the save and the
  new actor; the Czech wording is the string layer's.
- **No schema deadlines.** Nothing open here would require a field that must be recorded now. Every
  question above is about presentation, timing, or which of two recorded values wins — the meal's shape is
  settled by [`persistence-model.md`](persistence-model.md)'s `DATA-*` rules.
