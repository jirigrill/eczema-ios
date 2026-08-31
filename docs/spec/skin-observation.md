# Skin observation — behavior specification

**Status:** owner-confirmed template. This is the **first** spec section and doubles as the
**format template** every later section follows — see
[`TEMPLATE.md`](TEMPLATE.md) for the rules this document demonstrates.
**Behavior reference:** `jirigrill/eczema-helper` @ `582f662` (frozen PWA), `src/routes/skin/`.
**Resolves:** [#682](https://github.com/jirigrill/eczema-helper/issues/682) on the transition map
[#672](https://github.com/jirigrill/eczema-helper/issues/672).

## Overview

The skin observation screen is where the mother records how the baby's skin looks: a severity
level for each of nine body regions, an optional note, and any number of photos. It is the
second of the app's two recording surfaces (the other is the meal editor) and the smaller one
— but it carries the product's most distinctive rule, that **looking and finding nothing is
itself a record worth keeping** ([INV-7](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-7)).

This document states what the screen does, in English, without reference to Swift, SwiftUI,
SwiftData, Svelte, Dexie, or the Czech interface. Swift tests are derived from the numbered
rules; the owner's acceptance pass is derived from §11.

Three things about this screen are worth knowing before reading the rules:

1. **Every visit can save.** There is no "nothing to record" state in compose mode. A mother
   who opens the screen, looks, sees calm skin and taps save has written a real observation —
   nine regions, all `Calm`. Absence of a record means "didn't look", never "nothing wrong".
2. **A day holds many observations, not one.** The screen writes a *new* record per visit;
   morning and evening are two rows, each with its own timestamp. This is stated because it
   is easy to assume otherwise (§2.4) and because the PWA's own glossary and invariant text
   pull in opposite directions (§12.1).
3. **Delete is a hard delete with a short undo.** There is no trash. The undo lives in memory
   for one action and dies with the app (§8).

### How to read this document

Every rule has a **stable id** — `SKIN-<area>-<n>` — and is written as a single testable
claim. Ids are permanent identity, never renumbered or reused; a new rule appends the next
unused number in its area. Cite them from code comments, tests, and commit messages.

**Rule strength** is marked on every rule, because "what the PWA does" and "what the iOS app
must do" are not the same thing:

| Mark | Meaning |
| --- | --- |
| **MUST** | Required behavior. A Swift test asserts it. |
| **MUST NOT** | Prohibited behavior. Where practical, made unrepresentable rather than tested. |
| **SHOULD** | Strong default. Departing needs a recorded reason, not a preference. |
| **PWA** | Describes the reference implementation only — **does not** carry to iOS. Present so a reader who compares the two is not misled, and so the divergence is auditable. |
| **OPEN** | Genuinely undecided. Blocks nothing yet; listed in §12 with its ticket. **This section has none left** — the four it shipped with were resolved by the owner (Divergences 12–15); the mark stays documented because later sections will use it. |

An **OPEN** rule is never silently resolved by an implementer. If a rule you need is OPEN,
that is a map ticket, not a judgement call.

### Invariant dispositions

Invariants are **cited, never restated** — the numbered `INV-n` list in the frozen repo's
`CONTEXT.md` is the single home for their text, and duplicating it here would create two
copies free to drift.

But citation alone is not enough for this port, because **four invariants are deliberately
false for iOS**. [#691](https://github.com/jirigrill/eczema-helper/issues/691) classified all
fourteen; the ones this section touches carry an explicit **disposition** so a bare citation
can never import a contradiction:

| Ref | Leading phrase | Disposition here |
| --- | --- | --- |
| [INV-2](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-2) | _No backup mechanism exists_ | **Void for iOS.** Sync carries durability ([#683](https://github.com/jirigrill/eczema-helper/issues/683)); retirement is [#688](https://github.com/jirigrill/eczema-helper/issues/688)'s. Still true that there is no *rollback* — §8.5. |
| [INV-6](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-6) | _Per-region severity set, atomically saved with photos_ | **Holds, with one loss.** The local write stays atomic; atomic *arrival* on another device does not survive mirroring. §5.2, §12.4. |
| [INV-7](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-7) | _Calm regions persist as positive evidence_ | **Holds unchanged.** The defining rule of this screen. §3, §6.1. |
| [INV-8](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-8) | _`id` and `createdAt` immutable across edit, delete, undo_ | **Holds unchanged**, and is load-bearing beyond this screen — [#687](https://github.com/jirigrill/eczema-helper/issues/687)'s forced re-save depends on it. §7.2, §8.4. |
| [INV-9](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-9) | _Photos unencrypted at rest_ | **Void for iOS.** Superseded by [#693](https://github.com/jirigrill/eczema-helper/issues/693) / [#714](https://github.com/jirigrill/eczema-helper/issues/714). |
| [INV-10](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-10) | _Dexie/IndexedDB, normalized tables_ | **Void for iOS.** Replaced wholesale by SwiftData. |
| [INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11) | _The app is a Logging Tool_ | **Holds**, and governs §6.4 and §12.2 — the regulatory framing. |
| [INV-12](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-12) | _Records carry types, not display strings_ | **Holds**, and is tightened: §2.1 forbids the `MealItem.name` mistake reaching `SkinPhoto`. |

`CONTEXT.md` also holds roughly fifteen invariant-shaped rules **unnumbered**, in glossary
prose. Two bear on this screen and are cited by heading rather than id: _SkinObservation_ and
_Active region_ (both under § _Assessment & Observation_). Where one of them is ambiguous, this
document resolves it and says so (§12.1).

### Divergences from the PWA

This is not a 1:1 port. Per [#690](https://github.com/jirigrill/eczema-helper/issues/690),
**coherence is presumed right**: where the reference implementation does two different things,
the port picks the coherent rule, and *keeping* a wart is what needs a named reason.

Every divergence in this document is marked inline as **⚠ Divergence** with (a) what the PWA
does, (b) what the iOS app does, and (c) why. There are fifteen. They are the interesting part
of the document and are indexed in §10.

---
## 1. Vocabulary

| Term | Meaning |
| --- | --- |
| **Observation** | One record of how the skin looked, at one moment. Holds all nine regions, an optional note, and zero or more photos. |
| **Region** | One of nine fixed body areas (§2.2). The set is closed and ordered. |
| **Level** | A region's severity on a four-step absolute scale: `Calm`, `Mild`, `Moderate`, `Severe` (§2.3). |
| **Witnessed** | Spec-only term: the mother *looked*. Every save witnesses all nine regions, whether or not she touched them. Never a UI string ([#677](https://github.com/jirigrill/eczema-helper/issues/677)). |
| **Active region** | The region currently selected for tap-to-cycle. Interface state only — never persisted. (`CONTEXT.md` § _Active region_.) |
| **Compose** | A visit that will create a new observation. |
| **Edit** | A visit that will modify an existing one, identified by its id. |
| **Dirty** | An edit visit whose live state differs from what was loaded (§4.3). |

Three terms this section uses are shared with other areas and defined in
[`GLOSSARY.md`](GLOSSARY.md): **undoable action** (specified here in §8.1, owned by no screen),
**pending work** (§8.2 states what it means for this screen), and the **photo viewer** (specified
here in §5.5, reached from this screen's gallery and from the day view's grid).

### 1.1 Fixed at entry

The **date** is bound when the screen opens and cannot change during the visit. The **mode**
(compose or edit) is likewise fixed: it is compose when no observation id is supplied, edit
when one is.

**`SKIN-ENTRY-1` (MUST)** — The entry point supplies a date, an optional observation id, and a
return destination. A missing date means today. A missing return destination means the day view
for the resolved date.

**`SKIN-ENTRY-2` (MUST)** — A supplied date that is not a valid calendar date is not honoured.
The screen resolves to today and corrects the destination, rather than writing a record
carrying an uninterpretable date.

> **⚠ Divergence 1.** *PWA:* the date parameter is read raw and written straight onto the
> record, so a malformed value produces a row invisible to every date query and to
> date-ordering. The day view, given the same value, does redirect — but its guard is
> **shape-only**: `isIsoDate` is a `^\d{4}-\d{2}-\d{2}$` regex (`src/lib/utils/date.ts:39-48`),
> so `2026-02-31` passes it (pinned by `date.test.ts:188`) and reaches `resolveDay` as a valid
> day. Neither entry point checks that the date *exists*. *iOS:* validate at both entry points
> identically, and validate the **calendar date**, not its shape. *Why:* two rules for one
> concept, and the incoherent one silently corrupts data; the shape check is the weaker half of
> a rule this section states as calendar validity. Coherence default applies.

**`SKIN-ENTRY-3` (MUST)** — In edit mode, an observation id that names no existing observation
returns the mother to the destination without opening the editor. She is never shown an empty
form claiming to be editing something.

**`SKIN-ENTRY-4` (MUST)** — Existence is decided by **awaiting the read**, never by a timer. The
app fetches the observation by id and waits for a definite answer; only a completed read that
found nothing sends her back (`SKIN-ENTRY-3`). No elapsed-time threshold participates in the
decision.

**`SKIN-ENTRY-5` (MUST)** — While that read is in flight the screen shows a loading state, not an
empty form. A pending read is never rendered as an observation with nine calm regions.

> **⚠ Divergence 14.** *PWA:* waits a fixed **500 ms** for its reactive query to emit, then
> bounces — so a slow cold start silently rejects a **valid** id and returns her to the day view
> with no explanation. *iOS:* await the read; accept a brief loading state instead. *Why:* being
> wrong about whether her record exists is far worse than a spinner, and this screen is opened
> one-handed while holding a baby, so a spurious bounce costs a re-navigation. The timer is also
> untestable as behavior — a test could only assert a timing threshold, never the rule.

---

## 2. The record

### 2.1 Shape

An observation holds:

| Field | Type | Notes |
| --- | --- | --- |
| id | stable unique id | Immutable. Minted by the app, not derived from content (INV-8). |
| date | calendar date | Day granularity, no time component. |
| createdAt | timestamp | The **witnessing moment** — when she looked. See §7.2. |
| regions | exactly nine region/level pairs | Never fewer (§3.1). |
| notes | optional text | Absent, not empty, when she typed nothing (§6.3). |

A photo holds:

| Field | Type | Notes |
| --- | --- | --- |
| id | stable unique id | Preserved verbatim across delete-and-undo (§8.4). |
| observationId | reference to the parent | Required. A photo cannot exist without one. |
| region | region id | Which region it depicts (§5.1). |
| capturedAt | timestamp | See `SKIN-PHOTO-6`. |
| image data | the bytes | Record shape is **OPEN** — [#684](https://github.com/jirigrill/eczema-helper/issues/684) deferred the pixel/quality targets; whether size, format or dimensions are *recorded fields* is a schema-deadline question on the map's SwiftData fog. |

**`SKIN-REC-1` (MUST NOT)** — No field on either record holds display text. Region and level
are stored as their identifiers; the human-readable label is resolved for presentation only
(INV-12). The reference implementation violated this on the *meal* side, persisting Czech
labels onto records and feeding them into a comparison key; that mistake must not reach here.

**`SKIN-REC-2` (MUST)** — A photo carries no date of its own. Its day is its parent
observation's date.

**`SKIN-REC-3` (SHOULD)** — `capturedAt` records when the image was captured, per photo.

> **⚠ Divergence 2.** *PWA:* every photo in one save shares an identical timestamp, computed
> once at *write* time — so the field named "captured at" records when she tapped save, not
> when the shutter fired, and a batch of five is indistinguishable in time. *iOS:* take the
> capture time from the image's own metadata where available, falling back to write time.
> *Why:* the field name states a promise the implementation does not keep, and on iOS the
> metadata is available where the web file input gave nothing. Only the fallback is a
> divergence in behavior; the rest is a capability the platform adds.

### 2.2 The regions

Nine, closed, ordered. The order is canonical and drives presentation order everywhere.

| # | Id | English label |
| --- | --- | --- |
| 1 | `face` | Face |
| 2 | `scalp` | Scalp |
| 3 | `neck` | Neck |
| 4 | `belly` | Belly |
| 5 | `back` | Back |
| 6 | `arms` | Arms |
| 7 | `elbow-folds` | Elbow folds |
| 8 | `knee-folds` | Knee folds |
| 9 | `legs` | Legs |

**`SKIN-REG-1` (MUST)** — The region set is fixed at nine. Adding a region is a schema change
and a spec change, not configuration.

**`SKIN-REG-2` (MUST)** — Region ids are the identifiers above, unchanged from the reference
implementation. They were already English ([#677](https://github.com/jirigrill/eczema-helper/issues/677)),
so nothing is renamed here.

**`SKIN-REG-3` (MUST)** — Wherever regions are listed — the grid, saved records, chips on the
day view — they appear in the canonical order above, regardless of the order the mother touched
them or the order storage returns.

### 2.3 The levels

Four, absolute, ordered.

| Value | Label | Meaning |
| --- | --- | --- |
| 0 | `Calm` | No visible problem. **The explicit default**, not "unknown". |
| 1 | `Mild` | |
| 2 | `Moderate` | |
| 3 | `Severe` | |

**`SKIN-LVL-1` (MUST)** — The scale is absolute, not relative to a previous observation. `Mild`
means mild, not "milder than yesterday".

**`SKIN-LVL-2` (MUST)** — There is no "unknown" or "not checked" level. A region the mother
never touched is `Calm` (§3.1). This is the whole point of INV-7 and the reason the app can
distinguish "checked, all calm" from "didn't check".

**`SKIN-LVL-3` (MUST)** — Level labels are `Calm` / `Mild` / `Moderate` / `Severe`, settled by
[#677](https://github.com/jirigrill/eczema-helper/issues/677). *Witnessed* is spec vocabulary
and never appears in the interface.

### 2.4 Many observations per day

**`SKIN-REC-4` (MUST)** — A day may hold any number of observations. Each visit in compose mode
creates a new one; morning and evening are two records, each with its own `createdAt`.

**`SKIN-REC-5` (MUST)** — Observations are never merged, and a second observation on a day does
not supersede the first. The day view lists each one as its own timestamped entry.

**`SKIN-REC-6` (MUST NOT)** — There is no uniqueness constraint on (date) or on
(date, anything). Unlike a meal — which occupies exactly one (date, meal type, actor) slot —
an observation is a free-standing event.

This last point matters for the port in a way it did not for the PWA: because observations
have no natural key, the duplicate-record hazard that
[#691](https://github.com/jirigrill/eczema-helper/issues/691) found for meals under sync
**does not arise here**. Two devices creating two observations is not a conflict; it is two
observations. There is nothing to deduplicate and no tiebreak attribute needed.

---
## 3. Witnessing all nine

The rule that defines this screen.

**`SKIN-WIT-1` (MUST)** — Every save writes **all nine** regions, each with an explicit level.
A region the mother never touched is written at `Calm`. The record never holds a subset.

**`SKIN-WIT-2` (MUST)** — The absence of any observation for a day means **"she did not look"**.
An observation with all nine regions at `Calm` means **"she looked, and everything was calm"**.
These are different facts and the app must be able to distinguish them.

**`SKIN-WIT-3` (MUST)** — In compose mode the save action is **always available**, from the
moment the screen opens, with nothing touched. Opening the screen and saving immediately is a
legitimate, meaningful act — it records a witnessed all-calm day.

**`SKIN-WIT-4` (MUST)** — Saving a freshly-opened compose screen writes nine regions at `Calm`,
no note, and no photos.

These four rules are the reason `Calm` is a level rather than the absence of one, and they are
worth defending in review: a future contributor optimising away "pointless" all-calm saves would
delete the app's ability to record the most common day.

---

## 4. Visit state

### 4.1 Compose vs edit

**`SKIN-VIS-1` (MUST)** — Mode is decided at entry by the presence of an observation id and
never changes during the visit — with exactly one exception, the post-delete undo (§8.4), which
re-enters edit mode from the undoable action rather than from storage.

### 4.2 Loading an edit

**`SKIN-VIS-2` (MUST)** — Opening an edit populates the nine levels, the note, and the gallery
from the stored observation, then records a **load snapshot** of that state for the dirty
comparison (§4.3).

**`SKIN-VIS-3` (MUST)** — Edit-only controls (the overflow menu carrying delete) appear only
once a load has completed. A still-loading edit, and an unknown id on its way to bouncing, show
no delete affordance.

**`SKIN-VIS-4` (MUST)** — If the stored photos cannot be read, the visit does not silently
present the observation as photo-less.

> **⚠ Divergence 3.** *PWA:* a failed photo read yields an empty gallery with no signal. Benign
> on save (the photos survive, since only explicit removals are sent) but **destructive on
> delete**: the undo snapshot captures the empty list, so undoing a delete permanently loses
> photos that merely failed to load. *iOS:* surface the failure and disable delete while photo
> state is unknown. *Why:* a silent read failure that becomes permanent data loss one tap later
> is a defect, not a behavior.

### 4.3 Dirtiness

**`SKIN-VIS-5` (MUST)** — An edit visit is **dirty** when any of the following differs from the
load snapshot: any region's level, the note (compared trimmed), the set of newly staged photos,
or the set of photos marked for removal.

**`SKIN-VIS-6` (MUST)** — In edit mode the save action is available only when dirty. A clean
edit has nothing to write and the back affordance is the correct exit.

**`SKIN-VIS-7` (MUST)** — Compose mode has no dirty gate. `SKIN-WIT-3` governs instead.

Note the asymmetry is intentional and not a divergence: compose can always save because an
all-calm save is meaningful; edit cannot save an unchanged record because re-writing it would
be a no-op that touches the update timestamp.

---

## 5. Photos

### 5.1 Attaching

**`SKIN-PHOTO-1` (MUST)** — A photo is attached **to a region**, not to the observation at
large. The region is whichever is active when the photo is added.

**`SKIN-PHOTO-2` (MUST)** — Adding a photo requires an active region. With none selected, the
add-photo affordance is present but inert, and states what is needed rather than simply being
disabled.

**`SKIN-PHOTO-3` (MUST)** — Any number of photos may be attached to any region, and to any
number of regions, in one observation. There is no cap.

**`SKIN-PHOTO-4` (MUST)** — A photo may be attached to a region at `Calm`. Photographing skin
that looks fine is legitimate, and doing so does not change the region's level.

**`SKIN-PHOTO-5` (MUST)** — Photos staged during a visit are not written until the observation
is saved. Leaving without saving discards them, subject to §8.

**`SKIN-PHOTO-6` (SHOULD)** — See `SKIN-REC-3` for `capturedAt`.

**`SKIN-PHOTO-7` (MUST)** — Adding a photo offers **the camera first, with the photo library
reachable in one further tap**. Both sources are available; neither is forced.

> **⚠ Divergence 15.** *PWA:* opens the OS picker first, so reaching the camera costs an extra
> tap. *iOS:* camera first, library one tap away. *Why:* the owner's call. The dominant case is
> photographing the skin she is looking at as she logs it; the PWA's order inverts that for no
> stated reason, and the web file input gave it little choice.

**`SKIN-PHOTO-22` (MUST)** — A photo attached from the library is indistinguishable from a
captured one once attached. The source is not recorded on the record and does not affect any
later behavior.

**`SKIN-PHOTO-23` (MUST NOT)** — `capturedAt` is never clamped or rewritten to fall inside the
observation's day. A library photo taken three weeks ago keeps its own capture time on an
observation created today; the two fields answer different questions (`SKIN-REC-3`, INV-8's
witnessing-moment reasoning) and disagreeing is the correct outcome, not a bug to fix.

Camera-first matches the dominant case — she is looking at the skin as she logs it. The library
must stay reachable because attaching an earlier photo is a real need, not an edge case: the light
was better an hour ago, or the baby was still. The reference implementation offers the OS picker
first, which inverts the common case for no stated reason.

### 5.2 Atomicity

**`SKIN-PHOTO-8` (MUST)** — An observation and its photos are written **together**. A save
either lands with all its photos or does not land at all. No observation is ever visible without
the photos saved alongside it, and no photo exists without its parent.

**`SKIN-PHOTO-9` (MUST)** — On another device, the same guarantee does **not** hold on arrival.
Mirroring may deliver a parent without its children, or children before their parent, in
indeterminate order. Both are legitimate transient states and the app must render them without
error — an observation whose photos have not arrived shows as an observation with no photos yet,
never as a failure.

**`SKIN-PHOTO-10` (MUST)** — Orphan cleanup — a photo whose parent will never arrive because it
was deleted elsewhere — runs as an idempotent, order-independent sweep, safe to re-run on every
launch. It must not assume a transaction it does not have.

> **⚠ Divergence 4.** *PWA:* atomicity is a storage guarantee — one multi-table transaction.
> *iOS:* the local write stays atomic within a single save; cross-device atomic arrival is
> **lost** and replaced by the sweep above. *Why:* not a choice — mirroring provides no batch
> atomicity ([#679](https://github.com/jirigrill/eczema-helper/issues/679),
> [#691](https://github.com/jirigrill/eczema-helper/issues/691)). This is the one place INV-6
> genuinely weakens, and it is recorded rather than papered over.

### 5.3 Removing

**`SKIN-PHOTO-11` (MUST)** — Removing a *staged* photo — one added this visit, not yet saved —
removes it immediately and completely. There is nothing to undo because nothing was written.

**`SKIN-PHOTO-12` (MUST)** — Removing a *stored* photo during an edit marks it for removal and
shows it as marked, with an undo affordance, rather than removing it from view. The removal
takes effect on save.

**`SKIN-PHOTO-13` (MUST)** — Un-marking a photo marked for removal restores it fully, and the
observation is dirty or clean according to §4.3 as though it had never been marked.

**`SKIN-PHOTO-14` (MUST)** — A save carries both additions and removals; either may be empty.

**`SKIN-PHOTO-15` (MUST)** — Deleting an observation deletes all its photos. The cascade is the
application's responsibility, not storage's — it always was, and under mirroring there is no
transaction around it (`SKIN-PHOTO-10`).

**`SKIN-PHOTO-16` (MUST)** — Photo identity is preserved across a marked-then-unmarked cycle and
across delete-and-undo (§8.4). A photo that survives a round trip is the *same* photo, not a
copy with a new id.

### 5.4 Sharing to the camera roll

**`SKIN-PHOTO-17` (PWA)** — After a successful save, the reference implementation offers newly
captured photos to the OS share sheet so the mother can save them to her photo library with one
tap. Best-effort: silently does nothing where unsupported, and silently absorbs a cancel.

**`SKIN-PHOTO-18` (MUST)** — iOS keeps this. After a successful save, newly captured photos are
offered to the system share sheet so the mother can save them to her photo library.

**`SKIN-PHOTO-19` (MUST)** — The offer is **best-effort and never blocking**: a cancel, a refusal,
or a denied Photos permission leaves the save already committed and the observation unchanged.
Saving to the library is never a precondition for recording.

**`SKIN-PHOTO-20` (MUST)** — The app requests Photos access only at the point the mother first
takes this action, never at launch and never during first run, and the permission string names
what is being saved.

**`SKIN-PHOTO-21` (MUST NOT)** — Nothing is written to the photo library without the mother
having asked for it in that moment. There is no setting that makes it automatic, and no silent
background copy.

> **⚠ Divergence 12.** *PWA:* offers newly captured photos to the share sheet as a **durability
> workaround** — browser storage is opaque and fragile, so a copy in Photos was insurance against
> losing the originals. *iOS:* the behavior is kept, but the reason is different — the app's own
> store is durable and syncs, so this is now about the mother *reaching* her photos, not about not
> losing them. *Why:* the owner's call. A mother showing a dermatologist reaches for Photos, not
> for this app, and with export declined ([#683](https://github.com/jirigrill/eczema-helper/issues/683))
> this is the only route an image can leave.

Worth stating plainly, because it is the app's largest deliberate privacy concession: **this is
the one path by which infant medical photographs leave the app's boundary.** The photo library
syncs to iCloud Photos, is readable by any app the mother grants library access, and appears in
shared albums and Memories — none of which this app controls or can revoke. The decision was made
knowingly, on the grounds that an unreachable photo is not much use to a mother in a
dermatologist's office. Three consequences follow and are not optional: the Photos usage
description is user-facing text that must not overstate ([#709](https://github.com/jirigrill/eczema-helper/issues/709)),
the App Store privacy labels must declare it, and `SKIN-PHOTO-21` is what keeps the concession
narrow — a deliberate act each time, never a default. → §12.6

### 5.5 The photo viewer

The viewer is reached from **both** thumbnail surfaces — this screen's gallery and the day view's photo
grid ([`day-view.md`](day-view.md) `DAY-SKIN-11`) — and it is **one** surface, not two. The rules here
are the shared ones; each caller fixes only its own sequence. Settled by
[#740](https://github.com/jirigrill/eczema-helper/issues/740), which took both halves as one decision
because they are the same component and the same question.

**`SKIN-PHOTO-24` (MUST)** — Tapping a thumbnail on this screen opens the photo viewer, paging across
**this observation's** photos, in the gallery's own display order — stored photos then staged ones, exactly
as the gallery lays them out.

**The pager's order is always the order of the surface it was launched from.** That is the governing
principle, and it is why the two callers differ: the day view's grid is chronological across the day, this
gallery's is stored-then-staged within one observation. A pager that re-sorted — by capture time, say,
interleaving staged photos among stored ones — would disagree with the grid she just tapped, and would
need a capture instant that a staged library photo may not carry.

**`SKIN-PHOTO-25` (MUST)** — A photo marked for removal (`SKIN-PHOTO-12`) still opens, and is shown as
marked in the viewer.

`SKIN-PHOTO-12` deliberately keeps a marked photo **in view** rather than removing it, and the reason
extends here: opening one full-screen is a reasonable way to decide whether she meant to remove it. A
marked photo she cannot inspect is a decision she has to make from a thumbnail.

**`SKIN-PHOTO-26` (MUST)** — The viewer shows the photo's caption on open — the region, and for the day
view's grid the parent observation's time (`DAY-SKIN-7`) — and a tap hides it. A further tap restores it.
The dismiss control lives in that same chrome and hides with it.

`DAY-SKIN-7` makes the caption **required** in the grid, on the grounds that it is the only thing
re-attaching a photo to the record it came from once the grid has separated them. Full-screen that
argument is stronger, not weaker: the surrounding grid is gone, so nothing else says which region or which
check this is. Hence shown on open rather than hidden by default.

Hiding is offered for the one legitimate reason to want it: at full screen the caption's scrim covers part
of the image, and the image is the evidence. That is not true at thumbnail size, which is why the grid's
caption is unconditional and the viewer's is not.

**`SKIN-PHOTO-27` (MUST)** — The viewer is dismissed by a downward swipe, available whether or not the
chrome is showing, **and** by an explicit control in the chrome.

The swipe is what the platform's own photo viewers train, and it does not collide with the pager's
horizontal axis. The explicit control is the accessibility half: a gesture-only dismissal is unreachable
for anyone who cannot perform it, and this screen is used one-handed while holding a baby — the same
premise `SKIN-INT-2` reasons from. Keeping the swipe available with chrome hidden is what makes hiding the
chrome safe.

**`SKIN-PHOTO-28` (MUST)** — The viewer supports pinch-to-zoom.

This is a product requirement rather than a convenience. The thing lossy compression destroys first is
fine texture — scale, papules, lichenification — and texture is what separates a `Moderate` region from a
`Severe` one. A viewer she cannot zoom cannot answer the question she opened it to ask.

**`SKIN-PHOTO-29` (MUST)** — Paging **stops** at the first and last photo of the sequence. It does not
wrap.

Wrapping a chronological sequence would jump from the day's last photo to its first with nothing marking
that it happened. With `DAY-SKIN-11b` removing any position indicator, the resistance at the end is the
**only** signal she has that there is nothing further — so the stop is load-bearing rather than
conventional.

**`SKIN-PHOTO-30` (MUST NOT)** — No photo can be deleted from the viewer. It offers no destructive action
of any kind.

Stated as a prohibition rather than left as an absence, following `DAY-SKIN-8a`'s precedent, because a
trash button is the obvious convenience for an implementer to add. Deletion stays where `SKIN-PHOTO-11`
and `SKIN-PHOTO-12` put it — on this screen's own thumbnails, with the mark-and-save flow — and
`DAY-SKIN-11c`'s edit route is how she gets there from the day view.

Two consequences this keeps: the **day view acquires no destructive action**, which would otherwise be its
first, and `DAY-ROOT-7`'s undo affordance needs no story for photo deletion performed outside an editor.

**`SKIN-PHOTO-31` (MUST NOT)** — The viewer offers no route into an editor **from this screen's gallery**.
The observation is already open; a control opening it would point at the screen underneath.

The day view's viewer *does* carry one (`DAY-SKIN-11c`) — the asymmetry is deliberate and is the only
behavioural difference between the two callers besides the sequence.

> **⚠ Divergence 16.** *PWA:* tapping a thumbnail in this screen's gallery opens the same single-photo
> lightbox the day view uses — one photo, no paging, no zoom (`SkinPhotoGallery.svelte:111`,
> `PhotoLightbox.svelte`). *iOS:* the shared viewer, paging across the observation's photos, with zoom.
> *Why:* settled by [#740](https://github.com/jirigrill/eczema-helper/issues/740) alongside the day
> view's half. Class: **resolved by #740**.

**What was unspecified before this section existed.** The PWA has *two* thumbnail surfaces feeding one
`PhotoLightbox`, and §5 previously specified attaching, atomicity, removal and sharing while never saying
what tapping a thumbnail does. So tap-to-enlarge on this screen was an unspecified reference behavior
rather than a settled one, and #740 closed it here rather than leaving a second `OPEN` behind.

**One rendition, and what that obliges.** There is no thumbnail tier: `persistence-model.md`
`DATA-PHOTO-2`/`-3` store one set of bytes per photo with its dimensions recorded. The viewer therefore
displays the same bytes the grid does, scaled up. The spec deliberately states **no** resolution
requirement — the pixel target is [#684](https://github.com/jirigrill/eczema-helper/issues/684)'s deferred
decision, to be measured on a device — but whoever settles it should know that **full-screen display is
now the binding fidelity case**, not the thumbnail: a target that reads well at 118 pt and falls apart at
full width fails `SKIN-PHOTO-28`'s purpose.

---
## 6. Interaction

### 6.1 The region grid

**`SKIN-INT-1` (MUST)** — All nine regions are visible at once, in canonical order, each showing
its current level.

**`SKIN-INT-2` (MUST)** — Tapping an **inactive** region makes it active and **does not change
its level**.

**`SKIN-INT-3` (MUST)** — Tapping the **active** region advances its level by one, wrapping
`Severe → Calm`. The full cycle is `Calm → Mild → Moderate → Severe → Calm`.

**`SKIN-INT-4` (MUST)** — Activating a different region leaves the previous region's level
exactly as it was. Levels are only ever changed by tapping an already-active region.

`SKIN-INT-2` and `SKIN-INT-3` together are the "activate first, then cycle" rule, and it exists
for a reason worth preserving: the screen is used one-handed while holding a baby, and a stray
tap must not silently record a severity the mother did not mean. The cost is one extra tap on the
first region she edits; the benefit is that no single mis-tap ever writes a wrong level.

**`SKIN-INT-5` (MUST)** — Cycling past `Severe` back to `Calm` is a normal, supported way to
retire a region. There is no separate "clear" action.

**`SKIN-INT-6` (MUST)** — Exactly one region is active at a time, or none. Activation is
interface state and is never saved.

### 6.2 What the grid shows

**`SKIN-INT-7` (MUST)** — Each region tile conveys its level non-verbally (the reference
implementation uses a severity colour ramp) **and** carries the level as text or an accessible
label. Colour is never the only channel.

**`SKIN-INT-8` (MUST)** — The active region is visually distinguished from the inactive ones, and
that distinction is independent of its level — an active `Calm` region and an active `Severe`
region are both legible as active.

**`SKIN-INT-9` (MUST)** — Active state is exposed to assistive technology as a selection state on
the tile.

> **⚠ Divergence 5.** *PWA:* the save button carries both a native disabled attribute and an
> ARIA disabled attribute. The native one removes the control from the accessibility tree, so the
> ARIA hint it was paired with can never be read — a screen-reader user hears nothing rather than
> "unavailable". *iOS:* one mechanism, and the control stays discoverable with its reason.
> *Why:* the pairing defeats its own purpose.

### 6.3 The note

**`SKIN-INT-10` (MUST)** — One free-text note per observation, optional, unstructured.

**`SKIN-INT-11` (MUST)** — A note that is empty or only whitespace is stored as **absent**, not
as an empty value. Trimmed before comparison and before storage.

**`SKIN-INT-12` (MUST)** — Editing the note dirties an edit visit (§4.3).

### 6.4 What the screen must not do

**`SKIN-INT-13` (MUST NOT)** — The screen offers no interpretation of what was recorded. No
guidance, no comparison to previous days, no suggestion of a cause, no summary judgement of the
skin's state.

**`SKIN-INT-14` (MUST NOT)** — No copy on this screen, or anywhere the observation is displayed,
frames the record as evidence *about* a food, a trigger, or a cause. She records what she sees;
reading the diary is her job and her doctor's (INV-11, and the map's recording-not-finding rule).

This is the regulatory boundary and it is narrower than it looks: the difference between a diary
and a regulated medical device is partly a matter of what the interface *claims*, and a
well-meant "looking better than yesterday" is a clinical inference the app is not entitled to
make.

---

## 7. Saving

### 7.1 Compose

**`SKIN-SAVE-1` (MUST)** — A compose save creates a new observation with a newly minted id, the
resolved date, `createdAt` set to now, nine regions, the trimmed note if any, and all staged
photos — written together (`SKIN-PHOTO-8`).

**`SKIN-SAVE-2` (MUST)** — On success the mother returns to the destination she came from.

### 7.2 Edit

**`SKIN-SAVE-3` (MUST)** — An edit save preserves the observation's **id** and **`createdAt`**
verbatim (INV-8). `createdAt` is the witnessing moment; correcting a typo or bumping a severity
does not retroactively change when she looked at the skin.

**`SKIN-SAVE-4` (MUST)** — An edit save replaces all nine region levels and the note, applies
staged photo additions and removals, and leaves every other field untouched.

**`SKIN-SAVE-5` (SHOULD)** — An edit records that it was updated, separately from `createdAt`, so
the two facts — when she looked, and when the record last changed — are both available.

**`SKIN-SAVE-6` (MUST)** — A restore following a delete-and-undo is **not** an edit. It
reinstates the original record, its id, its `createdAt`, and its photos with their original ids
(§8.4), and it does **not** record an update — nothing was updated; the record was put back.

### 7.3 Failure and double submission

**`SKIN-SAVE-7` (MUST)** — A failed save keeps the mother on the screen with her work intact,
and tells her it failed. It never navigates away.

**`SKIN-SAVE-8` (MUST)** — A failed save leaves storage unchanged — no partial observation, no
orphaned photos.

**`SKIN-SAVE-9` (MUST)** — The save action cannot be invoked twice concurrently. A second tap
while a save is in flight does nothing.

**`SKIN-SAVE-10` (MUST)** — Nothing that supersedes an undoable action is discarded until the
write that supersedes it has actually landed. A failed save or a failed delete leaves any
existing undo intact.

> **⚠ Divergence 6.** *PWA:* on the meal side, invalidation runs *before* the write is attempted,
> so a failed delete destroys a pre-existing undo. Stated here as a general rule because
> [#690](https://github.com/jirigrill/eczema-helper/issues/690) made it one — it applies to both
> the save and delete paths, on both screens.

### 7.4 Writing while iCloud is unavailable

**`SKIN-SAVE-11` (MUST)** — Saving is gated on the account states that make durability
impossible, and only those, per [#687](https://github.com/jirigrill/eczema-helper/issues/687).
Airplane mode, a basement, and a temporarily unreachable service are **not** gates: she logs
normally and the record uploads on reconnect.

**`SKIN-SAVE-12` (MUST)** — Existing observations remain **readable** in every degraded state.
The gate is on writing, never on reading.

**`SKIN-SAVE-13` (MUST)** — In a gated state the screen states the consequence concretely rather
than failing at the moment she taps save. Discovering a save is impossible after composing one is
the wrong order.

The full account-state model, the banner, and the sign-in transition belong to
[#687](https://github.com/jirigrill/eczema-helper/issues/687) and are not restated here.

---
## 8. Leaving, deleting, and undo

The messiest area in the reference implementation, and where most of the divergences land.

### 8.1 The undoable action

**`SKIN-UNDO-1` (MUST)** — There is **one** undoable action at a time, application-wide, shared
with the meal editor. Recording a new one destroys the previous.

**`SKIN-UNDO-2` (MUST)** — An undoable action knows what it reverses and where reversing it lands.
It is a single concept with a single implementation, not per-screen copies.

> **⚠ Divergence 7.** *PWA:* the routing logic exists in four places — the app shell, the meal
> screen, the meal editor overlay, and this screen's own copy — and they had already drifted apart
> (the meal screen's ownership test compares one component of the key; the shell builds its
> destination from three). *iOS:* one implementation. *Why:* per
> [#690](https://github.com/jirigrill/eczema-helper/issues/690), the duplication is *what let the
> rules drift*; fixing the rule without collapsing the sites leaves the mechanism in place. This
> screen's own version is already correct — it matches on observation id — but it shares the
> duplication.

**`SKIN-UNDO-3` (MUST)** — An undoable action belongs to a screen only if it identifies the same
record that screen is opening. A mismatched action is left alone, not adopted.

### 8.2 Leaving with unsaved work

The question this group answers is **pending work** ([`GLOSSARY.md`](GLOSSARY.md)) — would leaving
lose something she did? `SKIN-UNDO-6` states what counts as work on this screen.

**`SKIN-UNDO-4` (MUST)** — Leaving a **dirty edit** without saving records an undoable action
carrying the live state, so returning restores exactly what she had — levels, note, staged
additions, and pending removals — and the action is consumed on restoration.

**`SKIN-UNDO-5` (MUST)** — Leaving a **clean edit** records nothing. There was nothing to lose.

**`SKIN-UNDO-6` (MUST)** — Leaving a **compose visit with work in it** records an undoable action
on the same terms as `SKIN-UNDO-4`. "Work in it" means any region above `Calm`, any note text, or
any staged photo.

> **⚠ Divergence 8.** *PWA:* compose drafts are **never** buffered — the snapshot path returns
> early unless the visit is an edit. Backing out of a compose visit with nine bumped regions, a
> note and staged photos discards all of it with no toast, no confirmation, and no undo, while the
> identical loss during an *edit* is fully recoverable. The meal side has a compose descriptor; the
> skin side has no counterpart. *iOS:* compose and edit behave identically. *Why:* the asymmetry is
> undocumented, protects the cheaper case and abandons the expensive one, and is the same class of
> defect [#690](https://github.com/jirigrill/eczema-helper/issues/690) fixed for the meal editor.
> This is the largest behavioral divergence in this document.

**`SKIN-UNDO-7` (MUST)** — Exactly one undoable action is recorded per departure, whichever way
she leaves — an explicit back control or the system back gesture. Leaving must not record twice.

**`SKIN-UNDO-8` (MUST NOT)** — Departing must never *overwrite* a post-delete undo with an edit
snapshot. A record that no longer exists cannot be restored by an edit.

### 8.3 Deleting

**`SKIN-DEL-1` (MUST)** — Delete is available only in edit mode, only once loaded, and is not a
primary action — it sits behind a secondary affordance.

**`SKIN-DEL-2` (MUST)** — Delete requires an explicit confirmation, presented as destructive, and
that confirmation **states that the photos go too**.

**`SKIN-DEL-3` (MUST)** — Cancelling the confirmation changes nothing and navigates nowhere.

**`SKIN-DEL-4` (MUST)** — Delete is a **hard delete**. The observation and all its photos are
removed. There is no trash and no deleted-items view in v1
([#687](https://github.com/jirigrill/eczema-helper/issues/687) declined one explicitly).

**`SKIN-DEL-5` (MUST)** — The undoable action is captured **before** the delete is attempted, so
it exists even if she leaves during the transition — and per `SKIN-SAVE-10`, a failed delete
neither navigates nor destroys anything.

**`SKIN-DEL-6` (MUST)** — A failed delete leaves her on the screen, with the confirmation closed
and the record intact, and says so.

**`SKIN-DEL-7` (MUST)** — Deleting while the edit is dirty captures the **stored** record, not the
unsaved edits. Undo restores what was actually in storage; the pending edits are gone. This is
deliberate — undo reverses the delete, it does not resurrect an unsaved draft — and it is stated
because the reference implementation does it without saying so.

### 8.4 Undoing a delete

**`SKIN-DEL-8` (MUST)** — Undoing a delete restores the observation with its **original id and
`createdAt`** (INV-8) and its photos with their **original ids** (`SKIN-PHOTO-16`). It lands back
in its original position in the timeline, indistinguishable from never having been deleted.

**`SKIN-DEL-9` (MUST)** — Undo restores it to storage directly. She is not required to save again
for the record to survive.

> **⚠ Divergence 9.** *PWA:* undo restores a **draft**, not a row — the record is genuinely gone
> from storage and she must tap save again. Worse, the restored form is compared against an
> all-`Calm` empty snapshot, so if the deleted observation happened to be all-calm with no note and
> no photos, the form reads as *clean* and **save is disabled** — undo is impossible for exactly
> the "checked, all calm" record INV-7 exists to make first-class. *iOS:* undo writes. *Why:* a
> two-step undo that silently cannot complete for the app's most common record is a defect; and
> "undo" that requires a save to take effect is not what the word means.

**`SKIN-DEL-10` (MUST)** — After a successful restore, the undoable action is consumed.

### 8.5 What undo does not cover

**`SKIN-DEL-11` (PWA + iOS)** — The undoable action lives in memory only. It does not survive an
app restart, a discard by the system, or backgrounding long enough to be reclaimed. Once it is
gone, a hard-deleted observation is unrecoverable.

**`SKIN-DEL-11a` (MUST)** — The **offer** and the **undoable action** have different lifetimes, on
`MEAL-UNDO-13`'s rule: dismissing the offer, or letting it time out, hides the offer and does not
discard the action. The action is discarded when a newer one replaces it, when a restore consumes it
(`SKIN-DEL-10`), when she leaves the screen the offer was made on, or when `SKIN-DEL-11` takes it.
No timer discards it.

**`SKIN-DEL-12` (MUST)** — Copy about undo promises no more than this. It is honest about being
available *right after* deleting, and never implies a recoverable history.

Worth stating plainly, because it is the sharpest edge in the product: **v1 has no rollback**.
CloudKit is sync, not backup ([#683](https://github.com/jirigrill/eczema-helper/issues/683)) — a
delete propagates to every device, and neither the mother nor the developer can retrieve it. The
in-memory undo is the *only* recovery path for an accidental delete, and it is measured in
seconds — but not in the *five* seconds the reference allowed, which is what `SKIN-DEL-11a` and
`MEAL-UNDO-13` change. This was decided knowingly, against the recommendation, and the exposure was
accepted.

---
## 9. How the observation appears elsewhere

Stated here only where it constrains this screen; the day view gets its own section.

**`SKIN-VIEW-1` (MUST)** — The day view lists each observation for the day separately, ordered by
`createdAt` ascending, each showing its time.

**`SKIN-VIEW-2` (MUST)** — Each entry shows the regions **above** `Calm`, in canonical order
(`SKIN-REG-3`). An observation with no bumped regions is shown as an explicit all-calm entry —
never as an empty row, and never omitted.

**`SKIN-VIEW-3` (MUST)** — A day with no observations is distinguishable from a day with an
all-calm observation (`SKIN-WIT-2`), in the interface and not merely in the data.

**`SKIN-VIEW-4` (MUST)** — Tapping an entry opens this screen in edit mode for that observation,
returning to the day view on exit.

**`SKIN-VIEW-5` (MUST NOT)** — No single day-level severity is displayed anywhere. The day view
shows per-region levels per observation and never collapses them into one figure.

The reference implementation defines a day-overall severity as the maximum level across an
observation's regions, and INV-6 records it as derived-never-stored. **Nothing calls it.** The
function has no callers, no test, and no render site anywhere in the shipped app; the day view
shows per-region chips instead. So the rule described in INV-6 was, in practice, never
implemented — and this document declines to implement it.

The reason is regulatory, not cosmetic:
[#677](https://github.com/jirigrill/eczema-helper/issues/677) identified `max(regions)` as **the
regulatory surface** — collapsing nine observations into one severity figure is closer to
*assessing* the skin than to recording it, and the copy around such a figure is precisely where a
diary starts to read like an assessment (§6.4, INV-11). #677 accepted the level *names* as
clinically safe because the app records the mother's observation rather than asserting an
assessment; a derived day figure is exactly the case where that defence weakens, because no
observation the mother made says "today was Moderate".

> **⚠ Divergence 13.** *PWA:* `INV-6` describes a derived day-overall severity, and the code to
> compute it exists. *iOS:* the concept does not exist. *Why:* the owner's call. It was never
> displayed, so nothing is lost; it is the app's sharpest regulatory edge per #677; and it is
> free to reverse, since the value is derived and would need no stored field. INV-6 should stop
> describing it at the source (→ §12.2).

---

## 9a. Accessibility

This is the screen the accessibility block was invented for. It is a nine-tile grid whose entire
meaning is carried by a severity ramp, driven by a two-stage tap gesture, with a photo viewer behind
it dismissed by a swipe — every one of those is a place where a correct-looking screen is an unusable
one. §6.2 already carried three rules of this kind (`SKIN-INT-7`, `-8`, `-9`); they are the seed of
this block, not a substitute for it, and they stay where they are because they are also rules about
what the grid *shows*.

### 9a.1 The region grid

**`SKIN-A11Y-1` (MUST)** — Each region tile is **one** element to assistive technology, not a tile
plus a separate level. Its label is the region's English label (§2.2) and its value is the level's
label (§2.3) — "Elbow folds, Moderate". Focus order is the canonical order (`SKIN-REG-3`), the same
order the grid displays, never a layout-derived or storage-derived order.

**`SKIN-A11Y-2` (MUST)** — The tile's **trait** says it is a control that adjusts a value, and the
active region's selection state is exposed as required by `SKIN-INT-9`.

**`SKIN-A11Y-3` (MUST)** — The two-stage gesture (`SKIN-INT-2`, `SKIN-INT-3`) is reachable without
sight. Activating an inactive tile announces that it became active **and** that its level is
unchanged; advancing an active tile announces the new level. A user who cannot see the ramp must be
able to tell those two outcomes apart from the announcement alone, because they differ in whether
anything was recorded.

**`SKIN-A11Y-4` (MUST)** — The wrap from `Severe` to `Calm` (`SKIN-INT-5`) is announced as the level
it landed on. It is never announced as a reset, a clear, or a removal — it is the supported way to
retire a region, and copy that framed it as clearing would misdescribe what was written.

**`SKIN-A11Y-5` (SHOULD)** — Where the platform offers an adjustable-value gesture (increment and
decrement), the grid supports it in addition to the tap cycle. A cycle-only control forces someone
using it to step through three levels to go back one.

### 9a.2 The note, saving, and deleting

**`SKIN-A11Y-6` (MUST)** — The note field is labelled, and its optionality is part of the label or
hint rather than conveyed only by placeholder text. Placeholder text disappears on focus, which is
exactly when it would be read.

**`SKIN-A11Y-7` (MUST)** — When the save action is unavailable in edit mode (`SKIN-VIS-6`), it stays
**in** the accessibility tree with its unavailable state and the reason. This is Divergence 5's rule
stated positively: one disabled mechanism, discoverable, with the reason readable.

**`SKIN-A11Y-8` (MUST)** — A failed save or a failed delete (`SKIN-SAVE-7`, `SKIN-DEL-6`) is
**announced**, not shown only as a visual banner. She is still on the screen with her work intact and
nothing on the visual surface has changed position, so a user not watching the screen has no other
signal that the write did not land.

**`SKIN-A11Y-9` (MUST)** — The delete confirmation is announced as destructive, and the announcement
includes that the photos go too (`SKIN-DEL-2`). The photo clause is the substance of the warning, so
it cannot be the part that only the sighted read.

**`SKIN-A11Y-10` (MUST)** — The undo affordance is **reachable and announced** for as long as it is
available. `SKIN-DEL-11` makes the undoable action in-memory and short-lived, and it is the only
recovery path in the product (§8.5) — an undo that appears as a transient visual toast and is never
announced does not exist for a VoiceOver user, which would make the hard delete unconditional for
them.

### 9a.3 The photo viewer and the gallery

**`SKIN-A11Y-11` (MUST)** — A gallery thumbnail is announced with its region and its position in the
sequence, and a photo marked for removal (`SKIN-PHOTO-12`) announces that state — it is shown as
marked visually, and `SKIN-A11Y-14` forbids colour or opacity being the only channel for it.

**`SKIN-A11Y-12` (MUST)** — The viewer's dismissal has a control in the chrome, not only the downward
swipe. `SKIN-PHOTO-27` already requires this and gives the reason; it is repeated here because it is
the one place in the section where an accessibility requirement is already load-bearing for a
non-accessibility rule (it is what makes hiding the chrome safe).

**`SKIN-A11Y-13` (MUST)** — Paging position is announced on each page change, including the stop at
the first and last photo (`SKIN-PHOTO-29`). `DAY-SKIN-11b` removes the visual position indicator, so
the resistance at the end is the only sighted signal — and resistance is not perceptible at all
through assistive technology. Without the announcement the sequence has no discoverable end.

### 9a.4 The five questions

| # | Answer |
| --- | --- |
| 1 | **VoiceOver label and trait** — specified for every interactive element this section has: region tiles (`SKIN-A11Y-1`, `-2`), the note (`-6`), save (`-7`), delete and its confirmation (`-9`), undo (`-10`), thumbnails (`-11`), and the viewer's pager and dismissal (`-12`, `-13`). |
| 2 | **Dynamic Type** — region labels and level labels **must never truncate**: they are the record's entire content, and `Mild` clipped against `Moderate` is a misread severity, not a cosmetic loss. The nine-tile grid must therefore reflow — fewer tiles per row, or one per row — rather than hold its shape and clip. `SKIN-INT-1` requires all nine be visible at once, and at the largest sizes that is satisfied by scrolling the grid, not by abbreviating it. The note field grows; the photo grid may reduce to fewer, larger thumbnails. |
| 3 | **Colour alone** — this section's central case, already answered by `SKIN-INT-7` (level carried as text or an accessible label as well as the ramp) and `SKIN-INT-8` (active state distinguished independently of level). `SKIN-A11Y-14` closes the two the ramp rule missed. |
| 4 | **Focus order and grouping** — a region tile is one element, in canonical order (`SKIN-A11Y-1`). An observation entry in the day view is one element per `DAY-SKIN`'s rules; its region chips are its value, not nine separate stops. |
| 5 | **Reduce Motion** — this section specifies two transitions: the viewer's open and dismiss, and the pager. Under Reduce Motion both complete without a positional or scaling animation. Nothing about *what* is reachable changes — `SKIN-PHOTO-27`'s swipe and `SKIN-A11Y-12`'s control both remain. |

**`SKIN-A11Y-14` (MUST)** — Nothing in this section conveys meaning by colour, opacity, or position
alone. The three cases are the severity ramp (`SKIN-INT-7`), the active region (`SKIN-INT-8`), and a
photo marked for removal (`SKIN-PHOTO-12`); each carries a second channel that is text or an
accessibility value.

**`SKIN-A11Y-15` (MUST NOT)** — No label, hint, value or announcement on this screen frames the
record as evidence about a food, a trigger, or a cause, offers a comparison to a previous day, or
states a day-level severity. This is `SKIN-INT-13`, `SKIN-INT-14` and `SKIN-VIEW-5` bound to the
accessibility surface — the regulatory boundary §6.4 draws is drawn against what the interface
*claims*, and an announcement is a claim.

---

## 10. Divergence index

Every intentional departure from the reference implementation, in one place. This is the table a
reviewer reads to check the port did not drift by accident.

| # | § | What changes | Class |
| --- | --- | --- | --- |
| 1 | §1.1 | Calendar-date validation at both entry points; the day view's guard is shape-only and the editor has none | Defect fixed |
| 2 | §2.1 | `capturedAt` per photo, from capture metadata where available | Promise kept + platform capability |
| 3 | §4.2 | Photo-read failure surfaced; delete disabled while photo state unknown | Defect fixed (data loss) |
| 4 | §5.2 | Cross-device atomic arrival lost; idempotent orphan sweep replaces it | Forced by platform |
| 5 | §6.2 | One disabled mechanism, control stays discoverable | Accessibility defect fixed |
| 6 | §7.3 | Nothing invalidates an undo until the superseding write lands | Defect fixed |
| 7 | §8.1 | One undoable-action implementation, not four | Defect fixed (drift source) |
| 8 | §8.2 | Compose drafts buffered exactly as edits are | Defect fixed (largest) |
| 9 | §8.4 | Undo writes the record back rather than restoring a draft | Defect fixed (undo could be impossible) |
| 10 | §11 | Level labels `Calm`/`Mild`/`Moderate`/`Severe`; English throughout | Settled by [#677](https://github.com/jirigrill/eczema-helper/issues/677) |
| 11 | §11 | No destructive migration, ever | Settled — the PWA wiped rows in four upgrade hooks |
| 12 | §5.4 | Camera-roll sharing kept, but as reach rather than durability | Owner's call — privacy concession accepted |
| 13 | §9.5 | No day-level severity exists at all | Owner's call — retires #677's regulatory surface |
| 14 | §1.1 | Existence decided by awaiting the read, not a 500 ms timer | Defect fixed (silent false negative) |
| 15 | §5.1 | Camera offered first; library one tap away | Owner's call — inverts the PWA's order |
| 16 | §5.5 | A paging, zoomable photo viewer replaces the single-photo lightbox | Resolved by [#740](https://github.com/jirigrill/eczema-helper/issues/740) |
| 17 | §8.5 | An undo offer's disappearance hides the offer without discarding the undoable action | Owner's call — [#772](https://github.com/jirigrill/eczema-helper/issues/772) |
| 18 | Appendix A | Five absences become numbered prohibitions (`SKIN-ABSENT-1`..`-5`) rather than features that merely do not exist | Settled by [#772](https://github.com/jirigrill/eczema-helper/issues/772) |

Nine of the seventeen are the coherence default from
[#690](https://github.com/jirigrill/eczema-helper/issues/690) doing its work: in each case the
reference implementation did two different things and this document picks one. None of them was
kept as a wart, so no named reasons are needed — which is itself the finding.

Divergences 12–15 are different in kind: all four are **owner decisions on questions this
document originally recorded as OPEN**, and they do not pull the same way. 13 removes the app's
sharpest regulatory edge; 12 knowingly accepts its largest privacy concession, against the
recommendation, because an unreachable photo does not help a mother in a consulting room; 14 trades
a spinner for correctness about whether her record exists; 15 reorders a picker to match the case
that actually happens. Each was decided with its trade named. **No OPEN rules remain.**

Divergence 16 arrived later and belongs with 12 and 15 as an owner's call made against a
recommendation — but it differs from every other entry in one way worth stating: it does not resolve
anything this document had recorded as open. §5 specified attaching, atomicity, removal and sharing
and **never said what tapping a thumbnail does**, so this was an unspecified reference behavior
rather than a question anyone had asked. It closed here because
[#740](https://github.com/jirigrill/eczema-helper/issues/740) settled the day view's half and the two
surfaces share one component; splitting them would have invited them to diverge for no reason.

Divergence 17 is the same shape as 16 — an unspecified reference behavior rather than a question
anyone had asked — found by [#772](https://github.com/jirigrill/eczema-helper/issues/772)'s coverage
sweep. §8 specified what the undo offer restores, what consumes it and what it cannot survive, and
never said what the offer's own *disappearance* does to the action behind it. The reference's answer
was that it destroys it. The rule now lives in `meal-editor.md` (`MEAL-UNDO-13`, `-14`) because both
screens share one buffer concept, and `SKIN-DEL-11a` cites it rather than restating it.

**Divergence 18 changes no behaviour**, and is listed so a reviewer checking for drift finds it: the
reference has none of the five surfaces `SKIN-ABSENT-1`..`-5` forbid, and neither does the port. What
changed is that the absences now have ids and reach §11 as checks, instead of existing only as the fact
that nobody built them.

---

## 11. Where each rule is verified today

For a port translating the existing tests rather than writing fresh ones. Paths are in the frozen
repo at `582f662`.

| Area | Current verification | Translate? |
| --- | --- | --- |
| §2.2 regions, §2.3 levels | `src/lib/domain/models.ts` types + `strings/skin-regions.ts` `satisfies` clause | **Types, not tests.** Re-express as a Swift enum — the compiler carries it. |
| §3 witnessing all nine | `src/routes/skin/page.test.ts:190`, `:215` | Yes — the two most important tests in the file. |
| §6.1 activate-then-cycle | `page.test.ts:124`, `:140`, `:167` | Yes, directly. |
| §4.3 dirtiness, §4.2 load | `page.test.ts:700`, `:725`, `:740` | Yes, with a storage double. |
| §5 photos | `page.test.ts:528`–`:938` (14 tests) | Mostly — they are label-driven, so re-derive the assertions from this document. |
| §7 saving | `page.test.ts:246`–`:413` | Yes, with a storage double. |
| §8 delete + undo | `page.test.ts:1022`–`:1288` | **Re-derive.** Divergences 8 and 9 change what the answer should be. |
| §5.2 atomicity | `dexie-skin-observation-repository` tests | **Do not translate** — asserts a transaction iOS does not have. Replace with `SKIN-PHOTO-9`/`-10` tests. |
| §9 day view | `src/routes/day/[date]/page.test.ts`, `SkinObservationCard` | Partly; §9 gets its own section. |
| §5.5 the photo viewer | `SkinPhotoCard.test.ts:159-208` and the gallery's own lightbox tests — open, `×` close, backdrop close | **Do not translate.** All three pin the single-photo lightbox Divergence 16 replaces; the backdrop-close test in particular asserts a mechanism (`SKIN-PHOTO-27` swaps it for a swipe) that no longer exists. Re-derive entirely. |
| Appendix A `SKIN-ABSENT-1`..`-5` | nothing asserts any of them; the nearest is the `accept="image/*"` attribute itself (`src/routes/skin/+page.svelte:545`) | **Re-derive** as absence checks. Two are worth writing: `-2` (no field on this screen records a treatment, cream or bath) and `-3` (no field, prompt or announcement asks for or infers a cause), because both are the additions a well-meaning implementer makes and both reverse `DECISIONS.md` §5. `-1` is carried by the picker's media type, and `-4` is already asserted via `SKIN-VIEW-5`'s guards. `-5` needs no test — it is the absence of a whole subsystem. |
| §9a accessibility | `SKIN-INT-7`/`-8`/`-9` have no test; `page.test.ts` queries by accessible role and label throughout, which exercises labels **incidentally** without asserting any of them | **Re-derive, all of it.** The label-driven queries are the closest thing to coverage and they are not coverage: a test that finds a button by its name fails if the name changes, but never fails if the name is wrong, missing a value, or leaking something `SKIN-A11Y-15` forbids. |

**Rules nothing verifies today.** Worth stating, because these are where a port inherits
ambiguity if it assumes test coverage equals specification:

- **`SKIN-ENTRY-2`** — nothing tests calendar validity anywhere. `date.test.ts:188` asserts the
  *opposite* for the day view's guard (`expect(isIsoDate('2026-02-31')).toBe(true)`), documenting the
  shape-only check as intended, and the skin editor never validates at all. Divergence 1 is therefore
  a **re-derive**, and the assertion worth writing first is that `2026-02-31` is rejected — the case
  both halves of the reference accept.
- **`SKIN-UNDO-7`** — the system-back-gesture path has no test at all; the reference
  implementation's "exactly one write per departure" claim rests on an untested assumption.
- **`SKIN-DEL-7`** — delete-while-dirty is undocumented and untested.
- **`SKIN-DEL-9`/`-11`** — no test covers losing the undo, and the all-calm undo-impossible case
  (Divergence 9) is asserted nowhere.
- **`SKIN-VIS-4`** — photo-read failure is unhandled and untested.
- **`SKIN-PHOTO-16`** — one test acknowledges in a comment that it *cannot* verify the image
  survives its round trip in the test environment, and checks only that a value is present. The
  one property that matters is asserted nowhere.
- **Everything in §5.5 beyond opening and closing.** The reference has no pager, no zoom, no chrome
  toggle and no swipe dismissal, so `SKIN-PHOTO-24`..`-29` have no reference equivalent at all. Three
  are prohibitions worth writing as regression guards: nothing deletes from the viewer
  (`SKIN-PHOTO-30`), no editor route from the gallery's viewer (`SKIN-PHOTO-31`), and — the guard that
  keeps a reasonable feature from creeping back — no position or extent indicator anywhere in it
  (`DAY-SKIN-11b`).
- **Every rule in §9a.** The reference asserts nothing about the accessibility surface, and two of the
  gaps are consequential rather than cosmetic. `SKIN-A11Y-3`: the reference's activate-then-cycle
  gesture announces nothing distinguishing "became active" from "level advanced", so a
  non-sighted user cannot tell whether a tap recorded a severity. `SKIN-A11Y-10`: nothing verifies the
  undo affordance is announced at all, and it is the product's only recovery path from a hard delete.

### 11.1 Acceptance pass

The owner cannot review Swift, so these are the behavioral checks that stand in for a code review
of this screen. Each maps to rules above; each is a thing to *do* on a device, in order.

1. Open the screen on a fresh day, touch nothing, save. The day view shows an all-calm entry with
   a time. → `SKIN-WIT-3`, `SKIN-WIT-4`, `SKIN-VIEW-2`
2. Open it again the same day, bump one region, save. The day now shows **two** entries. →
   `SKIN-REC-4`, `SKIN-REC-5`
3. Tap a region once — nothing changes but selection. Tap it four more times — it walks through
   the three severities and returns to calm. → `SKIN-INT-2`, `SKIN-INT-3`, `SKIN-INT-5`
4. Bump one region, then tap a different region. The first keeps its level. → `SKIN-INT-4`
5. With no region selected, the add-photo control tells you to pick a region. Select one; it
   becomes usable and names the region. → `SKIN-PHOTO-2`
6. Attach two photos to a calm region and save. Both are there; the region is still calm. →
   `SKIN-PHOTO-4`
7. Open a saved observation. Save is unavailable until you change something. → `SKIN-VIS-6`
8. Change a note, leave without saving, come straight back. Your text is there. → `SKIN-UNDO-4`
9. **Compose** a new observation with several regions bumped, leave without saving, come back.
   Your work is there. → `SKIN-UNDO-6` *(this fails on the PWA — Divergence 8)*
10. Edit an observation, delete it, undo. It is back, in its original timeline position, with its
    photos. → `SKIN-DEL-8`, `SKIN-DEL-9`
11. Do the same with an **all-calm** observation with no note and no photos. It comes back. →
    Divergence 9 *(this fails on the PWA)*
12. Turn on airplane mode. You can still log, and still read everything. → `SKIN-SAVE-11`,
    `SKIN-SAVE-12`
13. Sign out of iCloud. You can still read; the screen tells you why you cannot log. →
    `SKIN-SAVE-13`
14. Attach a photo and save. You are offered the chance to save it to your photo library, and the
    permission prompt appears **now** — not at launch. Decline it. The observation and its photo
    are unaffected. → `SKIN-PHOTO-18`, `SKIN-PHOTO-19`, `SKIN-PHOTO-20`
15. Save a further observation with a photo. Nothing reaches the photo library unless you ask for
    it in that moment. → `SKIN-PHOTO-21`
16. Look at any day with several observations. Nowhere is there a single severity figure for the
    day. → `SKIN-VIEW-5` *(this is Divergence 13; the PWA also shows none, but its INV-6 says it
    should)*
17. Force-quit the app, then open a saved observation directly — cold start, slow first read. It
    opens the right record. It must never bounce you back to the day view, and must never show an
    empty all-calm form while loading. → `SKIN-ENTRY-4`, `SKIN-ENTRY-5` *(this can fail on the
    PWA — Divergence 14)*
18. Tap add-photo. The camera comes up first, and the photo library is one tap away. → `SKIN-PHOTO-7`
19. Attach a photo from the library that was taken days ago, and save. It attaches like any other
    photo, and its own capture time is kept rather than rewritten to today. → `SKIN-PHOTO-22`,
    `SKIN-PHOTO-23`
20. Open an observation holding three photos and tap the first thumbnail. It fills the screen, showing
    its region. Swipe sideways: you reach the other two, and swiping past the third does **not** wrap
    to the first. → `SKIN-PHOTO-24`, `SKIN-PHOTO-29` *(this fails on the PWA — Divergence 16; its
    lightbox shows one photo and does not page)*
21. Pinch to zoom in on the skin. Tap once: the caption and the close control disappear. Tap again:
    they return. With them hidden, swipe **down** — the viewer closes. → `SKIN-PHOTO-26`,
    `SKIN-PHOTO-27`, `SKIN-PHOTO-28` *(all fail on the PWA)*
22. Look everywhere in the viewer for a way to delete the photo. There is none, on either surface. →
    `SKIN-PHOTO-30`
23. Mark a stored photo for removal, then tap it. It still opens, and is still shown as marked. →
    `SKIN-PHOTO-25`
24. From **this** screen's viewer, look for a control that opens the observation. There is none — you
    are already in it. → `SKIN-PHOTO-31`
25. **Turn VoiceOver on.** Swipe through the grid. You hear nine stops, in canonical order, each one
    "region, level" — not eighteen stops, and not a tile whose level you have to look for. →
    `SKIN-A11Y-1`, `SKIN-A11Y-2`
26. Still under VoiceOver, double-tap an inactive region. You hear that it is now active **and** that
    its level did not change. Double-tap again: you hear the new level. Keep going past `Severe`: you
    hear `Calm`, described as a level and not as "cleared". → `SKIN-A11Y-3`, `SKIN-A11Y-4`
27. Open a saved observation under VoiceOver and change nothing. You can still **reach** the save
    control, and it tells you it is unavailable and why. → `SKIN-A11Y-7` *(this fails on the PWA —
    Divergence 5; the control is absent from the accessibility tree entirely)*
28. Delete it. The confirmation is announced as destructive **and** says the photos go too. Undo: the
    undo affordance is announced, and you can reach it without seeing it. → `SKIN-A11Y-9`,
    `SKIN-A11Y-10`
29. Under VoiceOver, open the viewer on the middle of three photos. You hear which photo of how many.
    Page to the third and try to page again: you hear that you are at the end. Then dismiss it using
    the control, not the swipe. → `SKIN-A11Y-11`, `SKIN-A11Y-13`, `SKIN-A11Y-12`
30. Set Dynamic Type to the **largest accessibility size**. Every region label and every level label
    is fully readable — the grid reflows or scrolls, and nothing reads `Mod…`. → §9a question 2
31. Turn **Reduce Motion** on and open, page, and dismiss the viewer. All three work; none animates
    position or scale. → §9a question 5
32. Turn colour filters to greyscale, or just squint. Each region's level is still readable, the
    active region is still identifiable, and a photo marked for removal is still identifiably marked.
    → `SKIN-A11Y-14`, `SKIN-INT-7`, `SKIN-INT-8`
33. Under VoiceOver, listen to everything on the screen and everywhere the observation appears. Nothing
    announced compares today to yesterday, names a food, or gives the day one severity. →
    `SKIN-A11Y-15`

---
## 12. Open questions

Recorded rather than guessed, per the map's cite-or-don't-claim rule. Each is a candidate ticket;
none blocks writing the remaining spec sections.

**12.1 — `CONTEXT.md` should stop contradicting itself about observations per day. (Resolved
here; the source still needs fixing.)** The glossary § _SkinObservation_ says "Multiple
`SkinObservation` records may exist for the same day", while INV-6 describes the observation as "a
per-region severity set" and INV-7 says "every save witnesses all nine regions" — phrasings that
read naturally as one-per-day. **The owner has confirmed *many*,** which is what this document
already specifies (§2.4) on the evidence that the storage port returns a list, the day view
renders each with its own time, and nothing anywhere upserts. It stays listed because the
remaining work is on the *frozen repo*: INV-6 and INV-7 should be reworded so a reader who takes
them at face value does not design a one-per-day schema. Worth doing before that repo freezes,
since this document cites those anchors.

**12.2 — INV-6 should stop describing a day-level severity. (Decided: nothing is displayed.)**
§9.5, `SKIN-VIEW-5`, Divergence 13. The owner has dropped the concept: no day-level figure is
displayed anywhere, on the grounds that it was never implemented, that
[#677](https://github.com/jirigrill/eczema-helper/issues/677) named the derivation the app's
regulatory surface, and that it is free to reverse because the value is derived and needs no
stored field. What remains is the same source-side fix as §12.1 — INV-6 still describes
`max(regions)` as a rule of the domain, and on this decision it is not one.

**12.3 — `SkinPhoto`'s record shape.** Whether size, format, and dimensions are recorded fields is
a **schema-deadline** question: additive-only promotion means a field never recorded cannot be
backfilled ([#679](https://github.com/jirigrill/eczema-helper/issues/679)). Lives on the map's
SwiftData fog; [#684](https://github.com/jirigrill/eczema-helper/issues/684) deferred only the
pixel and quality *targets*, not the shape.

**12.4 — Which of these fields get CloudKit field-level encryption.**
[#714](https://github.com/jirigrill/eczema-helper/issues/714) decides against the real schema. Note
this screen holds the most sensitive data in the app — infant medical photographs and per-region
severities — so it is the section that question is really about.

**12.5 — How long may the edit-loading state last before it needs its own copy? (The mechanism
is decided; the threshold is not.)** `SKIN-ENTRY-4`/`-5`, Divergence 14. The owner has chosen to
**await the read** rather than keep the PWA's 500 ms timer, so a valid id can no longer be rejected
silently. That moves the question rather than closing it: a read that takes unusually long now
shows a loading state indefinitely instead of bouncing, and this document deliberately sets **no
threshold** at which that state should say something more than "loading". Almost certainly a
non-issue for a local SwiftData fetch by identifier, which is why no number is guessed here — but
if one is ever needed it is copy plus a duration, not a change to the rule.

**12.6 — What the Photos permission string says, and how the privacy surfaces declare the camera
roll. (The behavior is decided; its copy is not.)** §5.4, `SKIN-PHOTO-18`–`-21`, Divergence 12.
The owner has kept camera-roll sharing, accepting that it is the one path by which infant medical
photographs leave the app's boundary. That makes three pieces of *text* load-bearing, and none of
them is written: the `NSPhotoLibraryAddUsageDescription` string, which is user-facing and must
describe saving without implying the app manages her library; the Art. 13 privacy notice
([#709](https://github.com/jirigrill/eczema-helper/issues/709)), which now has a disclosure it did
not have before; and the App Store privacy labels, which must declare it. Copy, not behavior — but
per the map's marketing-tripwire note, copy about medical photographs is exactly where this
product's risk lives.

**12.7 — Does anything on this screen need a *pending work* concept? — RESOLVED.**
[#707](https://github.com/jirigrill/eczema-helper/issues/707) settled it: **yes, and it is the same
concept as the meal editor's.** *Pending work* is one shared question — would leaving lose something
she did? — defined in [`GLOSSARY.md`](GLOSSARY.md), with each area stating what counts as work.
`SKIN-UNDO-6` is this screen's list and is unchanged. This section's own premise for doubting it was
the one that failed: *every visit can save* ([INV-7](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-7))
says nothing about whether leaving loses anything, and Divergence 8 is the proof — a compose visit
that could always have saved still discards nine bumped regions, a note and staged photos with no
undo.

**12.8 — Whether attaching an older library photo needs any visible signal. (Sources are
decided; this consequence is not.)** `SKIN-PHOTO-7`, `-22`, `-23`, Divergence 15. The owner has
settled **camera first, library one tap away**. `SKIN-PHOTO-23` then makes a deliberate choice
visible: a photo taken three weeks ago keeps its own `capturedAt` on an observation created today,
because the two fields answer different questions and clamping either would be a lie. What is not
decided is whether the interface ever *says* so — a photo visibly older than the observation it
sits on is either useful context or a confusing detail, and nothing in the data settles which. Pure
presentation, so it belongs with the UI/UX rework rather than here; recorded because the rule that
creates it is now a MUST NOT and a later reader will otherwise read the mismatch as a defect.

---

## Appendix A: what this screen must not grow

These are prohibitions with ids, not features nobody built. Each names a surface an implementer would
reasonably add to a screen about a rash, and each would be a silent addition rather than a decision.
Appendix B answers the different question of which document owns what.

**`SKIN-ABSENT-1` (MUST NOT)** — No video is captured, and no photo control offers one. The record
holds still photographs alone.

The reference's file input is `accept="image/*"` (`src/routes/skin/+page.svelte:545`). Video is the
obvious extension for a rash that moves — scratching, a flare's spread — and it breaks three rules at
once rather than one: `SKIN-PHOTO-16`'s round-trip guarantee, the per-photo `capturedAt` in §2.1, and
the encrypted-asset budget the persistence model sizes for images.

**`SKIN-ABSENT-2` (MUST NOT)** — Nothing on this screen offers a treatment, a cream, a medication, an
emollient log, a bath record, or any intervention field.

The nearest miss in the whole product. An observation screen is where a mother is already looking at
the skin, and *what did you put on it* feels like the same act of recording — but a treatment field
plus a severity field is a before-and-after, which is the derived claim
[INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11) and `DECISIONS.md` §5
forbid the app from making. It is also the field most likely to be read as advice. If interventions are
ever recorded, they are a separate record type argued on its own, not a text box added here.

**`SKIN-ABSENT-3` (MUST NOT)** — No region, level, or observation carries a suspected cause, a trigger,
a food reference, or a link to a meal. The note is free text and is not parsed for one.

`DATA-ABSENT-1` forbids the field and `SKIN-INT-14` forbids the framing; this states it on the surface,
because a "what do you think caused this?" prompt is the single most natural thing to add beneath a
severity picker, and it would make the app the thing
[INV-5](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-5) says it is not.

**`SKIN-ABSENT-4` (MUST NOT)** — No total, average, count of affected regions, or day-level figure is
computed or shown — not on this screen, not in its save confirmation, and not in any announcement.

`SKIN-VIEW-5` states the display half and Divergence 13 records the decision; the prohibition is
repeated here because this is the one screen holding all nine levels at once, which is exactly where a
sum is cheapest to compute and most misleading to read.

**`SKIN-ABSENT-5` (MUST NOT)** — There is no reminder, no schedule, no streak, and no prompt to observe.
The app never asks her to open this screen.

---

## Appendix B: what this section deliberately does not contain

Recorded so a reader does not mistake an omission for a gap:

- **Swift, SwiftUI, or SwiftData types.** The spec is platform-neutral; the schema is its own
  concern and its own section.
- **Layout, spacing, colour values, or component structure.** iOS UI/UX is untouched fog. The
  reference implementation's design prototype is a **Czech-web** artifact, and its skin screens are
  additionally unusable as a reference: two of the three variants depict the parked
  protocol engine (a reintroduction-test context pill, and an in-test escalation state), and its
  photo section is labelled a historical placeholder in the prototype's own text. Only the
  ordinary-day variant reflects what ships.
- **Invariant text.** Cited, never copied.
- **The day view, first-run, feeding stage, and settings.** Their own sections.
- **Anything about meals.** The undoable action is shared and is specified in both places by
  reference to one rule set, not duplicated.
