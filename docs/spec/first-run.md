# First run and the feeding stage — behavior specification

**Status:** written, **awaiting owner confirmation** on two points marked in place (§3.1 `RUN-COPY-2`,
§5 `RUN-ICLOUD-2`). Written against the format settled by
[#682](https://github.com/jirigrill/eczema-helper/issues/682) — see [`TEMPLATE.md`](TEMPLATE.md) for
the rules, and [`skin-observation.md`](skin-observation.md) for the worked example.
**Behavior reference:** `jirigrill/eczema-helper` @ `582f662` (frozen PWA), `src/routes/+page.svelte`,
`src/routes/+layout.svelte:109-113`, `src/lib/stores/settings-context.ts`,
`src/lib/stores/settings.svelte.ts`, `src/lib/config/feeding-stages.ts`.
**Resolves:** [#729](https://github.com/jirigrill/eczema-helper/issues/729) on the transition map
[#672](https://github.com/jirigrill/eczema-helper/issues/672).

## Overview

Before the mother can record anything, the app needs one value: **who eats**. A newborn's intake is
her own diet, an infant on solids eats for himself, and in between it is both — so this one answer
decides whose meals the app will let her log. It is the only question the app ever asks her, and it
takes one tap.

That is the whole of first run. There is no questionnaire, no birth date, no severity assessment and
no plan: those belonged to the elimination-protocol product and are parked
([INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11)). What remains is a
single screen with three choices.

The screen is harder than it looks, for one reason. **It is not shown "the first time the app runs" —
it is shown whenever no feeding stage is known.** Those were the same thing on a single device with
local-only storage. Under sync they are not: a mother who reinstalls, or who installs on a second
phone, reaches this screen with months of records that have not arrived yet.
[#712](https://github.com/jirigrill/eczema-helper/issues/712) established that no signal on iOS can
tell those cases apart — a correct first-run gate needs a server or an account, and this app has
neither by design — so the gate is not made *correct*, it is made **harmless**.

This document states what the screen does, in English, without reference to Swift, SwiftUI,
SwiftData, Svelte, Dexie, or the Czech interface. Swift tests are derived from the numbered rules;
the owner's acceptance pass is derived from §9.

Three things are worth knowing before the rules make sense:

1. **The trigger is the absence of a stage, not the newness of the install.** Nothing else is
   consulted — not the store's emptiness, not a device-local marker, not the keychain. #712 ruled out
   all four candidates against primary sources.
2. **Her answer is provisional for one launch session.** A stage arriving from her own iCloud during
   that session silently replaces it, because the pre-reinstall answer is the true one. After the
   session, ordinary last-writer-wins (`settings.md` `SET-STAGE-8`).
3. **The stage governs what may be *created*, never what is *shown*.** This is the rule the day view
   depends on, and violating it is precisely how #712's apparent-total-data-loss path worked. It is
   stated here as `RUN-MEANS-1` because this section owns it.

**How to read this document:** see
[`skin-observation.md` § How to read this document](skin-observation.md#how-to-read-this-document).
Rule ids here are `RUN-<group>-<n>`, permanent identity, never renumbered or reused.

### Invariant dispositions

Invariants are cited, never restated. [#691](https://github.com/jirigrill/eczema-helper/issues/691)
classified all fourteen; the ones this section touches carry their disposition here so a bare
citation cannot import a contradiction.

| Ref | Leading phrase | Disposition here |
| --- | --- | --- |
| [INV-1](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-1) | _Single device, no sync_ | **Void for iOS.** Sync is mandatory and always on ([#705](https://github.com/jirigrill/eczema-helper/issues/705)). It is the whole reason this section is hard: the gate's trigger and "this install is new" stopped being the same proposition. |
| [INV-2](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-2) | _No backup mechanism exists_ | **Void for iOS** as to durability ([#683](https://github.com/jirigrill/eczema-helper/issues/683)). Load-bearing here in its surviving half: with no export, a screen that appears to have lost her records is not recoverable by any user action, which is what makes `RUN-MEANS-1` matter. |
| [INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11) | _The app is a Logging Tool_ | **Holds**, and bounds this screen: it asks one operational question and makes no assessment, offers no plan, and states no expectation. §3.2. |
| [INV-12](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-12) | _Records carry types, not display strings_ | **Holds.** The stage persists as one of three stable identifiers; the labels are resolved at render (`RUN-PICK-6`). |
| [INV-14](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-14) | _Every meal has an eligible actor_ | **Holds, and is read precisely.** It binds **at log time**, which is what makes a provisional answer survivable: a stage that changes an hour later does not retro-invalidate anything (`RUN-MEANS-3`). |

`CONTEXT.md` also holds invariant-shaped rules **unnumbered**, in glossary prose. One bears on this
screen and is cited by heading: _Actor_ (the stage → actors mapping), under § _Glossary_.

### Divergences from the PWA

This is not a 1:1 port. Per [#690](https://github.com/jirigrill/eczema-helper/issues/690),
**coherence is presumed right**: where the reference implementation does two different things, the
port takes the coherent rule, and *keeping* a wart needs a named reason. There are **five**, marked
inline and indexed in §8. Two of them fix defects that are live in the shipped PWA today, and one of
those two — the preselected stage — is the specific mistake that made #712's data-loss path reachable.

---

## 1. Vocabulary

| Term | Meaning |
| --- | --- |
| **First run** | The state in which no feeding stage is known, and the screen shown in it. Not a synonym for "a new install" — that is the distinction this section exists to hold. |
| **Onboarding launch session** | The single foreground session in which first run was shown. Its end is defined by `RUN-SYNC-4`; it is the window in which an arriving stage overrides her answer. |
| **Provisional answer** | The stage she picks during first run, before the window closes. It governs immediately and may be silently replaced within that window. |
| **Arriving stage** | A feeding stage value reaching this device from her own iCloud, written on another device or before a reinstall. |
| **Stage-less** | Having no known feeding stage. A state the app must tolerate arriving in, never a state it can prove is new. |

Two terms this section uses are shared with the day view and settings and are defined in
[`GLOSSARY.md`](GLOSSARY.md): **feeding stage** and **eligible actors**.

---

## 2. When first run is shown

**`RUN-GATE-1` (MUST)** — First run is shown when, and only when, no feeding stage is known. Nothing
else is consulted.

**`RUN-GATE-2` (MUST)** — The decision is made instantly and locally, with no wait for sync, no fixed
delay, no launch-screen hold and no placeholder gate.

**`RUN-GATE-3` (MUST NOT)** — The app does not read the emptiness of the record store to decide
whether to show first run, and does not write a device-local marker recording that onboarding has run.

**`RUN-GATE-4` (MUST NOT)** — First run is never shown and then retracted. It is shown or it is not;
there is no flash.

**`RUN-GATE-5` (MUST)** — Being stage-less is tolerated in any launch, at any age of the install. The
question stays reachable whenever the stage is absent.

These five are #712's resolution, and they are a set: each closes an escape route the others would
otherwise open. `RUN-GATE-3`'s two prohibitions are the ones a future contributor will reach for, so
the reasoning belongs here rather than only on the ticket. Branching on an empty store is Apple's
documented **fallacy** and there is no "initial import complete" API to replace it. A device-local
marker looks like the obvious fix and is worse than nothing: it dies with the app container on
deletion — the case that matters — while *surviving* a backup restore, so on a replacement phone it
claims onboarding has run when it never has, and that state is neither askable nor repairable.
Waiting is ruled out on Apple's own technotes: TN3164 says imports may be *"intentionally deferred"*
out of a launch session, TN3163 that a throttle *"can expire in a second or last for hours"* with
*"no API … to configure the expiration time"*. Waiting therefore has no terminating condition.

> **⚠ Divergence 1.** *PWA:* the gate is the same proposition — an unset stage routes to first run,
> a set stage routes to the day view (`+layout.svelte:109-113`) — but it is *implemented* as a
> redirect effect holding on a three-valued `loading`/`unset`/`seeded` signal, guarding the #353 race
> in which a seeded mother hard-loading the day view is bounced to first run on the pre-emission tick.
> *iOS:* the outcome is identical and the mechanism does not port; there is no redirect and no race to
> guard. *Why:* obsolete. The guard exists because a `liveQuery` emits asynchronously after mount;
> reading a value the platform provides synchronously has no pre-emission tick.
> `settings.md` Divergence 3 retires the sibling guard on the same grounds. Class: **obsolete**.

---

## 3. The screen

### 3.1 What she sees

**`RUN-COPY-1` (MUST)** — The screen states the question and what the answer governs: whose meals she
will be able to record. It says nothing about feeding practice, diet, elimination, or the protocol.

**`RUN-COPY-2` (MUST)** — The copy is **branched on whether the record store holds any records**: a
store with no records gets new-user copy that may welcome her and introduce the app; a store already
holding records gets copy that does not, and reads correctly for a mother who has used the app before.

> **⚠ Divergence 2.** *PWA:* one text for everyone, and it assumes newness — *"Vítejte"* (Welcome) and
> *"Než začnete"* (before you begin), with no second variant. *iOS:* two variants, chosen by whether
> any records exist. *Why:* owner's call. Under sync this screen has two audiences, and welcome copy
> is false for the returning one — it lands beside an empty day view and reinforces exactly the
> apparent-data-loss reading #712 spent its resolution defusing. Class: **defect fixed**.

**Awaiting owner confirmation.** This was decided against a recommendation of one newness-neutral text
true for both audiences, and it carries a cost that must be recorded rather than discovered later:
**on the reinstall path the branch is wrong.** She reinstalls, launches, and neither her records nor
her stage have arrived — so the store is empty, the branch reads *new*, and she gets welcome copy as a
mother of four months. That is the very path #712 designed for. The branch is right on a second device
that has already synced and right for a genuinely new user; it is wrong precisely when the arrival
race is lost. There is no way to close that gap: #712's correction 4 found **KVS↔CloudKit ordering
undocumented** (zero cross-references between the KVS header and CoreData/CloudKit/SwiftData), so
mirroring progress cannot proxy for the settings value having arrived, and the two mechanisms cannot
be sequenced against each other.

Two things make this defensible rather than merely accepted. Reading emptiness *for copy* is far
weaker than reading it *for the gate*: `RUN-GATE-3` still forbids the gate, and `settings.md`
`SET-SYNC-6` already reads emptiness for a message and says in place that it "reads emptiness for
something far weaker than the first-run gate," so there is precedent in the spec. And the failure mode
is one wrong sentence, where the gate's failure mode was hidden records.

**`RUN-COPY-3` (MUST NOT)** — Neither variant states or implies what the app will find, conclude,
suggest, or help her discover. It describes recording only.

`RUN-COPY-3` is the marketing-tripwire rule at its earliest surface. The PWA's own copy is already
correct here — *"Jednoduchý deník jídel a stavu kůže"*, a simple diary of meals and skin — while the
design prototype's welcome screen, from the parked protocol product, says *"Pomůžeme ti najít, co
miminku spouští ekzém"* (we will help you find what triggers your baby's eczema). That sentence is the
MDCG 2019-11 line, and it is on the screen this section replaces. See §11.

### 3.2 What it does not contain

**`RUN-ABSENT-1` (MUST NOT)** — First run asks nothing except the feeding stage. No birth date, no
eczema severity, no allergen history, no start date, no summary step.

**`RUN-ABSENT-2` (MUST NOT)** — First run makes no assessment, offers no plan or schedule, and sets no
expectation of what recording will achieve.

**`RUN-ABSENT-3` (MUST NOT)** — First run has no progress indicator, step counter or dots. It is one
screen, not the first of several.

**`RUN-ABSENT-4` (MUST NOT)** — First run does not ask for any system permission. Notifications,
Photos and the camera are requested at first use, never here (`skin-observation.md` `SKIN-PHOTO-20`).

These are prohibitions with ids rather than features nobody built, because the parked product had all
four and its design prototype still depicts them: a six-step questionnaire with a dotted progress bar,
a severity question, allergen checklists and a generated phase schedule. An implementer reading that
prototype would build them back. §11 names it as not-to-be-consulted for this screen.

### 3.3 The picker

**`RUN-PICK-1` (MUST)** — All three stages are offered together in the fixed order `breastfed`,
`mixed`, `solids`.

**`RUN-PICK-2` (MUST NOT)** — No stage is preselected. Nothing is indicated as current, recommended,
usual or default.

**`RUN-PICK-3` (MUST)** — First run cannot be completed without an explicit choice. Until she picks a
stage, no stage is written and the day view is not reached.

> **⚠ Divergence 3.** *PWA:* `breastfed` is preselected (`+page.svelte:19`) and the confirm button is
> live from the first frame, so tapping straight through writes the narrowest actor set without her
> having chosen anything. *iOS:* nothing is preselected and the confirm control does not act until she
> picks. *Why:* defect, and the sharpest one in this section. `breastfed → [mother]` is the narrowest
> eligible set, and a mother on `solids` whose records are all `baby`-actor could tap through and see
> none of them — #712's apparent-total-data-loss path, whose reachability was exactly this
> preselection. `settings.md` `SET-STAGE-7` took the same decision for the Settings control, on the
> same reasoning. Class: **defect fixed**.

**`RUN-PICK-4` (MUST)** — A confirm control completes first run, separate from the three choices, and
is inert until a stage is picked.

This keeps picking and committing distinct. It was decided against making the chips themselves the
action (one tap, no button), which would have matched `settings.md` `SET-STAGE-3`'s no-save-step shape
and is the cheaper screen. The reason to keep the button: in Settings she is changing a value she
already understands, while here she is answering a question for the first time, and a chip that both
selects and navigates gives her no moment to read her own answer before it commits. A mis-tap in
Settings is one tap to fix on a screen she is already looking at; a mis-tap here lands her on a
different screen with a stage she did not intend.

**`RUN-PICK-5` (MUST)** — Choosing a stage is reversible up to the moment she confirms: picking a
second stage replaces the first with no penalty and no confirmation.

**`RUN-PICK-6` (MUST)** — The three labels are resolved for display from the stable identifiers; the
persisted value is the identifier
([INV-12](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-12)).

**`RUN-PICK-7` (MUST)** — If writing the stage fails, she stays on first run, is told the answer was
not saved, and can retry. She is not advanced to the day view.

The reference implementation gets `RUN-PICK-7` right and it is worth keeping deliberately: on a failed
write it sets an error and returns before navigating (`+page.svelte:24-30`). Advancing on a failed
write would land her stage-less on the day view — recoverable, since `RUN-GATE-5` keeps the question
reachable, but it would present as the app having silently ignored her.

### 3.4 Leaving it

**`RUN-PICK-8` (MUST)** — On confirmation she lands on the day view for **today**
(`day-view.md` `DAY-NAV-1`).

**`RUN-PICK-9` (MUST NOT)** — Once a feeding stage is known, first run is not reachable by any
interaction. No back gesture, no navigation, no control returns to it.

`RUN-PICK-9` keeps `settings.md` `SET-STAGE-1` true — Settings is the *only* place the stage changes
after first run. A re-enterable first run would be a second such place, and the two would then have to
agree on preselection, on whether a confirm step exists, and on what a change means. Note this is a
rule about **reachability, not about the value**: `RUN-GATE-5` still shows first run whenever the stage
is absent, including after `settings.md` `SET-DELETE-8` clears it, which is why the two are not in
conflict.

---

## 4. What the stage means to the rest of the app

**`RUN-MEANS-1` (MUST NOT)** — The feeding stage never determines what is **shown**. No record is
hidden, filtered, blanked, greyed, marked or reordered because of the stage in force.

**`RUN-MEANS-2` (MUST)** — The feeding stage determines only what may be **created**: which actors she
may log a meal for, per the unnumbered _Actor_ rule in
[`CONTEXT.md`](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md) § _Glossary_.

**`RUN-MEANS-3` (MUST NOT)** — A stage change is never retroactive. No existing record is altered,
re-labelled, hidden, flagged or deleted when the stage changes, whatever actor logged it.

This section owns these three because they are the contract the other sections cite, and until now the
creates-versus-shows half was written down nowhere. `day-view.md` `DAY-STAGE-3` and `DAY-MEAL-2`/`-3`
rest on it; `settings.md` `SET-STAGE-5` states the retroactivity half for its own screen. The reason it
is a **rule** and not a glossary line is that it is falsifiable and was in fact false in the reference:
the PWA's day view builds its meal rows from the eligible-actor set
(`day/[date]/+page.svelte:36` → `MealCard.svelte:36`), so at `breastfed` a `baby`-actor meal is not
rendered at all. That is `RUN-MEANS-1` violated, and it is how one tap on a preselected chip looked like
losing every record she had.

[INV-14](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-14) is what licenses
`RUN-MEANS-3`: eligibility binds **at log time**, so a meal logged under a stage that no longer holds
was still legitimate when it was written. `settings.md` notes that `SET-STAGE-5` has **no test anywhere**
in the reference — in a codebase where #712's data-loss path ran through exactly this relationship — so
§9 marks it for re-derivation rather than translation.

> **⚠ Divergence 4.** *PWA:* the day view renders meal rows from the currently-eligible actor set, so
> the stage silently filters what she sees. *iOS:* the stage has no effect on display at all; the day
> view renders the union of eligible and recorded actors (`day-view.md` `DAY-MEAL-2`). *Why:* defect,
> and the one #712 identified as the whole cost of re-asking. Only observable at `breastfed` and
> `solids`; at `mixed` both actors are eligible, so nothing was ever hidden there. Class: **defect fixed**.

---

## 5. First run in a degraded iCloud state

**`RUN-ICLOUD-1` (MUST)** — First run can be completed in **every** account state, including
`noAccount` and `restricted`. The picker is never disabled and the stage write is never blocked.

**`RUN-ICLOUD-2` (MUST)** — In a degraded state (`noAccount` or `restricted` only), first run **states
the consequence** before she picks: records cannot be created yet, and what she is about to answer will
not be lost.

**Awaiting owner confirmation.** `RUN-ICLOUD-1` is settled and follows `settings.md`
`SET-STAGE-9`/`-10` — the stage is not a record, does not live in the synced store, and Apple documents
the write as succeeding locally with *"the changes remain only on the current device"*, so gating it
would invent a platform restriction. `RUN-ICLOUD-2` is the part decided against a recommendation to
proceed identically and let #687's persistent banner carry the message on the day view.

It is written as **warns, does not block** because blocking has no exit. `restricted` is documented by
Apple as **nonrecoverable**, so a first run that refuses to complete in that state is an app that can
never be used at all, by anyone on a managed device — a terminal state reached before she has seen a
single screen, and one no in-app action can clear. Warning costs one sentence and keeps every path
open. If the intent was in fact to block, that is a different rule and a decision that needs recording
against the `restricted` consequence.

**`RUN-ICLOUD-3` (MUST NOT)** — First run shows nothing about the account in `temporarilyUnavailable`
or `couldNotDetermine`. Those are self-resolving and Apple instructs apps to wait.

**`RUN-ICLOUD-4` (MUST NOT)** — First run does not offer to fix the account state, simulate a sign-in,
or require her to sign in before continuing. It may link out to iOS Settings
(`settings.md` `SET-ICLOUD-5`).

**`RUN-ICLOUD-5` (MUST)** — The wording names the consequence concretely rather than the technical
account status, matching `settings.md` `SET-ICLOUD-3`.

#687's gate is a **durability** gate, not a connectivity one, which is why `RUN-ICLOUD-3` exists as a
prohibition: a warning on airplane mode or in a basement would train her to ignore the warning that
matters. Note what `RUN-ICLOUD-2` must *not* claim — that her answer will sync. It will not, until the
account recovers; what it will do is persist locally, which is the concrete promise Apple's
documentation supports.

---

## 6. The provisional answer, and the arriving stage

**`RUN-SYNC-1` (MUST)** — Her answer governs from the moment she confirms it. Nothing waits for a
synced value to arrive or to fail to arrive.

**`RUN-SYNC-2` (MUST)** — Within the onboarding launch session, a stage arriving from her iCloud
**replaces** her answer.

**`RUN-SYNC-3` (MUST NOT)** — That replacement is **silent**. No toast, no banner, no dialogue, no
mark, and no explanation appears — not on first run, not on the day view she has landed on.

**`RUN-SYNC-4` (MUST)** — The onboarding launch session ends at whichever comes first: the app leaving
the foreground, or her changing the stage in Settings.

**`RUN-SYNC-5` (MUST)** — After the window closes, the stage is ordinary last-writer-wins with no
arriving-wins rule on top (`settings.md` `SET-STAGE-8`).

`RUN-SYNC-2` delivers the substance of "the pre-reinstall stage still governs" — it does, just a moment
later. `RUN-SYNC-3` is a `MUST NOT` rather than an absence for the `SET-SYNC-1` reason: left implicit, an
implementer reads silence as an oversight and helpfully adds a toast. It is safe to be silent because
under `RUN-MEANS-1` nothing is hidden by the change — the day view's row set may shift, but every
recorded meal stays rendered (`day-view.md` `DAY-MEAL-2`/`-3`) — and a notice would explain a sync
mechanism she cannot act on.

**`RUN-SYNC-4` is the load-bearing rule of this section, and both of its limbs are needed.** Scoping the
window is what stops a stale value clobbering a stage she deliberately changed weeks later; but the
window must also be *short*, and "the process is alive" is not short. iOS keeps processes resident for a
long time, so a mother who onboards, puts the phone down for an hour and comes back would still be
inside the session, and a value arriving then would overwrite an answer she has been using all along.
Backgrounding is the observable boundary that matches what she would call "when I set the app up."

The second limb — an explicit Settings change closes the window immediately — is what makes the window
safe for its whole duration rather than only after it. Without it, a mother who onboards, notices the
stage is wrong, corrects it in Settings, and *then* receives the arriving value would be overruled by a
value older than her correction, inside the one window where arriving-wins is meant to help her. This is
just `SET-STAGE-8`'s last-writer-wins asserting itself early, and it is the reason the two rules do not
conflict.

**What must not be built here.** `.import` completion **is** recorded as a local timestamp, per Apple's
own `LastImportDate` sample pattern — but it is read **only** by the sync-health rules
(`settings.md` `SET-SYNC-12`) and never by onboarding. Whether an *empty* server zone emits a completing
`.import` is unsourced, so a genuinely new mother could wait forever on it. Nor is "signed in but nothing
has arrived yet" a state: it is `available` with an empty store, indistinguishable from a healthy launch,
with no knowable end — #687's five-valued model needs no fourth branch, and #712 checked this explicitly.

One measurement bears on `RUN-SYNC-2` and is worth carrying, because it bounds what the rule can promise.
A from-scratch initial import emits **exactly one** `.import` event, verified at 100 rows and at 4,100
rows against the same zone ([#726](https://github.com/jirigrill/eczema-helper/pull/726)) — but two Apple
staff answers establish that a successful import means only that *this* device is current with what was on
the server at *that instant*, and *"doesn't imply anything about the state of other devices."* So no count
and no event licenses a "her real stage has now arrived" conclusion. `RUN-SYNC-2` is therefore written as
*if it arrives within the window*, never as *wait until it has arrived* — the second is not expressible.

---

## 7. Consent

**`RUN-CONSENT-1` (MUST)** — The consent gate precedes the feeding-stage picker. She reaches first run
only after consent has been recorded.

**`RUN-CONSENT-2` (MUST NOT)** — No feeding stage is written before consent is recorded.

**`RUN-CONSENT-3` (MUST NOT)** — Consent is not bundled into the feeding-stage choice. Confirming a
stage is not an act of consent, and the picker carries no consent language.

That is all this section says about consent. The screen itself — its eleven Tier-1 disclosures under
Art. 9(2)(a), the single checkbox covering recording and sync
([#705](https://github.com/jirigrill/eczema-helper/issues/705)), the durable consent record naming the
notice revision (`settings.md` `SET-PRIVACY-6`), and the refusal path — belongs to
[#737](https://github.com/jirigrill/eczema-helper/issues/737) and is not restated here.

The ordering is stated here because it constrains *this* screen and because it was, until now, owned by
no section at all: #709 found that grepping every open ticket for "consent" returned zero results.
[#694](https://github.com/jirigrill/eczema-helper/issues/694) §6.1 fixed the order and its reason — the
feeding stage is itself personal data about the mother, so it cannot be collected before the basis for
collecting it exists. `RUN-CONSENT-3` follows from #694's finding that a performative act is required: an
affirmative act bundled into an onboarding Continue is not one.

**`RUN-CONSENT-4` (OPEN)** — Whether, and how, the app tells her the privacy notice has **changed** on a
later launch is not decided.

This is `settings.md` `SET-PRIVACY-14` arriving here, because the app on a later launch is the only
surface available: there is no email address, no account and no server-side reach
(`settings.md` `SET-ABSENT-5`). WP260 para 29 bars the "check back regularly" formula outright as *"not
only insufficient but also unfair"* and requires active, dedicated notification instead — but every
modality it names (email, hard-copy letter, a pop-up on a webpage) assumes a channel this app does not
have. It stays `OPEN` rather than guessed, per the template.

Two things are settled about it and are stated so the next reader does not re-derive them. It **cannot
bind the first release**, which has no previous notice to have changed from — so there is no schema
deadline and nothing blocks. And it must not be conflated with **re-consent**: EDPB 05/2020 para 110
triggers re-consent when the *processing* changes considerably, not on rewording, so a
notice-changed prompt and a consent prompt are different events, and treating them as one would ask for
consent that nothing requires.

> **⚠ Divergence 5.** *PWA:* there is no consent gate, no privacy notice and no consent record; first
> run is the first screen and writes the stage immediately. *iOS:* consent precedes the picker and no
> stage is written before it. *Why:* new behavior rather than a port — the reference was a single-device
> app with no recipient, and #705 made sync mandatory, which is what puts an Art. 9(2)(a) basis in scope.
> Class: **settled by #694**.

---

## 7a. Accessibility

First run is a three-choice picker and a confirm control. It is the smallest interactive surface in the
spec, which is why the two rules that matter here are easy to get wrong: the whole screen turns on
**nothing being preselected** (`RUN-PICK-2`) and on the confirm control being **inert until she picks**
(`RUN-PICK-4`), and neither of those states is perceptible without being announced.

**`RUN-A11Y-1` (MUST)** — Each of the three stages is one element, announced by its display label
(`RUN-PICK-6`), traited as a control that can be selected, in the fixed order `breastfed`, `mixed`,
`solids` (`RUN-PICK-1`). Focus order is that order, and it is never reordered by likelihood or
recency.

**`RUN-A11Y-2` (MUST)** — On arrival **no stage announces as selected** (`RUN-PICK-2`). This is the
non-visual half of Divergence 3, and it is the rule most likely to be broken while the screen still
looks correct: a picker implemented with a platform control that requires a selected value will
announce one even when nothing is visually highlighted, which re-creates the preselection that
divergence removes — and re-creates it only for the person who cannot see that nothing is highlighted.

**`RUN-A11Y-3` (MUST)** — Picking a stage announces the new selection, and picking a second announces
that the first is no longer selected (`RUN-PICK-5`). Reversibility she cannot perceive is not
reversibility.

**`RUN-A11Y-4` (MUST)** — The confirm control stays **in** the accessibility tree while it is inert
(`RUN-PICK-4`), announced as unavailable with the reason — that a stage has not been chosen. Removing
it until a choice is made would leave the screen with no announced way forward; this is the same rule
`skin-observation.md` `SKIN-A11Y-7` states for save, and the same defect its Divergence 5 fixed.

**`RUN-A11Y-5` (MUST)** — A failed stage write (`RUN-PICK-7`) is **announced**, not shown only as
visible error text. She stays on the screen and nothing moves, so there is no other signal that her
answer did not persist — and the failure this rule exists to prevent is her believing she answered.

**`RUN-A11Y-6` (MUST)** — The degraded-account sentence (`RUN-ICLOUD-2`) is announced **before** she
reaches the picker in focus order, matching the requirement that it be stated before she picks. A
consequence read out after the choice is not a warning.

**`RUN-A11Y-7` (MUST NOT)** — No label, hint or announcement states or implies what the app will find,
conclude or recommend (`RUN-COPY-3`), marks any stage as usual, recommended or default
(`RUN-PICK-2`), or names the technical account status rather than its consequence (`RUN-ICLOUD-5`).

### 7a.1 The five questions

| # | Answer |
| --- | --- |
| 1 | **VoiceOver label and trait** — four interactive elements: three stage choices (`RUN-A11Y-1`, `-2`, `-3`) and confirm (`-4`). The copy above them is text, and its two variants (`RUN-COPY-2`) read as written. |
| 2 | **Dynamic Type** — the three stage labels **must never truncate**: they are the entire question, and a clipped label is an unanswerable choice. The picker therefore stacks rather than clipping at large sizes. The explanatory copy may wrap to any length — `RUN-ABSENT-3` forbids paging, so the screen scrolls. |
| 3 | **Colour alone** — one case: which stage is selected. It is carried by the accessibility selected state (`RUN-A11Y-2`, `-3`) as well as visually, and `RUN-PICK-2` means the initial answer to "which is selected" is *none*. |
| 4 | **Focus order and grouping** — copy, then the degraded-account sentence if present (`RUN-A11Y-6`), then the three stages in fixed order, then confirm. One element per stage; the three are a single group, so it is discoverable that there are exactly three. |
| 5 | **Reduce Motion** — one transition: leaving for the day view on confirmation (`RUN-PICK-8`). Under Reduce Motion it completes without animation. There is no other motion — `RUN-ABSENT-3` forbids progress indicators. |

---

## 8. Divergence index

| # | Where | Divergence | Class |
| --- | --- | --- | --- |
| 1 | §2 `RUN-GATE-1`..`-5` | The redirect effect and its `loading`/`unset`/`seeded` race guard do not port; the outcome is unchanged. | Obsolete |
| 2 | §3.1 `RUN-COPY-2` | The copy branches on whether records exist; the PWA has one welcome text that is false for a returning mother. | Defect fixed |
| 3 | §3.3 `RUN-PICK-2`, `-3` | No stage is preselected and first run cannot be completed without an explicit choice; the PWA preselects `breastfed` with a live confirm. | Defect fixed |
| 4 | §4 `RUN-MEANS-1` | The stage never affects display; the PWA's day view filters meal rows by the eligible-actor set. | Defect fixed |
| 5 | §7 `RUN-CONSENT-1`..`-3` | A consent gate precedes the picker; the PWA has none. | Settled by #694 |

Three of the five are defects live in the shipped PWA today, and they compound: the preselected stage
(3) is only dangerous because the day view filters on it (4), and the welcome copy (2) is what makes the
result read as data loss rather than as a wrong setting. #712 found the chain; this section breaks it at
all three links.

---

## 9. Verification

### Where each rule is verified today

| Rules | Verified today by | Verdict |
| --- | --- | --- |
| `RUN-GATE-1`, `-2` | `layout.test.ts:62-99` — five cases over the three-valued signal, including "does not redirect while loading" | **do not translate** as written; re-derive `RUN-GATE-1` alone. The tests pin the race guard Divergence 1 retires, and a synchronous read has no `loading` state to assert |
| `RUN-GATE-3` | none — the PWA has no store-emptiness check and no onboarding marker to forbid | **re-derive** as absence checks |
| `RUN-GATE-4` | none — nothing can flash in the reference, since the gate is synchronous once the signal emits | **re-derive** |
| `RUN-GATE-5` | none — the stage cannot go absent in the reference except by factory reset | **re-derive**; this is the rule the whole section rests on and nothing verifies it |
| `RUN-COPY-1` | `page.test.ts:29-36` asserts the heading and the three labels render | **translate** for the labels; the heading assertion pins `"Vítejte"`, which Divergence 2 replaces |
| `RUN-COPY-2` | none — there is one variant, so there is no branch to test | **re-derive**, both variants |
| `RUN-COPY-3` | none anywhere, in either repo | **re-derive** — see below |
| `RUN-ABSENT-1`..`-4` | none | **re-derive** as absence checks |
| `RUN-PICK-1` | `page.test.ts:29-36` (all three labels present) | **translate** |
| `RUN-PICK-2`, `-3` | none, and the reference asserts the **opposite** by implication: `page.test.ts:52-60` confirms without picking and expects a write | **do not translate**; the third case must be inverted, not ported |
| `RUN-PICK-4`, `-5` | `page.test.ts:38-50` picks `solids`, confirms, asserts the write and the landing | **translate** — the most valuable existing test on this screen |
| `RUN-PICK-6` | `feeding-stages.ts` maps identifiers to labels with a `satisfies` clause, so a missing label is a compile error | **translate** the mechanism, not a test |
| `RUN-PICK-7` | `page.test.ts:52-60` — a failed write does not navigate | **translate** |
| `RUN-PICK-8` | `page.test.ts:38-50` asserts the landing route is today | **translate** |
| `RUN-PICK-9` | `layout.test.ts:77-84` (issue #353) asserts a seeded mother landing on first run is redirected away | **do not translate**; re-derive as unreachability, which is a different claim than a redirect |
| `RUN-MEANS-1`, `-2` | `page.test.ts:432-574` in the day view pins the **opposite** — that rows collapse to the eligible set | **do not translate** (`day-view.md` records the same verdict); re-derive against the union rule |
| `RUN-MEANS-3` | **none anywhere** — `settings.md` `SET-STAGE-5` records the same gap | **re-derive**; this is the notable gap |
| `RUN-ICLOUD-1`..`-5` | none — no account state exists in the reference | **re-derive** |
| `RUN-SYNC-1`..`-5` | none — the PWA has no sync and no second writer | **re-derive**; `-4` is the one to write first, and both limbs need separate tests |
| `RUN-CONSENT-1`..`-3` | none — there is no consent gate in the reference | **re-derive** |
| `RUN-CONSENT-4` | `OPEN` | — |
| `RUN-A11Y-1`..`-7` | none, and the reference has no accessibility assertions at all | **re-derive**. `RUN-A11Y-2` is the one to write first and the only one with a subtlety: the assertion is that **no** element reports a selected state on arrival, which is a different claim from the existing visual check and is the claim a platform picker control silently breaks. `RUN-A11Y-4` is assertable as "confirm is present and reports unavailable", the inverse of the PWA's habit of removing inert controls |

### Rules nothing verifies today

Eleven groups above land on **re-derive** with no existing test at all. Four deserve naming, because a
port that assumed test coverage equals specification would inherit each silently:

- **`RUN-GATE-5` — that being stage-less is tolerated at any age of the install.** The load-bearing rule
  of the section, and unreachable in the reference: the PWA's stage can only go absent by factory reset,
  so the state this section is built to survive has never once been exercised. `settings.md` records the
  same for `SET-STAGE-7` — "the null-stage branch is never rendered in any test."
- **`RUN-MEANS-3` — that a stage change leaves existing meals alone.** No test anywhere, in a codebase
  where #712's data-loss path ran through exactly this relationship. It is the cheapest test in the
  section and the one whose absence cost the most.
- **`RUN-COPY-3` — that the copy makes no claim about finding causes.** Nothing in either repo asserts
  what the app's own text does *not* say, while the design prototype's welcome screen contains precisely
  the sentence that would fail it. This is the app's regulatory surface at its first screen, and it is
  guarded by nothing but review.
- **`RUN-SYNC-4` — the window's two boundaries.** Untestable in the reference by construction, and the
  rule most likely to be implemented as "while the process lives" by someone who has not read the
  reasoning. Both limbs are testable without CloudKit, by feeding the handler a synthetic arriving value
  before and after a backgrounding and a Settings write.
- **`RUN-A11Y-2` — that nothing announces as selected on arrival.** Named on its own because it is the
  accessibility half of the section's sharpest defect. Divergence 3 removes a visual preselection whose
  consequence was #712's apparent-total-data-loss path; a picker that announces a selected stage while
  highlighting none reinstates that path for exactly the user least able to notice it. Nothing in either
  repo asserts a selected state, so this fails silently and passes review.

### Acceptance pass

Instructions to a person holding a phone. Steps marked **✗ PWA** are expected to fail on the reference —
those are the divergences, and they are the steps that prove the port did something.

1. Install the app on a phone signed into an iCloud account with no records for it. Launch it. The
   consent screen appears **before** anything asks about feeding (`RUN-CONSENT-1`). **✗ PWA**
2. Complete consent. You reach one screen asking how the baby is fed. There is no questionnaire, no
   birth date, no severity question and no progress dots (`RUN-ABSENT-1`, `-3`).
3. Read the copy. It says what the answer governs — whose meals you can record — and says nothing about
   finding, discovering or identifying what triggers eczema (`RUN-COPY-1`, `-3`).
4. Look at the three choices. **None** is preselected or marked as usual (`RUN-PICK-2`). **✗ PWA**
5. Try to continue without picking. You cannot (`RUN-PICK-3`). **✗ PWA**
6. Pick `mixed`, then pick `solids`. The second replaces the first with no warning (`RUN-PICK-5`).
7. Confirm. You land on today's day view (`RUN-PICK-8`).
8. Try to get back to first run — swipe back, and look for any control that returns to it. There is none
   (`RUN-PICK-9`).
9. Log a meal for the baby. Change the stage in Settings to `breastfed` — the narrowest set. Return to
   the day view: the baby's meal is **still there**, unmarked, and still opens for editing
   (`RUN-MEANS-1`, `-3`). **✗ PWA** — the reference hides it.
10. Delete all data from Settings. You land on first run again, and again nothing is preselected
    (`RUN-GATE-5`, `RUN-PICK-2`, and `settings.md` `SET-DELETE-8`).
11. On a **second** phone signed into the same account, install and launch. Wait for records to arrive,
    then check that first run did **not** appear — the stage arrived with them (`RUN-GATE-1`).
12. Delete the app from the first phone and reinstall it, with the network **on**. First run appears
    (`RUN-GATE-1`, `-5`). Pick the *wrong* stage deliberately and confirm.
13. Stay in the foreground and wait for the synced stage to arrive. It replaces your answer with **no
    toast, no banner and no explanation** (`RUN-SYNC-2`, `-3`). Check Settings: the stage is the one from
    before the reinstall.
14. Repeat step 12. This time, after confirming, immediately change the stage in Settings to a third
    value. When the arriving stage lands, **your Settings change wins** (`RUN-SYNC-4`, second limb).
15. Repeat step 12 once more. After confirming, background the app and reopen it. When the arriving stage
    lands now, it does **not** override — the window has closed (`RUN-SYNC-4`, first limb).
16. Note what step 12 looked like before the records arrived: an empty day view. Confirm no
    reassurance, explanation or spinner claims the records are on their way (`RUN-GATE-2`) — the only
    thing that may appear is the empty-store download-failure message
    (`settings.md` `SET-SYNC-6`).
17. Sign out of iCloud entirely. Delete the app and reinstall. First run still appears, still completes,
    and the stage still persists (`RUN-ICLOUD-1`). **✗ PWA** — no account state exists in the reference.
18. In that state, read the screen: it tells you records cannot be created yet and that your answer will
    not be lost, in those terms rather than as an account status (`RUN-ICLOUD-2`, `-5`).
19. Turn on airplane mode with the account signed in. First run says **nothing** about iCloud
    (`RUN-ICLOUD-3`).
20. Check that first run never asks for notification, camera or photo permission (`RUN-ABSENT-4`).
21. **Turn VoiceOver on** and reach first run from a fresh install. Swipe through it: you hear the copy,
    then three stage choices in the order `breastfed`, `mixed`, `solids`, then confirm. **None of the three
    announces as selected** (`RUN-A11Y-1`, `-2`). **✗ PWA** — the reference preselects.
22. Still under VoiceOver, land on confirm before picking anything. It is **there**, and it tells you it
    is unavailable and that you need to choose (`RUN-A11Y-4`).
23. Pick `mixed`, then `solids`. You hear `solids` become selected and `mixed` stop being selected
    (`RUN-A11Y-3`).
24. Sign out of iCloud and reach first run again under VoiceOver. The consequence sentence is announced
    **before** you reach the three choices (`RUN-A11Y-6`), and it names what you cannot do rather than an
    account status (`RUN-ICLOUD-5`).
25. Set Dynamic Type to the **largest accessibility size**. All three stage labels are fully readable —
    the picker stacks if it must — and nothing is clipped (§7a question 2).

Steps 12–15 are the section's real acceptance test and each needs a fresh install; they are the only way
to exercise `RUN-SYNC-2`..`-4`, and they are slow. Steps 13–15 depend on an arriving import, which Apple
documents as deferrable out of a launch session entirely — so a step that does not fire is **not** a
failure until it has been retried on a charged, unthrottled device. Note also that step 13's timing is
what step 12 cannot control: if the import lands before you finish picking, `RUN-GATE-1` simply never
shows first run, and the case is untested rather than passed.

---

## 10. Open questions

Recorded rather than guessed. **None carries a schema deadline.** The feeding stage is a single
key-value entry outside the record store (`persistence-model.md` `DATA-OUT-1`), so nothing this screen
writes is subject to additive-only promotion, and the consent record's two fields are already settled
(`DATA-OUT-4`). Every question below concerns copy, an unowned document, or a channel that does not
exist yet.

**`RUN-CONSENT-4` — whether the app tells her the privacy notice has changed.** The only `OPEN` rule in
this section, stated at §7 with its reasoning and duplicated nowhere: it is the same question as
`settings.md` `SET-PRIVACY-14`, arriving here because a later launch is the only channel the app has.
Two things are settled about it — it cannot bind the first release, which has no previous notice to have
changed from, and it must not be built as a re-consent prompt (`consent.md` §11 states the constraint).
Nothing blocks on it and no rule branches on its answer.

**The screen's actual sentences.** `RUN-COPY-1`..`-3` fix what the copy must say, must govern, and must
never claim; they do not draft it. Two of those sentences are the owner's to write and neither is
independent of work outside this section: the new-user and returning-mother variants under `RUN-COPY-2`
have to be written as a *pair*, since the whole point of the branch is that one must not read as the
other; and the degraded-state sentence under `RUN-ICLOUD-2`/`-5` states a consequence whose wording is
already fixed in substance by `settings.md` `SET-ICLOUD-3` for the Settings line, so the two should be
drafted together or they will describe the same account state in two different vocabularies. The
regulatory constraint on all of them is `RUN-COPY-3`, and it is guarded by nothing but review (§9).

**Whether the returning-mother copy variant is worth its known failure.** `RUN-COPY-2` is
**awaiting owner confirmation** and §3.1 records the cost in place: on the reinstall path the branch
reads *new* and shows welcome copy to a mother of four months, because neither her records nor her
stage have arrived. That is not a gap to be closed later — #712's correction 4 found KVS↔CloudKit
ordering undocumented in both directions, so no signal can sequence "her settings value has arrived"
against mirroring progress. The question left open is therefore not *how to fix it* but whether the
branch earns its keep given that it is wrong precisely on the path it was added for. The alternative is
on the record as a recommendation: one newness-neutral text true for both audiences.

**Whether a degraded first run warns at all.** `RUN-ICLOUD-2` is the section's second
**awaiting confirmation** point, and unlike `RUN-COPY-2` the recommendation went the other way — that
first run proceed identically in every state and let #687's persistent banner carry the message once
she reaches the day view. What is *settled* either way is `RUN-ICLOUD-1`: first run always completes,
because `restricted` is documented by Apple as nonrecoverable, so a blocking first run would be an app
that can never be used at all on a managed device. If the answer is "no warning", `RUN-ICLOUD-2` is
deleted and `-5` goes with it; `-1`, `-3` and `-4` are untouched.

**Where first run sits relative to the OS permission prompts, in practice.** `RUN-ABSENT-4` settles the
rule — first run asks for nothing — and `skin-observation.md` `SKIN-PHOTO-20` settles the Photos case at
first use. What nobody has decided is whether the app ever explains, before that first use, why a
permission will be wanted. That is not a first-run question today only because the answer is currently
"it does not", and this section is where a future contributor would reach to add such a step. Recorded
so that reaching here is a decision rather than an oversight.

**Whether the reinstalling mother is ever told what happened.** `RUN-SYNC-3` makes the silent
replacement a prohibition, and §6 argues it is safe because `RUN-MEANS-1` hides nothing. But the wider
moment — she reinstalled, the day view is empty, records are on their way and nothing says so — is
owned by no section as a whole. The pieces exist: `settings.md` `SET-SYNC-6` puts a banner on an empty
store *only* when a download has actually failed, and `RUN-GATE-2` forbids a reassurance that the
records are coming, because no API can promise it. Whether the gap between those two is acceptable is a
product question that will be answered by real use, not by another spike, and it is the most likely
source of a future amendment to this section.

---

## 11. Appendix: what this section does not contain

So an omission is not mistaken for a gap.

- **The consent screen.** [`consent.md`](consent.md) owns it — the disclosures, the checkbox, the
  refusal path and the consent record. This section states only the three ordering rules that bind the
  picker (`RUN-CONSENT-1`..`-3`, §7) and cites the rest.
- **Changing the stage after first run.** [`settings.md`](settings.md) §2 owns the control
  (`SET-STAGE-1`..`-10`), including what a change does and does not do to existing records. This
  section owns only what the stage *means* (§4) and the one-session provisional window (§6).
- **Where the stage physically lives, and its sync semantics.**
  [`persistence-model.md`](persistence-model.md) §8.1 (`DATA-OUT-1`..`-2`) — a single key-value entry
  outside the record store, which is why the stage can be written with no iCloud account and can arrive
  independently of the records.
- **What the day view does with the stage.** [`day-view.md`](day-view.md) `DAY-STAGE-1`..`-3` and
  `DAY-MEAL-2`/`-3` — the union rule and the stage's invisibility on that screen. Received here as
  constraints, not restated.
- **The eligible-actor mapping itself.** Which actors each stage permits is the unnumbered _Actor_ rule
  in [`CONTEXT.md`](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md) § _Glossary_ and
  the **eligible actors** entry in [`GLOSSARY.md`](GLOSSARY.md). §4 cites it; it is not copied.
- **The account-state model.** Its five values, the read-only degraded mode and the banner belong to
  `settings.md` §4 and #687. §5 uses two of the five and names them; it does not define them.
- **Sync-health messaging.** `settings.md` §4.1 (`SET-SYNC-1`..`-12`). `RUN-GATE-2` forbids first run
  from showing anything about sync progress, which is a prohibition on *this* screen, not a statement
  about that surface.
- **The copy itself, in either language.** Rules constrain what the text must say and must not claim.
  The sentences are the owner's (§10), and there is no Czech: the product is English-only
  ([#677](https://github.com/jirigrill/eczema-helper/issues/677)).
- **Layout, colour, typography, component names, and whether the three choices are chips, a segmented
  control or rows.** `RUN-PICK-1`..`-5` constrain order, preselection, reversibility and the existence
  of a separate confirm control — never the shape of any of it.
- **Invariant text.** Cited by anchor, never copied.

**On the design prototype:** `redesign-prototype.html` in the frozen repo is **the most stale it is
anywhere** for this screen, and it must not be consulted for it. It depicts the parked
elimination-protocol product's onboarding: a multi-step questionnaire with dotted progress, a severity
question, allergen checklists and a generated phase schedule — all four of which `RUN-ABSENT-1`..`-3`
forbid. Its welcome screen also carries the one sentence in either repo that `RUN-COPY-3` exists to
prohibit: *"Pomůžeme ti najít, co miminku spouští ekzém"* — we will help you find what triggers your
baby's eczema (`redesign-prototype.html:146`). The live variant for this screen is the shipped route at
`582f662` (`src/routes/+page.svelte`), whose own copy is correct on that point — *"Jednoduchý deník
jídel a stavu kůže"*, a simple diary of meals and skin.

