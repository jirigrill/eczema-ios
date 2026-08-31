# Product decisions

The handful of decisions that shape the whole product, each readable here without opening a link.

## What this file is for

The spec's rules say **what the app does**. This file says **why the product is shaped this way** —
for the small number of decisions that a reader would otherwise mistake for an oversight, an
accident, or something safe to revise.

It exists because the arguments behind these decisions were had on an issue tracker in a **different
repository** — the frozen PWA repo's [Wayfinder map](https://github.com/jirigrill/eczema-helper/issues/672).
Those issues are permanent and are cited here as provenance, but **this repo does not depend on them
to be understood.** Every entry below states its own decision, its own cost, and its own
irreversibility in full. If a link here is the only way to learn what was decided, the entry is
written wrong.

## What belongs here

An entry earns its place by passing all three:

1. **Hard to reverse** — permanently, or only at a cost the reader should know before touching it.
2. **Surprising without context** — a competent implementer would otherwise read it as a bug, a
   missing feature, or an invitation to improve.
3. **The result of a real trade-off** — something was knowingly given up.

Anything failing all three is just a spec rule; it lives in its section and nowhere else. This file
is **not** a changelog, not a decision *log* of everything settled, and not a second home for rules.

## How to read an entry

Each entry is one paragraph of substance: **the call**, **what it cost**, and **what it would take to
undo**. Then two pointers — the spec rules that implement it, and the issue that argued it. The rules
are authoritative on behavior; if this file and a rule ever disagree, **the rule wins** and this file
is stale.

---

## 1. Sync is mandatory, and there is no way to turn it off

CloudKit sync is always on. There is no toggle, no opt-out, and no way to withdraw from sync while
continuing to keep a diary. The app's own definition is a *synced* diary, not a local one with a cloud
feature attached.

**What it cost.** Under the GDPR, one consent now covers both keeping a local record and copying an
infant's skin photographs to a cloud provider, where two separate consents would have been the more
cautious design. More seriously, the right to withdraw consent is satisfied only *mechanically*: the
in-app delete-all-my-data control is one tap, free, and always available, but exercising it destroys
her entire diary, because nothing is exported and nothing is backed up (see §3). Whether that counts
as withdrawal "without detriment" is genuinely unresolved — no regulatory source addresses the case
where the withdrawn processing *is* the product. That exposure was priced in and accepted, not
overlooked. Accepted alongside it: the cloud provider is a recipient of special-category data for
100% of users, with no local-only population left to argue otherwise.

**What was gained.** The ePrivacy consent story is stronger, not weaker: because the service *is* a
synced diary, sync sits inside what the user asked for. An optional sync toggle would have proved the
app works without sync, making sync separate functionality needing its own separate consent. The
engineering case pointed the same way — the platform does not document local-only ↔ cloud-backed as a
supported transition, two store configurations would have forced a schema partition this app's
related records cannot tolerate, and there is no documented way to upload a back-catalogue for
someone who logs for months and only then enables sync.

**To undo.** Adding a toggle later is not a settings change. It requires a supported store transition
the platform does not document, and the back-catalogue upload problem above. Treat it as a new
product, not a feature.

- **Rules:** `SET-SYNC-1` (no positive sync indicator anywhere), `SET-SYNC-2`…`-12` in
  [`settings.md`](settings.md) §4.1; `SET-ABSENT-1` (no toggle, no way to turn sync off);
  `SET-DELETE-1`…`-21` §3 (the delete-all-my-data control, including its degraded behavior);
  `CONSENT-GATE-1`…`-7` in [`consent.md`](consent.md); `INV-1` is **void for iOS** — see the
  disposition table in [`persistence-model.md`](persistence-model.md).
- **Argued in:** [#705](https://github.com/jirigrill/eczema-helper/issues/705).

## 2. Every field that can be encrypted is encrypted, and that choice is permanent

Every attribute the platform is capable of encrypting is declared encrypted — with no field-by-field
judgement and no exemption for values that look banal. That includes the timestamps and the calendar
dates. Photograph bytes are additionally encrypted **by the app itself** before they are stored, so
the app holds its own key.

**Why a blanket rule rather than a considered list.** A per-field list has to be re-derived every time
the schema moves, and it had already gone stale in three rows while the decision sat blocked. A
blanket rule cannot go stale. It also costs nothing measurable: every query this app issues is local,
and the encryption declaration does not affect the local store, so local predicates, sorting,
indexing and relationship traversal are untouched. The usual argument against encrypting fields is
about server-side queries, which this app never issues — and cannot: `CKQuery` is unusable against the
mirrored schema (#747), and a corpus-wide sweep of ~658 rules found none that assumed otherwise (#761).
And the "banal" fields are not banal here —
record *type names* are permanently plaintext and they say what this store is, so a plaintext meal
type on a record type named for an eczema diary is a correlation rather than a neutral value.

**Why the app encrypts photographs separately.** Platform field encryption and automatic promotion of
large values to attachments **do not compose**: past a boundary measured between 699 500 and 699 600
bytes the field is silently renamed and
the encryption request is dropped, with no error and no warning. This was measured on a physical
device against a real container, not inferred. For photographs the failure runs in the worst possible
direction — a detailed photograph of an affected area is *more* likely to cross the threshold than a
plain one, so the images most worth protecting were exactly the ones losing protection. App-side
encryption is the only remedy that holds regardless of image size. The two alternatives were
rejected: keeping bytes under the threshold would make confidentiality depend on compression
constants deliberately deferred to on-device measurement, and keeping bytes out of synced attributes
would mean photographs that do not survive a reinstall, which §1 forbids.

**What it cost.** The app now holds an encryption key, and the only defensible home for it is the
keychain — so **losing the keychain is a total loss of every photograph.** That is a real silent-loss
path, accepted knowingly, and it sits beside the platform's own hazard: an iCloud Keychain reset
permanently destroys encrypted synced data, and the documented remedy is re-uploading from the local
cache, which is the *only* remedy for an app with no export. §9 below narrows this without removing it —
the key syncs, so a new phone recovers it, and what is left is the case where iCloud Keychain is switched
off. Encryption also protects values and
never structure: relationships are stored as plaintext foreign keys and cannot be encrypted, so
*which observation belongs to which meal* stays visible to the server, and the server's own record
timestamps mean **logging timing is permanently observable** whatever this app declares.

**To undo.** You cannot. A field's encryption state is fixed when the schema is promoted to
production and can never change in either direction — an unencrypted field can never become
encrypted, and an encrypted field can never become unencrypted. There is also no deliberate promotion
step to act just before: the development schema is created as a side effect of the **first write**.
Note that the platform vendor documents this immutability rule only in an SDK header
(`NSAttributeDescription.h`, iOS 27.0 SDK) with **no web URL**, and never ties it to the framework
this app actually uses; the rule binds by construction plus measurement, not by documentation.

- **Rules:** `DATA-ENC-1`…`-6` and `DATA-LOCK-1`…`-5` in [`persistence-model.md`](persistence-model.md)
  §10.2–§10.3, which also carry the deadline table.
- **Argued in:** [#714](https://github.com/jirigrill/eczema-helper/issues/714), measured in
  [#748](https://github.com/jirigrill/eczema-helper/issues/748); the earlier field-by-field attempt is
  [#693](https://github.com/jirigrill/eczema-helper/issues/693).

## 3. Nothing is exported, and sync is the only durability

There is no export, no import, no PDF, and no share-my-record control in v1. Durability rests entirely
on CloudKit sync. The mother cannot get her data out of the app in any form.

**What it cost.** Every silent-loss path in this product traces back here. Withdrawal of consent is
destructive because there is nothing to withdraw *to* (§1). The keychain hazards in §2 are total
losses rather than recoverable ones, because the phone is the only recovery source. If the iCloud
storage allowance fills, the developer has no lever. The exposure was stated explicitly and accepted
by the owner **against the recommendation** — this is the one entry here that the person writing the
spec argued the other way.

**A known conflict, deliberately left standing.** Apple's own guidance says apps integrating with
CloudKit *"need to provide users with a way to view and export their data."* This decision does not
comply, and the conflict was found *after* the decision was made rather than before. It is recorded in
the spec at the rule itself rather than quietly resolved, because it is a submission risk somebody
should weigh with current information rather than inherit as settled.

**Related, and separate:** a clinician-facing PDF report — and data sharing generally — is not merely
unbuilt but deliberately out of scope, partly because a document arranging meals against flare-ups
edges toward regulated medical-device territory (see §5).

**To undo.** Adding export later is straightforward and breaks nothing. This is the least irreversible
entry in the file; it is here because the *absence* is easy to mistake for an oversight, and because
so much else in the spec is shaped by it.

- **Rules:** `SET-ABSENT-2` in [`settings.md`](settings.md), with the Apple-guidance conflict recorded
  in that section's open questions; `INV-2` is **void for iOS** as to durability — sync carries it —
  while the no-rollback half still holds.
- **Argued in:** [#683](https://github.com/jirigrill/eczema-helper/issues/683).

## 4. Refusing consent is a terminal state, in an app she has already paid for

The app is gated on consent before anything is recorded. Declining writes **nothing at all** — no
consent record, no feeding stage, not even a marker that she declined — and lands on a refusal screen
that is the end of the road. There is no reduced, local-only, or read-only mode to fall back to.

**Why there is no fallback mode.** It follows directly from §1 and §2. Because sync is mandatory and
the app's lawful basis for handling an infant's health data *is* her explicit consent, an app running
without that consent has no basis to record anything. A local-only degraded mode would be exactly the
"the app works fine without sync" proof that §1 was designed not to give.

**What it cost.** She has already paid — v1 is a paid app with no free tier — so the refusal path
invites refund requests, and that is the honest price of the structure rather than a defect in it.
Note also what a *later* withdrawal costs: it is not a return to this screen but a destruction of her
diary (§3).

**To undo.** The gate itself is soft — nothing is persisted, so removing or relaxing it changes no
stored data. But it cannot be relaxed while §1 and §2 stand, because the consent is what makes the
recording lawful at all. Reopen this only together with §1.

**What is deliberately still open.** The *copy* on both the consent screen and the refusal screen is
the owner's to draft, with several questions tabled for a lawyer's review. That is prose and legal
opinion, not behavior — which is why the consent section is the one part of the spec with no open
behavioral rules.

- **Rules:** `CONSENT-NO-1`…`-8` (the refusal path) and `CONSENT-GATE-1`…`-7` in
  [`consent.md`](consent.md); `RUN-GATE-*` and `RUN-CONSENT-*` in [`first-run.md`](first-run.md).
- **Argued in:** [#737](https://github.com/jirigrill/eczema-helper/issues/737), with the structural
  reasoning in [#705](https://github.com/jirigrill/eczema-helper/issues/705) §6.2.

## 5. The app records; it never finds. Nothing is derived, anywhere

No stored record holds a suspected cause, a trigger, a correlation, or a score. Nothing derived from
her records is displayed on any screen — no day-overall severity, no pattern, no suggestion, no
"foods to watch". The elimination-protocol engine that the PWA once had is parked and is not part of
this product.

**This is the boundary the whole product rests on.** An app that *finds* which foods cause flare-ups
is software intended to support a diagnostic decision, which puts it in regulated medical-device
territory with a conformity burden a single individual cannot carry. An app that *records* what was
eaten and how the skin looked is not. The distinction is not in the code — it is in what the app
claims to do, which means **marketing copy is a regulatory tripwire**: "discover which foods trigger
flare-ups" re-qualifies this app as a medical device with no code change whatsoever. Describe
recording, never finding, everywhere the product speaks about itself.

**What it cost.** The obviously useful feature — telling her what her own data suggests — is
unavailable, permanently, and it is the feature a well-meaning contributor will reach for first. Users
will ask for it.

**Why the absences are numbered rules.** Each is a field or a screen element a competent implementer
would add without thinking, so the spec numbers the prohibitions rather than leaving them as
omissions. A stored suspected-cause field is not a small convenience; it is the line between two
regulatory categories.

**To undo.** Not a code decision. It requires accepting a medical-device conformity route, and the
owner's position is that the engine would be rewritten from scratch if ever revived rather than
ported.

- **Rules:** `DATA-ABSENT-1`…`-5` in [`persistence-model.md`](persistence-model.md) §10.1;
  `DAY-DERIVE-1` in [`day-view.md`](day-view.md); `SET-ABSENT-4` in [`settings.md`](settings.md);
  `CAT-ABSENT-1`…`-2` in [`catalog.md`](catalog.md) (no ladder, dose schedule or protocol on any
  allergen or food);
  [`CONTEXT.md#inv-5`](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-5)
  (*causation is derived, not recorded*) **holds unchanged**, as an absence.
- **Argued in:** carried from the PWA's descaling to a logging-only tool
  ([#613](https://github.com/jirigrill/eczema-helper/issues/613)); day-level severity retired by
  [#717](https://github.com/jirigrill/eczema-helper/issues/717).

## 6. Newly captured photographs are still offered to the camera roll

After a skin observation is saved, the photographs just taken are offered to the system share sheet.
This is the app's **largest deliberate privacy concession**, and it survived the port on purpose.

**Why it is surprising.** On the web this was a *durability* workaround: browser storage is opaque and
fragile, so pushing a copy somewhere the user controls was the only backup available. On iOS that
rationale is gone — the store is durable and it syncs (§1) — so the feature was retained for a
different reason than the one that created it, and the owner retained it **against the
recommendation**. An implementer reading only the PWA would assume it came across by inertia. It did
not; it was re-decided.

**What it cost.** Photographs of an infant's skin leave the app's encrypted store (§2) and land in a
general-purpose photo library that syncs, shares and backs up on its own terms, outside anything this
app's rules can govern. Every confidentiality guarantee in §2 stops at that boundary.

**To undo.** Trivial in code; it removes a capability the owner asked for twice. Raise it with the
owner, not in a refactor.

- **Rules:** `SKIN-PHOTO-18` (MUST) in [`skin-observation.md`](skin-observation.md).
- **Argued in:** raised and resolved on the map — see the Decisions-so-far entry on camera-roll
  sharing in [#672](https://github.com/jirigrill/eczema-helper/issues/672).

## 7. There is no hazard axis, so an infant feeding hazard cannot be shown

v1 has **no hazard field** on any record type — not on a food, not on an allergen, not anywhere. A
food's record shape carries its identity, its family and its `allergenIds`, and nothing that marks it
as unsafe at an age. "No honey under 12 months" is therefore not something the app declines to
display; it is something the app **has no way to represent**.

**Why it is worth recording rather than leaving as an absence.** The allergen half of this question is
already closed as a rule — `CAT-DERIVE-1`…`-5` forbid displaying a food's allergen ids, an allergen's
name, or anything derived from either. The hazard half was closed by *nothing*, and the two look
identical from inside the code: both are simply not shown. An implementer who notices that `honey` has
no age warning has no way to tell whether that is a decision, an oversight, or a field someone forgot
to populate. Worse, the natural repair is wrong twice over: adding a hazard field and rendering it
would breach §5's recording-not-advising boundary, and `honey` reaching a screen today would surface
as an **allergen**, not a hazard, because the allergen axis is the only one that exists.

**What it cost.** Real infant hazards — honey, whole nuts, cow's milk as a main drink under one year —
are genuinely useful information that this app will not carry, in a product used by a parent feeding a
newborn. The mitigation is that the app never claims to be a feeding guide: first-run copy calls it a
**diary**, and §5 is what keeps that honest.

**To undo.** Adding the field is easy; displaying it is the hard part, and it is not a schema decision.
The first surface that renders a hazard makes this a §5 question — it is the app telling her something
about a food rather than recording what she fed — and it would need the copy, the review and the caveat
in the same release. Note the asymmetry with allergens: `CAT-DERIVE-*` prohibits display and names the
ids to cite when reversing it; here there is no rule to reverse, so this entry is the citation.

- **Rules:** none — this is an absence, which is why it is recorded here. The nearest rules are
  `CAT-DERIVE-1`…`-5` in [`catalog.md`](catalog.md), which close the **allergen** half of the same
  question, and §5's boundary above.
- **Argued in:** carried as fog on the map ([#672](https://github.com/jirigrill/eczema-helper/issues/672),
  *"the hazard half, untouched by #734: v1 still has no hazard axis"*), recorded here so the absence
  reads as a choice.

## 8. The PWA's existing records are abandoned, and that loss is total

This app starts from an empty store. The records already in the Czech PWA — dated meals, dated skin
observations and photographs of a breastfed newborn's affected skin, accumulated in real household use
— do not come across in any form. There is no migration, no one-shot import, and no re-entry
procedure. The first launch of this app on the mother's phone is a first launch in the full sense.

**Why this entry exists at all.** The decision was made, early and deliberately: *start fresh, no
migration from the PWA*. But it was made as a **scoping** call, weighed as "which features does v1
carry", at a time when the iOS app was a plan rather than the successor to a phone holding a real
diary. What was scoped away turns out, on inspection, to be the only copy of the data. Read from
inside the code, the absence of an import path is indistinguishable from a feature nobody got to. This
entry is the difference.

**Why the loss is total rather than deferred.** The PWA is IndexedDB in Safari on one phone, with no
backend, no export and no backup — that is `ADR-0001` and `ADR-0029` in the frozen repo, both decided
the other way here. So those records are readable **only** in that browser profile, on that phone, for
as long as it survives. Clearing Safari's storage destroys them; so does a new phone. Nothing else
holds a copy. The photographs are the part with no substitute anywhere.

**Why the alternatives are closed rather than merely unbuilt.** Each was checked, and each fails on a
rule already written rather than on effort:

- **Hand re-entry does not exist as an option.** `DAY-NAV-9a` files a newly written record under the
  device's local calendar date **at the moment of writing**, and `DAY-NAV-9b` forbids any later
  rewrite of a stored date, on read or on edit. The app has no back-date affordance anywhere. So
  retyping last month's meals produces records dated *today* — which is not a partial recovery of the
  history but a corruption of it, and worse than nothing in an app whose only value is that dates line
  up. Re-entry would first require a back-dating capability, which is new behavior and a §5 hazard
  (a diary that lets you write yesterday is a diary you can tidy).
- **A one-shot import is the only route that preserves photographs, and it is out of reach here.**
  `SET-ABSENT-2` forbids import outright, and *start fresh* sits in the handoff's do-not-reopen set.
  Whether a developer-run migration run once is even the "import control" that rule prohibits is
  arguable — but it is the owner's call to make, not a reading to be discovered in a spec session.

**What it cost, stated plainly so it cannot later read as an oversight.** The lost record is not
reconstructible from memory and not re-derivable from anything: the whole premise of the app is that
the signal only appears across weeks of logging (`CONTEXT.md#inv-5`). This app therefore begins with
an empty store on the child whose history is the reason it was built, and every week of prior logging
is spent. Whether that matters depends on something outside this spec — whether the elimination phase
is still running — and the decision was taken without that being settled either way.

**This entry had an expiry, and it has passed.** Unlike everything else in this file, the choice could
be foreclosed by an unrelated event: once the PWA phone was wiped, updated or replaced, *abandoned*
became the outcome whether or not anyone chose it. That is why the question was raised urgently rather
than eventually. Recording it here converts a decision-by-erosion into a decision on the record.

**To undo.** Only while the PWA's browser profile is intact — and that window is not under this
project's control. If the records still exist and the owner wants them, the extraction is a throwaway
script run once, and it must happen **before** anything else: the file can then sit unread for as long
as the build takes. Once the profile is gone, this entry is not reversible at any price.

- **Rules:** none — this is an absence, like §7. The nearest rules are `SET-ABSENT-2` in
  [`settings.md`](settings.md) (no import, which is the route this would need) and `DAY-NAV-9a`/`-9b`
  in [`day-view.md`](day-view.md) (dates fixed at log time, which is what closes hand re-entry).
- **Argued in:** settled in the handoff's do-not-reopen set (*"Existing data: start fresh, no migration
  from the PWA"*), reachable via the map ([#672](https://github.com/jirigrill/eczema-helper/issues/672));
  the downstream durability decision is §3 above ([#683](https://github.com/jirigrill/eczema-helper/issues/683));
  examined and recorded here by
  [#757](https://github.com/jirigrill/eczema-helper/issues/757).

---

## 9. The photograph key rides in iCloud Keychain, so a switched-off setting can still lose every photo

The app encrypts photograph bytes with its own key (§2), and that key is a keychain item marked
**synchronizable** — it travels to a new phone through iCloud Keychain — accessible **after first
unlock**, so a photograph arriving in the background can be decrypted. If the mother has iCloud Keychain
switched off, the key stays on the old phone and every photograph on the new one is permanently
unopenable.

**Why it syncs, given that syncing puts a key in iCloud.** The alternative is worse, and not marginally.
A keychain item that does not sync **cannot** reach a new device through iCloud Backup at all: Apple backs
up the keychain "encrypted with a key derived from the Secure Enclave UID root cryptographic key of the
device… This allows the database to be restored only to the same device from which it originated." So
without syncing, a new phone is not a risk of loss — it is a guaranteed loss, silent, with the store
arriving complete and every photograph in it unopenable. Note this contradicts a plausible reading of the
SDK header, which says these items "will migrate to a new device when using encrypted backups": true of a
local encrypted backup, false of iCloud. And the confidentiality objection is weaker than it appears,
because the dependency **already exists** — every other field in the store is encrypted by CloudKit using
"key material that is stored in the iCloud Keychain belonging to the iCloud account signed in on the
device". Putting the photo key there adds no new party; it puts it where the rest of the store's
confidentiality already rests, while photographs keep the advantage §2 bought them, since reading them
needs the key material *and* the stored ciphertext.

**Why not keep the key out of the keychain entirely.** It could have been stored as an encrypted CloudKit
field — 32 bytes never approach the size threshold that silently voids encryption, so it would inherit the
store's own durability and recovery, keychain excluded. Rejected on purpose: it drops photographs to the
*same* protection as every other field, which is precisely what §2's app-side encryption exists to exceed.
A key kept in the same mechanism as the data it protects is a step for an attacker with server access, not
a barrier.

**What it cost.** A fifth silent-loss path, narrower than the default it replaces but outside the app's
control: the app can neither require iCloud Keychain nor detect that it is off, so nothing warns her, and
the loss surfaces only on the new phone. Two related unknowns are recorded rather than guessed — whether
an encrypted write behaves differently with the setting off (unsourced for third-party containers), and
whether deleting and reinstalling the app clears its keychain items (**undocumented by Apple in both
directions**, and if it does clear them, a routine reinstall becomes a total loss on the same phone). Both
are device-measurable and neither changes a rule. Separately, a photograph that cannot be decrypted must
never be shown as one that has merely not arrived yet — the two are indistinguishable in the data, and
telling her to wait for a photograph that is gone is the failure the rules forbid.

**To undo.** The attributes are rewritable in any release; the **key's value is not**. Changing keys means
decrypting what the old key protected, which is the exact operation that fails once a key is lost — so this
is settled by the **first photo write**, not by schema promotion, and no later release can revisit it for
photographs already stored. Turning syncing off later would strand every photograph written before the
change on the phone that wrote them.

- **Rules:** `DATA-KEY-1`…`-9` in [`persistence-model.md`](persistence-model.md) §11.2, with the open
  questions at §14 (13.7, 13.8); the parent decision is §2 above (`DATA-ENC-5`). The copy shown for an
  unopenable photograph is fenced by `DATA-KEY-7` and not yet drafted.
- **Argued in:** [#763](https://github.com/jirigrill/eczema-helper/issues/763), against the file-protection
  precedent settled in [#752](https://github.com/jirigrill/eczema-helper/issues/752); the app-encryption
  decision it follows from is [#714](https://github.com/jirigrill/eczema-helper/issues/714).

---

## 10. The app says nothing while sync is working, so silence is the healthy state

There is no affirmative sync indicator anywhere in this product — no "synced", no "up to date", no
"last synced at", no cloud glyph in a healthy condition, no progress spinner. The app is **silent
while sync is healthy and speaks only when something is wrong**, and when it does speak it says what
the failure costs her rather than naming a technical state.

**Why it is not a missing feature.** The reflex reading of a sync-less status bar is that someone
forgot the status bar. The truth is that the honest version cannot be built: **no API can report that
the store is synchronised.** A "synced" badge would be a claim the platform gives no way to verify, so
it would be decoration that reads as a guarantee — and the moment it is wrong is the moment she is
looking at an incomplete diary and being told it is complete. The framework only ever reports *events*,
and a verdict is taken only from an ended one; watermark inference was examined and rejected.

**What it cost.** She gets no reassurance. A mother who wants to know her infant's record is safely in
iCloud has no screen that tells her so, and reassurance is a reasonable thing to want in this product
of all products. Accepted knowingly: an unverifiable reassurance is worth less than none, because it
would be believed.

**What speaks instead, and only then.** Failures are surfaced only when **persistent** — no successful
upload for 24 hours while unexported changes are pending, a wall-clock gate rather than a count of
failures, chosen against a daily-use app. Two messages keyed to the consequence: her records are on
this phone only, or this phone may not be showing everything. A failed upload never means a lost
record, so the copy says *not yet copied to iCloud* and never *not saved*. The quota message names full
iCloud storage as a **likely** cause without asserting it, because quota exhaustion is genuinely not
detectable through the mirroring API — its error is the same code the platform documents for fatal
setup failure — and Apple's only published recovery instruction is to send her to iCloud settings.

**To undo.** Adding a positive indicator is easy in code and wrong for the reason above; the constraint
is the absent API, not the design. Anyone reversing this needs a way to know the store is synchronised
first. Removing the 24-hour gate is the cheaper knob, and it re-introduces alarms on transient
failures that train her to ignore the one that matters.

- **Rules:** `SET-SYNC-1`…`-12` in [`settings.md`](settings.md) §4.1 (`-2`, `-8`, `-9` are
  platform-forced, not choices); `RUN-ICLOUD-3` in [`first-run.md`](first-run.md) forbids the parallel
  connectivity warning at first run; [`day-view.md`](day-view.md)'s question of where a health
  indicator would live is closed **nowhere**.
- **Argued in:** [#723](https://github.com/jirigrill/eczema-helper/issues/723), the observability it
  rests on in [#704](https://github.com/jirigrill/eczema-helper/issues/704) and the banner form in
  [#687](https://github.com/jirigrill/eczema-helper/issues/687); owner-confirmed in
  [#767](https://github.com/jirigrill/eczema-helper/issues/767).

## 11. Sync failures are captured to a log with no way to read it

Every sync-event failure is written to a local diagnostic log at the moment it is observed — the
error's full detail, the event type, the time — pruned to a bounded number of recent entries. In v1
that log has **no user-facing surface at all**: it is not displayed, not exported, not shared, and
nothing in the app acknowledges it exists.

**Why a log nobody can read ships anyway.** Error detail exists **only live on the notification**. An
event re-read afterwards retains only the domain and code of the original error, so an app that does
not capture at notification time has lost the detail **permanently** — this is stated by an Apple
Frameworks Engineer on the developer forums and in a technote, and it is the reason this is the one
irreversible decision in the sync area. It is also the only route by which the open question of *which
error codes actually arrive in practice* can ever close from real use, rather than from another spike
that cannot provoke a genuine failure.

**Why no surface, when the capture is the expensive half.** A share-to-support flow would mail an
infant's medical record to the developer's inbox and require a new Art. 13 disclosure. Reading and
sharing are additive and cheap to add later; the capture is not. So the asymmetric bet is to capture
now and decide about surfaces once there is something to look at.

**What it cost.** Storage and code for a feature with no user value in v1, and a diagnostic channel the
owner cannot actually consult without attaching a debugger. Accepted as the price of not throwing away
the only evidence the failure ever produces.

**To undo.** The surface is addable in any release. The capture is not retroactive: any failure that
happened before capture shipped is gone, so removing or deferring it silently forecloses the diagnosis
it exists to enable.

- **Rules:** `SET-SYNC-10` (capture at notification time) and `SET-SYNC-11` (no user-facing surface) in
  [`settings.md`](settings.md) §4.1; `SET-SYNC-12`'s upload timestamp is a **correctness** requirement
  rather than a display one, because the platform gates persistent-history purging on it.
- **Argued in:** [#723](https://github.com/jirigrill/eczema-helper/issues/723), with the
  disclosure constraint from [#709](https://github.com/jirigrill/eczema-helper/issues/709);
  owner-confirmed in [#767](https://github.com/jirigrill/eczema-helper/issues/767).

---

## What is deliberately not in this file

**No ADR series, and no decisions log.** Both were considered and declined. The spec sections already
carry each decision's trade-off, rejected alternatives, accepted costs and irreversibility at the rule
itself — an ADR would restate them in a second place and go stale there. A numbered series would also
collide with the frozen PWA repo's own `docs/adr/`, where a second `0001` is a citation hazard.

**The frozen repo's ADRs are not this repo's.** `ADR-0001` (single device, no sync) and `ADR-0029` (no
cryptography, no backup) remain true of the PWA and were both decided **the other way here** — read
them for the trade-offs they record, never as guidance. `ADR-0028` (food-level preparations) is a
domain rule the platform change does not touch and it ports intact; it is cited from
[`catalog.md`](catalog.md).

**Everything still undecided lives on the map**, not here:
[Map: PWA → native iOS](https://github.com/jirigrill/eczema-helper/issues/672). This file records what
is settled and shaping; open questions are the map's job, or an `OPEN` rule in a spec section.
