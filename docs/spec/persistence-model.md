# Persistence model — behavior specification

**Status:** written against the format settled by
[#682](https://github.com/jirigrill/eczema-helper/issues/682) — see [`TEMPLATE.md`](TEMPLATE.md) for
the rules, and [`skin-observation.md`](skin-observation.md) for the worked example. **Awaits the
owner's confirmation.** Nine decisions were settled by the owner in the grilling session that produced
this document (§15 records all nine); the rest carry through from closed tickets and are cited rather
than re-derived.
**Behavior reference:** `jirigrill/eczema-helper` @ `582f662` (frozen PWA),
`src/lib/domain/models.ts`, `src/lib/db/atopic-db.ts`,
`src/lib/adapters/dexie-skin-observation-repository.ts`.
**Resolves:** [#730](https://github.com/jirigrill/eczema-helper/issues/730) on the transition map
[#672](https://github.com/jirigrill/eczema-helper/issues/672).

## Overview

This section states **what the app stores**: the shape of every record the mother's own use creates,
which parts of that shape are permanent, and what the app does about the ways a synchronised store
can misbehave. It is the only section on the map that a later release cannot freely rewrite.

That is not a stylistic claim. CloudKit schemas are **additive only** once promoted to production:
new record types and new fields may be added, but nothing existing may be renamed, retyped, deleted,
or have its encryption changed. A field that was never recorded therefore cannot be backfilled — the
data simply does not exist to fill it with. Every other section in this spec describes behavior a
patch release can change; this one carries deadlines, and §10 names which rules have them.

This document states what the app stores and what the mother can observe as a consequence, in
English, without reference to Swift, SwiftUI, SwiftData, Svelte or Dexie. Swift tests are derived
from the numbered rules; the owner's acceptance pass is derived from §13.

Five things are worth knowing before the rules make sense:

1. **The store holds only what she wrote.** The food catalog is bundled data outside the store
   ([#686](https://github.com/jirigrill/eczema-helper/issues/686)), so there is no record type for
   foods, allergens or families, nothing is seeded, and nothing reconciles on launch. The whole of
   this section concerns four record types and the one catalog value they reference.
2. **Identity is not the key she thinks in.** The reference implementation makes a meal's identity
   its own content — the string `date:mealType:actor` *is* the primary key, so writing the same slot
   twice overwrites. That mechanism does not survive mirroring, because the app cannot choose a
   record's name. The composite survives as a **field the app matches on**, and one-meal-per-slot
   becomes something the app converges toward rather than something the store guarantees (§4).
3. **Duplicates are a single-phone problem, not a two-device one.** This is the finding most likely
   to be forgotten: Apple's own reason for its deduplication routine is apps that preload data with
   no way to tell whether a peer already did. That is the **delete-and-reinstall** case — the exact
   scenario this port exists for. Deduplication cannot be scoped out by declaring the app
   single-device ([#691](https://github.com/jirigrill/eczema-helper/issues/691)).
4. **Nothing arrives atomically, and nothing announces that it has finished arriving.** A parent may
   arrive without its children, children before their parent, and in indeterminate order. There is no
   API for "the initial import is complete", so no rule in this document may branch on the store
   being empty (§7).
5. **Three things the mother would expect to be in the store are deliberately not.** The feeding
   stage, the consent record, and the diagnostic log all live outside it, each for the same
   structural reason and each at a stated cost (§8).

**How to read this document:** see
[`skin-observation.md` § How to read this document](skin-observation.md#how-to-read-this-document).
Rule ids here are `DATA-<group>-<n>`, permanent identity, never renumbered or reused.

**One departure from the template, stated rather than assumed.** `TEMPLATE.md` says a section is
*not a schema* and that rules describe what the mother can observe. This section is the acknowledged
exception it names: field lists appear here because identity, immutability and absent-versus-empty
*are* observable behavior. The test applied throughout is whether a wrong answer changes what she
sees or loses — if it does not, it is not in this document. Types, migration mechanics and CloudKit
console configuration stay out (see the appendix).

### Invariant dispositions

Invariants are cited, never restated. [#691](https://github.com/jirigrill/eczema-helper/issues/691)
classified all fourteen; the ones this section touches carry their disposition here so a bare
citation cannot import a contradiction. This section touches more of them than any other, because
**#691's sweep found that the store was carrying almost nothing** — only three invariants were
store-enforced, and the rest were already application code.

| Ref | Leading phrase | Disposition here |
| --- | --- | --- |
| [INV-1](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-1) | _Single device, no sync_ | **Void for iOS.** Sync is mandatory ([#705](https://github.com/jirigrill/eczema-helper/issues/705)). It is the premise of §4 through §7 — every convergence rule in this document exists because this invariant is false. |
| [INV-2](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-2) | _No backup mechanism exists_ | **Void for iOS** as to durability; sync carries it ([#683](https://github.com/jirigrill/eczema-helper/issues/683)). Still **no rollback** — which is why `DATA-CONV-4`'s losing edit is unrecoverable and why that cost is stated rather than mitigated. |
| [INV-3](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-3) | _Meals are day-granular_ | **Holds unchanged**, and is the reason `DATA-MEAL-3` keeps the calendar date as a label rather than deriving it from an instant. |
| [INV-4](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-4) | _One `Meal` per date+mealType+actor slot_ | **Enforcement moved, and weakened to an eventual property.** The store no longer guarantees it; the app converges on it (§4). The invariant's own text embeds the mechanism — "upserted, not appended" — which is no longer sufficient alone. The wording stays PWA-accurate; §4.1 states the sync-era enforcement. |
| [INV-5](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-5) | _Causation is derived, not recorded_ | **Holds unchanged**, as an absence: no record type in §3 carries a suspected cause, and `DATA-ABSENT-1` numbers that prohibition so a later reader cannot mistake it for an omission. |
| [INV-6](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-6) | _Per-region severity set, atomically saved with photos_ | **Holds, with one named loss** — the only invariant that genuinely weakens. The local write stays atomic; cross-device atomic *arrival* does not survive. `docs/spec/skin-observation.md` §5.2 records it; §5.2 and §6 here say what the app does about it. |
| [INV-7](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-7) | _Calm regions persist; every save witnesses all nine_ | **Holds unchanged, and is now structurally guaranteed.** `DATA-SKIN-4` folds the nine regions into one value precisely so a partial arrival cannot represent a sparse observation (Divergence 3). |
| [INV-8](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-8) | _`id` and `createdAt` immutable across edit, delete, undo_ | **Holds unchanged**, and this section is where it is enforced: `DATA-SKIN-2` makes `createdAt` write-once, and `DATA-CONV-3` must not let a convergence pass restamp it. |
| [INV-9](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-9) | _Photos stored unencrypted at rest_ | **Void for iOS.** Field encryption ships from release one and §10.3 declares **every** encryptable attribute encrypted (`DATA-ENC-1`). `DATA-LOCK-4` is why that is not the whole story for photographs — a declared-encrypted field is silently **not** encrypted past §5.2's asset threshold — so `DATA-ENC-5` has the app encrypt photo bytes itself. Both halves of the invariant are therefore void, by two different mechanisms. The on-device store file is settled separately in §11.1 ([#752](https://github.com/jirigrill/eczema-helper/issues/752)): it inherits `NSFileProtectionCompleteUntilFirstUserAuthentication`, measured, so the store is encrypted at rest without the app acting. The key `DATA-ENC-5` requires is §11.2 ([#763](https://github.com/jirigrill/eczema-helper/issues/763)). |
| [INV-10](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-10) | _Dexie/IndexedDB, normalized tables; photos in a dedicated table_ | **Void for iOS** as to mechanism — replaced wholesale. One clause outlives it by coincidence rather than inheritance: photos do keep their own record type (§5.1), for transport reasons that have nothing to do with normalization. |
| [INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11) | _The app is a Logging Tool_ | **Holds**, and constrains this section twice: no derived value is persisted (`DATA-ABSENT-2`), and no field exists whose only use would be to support a claim the app must not make. |
| [INV-12](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-12) | _Records carry types, not display strings_ | **Holds, and is tightened into a schema deadline.** `DATA-ITEM-2` drops `MealItem.name` — the violation [#677](https://github.com/jirigrill/eczema-helper/issues/677) flagged — and [#703](https://github.com/jirigrill/eczema-helper/issues/703) already settled that no fallback label replaces it. |
| [INV-13](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-13) | _Catalog is data-first and bundled_ | **Holds, and is strengthened by the platform.** Because the catalog is outside the store ([#686](https://github.com/jirigrill/eczema-helper/issues/686)), no catalog row can duplicate under sync — which removes the *one* duplicate cause Apple says is avoidable by design (§4.4). |
| [INV-14](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-14) | _Every meal has an eligible actor_ | **Holds as a rule; its input moved.** Eligibility derives from the feeding stage, which is no longer stored beside the meals (§8.1). The actor stays on the record, so a meal remains self-describing. |

`CONTEXT.md` also holds roughly fifteen invariant-shaped rules **unnumbered**, in glossary prose. One
bears on this section and is cited by heading: _SkinObservation_ (under § _Assessment & Observation_),
whose identity clause `DATA-SKIN-1` and `DATA-SKIN-2` implement. The _MealEditor_ trio, the Copy Meal
rules and the catalog _Principles_ are all application-enforced and untouched by anything here.

### Divergences from the PWA

This is not a 1:1 port. Per [#690](https://github.com/jirigrill/eczema-helper/issues/690),
**coherence is presumed right**: where the reference implementation does two different things, the
port picks the coherent rule, and *keeping* a wart is what needs a named reason.

Every divergence is marked inline as **⚠ Divergence** with (a) what the PWA does, (b) what the iOS
app does, and (c) why. There are eleven, and they are unusual for this spec in that **most are not
defects**: four are forced by the platform, because the reference implementation was built on a
store that made guarantees this one does not. They are indexed in §12.

---
## 1. Vocabulary

| Term | Meaning |
| --- | --- |
| **Record** | One stored row the mother's use created. There are four kinds (§2). |
| **Slot** | The addressable position of a meal: the `(date, mealType, actor)` triple. At most one meal belongs in a slot. |
| **Natural key** | The value that names a slot — the composite `date:mealType:actor`. A field the app matches on, never the record's identity (§4.1). |
| **Record name** | The identifier the sync layer gives a record. Opaque, assigned by the framework, and outside the app's control ([#714](https://github.com/jirigrill/eczema-helper/issues/714)). Never a natural key. |
| **Tiebreak** | A per-record value, minted once on the device that created the record and identical on every device thereafter, whose only purpose is to let two devices independently pick the same winner (§4.2). |
| **Convergence** | The process by which two records that should have been one become one, without coordination between devices (§4). |
| **Superseded** | Marked as a convergence loser: still stored, no longer shown, not yet erased (§4.3). |
| **Orphan** | A photo whose parent observation is absent — either because it has not arrived yet, or because it was deleted on another device. The two are indistinguishable at any single moment (§6). |
| **Arrival** | A record becoming visible on a device other than the one that wrote it. Unordered, unbatched, and unannounced (§7). |
| **Promotion** | Publishing the schema to production, after which record types and fields are permanent (§10). |

Three terms this section uses are shared and defined in [`GLOSSARY.md`](GLOSSARY.md): **feeding stage**
and **eligible actors** (§8.1 states where the stage is kept, not what it means) and **pending work**
(§7.3 states what it means for a record that has not uploaded).

---
## 2. What is stored, and what is not

**`DATA-SCOPE-1` (MUST)** — The store holds exactly four record types: **meal**, **meal item**, **skin
observation**, and **skin photo**. Nothing else the mother's use creates is a record.

**`DATA-SCOPE-2` (MUST NOT)** — No record type exists for a food, an allergen or a food family. The
catalog is bundled read-only data outside the store
([#686](https://github.com/jirigrill/eczema-helper/issues/686)).

**`DATA-SCOPE-3` (MUST NOT)** — Nothing is seeded into the store on first launch, and nothing
reconciles the store against the bundle on launch or at any other time.

These three rules are worth more than they look. Apple names two causes of duplicate data under
mirroring, and one of them is *"apps [that] rely on some initial data and there's no way to allow only
one peer to preload it"* — an app that seeds a catalog creates duplicates of it on every device that
installs. Because the catalog never enters the store, that entire class of duplicate is unreachable
here, and §4's convergence machinery has to handle only the other cause: two devices independently
creating the same thing.

**`DATA-SCOPE-4` (MUST)** — A meal item is stored **inside** its meal, not as an independently
addressable record (§3.2). A skin photo is stored as its **own** record, related to its observation
(§5.1). These two choices go opposite ways for the same reason, and §5.1 explains why.

### 2.1 The one catalog value the store holds

**`DATA-SCOPE-5` (MUST)** — The only catalog value any record holds is the **food id** on a meal item.
No record holds a family id, an allergen id, a label, or any other catalog-derived value.

**`DATA-SCOPE-6` (MUST)** — A food id is stored exactly as the bundled catalog spells it, and the app
never rewrites a stored food id — not on migration, not on catalog update, not on read.

The second rule is what makes [#703](https://github.com/jirigrill/eczema-helper/issues/703)'s tolerant
read possible at all. That ticket settled that an unresolvable food id is a display problem with no
schema consequence: the id stays on disk untouched, the item is hidden, the meal becomes read-only,
and the item reappears in full when the app updates. All of that depends on nothing ever rewriting the
stored id — a device on an older app version must not be able to damage a record written by a newer
one.

---
## 3. The meal record

### 3.1 Fields

**`DATA-MEAL-1` (MUST)** — A meal record holds: a **tiebreak** value, the **natural key**'s three
components (calendar date, meal type, actor), its **items**, an optional **note**, a **creation
instant**, and an optional **last-edit instant**.

**`DATA-MEAL-2` (MUST)** — The three natural-key components are stored as **three separate fields**,
not as one concatenated string.

> **⚠ Divergence 1.** *PWA:* the composite string `date:mealType:actor` is the record's primary key,
> and the separate `date`, `mealType` and `actor` fields duplicate it. *iOS:* the three fields are the
> only home for those values; no concatenated form is stored. *Why:* the concatenation existed to *be*
> the key, and it can no longer be one (§4.1). Keeping it as a field would store the same three values
> twice, giving them two places to disagree — and one of them, being a string, could not be checked by
> the compiler. Class: **forced by platform**.

**`DATA-MEAL-3` (MUST)** — The calendar date is stored as a **calendar-day label**, not as an instant.
It is the day the mother filed the meal under, and reading it never involves a time zone.

**`DATA-MEAL-4` (MUST)** — The creation instant is stored as an instant, and so is the last-edit
instant.

> **⚠ Divergence 2.** *PWA:* every date and timestamp is a string — the day as `YYYY-MM-DD`, the
> instants as ISO 8601. *iOS:* the two instants become real instants; the calendar day stays a label.
> *Why:* the instants genuinely are instants and should be typed as such, but the day is not one. It
> is derived from the *local* calendar at the moment she logged, and typing it as an instant would make
> the day a record appears under depend on the reader's time zone.
> [#728](https://github.com/jirigrill/eczema-helper/issues/728) has now **settled** the time-zone
> question the same way — `day-view.md` `DAY-NAV-9`: the calendar date is fixed at log time and never
> recomputed — so this typing is no longer merely keeping a deferral safe, it is what the resolution
> requires. The prototype behind it measured the alternative and found that recomputing each day from
> its instant moves records on every leg away from home *and does not unwind on return*. This is the
> one place the reference implementation's stringly typing is correct rather than lazy. Class:
> **defect fixed (half)** — half the fields are corrected, half are deliberately left as they are.

**`DATA-MEAL-5` (MUST)** — The last-edit instant is **absent** on a newly composed meal, and set only
when an existing meal is edited. Absent means "never edited since creation", and is distinct from
equal-to-creation.

**`DATA-MEAL-6` (MUST)** — The creation instant is **write-once**. An edit stamps the last-edit instant
and leaves the creation instant untouched.

**`DATA-MEAL-7` (MUST)** — The note is **absent** when she wrote none. An empty note and no note are
the same thing to every reader, and the app stores the absent form.

### 3.2 Items

**`DATA-ITEM-1` (MUST)** — A meal's items are stored **within the meal record**, as an ordered value.
An item is not independently addressable and has no identity of its own.

**`DATA-ITEM-2` (MUST)** — An item holds a **food id**, an **amount**, and an optional **preparation
method**. It holds nothing else.

> **⚠ Divergence 3.** *PWA:* an item also carries `id` — minted fresh on every write *and* every copy —
> and `name`, the Czech display string. *iOS:* both are gone. *Why:* two separate defects. The `id`
> looks stable and is not, so anything relying on it across a save is already broken; only
> copy-undo reads it, within one editor session, where position serves. And `name` is
> [INV-12](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-12)'s violation that
> [#677](https://github.com/jirigrill/eczema-helper/issues/677) flagged and
> [#703](https://github.com/jirigrill/eczema-helper/issues/703) settled — names resolve from the
> catalog at render, never from the record, and `DAY-MEAL-6` already states so as a written rule.
> Class: **defect fixed**.

**`DATA-ITEM-3` (MUST)** — Item order is stored and preserved: items read back in the order she added
them.

**`DATA-ITEM-4` (MUST NOT)** — No item is stored outside a meal. There is no route by which an item can
exist whose meal does not.

Embedding is the decision that pays for itself twice. It makes an item's arrival without its meal
unrepresentable — one of the two partial-arrival shapes §7 otherwise has to tolerate — and it removes a
relationship from the convergence pass in §4.3, which has to repoint every relationship a superseded
record held. Items are also the one child in this schema with nothing to lose from embedding: they are
few, small, always read with their parent, and never addressed alone.

---
## 4. Identity, uniqueness and convergence

This is the section [INV-4](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-4)
becomes true through rather than being guaranteed by. It is the largest behavioral change in the port,
and none of it is a choice.

### 4.1 The composite key stops being identity

**`DATA-ID-1` (MUST)** — A record's identity is the **record name**, which the app does not choose, does
not construct, and cannot make meaningful. It is opaque.

**`DATA-ID-2` (MUST)** — The natural key is a **field the app matches on**. It is not identity, and
writing a meal into an occupied slot is therefore not an overwrite.

That is a statement about the storage layer, and **no interface path reaches it**: `DAY-MEAL-8` in
[`day-view.md`](day-view.md#34-entering-the-editor) opens every occupied slot in **edit**, so the write
that would land beside an existing meal lands *into* it instead. Two records for one slot therefore
arise from **arrival** — a record reaching the device from elsewhere — and never from her logging a
meal. Do not read this rule as a hazard needing a guard: a confirm-the-overwrite prompt on save would
protect nothing and would fire on ordinary re-editing, which is the flow she uses most
([#744](https://github.com/jirigrill/eczema-helper/issues/744)).

This is also what happens when a westward flight makes her live one calendar date twice. Both
breakfasts claim `date:mealType:actor`, and the second opens the first in edit rather than colliding
with it — one meal, holding the foods of both. Day-granularity
([INV-3](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-3)) never promised to
separate two meals inside one slot, and nothing on screen distinguishes them, since a user-facing meal
time is forbidden. Accepted deliberately (#744).

**`DATA-ID-3` (MUST NOT)** — The app never derives a record name from a record's content, and never
attempts to make two devices mint the same record name for the same slot.

> **⚠ Divergence 4.** *PWA:* identity *is* content — `Meal.id` is the composite string, so writing the
> same slot twice is an upsert and one-meal-per-slot is free and immediate. *iOS:* identity is opaque
> and assigned; the composite is a field, and one-meal-per-slot becomes an eventual property the app
> converges on. *Why:* two independent reasons, and either alone would be sufficient. The framework
> derives a record's name from its own local object identifier and offers no way to supply one
> ([#691](https://github.com/jirigrill/eczema-helper/issues/691),
> [#714](https://github.com/jirigrill/eczema-helper/issues/714)); and record names are permanently
> plaintext and copied into relationship fields, so a content-derived name would publish an infant's
> feeding schedule to the sync provider in the clear, forever, **even with every field encrypted**.
> Class: **forced by platform**.

**`DATA-ID-4` (MUST)** — The observable consequence of a collision is a **visible duplicate**, never a
silent loss. Two meals in one slot both appear until convergence resolves them.

That last rule is the honest statement of what was traded. The reference implementation could not
produce a duplicate and could silently overwrite; this one cannot silently overwrite and can produce a
duplicate. A duplicate meal is visible on the day view, which is what makes it tolerable — she can see
that something is wrong, and it corrects itself.

The claim holds because `DATA-ID-2` leaves **arrival as the only route** to two records in one slot. A
collision is therefore always the reinstall case, where `DATA-CONV-4`'s warrant applies exactly: the two
records are the same record and the discarded content is identical to the kept content. It was asked
whether a twice-lived calendar date breaks the claim, by putting two genuinely different breakfasts in
one slot; it does not, because that case produces one record rather than two
([#744](https://github.com/jirigrill/eczema-helper/issues/744)).

### 4.2 The tiebreak, and why it has a deadline

**`DATA-CONV-1` (MUST)** — Every meal record carries a **tiebreak** value, minted once when the record
is created and never changed afterwards. It is unique across all devices without coordination between
them.

**`DATA-CONV-2` (MUST)** — When two or more meal records share a natural key, the winner is the one with
the **lowest tiebreak**. Every device applies that rule to the same set and reaches the same answer
without communicating.

The tiebreak is the single most deadlined field in this document, and it is worth being explicit about
why a value with no user-visible purpose ships in release one. Apple's deduplication blueprint picks a
winner by sorting on a stable device-independent attribute, and its stated reason for the choice is
exactly this: *"Because each UUID is globally unique and each peer picks the first tag, all peers
eventually reserve the same tag, which is the one that has the globally lowest UUID."* The framework's
own local object identifier cannot serve — it is documented as meaningful only within one device's
store. And because the schema is additive-only, a tiebreak not recorded in release one can be added as
a field later but will be **empty on every record already written**, which is precisely the population
that needs converging after a reinstall. It is unbackfillable in the way that matters.

### 4.3 Converging

**`DATA-CONV-3` (MUST)** — Convergence runs when records arrive from another device, and considers only
records that arrived rather than rescanning the store. It never modifies the winner's creation instant,
its natural key, or its tiebreak.

**`DATA-CONV-4` (MUST)** — Where two records for one slot differ in content, the **most recently
modified** wins — last-edit instant if present, creation instant otherwise — and the tiebreak breaks an
exact tie. The losing record's content is discarded.

**A same-device clock repeat does not reach the tiebreak (fact, measured).**
[#766](https://github.com/jirigrill/eczema-helper/issues/766) measured the one case that could have
defeated a tiebreak designed for two-device conflict: an autumn DST transition, where one device
reads the same wall clock twice with no travel and no zone change. Two records written in the two
passes through `02:30` are **one hour apart as instants**, so `DATA-CONV-4` is decided on the creation
instant and the tiebreak is never consulted. They also share the ordinary calendar date of that day —
a repeated *hour* is not a repeated *date* — so the repeat introduces no new natural-key collision
either. The tiebreak's deadline stands on the reinstall case above, unchanged by this.

**`DATA-CONV-5` (MUST NOT)** — The app never merges the contents of two colliding meals. A meal she
never ate must not be assembled from two she did.

**`DATA-CONV-6` (MUST NOT)** — The app never shows her a conflict, never asks her to choose, and never
tells her that a conflict occurred.

Rules 4 through 6 are one decision seen from three sides, and the cost belongs in the open: **the losing
edit is destroyed without notice, and with no export ([#683](https://github.com/jirigrill/eczema-helper/issues/683))
and no rollback it is unrecoverable.** That is tolerable only because of what the realistic collision
actually is. Two people editing one journal simultaneously is not this product's case; one phone,
reinstalled, receiving its own history back is. In that case the two records are the same record and
the discarded content is identical to the kept content. Field-level merging would trade an
unobservable loss in the common case for an invented meal in the rare one, and an invented meal is a
false entry in a health journal.

**`DATA-CONV-7` (MUST)** — A convergence loser is marked **superseded** rather than erased. A superseded
record is not shown anywhere and is not counted in anything she sees.

**`DATA-CONV-8` (MUST)** — Before erasing a superseded record, the app moves every relationship it holds
to the winner.

**`DATA-CONV-9` (MUST)** — A record is marked superseded **once**. A record already marked is never
re-marked, and its marking instant never moves.

**`DATA-SUPER-1` (MUST)** — The mark is a **stored field on every record type that can be superseded** —
an optional instant, absent on every record until it loses a convergence. Absent means "not superseded",
and it is the same field `DATA-CONV-9` forbids moving and `DATA-CONV-10` reads.

`DATA-SUPER-1` exists because the rules above describe the mark's behavior without ever saying it is a
field, and §3.1 and §5.1 do not list it — an omission found while settling
[#714](https://github.com/jirigrill/eczema-helper/issues/714), which had to give every field an encryption
state and so had to enumerate them all. It is stated separately rather than folded into those two lists
because it belongs to convergence rather than to either record's subject matter, and because it is
**deadlined and unbackfillable in the way `DATA-CONV-1` is**: a record written without it cannot be
converged safely later, and additive-only promotion means the field could be added but would be absent on
exactly the reinstall population §4 exists for.

**`DATA-CONV-10` (MUST)** — A superseded record is erased only after **both** an upload and a download
have completed successfully since it was marked, and then only if it was marked sufficiently long ago
that its relationships can be assumed settled.

**`DATA-CONV-11` (MUST)** — When the winner is deleted, its superseded records are erased with it.

The deferral in `DATA-CONV-10` is the part of this section most likely to be read as excessive caution
and deleted by someone tidying up. It is neither excessive nor caution: it is the fix for a documented
data-loss sequence. Apple's own sample spells out the failure in eight steps — a record arrives before
the photo it relates to, so at that moment its relationship is empty; a device converges and deletes
it; the deletion syncs back; and the relationship is lost on the device that *had* it. Their conclusion
is the sentence to keep in mind: *"gating the deletion […] by checking tagA.photos is empty doesn't
help"*, because with more devices involved the same race simply happens again. Marking rather than
deleting is what keeps the relationship reachable until it can be moved. `DATA-CONV-9` guards a
separate hazard from the same source — re-stamping the marking instant triggers an endless
synchronisation loop, since each restamp is itself a change to export.

### 4.4 What is not attempted

**`DATA-CONV-12` (MUST NOT)** — The app does not declare any field unique to the store, and does not
rely on the store to reject a duplicate.

This is not a limitation being worked around; it is a property of the architecture. The framework's own
documentation gives the reason — *"The framework synchronizes changes concurrently and at opportune
times, which means CloudKit is unable to enforce the `unique` property option"* — and the consequence is
structural rather than incidental: peers write independently, so no participant is ever in a position
to reject a colliding insert. Declaring a uniqueness constraint anyway does not degrade gracefully; the
store refuses to open at all (§7.2).

One further trap deserves naming, because the newest platform guidance walks straight into it. Recent
framework documentation promotes a uniqueness declaration as *the* way to avoid writing deduplication
code — *"this code doesn't need to de-duplicate any data — SwiftData does it for me!"* — without
mentioning that the declaration is inert once mirroring is switched on. An implementer following the
most recent guidance in good faith will delete everything in §4 and ship a schema that cannot load.

---
## 5. The skin observation and its photos

### 5.1 The observation record

**`DATA-SKIN-1` (MUST)** — A skin observation record holds: a **tiebreak** value, a **calendar-day
label**, a **creation instant**, the **nine regions with their levels**, and an optional **note**.

**`DATA-SKIN-2` (MUST)** — The creation instant is **write-once** and is never touched by an edit, a
delete, an undo, or a convergence pass. It is the moment she *looked*, not the moment the row was last
written.

**`DATA-SKIN-3` (MUST NOT)** — An observation has no last-edit instant. Nothing about an observation
records when it was amended.

**`DATA-SKIN-4` (MUST)** — The nine regions are stored as **one value on the observation**, not as nine
related records and not as nine separate fields. All nine are always present.

**`DATA-SKIN-5` (MUST)** — The canonical order of the nine regions is a property of the **app**, not of
the stored value. Reading derives order from each region's own identity, never from the position it
occupied in storage.

> **⚠ Divergence 5.** *PWA:* `regions` is an array in which a region may simply be absent, and absence
> is *"treated as klidné (0)"* by every reader. *iOS:* all nine are always stored explicitly; there is no
> absent case to interpret. *Why:*
> [INV-7](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-7) makes every save
> witness all nine regions, so an absent region was never a legitimate state — it was a shorter way to
> write the same thing, whose cost is that "she saw calm" and "the record is incomplete" become
> indistinguishable. Under sync that ambiguity acquires teeth: a partial arrival would read as *calm
> skin* rather than as an incomplete record. Class: **defect fixed**.

`DATA-SKIN-4` is the one place in this document where the platform's weakness argues *for*
denormalisation, and the argument is worth stating because it runs against the instinct a reader will
bring. Nine related records would arrive independently and in indeterminate order, so a device could
legitimately hold an observation with four regions present — and would render it, per Divergence 5, as
five calm regions. That is a **wrong severity reading of an infant's skin**, produced silently, with
nothing anywhere reporting an error. Folding the nine into one value makes it unrepresentable: they
travel with their parent or not at all.

**Verified against a real container** ([#747](https://github.com/jirigrill/eczema-helper/issues/747)), not
inferred: written from a physical device and read back as a raw server record, the nine regions arrive as
**one** field holding JSON bytes, with all nine members and their order intact. The decomposed
representation that would have defeated this rule does not occur, so `DATA-SKIN-4` stands as written and
§14.1's fallback is closed. The stored value is opaque to the server — it cannot be queried into, and the
same is true of a dictionary or an app-encoded blob, so `DATA-SKIN-5`'s app-side ordering is the only
ordering there is.

`DATA-SKIN-5` closes the other half. The platform has no notion of a stored order for a related
collection at all — there is no ordered-relationship facility to ask for — so an implementation that
reads regions positionally is relying on an accident. For nine fixed regions this costs nothing, since
the canonical order is a constant in the app rather than data: the rule exists to stop a future reader
inferring that because the stored form is ordered, the order is meaningful.

### 5.2 The photo record

**`DATA-PHOTO-1` (MUST)** — A skin photo is its **own record type**, related to exactly one observation.

**`DATA-PHOTO-2` (MUST)** — The image bytes live on a **separate record** from the photo's descriptive
fields. A photo is therefore two related records: one small and always present, one large.

**`DATA-PHOTO-3` (MUST)** — The descriptive record holds: a **tiebreak** value, the **region** the photo
is of, a **capture instant**, the **byte size** of the image, its **format**, and its **pixel
dimensions**.

**`DATA-PHOTO-4` (MUST)** — The capture instant is the moment the photograph was **taken**, not the
moment it was attached. For a photo chosen from the library it is the library's own capture metadata
where available.

**`DATA-PHOTO-5` (MUST)** — Byte size, format and dimensions describe the bytes **as stored**, are
written at the same moment as the bytes, and are never recomputed afterwards.

> **⚠ Divergence 6.** *PWA:* a photo is one row, `{ id, observationId, region, capturedAt, blob }` — the
> bytes sit beside the metadata, and nothing records the image's size, format or dimensions. *iOS:* the
> bytes are separated onto their own record, and three descriptive fields are added. *Why:* the
> separation is transport, and the three fields are a permanent gap being closed while it still can be —
> see the two paragraphs below. Class: **forced by platform** (separation) and **settled by #730**
> (fields).

**The separation is not about asset promotion, and the reason it was originally proposed was wrong.**
The platform maps a large value to an external asset **automatically, by size at the moment of
serialization** — above roughly 750 KB for one value, or whenever the whole record exceeds 1 MB — and
that behavior is not something a schema opts into. That threshold carries a consequence beyond storage
layout: crossing it also **silently voids a field's encryption declaration** (`DATA-LOCK-4`, §10.2), which
is why the figure matters to confidentiality and not only to field budgeting. Two live reasons survive. First, a record type is
limited to 256 fields, and the platform generates a *second* field for every variable-length attribute
to hold its asset counterpart, so binary fields cost double against that limit; keeping them on a record
of their own keeps the observation's record shape unaffected by them. Second, and more practically for
this product, it decouples the pixel target from the record shape: the compression target is a constant
a later release may freely change, while the record shape is permanent, and putting them on the same
record would couple a revisable decision to an irrevocable one. [#684](https://github.com/jirigrill/eczema-helper/issues/684)
deferred the pipeline precisely so those constants could be measured on a device later — that deferral
is only safe if the shape does not depend on them.

**Why three metadata fields exist for a feature the app does not have.** She has no export
([#683](https://github.com/jirigrill/eczema-helper/issues/683)), the photos consume **her own** iCloud
allowance ([#679](https://github.com/jirigrill/eczema-helper/issues/679)), and quota exhaustion is
undetectable through the mirroring interface — `SET-SYNC-8` forbids branching on any specific error
condition for exactly that reason. Being able to tell her how much space her photos occupy is close to
the only lever left, and it must be answerable without decoding thousands of images on a launch path.
Recording the size at write time is exact and free; deriving it later is neither. `DATA-PHOTO-5` makes
these fields describe the stored bytes rather than the original, so they cannot drift from their
subject — which is the standing objection to storing derivable data, and it is answered by scoping
rather than dismissed.

### 5.3 Deletion

**`DATA-PHOTO-6` (MUST)** — Deleting an observation deletes its photos. The delete rule is declared on
the relationship rather than performed by application code.

**`DATA-PHOTO-7` (MUST)** — Deleting the descriptive photo record deletes its bytes record.

**`DATA-PHOTO-8` (MUST NOT)** — No delete anywhere in the schema is refused because another record
refers to the record being deleted.

> **⚠ Divergence 7.** *PWA:* the cascade is hand-written — the repository scans an index and deletes the
> matching rows itself, and referential integrity is a hand-rolled throw. *iOS:* the cascade is declared
> on the relationship. *Why:* it is available, and a declared rule cannot be forgotten at one of several
> call sites the way a manual scan can. This corrects a claim this map carried for some time: the
> platform prohibits only the *refusing* delete rule, and cascade is used on three relationships in the
> platform vendor's own mirrored sample. What is unavailable is not the cascade but the **transaction
> around it** — see `DATA-ARRIVE-3`. [#764](https://github.com/jirigrill/eczema-helper/issues/764) has since
> measured the prohibition directly and narrowed it: the refusing rule is rejected local-only too, so it is
> not a mirroring restriction and the cascade's availability does not depend on mirroring either.
> Class: **defect fixed**.

`DATA-PHOTO-8` is the prohibition to keep. The refusing delete rule is the one the platform names as
unsupported, and the failure it produces is not a refused delete — it is a store that will not open
(§7.2).

This is now measured rather than inferred, and the measurement moves the *reason* without moving the rule
(`(fact, measured)` — [#764](https://github.com/jirigrill/eczema-helper/issues/764), physical device, real
container, live iCloud account). A refusing delete rule on a to-many is rejected at store-open **whether or
not mirroring is enabled**: the same model, attempted local-only with no CloudKit database configured, fails
identically, with `NSLocalizedFailureReason` naming only *"The following relationships are configured with
unsupported delete rules"*. So it is a persistence-framework prohibition, not a mirroring one, and
`DATA-PHOTO-8` cannot be relaxed by unmirroring a relationship — a remedy that would otherwise look
available. #764 went looking for the pattern §10.3 records for field encryption, where mirroring silently
voids a declaration past a threshold; here there is nothing to void, because the model never loads. The
failure is loud, total, and at launch, so **no orphan can be created through a refused delete** — the
`DATA-ORPHAN-*` sweep owes nothing to this case.

Two consequences worth stating for whoever implements §5.3. First, referential integrity of the form
"refuse to delete a parent while children exist" is **not expressible in the schema at all** and must be
application code if it is ever wanted — `DATA-PHOTO-8` says it is not. Second, the thrown Swift error is as
opaque as `DATA-ARRIVE-10`'s note warns, but the `NSCocoaErrorDomain` 134060 error beneath it carries a
precise reason naming the offending entity and relationship: diagnosable in the Core Data log, not from the
caught error.

---
## 6. Orphans

An orphan is a photo whose parent observation is not in the store. §5.3's declared cascade does not
prevent one, because a cascade is applied where it is issued and its individual deletions then travel
separately.

**`DATA-ORPHAN-1` (MUST)** — An orphan photo is **invisible**. Every read path reaches photos through
their observation, so a photo with no parent appears nowhere and cannot be reached by any screen.

**`DATA-ORPHAN-2` (MUST)** — The app treats "the parent has not arrived yet" and "the parent was deleted
elsewhere" as **indistinguishable**, because they are.

**`DATA-ORPHAN-3` (MUST)** — Orphan cleanup is an **idempotent, order-independent sweep**, safe to run on
every launch and safe to interrupt at any point.

**`DATA-ORPHAN-4` (MUST)** — The sweep deletes an orphan only once its parent has been missing for a
**sustained period measured in wall-clock time** since the photo itself arrived. It never deletes an
orphan on first sight.

**`DATA-ORPHAN-5` (MUST NOT)** — The sweep never uses a count of sync events, or any number of completed
imports, as evidence that a parent will not arrive.

**`DATA-ORPHAN-6` (MUST)** — The sweep is silent. Nothing about it is shown to her, and an orphan's
existence is never surfaced.

The sweep can afford to be slow and conservative, and it is worth being clear why, because a reader who
thinks the sweep protects correctness will be tempted to make it eager. It does not: `DATA-ORPHAN-1`
already makes an orphan invisible, and the reference implementation's read path is a join rather than a
scan, so an orphan photo has *never* been renderable in either product. The sweep exists solely to
reclaim **her** storage allowance. Deleting a photo whose parent is merely late destroys a photograph of
her child's skin to save bytes; waiting costs the bytes for another day. The asymmetry is total, and it
sets the direction of every judgement call here.

`DATA-ORPHAN-5` names the mistake that will otherwise be made. The obvious way to decide a parent is
never coming is to wait for the initial import to finish — and there is no such thing to wait for. No
interface reports that synchronisation is complete, one logical import may emit any number of events
([#726](https://github.com/jirigrill/eczema-helper/pull/726)), and `SET-SYNC-1` already forbids the app
claiming a synchronised state anywhere. A sweep gated on event counts would delete photos on a device
that happened to be quiet.

---
## 7. Arrival

Everything in this section is a property of the platform rather than a decision, and each rule exists
because the reference implementation was entitled to assume the opposite.

**`DATA-ARRIVE-1` (MUST)** — Records arrive in **indeterminate order**. A parent may arrive before its
children, after them, or between them.

**`DATA-ARRIVE-2` (MUST)** — Every arrival state that ordering permits is a **legitimate transient
state**, and the app renders it without error. An observation whose photos have not arrived is an
observation with no photos yet, never a failure.

**`DATA-ARRIVE-3` (MUST)** — A single local save is **atomic on the device that makes it**. Atomic
*arrival* on another device does not exist, and no rule may assume it.

**`DATA-ARRIVE-4` (MUST)** — Every relationship in the schema is **optional**, in both directions, and
every relationship has an inverse.

**`DATA-ARRIVE-5` (MUST NOT)** — No rule, read path, or launch decision branches on the store being
**empty**. Emptiness is never evidence of anything.

**`DATA-ARRIVE-6` (MUST NOT)** — Nothing in the app waits for synchronisation to finish, or acts on a
belief that it has.

> **⚠ Divergence 8.** *PWA:* an observation and its photos are written in one multi-table transaction,
> so no reader can ever see one without the other. *iOS:* the local write stays atomic; cross-device
> atomic arrival is **lost**, and §6's sweep replaces the guarantee. *Why:* not a choice — the platform
> states that relationship changes may not be saved atomically and are processed in indeterminate order
> ([#679](https://github.com/jirigrill/eczema-helper/issues/679),
> [#691](https://github.com/jirigrill/eczema-helper/issues/691)). This is the one place
> [INV-6](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-6) genuinely weakens, and
> `docs/spec/skin-observation.md` §5.2 records it from the screen's side. Class: **forced by platform**.

`DATA-ARRIVE-5` is the rule most likely to be violated by accident, because the pattern it forbids is
the ordinary way to write a first launch: read, find nothing, seed. Under mirroring the read completes
before the import does, so an empty store means *"nothing has arrived yet"* far more often than it means
*"this is a new installation"* — a framework engineer for the platform calls the read-then-branch
pattern a fallacy for precisely this reason. This spec's dependents already comply:
[#712](https://github.com/jirigrill/eczema-helper/issues/712) decided first run is not detected from the
store, and §8.1 keeps the feeding stage out of it.

`DATA-ARRIVE-4` looks like a technicality and carries a real loss worth recording: because every
relationship must be optional, any minimum-cardinality expectation is unenforceable by the store. "An
observation has at least one region" cannot be a stored constraint — which is a second, independent
reason for `DATA-SKIN-4`.

### 7.1 Pending work

**`DATA-ARRIVE-7` (MUST)** — A record that has been saved but not yet uploaded is **fully recorded**. It
survives termination, relaunch, and an indefinite period offline.

**`DATA-ARRIVE-8` (MUST NOT)** — No failure to upload is ever reported to her as a failure to record.

These restate, from the store's side, what `SET-SYNC-9` states from the screen's: *"A failed upload never
means a lost record."* They are here because this is where the property actually lives — the local save
is durable independently of the upload, and the upload is retried from a log the store keeps.

### 7.2 The schema must load

**`DATA-ARRIVE-9` (MUST)** — The schema contains no feature the store rejects at load: no uniqueness
constraint, no refusing delete rule, no required relationship, and no attribute that is neither optional
nor defaulted.

One of those four is **not** a mirroring restriction, which matters only because it forecloses a remedy.
[#764](https://github.com/jirigrill/eczema-helper/issues/764) measured the refusing delete rule as rejected
**local-only as well**, with no CloudKit database configured, so it cannot be escaped by unmirroring the
type that carries it. Required *relationships*, by contrast, are genuinely mirroring-specific — the same
probe recorded a non-optional to-many failing with *"CloudKit integration requires that all relationships
be optional"*, a reason that names mirroring explicitly and that `DATA-ARRIVE-4` already covers. The
optional-or-defaulted **attribute** rule was not probed either way and remains as 13.3 describes it: every
model in #764's probe carried defaulted attributes throughout, so nothing there tests it.

**`DATA-ARRIVE-10` (MUST)** — A test loads the **real schema with mirroring enabled** and fails if it
does not open. It runs on every change to the schema.

The test in `DATA-ARRIVE-10` is unusually valuable relative to its cost, and both halves of that are
worth stating. The cost is nil: validation happens before any network contact, so the test needs no
account, no container and no connection. The value is that the failure it catches is **total and
undiagnosable** — [#713](https://github.com/jirigrill/eczema-helper/issues/713) measured five distinct
schema violations and found that all five surface as the same opaque error with no useful detail, at
launch, with no partial degradation. Without this test, the first sign of a bad schema is an app that
does not start, and nothing indicating why.

One caution for whoever writes that test, and the reason `DATA-ARRIVE-9` lists the optional-or-defaulted
requirement last. The first three items are documented by the platform vendor. The fourth is **observed
behavior only** — [#713](https://github.com/jirigrill/eczema-helper/issues/713) measured it directly, and
it is real, but no primary source states it, and the vendor's own documentation names only *required
relationships*, never required attributes. It is stated here as a rule because the measurement is
trustworthy and the consequence of getting it wrong is a store that will not open; it must not be
attributed to documentation. §14.3 records this as an open question against the source.

---
## 8. What lives outside the store

Three values the mother's use creates are deliberately not records. Each is out for the same structural
reason — **duplication of a singleton is invisible** — and each pays a stated price.

### 8.1 The feeding stage

**`DATA-OUT-1` (MUST)** — The feeding stage is **not** a record in the store. It is a single
key-and-value in the platform's ubiquitous key-value store, synchronised separately.

**`DATA-OUT-2` (MUST)** — Writing the stage twice is a **last-writer-wins overwrite**. Two values for
the stage cannot exist.

Settled by [#691](https://github.com/jirigrill/eczema-helper/issues/691), and the reasoning is the
template for the two below it. In the reference implementation the settings row worked because its
primary key was the literal constant `singleton`; under mirroring the app does not choose record names,
so two writes become two records rather than one overwrite. A duplicate meal is visible on the day view
and self-correcting; a duplicate settings row is **invisible**, and the feeding stage gates which actors
may be logged at all
([INV-14](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-14)) — so a silently wrong
read changes whether the baby is a loggable actor. A key is a key, which makes the wrong state
unrepresentable rather than merely swept.

**Two costs, accepted knowingly.** The key-value store is documented as unencrypted on disk, so the
feeding stage sits outside §10.3's encryption — by construction, not by choice, and the exclusion is now
sharper than it was: §10.3 encrypts every attribute it can reach, so this is one of exactly two values the
mother creates that are not encrypted at all. And it is a *second* synchronisation mechanism with its own
availability behavior, so `SET-STAGE-*` must state what the stage does in each degraded account state,
since it no longer travels with the records it governs.

### 8.2 The consent record

**`DATA-OUT-3` (MUST)** — The consent record is **not** a record in the store. It is a key-and-value
beside the feeding stage.

**`DATA-OUT-4` (MUST)** — It holds the instant she consented and the **revision identifier of the notice
she was actually shown** (`SET-PRIVACY-6`), and both are write-once per revision.

Same structure, same reason: there is exactly one consent record forever, and a duplicate would be
invisible. The privacy cost is materially smaller than the feeding stage's, which is why the concession
is easier here — a consent record contains no health data at all. It records that she consented, when,
and to which text. The requirement it satisfies is evidentiary rather than medical: the regulator's
guidance requires that *"the information provided to the data subject at the time shall be
demonstrable"*, and an identifier plus text compiled into the binary is the cheapest thing that
satisfies it.

> **⚠ Divergence 9.** *PWA:* no consent record exists, because there is no notice and no consent.
> *iOS:* consent is recorded durably, outside the store, naming the exact revision shown. *Why:* new
> behavior with no reference counterpart, required by
> [#709](https://github.com/jirigrill/eczema-helper/issues/709) and shaped here only as to *where* it
> lives. Class: **settled by #709**.

### 8.3 The diagnostic log

**`DATA-OUT-5` (MUST)** — The diagnostic log (`SET-SYNC-10`) is **not** a record in the store, and is
never synchronised. It is a local file.

**`DATA-OUT-6` (MUST)** — It is device-local by nature: it describes failures on *this* phone, and is
never merged with, compared against, or reconciled with any other device's.

Three reasons, and the second is decisive. It would consume her storage allowance to store a log of her
storage allowance failing. A log of "synchronisation is broken" that requires synchronisation to be
written cannot be written when it is most needed. And keeping it out of the schema keeps it off the
additive-only deadline entirely — its shape stays freely revisable, which matters for the one artifact
whose whole purpose is to capture detail nobody has seen yet.

### 8.4 What this leaves in the store

**`DATA-OUT-7` (MUST)** — Everything else the mother's use creates is a record in the store. There is no
fourth location.

Worth a rule because three exceptions is where a pattern starts. The test that keeps the list at three:
each is a **singleton whose duplication would be invisible**, or a **device-local artifact that cannot
depend on sync**. Meals and observations are neither — they are many, they are hers, they must survive a
reinstall, and a duplicate of one is visible on a screen.

---
## 9. Persistent history

The store keeps a log of its own changes. The app reads it to find arrivals (§4.3) and the sync layer
reads it to know what still needs uploading.

**`DATA-HIST-1` (MUST)** — Arrivals are identified by reading the change log when the store reports
remote changes, filtered to changes this device did not itself make.

**`DATA-HIST-2` (MUST NOT)** — The app does not purge the change log in release one.

**`DATA-HIST-3` (MUST)** — If the app ever purges the log, it purges only entries older than the **last
successful upload**, with a margin measured in months, and never on a schedule tied to launches.

`DATA-HIST-2` is the rule this section changes its own mind about, and the reasoning belongs in the open
because `SET-SYNC-12` was written on the other assumption. That rule requires the last-successful-upload
time to be recorded, and correctly identifies purging as this section's to specify. Having specified it:
**the app should not purge.** The platform's guidance recommends purging only for large data sets, puts
the safe margin at *"several months"*, and expects the operation *"several times a year"* — while the
same guidance warns that purging what the sync layer still needs *"invalidates some internal state, and
triggers a `reset` operation that synchronizes the store with the CloudKit server truth"*, which for
this app means re-downloading every photo the mother owns over her own connection. Against a journal of
a few thousand rows a year, the disk saved does not pay for that risk. The recorded timestamp stays
required — it costs nothing, it cannot be backfilled meaningfully, and it is what makes `DATA-HIST-3`
implementable if the calculus ever changes.

> **⚠ Divergence 10.** *PWA:* not applicable — there is no change log and nothing to purge. *iOS:* the
> log accumulates and is not pruned in release one. *Why:* the risk of purging early is a full re-sync
> of every photo; the cost of not purging is disk this data volume does not threaten. Class: **settled
> by #730**.

One trap for whoever revisits this. The general, non-mirrored guidance for the same log ships an example
that purges everything older than **seven days**. That figure must not be carried into a mirrored store —
it comes from a page written for stores that do not sync, and the mirrored guidance says months. Copying
it would produce exactly the full-reset failure above, on a schedule.

---
## 10. Absences, and the promotion deadline

### 10.1 Fields that deliberately do not exist

**`DATA-ABSENT-1` (MUST NOT)** — No record holds a suspected cause, a trigger, a correlation, a score, or
any other value connecting a food to a skin change.

**`DATA-ABSENT-2` (MUST NOT)** — No derived value is stored. Day-overall severity in particular is stored
nowhere ([#727](https://github.com/jirigrill/eczema-helper/issues/727) retired the concept outright).

**`DATA-ABSENT-3` (MUST NOT)** — No record holds a display string in any language.

**`DATA-ABSENT-4` (MUST NOT)** — No record holds a marker meaning "suspect", "unresolvable", "needs
attention" or similar. [#703](https://github.com/jirigrill/eczema-helper/issues/703) settled this
explicitly: an unresolvable food id is a display problem, and nothing marks the record.

**`DATA-ABSENT-5` (MUST NOT)** — No record holds a schema version number, a device identifier, or an app
version.

> **⚠ Divergence 11.** *PWA:* not applicable — a single-device store with no synchronised schema has
> nothing to version, so the absence is incidental rather than chosen. *iOS:* the absence is deliberate
> and permanent: no version attribute is added, declining the platform vendor's documented advice to
> include one from the outset. *Why:* the advice is sound in general but its mechanism is to hide records
> an older app cannot read, and hiding a mother's own records from her, silently, is a worse failure than
> the display degradation [#703](https://github.com/jirigrill/eczema-helper/issues/703) already accepted.
> Because the advice must be taken before promotion or not at all, declining it is itself a deadlined
> decision (§10.4).

These are numbered rather than left as omissions because each is a field a well-meaning implementer would
add. The first is
[INV-5](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-5) and it is the app's
regulatory boundary: a stored `suspectedCause` field would be an app that *finds* causes rather than one
that records observations, which is the distinction the whole product rests on. The third is
[INV-12](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-12), and Divergence 3 already
removed the one instance of it.

`DATA-ABSENT-5` carries a cost worth stating plainly rather than leaving inside the divergence above: it is
one-way. If a future record type ever genuinely cannot be read by an older app, there will be no mechanism
to hide it, and no way to add one after promotion. That is recorded as accepted, not overlooked.

### 10.2 What promotion freezes

**`DATA-LOCK-1` (MUST)** — Before release, the schema is promoted to production, and from that moment no
record type or field may be renamed, retyped, deleted, or have its encryption changed. Only additions are
possible.

**`DATA-LOCK-2` (MUST)** — Every field's encryption state is decided **before** promotion. Encryption is
a one-time, bidirectional lock: an unencrypted field can never become encrypted, and an encrypted field
can never become unencrypted.

**`DATA-LOCK-3` (MUST NOT)** — A local change to the schema is never taken as evidence that the
synchronised schema accepts it.

`DATA-LOCK-2` is stated as its own rule because the vendor's framing makes the consequence easy to
misjudge: encryption is not a special case with its own rules, it is a **field type**, and field types are
immutable in production. That is why the lock runs in both directions. Which fields are encrypted is
settled in §10.3 ([#714](https://github.com/jirigrill/eczema-helper/issues/714)).

**`DATA-LOCK-5` (MUST)** — The immutability in `DATA-LOCK-1` and `DATA-LOCK-2` is a property of the
**synchronised schema**, not of the API that declared it. No implementation relies on a documented
statement that the declaration used here carries those rules, because none exists.

`DATA-LOCK-5` records a gap rather than a hazard, and it exists so nobody cites documentation that is not
there — the same discipline §14.3 applies. The vendor documents the encryption restrictions on the
*previous* framework's attribute description, in an SDK header:

> Attributes to be encrypted must be new additions to the CloudKit schema. Attributes that already exist
> in the production schema cannot be changed to support encryption.
>
> Attributes cannot (ever) change their encryption state in the CloudKit schema. Once something is
> encrypted (or not) it will forever be so.

— `NSAttributeDescription.h` lines 64–65, iOS 27.0 SDK. **This passage has no web URL**: the rendered
documentation page drops the surrounding note entirely, so the header path and SDK version are the
citation.

Nothing ties those sentences to the framework this app uses: its encryption option has no discussion page
and no doc comment in the shipped module interface. The rules nevertheless bind, for two reasons that do
not depend on documentation. The quoted restriction is scoped to *the CloudKit schema*, which the server
owns and enforces whichever layer declared the field. And the option was **measured** producing a real
encrypted server field through this framework
([#748](https://github.com/jirigrill/eczema-helper/issues/748)), on the same records that measured
`DATA-LOCK-4`. So this is settled by construction plus measurement, and an implementer should know that is
what it rests on.

**`DATA-LOCK-4` (MUST NOT)** — A field declared encrypted is never relied on to be encrypted once its
value can exceed the asset-promotion threshold. Field encryption and automatic asset promotion do not
compose: past the threshold the declaration is silently ignored.

This was the one unclosed risk in the pairing above, and it is now **measured and closed adversely**
([#748](https://github.com/jirigrill/eczema-helper/issues/748)). One model with a single field declared
`@Attribute(.allowsCloudEncryption)`, two rows straddling §5.2's ~750 KB single-value threshold, written
to a real private container from a physical device; the raw `CKRecord` was read back from the server.
Bytes were incompressible random data, so the serializer could not shrink the large row under the
threshold and produce a false reassurance.

| | Below the threshold (200 KB) | Above it (3 MB) |
| --- | --- | --- |
| Field name on the server | `CD_bytes` | **`CD_bytes_ckAsset`** |
| Plain value | absent | `CKAsset` |
| Fields in `encryptedValues` | **1** — the value | **0** |

Same model, same declaration, same run: the only difference is size. On promotion to an asset the field
is **renamed** and the encryption request is **dropped with no error and no warning**. So the feared
behaviour — a photo encrypted while small and unencrypted once it grows — is what the platform actually
does, and for photographs it means confidentiality varies with image size and therefore with image
content: a detailed photograph of an affected area is *more* likely to cross the threshold than a plain
one, so the values most worth protecting are the ones that lose protection.

Two consequences for the deadline itself. `DATA-LOCK-2` makes this uncorrectable after promotion, and
there is **no deliberate promotion step to act just before**: SwiftData exposes no equivalent of Core
Data's `initializeCloudKitSchema`, so the development schema is created as a side effect of the **first
write**. `DATA-LOCK-3`'s trap and this one share that timing.

**The remedy is settled in §10.3** (`DATA-ENC-5`): the bytes are encrypted by the app before they are
stored, so the asset carries ciphertext and the platform's field encryption is irrelevant to them. The two
alternatives — keeping the bytes under the threshold by construction, or out of mirrored attributes
altogether — are recorded there as rejected, with the reason.

`DATA-LOCK-3` names a specific trap: the local store and the synchronised schema migrate by different
mechanisms, and a local migration succeeding says nothing about the other accepting it. The observable
failure is an app that works in development and fails only in a distributed build, reporting that a field
cannot be created in the production schema.

### 10.3 Which fields are encrypted

Settled by [#714](https://github.com/jirigrill/eczema-helper/issues/714), owner-confirmed, against the
schema this document defines rather than against an earlier field list. Every rule here is deadlined by
`DATA-LOCK-2`.

**`DATA-ENC-1` (MUST)** — **Every attribute the platform is capable of encrypting is declared encrypted.**
There is no field-by-field judgement, and no attribute is exempted on the grounds that its value is
unremarkable.

**`DATA-ENC-2` (MUST)** — This includes the calendar-day labels, the creation and last-edit instants, the
capture instant, the tiebreak, the supersession marking instant, and the photo's byte size, format and
dimensions — every field whose value would, read alone, look banal.

**`DATA-ENC-3` (MUST NOT)** — No rule anywhere depends on a mirrored attribute being server-readable. In
particular, no read path, convergence step or sweep may be implemented as a server-side query.

**This rule is a platform constraint, not a self-imposed discipline, and the distinction matters to
anyone tempted to negotiate it.** `CKQuery` is **unusable** against the mirrored schema: the #747 probe
measured `CKError 12/2015` from a real container, with `recordName` not queryable, and reading mirrored
records requires `CKFetchRecordZoneChangesOperation` instead
([#747](https://github.com/jirigrill/eczema-helper/issues/747)). So a rule written as a server-side query
would not merely violate policy — it would not run. Two consequences follow. A server-side query cannot
be introduced later as an optimisation, and the fact that this app "never issues" one is not a choice it
could reverse.

**Verified against the whole corpus** ([#761](https://github.com/jirigrill/eczema-helper/issues/761)), by
review rather than by test, as §12 anticipates. All seven sections plus `DECISIONS.md` and `GLOSSARY.md`
were swept — ~658 rules, counting `meal-editor.md` in the draft state it was in at the time — and **no
rule depends on a mirrored attribute being server-readable**;
`CKQuery` does not occur anywhere in the corpus. The four constructs most likely to have assumed
otherwise, all written before #747, were each confirmed local: §6's orphan sweep tests whether a parent
is *in the store* over a wall-clock grace period (`DATA-ORPHAN-1`, `-4`); convergence considers only the
records that *arrived* rather than rescanning (`DATA-CONV-3`, `-4`); settings' `SET-SYNC-*` reason from
*emitted mirroring events* and locally recorded timestamps, never from a server read
(`SET-SYNC-2`, `-10`, `-12`); and `SKIN-ENTRY-2`'s "invisible to every date query" describes the PWA's
local predicate in a divergence note. The one construct that does read the server —
`SET-DELETE-7`/`-14`'s zone enumeration for deletion — reads **zone metadata, not attributes**, which
`DATA-ENC-6` keeps permanently plaintext, so it is consistent with this rule rather than an exception to
it. The negative result is the finding: `DATA-ENC-3`'s "no rule anywhere" is now checked rather than
asserted, which matters because §10.3 argues *from* it and
[#714](https://github.com/jirigrill/eczema-helper/issues/714) made that decision permanent.

**`DATA-ENC-4` (MUST NOT)** — The app never represents its storage to the mother as encrypted without
qualification, and never as end-to-end encrypted.

**`DATA-ENC-5` (MUST)** — Photo bytes are encrypted **by the app, before they are stored**. Their
confidentiality never depends on the platform's field-encryption declaration.

**`DATA-ENC-6` (MUST)** — Record names, zone names, relationship fields, and the server's own creation and
modification timestamps are **permanently plaintext**. Every rule in this document is written so that
nothing sensitive is inferable from them alone.

**Why a blanket rule and not a field list.** The earlier analysis
([#693](https://github.com/jirigrill/eczema-helper/issues/693)) sorted the fields into clinical content,
banal-but-correlated values, and an arguable timestamp row. Deciding them individually was rejected, for
three reasons. Encrypting costs this product **nothing measurable**: all three of the reference
implementation's query shapes are local, and the vendor states the flag "does not affect the data in the
persistent store", so local predicates, sorting, indexing and relationship traversal are untouched — the
usual argument against encrypting is scoped to server-side queries this app never issues — and, per
`DATA-ENC-3`, could not issue if it wanted to. The banal fields
are not banal *here*: the record type names are permanently plaintext (`DATA-ENC-6`) and they say what this
store is, so a plaintext meal type on a record whose type name is an eczema diary is a correlation, not a
neutral value. And a blanket rule is **one decision instead of eleven**, each of which would otherwise be
re-argued whenever a field is added — under a deadline where getting it wrong is permanent.

**The timestamp row, decided the same way.** #693 left the calendar day and the instants explicitly to the
owner, because the server's own `creationDate` leaks the timeline whatever the app does. That is true, and
it is an argument that encrypting these fields *gains little* — not that it costs anything. The counter-case
was recoverability: a keychain reset makes encrypted values permanently unrecoverable, where plaintext ones
would survive. What would survive is dates and meal types with no severities, no notes and no foods, which
is worthless as a recovery artifact; and with no export ([#683](https://github.com/jirigrill/eczema-helper/issues/683))
the phone is the only real recovery source regardless. The asymmetry decides it: leaving a value plaintext
is permanent, and so is encrypting it, but only one of them can be wrong in a way that matters.

**The tiebreak is encrypted, and this corrects a plausible misreading.** It looks like a field that must
stay readable, because convergence sorts on it. It need not: `DATA-CONV-3` converges over the records that
*arrived*, on-device, and `DATA-ENC-3` forbids doing it any other way. Nothing in this schema stays
plaintext by choice — only the four things `DATA-ENC-6` names, which stay plaintext by force.

**Why the photo bytes are app-encrypted rather than kept small.** `DATA-LOCK-4` measured the platform
silently dropping the encryption declaration once a value is promoted to an asset, which is exactly the
case photographs reach. Of the three available remedies, keeping the bytes under the threshold by
construction was rejected because it makes confidentiality depend on the compression constants
[#684](https://github.com/jirigrill/eczema-helper/issues/684) deliberately deferred to on-device
measurement — coupling a revisable decision to an irrevocable one, which is the precise thing §5.2 shaped
the record split to avoid. Keeping them out of mirrored attributes was rejected because
[#705](https://github.com/jirigrill/eczema-helper/issues/705) makes sync mandatory with no opt-out, so
photographs that do not sync are photographs that do not survive a reinstall. App-encryption is the only
remedy that holds regardless of image size.

**Its cost, accepted knowingly.** App-encryption means the app holds a key, and the only defensible home
for one is the keychain — which makes keychain loss a **total loss of photographs**, adding a fourth
silent-loss path to the three already accepted (#683, #687, and the keychain-reset path #693 identified).
The alternative was confidentiality that varies with image size, in the direction where the more detailed
photograph of an affected area is the one that loses protection. The key's own lifecycle — where it lives,
its accessibility class, whether it syncs, and what she sees when it is gone — is settled in **§11.2**
([#763](https://github.com/jirigrill/eczema-helper/issues/763)), which is not under this section's deadline
but has a deadline of its own: the first photo write, because a re-key must decrypt what the lost key
protected. Note that §11.2 **narrows** the loss recorded here rather than removing it: the key syncs, so a
new phone recovers it, and what remains is the case where the mother has iCloud Keychain switched off — a
setting the app can neither require nor detect.

**What this does not cover.** Two things sit outside these rules by construction, not by choice. The
feeding stage and the consent record live in the ubiquitous key-value store (§8.1, §8.2), which is
documented as unencrypted on disk, so `DATA-ENC-1` does not reach them; §8 states that price where it is
paid. And the on-device store file is untouched by any rule here — the vendor's own note directs local
protection to a separate mechanism, which is
[#752](https://github.com/jirigrill/eczema-helper/issues/752)'s and is deliberately not decided here
because, unlike everything else in this section, it is **not deadlined**: a file's protection class is
changeable in any release.

`DATA-ENC-4` is a drafting constraint with a regulatory edge, and `settings.md` §5 and `consent.md`
already carry it: field encryption protects **values, never structure**, and it is not end-to-end without a
platform feature the app can neither require nor detect (#693). "Your data is encrypted" would overclaim
on both counts.

### 10.4 The deadlined decisions, in one place

Every rule in this document that cannot be revised after promotion. This table is the reason the section
exists, and it is what a reviewer should check before release one ships.

| Deadlined | Rule | If it is wrong |
| --- | --- | --- |
| The tiebreak on every record type | `DATA-CONV-1` | Convergence is impossible for records written before the fix — which is the reinstall population that needs it |
| Meal item embedded, not related | `DATA-ITEM-1` | Every existing meal must be rewritten |
| Item `id` and `name` absent | `DATA-ITEM-2` | Adding them back is legal but they are empty on every existing record |
| Nine regions as one value | `DATA-SKIN-4` | Every existing observation must be rewritten |
| Photo bytes on their own record | `DATA-PHOTO-2` | Every existing photo must be migrated |
| Photo size, format, dimensions | `DATA-PHOTO-3` | Unbackfillable — the values can be recomputed from bytes, but only by decoding every image |
| Calendar day as a label, not an instant | `DATA-MEAL-3` | Retyping is prohibited; a new field plus a rewrite of every meal |
| Last-edit instant absent-when-unedited | `DATA-MEAL-5` | The distinction is unrecoverable once lost |
| Every relationship optional | `DATA-ARRIVE-4` | The store will not open |
| Each field's encryption state | `DATA-LOCK-2`, `DATA-ENC-1` | Permanent, in both directions |
| Photo bytes encrypted by the app | `DATA-ENC-5` | Every existing photo is plaintext on the server and must be rewritten to fix it |
| The supersession marking instant | `DATA-CONV-7`, `DATA-SUPER-1` | Convergence cannot defer erasure for records already written — the documented data-loss sequence returns |
| No version attribute | `DATA-ABSENT-5` | The strategy becomes unavailable forever |

The three fields on the photo record are the clearest case of a deadline that looks like a nicety.
Nothing in release one displays them; they exist because the alternative to recording a photo's size at
the moment it is written is decoding every photo the mother owns, and because there will be no second
chance to record it cheaply.

**One deadline sits outside this table, and a reviewer should check it in the same pass.** The photo key
(§11.2, `DATA-KEY-1`..`-5`) is not frozen by schema promotion — no keychain attribute is — but it is frozen
by the **first photo write**, because changing the key means decrypting what the old one protected. It is
excluded from the table above because the table's subject is promotion; it is named here so that a reviewer
working from the table does not conclude the key can be revisited after release one. Same deadline as
[#762](https://github.com/jirigrill/eczema-helper/issues/762)'s encode targets.

---
## 11. What sits on the phone

Everything in §10 is frozen at production schema promotion. **Nothing in this section is frozen by
*that*.** A file's protection class is an attribute of a file, changeable in any release, which is why
[#752](https://github.com/jirigrill/eczema-helper/issues/752) was split out of
[#714](https://github.com/jirigrill/eczema-helper/issues/714) rather than settled under its deadline.
§10.3 governs what the *server* stores; this section governs what sits on the phone — the store file
(§11.1) and the photo key (§11.2). **§11.2 carries a deadline of its own**, though not the schema's: a
keychain item is rewritable in any release, but the key's *value* cannot be changed once photographs have
been encrypted with it, so the first photo write closes it. §11.1 has no deadline at all.

The two are independent, and the SDK says so in as many words — `NSAttributeDescription.h` line 67,
iOS 27.0 SDK, a passage the rendered documentation page drops entirely:

> Note: This property does not affect the data in the persistent store. Local file encryption should
> continue to be managed by using `NSFileProtection` and other standard platform security mechanisms.

### 11.1 The store file

**`DATA-FILE-1` (MUST)** — The app sets **no** protection class on the store file. It relies on the
inherited default, which is `NSFileProtectionCompleteUntilFirstUserAuthentication`.

**`DATA-FILE-2` (fact, measured)** — The store file and **both** its SQLite sidecars — `-wal` and `-shm` —
each carry `NSFileProtectionCompleteUntilFirstUserAuthentication`. The sidecars are stated separately
because a class on the main store file says nothing about them, and the `-wal` is where recently written
rows live before a checkpoint. Measured, not assumed: see *Provenance* below.

**`DATA-FILE-3` (MUST NOT)** — The app does **not** raise the class to `NSFileProtectionComplete`. That
class means the file "cannot be read from or written to while the device is locked or booting"
(`NSFileManager.h:1307`), and CloudKit mirroring is driven by silent remote notifications — i.e. it works
while the phone is locked. Apple's guidance, quoted from
[#752](https://github.com/jirigrill/eczema-helper/issues/752)'s research rather than re-verified here — the
rendered *Encrypting your app's files* page served no body text when re-fetched, so this one line is the
section's only citation not checked against a local SDK header: *"If your app supports background
capabilities … assign a different protection level for files that you might access while in the
background."* The rule does not rest on it — `NSFileManager.h:1307` alone is sufficient grounds.

**`DATA-FILE-4` (MUST NOT)** — Nor does the app use `NSFileProtectionCompleteUnlessOpen`. Files under that
class "can be created while the device is locked, but once closed, cannot be opened again until the device
is unlocked" (`NSFileManager.h:1311`). Mirroring wakes at arbitrary times and would need to *open* a
closed store, so this class is a worse fit than the default, not a safer one.

**`DATA-FILE-5` (MUST NOT)** — Nor `NSFileProtectionCompleteWhenUserInactive` (iOS 17+, iOS-only,
`NSFileManager.h:1317`). It is stricter than the default and reintroduces exactly the background-write
exposure `DATA-FILE-3` avoids.

**`DATA-FILE-6` (MUST NOT)** — No `applicationProtectedDataWillBecomeUnavailable(_:)` /
`applicationProtectedDataDidBecomeAvailable(_:)` handling. Apple documents that pair for `.complete`
files, which `DATA-FILE-3` rules out; under the default class, protected data does not become unavailable
after first unlock.

**`DATA-FILE-7` (fact)** — There is **no SwiftData API** for this. `ModelConfiguration` exposes no
protection-class parameter, and the string `protection` does not occur anywhere in
`SwiftData.swiftmodule/arm64e-apple-ios.swiftinterface` (iOS 27.0 SDK). Were a class ever to be set, the
routes are `setResourceValue(_:forKey:)` with `fileProtectionKey` on the file, or
`NSPersistentStoreFileProtectionKey` — the latter iOS-only (`API_UNAVAILABLE(macosx)`), relevant only if a
Mac target ever shares the store.

**`DATA-FILE-8` (implementation note)** — Read a class with `URL.resourceValues(forKeys:)`, **not**
`FileManager.attributesOfItem(atPath:)`. The two documented routes disagree: in the #752 measurement the
`URL` route returned the class on all three files while `attributesOfItem` returned `nil` for every one.
Any test asserting a protection class must use the `URL` route or it will assert `nil`.

### Why the default is left alone

The threat is a device seized or lost while locked with the passcode unknown. The default already means the
file "is stored in an encrypted format on disk and cannot be accessed until after the device has booted"
(`NSFileManager.h:1313`), so the store is encrypted at rest without any action. The residual gap —
a device powered on and unlocked at least once, then locked — is not closed by any class compatible with
background mirroring, so the choice is not *default vs. safer* but *default vs. broken sync*.

Full-device encryption covers the powered-off case, and the photo bytes carry a second, app-level layer
(`DATA-ENC-5`). The keychain item holding that photo key is **§11.2**, and it is deliberately given the
matching class for the reason set out there.

### Provenance

`DATA-FILE-2` is measured, because the Core Data default is documented in a header while SwiftData's
inheritance of it is documented nowhere. The header, `NSPersistentStoreCoordinator.h:131`, iOS 27.0 SDK —
no web URL exists for this passage:

> The default value of `NSPersistentStoreFileProtectionKey` is
> `NSFileProtectionCompleteUntilFirstUserAuthentication` for all applications built on or after iOS5. The
> default value for all older applications is `NSFileProtectionNone`.

The probe is `eczema-ios-spikes/probe-fileprotection-752/`. It builds a SwiftData store with no CloudKit
container, reads all three files by both documented routes, and **writes a control file with an explicitly
set class first** — data protection is not enforced on the simulator, so without the control a `nil`
reading could not be distinguished from an unprotected file. The control round-tripped, so the readings
stand.

**Two limits of the measurement, stated rather than papered over:** it ran on the simulator, so it
establishes the class the framework *assigns*, not that the kernel *enforces* it; and it ran without
mirroring enabled. Neither was the doubtful part — the doubt was whether SwiftData inherits the Core Data
default at all, and it does — but a device run with `cloudKitDatabase:` set would close both.

### 11.2 The photo key

Settled by [#763](https://github.com/jirigrill/eczema-helper/issues/763), owner-confirmed. `DATA-ENC-5`
makes the app encrypt photo bytes itself, so the app holds a key. Nothing here is frozen by schema
promotion — a keychain item's attributes are rewritable in any release — but the **first photo write** is a
real deadline all the same, and the same one [#762](https://github.com/jirigrill/eczema-helper/issues/762)
carries: a re-key requires decrypting what the old key protected, which is precisely the operation that
fails once the key is gone. The rules are therefore written as though deadlined, and §11's opening
sentence about revisability does not extend to them in practice.

**`DATA-KEY-1` (MUST)** — The key that `DATA-ENC-5` encrypts photo bytes with lives in the **keychain**,
as a single item, and nowhere else. It is never written into the store, into a file, into the ubiquitous
key-value store of §8, or into any mirrored attribute.

**`DATA-KEY-2` (MUST)** — The item carries `kSecAttrAccessibleAfterFirstUnlock`.

**`DATA-KEY-3` (MUST NOT)** — The item does **not** carry `kSecAttrAccessibleWhenUnlocked`, nor any class
whose name ends `ThisDeviceOnly`, nor `kSecAttrAccessibleAlways`.

**`DATA-KEY-4` (MUST)** — The item carries `kSecAttrSynchronizable = true`, so it travels to a new device
through iCloud Keychain.

**`DATA-KEY-5` (MUST)** — The key is generated on first need — the first photo written on this device with
no key already present — and never regenerated while an item exists. No code path overwrites, rotates or
deletes it.

**`DATA-KEY-6` (MUST)** — A photograph whose bytes cannot be decrypted is a **permanent** state, and the
app must distinguish it from `SKIN-PHOTO-9`'s transient not-yet-arrived state. It is never rendered as an
observation with no photos yet.

**`DATA-KEY-7` (MUST NOT)** — No copy anywhere attributes the loss to encryption in terms that would
represent the app's storage as encrypted without qualification (`DATA-ENC-4`), and none claims the
photograph may still arrive.

**`DATA-KEY-8` (fact, sourced)** — `AfterFirstUnlock` is the class Apple names for exactly this need:
"Item data can only be accessed once the device has been unlocked after a restart. This is recommended for
items that need to be accesible by background applications" (`SecItem.h:570–574`, iOS 27.0 SDK; the typo is
Apple's). `WhenUnlocked` is documented for items that "only need be accesible while the application is in
the foreground" (`SecItem.h:565–569`).

**`DATA-KEY-9` (fact, sourced)** — `kSecAttrSynchronizable` "may not also specify a `kSecAttrAccessible`
value which is incompatible with syncing (namely, those whose names end with \"ThisDeviceOnly\".)"
(`SecItem.h:244–246`). No error code is documented for the combination, so `DATA-KEY-3` and `DATA-KEY-4`
are one constraint stated twice rather than two independent choices.

#### Why the class matches the store file's

This is the direct analogue of `DATA-FILE-1`, under the same constraint, and it is argued from it rather
than chosen freehand. A key the app cannot read while the phone is locked cannot decrypt a photo that
arrives while the phone is locked — and background arrival is not hypothetical here, it is how mirroring
works: `DATA-FILE-3` rejects `NSFileProtectionComplete` precisely because "CloudKit mirroring is driven by
silent remote notifications". `kSecAttrAccessibleWhenUnlocked` is the keychain analogue of the class
`DATA-FILE-3` refuses, and `AfterFirstUnlock` the analogue of the default `DATA-FILE-1` accepts.

The classes even coincide by name: the store file carries
`NSFileProtectionCompleteUntilFirstUserAuthentication` (`DATA-FILE-2`, measured), so raising the key above
`AfterFirstUnlock` would buy nothing. The ciphertext the key opens sits in a file that is itself readable
after first unlock; a stricter class on the key would leave the weaker term untouched and break background
decryption in exchange. The residual gap is identical to the one §11.1 accepts, and identical for the same
reason: no class compatible with background mirroring closes it.

#### Why the key syncs, and what that costs

**The non-syncing option is worse than it looks, and the reason is not the one this question was framed
around.** It was framed as a dilemma with two bad horns — a key that does not sync loses the photographs on
restore, a key that syncs weakens confidentiality. The first horn is sharper than framed and the second is
softer, so the balance is not close.

An iCloud Backup restore to a **new** device does not carry a non-synchronizable keychain item at all.
Apple Platform Security, *iCloud Backup*:

> iCloud Backup is also used to back up the local device keychain, encrypted with a key derived from the
> Secure Enclave UID root cryptographic key of the device. This key is unique to the device and not known
> to Apple. This allows the database to be restored only to the same device from which it originated, and
> it means no one else, including Apple, can read it.

— <https://support.apple.com/guide/security/icloud-backup-security-sec2c21e7f49/web>, Apple Platform
Security (August 2026 revision), fetched 2026-08-31.

This corrects a reading the SDK header invites. `SecItem.h` says items in the non-`ThisDeviceOnly` classes
"will migrate to a new device when using **encrypted backups**" (`SecItem.h:568–569`, `573–574`) — which is
true of a local encrypted backup and **not** of iCloud Backup, whose keychain copy is sealed to the
originating device's Secure Enclave. Without `DATA-KEY-4`, the store therefore arrives on the new phone
complete while the key does not arrive at all, silently: no error, no signal, nothing the app could branch
on. Every photograph would be present, listed, and permanently unopenable — and with no export
([#683](https://github.com/jirigrill/eczema-helper/issues/683)) and no import (`SET-ABSENT-2`) there is no
route by which a readable copy could have been kept. That is the *default* outcome of a new phone, not a
tail risk.

**And the confidentiality cost is smaller than the framing assumed, because the dependency already
exists.** `DATA-ENC-1` puts every other field in this store behind CloudKit's field encryption, and for
third-party containers that encryption already draws on iCloud Keychain key material: "This encryption
functionality uses key material that is stored in the iCloud Keychain belonging to the iCloud account
signed in on the device" (WWDC21 session 10086, *What's new in CloudKit*,
<https://developer.apple.com/videos/play/wwdc2021/10086/>, transcript fetched 2026-08-14, recorded in
`eczema-helper/docs/research/cloudkit-encrypted-values.md`). So `DATA-KEY-4` does not introduce an iCloud
Keychain dependency — it puts the photo key in the same place the rest of the store's confidentiality
already rests, and the photographs keep the one advantage `DATA-ENC-5` bought them: reading them needs the
key material *and* the ciphertext, where `DATA-LOCK-4` would otherwise have handed the server plaintext
outright once an image crossed ~750 KB.

**A caution against over-reading that.** Platform Security does say CloudKit service keys "are synchronized
between a user's devices even if the user chooses not to use iCloud Keychain to sync their passwords,
passkeys, and other user data" — but that sentence is scoped to "Many Apple services, listed in the Apple
Support article iCloud data security overview" and "these CloudKit containers"
(<https://support.apple.com/guide/security/icloud-encryption-sec3cac31735/web>). It is **not** sourced for
third-party containers, so nothing here claims this app's field encryption works with the toggle off. That
is an open question — §14's 13.7 — and it cuts both ways: whatever the answer, `DATA-KEY-4` shares it with
`DATA-ENC-1` rather than adding to it.

**Its cost, accepted knowingly.** With iCloud Keychain switched off, `DATA-KEY-4` silently degrades to the
non-syncing case: the item stays local, the new phone gets no key, and the photographs are lost exactly as
described above. The app cannot require the setting, and nothing in these rules detects it. So the
fifth silent-loss path is real, narrower than the default it replaces, and outside the app's control —
recorded as `DECISIONS.md` §9 rather than left to be re-derived.

**The alternative that was considered and rejected.** The photo key could have been stored as an
**encrypted CloudKit field** instead of in the keychain — a 32-byte value never approaches §5.2's ~750 KB
promotion threshold, so `DATA-LOCK-4` never fires on it, and the key would then inherit precisely the
durability and recovery paths of the CloudKit key hierarchy, keychain excluded. It is the better option on
recovery, and it is rejected on purpose: it collapses the photographs to the *same* protection as every
other field, which is what `DATA-ENC-5` exists to exceed. A key held in the same encrypted-field mechanism
as the data it protects adds a step for an attacker with server access, not a barrier.

#### What a lost key looks like to her

`DATA-KEY-6` is the rule that keeps an already-accepted loss from being reported as a lie.
`SKIN-PHOTO-9` requires an observation whose photos have not arrived to render "as an observation with no
photos yet, never as a failure" — correct for mirroring, where the photos genuinely may still arrive. A
photograph with no key is the opposite case: it will never arrive, and rendering it in the transient state
would tell her to wait for something that is gone. The two states are indistinguishable in the data — a
photo record present, its bytes unreadable — which is exactly why the rule is needed rather than left to
the implementer.

The **copy** is not written here. `DATA-KEY-7` fences it on two sides — it may not overclaim encryption
(`DATA-ENC-4`), and it may not imply the photograph is still coming — and the wording itself belongs with
the rest of the skin-observation copy, which is the owner's to draft. That is carved out rather than
guessed.

---

## 11a. Accessibility

The store has no interface, so this block is short — and it is here rather than omitted for the same
reason `catalog.md` §9a is: the template requires every section to answer, and "nothing renders" is an
answer only once it has been checked against what this section actually decides. Two of its decisions
do reach the accessibility surface.

**`DATA-A11Y-1` (MUST)** — No stored value is exposed to assistive technology that is not also
displayed. Tiebreak values, record identifiers, food ids (`DATA-SCOPE-5`), byte sizes, formats and
dimensions (`DATA-PHOTO-5`), and change-log entries (`DATA-HIST-*`) are internal. An accessibility label
is the likeliest place for a raw id to escape, because it is a natural stand-in when there is no display
string to hand — which is exactly the unresolvable-item case `day-view.md` `DAY-A11Y-6` governs.

**`DATA-A11Y-2` (MUST)** — The distinction between **absent** and **empty** that §10 makes carries into
what is announced. An absent note is not announced as an empty note, and an absent value is not
announced as a zero, a blank, or an unknown — the display rules for each absence live in the section
that owns the surface, and this rule says the announcement follows them rather than exposing the
storage state.

**`DATA-A11Y-3` (MUST)** — An orphan photo is invisible to assistive technology exactly as it is
invisible on screen (`DATA-ORPHAN-1`), and the sweep is silent in announcements as well as in the
interface (`DATA-ORPHAN-6`). A record whose parent has not arrived is not announced as anything,
including as missing.

**`DATA-A11Y-4` (MUST)** — Where photo bytes cannot be read, the failure is surfaced through
`skin-observation.md` `SKIN-VIS-4`'s rule and announced as that section requires. Nothing announces a
storage diagnostic, a file-protection class, or a byte count.

### 11a.1 The five questions

| # | Answer |
| --- | --- |
| 1 | **VoiceOver label and trait** — not applicable. This section specifies no interactive element and no screen. Every surface that renders a stored value is specified elsewhere, and each of those sections carries its own block. |
| 2 | **Dynamic Type** — not applicable to the store itself. One consequence is worth naming: nothing in the schema imposes a length limit on the note (§10), so no stored value is short enough to assume a fixed line count, and the surfaces that render notes must reflow rather than rely on brevity. |
| 3 | **Colour alone** — not applicable. The store holds no presentational value: no colour, no severity ramp, no emphasis. `DATA-SKIN-5` keeps even the canonical region order a property of the app rather than of the data. |
| 4 | **Focus order and grouping** — not applicable, with one consequence. Storage order is not display order (`DATA-SKIN-5`, and `catalog.md` `CAT-SRC-3`), so a surface must not derive focus order from what the store returns — the rule that binds this is `day-view.md` `DAY-A11Y-4`. |
| 5 | **Reduce Motion** — not applicable. The store specifies no animation and no transition. |

---
## 12. Divergence index

| # | Section | Summary | Class |
| --- | --- | --- | --- |
| 1 | §3.1 `DATA-MEAL-2` | The composite key is no longer stored as a string alongside its own components. | Forced by platform |
| 2 | §3.1 `DATA-MEAL-4` | Instants become instants; the calendar day stays a label. | Defect fixed (half) |
| 3 | §3.2 `DATA-ITEM-2` | The item loses both its unstable `id` and its Czech display name. | Defect fixed |
| 4 | §4.1 `DATA-ID-1`..`-3` | Identity stops being content; one-meal-per-slot becomes eventual. | Forced by platform |
| 5 | §5.1 `DATA-SKIN-4` | All nine regions are always stored; there is no absent-means-calm case. | Defect fixed |
| 6 | §5.2 `DATA-PHOTO-2`, `-3` | Photo bytes move to their own record, and three metadata fields are added. | Forced by platform + settled by #730 |
| 7 | §5.3 `DATA-PHOTO-6` | The cascade becomes a declared delete rule rather than hand-written code. | Defect fixed |
| 8 | §7 `DATA-ARRIVE-3` | Cross-device atomic arrival is lost; an idempotent sweep replaces it. | Forced by platform |
| 9 | §8.2 `DATA-OUT-3` | A consent record exists at all, and lives outside the store. | Settled by #709 |
| 10 | §9 `DATA-HIST-2` | The change log is not purged in release one. | Settled by #730 |
| 11 | §10.1 `DATA-ABSENT-5` | No version attribute, against the platform vendor's own from-the-outset advice. | Owner's call — hiding records is the wrong failure |
| 12 | §11.2 `DATA-KEY-6` | A photograph can be permanently unopenable while its record is intact — a state the PWA cannot reach, and one the app must render as distinct from a photo that has not arrived yet. | Forced by platform |

Eleven of these twelve divergences predate [#763](https://github.com/jirigrill/eczema-helper/issues/763),
and of them **four are forced by the platform and two are the vendor's own advice
declined or reversed** — a distribution unlike any other section in this spec, and the honest measure of
what this area is. Elsewhere a divergence usually means the reference implementation was incoherent and
the port picked one behavior. Here it often means the reference implementation rested on a guarantee
that no longer exists: a store that made identity out of content, wrote several tables in one
transaction, and could refuse a delete. Only four (2, 3, 5, 7) are defects in the ordinary sense.

Divergence 11 is worth reading twice, because it is the one place this document declines documented
platform guidance rather than absorbing it. The advice — include a version attribute from the outset — is
sound in general and is refused on product grounds: its mechanism is to hide records an older app cannot
read, and hiding a mother's own records from her, silently, is a worse failure than the display
degradation [#703](https://github.com/jirigrill/eczema-helper/issues/703) already accepted. The cost of
refusing is permanent and is recorded in §10.1 rather than glossed.

---
## 13. Verification

### Where each rule is verified today

For a port translating the existing tests rather than writing fresh ones. Paths are in the frozen repo at
`582f662`.

| Rules | Existing TypeScript tests | Verdict |
| --- | --- | --- |
| §2 scope, §2.1 catalog values | `allergen-catalog.test.ts`, `curation-rules.test.ts:340` | **Re-derive.** They guard the catalog's own shape, which is bundled data in both products; nothing there tests that the *store* holds no catalog. |
| §3.1 meal fields | `working-meal.test.ts` (727 ln) | **Translate**, minus identity. The field-level rules port directly; every assertion about `Meal.id` being the composite must be dropped rather than adapted (Divergence 4). |
| §3.1 `DATA-MEAL-5`, `-6` | `meal-editor.test.ts` — the `updatedAt`-on-edit-only tests | **Translate** directly. This is the best-tested behavior in this document. |
| §3.2 items | `working-meal.test.ts`, `meal-dirtiness.ts:29` | **Re-derive.** The dirtiness key is composed as `${foodId}${name}${amount}${preparation}` and `name` no longer exists; #703 already recorded that the key must be restated without it, not ported as written. |
| §4 identity and convergence | **none anywhere** | Nothing to translate. The reference implementation cannot produce a duplicate, so no test can exist for resolving one. |
| §5.1 observation, regions | `src/routes/skin/page.test.ts:190`, `:215` | **Translate** — the two tests that assert all nine regions are witnessed are the closest existing guard on `DATA-SKIN-4`. |
| §5.1 `DATA-SKIN-2` write-once | `page.test.ts` edit tests | **Translate.** `createdAt` immutability across edit is asserted today. |
| §5.2 photo record shape | `page.test.ts:528`–`:938` | **Do not translate.** Every test asserts the single-row shape Divergence 6 replaces, and one acknowledges in a comment that it cannot verify the image survives its round trip at all. |
| §5.3 cascade | `dexie-skin-observation-repository` tests | **Do not translate.** They assert a hand-written scan inside a transaction — both the mechanism and the transaction are gone. Replace with a test that deleting an observation removes its photos. A test that "no delete is ever refused" is **not writable at runtime** — per [#764](https://github.com/jirigrill/eczema-helper/issues/764) a refusing rule prevents the store from opening at all, so `DATA-PHOTO-8` is verified by `DATA-ARRIVE-10` loading the schema, not by attempting a delete. |
| §6 orphans | **none** | Nothing to translate. An orphan is unrepresentable in a store with transactions. |
| §7 arrival | **none — the reference implementation is single-device by construction** | Nothing to translate. Every rule in §7 describes a state the reference store cannot enter. |
| §7.2 `DATA-ARRIVE-10` | **none** | New, and the cheapest test in the suite: load the real schema with mirroring enabled and assert it opens. |
| §8 outside the store | `settings.svelte.ts` tests | **Do not translate.** They test a store row that no longer exists; the singleton moves out entirely. |
| §9 history, §10 promotion | **none, and none possible** | Nothing to translate, and mostly nothing testable — see below. |
| §11 `DATA-FILE-1`, `-2` | **none in either repo, but already measured** — `eczema-ios-spikes/probe-fileprotection-752/` | **Re-derive as a Swift test**, and it is nearly free: open the container, read `fileProtectionKey` off the store and both sidecars, assert `completeUntilFirstUserAuthentication`. Two constraints or the test lies. It must use the **`URL`** route (`DATA-FILE-8`) — `attributesOfItem` returns `nil` and an assertion against it would pass vacuously; and it must assert a **control** file whose class the test sets itself, because data protection is unenforced on the simulator, so without a control a green run proves nothing. |
| §11.2 `DATA-KEY-1`..`-5` | **none — the reference implementation holds no key** | **Re-derive as a Swift test**, and read the attributes back rather than trusting the write: query the item with `kSecReturnAttributes` and assert `kSecAttrAccessible == kSecAttrAccessibleAfterFirstUnlock` **and** `kSecAttrSynchronizable == true`. Asserting only that a key can be fetched would pass under every class this section refuses. `DATA-KEY-5`'s stability is the second test: generate, read, call the generation path again, assert the same bytes come back. |
| §11.2 `DATA-KEY-6`, `-7` | **none** | **Re-derive**, and this is the one rule here with a *user-visible* failure, so it is worth more than an attribute check: write a photo, remove the key, and assert the record renders in the permanent state and **not** in `SKIN-PHOTO-9`'s transient one. The two states are indistinguishable in the data, so a test that only asserts "no crash" would pass while the app told her to wait for a photograph that is gone. |
| §11 `DATA-FILE-3`..`-7` | **none, and none wanted** | Prohibitions on code that does not exist. A test asserting the app never calls `setResourceValue(_:forKey:)` is a lint rule, not a behavior test. |
| §11a accessibility | **none** | **Re-derive**, and only `DATA-A11Y-1` is really this section's to verify: assert that no accessibility label, value or hint anywhere in the app contains a record identifier, a tiebreak value or a raw food id. It is one sweep over the rendered surface rather than a per-rule test, and it is the guard against a raw id escaping as a stand-in label. The other three are enforced by the sections that own the surfaces. |

**Rules nothing verifies today.** The list is unusually long for this spec, and its length is the finding:
**most of this document specifies behavior the reference implementation could not exhibit**, so absence of
a test is not an oversight in the PWA — it is a property of having had a store with transactions and
content-derived identity.

- **The whole of §4.** Convergence, the tiebreak, supersession, deferred erasure, the last-writer rule.
  Nothing in either repo tests any of it, and the tiebreak (`DATA-CONV-1`) is the most deadlined field in
  the document. `DATA-CONV-10`'s deferred erasure is the hardest to test honestly, because the failure it
  prevents needs three participants and an unlucky ordering; the testable core is narrower and should be
  written as such — that a marked record is never erased before both an upload and a download have
  completed, and that its marking instant never moves (`DATA-CONV-9`).
- **The whole of §6 and §7.** Both describe arrival states, and arrival needs two devices. The parts
  testable without a second device are worth isolating: that the sweep is idempotent and
  order-independent (`DATA-ORPHAN-3`) is verifiable by running it twice against a synthetic orphan, and
  `DATA-ARRIVE-5` — nothing branches on emptiness — is verifiable by inspection of the launch path rather
  than by a test.
- **`DATA-SKIN-5`, order derived from identity rather than position.** Untestable through the store, since
  a store that happens to preserve order will pass either way. This one belongs in a review, not a test
  suite.
- **`DATA-PHOTO-5`, metadata describing the stored bytes.** Nothing verifies it and it is the field most
  likely to drift, because the natural implementation reads the size of the *original* image before
  compression. A test that compresses a known image and asserts the recorded size equals the stored
  length is cheap and worth writing.
- **Everything in §10.2 and §10.3.** Promotion, encryption locks, and the local-versus-remote migration trap
  cannot be tested from a test suite at all — they are properties of a deployment. `DATA-ARRIVE-10` catches
  the one failure that *is* catchable; the rest are a release checklist, and it is now a checklist of
  *settled* items rather than open ones. Two parts of §10.3 are nonetheless testable and worth writing,
  because both fail silently: that a photo's stored bytes are **not** readable as an image without the app's
  key (`DATA-ENC-5`), and that no query in the codebase is server-side (`DATA-ENC-3`) — the second is a
  review or a lint, not a test. Whether a field actually arrived encrypted is only observable by reading the
  raw server record, which is what the #747/#748 probe harness does and no unit test can.
- **§11a, and it is genuinely thin.** Only `DATA-A11Y-1` is verifiable here and it is worth the one
  sweep. `DATA-A11Y-2`'s absent-versus-empty distinction is verified by the sections that render it, and
  `DATA-A11Y-3`'s silence is verified by the same absence checks the orphan rules already need.

### Acceptance pass

Instructions to a person holding a phone. Steps marked **✗ PWA** are expected to fail on the reference —
those are the divergences, and they are the steps that prove the port did something.

This section's acceptance pass is unlike the others: **most of it needs two devices or a reinstall**, and
a step that needs an arrival cannot be hurried. Steps 1–6 are the ones doable on one phone in a few
minutes.

1. Log a meal with three foods, in a deliberate order. Reopen it. The foods are in the order you entered
   them (`DATA-ITEM-3`).
2. Log a meal with no note. Reopen it and add nothing. Nothing about it distinguishes "no note" from an
   empty one — there is no stray blank line, no placeholder (`DATA-MEAL-7`).
3. Log a meal, note the time it shows. Edit it an hour later, changing one food. The displayed time is
   still the original (`DATA-MEAL-6`).
4. Save a skin observation with one region bumped and the rest untouched. Reopen it: **all nine** regions
   are present, eight of them calm — not eight missing (`DATA-SKIN-4`). **✗ PWA**
5. Attach a photo to an observation and save. Delete the observation. The photo is gone with it, and
   nothing anywhere still refers to it (`DATA-PHOTO-6`).
6. Photograph a region, save, then look at the record's own storage figure if any diagnostic surface
   exists. It reports a size matching the stored image, not the camera's original
   (`DATA-PHOTO-3`, `DATA-PHOTO-5`). **✗ PWA**
7. Turn on airplane mode. Log two meals and an observation with a photo. Force-quit the app. Relaunch,
   still offline: everything you logged is there (`DATA-ARRIVE-7`).
8. Still offline, look everywhere for a sign that something has not uploaded. There is none, and nothing
   suggests a record was lost (`DATA-ARRIVE-8`).
9. Delete the app and reinstall it, signed into the same iCloud account. Do not touch anything. Records
   begin appearing. While they are appearing, open a day that is partly populated — it renders without
   error, showing what has arrived (`DATA-ARRIVE-2`). **✗ PWA**
10. During that same import, watch for an observation that shows with no photos and then gains them
    minutes later. This is the expected behavior, not a bug (`DATA-ARRIVE-2`, Divergence 8). **✗ PWA**
11. After that reinstall completes, check the day view for **duplicate meals in one slot**. There should
    be none — and if any appear transiently, they must disappear without you doing anything
    (`DATA-CONV-2`, `DATA-CONV-7`). **✗ PWA**
12. The two-device case, which needs a second phone on the same account. Put both offline. On each, log a
    meal in the **same** slot — the same day, the same meal type, the same actor — with different foods.
    Bring both online. Both devices end up showing **one** meal in that slot, and both show the **same**
    one: the one edited most recently (`DATA-CONV-4`). **✗ PWA**
13. Same setup, but make the two edits at times you have noted. Confirm the surviving meal is the later
    one and that the earlier one's foods are simply gone — **not merged into a single meal containing
    both** (`DATA-CONV-5`). **✗ PWA**
14. Through all of step 12 and 13, confirm you were never shown a conflict, never asked to choose, and
    never told anything happened (`DATA-CONV-6`). **✗ PWA**
15. On the second device, delete an observation that has photos. On the first device, before it has
    finished syncing, look for the photos. They are not visible at any point, in any state
    (`DATA-ORPHAN-1`). **✗ PWA**
16. Leave both devices running for a day after step 15, then check that storage has been reclaimed
    rather than the photos lingering forever (`DATA-ORPHAN-4`). **✗ PWA**
17. Change the feeding stage on one device. It changes on the other. Then look for any meal whose
    displayed actor changed as a result: there must be none (`DATA-OUT-1`, and
    [INV-14](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-14) binding at log time).
18. Delete the app and reinstall **while signed out** of iCloud. Nothing arrives, and the app does not
    treat the empty store as a fresh installation by asking you to consent again or re-pick a feeding
    stage that is still recorded (`DATA-ARRIVE-5`, `DATA-OUT-3`). **✗ PWA**
19. **Turn VoiceOver on** and sweep the whole app — day view, both editors, Settings. Nothing announced
    anywhere is a record identifier, a tiebreak value, a raw food id, a byte size or an image dimension
    (`DATA-A11Y-1`). Pay particular attention to a meal row whose items do not resolve: it must announce
    as occupied with no names, not as an id (`day-view.md` `DAY-A11Y-6`).

Steps 9–16 are this section's real acceptance test, and they are slow: each needs a fresh install or a
second device, and steps 9–11 need an import that the platform is entitled to defer out of a launch
session entirely. **A step that does not fire is not a failure until it has been retried on a charged,
unthrottled device.** Steps 12–14 are the only way to exercise §4 at all, and they are the ones most
worth doing before promotion, because §4 is where the deadlined tiebreak either works or is discovered to
be missing.

One warning about step 11. Its timing is not controllable: if the import completes before you look, the
duplicates never existed to observe and the step is *untested* rather than passed. The observable it is
really checking is the end state — one meal per slot — so treat a clean day view as the pass condition
and a persistent duplicate as the failure.

---
## 14. Open questions

Recorded rather than guessed, per the map's cite-or-don't-claim rule. Each is a candidate ticket. **Two
carry a schema deadline** and are marked as such — they are the only ones that cannot wait, because
additive-only promotion means a field never recorded cannot be backfilled.

**13.1 — Does an array of composite values mirror, and as what? ✅ ANSWERED: yes, as one opaque blob.**
Measured on a real container from a physical device ([#747](https://github.com/jirigrill/eczema-helper/issues/747)),
recorded at `DATA-SKIN-4` in §5.1. The composite mirrors as **one** field, not decomposed field by field,
so the partial arrival the rule exists to prevent is unrepresentable and the fallback to nine discrete
named attributes is **not** required. Two findings the question did not anticipate. First, the value
arrives as an opaque `Data` blob whichever way it is declared — a `Codable` array, a dictionary, and an
app-encoded `Data` field all land as JSON bytes — so the "explicit blob" fallback buys nothing on the
server side, and the choice is an app-side one. Second, because it is a blob it does inherit §5.2's
size-driven asset promotion, as this section anticipated; nine regions are ~221 bytes, so the threshold is
not in reach, but the inheritance is real and `DATA-LOCK-4` is what it would run into.

**13.2 — Are externally stored assets covered by field encryption? ✅ ANSWERED: no.**
Measured on a real container from a physical device and recorded as `DATA-LOCK-4` in §10.2
([#748](https://github.com/jirigrill/eczema-helper/issues/748)). A field declared
`@Attribute(.allowsCloudEncryption)` arrives encrypted below §5.2's ~750 KB threshold and, above it, is
renamed to a `_ckAsset` field and carries **no** encrypted value — silently, with no error. So a photo is
encrypted while small and unencrypted once it grows: the confidentiality of an image varies with its size.
The **remedy is now settled too** — `DATA-ENC-5`, §10.3: the app encrypts the bytes before storing them, so
the asset carries ciphertext and the declaration's behavior stops mattering for photographs. Nothing about
this question remains open.

**13.3 — The optional-or-defaulted rule for attributes has no primary source.**
`DATA-ARRIVE-9` states it and `DATA-ARRIVE-10` tests for it, on the strength of
[#713](https://github.com/jirigrill/eczema-helper/issues/713)'s direct measurement. But the platform
vendor documents no such requirement — its own compatibility table names only *required relationships* —
and this map has been repeating the claim as though it were documented. Nothing depends on resolving it:
the rule is stated conservatively, the measurement is trustworthy, and the test catches the failure either
way. It is recorded so that nobody cites documentation that does not exist. This is an open question
**against the source**, in the sense `skin-observation.md` §12.1 uses.

**13.4 — There is no documented deduplication path for the framework this app uses.**
The vendor's convergence blueprint, which §4 follows, is written against the *previous* persistence
framework: it reads a change log through that framework's interfaces and depends on a per-transaction
author field to tell local writes from arrivals. No equivalent walkthrough exists for the framework this
app uses, and no documented equivalent of the author filter could be found. §4's rules are written as
behavior rather than mechanism precisely so they survive this gap — but whoever implements `DATA-HIST-1`
is doing unsourced translation, and should know that rather than discover it. Worth a spike before §4 is
implemented, not before the schema is promoted.

**13.5 — The upload-time boundary the vendor's own guidance and sample disagree about.**
`DATA-HIST-3` gates purging on the last successful upload. The prose says that event's **start** time; the
vendor's own sample code records its **end** time, for a related but different purpose. No source
reconciles them. It affects nothing today because `DATA-HIST-2` does not purge; if that ever changes, the
start time is the conservative choice, being always the earlier of the two.

**13.6 — Whether anything should ever be recorded about which device wrote a record.**
`DATA-ABSENT-5` forbids a device identifier, and that is the right default for a single-user private
journal. But it interacts with §14.4: the vendor's convergence blueprint distinguishes local writes from
arrivals using framework-level metadata, and if that metadata proves unavailable in this framework, an
app-level equivalent would be the fallback — and would be a **new field**, deadlined. Recorded so the
dependency is visible: if 13.4's spike finds no author filter, this question becomes urgent rather than
theoretical.

**13.7 — What happens to an encrypted write when the mother has iCloud Keychain switched off.**
Unanswered in both directions, and it is `DATA-ENC-1`'s question before it is `DATA-KEY-4`'s. For
third-party containers the only sourced statement is that field encryption "uses key material that is
stored in the iCloud Keychain belonging to the iCloud account signed in on the device" (WWDC21 10086).
Apple Platform Security *does* say CloudKit service keys synchronise "even if the user chooses not to use
iCloud Keychain", but that passage is scoped to "Many Apple services … these CloudKit containers"
(<https://support.apple.com/guide/security/icloud-encryption-sec3cac31735/web>) and **cannot** be read as
covering this app. So it is unknown whether an encrypted-field write fails, silently falls back, or works
normally with the toggle off. Nothing in the spec depends on the answer — `DATA-KEY-4` shares the exposure
with `DATA-ENC-1` rather than adding to it, and the loss it would cause is already recorded as
`DECISIONS.md` §9 — but it is the difference between one silent-loss path and a broader one, and it is
measurable on a device now that a probe builds and signs. This question was already open in
`eczema-helper/docs/research/cloudkit-encrypted-values.md` (Gap 12) and is restated here because a rule now
rests beside it.

**13.8 — Whether deleting and reinstalling the app clears its keychain items.**
Undocumented by Apple in **both** directions — no statement was found either way, and community reports
disagree across OS versions. It matters because `DATA-KEY-5` generates the key on first need: if a
reinstall clears the item, a reinstall on the *same* phone is a total loss of photographs, which would make
`DATA-KEY-4`'s sync the only thing standing between a routine action and the loss. If it does not clear,
the reinstall case is safe on any device that ever held the key. Worth a device probe before the first
photo write, not a decision — no rule changes either way, but the size of the accepted loss does.

---
## 15. What the owner settled

Nine questions were put to the owner in the grilling session that produced this document, each with a
recommendation. **All nine were settled in agreement with the recommendation**, so no rule below carries
a "decided against advice" mark. They are recorded here because six of them are locked by first schema
promotion, and a later reader needs to know which rules are the owner's decision rather than a
carry-through from an earlier ticket.

| # | Question | Settled | Rules | Deadlined |
| --- | --- | --- | --- | --- |
| 1 | Do photo bytes ride on the photo record, or on their own? | Their own record, forcing the asset path and decoupling the pixel target from transport | `DATA-PHOTO-2` | ⏳ Yes |
| 2 | Does a photo record its byte size, format and dimensions? | Record all three | `DATA-PHOTO-3` | ⏳ Yes |
| 3 | Does the consent record live in the store? | Outside it, as a key, so duplication is unrepresentable | `DATA-OUT-3` | ⏳ Yes |
| 4 | Where does the sync diagnostic log live? | A local file outside the store, never mirrored | `DATA-OUT-5` | No |
| 5 | Are the nine regions one value or nine records? | One value on the observation | `DATA-SKIN-4` | ⏳ Yes |
| 6 | Is a meal item its own record type? | Embedded on the meal, and the item id dropped | `DATA-ITEM-1`, `DATA-ITEM-2` | ⏳ Yes |
| 7 | Which record wins when the same slot is written twice? | Most-recently-modified, with the tiebreak breaking exact ties | `DATA-CONV-4` | No |
| 8 | Does the orphan sweep delete orphan photos? | Only after a grace period from the photo's own arrival, never on first sight | `DATA-ORPHAN-4` | No |
| 9 | Do dates and timestamps stay strings? | Instants become native instants; the calendar day stays a label | `DATA-MEAL-3`, `DATA-MEAL-4` | ⏳ Yes |

Two of these deserve a second glance from the owner at confirmation time, because both accept a loss
rather than avoiding one. Decision 7 destroys the losing edit with no notice and, under mandatory sync
with no export, unrecoverably — tolerable only because the realistic collision is the reinstall case, one
phone writing sequentially, not two people editing at once. Decision 3 places the consent record in
storage documented as **unencrypted on disk**, which puts its timestamp and revision id outside §10.3's
blanket encryption — now that §10.3 encrypts *everything* it can, this is one of only two values the mother
creates that are not covered (the feeding stage is the other). That is still a weaker concession than the
feeding stage's, since the record holds no health data — only that she consented, when, and to which text.

**Four further decisions were settled by the owner after this table was written**, in
[#714](https://github.com/jirigrill/eczema-helper/issues/714), and all four are deadlined: encrypt every
encryptable attribute rather than a chosen list (`DATA-ENC-1`), include the timestamp row #693 had left
explicitly to the owner (`DATA-ENC-2`), encrypt photo bytes in the app rather than keeping them small
(`DATA-ENC-5`), and treat the on-device store file as a separate, undeadlined question rather than settling
it under the same deadline ([#752](https://github.com/jirigrill/eczema-helper/issues/752), now settled in
§11.1 — the default class is inherited and nothing is set). Each was settled
in agreement with the recommendation put to the owner, so as with the nine above, no rule carries a
"decided against advice" mark.

**Three more were settled in [#763](https://github.com/jirigrill/eczema-helper/issues/763)**, on the photo
key `DATA-ENC-5` implies: its accessibility class (`kSecAttrAccessibleAfterFirstUnlock`, `DATA-KEY-2`),
that it syncs through iCloud Keychain (`DATA-KEY-4`), and that an undecryptable photograph gets a permanent
state distinct from the transient not-yet-arrived one (`DATA-KEY-6`). All three were settled in agreement
with the recommendation. None is deadlined by schema promotion; all three are closed by the **first photo
write**, since a re-key must decrypt what the lost key protected. The second accepts a cost knowingly and
carries a `DECISIONS.md` entry for it.

---
## Appendix: what this section does not contain

- **Swift types, property wrappers, and macro syntax.** Every rule is a claim about stored behavior; how
  it is declared is an implementation matter.
- **The photo pipeline's constants** — target dimensions, format, quality, any cap.
  [#684](https://github.com/jirigrill/eczema-helper/issues/684) deferred them to implementation, to be
  measured on a device. §5.2 is deliberately written so that no constant it picks can change the record
  shape.
- **The photo key's cipher, key size and derivation function.** §11.2 settles the key's *lifecycle* — where
  it lives, its accessibility class, that it syncs, and what she sees when it is gone (`DATA-KEY-1`..`-9`) —
  but not the cryptography it is used with. That was ruled out of scope by
  [#763](https://github.com/jirigrill/eczema-helper/issues/763) as Swift implementation detail, on the
  condition that no choice among them changes an answer in §11.2. A 256-bit symmetric key in the platform's
  own crypto library satisfies every rule there; nothing in the spec requires that specific choice.
- **Migration mechanics** — how a later release adds a field, and what the local migration does. Out of
  scope by the ticket, and §10.2's `DATA-LOCK-3` states the only part that carries behavior.
- **Console configuration**, environment management, and how promotion is performed.
- **The catalog's own shape.** Bundled data outside the store; its spec section is
  [#734](https://github.com/jirigrill/eczema-helper/issues/734)'s, and
  [#686](https://github.com/jirigrill/eczema-helper/issues/686) settled that it is not persisted.
- **What the mother is told when sync fails**, and every other sync-facing surface. `settings.md` §4.1
  owns all of it. This section specifies what the store does; that one specifies what she sees.
- **Account states and the sign-in transition.**
  [#687](https://github.com/jirigrill/eczema-helper/issues/687)'s.
- **Time zones.** Settled by [#728](https://github.com/jirigrill/eczema-helper/issues/728) —
  `day-view.md` `DAY-NAV-9`..`-9c` own the rules, and this section makes the one commitment they rest
  on: `DATA-MEAL-3`'s calendar-day label. **No schema change followed**, which is the point — the
  resolution is expressible in the shape already specified here. A record **dated after today** is
  settled too, as `day-view.md` `DAY-NAV-13`
  ([#743](https://github.com/jirigrill/eczema-helper/issues/743)): it is stored, synced and complete,
  with no quarantine, no pending state and no field marking it — `DATA-ARRIVE-7` already makes it
  fully recorded, and its unreachability is a property of the selector's range, not of the record.
  **One consequence remains unsettled** and it lands in this section rather than the day view: the
  meal-slot collision on a twice-lived date
  ([#744](https://github.com/jirigrill/eczema-helper/issues/744)), a write-side `INV-4` upsert
  question for §4.1 and §5.
