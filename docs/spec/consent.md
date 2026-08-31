# Consent and the refusal path — behavior specification

**Status:** **owner-confirmed.** Twelve decisions were settled with the owner while writing it and
confirmed as written in [#767](https://github.com/jirigrill/eczema-helper/issues/767); each is marked
in place where a reader would otherwise re-derive it, and § Confirmation status below names all twelve.
Written
against the format settled by [#682](https://github.com/jirigrill/eczema-helper/issues/682) — see
[`TEMPLATE.md`](TEMPLATE.md) for the rules, and [`skin-observation.md`](skin-observation.md) for the
worked example.
**Behavior reference:** none. There is no counterpart in the frozen PWA — no consent gate, no
notice, no consent record, and nothing in `src/`. Every rule here is new behavior, and the section's
sources are primary-source research rather than a codebase:
`jirigrill/eczema-helper` @ `4ff1c8f`, `docs/research/art-9-lawful-basis.md` §§4.6–4.8 and 6.1–6.7.
**Resolves:** [#737](https://github.com/jirigrill/eczema-helper/issues/737) on the transition map
[#672](https://github.com/jirigrill/eczema-helper/issues/672).

## Overview

The app records health data about an infant. Under GDPR that needs a permission to process at all,
and [#694](https://github.com/jirigrill/eczema-helper/issues/694) established that exactly one is
available: **Art. 9(2)(a) explicit consent**, given by the mother on her child's behalf. Nine other
limbs were walked and closed. So before the app may write anything — before it may even ask how the
baby is fed, because that answer is personal data about her too — it has to ask, and she has to be
able to say no.

That is this screen. It states eleven things, in plain sentences, and offers two buttons: *I
consent* and *I do not consent*. If she consents, the app records that she did, which text she was
shown, and when, and she goes on to the feeding-stage picker. If she declines, the app writes
**nothing at all** and shows her a screen saying the diary cannot be kept without her consent, with
a way back and a link to the privacy notice.

The uncomfortable part is that decline is terminal. Every function of this app is recording, so an
app forbidden to record has nothing to do. That is not a design failure to be engineered around: it
is the configuration the regulator's own guidance illustrates as **compliant** — where the data is
necessary to the service requested, mandatory consent is still freely given, and total loss of
function on refusal is not "detriment". What the design owes her is honesty about it, a working way
back, and no nagging.

This document states what the screen does, in English, without reference to Swift, SwiftUI,
SwiftData, Svelte, Dexie, or the Czech interface. Swift tests are derived from the numbered rules;
the owner's acceptance pass is derived from §9.

Four things are worth knowing before the rules make sense:

1. **The gate's trigger is the absence of a consent record**, decided locally and instantly —
   exactly as `first-run.md` `RUN-GATE-1` derives first run from the absence of a stage. Nothing
   else is consulted and nothing is waited for.
2. **There is one checkbox's worth of choice, covering recording *and* sync.**
   [#705](https://github.com/jirigrill/eczema-helper/issues/705) made sync mandatory with no toggle,
   so this screen has no partial states — but it still states the two operations *separately*,
   because one choice is a granularity concession and one sentence would be an informedness defect.
3. **Withdrawal is deletion.** With no sync toggle (`settings.md` `SET-ABSENT-1`) and no export
   (`SET-ABSENT-2`), the only way to withdraw is the delete-all control. The screen must say so
   before she consents, in the same breath, because that disclosure is simultaneously an Art. 13(2)(e)
   requirement and the app's best evidence that her choice was informed.
4. **Nothing here is legal advice, and the section does not pretend the analysis is closed.** #694
   rates several downstream questions `UNSETTLED` — chief among them whether deletion-as-withdrawal
   satisfies Art. 7(3) at all. This section specifies the app's behavior; it does not resolve those,
   and §11 names them.

**How to read this document:** see
[`skin-observation.md` § How to read this document](skin-observation.md#how-to-read-this-document).
Rule ids here are `CONSENT-<group>-<n>`, permanent identity, never renumbered or reused.

### Confirmation status

**Stated per decision** so nothing unreviewed passes as settled, in the form `settings.md` §4.1 uses.
All twelve are **owner-confirmed as written**
([#767](https://github.com/jirigrill/eczema-helper/issues/767)); nothing changed on confirmation.

The status line long carried the count without the roster, which forced a reader to re-derive which
twelve were meant. They are named here once, keyed to the rule that holds each:

| # | Rule | The decision |
| --- | --- | --- |
| 1 | §2 `CONSENT-GATE-4` | An arriving consent record never dismisses the gate, though an arriving feeding stage does replace her answer (Divergence 1) |
| 2 | §4 `CONSENT-ACT-6` | One accept control, but the two processing operations stated as separate purposes (Divergence 2) |
| 3 | §5 `CONSENT-NO-1`..`-8` | A terminal refusal state exists at all (Divergence 3) |
| 4 | §6 `CONSENT-REC-5` | Delete-all clears the consent record, so withdrawal is followed by re-consent (Divergence 4) |
| 5 | §4 `CONSENT-ACT-4` | No photo-specific consent — **declined #694 §6.4's recommendation** |
| 6 | §3 `CONSENT-FORM-1`, `-2` | One long scrolling screen; a three-screen sequence rejected |
| 7 | §2 `CONSENT-GATE-6` | The sync disclosures stated in full even when sync is unreachable |
| 8 | §2 `CONSENT-SAY-8` | Apple named; the transfer disclosure rests on contractual terms alone |
| 9 | §2 `CONSENT-SAY-9`, `-10` | Withdrawal stated with its cost, in the same breath |
| 10 | §6 `CONSENT-REC-4` | The consent record holds no child identifier and no contact details |
| 11 | §7 `CONSENT-ABSENT-5` | Silence on whether app deletion removes her iCloud data, in **both** directions — **narrowed #694 §4.6 step 4's recommendation** |
| 12 | §3 `CONSENT-FORM-6`, `-4` | One text, English only; no progress indicator |

Two carry the highest re-litigation risk and are the reason this block exists: **1**, which
deliberately reverses `first-run.md` `RUN-SYNC-2` for the adjacent screen (§8 explains why "fixing"
the inconsistency would make the app record an act of consent nobody performed), and **5** and **11**,
which decline or narrow a recommendation from the research rather than following it.

**What confirmation did not cover.** Every rule above fixes **structure and branching**, not wording.
The sentences are the owner's to draft (§10, against #694 §6.3) and are **not written**, so a
confirmed rule here is not confirmed copy. The `UNSETTLED` legal questions in §11 are untouched by
this — confirmation is the owner's assent to the app's behavior, not a resolution of the law.

### Invariant dispositions

Invariants are cited, never restated. [#691](https://github.com/jirigrill/eczema-helper/issues/691)
classified all fourteen; the ones this section touches carry their disposition here so a bare
citation cannot import a contradiction.

| Ref | Leading phrase | Disposition here |
| --- | --- | --- |
| [INV-1](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-1) | _Single device, no sync_ | **Void for iOS**, and it is why this section exists. A single-device app with no recipient had no Art. 9 story to tell; [#705](https://github.com/jirigrill/eczema-helper/issues/705)'s mandatory sync is what puts an Art. 9(2)(a) basis, a named recipient and a transfer disclosure in scope. |
| [INV-2](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-2) | _No backup mechanism exists_ | **Void for iOS** as to durability ([#683](https://github.com/jirigrill/eczema-helper/issues/683)), and load-bearing in its surviving half: no export means withdrawal costs her the diary, which `CONSENT-SAY-9` must disclose *before* she consents. |
| [INV-9](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-9) | _Photos stored unencrypted at rest_ | **Void for iOS.** #705 ships CloudKit field encryption from release one. This section makes no claim about it either way — see `CONSENT-ABSENT-4`. |
| [INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11) | _The app is a Logging Tool_ | **Holds, and binds the copy.** The purpose statement says recording, never finding (`CONSENT-SAY-4`). This is the marketing tripwire at the screen where it is most dangerous, because a purpose stated here is the purpose consented to. |
| [INV-5](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-5) | _Causation is derived, not recorded_ | **Holds**, and is the reason `CONSENT-ABSENT-3` forbids an automated-decision disclosure: v1 derives nothing, so there is nothing to disclose, and disclosing "no automated decisions" would be a claim that goes stale the moment the insight engine ships. |

`CONTEXT.md` also holds invariant-shaped rules **unnumbered**, in glossary prose. None bears on this
screen: the consent gate has no counterpart in the reference product's domain at all.

### Divergences from the PWA

This is not a 1:1 port. Per [#690](https://github.com/jirigrill/eczema-helper/issues/690),
**coherence is presumed right**. This section is the one place that principle barely applies:
**every rule here is new behavior**, because the reference has no consent surface whatsoever. There
are **four** divergences, marked inline and indexed in §8, and each is of the form *"the PWA has
nothing here"* rather than *"the PWA does it differently"* — except one, which reverses a rule this
spec itself established for the adjacent screen (`CONSENT-GATE-4` against `RUN-SYNC-2`) and is the
only divergence here a reviewer should read twice.

---

## 1. Vocabulary

| Term | Meaning |
| --- | --- |
| **Consent gate** | The screen that asks for Art. 9(2)(a) explicit consent, and the state in which no consent record exists. Shown before every other screen, including first run. |
| **Consent record** | The durable evidence that she consented: the instant, and the revision identifier of the notice she was shown. A key beside the feeding stage, not a record in the store (`persistence-model.md` `DATA-OUT-3`, `-4`). |
| **Refusal screen** | Where declining lands. States that the diary cannot be kept without consent, offers a route back to the gate, and links the notice. Writes nothing. |
| **Tier 1** | The eleven disclosures that must appear on the gate itself, from #694 §6.3. Fixed by EDPB Guidelines 05/2020 para 64 plus the Art. 7(3) pre-disclosure duty — not a drafting preference. |
| **Tier 2** | The remaining Art. 13 disclosures, which live in the privacy notice instead (`settings.md` §5). The layering is authorised by Guidelines para 72. |
| **Revision identifier** | The notice's opaque monotonic version string — `v1`, `v2`, … — defined by `settings.md` `SET-PRIVACY-6`. This section only stores it. |

Two terms this section uses are shared and defined in [`GLOSSARY.md`](GLOSSARY.md): **feeding
stage**, and — by reference rather than use — **pending work**, which this screen deliberately has
none of (`CONSENT-ACT-5`).

---
## 2. When the gate is shown

**`CONSENT-GATE-1` (MUST)** — The consent gate is shown when, and only when, no consent record
exists. Nothing else is consulted.

**`CONSENT-GATE-2` (MUST)** — The decision is made instantly and locally, with no wait for sync, no
fixed delay, no launch-screen hold and no placeholder gate.

**`CONSENT-GATE-3` (MUST)** — The gate precedes every other screen, including first run
(`first-run.md` `RUN-CONSENT-1`). No feeding stage is written before a consent record exists
(`RUN-CONSENT-2`).

These three are the same shape as `first-run.md` `RUN-GATE-1`/`-2`, and deliberately so: two gates
keyed on the absence of two different keys, each decided synchronously from a local read. The
reasoning #712 established for the stage transfers without change — there is no "initial import
complete" API to wait for, and Apple's own technotes leave waiting with no terminating condition
(TN3163: a throttle *"can expire in a second or last for hours"* with *"no API … to configure the
expiration time"*).

**`CONSENT-GATE-4` (MUST NOT)** — A consent record arriving from her iCloud **never** dismisses the
gate while it is on screen. The gate is shown or it is not; an arriving record does not retract it.

> **⚠ Divergence 1 — an arriving consent record does not dismiss the gate, though an arriving
> feeding stage does replace her answer.**
> *PWA:* nothing here — no consent, no sync, no second writer.
> *iOS:* `first-run.md` `RUN-SYNC-2` lets a stage arriving mid-session silently replace her answer;
> this rule refuses the parallel move for consent.
> *Why:* a deliberate reversal, and the one divergence in this section worth reading twice. The stage
> is a *setting* whose pre-reinstall value is the true one, so overwriting a provisional guess is a
> correction. Consent is a **performative act** — para 96's *"I hereby consent"* — and a gate that
> vanishes under her thumb produces an accept she never tapped. That is not consent that has arrived;
> it is consent that has been assumed. Class: **settled by #737**.

The cost is that she may consent twice — once per device — and that is accepted, because it is
*evidentially better*: two records, each naming the revision actually shown on that device, which is
exactly what EDPB 05/2020 para 108's demonstrability test asks for. One extra screen on a second
phone is a small price for never fabricating an affirmative act.

**`CONSENT-GATE-5` (MUST)** — The gate is shown identically in every iCloud account state, including
`noAccount` and `restricted`, and says nothing about the account.

**`CONSENT-GATE-6` (MUST)** — The sync disclosures (`CONSENT-SAY-7`, `-8`) are stated in full even
when sync is currently unreachable. They describe the processing she is consenting to, not today's
connectivity.

`first-run.md` `RUN-ICLOUD-2` warns about a degraded account on the *stage picker*, and that is where
the warning stays. Consent is not a durability question: the eleven Tier-1 items are fixed by para 64
regardless of whether the account is reachable, and a twelfth conditional sentence about account state
would be the fastest way to make the one screen whose content is legally prescribed unreadable —
against para 67's *"average person"* standard. `CONSENT-GATE-6` exists because the tempting
simplification is the wrong one: an app that omitted the iCloud disclosure in `noAccount` would be
taking consent for processing it fully intends to perform.

**`CONSENT-GATE-7` (MUST)** — After consent is recorded she continues to first run
(`first-run.md` §3), which asks the feeding stage.

---
## 3. What the screen says

### 3.1 The eleven Tier-1 disclosures

Fixed by [#694](https://github.com/jirigrill/eczema-helper/issues/694) §6.3, which derived them from
EDPB Guidelines 05/2020 para 64 (a closed six-item minimum for *informed* consent), Art. 7(3)
sentence 3, and §5.5's two Apple-specific additions. They are **not a drafting preference and not
reorderable at will** — each carries its own source. This section states them as one rule each so a
test can name the missing one.

**`CONSENT-SAY-1` (MUST)** — The developer's **real name** as a natural person, plus a contact email.

A trading name alone fails Art. 13(1)(a), and Art. 4(7) expressly contemplates a natural-person
controller, so there is no entity to stand behind. A home address is not required where an email is
given. Note this is the one Tier-1 item that **cannot** be demoted to the notice: Guidelines
footnote 42 draws the line at controller identity and purposes.

**`CONSENT-SAY-2` (MUST)** — That the records are **about the child**, and that she is consenting
**as the child's parent, on the child's behalf**.

Not *"my data"* — that would be inaccurate on these facts. #694 §3.5 established the mechanism:
outside Art. 8, the GDPR is silent on proxy consent, so validity falls to the Czech Civil Code, where
§ 892(2) lets either parent act alone and § 876(3) presumes the other's agreement toward a good-faith
third party. **`UNVERIFIED` as to drafting** — no EDPB guidance addresses the wording of parental
explicit consent outside Art. 8, which does not apply here.

**`CONSENT-SAY-3` (MUST)** — That this is **health data** about the child, said plainly.

Not euphemised as *"wellness information"*. Art. 9(1) is what makes the whole screen necessary, and a
screen that will not name the category it is unlocking is not informing her of the choice she is
making.

**`CONSENT-SAY-4` (MUST)** — The purpose, stated as **recording only** — keeping a diary she can look
back over.

**`CONSENT-SAY-5` (MUST NOT)** — The purpose never states or implies that the app will find, discover,
identify, suggest or help her determine what triggers the child's eczema.

These are one finding split by strength, and `-5` is the highest-stakes prohibition in this section.
It is the MDCG 2019-11 marketing tripwire at the one screen where it does double damage: a claimed
diagnostic purpose would re-qualify the app as a medical device *and* would fail para 64(ii)'s
specificity, because the app does not do it — v1 derives nothing
([INV-5](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-5)). Note the design
prototype's welcome screen carries precisely the forbidden sentence, in Czech; `first-run.md`
`RUN-COPY-3` guards the adjacent screen for the same reason. Consent is worse than copy, though: a
purpose stated here is the purpose consented to, so an overstated purpose does not merely mislead, it
misdescribes the lawful basis.

**`CONSENT-SAY-6` (MUST)** — The data types, itemised: the meals the mother eats, skin observations
across nine body regions at four severity levels, **photographs of the child's skin** named
separately, and dates and times.

Photographs are named as their own item rather than folded into "observations" — see `CONSENT-ACT-4`,
where the decision not to give them a second checkbox is recorded. Naming them here is what carries
that decision's weight.

**`CONSENT-SAY-7` (MUST)** — That the data is stored **on this phone**.

**`CONSENT-SAY-8` (MUST)** — That the data is **copied to her own iCloud account**, naming **Apple**,
and that it **may be stored outside the EEA** with the risk that carries.

Para 65 does not strictly require naming a *processor* on the consent screen, but sync is the single
fact most likely to surprise her, and the transfer disclosure pulls Apple in regardless. The transfer
half is **mandatory consent content** under para 64(vi), engaged on the conservative reading: #694
§5.4 found no executed current SCCs in the ADPLA (only *"Model Contract Clauses"* on request), no
published sub-processor list, and Apple's contractual geographic discretion.
`settings.md` `SET-PRIVACY-10` additionally forbids any claim that Apple participates in the EU–US
Data Privacy Framework — **Apple Inc. is not on the participant list at all**, verified against the
official workbook — so the transfer disclosure rests on contractual terms alone and must not be
softened by an adequacy claim.

**`CONSENT-SAY-9` (MUST)** — The right to **withdraw at any time**, stated *before* she consents,
naming where it lives — **and stating in the same breath that withdrawing means deleting everything,
and that the records cannot be got out of the app first.**

**`CONSENT-SAY-10` (MUST NOT)** — The screen never implies that withdrawal is a switch, a toggle, or
a reversible setting, and never implies that her records can be kept after it.

Art. 7(3) sentence 3 requires the pre-disclosure specifically — the existence of the right is a
*precondition* of valid consent, not a downstream obligation. What makes this pair heavier than #694
§6.3's original item 9 is the shape #705 left: with no sync toggle
(`settings.md` `SET-ABSENT-1`) and no export (`SET-ABSENT-2`), the only withdrawal route is the
delete-all control (`SET-DELETE-1`), which destroys the diary. #694 §6.5 is explicit that this
disclosure must get **heavier, not lighter**, and the reason is not candour for its own sake: a mother
who understands that withdrawal costs her the whole record is materially better informed, which is
simultaneously the Art. 13(2)(e) *"consequences of failure to provide"* disclosure and the strongest
available support for the *"freely given"* argument in §4.4 — the argument the entire Art. 9(2)(a)
basis rests on. Softening it would trade the app's best evidence of valid consent for a nicer screen.

Note what these two do **not** do: they do not enumerate deletion mechanisms. Apple's system deletion
path belongs in the notice and on the delete confirmation (`settings.md` `SET-PRIVACY-3`,
`SET-DELETE-17`), not here. Item 9's job is that the right exists, where it lives, and what it costs.

**`CONSENT-SAY-11` (MUST)** — That the app is offered to **adults**.

This is #694 §6.6 item 9's in-app half, and it lands here because this is the screen where the claim
does work: `CONSENT-SAY-2` already establishes she is the parent consenting for the child, so "this
app is for adults" is that sentence's other half rather than a bolt-on. It is sourced to Guidelines
para 130, which is the EDPB's own route to putting **Art. 8 out of scope** — and Art. 8 being out of
scope is what makes the Czech 15-year age threshold a red herring for this product (#694 §3.2, §3.3).
Without this statement, the disapplication argument loses its cleanest support.

The **App Store listing half** of that build-list item is *not* this section's, and is not
implementable from a spec: it is a pre-submission human task in the same class as the app's real name
([#697](https://github.com/jirigrill/eczema-helper/issues/697)) and trader status, and it belongs to
the map's listing-surface work. Recorded in §10 so it is not lost.

---
### 3.2 How the eleven fit on one screen

**`CONSENT-FORM-1` (MUST)** — All eleven disclosures are readable on the consent screen itself,
without tapping into a sub-layer, an accordion, a "more detail" reveal or a second step.

**`CONSENT-FORM-2` (SHOULD)** — The screen is **one scrolling screen** with the two act controls at
its end, not a sequence of steps.

**`CONSENT-FORM-3` (MUST NOT)** — Neither act control is reachable before the disclosures have been
laid out above it. There is no *"skip to accept"*.

**`CONSENT-FORM-4` (MUST NOT)** — The screen carries no progress indicator, step counter or dots.

WP260 para 11's test is that she *"should not have to seek out the information"*, and para 82
expressly permits interruption: *"it may be necessary that a consent request interrupts the use
experience to some extent to make that request effective."* So a long screen is sanctioned; a layered
one is the thing to avoid. `CONSENT-FORM-2` is `SHOULD` rather than `MUST` because scrolling is a
presentation choice — what is required is that nothing is hidden behind a tap, and that is
`CONSENT-FORM-1`. A **sequence** was considered and rejected: three screens of two disclosures each
would each be short, but she would be four taps into an act of consent before seeing the sync
disclosure, which is the one most likely to change her answer.

`CONSENT-FORM-4` mirrors `first-run.md` `RUN-ABSENT-3` for the same reason: dots imply a funnel she is
progressing through, and a consent request is not a step in a sign-up.

**`CONSENT-FORM-5` (MUST)** — The register is short declarative sentences an average person reads
once. The screen links the privacy notice for the Tier-2 detail (`settings.md` `SET-PRIVACY-1`, `-2`)
and links nothing else.

Para 67 sets the standard — *"easily understandable for the average person and not only for
lawyers"* — and para 70 requires assessing the audience, which here is a new mother, on a phone,
plausibly one-handed and tired. Para 72 authorises the layering that keeps this screen short: legal-basis
citations, the recipients list, transfer-mechanism detail, the full rights list, the ÚOOÚ complaint
route and retention criteria all live in the notice, and Example 13 confirms that omitting them from
the first layer still yields valid informed consent.

**`CONSENT-FORM-6` (MUST)** — One text, in English. No dialect split and no Czech version.

Consistent with `settings.md` `SET-PRIVACY-11` and for the same sourced reason: the translation trigger
throughout is **targeting**, not establishment. If the product is ever offered in Czech this rule is
what must be revisited first, and para 67's *"clear and plain language"* is assessed in the language
she reads.

---

## 4. The act of consenting

**`CONSENT-ACT-1` (MUST)** — The screen offers exactly **two controls**: a performatively-worded
accept and a performatively-worded decline. *"I consent"* / *"I do not consent"*, not *"Continue"* and
not *"I understand"*.

**`CONSENT-ACT-2` (MUST)** — The two controls are **equally weighted** visually. The decline is not
greyed, not smaller, not lower-contrast, and not rendered as a text link beside a filled button.

**`CONSENT-ACT-3` (MUST NOT)** — There is no pre-ticked state, no default selection, and no control
that is armed before she acts.

Example 17 (para 96) illustrates the pattern as *"Yes and No check boxes"*, drawn from web forms; what
it **tests** is an unambiguous affirmative act plus a working refusal. Two performative buttons satisfy
both more cleanly on a phone than tick-then-tap, which introduces a state where she has ticked and not
continued — an ambiguity about whether she consented that a consent record must never be built on.
`CONSENT-ACT-2` is para 79's logic (which rules out pre-ticked boxes) applied to the refusal: a
disadvantaged decline is a pre-ticked accept by other means. This is also the pair the acceptance pass
can actually check on a device, which is why they are separate rules.

**`CONSENT-ACT-4` (MUST NOT)** — There is **no second checkbox** for photographs, and no separate
photo consent. One act covers recording, photographs and sync.

#694 §6.4 recommended a photo-specific opt-in on granularity grounds (paras 43–44) and §4.8 rates it
**`UNVERIFIED`** — prudent design, required by no source. It is declined, and #705's own reasoning is
what declines it: Recital 43's separation duty is conditioned on *"despite it being appropriate in the
individual case"*, and separation is not appropriate here because photographs are not a **purpose**
boundary — they serve the identical purpose as the rest of the diary, which is what para 57 permits one
consent to span. A photo checkbox would also create a persisted per-user state gating a feature — a
partial state and a schema deadline — for an intrusion she already controls per frame by not taking the
photograph. `CONSENT-SAY-6` carries the granularity weight instead, by naming photographs explicitly.

**`CONSENT-ACT-5` (MUST NOT)** — The screen holds no *pending work* ([`GLOSSARY.md`](GLOSSARY.md)).
Leaving it before acting writes nothing and warns about nothing.

There is nothing to lose here: no text field, no partial state, and no draft. This is a prohibition
with an id rather than an absence, because every *other* editing surface in the product answers the
pending-work question and an implementer would reasonably look for this one's answer.

**`CONSENT-ACT-6` (MUST)** — The two operations — keeping the diary on this phone, and copying it to
her iCloud — are stated as **two separate purposes** above the single act control.

> **⚠ Divergence 2 — one choice, two stated purposes.**
> *PWA:* nothing here.
> *iOS:* one accept control covering both operations, with their purposes stated separately rather
> than merged into a single sentence.
> *Why:* [#705](https://github.com/jirigrill/eczema-helper/issues/705) accepted the granularity loss
> on the **choice**, not on the **disclosure**. One checkbox is a granularity concession the ticket
> priced and took; blurring two processing operations into one sentence would be a distinct and
> cheaper-to-avoid informedness defect, because para 64(ii) requires *"the purpose of **each** of the
> processing operations for which consent is sought"*. Stating them separately also anchors
> `CONSENT-SAY-8`'s transfer risk to the operation it belongs to instead of leaving it floating.
> Class: **settled by #737**.

**`CONSENT-ACT-7` (MUST NOT)** — Consent is never carried by anything else: not the App Store
purchase, not an onboarding *Continue*, not accepting terms, and not the act of picking a feeding
stage (`first-run.md` `RUN-CONSENT-3`).

Para 81 is explicit that consent *"cannot be obtained through the same motion as agreeing to a
contract or accepting general terms and conditions of a service"*, and WP 202 p. 14 (persuasive only)
adds that tapping Install *"is unlikely to provide sufficient information in order to act as valid
consent"*.

---
## 5. The refusal path

**`CONSENT-NO-1` (MUST)** — Declining writes **nothing**. No consent record, no feeding stage, no
record of any kind, and no marker that she declined.

**`CONSENT-NO-2` (MUST)** — Declining lands on the **refusal screen**, which states plainly that the
diary cannot be kept without her consent.

**`CONSENT-NO-3` (MUST)** — The refusal screen offers exactly two things: a route **back to the
consent gate**, and a link to the **privacy notice**.

**`CONSENT-NO-4` (MUST NOT)** — The refusal screen offers nothing else. No refund route, no
contact-the-developer control, no feedback prompt, no "tell us why", and no survey.

**`CONSENT-NO-5` (MUST NOT)** — The refusal screen is never a dead end with no way back.

> **⚠ Divergence 3 — a terminal refusal state exists at all.**
> *PWA:* nothing here. The reference has no consent, so refusal is unrepresentable and the first screen
> is the stage picker.
> *iOS:* declining reaches a screen from which the app does nothing but explain itself and offer a way
> back.
> *Why:* new behavior forced by the Art. 9 structure. Every function of this app is recording, so an
> app forbidden to record has nothing to do — the terminal state is not a design choice but an
> arithmetic one. Class: **settled by #694** (§6.2), **shaped by #737**.

The shape is uncomfortable and it is the configuration the regulator's own guidance illustrates as
**compliant**. #694 §4.4 established it from Guidelines paras 99–102: para 32 disapplies Art. 7(4)
where the data is necessary for the requested service, and Examples 19–20 demonstrate residual explicit
consent operating validly where the health data is indispensable. **Total loss of function on refusal is
not, on those examples, "detriment" under Recital 42** — though §4.8 records that no source addresses
withdrawal of the processing that *is* the product, so this is settled in substance rather than in terms
(§11).

`CONSENT-NO-4` is a prohibition rather than an omission because each excluded affordance is one a
reasonable implementer would add. A refund link is Apple's flow to own, and an in-app link to it is the
app talking her out of a purchase she has not asked to reverse. A contact control is redundant: the
developer's email is on the consent screen as `CONSENT-SAY-1`, one tap back. And a "tell us why" prompt
on a refusal screen is pressure applied at the moment the guidance is most concerned about pressure.
The screen's only honest content is *"there is nothing here"*; a fourth affordance makes it look like a
negotiation.

**`CONSENT-NO-6` (MUST)** — On a later launch after declining, the **consent gate** is shown again —
not the refusal screen.

**`CONSENT-NO-7` (MUST NOT)** — The app does not record that she declined, and does not write a
device-local marker of any kind on the refusal path.

**`CONSENT-NO-8` (MUST NOT)** — Within a single session, declining is never followed by an unprompted
re-ask. The gate returns only because she navigated back to it (`CONSENT-NO-3`) or because the app
launched again.

These three are one decision. The gate is derived from the *absence* of a consent record
(`CONSENT-GATE-1`), so a decline flag would be the device-local marker `first-run.md` `RUN-GATE-3`
already refused once — and it fails the same way: it dies with the app container on deletion, while
**surviving a backup restore**, so on a replacement phone it would assert a refusal she never made, in
a state that is neither askable nor repairable. It would also be a persisted field, taking on a schema
deadline (`persistence-model.md` §10.3) that this section otherwise does not have.

Re-presenting the gate on a **fresh launch** is not the repeated nagging #694 §6.2 forbids, and the
distinction is `CONSENT-NO-8`: nagging is prompting again *within* a session she has already declined
in. A launch is her opening the app, which is a fresh request to use it — and the app's only honest
answer to that request is the same question.

---

## 6. The consent record

**`CONSENT-REC-1` (MUST)** — Accepting writes a durable consent record before any other write.

**`CONSENT-REC-2` (MUST)** — It holds the **instant** she consented and the **revision identifier of
the notice she was actually shown** (`settings.md` `SET-PRIVACY-6`).

**`CONSENT-REC-3` (MUST)** — The revision recorded is the revision of the text **rendered on this
device**, never the newest revision known to exist anywhere.

Where it lives is the persistence section's: a key beside the feeding stage rather than a record in the
store, so a duplicate is unrepresentable (`persistence-model.md` `DATA-OUT-3`, `-4`, and Divergence 9
there). What this section adds is `CONSENT-REC-3`, which is the rule that makes the record *evidence*
rather than a timestamp. EDPB 05/2020 para 108 requires that *"the information provided to the data
subject at the time shall be demonstrable"*, illustrates it with *"a copy of the information that was
presented to the data subject at that time"*, and rules out the cheap substitute: *"It would not be
sufficient to merely refer to a correct configuration of the respective website."* Since the notice text
is compiled into the binary (`settings.md` `SET-PRIVACY-2`), the identifier plus the build is a
retrievable copy — but only if the identifier names what *this* build rendered. A phone running an older
build holds older text, and that is correct rather than stale (`SET-PRIVACY-8`).

**`CONSENT-REC-4` (MUST NOT)** — The consent record holds no health data, no identifier of the child,
and no contact details.

Its content is exactly: that she consented, when, and to which text. #694 §6.6 items 12 and 13 forbid
the two things that would otherwise creep in — collecting the child's identity to enable notification
at 18 (which fails minimisation and is the precise pattern para 145 warns against), and an age-triggered
re-consent flow at 15/16/18 (which would encode a guess about an `UNSETTLED` question into the schema,
where para 148's default is continuity).

**`CONSENT-REC-5` (MUST)** — The delete-all control clears the consent record along with everything
else, and she consents again before being asked the feeding stage.

> **⚠ Divergence 4 — delete-all clears the consent record, so withdrawal is followed by re-consent.**
> *PWA:* the reset clears every table in the local database and there is nothing else anywhere; a
> consent record does not exist to survive it (`reset-database.ts`).
> *iOS:* the wipe reaches a value that is **not** in the store — the consent record beside the feeding
> stage — and re-consent is therefore part of the post-deletion path.
> *Why:* `settings.md` `SET-DELETE-8` already promises she lands on first run *"in the same state as a
> fresh install"*, and a surviving consent record would contradict that promise in the one place it
> matters. Class: **settled by #737**.

This closes a gap rather than adding a feature. `SET-DELETE-6` enumerates what the wipe destroys —
meals, observations, photos, the feeding stage — and does **not** name the consent record, while
`SET-DELETE-8` promises fresh-install state; before this rule, those two were in conflict and an
implementer would have resolved it silently either way. The resolution is not merely tidiness: delete-all
**is** #705's Art. 7(3) withdrawal route, so a wipe that left the consent evidence standing would leave a
record asserting a live consent for processing she has just revoked. Art. 17(1)(b) and Guidelines para
117 (*"further storage"* is itself a processing action needing a basis) both point the same way.

The cost is one extra screen on a path she takes at most once, and re-consent is cheaper here than
re-asking the stage: nothing is lost by asking again, and #712 already established that re-asking the
stage is harmless. **`settings.md` `SET-DELETE-6` should name the consent record** — recorded in §10 as
an amendment this section needs rather than made silently to another section's rule.

---

## 6a. Accessibility

On this screen accessibility is not a usability property — it is a **validity** property. Consent is
valid only if it is informed (§3), and a disclosure she cannot read is a disclosure she was not given.
WP260 para 11's test is that she *"should not have to seek out the information"*, and information
present on screen but unreachable through the interface she is using has been sought out and not found.
So every rule below is §3 or §4 restated against the accessibility surface, and a breach of one is a
breach of the rule it restates.

**`CONSENT-A11Y-1` (MUST)** — All eleven disclosures (§3.1) are reachable and readable through
assistive technology, in the order they appear, without entering any sub-layer. This is
`CONSENT-FORM-1` bound to the accessibility surface: a disclosure hidden behind an accessibility
container that must be opened is behind a tap, which that rule forbids.

**`CONSENT-A11Y-2` (MUST)** — The two act controls (`CONSENT-ACT-1`) are announced by their
performative wording — *"I consent"*, *"I do not consent"* — and traited as buttons. Neither is
announced as *Continue*, and neither is announced in a way that implies it is the expected answer.

**`CONSENT-A11Y-3` (MUST)** — The two controls are **equally weighted** to assistive technology, as
`CONSENT-ACT-2` requires visually. Same trait, adjacent in focus order, neither marked as a default,
a preferred action, or a hint. A decline that is reachable only after passing over the accept, or
announced with a lower prominence the platform assigns to secondary actions, is the disadvantaged
refusal that rule forbids by another route.

**`CONSENT-A11Y-4` (MUST)** — Neither control is reachable in focus order before the disclosures above
it (`CONSENT-FORM-3`). There is no accessibility shortcut, rotor entry, or custom action that jumps to
accept.

**`CONSENT-A11Y-5` (MUST)** — The link to the privacy notice (`CONSENT-FORM-5`) is announced as a link
and says where it goes, not *"tap here"*. It is the Tier-2 route, so an announcement that does not
identify it makes the layering §3.2 relies on unnavigable.

**`CONSENT-A11Y-6` (MUST)** — The refusal screen (§5) is fully reachable, and both of the two things it
offers (`CONSENT-NO-3`) are announced. `CONSENT-NO-5` forbids a dead end, and a route back that is not
announced is a dead end for anyone who cannot see it.

**`CONSENT-A11Y-7` (MUST NOT)** — No label, hint or announcement on this screen states or implies what
the app will find, discover or conclude (`CONSENT-SAY-5`), or that withdrawal is a toggle
(`CONSENT-SAY-10`). The prohibitions in §3 are prohibitions on what the screen *says*, and an
announcement is the screen saying something.

### 6a.1 The five questions

| # | Answer |
| --- | --- |
| 1 | **VoiceOver label and trait** — three interactive elements only: accept, decline (`CONSENT-A11Y-2`, `-3`) and the privacy-notice link (`-5`), plus the refusal screen's two (`-6`). Everything else on the screen is text, and `CONSENT-A11Y-1` governs it. |
| 2 | **Dynamic Type** — no disclosure may truncate, be clipped, or become unreachable at any size. This is the strongest Dynamic Type requirement in the spec, and it follows from validity rather than comfort: at the largest accessibility sizes the eleven disclosures may run to many screens of scrolling, and that is **acceptable** — para 82 sanctions interruption, and `CONSENT-FORM-2` is already only a `SHOULD`. What is not acceptable is a fixed-height text area that scrolls internally, a "read more" that appears only at large sizes, or act controls pinned over the text. |
| 3 | **Colour alone** — the one case is `CONSENT-ACT-2`'s equal weighting, which is about visual prominence and is answered by `CONSENT-A11Y-3` for the non-visual channel. Nothing on this screen conveys meaning by colour. |
| 4 | **Focus order and grouping** — disclosures in their stated order, then the two act controls, per `CONSENT-A11Y-4`. Each disclosure is its own element; the eleven are not merged into one long announcement, because a single utterance of the whole screen cannot be re-read selectively. |
| 5 | **Reduce Motion** — not applicable. This section specifies no animation and no transition; `CONSENT-FORM-4` even forbids a progress indicator. |

---
## 7. What this screen does not contain

These are prohibitions with ids, not features nobody built. Each is a decision taken elsewhere that a
reader would come to this screen looking for, and an implementer filling the gap with a reasonable guess
would silently reverse it.

**`CONSENT-ABSENT-1` (MUST NOT)** — No second-parent consent flow, and the mother is never asked to
declare that the father agrees.

§ 876(3) already supplies the presumption. Asking converts it into a user representation that may be
false, and collects data the app does not need (Art. 5(1)(c)) — #694 §3.5 and §6.6 item 11.

**`CONSENT-ABSENT-2` (MUST NOT)** — No age gate, no date of birth, and no question about the mother's
own age.

Art. 8 does not apply on two independent grounds (#694 §3.2): the service is offered to an adult, and
`CONSENT-SAY-11` states so. An age gate would be machinery for a threshold that is a red herring for this
product, and would collect a new category of personal data to service it.

**`CONSENT-ABSENT-3` (MUST NOT)** — The screen makes no automated-decision-making disclosure, in either
direction. It does not say the app makes them and does not say it makes none.

Para 64(v) is conditioned on *"where relevant"*, and v1 derives nothing
([INV-5](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-5),
[INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11)) — so there is nothing to
disclose. Stating *"no automated decisions"* is declined because it is a claim that goes stale the moment
the insight engine ships, and #694 §4.5 established that the insight engine requires **fresh consent**
anyway (paras 58, 90, Example 11), so the disclosure would arrive with its own new screen rather than
needing a placeholder now.

**`CONSENT-ABSENT-4` (MUST NOT)** — The screen makes no claim about encryption, and does not describe
what field encryption protects.

#705 ships CloudKit field encryption from release one, and it is a real Art. 32 measure — but it protects
*values*, never *structure*: Core Data stores relationships as plaintext foreign keys, so which observation
belongs to which meal stays server-visible regardless (recorded on
[#714](https://github.com/jirigrill/eczema-helper/issues/714)). A consent screen that said "your data is
encrypted" would therefore overstate it, and the qualification that made it accurate would cost a paragraph
on the screen para 67 wants short. The notice is where technical measures may be described at length.

**`CONSENT-ABSENT-5` (MUST NOT)** — The screen does not state that deleting the app removes her iCloud
data, and does not state that it preserves it.

Binding here for the same reason it binds the notice (`settings.md` `SET-PRIVACY-4`): Apple documents
**neither**, the question is `NOT FOUND` in both directions, and this is a statement to a mother about
where her infant's health records are. #694 §4.6 step 4 recommended stating the survival half; #716 found
it unsourced and forbade asserting it either way. The **substance** of the recommendation survives without
the unsourced mechanism, and it is `CONSENT-SAY-9`: what withdrawal costs her, and that the records cannot
be exported.

**`CONSENT-ABSENT-6` (MUST NOT)** — The screen requests no system permission. Notifications, Photos and
the camera are requested at first use (`skin-observation.md` `SKIN-PHOTO-20`), never here.

Consistent with `first-run.md` `RUN-ABSENT-4`. A permission prompt riding on the consent screen would also
blur the two very different things a mother is being asked in the same moment.

**`CONSENT-ABSENT-7` (MUST NOT)** — The screen offers no way to proceed with recording but without sync,
and no partial-consent state of any kind.

`settings.md` `SET-ABSENT-1`: #705 made sync mandatory. Layout B of #694 §6.4 — two checkboxes, sync
optional — is **dead**, and this rule exists because that layout is written down in the research document
and a reader may reach it without reaching #705.

---

## 8. Divergence index

| # | Where | Divergence | Class |
| --- | --- | --- | --- |
| 1 | §2 `CONSENT-GATE-4` | An arriving consent record never dismisses the gate, though an arriving feeding stage does replace her answer (`first-run.md` `RUN-SYNC-2`). | Settled by #737 |
| 2 | §4 `CONSENT-ACT-6` | One accept control, but the two processing operations are stated as separate purposes. | Settled by #737 |
| 3 | §5 `CONSENT-NO-1`..`-8` | A terminal refusal state exists at all — the PWA has no consent and so no refusal. | Settled by #694 |
| 4 | §6 `CONSENT-REC-5` | Delete-all clears the consent record, so withdrawal is followed by re-consent. | Settled by #737 |

Unlike every other section written against this format, **none of these four is a defect fixed** — there
is no reference behavior here to have got wrong. Three are new behavior with no counterpart, and the one
worth a reviewer's attention is Divergence 1, because it deliberately reverses a rule this spec itself
established for the adjacent screen. If a future contributor "fixes" the inconsistency, they will have
made the app record an act of consent that nobody performed.

---
## 9. Verification

### Where each rule is verified today

**Nothing in the reference repo verifies any rule in this section**, because the reference has no consent
surface at all: no gate, no notice, no record, and no refusal path. The table below is therefore shorter
than every other section's, and its verdict column is uniform for a reason worth stating rather than
leaving implicit.

| Rules | Verified today by | Verdict |
| --- | --- | --- |
| `CONSENT-GATE-1`..`-3`, `-7` | none — no consent record exists to be absent | **re-derive**. The gate's shape may be modelled on `layout.test.ts:62-99`, which tests the *stage* gate, but only as a pattern: those tests pin the three-valued `loading` signal that `first-run.md` Divergence 1 retires |
| `CONSENT-GATE-4` | none — the PWA has no sync and no second writer | **re-derive**. Testable without CloudKit by feeding the handler a synthetic arriving record while the gate is on screen |
| `CONSENT-GATE-5`, `-6` | none — no account state exists in the reference | **re-derive** |
| `CONSENT-SAY-1`..`-11` | none | **re-derive** as content assertions. Eleven separate rules exist precisely so a test can name which disclosure is missing |
| `CONSENT-SAY-5` | none anywhere, in either repo | **re-derive** — see below |
| `CONSENT-FORM-1`..`-6` | none | **re-derive**; `-1` and `-3` are assertable, `-2` and `-5` are acceptance-pass matter |
| `CONSENT-ACT-1`..`-3`, `-6`, `-7` | none | **re-derive** |
| `CONSENT-ACT-4`, `-5` | none | **re-derive** as absence checks — prefer making the state unrepresentable |
| `CONSENT-NO-1`, `-7` | `reset-database.ts` tests assert a full wipe, which is the opposite claim | **do not translate**; re-derive as "no write occurred", which needs a store spy rather than a wipe assertion |
| `CONSENT-NO-2`..`-6`, `-8` | none | **re-derive** |
| `CONSENT-REC-1`..`-4` | none — no consent record exists | **re-derive**; `-3` is the one to write first |
| `CONSENT-REC-5` | `reset-database.ts` clears the settings table with all the others, which is the analogous claim | **translate** the intent, not the mechanism: the consent record is in `NSUbiquitousKeyValueStore`, not a table, so `db.tables` enumeration has no counterpart |
| `CONSENT-ABSENT-1`..`-7` | none | **re-derive** as absence checks |
| `CONSENT-A11Y-1`..`-7` | none, and the reference has neither a consent screen nor any accessibility assertion | **re-derive**. Two are assertable cheaply and both are validity guards rather than usability ones: that all eleven disclosures are present in the accessibility tree without opening anything (`-1`), and that the two act controls carry the same trait with neither marked as a default action (`-3`). `-2`'s performative wording is the same content assertion `CONSENT-ACT-1` needs, run against the label instead of the rendered text |

### Rules nothing verifies today

Every rule in this section lands on **re-derive** or **do not translate**; not one has an existing test.
That is expected for a from-scratch surface, and it means the usual value of this subsection — catching
rules a port would assume were covered — applies differently here: the risk is not inherited false
confidence but **untested-by-default**, because there is no failing test to notice. Four deserve naming.

- **`CONSENT-SAY-5` — that the purpose makes no claim about finding causes.** The regulatory surface of
  the whole product, at the screen where a wrong sentence does the most damage, and guarded by nothing but
  review. `first-run.md` names the identical gap for `RUN-COPY-3` on the adjacent screen; the design
  prototype contains the forbidden sentence in Czech, so the text an implementer is most likely to
  translate is the text that fails. A test asserting the absence of a word list is weak, and it is
  better than nothing.
- **`CONSENT-REC-3` — that the recorded revision is the one this build rendered.** The single rule that
  makes the consent record evidence rather than decoration, and the one whose failure is **silent and
  permanent**: a record naming the wrong revision looks correct forever, and the error is unrecoverable
  because nothing else retains what she was shown (`settings.md` `SET-PRIVACY-6` — Apple stores only the
  URL, never the text). Test it by rendering the notice and asserting the written identifier against the
  rendered one, not against a constant.
- **`CONSENT-NO-1` — that declining writes nothing.** Easy to get wrong in the direction that cannot be
  seen: an app that wrote a consent record and then routed to the refusal screen would behave correctly
  on every visible path while holding evidence of a consent that was refused. Assert the absence of
  writes, not the presence of the screen.
- **`CONSENT-GATE-4` — that an arriving record does not dismiss the gate.** Untestable in the reference by
  construction, and the rule most likely to be "fixed" into its opposite for consistency with
  `RUN-SYNC-2`. The test is cheap and its name should carry the reason.
- **`CONSENT-A11Y-1` and `-3` — that the disclosures are reachable and the refusal is not disadvantaged.**
  Named separately from the rest of §6a because on this screen they are not usability rules: an
  unreachable disclosure means consent was not informed, and a decline the interface disadvantages is the
  pre-ticked accept para 79 rules out. Both would fail invisibly — the visual screen satisfies
  `CONSENT-FORM-1` and `CONSENT-ACT-2` while the accessibility surface does not, and no screenshot review
  distinguishes the two cases.

### Acceptance pass

Instructions to a person holding a phone. Steps marked **✗ PWA** are expected to fail on the reference —
those are the divergences, and they are the steps that prove the port did something. Every step here is
marked, because none of this exists in the reference.

1. Install the app on a phone signed into an iCloud account with no records for it. Launch it. The **first
   screen is the consent screen** — nothing has asked about feeding yet, and no day view has appeared
   (`CONSENT-GATE-1`, `-3`). **✗ PWA**
2. Read the screen top to bottom without tapping anything. Find all eleven disclosures: the developer's
   real name and an email; that the records are about the child and you are consenting as her parent; that
   this is health data; the purpose, stated as keeping a diary; the data types with photographs named
   separately; storage on the phone; the copy to your iCloud naming Apple and the possibility of storage
   outside the EEA; the right to withdraw, what it costs, and that there is no export; and that the app is
   for adults (`CONSENT-SAY-1`..`-11`). **✗ PWA**
3. Check that reading all eleven required **no tap** — no "more", no accordion, no second step
   (`CONSENT-FORM-1`, `-3`). Scrolling is expected and fine. **✗ PWA**
4. Read the purpose sentence again, looking for a claim about finding, discovering or identifying what
   triggers eczema. There is **none** (`CONSENT-SAY-5`). **✗ PWA**
5. Look at the two act controls. Both say what they do — *I consent* / *I do not consent* — and **neither
   is visually favoured**: same size, same contrast weight, neither a bare text link beside a filled button
   (`CONSENT-ACT-1`, `-2`). Nothing is pre-selected (`CONSENT-ACT-3`). **✗ PWA**
6. Count the checkboxes and toggles. There are **none** — no photo opt-in, no sync opt-out
   (`CONSENT-ACT-4`, `CONSENT-ABSENT-7`). **✗ PWA**
7. Tap **I do not consent**. You reach a screen that says the diary cannot be kept without consent, offers
   a way back, and links the privacy notice — and offers **nothing else**: no refund link, no contact
   control, no "tell us why" (`CONSENT-NO-2`..`-4`). **✗ PWA**
8. From the refusal screen, wait. Nothing re-prompts you (`CONSENT-NO-8`). Then take the route back: you
   land on the consent screen again (`CONSENT-NO-3`, `-5`). **✗ PWA**
9. Decline again, then force-quit the app and relaunch. You get the **consent screen**, not the refusal
   screen (`CONSENT-NO-6`). **✗ PWA**
10. Tap **I consent**. You continue to the feeding-stage question (`CONSENT-GATE-7`, and
    `first-run.md` `RUN-CONSENT-1`). **✗ PWA**
11. Open Settings → the privacy notice, and find its revision identifier. Check it against what the app
    recorded when you consented: the **same** identifier (`CONSENT-REC-2`, `-3`, and
    `settings.md` `SET-PRIVACY-6`). **✗ PWA**
12. Turn on **airplane mode**, then sign out of iCloud in iOS Settings, delete the app, reinstall and
    launch. The consent screen appears and reads **identically** — same eleven disclosures, including the
    iCloud and outside-the-EEA sentences, with nothing said about the account state
    (`CONSENT-GATE-5`, `-6`). **✗ PWA**
13. Consent, pick a stage, log one meal and one skin observation with a photo. Then Settings → delete all
    data. Accept the confirmation. You land on the **consent screen** — not the feeding-stage picker —
    and consenting again is required before you are asked the stage (`CONSENT-REC-5`, and
    `settings.md` `SET-DELETE-8`). **✗ PWA**
14. On a **second** phone signed into the same account, install and launch. The consent screen appears even
    though you have already consented on the first phone, and it does **not** disappear while you are
    reading it (`CONSENT-GATE-1`, `-4`). Consent, and check that this device's record names the revision
    this device rendered. **✗ PWA**
15. **Turn VoiceOver on** and restart from a fresh install. Swipe through the consent screen from the top.
    You reach all eleven disclosures, in order, and you never have to open a container to hear one
    (`CONSENT-A11Y-1`). This is the step that decides whether consent given on this device was informed.
    **✗ PWA**
16. Keep swiping to the end. The next two stops are *I consent* and *I do not consent*, in that order,
    both announced as buttons, and **neither** is announced as the default or preferred action
    (`CONSENT-A11Y-2`, `-3`). You could not have reached either before the disclosures (`-4`). **✗ PWA**
17. Find the privacy-notice link under VoiceOver. It is announced as a link and says what it opens
    (`CONSENT-A11Y-5`). **✗ PWA**
18. Decline, under VoiceOver. On the refusal screen you can reach and hear both things it offers,
    including the way back (`CONSENT-A11Y-6`). **✗ PWA**
19. Set Dynamic Type to the **largest accessibility size** and read the consent screen again. Every
    disclosure is still fully readable — the screen simply gets longer. Nothing scrolls inside a fixed box,
    no "read more" has appeared, and the act controls are not sitting on top of the text (§6a question 2).
    **✗ PWA**

---
## 10. Amendments this section needs elsewhere

Two rules in adjacent sections are incomplete because this screen did not exist when they were written.
Recorded here rather than edited silently, since they belong to other sections' rule sets.

**`settings.md` `SET-DELETE-6` should name the consent record.** It enumerates what the wipe destroys —
every meal, every skin observation, every photo, and the feeding stage — and the consent record is a key
beside the stage that it does not mention, while `SET-DELETE-8` promises fresh-install state. `CONSENT-REC-5`
resolves the conflict; the enumeration should carry it, so that a reader of `SET-DELETE-6` alone reaches the
same answer. **No schema deadline** — both values are keys, not fields.

**The App Store listing's adults statement is unowned.** #694 §6.6 item 9 requires it *"and in-app"*;
`CONSENT-SAY-11` takes the in-app half. The listing half is a pre-submission human task in the class of the
app's real name ([#697](https://github.com/jirigrill/eczema-helper/issues/697)), the privacy-policy URL
(`settings.md` `SET-PRIVACY-7`) and trader status, and belongs to the map's App-Store-listing work. It is
named here because a build-list item split across two surfaces is exactly the kind that gets half-built.

---

## 11. Open questions

Recorded rather than guessed. **None carries a schema deadline**: the consent record's two fields are
settled (`persistence-model.md` `DATA-OUT-4`), and every question below concerns copy, legal exposure, or a
surface that does not exist yet.

**Whether deletion-as-withdrawal satisfies Art. 7(3) at all.** Art. 7(3) requires that *"it shall be as
easy to withdraw as to give consent"*. Giving is one tap; withdrawing means the delete-all control, which
destroys the diary, because #705 left no sync toggle and #683 left no export. #705 accepted this exposure
knowingly and #694 rates it **`UNSETTLED`** — para 46 requires the controller to show withdrawal carries
*"no costs for the data subject and thus no clear disadvantage"*, while §4.4's distinguishing argument is
that cessation here is not punitive degradation but the logical consequence of there being no data left to
display. **This section cannot resolve it and does not try**: `CONSENT-SAY-9` makes the cost explicit
before she consents, which is the only mitigation available in the app. It is one of #694's two questions
for a qualified Czech data-protection lawyer, and the app's behavior does not change on either answer.

**Whether total loss of function on refusal is "detriment" under Recital 42.** Settled in substance by
Guidelines Examples 19–20 and para 32, and **`UNSETTLED` in terms** — #694 §4.8 records that no source
addresses withdrawal of the processing that *is* the product. Guidelines Example 8 (para 49) points the
other way but is distinguishable, since the accelerometer data there was unnecessary to the service. Nothing
in §5 depends on the answer: the refusal path is the same either way.

**Whether the app actively notifies her that the notice has changed.** `settings.md` `SET-PRIVACY-14` and
`first-run.md` `RUN-CONSENT-4`, both `OPEN`, and both arriving at the same place: the app on a later launch
is the only channel available, because there is no email address, no account and no server-side reach
(`SET-ABSENT-5`), while WP260 para 29 bars the *"check back regularly"* formula outright and every modality
it names assumes a channel this app lacks. **It cannot bind the first release**, which has no previous notice
to have changed from. This section adds one constraint to whoever resolves it: a notice-changed prompt must
not be built as a re-consent prompt, because para 110 triggers re-consent on the **processing** changing
considerably, not on rewording — and re-asking for consent that nothing requires would invalidate nothing
but would teach her that the act is routine.

**The consent text itself.** These eleven rules fix what the screen must *say*; they do not draft the
sentences. Drafting is the owner's, against #694 §6.3, in the same pass as the notice's ~1,500 words
(`settings.md` §10) — and the two must be drafted **together**, because `CONSENT-SAY-9`'s withdrawal
sentence and the notice's Art. 13(2)(a) retention disclosure are the same fact stated at two lengths. No
`OPEN` rule depends on it.

**Controllership of the synced copy.** **`UNSETTLED`** (#694 §5.7), and upstream of the Art. 17 analysis
that shapes what withdrawal must achieve. Both readings are tabled there and the practical posture survives
either, which is why no rule here branches on it. Noted because a reader who resolves it may expect this
section to change, and it does not.

---

## 12. Appendix: what this section does not contain

So an omission is not mistaken for a gap.

- **The privacy notice's rules and its prose.** `settings.md` §5 (`SET-PRIVACY-1`..`-14`) settles where the
  notice lives, its versioning, its URL and the five things it must not say. This section only links to it
  and stores its revision identifier.
- **Where the consent record physically lives, and its schema.** `persistence-model.md` §8.2
  (`DATA-OUT-3`, `-4`).
- **The feeding-stage picker, its copy and its degraded-account warning.** `first-run.md` §§3, 5. The
  ordering rules that bind both screens are `RUN-CONSENT-1`..`-3` there, cited here rather than restated.
- **The delete-all control and its degraded paths.** `settings.md` §3 (`SET-DELETE-1`..`-21`). This section
  adds only what the wipe does to the consent record.
- **Layout, colour, typography and component names.** Not a design document. `CONSENT-FORM-2` names a
  scrolling screen because layering is a *content-accessibility* rule under WP260 para 11, not because the
  spec has a view of scroll views.
- **The legal analysis.** `docs/research/art-9-lawful-basis.md` is the source; this section is derived from
  it and does not restate its reasoning. Where a rule looks arbitrary, the paragraph under it names the
  paragraph of the guidance that produced it.
- **The design prototype** `redesign-prototype.html`. It depicts **no consent screen at all**, and its
  welcome screen carries the one sentence `CONSENT-SAY-5` forbids — *"Pomůžeme ti najít, co miminku spouští
  ekzém"* (we will help you find what triggers your baby's eczema). **Do not consult it for this screen.**

---

_This section states app behavior derived from primary-source research. It is **not legal advice**, and the
research it rests on says so in six places. `UNSETTLED` and `UNVERIFIED` are used literally: where #694
could not close a question, this section specifies behavior that is correct under either answer rather than
picking one silently._
