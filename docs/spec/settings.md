# Settings — behavior specification

**Status:** **owner-confirmed throughout.** §4.1's last five open decisions — the diagnostic log's
shape, the banner/Settings split, the 24-hour threshold, the quota copy, and the two timestamps — were
confirmed as written in [#767](https://github.com/jirigrill/eczema-helper/issues/767), closing the
section written against [#723](https://github.com/jirigrill/eczema-helper/issues/723). §4.1's own note
records the split as it stood. §3's `SET-DELETE-13`..`-21` are **owner-confirmed** (#733, eight answers). Written against the format settled by
[#682](https://github.com/jirigrill/eczema-helper/issues/682) — see
[`TEMPLATE.md`](TEMPLATE.md) for the rules, and
[`skin-observation.md`](skin-observation.md) for the worked example.
**Behavior reference:** `jirigrill/eczema-helper` @ `582f662` (frozen PWA),
`src/routes/settings/`, `src/lib/stores/settings.svelte.ts`, `src/lib/db/reset-database.ts`.
§4.1 has **no behavior reference** — the PWA has no sync of any kind.
**Resolves:** [#716](https://github.com/jirigrill/eczema-helper/issues/716) on the transition map
[#672](https://github.com/jirigrill/eczema-helper/issues/672),
[#709](https://github.com/jirigrill/eczema-helper/issues/709) (§5, the privacy notice's form),
[#723](https://github.com/jirigrill/eczema-helper/issues/723) (§4.1, sync health), and
[#733](https://github.com/jirigrill/eczema-helper/issues/733) (§3 `SET-DELETE-13`..`-21`, deletion
that cannot reach the server).

## Overview

Settings is the smallest screen in the app and the one that changed most in the port. In the
reference implementation it holds exactly two things: a picker for the feeding stage, and a
destructive factory reset. On iOS it also has to carry the iCloud account state, a route to the
privacy notice, and a deletion control that must reach a server the reference implementation never
had.

So most of this section is **new behavior, not a port**. Its job is to make decisions taken
elsewhere on the map visible to the mother — or provably invisible, which is why several of its
rules are prohibitions with ids rather than features that merely do not exist.

This document states what the screen does, in English, without reference to Swift, SwiftUI,
SwiftData, Svelte, Dexie, or the Czech interface. Swift tests are derived from the numbered rules;
the owner's acceptance pass is derived from §9.

Six things are worth knowing before the rules make sense:

1. **The feeding stage governs what may be *created*, never what is *shown*, and a change is never
   retroactive.** [INV-14](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-14)
   binds at log time, so changing the stage cannot invalidate, hide or alter a meal already
   recorded. `docs/spec/day-view.md` §6 depends on this being true.
2. **The feeding stage does not live with the records it governs.**
   [#691](https://github.com/jirigrill/eczema-helper/issues/691) moved it to
   `NSUbiquitousKeyValueStore`, outside the SwiftData store, so that a duplicate settings row is
   structurally impossible. That is why §4's account-state rules do not reach it (§2.3).
3. **Two absences are load-bearing.** There is no sync toggle
   ([#705](https://github.com/jirigrill/eczema-helper/issues/705)) and no export, import or backup
   of any kind ([#683](https://github.com/jirigrill/eczema-helper/issues/683)). Settings is where a
   reader would look for both, so §7 states them as prohibitions rather than leaving a gap.
4. **The privacy notice is bundled text, not a web page.** §5 is the largest part of this section and
   the least like a screen spec: **six of its fourteen rules are `MUST NOT`s**, constraining what a
   legal document may claim rather than what the screen does, because each stops the app asserting
   something no primary source supports.
5. **The app is silent about sync while sync is working.** §4.1 says so as a numbered prohibition, not
   as an absence, because no Apple API can report that the store is synchronised — only that one
   operation finished at one moment. The app speaks up on **persistent** failure and says nothing
   otherwise, which is the opposite of what most CloudKit apps do and is deliberate.
6. **The deletion control never refuses, and its degraded path is disclosed rather than hidden.** §3's
   deletion is **two** operations against two different stores — the zone in her iCloud and the store
   on the phone — and only the second always works. `SET-DELETE-13`..`-21` settle that the second
   proceeds regardless, that ordinary queued deletions carry the first when the account is later
   reachable, and that the app says so plainly instead of implying a completeness the platform will
   never confirm.

**How to read this document:** see
[`skin-observation.md` § How to read this document](skin-observation.md#how-to-read-this-document).
Rule ids here are `SET-<group>-<n>`, permanent identity, never renumbered or reused.

### Invariant dispositions

Invariants are cited, never restated. [#691](https://github.com/jirigrill/eczema-helper/issues/691)
classified all fourteen; the ones this section touches carry their disposition here so a bare
citation cannot import a contradiction.

| Ref | Leading phrase | Disposition here |
| --- | --- | --- |
| [INV-1](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-1) | _Single device, no sync_ | **Void for iOS.** Sync is mandatory and always on ([#705](https://github.com/jirigrill/eczema-helper/issues/705)). It is why §4 exists at all — the reference implementation had no account state to display, and no sync that could fail. Voiding it creates the whole of §4.1: a failure mode the PWA could not have. But it is void only as to *whether records leave the device* — it does not license reporting sync's health, which `SET-SYNC-1` forbids. |
| [INV-2](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-2) | _No backup mechanism exists_ | **Void for iOS** as to durability — sync carries it ([#683](https://github.com/jirigrill/eczema-helper/issues/683)). But there is still **no rollback**, which is what makes every rule in §3 irreversible and why `SET-ABSENT-3` forbids implying otherwise. |
| [INV-8](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-8) | _`id` and `createdAt` immutable across edit, delete, undo_ | **Holds unchanged**, and is load-bearing off-screen: [#687](https://github.com/jirigrill/eczema-helper/issues/687)'s forced re-save on the sign-in transition must not stamp today onto months of records. Settings triggers nothing that may touch them. |
| [INV-9](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-9) | _Photos stored unencrypted at rest_ | **Void for iOS.** `encryptedValues` field encryption ships from release one ([#705](https://github.com/jirigrill/eczema-helper/issues/705), field list [#714](https://github.com/jirigrill/eczema-helper/issues/714)). Bears on what the privacy route in §6 may claim — encryption protects **values, never structure**. |
| [INV-10](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-10) | _Dexie/IndexedDB; reactive UI via `liveQuery`_ | **Void for iOS.** Directly relevant twice: the feeding stage leaves the store entirely (#691), and the PWA's post-reset navigation guard exists only to work around a `liveQuery` race (Divergence 4). |
| [INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11) | _The app is a Logging Tool_ | **Holds**, and governs `SET-ABSENT-4`: Settings displays nothing derived from her records, no more than the day view does. |
| [INV-14](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-14) | _Every meal has an eligible actor_ | **Holds, and is read precisely.** It binds **at log time**, which is the whole of `SET-STAGE-5`: a stage changed here does not reach backwards. |

`CONTEXT.md` also holds invariant-shaped rules **unnumbered**, in glossary prose. One bears on this
screen and is cited by heading: _Actor_ (the stage → actors mapping) under § _Glossary_.

### Divergences from the PWA

This is not a 1:1 port. Per [#690](https://github.com/jirigrill/eczema-helper/issues/690),
**coherence is presumed right**: where the reference implementation does two different things, the
port takes the coherent rule, and *keeping* a wart needs a named reason. There are **ten**, marked
inline and indexed in §8. Most of this section has no PWA counterpart at all, so the divergence
count is a poor measure of how much changed here — §9's "rules nothing verifies today" is the
honest one.

---

## 1. Vocabulary

| Term | Meaning |
| --- | --- |
| **Account state** | The five-valued iCloud account status of [#687](https://github.com/jirigrill/eczema-helper/issues/687), not a boolean. |
| **Degraded state** | `noAccount` or `restricted` only — the two states that gate writing. `temporarilyUnavailable` and `couldNotDetermine` are **not** degraded for this purpose. |
| **Delete-all control** | The single destructive control in the app, settled by [#705](https://github.com/jirigrill/eczema-helper/issues/705). |
| **Diagnostic log** | A local, bounded, unsynced record of observed sync failures. Captured because error detail is unrecoverable after the fact; has no user-facing surface in v1 (§4.1). |
| **Her iCloud** | The private CloudKit database in the mother's own iCloud account. The developer holds no copy and cannot reach it. |
| **Notice revision** | An opaque monotonic identifier (`v1`, `v2`, …) for one wording of the privacy notice. Not the app's version, not a date (§5). |
| **Persistent failure** | A sync failure still unresolved 24 hours after the last success, with changes pending. Only a persistent failure is ever surfaced to her (§4.1). |
| **The notice** | The Art. 13 privacy notice: one English text, shipped in the bundle and served at a stable URL (§5). |
| **System deletion path** | Apple's own route to delete an app's iCloud data from iOS Settings, outside this app (§5). |

Two terms this section uses are shared with the day view and defined in
[`GLOSSARY.md`](GLOSSARY.md): **feeding stage** — the app-wide `breastfed` / `mixed` / `solids`
value this screen owns the setting of (§2) — and **eligible actors**, the set that stage permits.

---

## 2. The feeding stage

### 2.1 The control

**`SET-STAGE-1` (MUST)** — Settings is the only place the feeding stage can be changed after first
run. No other screen offers it.

**`SET-STAGE-2` (MUST)** — All three stages are offered together in the fixed order `breastfed`,
`mixed`, `solids`, and the current one is indicated.

The order is the source protocol's progression, not an alphabetisation or a frequency ranking. It
is stable so that the control's shape does not change as she moves through it.

**`SET-STAGE-3` (MUST)** — A change takes effect immediately on selection. There is no save button,
no confirmation and no undo.

**`SET-STAGE-4` (MUST NOT)** — Selecting the stage that is already current writes nothing.

**`SET-STAGE-5` (MUST NOT)** — A stage change is never retroactive. No meal already recorded is
altered, re-labelled, hidden, flagged or deleted, whatever actor logged it.

This is [INV-14](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-14) read
precisely: eligibility binds when the meal is logged, so a later change cannot make a recorded meal
retrospectively illegitimate. `docs/spec/day-view.md` `DAY-MEAL-2`/`-3` is the visible consequence —
the day view renders meals by their **recorded** actor, unmarked. Anything here that reached
backwards would re-create the data-loss path
[#712](https://github.com/jirigrill/eczema-helper/issues/712) exists to close.

**`SET-STAGE-6` (MUST)** — The hint beside the control says what the stage governs: whose meals she
can record. It does not describe feeding, diet or the protocol.

**`SET-STAGE-7` (MUST)** — When no feeding stage is known, the control shows **no selection** rather
than a guess, and choosing one sets it.

"No stage" is never a durable state
([#712](https://github.com/jirigrill/eczema-helper/issues/712)) — but the app cannot detect a
restored device at all, so it must *tolerate* arriving stage-less rather than detect it. Showing a
pre-selected stage she never chose is the specific mistake that made #712's data-loss path
reachable; this screen must not repeat it.

### 2.2 Sync

**`SET-STAGE-8` (MUST)** — Outside the onboarding launch session, the feeding stage is
**last-writer-wins**: the most recent change, wherever it was made, is the current value. The app
adds no arriving-wins rule on top of the store's own semantics.

That is exactly why [#691](https://github.com/jirigrill/eczema-helper/issues/691) chose
`NSUbiquitousKeyValueStore` — a key is a key, and two writes to it overwrite rather than duplicate,
which is the wanted semantics for a value whose duplicate would be **invisible**. The single
exception is #712's onboarding-session rule, under which a late-arriving stage silently overwrites
her fresh answer; that rule is scoped to onboarding and is owned by
[the first-run section](https://github.com/jirigrill/eczema-helper/issues/729), not by this one.
Unbounded arriving-wins would clobber a stage she deliberately changed here.

### 2.3 Availability

**`SET-STAGE-9` (MUST)** — The feeding stage can be changed in **every** account state, including
`noAccount` and `restricted`.

**`SET-STAGE-10` (MUST)** — The control looks and behaves identically in every account state. It is
never disabled, greyed, annotated or accompanied by an explanation of why it still works.

[#687](https://github.com/jirigrill/eczema-helper/issues/687)'s gate is a **durability** gate: its
purpose is that no *record* is created that CloudKit has not seen, because with no export and no
backup an unsynced record dies with the phone. The feeding stage cannot suffer that loss. It is not
a record, it does not live in the synced store (#691), and #712 already established that losing it
costs one question with three chips — the app is *required* to tolerate arriving without it. Gating
it would key a `NSUbiquitousKeyValueStore` write on a `CKAccountStatus` signal that does not
describe that store's availability, which is the mismatch #691 flagged when it handed this question
to the spec.

The platform agrees. Apple documents that with no account, *"the changes remain only on the current
device"* — the write succeeds and persists locally, and the API exposes essentially no error surface
to gate on (`docs/research/settings-data-deletion.md` §A). A disabled control here would be the app
inventing a restriction the platform does not impose, on the one value in the product that is not at
risk — and doing it on the same screen that carries the degraded-state warning, where it would read
as *your data is in danger*.

The cost, accepted: in a degraded state she can change a stage while unable to log anything, so the
change has no observable effect until the state resolves. That is harmless, and the alternative is
freezing a setting forever on a `restricted` phone, which Apple documents as **nonrecoverable**.

---

## 3. Deleting everything

**`SET-DELETE-1` (MUST)** — Settings offers a control that deletes all of the mother's data.

This is not merely permitted, it is instructed. Apple: *"If your app stores data in CloudKit on
behalf of your users, give them a simple way to delete their data"* (*Responding to Requests to
Delete Data*). It is also [#705](https://github.com/jirigrill/eczema-helper/issues/705)'s
mitigation for GDPR Art. 7(3): consent is given in-app, so withdrawal must be reachable in-app —
EDPB Guidelines 05/2020 para 114's *"same electronic interface"* test, whose failure mode
(Example 22) is one click to give and somewhere else to withdraw.

Note that App Store Review Guideline **5.1.1(v) does not apply** — it is scoped to *"if your app
supports account creation"*, and this app has no accounts of its own. The obligation above is a
different document and reaches an app with no accounts. Do not cite 5.1.1(v) for it.

**`SET-DELETE-2` (MUST)** — Nothing is destroyed until an explicit confirmation is accepted.

**`SET-DELETE-3` (MUST)** — The confirmation names what will be destroyed — meals, skin observations
and photos — and states that it cannot be undone.

**`SET-DELETE-4` (MUST)** — Cancelling destroys nothing, writes nothing and leaves the screen
unchanged.

**`SET-DELETE-5` (MUST)** — The control and its confirmation name the action plainly. The verb is
*delete*, never a euphemism, and never a generic affirmative.

> **⚠ Divergence 1.** *PWA:* the control is labelled *"Restartovat"* — **restart** — and the
> confirmation repeats it (`+page.svelte:71,79`, `common.ts:59-68`). *iOS:* the action is named as
> the deletion it is. *Why:* it destroys the mother's only record of months of her infant's health
> and there is no rollback anywhere in the product. Apple's HIG requires a confirmation's button to
> *"clearly indicate the action"* rather than a bare affirmative; "restart" describes what the app
> does afterwards, not what happens to her data. Class: **defect fixed**.

**`SET-DELETE-6` (MUST)** — The deletion removes every meal, every skin observation, every photo,
and the feeding stage.

**`SET-DELETE-7` (MUST)** — The deletion removes those records from her iCloud as well as from the
phone.

> **⚠ Divergence 2.** *PWA:* the reset clears every table in the local database and there is nowhere
> else for data to be — the table list is read live from `db.tables` precisely so a future table
> cannot be missed (`reset-database.ts`). *iOS:* the same wipe must also reach the server. *Why:*
> forced by platform. Under mandatory sync her records exist in two places, and a control that
> cleared only the phone would leave a full copy in iCloud that the app can no longer see or reach.
> Apple documents the recipe — enumerate the container's zones and delete them
> (*Responding to Requests to Delete Data*); note this is **separate** from clearing the local
> store, and that SwiftData's own `deleteAllData()` is documented against *"the app's persistent
> storage"* with **no documented CloudKit propagation**
> (`docs/research/settings-data-deletion.md` §D). Class: **forced by platform**.

**`SET-DELETE-8` (MUST)** — On completion she lands on first run, in the same state as a fresh
install.

Clearing the feeding stage is what makes this coherent: it is a health-adjacent value — *this
household has an infant on solids* — that she has just asked to erase, and #712 already made
re-asking harmless. The reference implementation does the same thing for the same reason
(`resetDatabase()` clears the settings table with all the others), so this is a port, not a new
rule.

> **⚠ Divergence 3.** *PWA:* after wiping, the page subscribes to the settings signal and waits for
> it to flip to `unset` before navigating, because the `liveQuery` still reports the stale `seeded`
> value for a tick and the layout's redirect would otherwise bounce her straight back to the day
> view (`+page.svelte:30-45`, a re-opening of issue #353). *iOS:* no such guard. *Why:* obsolete.
> The race is a property of Dexie's `liveQuery`
> ([INV-10](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-10), void for iOS)
> and of the stage living in the same store as the records; under #691 the stage is in
> `NSUbiquitousKeyValueStore` and is cleared directly. Do not port the machinery, and do not port
> its test. Class: **obsolete**.

**`SET-DELETE-9` (MUST NOT)** — There is no undo, no trash, no grace period and no recovery. The
deletion is immediate and final.

Consistent with [#687](https://github.com/jirigrill/eczema-helper/issues/687)'s no-trash decision,
and unavoidable regardless: there is no export, no backup and no server-side recovery
([#683](https://github.com/jirigrill/eczema-helper/issues/683)).

**`SET-DELETE-10` (MUST NOT)** — The app never terminates itself after the deletion.

**`SET-DELETE-11` (MUST NOT)** — The control never claims to have deleted photos the mother
previously shared to the system camera roll, and the confirmation says so.

> **⚠ Divergence 4.** *PWA:* the confirmation states that *"all meals, observations and photos will
> be permanently deleted"* (`common.ts:67-68`) — which is false for any photo she shared out, since
> camera-roll copies are in Photos and beyond the app's reach forever. *iOS:* the copy names the
> exception. *Why:* defect. Camera-roll sharing is the app's largest deliberate privacy concession
> and survives the port as the only route by which an image leaves the boundary; a deletion control
> that implies it can retrieve those copies is making a false statement to a mother about her
> infant's medical photographs. Class: **defect fixed**.

**`SET-DELETE-12` (MUST NOT)** — The app does not claim that server-side deletion has completed.

Deletion is **not verifiably complete** — Apple exposes no API that confirms it, and the local wipe
and the zone deletion are two operations with no shared transaction
(`docs/research/settings-data-deletion.md` §D). Copy may state what was requested; it may not
certify an outcome the platform will not report.

**`SET-DELETE-13` (MUST)** — The control never refuses. Whatever the account state, and with or
without a network, accepting the confirmation destroys her records on this phone.

Settled by [#733](https://github.com/jirigrill/eczema-helper/issues/733). An erasure right that a
basement can block is not a right. The decisive case is `restricted`, which Apple documents as
**nonrecoverable** — refusing there would not defer the deletion, it would forbid it permanently, on
a phone whose state she has no way to fix. This is an Art. 17 surface and #705's Art. 7(3)
withdrawal route, so availability is the property that matters most about it.

**`SET-DELETE-14` (MUST)** — The deletion is carried out in two parts, in this order: her records'
zone in iCloud is deleted first, then the store on the phone is wiped — **and the local wipe happens
whether or not the first part succeeded.**

Apple's order, from its own recipe: enumerate the private database's zones and delete them
(*Responding to Requests to Delete Data*). Taking the server first avoids a gap that has no
documented answer — what mirroring does with queued deletes aimed at a zone that no longer exists is
`NOT FOUND` in both directions (`docs/research/settings-data-deletion.md` §D.4), and a silent zone
re-creation would be the worst outcome available here. Never gating the local wipe on the result is
what collapses failure into the path `SET-DELETE-16` already specifies: there is one degraded path,
not one for offline and another for a server error.

**`SET-DELETE-15` (MUST)** — The local wipe deletes her records **through the store**, as ordinary
deletions, so that the deletions themselves are queued for upload by normal mirroring.

This is the mechanism that makes `SET-DELETE-16` work without new persisted state. Apple documents
deletes as ordinary exportable work — *"the user creates, updates, or **deletes** a managed
object… When its managed object context saves changes to the store, Core Data creates a background
task… uploading it to CloudKit"* — so a deletion requested with no account is carried by the same
machinery that carries a meal, and completes when the account is next reachable.

The alternative was a wipe that destroys the store outright plus a durable pending-deletion marker
to drive a retry. It is **rejected**, and the reason is a deadline rather than a preference: such a
marker is a persisted field, and additive-only schema promotion
([#679](https://github.com/jirigrill/eczema-helper/issues/679)) means a field absent at first
production promotion can never be backfilled ([#691](https://github.com/jirigrill/eczema-helper/issues/691)).
This section takes on **no schema deadline**, which it could not have avoided under that design.

> **Correction to a premise, recorded because it is the reason no marker is needed.** #733 was
> written believing that a local wipe destroys the app's *handle* on the iCloud copy — *"it has just
> destroyed its own handle on them"* — and that a marker is therefore unavoidable. That is wrong:
> Apple's recipe enumerates zones **server-side**, from the account
> (`fetchAllRecordZones`, then `CKModifyRecordZonesOperation` — §D.1). The handle is the account, not
> the local store, so wiping the phone never orphans the zone, and `SET-PRIVACY-3`'s system route
> stays available regardless.

**`SET-DELETE-16` (MUST)** — When the zone deletion did not succeed — she is offline, the account is
degraded, or the call failed — the app states plainly that the copy in her iCloud is **still there
now**, and that it is removed when the phone next reaches her account.

This is the disclosure half. `SET-DELETE-12` is a prohibition and cannot by itself require the app to
say anything; without this rule the honest case would be unspoken. Note what the app knows here, which
is more than `SET-DELETE-12`'s general uncertainty: not merely that completion is unconfirmed, but
that the server side has **not started**.

**`SET-DELETE-17` (MUST)** — In that same case, the copy names the two things she can do: **open the
app once more while online**, which lets the queued deletion complete, and the **system deletion
path** (`SET-PRIVACY-3`), which does not depend on this app at all.

She is the only actor who can close this window, and it is a real one: she wipes, lands on first run,
deletes the app, and the queued deletions never flush — the iCloud copy then survives with no in-app
route left. Nothing detects this, because the app **cannot tell whether the queued deletions have
flushed**: no API distinguishes "not yet exported" from "exported"
(`docs/research/cloudkit-unavailable-behavior.md`), and `SET-SYNC-12`'s last-upload timestamp is a
proxy, not an answer. One sentence closes the window; withholding it would leave her the harder route
and not the easy one.

**`SET-DELETE-18` (MUST)** — In `noAccount`, the copy **leads with** the system deletion path, and
presents the in-app wipe as the part that clears this phone.

The one state where the ordering changes, because it is the state where the in-app control is
weakest: with no account she cannot reach her own iCloud data from this app at all, so
`SET-PRIVACY-3`'s route is not an alternative, it is the only thing that works. Uniform copy would
bury the working path exactly where it is needed. The local wipe is still offered — withholding it
would be `SET-DELETE-13`'s refusal by another name.

**`SET-DELETE-19` (MUST)** — A zone deletion that fails while the account **is** reachable is treated
exactly as the unreachable case: same disclosure, same two remedies.

No branching on the error. She can act on no `CKError` code, and the remedy is identical either way.
The failure is also more likely to be partial than clean: in a custom zone *"the system processes all
items in an operation atomically"*, so per-item failures cascade to `batchRequestFailed` (§D.4) —
"the zone is partly deleted" is not a state worth describing to a mother. What must **not** happen is
treating reachable-but-failed as success on the grounds that mirroring will carry the deletions
anyway; that would certify an outcome `SET-DELETE-12` forbids certifying.

**`SET-DELETE-20` (MUST)** — The outcome of the zone-deletion call — success, or the failure's full
detail — is captured to the diagnostic log of `SET-SYNC-10`, with no user-facing surface.

`SET-SYNC-10` as written covers **mirroring events**; a zone deletion is a direct CloudKit call and
falls outside it, which is why this rule exists rather than being implied. It is the only
capture-by-omission risk left in this section: a silent failure of the app's single erasure control
would otherwise be unreconstructible afterwards, and this control is the one whose failure has a
regulatory consequence. `SET-SYNC-11`'s prohibition continues to hold — captured, never displayed,
never shared. No schema deadline: the log is local, unsynced and freely reshapeable.

**`SET-DELETE-21` (MUST NOT)** — The destructive confirmation does not wait indefinitely on the
network. If the zone deletion has not returned within a few seconds, the local wipe proceeds and
`SET-DELETE-16`'s disclosure is shown.

The corollary of `SET-DELETE-14`'s ordering. Apple describes sync as running on a *"natural cadence"*
and offers no latency guarantee, so an ungated wait would hold a destructive action open on the water
cycle — and a confirmation that appears to hang is read as a broken app, at the worst possible moment.
The bound belongs in the spec because "wait for the server" is otherwise the obvious reading of
`SET-DELETE-14`.

---

## 4. The iCloud account state

**`SET-ICLOUD-1` (MUST)** — While the account state is degraded, Settings states it in plain
language.

This is [#687](https://github.com/jirigrill/eczema-helper/issues/687)'s "plus a line in Settings",
the detail surface behind the persistent banner.

**`SET-ICLOUD-2` (MUST)** — The persistent non-blocking banner shown elsewhere in the app links
here.

**`SET-ICLOUD-3` (MUST)** — The line names the **consequence** concretely — new records cannot be
created, and records already on this phone are not being copied anywhere — rather than the technical
account status.

**`SET-ICLOUD-4` (MUST NOT)** — Settings shows nothing about the account in
`temporarilyUnavailable` or `couldNotDetermine`.

Those are self-resolving and Apple instructs apps to wait. #687 made this a **durability** gate, not
a connectivity one: airplane mode and a basement must produce no warning, or the warning that
matters stops being read.

**`SET-ICLOUD-5` (MUST NOT)** — Settings offers no control that changes the account state. The OS
owns it; the app may link out to iOS Settings and may not simulate a sign-in.

### 4.1 Sync health — the app speaks only when something is wrong

Settled by [#723](https://github.com/jirigrill/eczema-helper/issues/723). The rules below replace the
`SET-ICLOUD-6` placeholder this section previously carried.

**Confirmation status, stated per decision** so nothing unreviewed passes as settled. Twelve rules, of
which three (`SET-SYNC-2`, `-8`, `-9`) are forced by the platform and are not product choices at all —
leaving **nine decisions, all nine owner-confirmed** — four settled while the section was written and
five confirmed afterwards in [#767](https://github.com/jirigrill/eczema-helper/issues/767).

**Settled by the owner:** silence while sync is healthy (`SET-SYNC-1`), writing that silence as a
numbered prohibition rather than leaving it an absence (`-1`), two failure messages keyed to the
consequence for her (`-3`), and surfacing only persistent failures rather than every one (`-4`).

**Confirmed as written in [#767](https://github.com/jirigrill/eczema-helper/issues/767)** — the
remaining five, presented there with the reasoning and, where one existed, the recommendation each was
decided against: the diagnostic log's capture-only shape (`-10`, `-11`), the banner/Settings split and
its empty-store exception (`-5`, `-6`), the **24-hour** figure specifically (`-4` — that the gate is
persistence was already settled; the number is now too), naming quota as a *likely* cause in the copy
(`-7`), and recording the two timestamps (`-12`). Nothing changed on confirmation: the rules stand as
written. So **all nine decisions are owner-confirmed**, and no rule in this section awaits review.

**`SET-SYNC-1` (MUST NOT)** — The app displays no affirmative sync state anywhere: no "synced", no
"up to date", no "last synced at", no cloud glyph in a healthy condition, no progress indicator. It
is **silent while sync is healthy** and speaks only when something is wrong.

This is written as a prohibition, not left as an absence, because it is the counter-intuitive half of
the decision and would otherwise read to an implementer as an oversight — the pattern
`docs/spec/day-view.md` `DAY-DERIVE-1` uses for the same reason. It is **not** merely a product
preference: **no API can report that the store is synchronised.** Two Apple staff answers settle it.
A successful `.import` means only that *"your device is 'current' with whats in iCloud … it doesn't
imply anything about the state of other devices"* (Frameworks Engineer, forum thread 744709), and the
notification *"tells you the state of an individual `export` or `import` event, and not that the whole
Core Data store is synchronized with the CloudKit server (or not), because there may have new changes
happening on the CloudKit server while the event is being handled"* (DTS Engineer, thread 763876, on
SwiftData specifically). A "synced" indicator would therefore assert something unknowable, on the
screen the mother would most reasonably trust — in an app with no export
([#683](https://github.com/jirigrill/eczema-helper/issues/683)) where that assertion is the last line
of defence.

> **⚠ Divergence 8.** *PWA:* nothing — the app has no sync of any kind, so it reports no sync state and
> the question never arose. *iOS:* the silence is a numbered prohibition rather than an absence. *Why:*
> once sync exists, a healthy-state indicator is the first thing an implementer adds, and no API can
> honestly support one. Settled by [#723](https://github.com/jirigrill/eczema-helper/issues/723).

**`SET-SYNC-2` (MUST)** — A sync failure is judged only from an event that has **ended**. An event
whose end date is absent is in flight and is never a verdict.

The single most dangerous detail in this area. An in-flight event reports *not succeeded*, so an
indicator reading success alone reports failure **on every launch during healthy setup** — the
cries-wolf outcome [#687](https://github.com/jirigrill/eczema-helper/issues/687) rates as worse than
no indicator at all. Apple's own guidance is the three-part predicate — match the event type, match
the store, and check the end date is not nil (WWDC22 session 10119; sample
`SynchronizingALocalStoreToTheCloud`). **Apple's other sample gets this wrong**, checking success
before the end date so an in-flight event takes the failure branch
(`SharingCoreDataObjectsBetweenICloudUsers`, `PersistenceController+Deduplicate.swift`) — the two
samples contradict each other and the app-facing one is the wrong one, which is why this is a rule
rather than a note.

**`SET-SYNC-3` (MUST)** — Two failure messages exist, keyed to the **consequence for her**, never to
the event type or the error:

| Failing operation | What she is told |
| --- | --- |
| Upload, or mirroring failing to initialise | Her records are **on this phone only** — not yet copied to iCloud. |
| Download | This phone **may not be showing everything** recorded on another device or before a reinstall. |

Three event types collapse onto two messages because only two consequences differ for her. A
mirroring-initialisation failure sits with upload: when mirroring never starts, nothing leaves the
phone, and the durability consequence is the one that matters. Keying on event *type* rather than on
an error code is also what makes these rules writable at all — see `SET-SYNC-8`.

**`SET-SYNC-4` (MUST)** — A failure is surfaced only once it is **persistent**: no successful upload
for **24 hours** while unexported changes are pending. A single failure is never surfaced.

`SET-ICLOUD-4` makes this a **durability** gate rather than a connectivity one, and the same
reasoning has to apply one level down or the gate stops meaning anything: a tunnel, a lift or a
basement must produce no warning. **The threshold is wall-clock and cannot be a count of failures**,
because Apple documents no retry schedule for mirroring — automatic recovery is documented for
*throttles* only (*"stops synchronization when hitting rate limit throttles, and automatically
recovers when the throttles expire"*, TN3164), quota is never documented as a throttle, and any
backoff, attempt cap or give-up condition is `NOT FOUND`. "Three consecutive failures" would
therefore have no knowable duration behind it. 24 hours is chosen against usage: this app is opened
roughly daily, so a day of silence is the natural unit, and it survives a phone left in a drawer over
a weekend.

**`SET-SYNC-5` (MUST)** — The upload-failure message appears as the persistent non-blocking banner of
`SET-ICLOUD-2`, and as a line in Settings.

**A correction to #687, which this section inherited.** #687 recorded the banner as *"a deliberate
departure from the HIG"*, citing Apple's *"you don't need to display an alert notifying them iCloud is
unavailable"*. **The sentence does not end there.** The HIG's iCloud page continues: *"However, it may
still be helpful to unobtrusively let people know that changes they make won't be available on other
devices until they restore iCloud access."* Apple's objection is to an **alert**, and the second clause
affirmatively endorses exactly what these rules specify. The same page asks for *"subtle feedback"* on
slow updates and for apps to *"Respect iCloud storage space."* So a passive, non-modal banner is
**inside** the guidance, not a departure from it — and nothing here needs the departure justification
#687 wrote. Recurring word across all three statements: *unobtrusive*.

**`SET-SYNC-6` (MUST)** — The download-failure message appears **only** as a line in Settings, except
when the store holds no records at all, in which case it also takes the banner.

She can do nothing about a failed download, so a persistent banner on every screen would be alarm
without a remedy. The exception is the case
[#712](https://github.com/jirigrill/eczema-helper/issues/712) exists to prevent: a mother who has
just reinstalled, looking at an app with no records in it, reading apparent total data loss. An empty
store plus a failed download is exactly that moment, and the only time this message is explanatory
rather than merely worrying. Note this reads emptiness for something far weaker than the first-run
detection #712 ruled out: not to decide who she is, only whether a failure is worth showing, where a
false positive shows an accurate message slightly too eagerly.

**`SET-SYNC-7` (MUST)** — The upload-failure copy names **full iCloud storage as a likely cause** and
routes her to iOS Settings to manage it, without asserting that it *is* the cause.

Hedged deliberately, because the app cannot know (`SET-SYNC-8`) — but it is the most likely cause and
the only one she can fix, and Apple's sole published recovery instruction for private-database quota
is to *"Prompt the user to go to iCloud settings to manage their storage."* Copy that named quota
outright would assert what the app cannot observe; copy that named nothing would report a problem
with no route to fixing it.

**`SET-SYNC-8` (MUST NOT)** — No rule, message or branch is keyed to a specific CloudKit error code.

Not caution — **quota exhaustion is not detectable through the mirroring API**, confirmed by Apple
staff as a known framework issue. The quota error *"is nested inside the CloudKit operation's internal
partial failures dictionary, and `NSPersistentCloudKitContainer` does not preserve or populate
`partialErrorsByItemID` … on the public `Event.error` object"* (DTS Engineer, thread 840348, Aug 2026,
with a third-party feedback report on file); a Frameworks Engineer confirms the intent is otherwise —
*"We expect the `eventChangedNotification` to include the full error payload … If that's not
happening we would like the fix that"* (thread 830420, accepted, Jun 2026). So it is a bug, not a
design, and until it is fixed the outer error is `NSCocoaErrorDomain 134410` — **the same code Apple
documents for fatal setup failure** — so a code cannot even distinguish "her iCloud is full" from
"mirroring never initialised". Apple's only workaround is a probe write via raw CloudKit followed by a
delete, which DTS itself calls *"far from ideal"*; it is not specified here.

> **⚠ Divergence 9.** *PWA:* nothing — no sync, so no failure copy and no error taxonomy. *iOS:* quota
> is named as a **likely** cause and no rule branches on an error code. *Why:* forced by the platform,
> not chosen — the quota error is unreachable through the mirroring API, and the outer code is the same
> one Apple documents for fatal setup failure, so a confident message would be a guess presented as a
> diagnosis.

**`SET-SYNC-9` (MUST)** — A failed upload never means a lost record. Copy says **not yet copied to
iCloud**, never *not saved*.

Documented, not reassurance. TN3163: *"When you perform a save, Core Data writes the data to the
store and records the changes in the persistent history."* The export queue *is* that on-disk
persistent history, so an unexported change survives termination and a later launch can still upload
it. A quota condition means "not uploaded"; it never means "not recorded".

**`SET-SYNC-10` (MUST)** — Sync-event failures are captured to a **local diagnostic log** at the
moment they are observed: the error's full detail, the event type, and the time. The log is pruned to
a bounded number of recent entries.

The one irreversible decision in this area, which is why it ships in v1 with no UI attached. Error
detail exists **only live on the notification** — events re-read afterwards retain *"only the domain /
code of the original error"* (Frameworks Engineer, thread 830420; TN3163). An app that does not
capture at notification time has lost the detail permanently. It is also the only route by which the
open question of *which codes actually arrive* (§10) can ever close from real use, rather than from
another spike that cannot provoke a failure.

**`SET-SYNC-11` (MUST NOT)** — The diagnostic log has no user-facing surface in v1: it is not
displayed, not exported, and not shared.

Deliberately capture-only. A share-to-support flow would send an infant's medical record to the
developer's inbox — Bear warns its own users that sync logs *"can contain pieces of text of your
notes"* and asks them to redact before sending; the equivalent here is health data about a child,
which would make the developer a recipient and require a new disclosure in the Art. 13 notice
([#709](https://github.com/jirigrill/eczema-helper/issues/709)). Reading and sharing are **additive**
and cheap to add later; the capture in `SET-SYNC-10` is the part that cannot be added retrospectively.

**`SET-SYNC-12` (MUST)** — The app records the time of the last successful upload and the last
successful download.

The upload timestamp is a **correctness requirement, not a display feature** — nothing in `SET-SYNC-1`
shows it to her. Apple gates persistent-history purging on it: purging history that mirroring still
needs *"invalidates some internal state, and triggers a `reset` operation that synchronizes the store
with the CloudKit server truth"*, and apps are told to gate purging on the start date of the last
successful export event. Whatever purges history is
[#730](https://github.com/jirigrill/eczema-helper/issues/730)'s to specify; this rule exists so the
value is being recorded before anything needs it. The download timestamp is
[#712](https://github.com/jirigrill/eczema-helper/issues/712)'s banked value, which that ticket
recorded for this section to read — under `SET-SYNC-1` nothing reads it in the UI, so it survives as
a diagnostic only.

---

## 5. Privacy and the notice

**`SET-PRIVACY-1` (MUST)** — Settings offers a route to the Art. 13 privacy notice.

**`SET-PRIVACY-2` (MUST)** — The route opens the notice **as a screen in the app**, rendered from
text compiled into the bundle. It does not open a browser, and it does not fetch anything.

Settled by [#709](https://github.com/jirigrill/eczema-helper/issues/709). Two independent reasons.
Apple's guideline 5.1.1(i) requires *"a link to their privacy policy in the App Store Connect
metadata field **and within the app in an easily accessible manner**"* — so an in-app route is
mandatory, not a choice. And the notice is the one document that must be readable in exactly the
conditions a network is not: `SET-ICLOUD-4` requires the app to work in a basement, and a notice that
404s or spins is not *"easily accessible"* in the sense WP260 para 11 means. Bundling it also
forecloses the drift question — the text she reads is the text her consent record names
(`SET-PRIVACY-6`).

Whether embedded text *by itself* discharges 5.1.1(i) is **`NOT FOUND`** in Apple's documentation:
the guideline says "link", the ADPLA §3.3.3(C) says *"in Your Application, on the App Store, and/or
on Your website"*, and Apple has never reconciled the two
(`docs/research/privacy-notice-hosting.md` §2.2). This section does not need the question answered,
because `SET-PRIVACY-7` requires the hosted URL as well — a bundled screen **plus** the App Store
Connect URL satisfies every reading of the guideline without an interpretive claim about Apple's
intent.

**`SET-PRIVACY-3` (MUST)** — Settings names the **system deletion path** — Apple's own route to
delete this app's data from iCloud, in iOS Settings — as a second route, independent of
`SET-DELETE-1`.

The in-app control is unreachable once the app is deleted, and this is the only path that still
works then. Apple's route exists and is confirmed by the error it produces: `CKError.userDeletedZone`
is documented as *"an error that occurs when the user deletes a record zone using the Settings app"*
(`docs/research/settings-data-deletion.md` §C).

**`SET-PRIVACY-4` (MUST NOT)** — The app does not state that deleting the app removes her iCloud
data, and does not state that it preserves it. **This binds the notice too, not only the screen.**

Apple documents **neither** — the dedicated article on deleting an app mentions iCloud only to link
to a separate article about *Backup*, and the question is `NOT FOUND` in both directions
(`docs/research/settings-data-deletion.md` §C). The existence of the system deletion path implies
the data survives, but an implication is not a citation, and this is a statement to a mother about
where her infant's health records are. State the path (`SET-PRIVACY-3`); do not narrate the
consequence of uninstalling.

> **Divergence 7 — the notice states the deletion *path*, never the uninstall *consequence*.**
> **PWA:** no notice exists, and the question cannot arise — there is no server and no iCloud.
> **iOS:** [#705](https://github.com/jirigrill/eczema-helper/issues/705) obliged the notice to state
> *"data already in iCloud stays there until deleted, and how to delete it"*. The survival half is
> **not stated**; the deletion path is.
> **Why:** a direct conflict, resolved in favour of the sourced half.
> [#716](https://github.com/jirigrill/eczema-helper/issues/716) found the survival claim `NOT FOUND`
> in both directions and wrote `SET-PRIVACY-4` forbidding the app from asserting it either way — so
> the notice cannot both state it and not state it. The **substance** of #705's requirement survives
> intact without the unsourced mechanism: Art. 13(2)(a) retention ("kept until you delete it; the
> developer holds no copy") plus the two deletion routes (`SET-DELETE-1`, `SET-PRIVACY-3`) tell her
> everything actionable. What is dropped is a claim about what iOS does on uninstall, which is Apple's
> to document and Apple has not.

**`SET-PRIVACY-5` (MUST)** — The notice is reachable in **at most two taps** from the day view, under
a plainly-named route.

WP260 para 11 offers *"never more than 'two taps away'"* as **one way** to meet the accessibility
test, not as the test itself — the rule is that she *"should not have to seek out the information"*.
Two taps is adopted because it is the only numeric figure any endorsed source states, and because
Settings is already one tap from the day view (`SET-NAV-1`), so the notice is the second and the
budget is met by the navigation this screen already has. Apple's own definition of *"easily
accessible"* is **`NOT FOUND`** — the phrase appears twice in the Review Guidelines, undefined both
times (`docs/research/privacy-notice-hosting.md` §2.1) — so this rule is sourced to WP260 alone and
must not be attributed to Apple.

**`SET-PRIVACY-6` (MUST)** — The notice carries a **revision identifier** — an opaque monotonic
string, `v1`, `v2`, … — displayed on the notice itself, and the consent record stores the identifier
of the revision she was actually shown.

No source requires a version number or a date: *"version"* appears **0 times** in the GDPR and **0
times** in WP260 (`docs/research/art-13-notice-form.md` §3.1). The requirement is one step removed
and is mandatory in its own terms — EDPB 05/2020 para 108 requires that *"the information provided to
the data subject at the time shall be demonstrable"*, illustrates it with *"a copy of the information
that was presented to the data subject at that time"*, and rules out the cheap substitute: *"It would
not be sufficient to merely refer to a correct configuration of the respective website."* An
identifier plus bundled text is the cheapest thing that satisfies that, since the text ships with the
binary anyway.

The identifier is deliberately **not** the app's build or version number, and not a date. A build
number over-versions — most releases will not touch the notice, and a consent record naming build 47
implies a text that changed 46 times. A date under-specifies if two edits land in one day. The
revision is bumped when the notice's **wording** changes, which is a different question from whether
consent must be re-obtained: EDPB 05/2020 para 110 triggers re-consent on *"the processing operations
change[ing] or evolv[ing] considerably"*, not on rewording, and no source consulted says a
wording-only change invalidates consent.

> **Divergence 6 — the notice is versioned though nothing requires it.**
> **PWA:** no privacy notice exists at all — there is no privacy string, no route, and nothing in
> `src/`. This is a from-scratch artifact, not a port.
> **iOS:** the notice carries a revision identifier and the consent record stores it.
> **Why:** not a port decision but a consequence of taking Art. 9(2)(a) explicit consent, which the
> PWA never did. Apple requires no versioning either (`NOT FOUND`,
> `docs/research/privacy-notice-hosting.md` §5.1) — and Apple stores only the *URL*, never the text
> (§5.2), so **the developer is the only party retaining the notice's history**. Attributing this
> rule to Apple would be wrong.

**`SET-PRIVACY-7` (MUST)** — The same revision is also served at a **stable public URL**, and that
URL is what the App Store Connect Privacy Policy field holds.

Required by 5.1.1(i) independently of the in-app route, and the field is mandatory for submission.
The rule says **stable** for a mechanical reason: Apple's editability table marks Privacy Policy URL
`Required` and `Localized` but leaves `Editable` **blank** — the same class as the app **Name** — and
App Store Connect Help states the consequence outright, *"Any changes to the URLs releases with your
next app version"* (`docs/research/privacy-notice-hosting.md` §1.3). So **moving the URL costs a
submission, while editing the content behind it costs nothing.** The URL must be one that can be held
for the app's lifetime, which is why it is not tied to a repo name or an account plan.

Which domain is a deployment decision, not a behavior one, and is deliberately **not** fixed here —
it is a pre-submission blocker in the same class as the app's real name
([#697](https://github.com/jirigrill/eczema-helper/issues/697)) and trader status. The spec constrains
only that the URL is stable and that the served text is not *older* than the shipped one
(`SET-PRIVACY-8`).

**`SET-PRIVACY-8` (MUST NOT)** — The served page is never a revision **older** than the one in the
shipped app.

Drift is one-directional by construction: a phone running an old build holds old text, which is
expected and correct — that is what her consent record names. A website behind the current release is
a defect, because it is the copy a person who has not installed the app reads. The bundled text is
authoritative for what *that user* consented to; the served copy is authoritative for nothing, which
is why both display the revision identifier and a reader can tell which is which.

**`SET-PRIVACY-9` (MUST NOT)** — The notice does not state that the processor contract with Apple
fails Art. 28(3), and does not otherwise characterise the developer's own compliance.

It states the **facts** instead, which are the actual Art. 13 disclosures: Apple receives the data,
Apple's sub-processors are not published so recipients are named at **category** level, storage
location is at Apple's contractual discretion, and no adequacy safeguard is verified. What stays out
is the legal *characterisation*.

Nothing in Art. 13(1) or (2) reaches a processor-contract deficiency, and requiring a controller to
confess its own non-compliance to data subjects is **`NOT FOUND`** across EDPB and WP29 guidance
(`docs/research/art-13-notice-form.md` §4.2). The distinction the rule turns on is textual and clean:
Art. 30(4) sends the record of processing *"to the supervisory authority on request"*, whereas
Arts. 12–14 govern what reaches the data subject. The assessment is the accountability deliverable
and it belongs in the internal file
([#694](https://github.com/jirigrill/eczema-helper/issues/694) §5.7). Disclosing the characterisation
would also assert the controller reading, which #694 left deliberately **UNSETTLED**.

This is a narrowing rule, not a licence: the EDPB is blunt that weak bargaining power does not excuse
accepting non-compliant processor terms, so the underlying exposure is real. It is simply not a
transparency problem.

**`SET-PRIVACY-10` (MUST NOT)** — The notice does not state or imply that Apple participates in the
EU–US Data Privacy Framework.

**Apple Inc. is not on the DPF participant list at all** — verified against the official 42,398-entry
workbook (`docs/research/art-13-notice-form.md` §5). There is no certification to describe, no status
and no date. This is consistent with Apple's own ADPLA, which names *"Model Contract Clauses"* and
never mentions the DPF or Privacy Shield. #709 carried this as an **UNVERIFIED** status to check; the
answer inverts the question, so the transfer disclosure must rest on Apple's contractual terms alone.

**`SET-PRIVACY-11` (MUST)** — One text, in English, with no dialect split and no Czech version.

[#702](https://github.com/jirigrill/eczema-helper/issues/702) ships three catalog localizations
(`en` / `en-GB` / `en-US`) because `courgette` and `zucchini` are food names on a tile that a mother
must recognise. A privacy notice has no dialect-divergent vocabulary worth a second file, and two
texts are two things to keep in sync for no comprehension gain — with `SET-PRIVACY-6` and `-8` that
cost is real rather than notional.

No primary source requires Czech. The trigger throughout is **targeting**, not establishment: WP260
requires translation *"where the controller targets data subjects speaking those languages"*, and
Recital 23 treats language as evidence of targeting. ÚOOÚ has enforced on notice language, but only
against Czech-facing services, so the test cuts in an English-only product's favour; zákon
č. 634/1992 Sb. § 11(1) is a closed enumeration that does not reach a privacy notice
(`docs/research/art-13-notice-form.md` §2.3). If the product is ever offered in Czech, this rule is
what must be revisited first — `SET-ABSENT-6` records that no language picker exists.

**`SET-PRIVACY-12` (MUST NOT)** — The notice does not claim to be legal advice, and does not present
itself as a lawyer's work.

The owner drafts it against #694's Tier-2 table, and a review by a qualified Czech data-protection
lawyer is **recommended but not a gate this section imposes** — the content is fixed by primary
sources, so drafting is transcription, and #694's two lawyer questions (the Art. 28 conclusion, and
Art. 7(3) withdrawal under mandatory sync) are about the *product's* exposure rather than the notice's
wording. If the review happens it should be a **dated artifact**:
[#681](https://github.com/jirigrill/eczema-helper/issues/681) found that how a review is documented
bears on whether professional indemnity cover responds.

**`SET-PRIVACY-13` (MUST NOT)** — The notice does not tell her to check back for changes.

**`SET-PRIVACY-14` (OPEN)** — Whether the app **actively notifies** her when the notice changes
substantively, and by what surface, is not decided here.

These two are one finding split by how sure it is. The prohibition is sourced flatly: WP260 para 29
holds that *"References in the privacy statement/ notice to the effect that the data subject should
regularly check the privacy statement/notice for changes or updates are considered not only
insufficient but also unfair in the context of Article 5.1(a)"* — so the standard formula is barred
outright, which makes it a rule rather than a preference.

What the same paragraph requires *instead* is active, dedicated notification: *"a notification of
changes should always be communicated by way of an appropriate modality (e.g. email, hard copy letter,
pop-up on a webpage or other modality which will effectively bring the changes to the attention of the
data subject) specifically devoted to those changes"*. Every modality WP260 names assumes a channel
this app does not have — **there is no email address, no account and no server-side reach**
(`SET-ABSENT-5`); the developer cannot contact her at all. The only surface available is the app itself
on a later launch, which is a first-run decision rather than a Settings one, and it interacts with
re-consent: para 110 triggers re-consent when the *processing* changes considerably, **not** on
rewording, so a notice-change prompt and a consent prompt are different events and conflating them
would ask for consent nothing requires.

Left `OPEN` rather than guessed, per the template: filling it in means inventing either a modality or a
re-consent trigger. **No schema deadline** — and it cannot bind the first release, which has no
previous notice to have changed from.

---

## 6. Navigation

**`SET-NAV-1` (MUST)** — Settings is reached from the day view and from nowhere else
(`docs/spec/day-view.md` `DAY-ROOT-4`).

**`SET-NAV-2` (MUST)** — Leaving Settings returns to the day she came from.

**`SET-NAV-3` (MUST NOT)** — Settings is not reachable from inside an editor.

---

## 6a. Accessibility

Settings holds the product's only **irreversible** control and its only **legal** document, and the
accessibility requirements follow from those two facts rather than from the screen being complicated.
The delete-all path has no undo, no trash and no recovery (`SET-DELETE-9`), so a warning she does not
receive is a warning that did not happen; the notice is the Art. 13 disclosure, so unreachable text is
undisclosed text.

### 6a.1 The stage control

**`SET-A11Y-1` (MUST)** — The three stages are announced by their labels in the fixed order
(`SET-STAGE-2`), each with a selected state, and the current stage announces as selected. When no stage
is known (`SET-STAGE-7`) **none** announces as selected — the same requirement `first-run.md`
`RUN-A11Y-2` makes, for the same reason.

**`SET-A11Y-2` (MUST)** — Selecting a stage announces the change. `SET-STAGE-3` makes the change take
effect immediately with no save step, so the announcement is the only confirmation that anything
happened.

**`SET-A11Y-3` (MUST)** — The hint saying what the stage governs (`SET-STAGE-6`) is announced as part of
the control's label or hint, not as a separate stop she may swipe past before reaching the choices.

### 6a.2 Deleting everything

**`SET-A11Y-4` (MUST)** — The delete control announces the verb *delete* (`SET-DELETE-5`) and is
traited as destructive. Never *reset*, never *restart*, never a generic affirmative — Divergence 1's
euphemism is forbidden in the label exactly as on the button.

**`SET-A11Y-5` (MUST)** — The confirmation's full content is announced: what is destroyed — meals,
observations, photos — and that it cannot be undone (`SET-DELETE-3`). The irreversibility clause is the
substance of the warning, so it cannot be the part carried only by visual emphasis.

**`SET-A11Y-6` (MUST)** — The confirmation's destructive action announces as destructive and is
distinguishable from cancel by more than position. Cancel is reachable, and reachable without passing
through the destructive action.

**`SET-A11Y-7` (MUST)** — The post-deletion disclosures are **announced**, not merely displayed:
that the iCloud copy is still there now (`SET-DELETE-16`), the two things she can do about it
(`SET-DELETE-17`), and the `noAccount` ordering (`SET-DELETE-18`). This is the case where a
visual-only message is most costly — she lands on first run immediately (`SET-DELETE-8`), so the
message has one chance to be received, and the window it warns about closes for good if she deletes
the app.

### 6a.3 The notice and sync

**`SET-A11Y-8` (MUST)** — The route to the privacy notice announces where it goes, and the notice
itself is fully reachable and readable through assistive technology — every section, in order, with no
part behind a container that must be opened. `SET-PRIVACY-2` renders it in-app precisely so it is
always available; unreachable in-app text would defeat that.

**`SET-A11Y-9` (MUST)** — The notice's revision identifier (`SET-PRIVACY-6`) is announced as text, not
conveyed only as fine print. It is what a consent record refers to (`consent.md` `CONSENT-REC-3`), so
it must be readable by anyone checking what they agreed to.

**`SET-A11Y-10` (MUST)** — A sync-failure line (`SET-SYNC-3`, `-5`, `-6`) is announced when it appears
and names the consequence (`SET-SYNC-9` — not yet copied, never lost). The banner is announced without
taking focus, since it can appear while she is reading something else.

**`SET-A11Y-11` (MUST NOT)** — Nothing announces an affirmative sync state (`SET-SYNC-1`) — no
"synced", no "up to date", no last-upload time. `SET-SYNC-12` records that timestamp and
`SET-SYNC-11` keeps the diagnostic log off every surface; both bind announcements as well as pixels.

### 6a.4 The five questions

| # | Answer |
| --- | --- |
| 1 | **VoiceOver label and trait** — the three stage choices (`SET-A11Y-1`), the delete control and its confirmation's two actions (`-4`, `-6`), the notice route (`-8`), and the link out to iOS Settings where offered (`SET-ICLOUD-5`, `SET-PRIVACY-3`). Sync and account lines are text, announced per `SET-A11Y-10`. |
| 2 | **Dynamic Type** — the confirmation's text and the post-deletion disclosures **must never truncate or scroll out of reach**: a warning about an irreversible act, clipped, is the failure mode this whole block exists to prevent. The confirmation therefore scrolls at large sizes rather than eliding its text, and `SET-DELETE-21` — which forbids waiting indefinitely — is about the network call, not about shortening the copy. The notice is long and scrolls freely. Stage labels must not truncate; row hints may wrap. |
| 3 | **Colour alone** — one case: the delete control's destructive styling. The destructive trait (`SET-A11Y-4`) and the verb itself are the second and third channels, which is why `SET-DELETE-5` names the verb rather than leaving it to red text. |
| 4 | **Focus order and grouping** — a Settings row is one element: its label, its value and its hint announced together (`SET-A11Y-3`), not three stops. The stage choices are one group of three. Order follows the screen: stage, delete, account and sync lines, privacy. |
| 5 | **Reduce Motion** — the confirmation's presentation and the transition to first run after deletion (`SET-DELETE-8`). Under Reduce Motion both complete without animation; neither is skipped, and in particular the confirmation is still presented. |

---

## 7. What Settings does not contain

These are prohibitions with ids, not features nobody built. Each is a decision taken elsewhere that
a reader would come to this screen looking for, and an implementer filling the gap with a reasonable
guess would silently reverse it.

**`SET-ABSENT-1` (MUST NOT)** — There is no sync toggle, no way to turn sync off, and no
withdrawal-from-sync.

Settled by [#705](https://github.com/jirigrill/eczema-helper/issues/705): sync is mandatory and
always on. Settings gains **one** control from that decision — the delete-all control — not two.

**`SET-ABSENT-2` (MUST NOT)** — There is no export, no import, no PDF and no share-my-record control.

Settled by [#683](https://github.com/jirigrill/eczema-helper/issues/683), the owner's call against
the recommendation, with the exposure accepted explicitly. See §10 — an Apple document found while
writing this section bears on it, and is recorded as a correction there rather than reopened here.

**`SET-ABSENT-3` (MUST NOT)** — There is no backup control, and nothing on this screen implies a
backup exists.

CloudKit is **sync, not backup**: it survives delete-and-reinstall, which is the reason for going
native, but it has **no rollback**, so a deletion propagates everywhere. Copy that says "backed up
to iCloud" would be false in the one direction that matters.

**`SET-ABSENT-4` (MUST NOT)** — Nothing derived from her records appears in Settings: no record
counts, no storage figure, no days-logged, no summary of any kind
([INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11)).

The same distinction `docs/spec/day-view.md` `DAY-DERIVE-3` draws applies: a fact about the *app* —
that sync last succeeded at a time — is about the machine rather than her diary, and §4.1 decides it.
`SET-SYNC-1` forbids showing one. A count of *her records* is a statement about her diary, and
acquires a meaning she never recorded the moment it appears.

**`SET-ABSENT-5` (MUST NOT)** — There is no account, no sign-in, no profile and no child profile.
The app has no accounts of its own and v1 is single-child.

**`SET-ABSENT-6` (MUST NOT)** — There is no language picker. The product is English-only
([#677](https://github.com/jirigrill/eczema-helper/issues/677)), though structured for a second
language from commit one.

**`SET-ABSENT-7` (MUST NOT)** — The app ships no iOS Settings bundle. Everything on this screen
lives in the app.

Not only a preference: a Settings bundle has eight specifier types and **none of them is a button**,
so it cannot express an action at all (`docs/research/settings-data-deletion.md` §E). The
delete-all control could not have lived there even if that had been wanted.

---

## 8. Divergence index

| # | Section | Summary | Class |
| --- | --- | --- | --- |
| 1 | §3 `SET-DELETE-5` | The action is named *delete*, not *restart*. | Defect fixed |
| 2 | §3 `SET-DELETE-7` | Deletion must reach her iCloud, not only the phone. | Forced by platform |
| 3 | §3 `SET-DELETE-8` | The post-wipe navigation guard does not port. | Obsolete |
| 4 | §3 `SET-DELETE-11` | The confirmation names the camera-roll exception; the PWA claims all photos are permanently deleted, which is false for any photo she shared out. | Defect fixed |
| 5 | §7 `SET-ABSENT-1`..`-7` | The absences become numbered prohibitions rather than features that merely do not exist. | Settled by #716 |
| 6 | §5 `SET-PRIVACY-6` | The notice carries a revision identifier, though no source requires one. | Settled by #709 |
| 7 | §5 `SET-PRIVACY-4` | The notice states the deletion path but never what uninstalling does, overriding #705's requirement to state it. | Settled by #709 |
| 8 | §4.1 `SET-SYNC-1` | The app never reports healthy sync, and the prohibition is numbered rather than left as an absence. | Settled by #723 |
| 9 | §4.1 `SET-SYNC-7`, `-8` | Quota exhaustion is named only as a *likely* cause, because it is undetectable through the mirroring API. | Forced by platform |
| 10 | §3 `SET-DELETE-14`..`-21` | The deletion is two operations with a disclosed degraded path, and the local wipe deletes through the store so mirroring carries it. | Forced by platform |

Ten divergences, of which two (1 and 4) correct copy that is misleading in the shipped PWA today.
The count understates the change: §4, §5 and most of §7 have **no PWA counterpart at all**, so they
are not divergences from the reference — they are new behavior the reference never had a reason to
express. Divergences 6 and 7 are the clearest case: the PWA has **no privacy notice whatsoever** — no
privacy string, no route, nothing in `src/` — so both are divergences from a *decision taken on this
map*, not from the reference implementation.

---

## 9. Verification

### Where each rule is verified today

| Rules | Existing TypeScript tests | Verdict |
| --- | --- | --- |
| `SET-STAGE-1`, `-2` | `page.test.ts:100-107` (a pill per stage, the current one active) | **translate** |
| `SET-STAGE-3` | `page.test.ts:109-115` (selection calls the setter), `settings-feeding-stage.test.ts` end-to-end incl. survival across reload | **translate** the behavior; **re-derive** the persistence assertions, which read Dexie directly and must target `NSUbiquitousKeyValueStore` |
| `SET-STAGE-4` | none — the equality guard exists in code (`+page.svelte:23`) and nothing exercises it | **re-derive** |
| `SET-STAGE-5` | none anywhere | **re-derive** — see below, this is the notable gap |
| `SET-STAGE-6` | none | **re-derive** |
| `SET-STAGE-7` | none — the null-stage branch is never rendered in any test | **re-derive** |
| `SET-STAGE-8` | none — the PWA has no sync and no second writer | **re-derive** |
| `SET-STAGE-9`, `-10` | none — no account state exists in the reference | **re-derive** |
| `SET-DELETE-2`, `-3` | `page.test.ts:55-66` (nothing wiped until the sheet is accepted; the sheet names meals, observations and photos) | **translate** — the single most valuable guard on this screen |
| `SET-DELETE-4` | `page.test.ts:68-78` (cancel wipes nothing, navigates nowhere) | **translate** |
| `SET-DELETE-5` | `page.test.ts:46-50` asserts the warning text, but pins the *"restart"* wording Divergence 1 replaces | **do not translate** as written; re-derive against the new copy |
| `SET-DELETE-6` | `reset-database.ts` reads `db.tables` live so no table can be missed; no test asserts the outcome per table | **re-derive** — the live-table-list trick has no SwiftData analogue and the guarantee must be re-established |
| `SET-DELETE-7` | none, and none is possible in the reference — there is no server | **re-derive** |
| `SET-DELETE-8` | `page.test.ts:80-98` asserts navigation only once the settings signal flips — a `liveQuery` race guard | **do not translate** (Divergence 3); re-derive the landing state alone |
| `SET-DELETE-9`..`-13` | none | **re-derive** |
| `SET-DELETE-14`, `-15`, `-21` | none, and none is possible in the reference — there is no server and no queue | **re-derive**; all three are testable without CloudKit, by asserting call order, that the local wipe runs on a failed first part, that deletions go through the store rather than destroying it, and that the wait is bounded |
| `SET-DELETE-16`..`-19` | none | **re-derive** as copy assertions per account state; `-19` is the one to write deliberately, since treating reachable-but-failed as success is the plausible implementation slip |
| `SET-DELETE-20` | none | **re-derive** — assert a failed zone deletion lands in the diagnostic log with full detail, and that no screen reads it (`SET-SYNC-11`) |
| `SET-ICLOUD-1`..`-5` | none | **re-derive** |
| `SET-SYNC-1`..`-12` | none, and none is possible in the reference — the PWA has no sync of any kind | **re-derive**; `-2` is the one to write first, and it is testable without CloudKit by feeding the handler a synthetic in-flight event |
| `SET-PRIVACY-1`..`-4` | none | **re-derive** |
| `SET-PRIVACY-5`..`-14` | none — the PWA has no privacy notice at all | **re-derive**; `-6`, `-8` and `-11` are checked against the built bundle and the served page rather than in-app, and `-14` is `OPEN` |
| `SET-ABSENT-1`..`-7` | none | **re-derive** as absence checks; see below |
| `SET-A11Y-1`..`-11` | none — the reference has no accessibility assertions at all | **re-derive**. Three are assertable and worth writing in this order: the delete control's label carries the verb *delete* and the destructive trait (`-4`, which is Divergence 1's guard on the spoken surface and would otherwise inherit *"Restartovat"* by translation), the confirmation announces the irreversibility clause (`-5`), and no announcement anywhere carries an affirmative sync state (`-11`, the spoken twin of `SET-SYNC-1`) |

### Rules nothing verifies today

Most of this section, and the reasons differ in a way worth separating.

- **`SET-STAGE-5` — that a stage change leaves existing meals alone.** Nothing anywhere asserts it,
  in a codebase where [#712](https://github.com/jirigrill/eczema-helper/issues/712)'s data-loss path
  ran through exactly this relationship. The rule is one of the most load-bearing in the product and
  has never had a test. It is the first thing to write.
- **The whole of §4, §5 and §7.** Not gaps in the reference's coverage — the reference has no
  account state, no privacy notice and no sync to toggle. Nothing was missed; there was nothing
  there. §4.1 is the largest such block and is broken out separately below, because its rules differ
  in *why* they resist verification.
- **The notice's revision identifier reaching the consent record (`SET-PRIVACY-6`).** The half a
  Swift test can check is that the identifier stored equals the identifier of the bundled text — worth
  writing, because the failure mode is silent and only discovered when someone asks what a mother was
  shown, by which time the answer is unrecoverable. The half nothing can check is whether the text
  itself is accurate.
- **`SET-PRIVACY-8` — the served page never older than the shipped one.** Not testable from inside
  the app at all: it compares an artifact in the bundle against a hosted page. It belongs to the
  release checklist, and it is the one rule here whose violation is invisible on any device.
- **Server-side deletion (`SET-DELETE-7`, `-12`).** Cannot be verified even in principle by a unit
  test, and Apple exposes no API that reports completion. The acceptance pass is the only check, and
  it is an observation rather than an assertion.
- **The deletion's degraded path (`SET-DELETE-13`..`-21`).** Splits cleanly, and the split is worth
  respecting. The **mechanism** is unit-testable with no CloudKit at all, by injecting a failing
  zone-deletion: call order, the local wipe running anyway, deletions going through the store, the
  bounded wait, and the log capture are all assertions. The **completion** is not testable by anyone —
  whether the queued deletions ever flush is precisely what no API reports, so `SET-DELETE-17`'s
  instruction to her is load-bearing rather than belt-and-braces. Write the mechanism tests; observe
  the rest in the acceptance pass.
- **The absences (`SET-ABSENT-*`).** Testing that a feature does not exist reads as absurd until it
  is the third release and someone adds a helpful "Back up now" button. `docs/spec/day-view.md`
  found the reference's own best guard to be exactly this shape — a regression test asserting a
  removed attribute stays absent. `SET-ABSENT-1` and `-2` deserve the same, since both reverse an
  owner decision taken against a recommendation.
- **The 24-hour persistence threshold (`SET-SYNC-4`).** Unit-testable with an injected clock, and it
  must be — the two failure modes are opposite and both bad: too eager and the mother sees a warning
  every time she logs a meal in a lift, too patient and a genuinely broken sync stays quiet for a day.
  What no test settles is whether 24 hours is the right number; that is a judgment, and the owner
  confirmed it in [#767](https://github.com/jirigrill/eczema-helper/issues/767) (§4.1).
- **The diagnostic log (`SET-SYNC-10`, `-11`).** Testable and cheap — assert a synthetic failure event
  lands in the log and that no screen reads it — but note what the test cannot cover: `-11` is a
  prohibition on a surface nobody has asked for yet, so the test's whole value is holding that line
  in a later release.
- **Everything else in §4.1 that needs a real failing CloudKit account.** `SET-SYNC-5`..`-7` and `-9`
  need quota actually exhausted or the network actually down on a device, which is the acceptance pass
  below, not a test. `SET-SYNC-2` is the exception and the one to write first: a synthetic in-flight
  event is enough to prove the app stays silent about it.
- **`SET-STAGE-9`/`-10` in a real degraded state.** Requires a signed-out device; see the standing
  ceiling on account-state testing recorded on
  [#704](https://github.com/jirigrill/eczema-helper/issues/704).
- **The whole of §6a.** Nothing in the reference asserts anything about the accessibility surface, and
  on this screen two of the gaps are consequential. `SET-A11Y-4`: the delete control's *label* is where
  Divergence 1's euphemism is most likely to survive the port, because a translator working from
  `common.ts` gets *"Restartovat"* and the visual button can be corrected without anyone re-reading the
  label. `SET-A11Y-7`: the post-deletion disclosures have exactly one chance to be received — she lands
  on first run immediately — so a visual-only message is a warning never given, and the window it warns
  about then closes permanently.

### Acceptance pass

Instructions for a person holding a phone. Steps marked **✗ PWA** are expected to fail on the
reference implementation — those are the divergences, and they are what prove the port did
something.

1. Open Settings from the day view. Confirm you cannot reach it from inside a meal editor or the
   skin screen (`SET-NAV-1`, `-3`).
2. Read the whole screen. There is **no** switch for iCloud or sync, **no** export, share, or
   backup control of any kind, and **no** number anywhere describing your records
   (`SET-ABSENT-1`, `-2`, `-3`, `-4`).
3. Change the feeding stage. It takes effect immediately — no save button, no confirmation
   (`SET-STAGE-3`).
4. Go back to a day where you had logged a meal for the other actor. It is **still there**,
   unmarked and still editable (`SET-STAGE-5`). **✗ PWA** — the reference hides it.
5. Return to Settings and tap the stage that is already selected. Nothing happens
   (`SET-STAGE-4`).
6. Turn on airplane mode. Settings says **nothing** about iCloud, and you can still log a meal
   (`SET-ICLOUD-4`).
7. Sign out of iCloud in iOS Settings and return. Settings now carries a line saying, in plain
   words, that new records cannot be created and what is on the phone is not being copied anywhere —
   not a status code (`SET-ICLOUD-1`, `-3`).
8. Still signed out: change the feeding stage. It works, and the control looks exactly as it did
   before — not greyed, not annotated (`SET-STAGE-9`, `-10`).
9. Find the route to the privacy notice, and the line naming Apple's own path for deleting this
   app's data from iCloud in iOS Settings (`SET-PRIVACY-1`, `-3`).
10. Count the taps from the day view to the notice's first line of text. It is **two or fewer**, and
    the route is named something you would look for — "Privacy" — not buried under an "About"
    (`SET-PRIVACY-5`).
11. Turn on airplane mode and open the notice again. It renders **in full**, in the app: no browser
    opens, no spinner, no error (`SET-PRIVACY-2`). **✗ PWA** — there is no notice to open.
12. Find the revision identifier on the notice — `v1` or similar — and check the same identifier is
    what the app recorded when you consented on first run (`SET-PRIVACY-6`).
13. Open the App Store Connect privacy policy URL in a browser. It serves the **same text** and shows
    a revision identifier **not older** than the one in the app (`SET-PRIVACY-7`, `-8`).
14. Read the notice end to end, checking five things it must **not** say: that the contract with Apple
    falls short of any legal requirement (`SET-PRIVACY-9`); that Apple is certified under the EU–US
    Data Privacy Framework (`SET-PRIVACY-10`); that it is legal advice (`SET-PRIVACY-12`); that you
    should check back for updates (`SET-PRIVACY-13`); and anything at all about what deleting the app
    does to your iCloud data (`SET-PRIVACY-4`).
15. Check what it **does** say about Apple: that Apple receives the data, that Apple's own
    sub-processors are described by category rather than named, that where it is stored is Apple's
    choice, and that no adequacy safeguard is verified (`SET-PRIVACY-9`).
16. Confirm the notice is in English, and that there is no language picker anywhere
    (`SET-PRIVACY-11`, `SET-ABSENT-6`).
17. Sign back in. Tap the delete-all control. Read the button: it says **delete**, not "restart" or
    "OK" (`SET-DELETE-5`). **✗ PWA**
18. Read the confirmation: it names meals, observations and photos, says it cannot be undone, and
    says that photos you saved to your camera roll are **not** removed
    (`SET-DELETE-3`, `-9`, `-11`). **✗ PWA** on the camera-roll line.
19. Cancel. Everything is still there (`SET-DELETE-4`).
20. Tap it again and confirm. You land on first run and are asked for the feeding stage — the same
    state as a fresh install (`SET-DELETE-8`). The app does not quit (`SET-DELETE-10`).
21. Complete first run, then check the day view: it is empty (`SET-DELETE-6`).
22. On a second device signed into the same iCloud account, confirm the records are gone there too
    (`SET-DELETE-7`). **✗ PWA** — the reference has no server. Note this is an observation, not a
    guarantee: nothing certifies server-side completion (`SET-DELETE-12`).
23. Check that a photo you had shared to the camera roll is **still in Photos** — the deletion did
    not reach it, exactly as the confirmation said (`SET-DELETE-11`).
24. With everything healthy and signed in, look for any mention of sync on **every** screen: Settings,
    the day view, the skin screen, the meal editor. There is **none** — no "synced", no "last synced",
    no cloud icon, no spinner (`SET-SYNC-1`). This step passes by finding nothing.
25. Turn on airplane mode, log a meal, and wait. For the whole of the first day there is still
    **nothing** — no banner, no warning (`SET-SYNC-4`). Then check the meal is still there and
    editable: a pending upload is not a lost record (`SET-SYNC-9`).
26. Leave the device offline past 24 hours with that meal unsynced. A persistent, non-blocking banner
    now appears, and it says her records are on this phone only, mentions that iCloud storage may be
    full, and routes to iOS Settings (`SET-SYNC-5`, `-7`). It is not an alert and does not block
    anything. Tap it: it lands on the Settings line (`SET-ICLOUD-2`).
27. Restore the network. The banner clears on the next successful upload, and the meal reaches a second
    device (`SET-SYNC-4`).
28. Hardest step, and the one worth doing on a spare device: delete the app, reinstall, and launch it
    with the network **off** so the download cannot run. The store is empty, so the banner appears and
    says this phone may not be showing everything — the explanation for an empty screen
    (`SET-SYNC-6`). Restore the network; records arrive and the banner clears.
29. Repeat 28 with records **already** on the phone and the network off. This time there is **no**
    banner — only a line in Settings (`SET-SYNC-6`). This is the step that distinguishes the two
    failure messages, and it is the easiest to get wrong.
30. Verification of `SET-SYNC-10`..`-12` is not a manual step — the diagnostic log has no surface
    (`SET-SYNC-11`). Confirm from the code and its tests that a failure is captured with full error
    detail at notification time, and that the two success timestamps are recorded.
31. Now the degraded deletion, and it needs records worth deleting — log a few meals with photos
    first. Turn on airplane mode, then tap the delete-all control and confirm. It **works**: nothing
    refuses, nothing is greyed out, and you land on first run with the phone's records gone
    (`SET-DELETE-13`). Note how long it took — it must not hang waiting for the network
    (`SET-DELETE-21`).
32. Read what it told you: that the copy in your iCloud is **still there now**, that it is removed
    when the phone is next online, and both remedies — open the app again with signal, and Apple's own
    route in iOS Settings (`SET-DELETE-16`, `-17`). It must not say the iCloud data has been deleted
    (`SET-DELETE-12`).
33. Restore the network and open the app. On a second device signed into the same account, the records
    disappear — the queued deletions flushed (`SET-DELETE-15`). Timing is Apple's, so give it minutes,
    not seconds; this is an observation, and there is no signal that says it finished.
34. Repeat 31 signed **out** of iCloud entirely. Same outcome, but the copy now **leads with** Apple's
    system deletion path and presents the local wipe as the part that clears this phone
    (`SET-DELETE-18`). This is the state where the in-app control alone cannot finish the job, and the
    step exists to check the app says so.
35. Follow that system path in iOS Settings and confirm it reaches this app's data
    (`SET-PRIVACY-3`) — the route the app just recommended, walked once so it is known to exist.
36. Optional but valuable, and it needs a developer build: force the zone deletion to fail while
    online. The deletion still completes locally and you see **the same** copy as step 32, not an
    error code (`SET-DELETE-19`). Then confirm from the log that the failure was captured with full
    detail (`SET-DELETE-20`).
37. **Turn VoiceOver on** and open Settings. Each row is one stop that reads its label, its value and its
    hint together — the stage row tells you the current stage and what it governs without you having to
    hunt for a second element (`SET-A11Y-1`, `-3`).
38. Change the stage under VoiceOver. You hear the change (`SET-A11Y-2`). There is no save control to
    look for, which is why the announcement is the confirmation.
39. Land on the delete control under VoiceOver. It says **delete** and announces as destructive
    (`SET-A11Y-4`). **✗ PWA** — the reference calls it *restart*.
40. Activate it and listen to the whole confirmation without looking. You hear what is destroyed **and**
    that it cannot be undone (`SET-A11Y-5`), and you can reach cancel without going through the
    destructive action first (`SET-A11Y-6`).
41. Go through with it, offline, under VoiceOver. The disclosure that the iCloud copy is still there —
    and the two things you can do about it — is **spoken**, not merely on screen (`SET-A11Y-7`). This is
    the one message in the product with a single chance to land.
42. Open the privacy notice under VoiceOver. Every part of it is reachable, in order, with nothing behind
    a container you have to open, and the revision identifier is readable (`SET-A11Y-8`, `-9`).
43. Listen to the whole of Settings for a claim that sync is working — "synced", "up to date", a last
    upload time. There is none (`SET-A11Y-11`).
44. Set Dynamic Type to the **largest accessibility size** and open the delete confirmation. Its full
    text is still reachable — it scrolls if it must — and the irreversibility sentence has not been
    clipped away (§6a question 2).

---

## 10. Open questions

**`SET-DELETE-13` is settled** — resolved by
[#733](https://github.com/jirigrill/eczema-helper/issues/733) as `SET-DELETE-13`..`-21` in §3, and no
longer open. The control **never refuses**; the zone deletion is attempted first and the local wipe
proceeds regardless; the deletions go through the store so mirroring carries them when the account is
next reachable; and the degraded case is disclosed, with the system deletion path and *open the app
once more while online* named as the two remedies. **Still no schema deadline** — deliberately, since
the rejected alternative (destroy the store outright plus a durable pending-deletion marker) would
have created one that additive-only promotion makes permanent.

One gap the resolution names rather than closes: the app **cannot tell whether the queued deletions
have flushed**. No API distinguishes "not yet exported" from "exported"
(`docs/research/cloudkit-unavailable-behavior.md`), so `SET-DELETE-17`'s instruction to her is the
mechanism, and there is no supervisory check behind it. That is a platform limit, not an unmade
decision.

**`SET-PRIVACY-14` — notifying her that the notice changed.** WP260 para 29 requires active,
dedicated notification of substantive changes and bars the "check back regularly" formula outright
(`SET-PRIVACY-13`), but every modality it names — email, letter, a pop-up on a webpage — assumes a
channel this app does not have: no email address, no account, no way for the developer to reach her.
The only available surface is the app on a later launch, which makes it a first-run decision
([#729](https://github.com/jirigrill/eczema-helper/issues/729)) rather than a Settings one. It must
not be conflated with re-consent, which EDPB 05/2020 para 110 triggers on the **processing** changing
considerably rather than on rewording. **No schema deadline**, and it cannot bind the first release,
which has no previous notice to have changed from.

**The notice's prose, and the consent record's schema.** #709 settled the notice's *rules*; the ~1,500
words a mother reads are drafting, deliberately not in this section, and mechanical against #694's
Tier-2 table. Two things it hands forward. The **revision identifier is a persisted field** on the
consent record (`SET-PRIVACY-6`), so it is deadlined by
[#730](https://github.com/jirigrill/eczema-helper/issues/730)'s schema — the only schema surface §5
has, and the reason the "no schema deadlines" note below is narrower than it was. And a **stable
public URL must exist before the first submission** (`SET-PRIVACY-7`): the App Store Connect field is
mandatory to submit and **not editable without a version submission**, which puts it in the same
pre-submission class as the app's real name and trader status.

**What the notice must claim about encryption.** `encryptedValues` protects **values, never
structure** — Core Data stores relationships as plaintext foreign keys
([#714](https://github.com/jirigrill/eczema-helper/issues/714)) — so any statement about what Apple
can see has to be written narrowly. Not an open question so much as a drafting constraint that
`SET-PRIVACY-9`'s facts must respect: "encrypted" without qualification would overclaim.

**Which CloudKit error codes actually reach the app.** Unverified, and it is the one gap §4.1 cannot
close by reasoning. Every event in every measured run succeeded, so the error field stayed empty
([#713](https://github.com/jirigrill/eczema-helper/issues/713) item 5, measured on a physical device);
provoking one needs a deliberately failing account state, such as an exhausted quota. Two facts make
this narrower than it sounds. Quota specifically is **not reachable at all** today — Apple staff
confirm the payload is dropped before it reaches the public event (`SET-SYNC-8`) — so no amount of
testing would surface it until the framework is fixed. And **no rule here depends on the answer**:
`SET-SYNC-3` keys on the event type, which is typed and verified, so the codes are wanted for
diagnosis rather than for behavior. `SET-SYNC-10`'s capture is what turns this from a question needing
another spike into one that answers itself from real use. **No schema deadline** — the diagnostic log
is local, unsynced, and freely reshapeable.

**Apple asks CloudKit apps to provide export, and `SET-ABSENT-2` does not.** Found while writing
this section. Apple's *Providing User Access to CloudKit Data* states that *"apps that integrate
with CloudKit need to provide users with a way to view and export their data"* — current, and
conditioned on exactly what this app does. It is **not** in the App Store Review Guidelines (5.1.1
was read in full and it is absent), so it reads as developer guidance rather than a review gate.
[#683](https://github.com/jirigrill/eczema-helper/issues/683) declined export without this document
in view. **Owner's call: recorded as a correction on #683 and carried; not reopened.** Stated here
because a future reader of `SET-ABSENT-2` will find that document too and should not have to
re-litigate it. Full detail: `docs/research/settings-data-deletion.md` §"Contradictions".

**One schema deadline, arriving with #709 — and #733 declined to add a second.** This section had none
when it was written, and the note was worth stating because a section about deletion and sync looks
like it should. It now has exactly one: the **notice revision identifier stored on the consent record**
(`SET-PRIVACY-6`), deadlined by
[#730](https://github.com/jirigrill/eczema-helper/issues/730)'s schema promotion, because
additive-only promotion means a field never recorded cannot be backfilled — and a consent record
that cannot name the text she was shown is exactly what EDPB 05/2020 para 108 rules insufficient.
Every other rule here reads or destroys records the persistence section already owns, and the feeding
stage lives outside the store by #691's decision.

The second was avoidable and was avoided. #733's degraded-deletion path could have been built on a
durable pending-deletion marker — a persisted field, and therefore a deadline on the same promotion.
`SET-DELETE-15` uses ordinary queued deletions instead, so the retry mechanism is the platform's
rather than the schema's. Worth recording as a decision rather than an absence: the marker design is
the one that reads as more careful, and it is the one that would have put a permanent field in the
schema for a branch that only fires when the account is unreachable.

---

## 11. Appendix: what this section does not contain

- **First run and the feeding-stage picker's first appearance.** Owned by
  [the first-run section](https://github.com/jirigrill/eczema-helper/issues/729), including the
  onboarding-session arriving-wins exception `SET-STAGE-8` defers to, what is preselected, and what
  first run does in a degraded account state.
- **The day view**, including how a stage change becomes visible there.
  [`day-view.md`](day-view.md) owns `DAY-STAGE-1`/`-2`/`-3` and `DAY-MEAL-2`/`-3`.
- **The persistence model** — the SwiftData schema, CloudKit configuration, `encryptedValues` field
  list, dedupe, and the zone-deletion mechanics `SET-DELETE-7` requires. §3 now fixes the *order* of
  the two deletions and that the local one goes through the store (`SET-DELETE-14`, `-15`); how the
  zone is enumerated and deleted, and how a store-wide delete-through-the-context is performed, remain
  [#730](https://github.com/jirigrill/eczema-helper/issues/730)'s. §3 takes on **no schema surface** —
  the rejected pending-deletion marker was the only candidate.
- **Where the sync-event observer lives, and what purges persistent history.** §4.1 says what the app
  tells her and what it must capture; the notification subscription, the diagnostic log's storage, and
  the purge gated on `SET-SYNC-12`'s upload timestamp are
  [#730](https://github.com/jirigrill/eczema-helper/issues/730)'s. The rule exists so the timestamp is
  recorded before anything needs it, not to specify the purge.
- **The consent screen and the refusal path.** [#705](https://github.com/jirigrill/eczema-helper/issues/705)
  settled that consent is one checkbox covering recording and sync, and explicitly left the
  decline-terminal-state unspecified. It is not this section's.
- **The content of the privacy notice** — its ~1,500 words of prose. §5 settles the notice's *form*,
  where it lives, what it may not say, and how a revision is identified; the wording itself is
  drafting against [#694](https://github.com/jirigrill/eczema-helper/issues/694)'s Tier-2 table.
- **The App Store Connect listing surface** — the privacy nutrition labels, the domain the policy URL
  points at, and trader status. `SET-PRIVACY-7` requires the URL to be stable and to serve the same
  text; which host, and what the labels declare, are submission-time work.
- **Layout, colour, typography, control shapes and component names.** Rules here constrain what the
  screen does and what it may claim, never how it looks — including whether the stage control is a
  segmented control, a list or chips.
- **Invariant text.** Cited by anchor, never copied.

**On the design prototype:** `redesign-prototype.html` in the frozen repo depicts **no settings
screen at all** — searching it for the heading returns nothing. There is therefore nothing to
consult and nothing stale; the only reference for this screen is the shipped route at `582f662`.
