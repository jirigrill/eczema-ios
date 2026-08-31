# The app's legal-facing copy

**Status:** drafted, **awaiting owner sign-off**. Filed for
[#758](https://github.com/jirigrill/eczema-helper/issues/758).

## Overview

Four bodies of user-facing English text, drafted as one set because they are one drafting problem:
the **eleven Tier-1 disclosures** on the consent gate, the **Art. 13 privacy notice**, the
**`NSPhotoLibraryAddUsageDescription`** string, and **first run's two copy variants**. They describe
the same processing at four lengths, so they are written together and pass a shared consistency
check (§6) rather than being reconciled after the fact.

**This document is copy, not behavior.** It adds no rule and changes none. Every sentence below is
drafted *against* a rule that already exists in `docs/spec/`, and each is mapped to that rule so the
mapping is auditable. Where a sentence and a rule disagree, **the rule wins** and this document is
wrong.

**It is not legal advice**, and the research it rests on says so in six places.

## What is settled and what is not

The one input the ticket named as unresolved — **controllership of the synced copy** — is settled as
far as this document is concerned, and not in the direction the ticket expected. See §5: the copy is
drafted to be true under **either** answer, and the three passages that would change if it is ever
settled are flagged in place with `<!-- controllership -->`.

Two **placeholders** remain, and both are pre-submission human tasks rather than drafting questions:

| Placeholder | Why it is not filled here | Owner |
| --- | --- | --- |
| `<DEVELOPER NAME>` | The developer's real name as a natural person. Required by `CONSENT-SAY-1`; a trading name fails Art. 13(1)(a). Not the app's name. | pre-submission |
| `<CONTACT EMAIL>` | A contact address that will outlive the first release. | pre-submission |
| `<NOTICE URL>` | The stable public URL of `SET-PRIVACY-7`, **not editable without a version submission**. | pre-submission ([#697](https://github.com/jirigrill/eczema-helper/issues/697) class) |

The product name is the working title **`Eczema Diary`** (#697), renamed before submission. Every use
of it below is in prose the rename must sweep, and §7 lists them.

---

## 1. The consent gate: the eleven Tier-1 disclosures

The screen as it reads, top to bottom. `CONSENT-FORM-1`/`-3` require all eleven readable with **no
tap** — scrolling is expected and fine — so this is one continuous text, not an accordion.

Register is fixed by EDPB 05/2020 para 67 (*"easily understandable for the average person and not
only for lawyers"*) and para 70's audience finding: a new mother, on a phone, plausibly one-handed
and tired.

### 1.1 The text

> ## Before you start
>
> This app keeps a diary of what you eat and how your baby's skin looks. You write the entries; the
> app stores them so you can look back over them.
>
> **It does not work out what is causing your baby's eczema, and it does not try to.** It has no
> opinion about your baby's skin. It is a notebook, not an advisor.
>
> ### What is recorded
>
> - the meals **you** eat, and when
> - how your baby's skin looks — nine areas of her body, each at one of four levels
> - **photographs of your baby's skin**, if you take them
> - the date and time of every entry
>
> These records are **about your baby**, and they are **health data** about her. That is why this
> screen exists: the law treats health data about a child as needing your explicit permission, given
> before anything is written down.
>
> You are giving that permission **as her parent, on her behalf** — not for yourself. This app is for
> adults.
>
> ### Where the records are kept
>
> They are stored **on this phone**, and they are also copied to **your own iCloud account**, which is
> run by **Apple**. That copy is how the diary survives a lost phone and appears on your other
> devices. It cannot be turned off — the diary works this way or not at all.
>
> Apple may keep that copy **on servers outside Europe**. Where exactly is Apple's decision, not ours,
> and we cannot promise the same legal protection for your baby's records there as inside Europe. If
> that is not acceptable to you, do not consent.
>
> ### Changing your mind
>
> You can withdraw your permission **at any time**, in Settings, and you should know now what that
> costs, because it is more than a switch.
>
> **Withdrawing means deleting the whole diary.** There is no way to keep the records without the
> permission, and there is no way to get them out of the app first — no export, no file, no copy to
> send yourself. Every meal, every observation and every photograph goes, on this phone and in your
> iCloud. It cannot be undone.
>
> ### Who is asking
>
> `<DEVELOPER NAME>` — one person, not a company. Write to `<CONTACT EMAIL>`.
>
> The full privacy notice explains all of this at greater length, including your rights and how to
> complain. You can read it now, and it stays in Settings.
>
> [Read the privacy notice]
>
> ---
>
> **I am my baby's parent, and I consent, on her behalf, to `<DEVELOPER NAME>` recording her health
> data — including photographs of her skin — on this phone and in my iCloud account, for keeping this
> diary.**
>
> [I consent]  [I do not consent]

### 1.2 The mapping

One row per rule, so a reviewer can check the eleven are all present and a test can name the missing
one. Rule text is in `docs/spec/consent.md` §3.1 and is **not** restated here.

| Rule | Where it lands | The sentence that carries it |
| --- | --- | --- |
| `CONSENT-SAY-1` | *Who is asking* | *"`<DEVELOPER NAME>` — one person, not a company. Write to `<CONTACT EMAIL>`."* The *"not a company"* half is not decoration: it is the Art. 4(7) natural-person controller stated in words a mother reads, and it forecloses her assuming a company stands behind it. |
| `CONSENT-SAY-2` | *What is recorded*, and the accept sentence | *"These records are **about your baby**"* plus *"You are giving that permission **as her parent, on her behalf** — not for yourself"*, restated performatively in the accept sentence. The *"not for yourself"* clause is there because this is the disclosure a reader is most likely to skim past into the ordinary "my data" reading. |
| `CONSENT-SAY-3` | *What is recorded* | *"they are **health data** about her"* — the words, unhedged. No *"wellness"*, no *"information about her skin"*. |
| `CONSENT-SAY-4` | Opening | *"keeps a diary of what you eat and how your baby's skin looks… so you can look back over them"*. Recording, stated as the whole purpose. |
| `CONSENT-SAY-5` | Opening, second paragraph | *"**It does not work out what is causing your baby's eczema, and it does not try to.**"* — see §1.3. |
| `CONSENT-SAY-6` | *What is recorded* | The four-item list. Photographs are their own bullet and are bolded, per the rule's requirement that they be named separately rather than folded into "observations". Nine regions and four levels are stated as numbers because *"how her skin looks"* alone does not convey the granularity. |
| `CONSENT-SAY-7` | *Where the records are kept* | *"stored **on this phone**"*. |
| `CONSENT-SAY-8` | *Where the records are kept* | *"copied to **your own iCloud account**, which is run by **Apple**"* plus the outside-Europe paragraph. Apple is named. The transfer risk is stated as a risk (*"we cannot promise the same legal protection"*), which is para 64(vi) content, and it is **not** softened by any adequacy claim — `SET-PRIVACY-10`. |
| `CONSENT-SAY-9` | *Changing your mind* | The whole section. Withdrawal, where it lives (Settings), and — in the same breath — that it deletes everything and that nothing can be got out first. |
| `CONSENT-SAY-10` | *Changing your mind* | Carried by what the text **refuses** to say: no "switch", no "turn off", no "you can always change this later". *"it is more than a switch"* names the misreading and denies it, and *"It cannot be undone"* closes the section. |
| `CONSENT-SAY-11` | *What is recorded*, last line | *"This app is for adults."* Placed as `CONSENT-SAY-2`'s other half, immediately after the parent sentence, rather than as a bolt-on at the bottom. |

### 1.3 Three drafting choices worth defending

**`CONSENT-SAY-5` is drafted as a plain denial, not an omission.** The rule is a MUST NOT, so silence
would satisfy it. A denial is chosen because the *design prototype carries the forbidden sentence*
(`consent.md` §12, in Czech) and because a mother arriving at an eczema app plausibly expects exactly
the capability the app lacks. An unstated non-capability is one she supplies herself, and a consent
given on a purpose she invented is not consent to the purpose disclosed. *"It is a notebook, not an
advisor"* is the same fact in the register para 67 asks for.

**The withdrawal disclosure is the heaviest thing on the screen, deliberately.** #694 §6.5 requires
it get *"heavier, not lighter"*, and the reason is not candour for its own sake: a mother who
understands that withdrawal costs her the diary is materially better informed, which is
simultaneously the Art. 13(2)(e) *"consequences of failure to provide"* disclosure and the strongest
available evidence that her consent was freely given. It is the one section drafted to be
uncomfortable to read.

**The accept control is a performative sentence, not "I understand".** Guidelines Example 17 (para 96)
and footnote 38 require *"I hereby consent to…"* wording; *"I am my baby's parent, and I consent, on
her behalf, to…"* is that, with `CONSENT-SAY-2`'s proxy fact folded in so the performative act and the
capacity it is performed in are one sentence. It names the controller, the data, the two locations and
the purpose — the four things a consent must be specific about — and nothing else, so it stays
readable.

**Not on this screen, and each for a reason with a rule behind it:** no age gate
(`CONSENT-ABSENT-2`), nothing about automated decisions in either direction (`CONSENT-ABSENT-3`),
**no claim that anything is encrypted** (`CONSENT-ABSENT-4` — see §6, check 4), nothing about what
uninstalling does (`CONSENT-ABSENT-5`, `SET-PRIVACY-4`), no permission prompt
(`CONSENT-ABSENT-6`), and no partial-consent or sync-opt-out control of any kind
(`CONSENT-ABSENT-7`).

---

## 2. The Art. 13 privacy notice

Bundled and rendered in-app (`SET-PRIVACY-2`), also served at `<NOTICE URL>` (`SET-PRIVACY-7`), one
English text with no dialect split and no Czech version (`SET-PRIVACY-11`). It carries its revision
identifier on its face (`SET-PRIVACY-6`), and the consent record stores the revision she was shown.

**Revision: `v1`.**

### 2.1 The text

> # Privacy notice
>
> **Revision `v1`.** This is the notice as it stands in this version of the app. When it is reworded,
> the revision changes, and the app remembers which revision you were shown when you gave your
> permission.
>
> This notice is written by the person who made the app. It is **not** written by a lawyer and is not
> legal advice.
>
> ## In short
>
> This app is a diary. You write down what you eat and how your baby's skin looks; the app stores it
> so you can look back. It works nothing out and tells you nothing about what is causing her eczema.
>
> The records are health data about your baby. They are kept on your phone and copied to your own
> iCloud account. `<DEVELOPER NAME>` never receives them and never sees them.
>
> ## 1. Who is responsible
>
> `<DEVELOPER NAME>`, a private individual in the Czech Republic — not a company.
>
> Email: `<CONTACT EMAIL>`
>
> There is no data protection officer. One is not required for processing of this kind and size, and
> appointing one voluntarily is not something a single person can meaningfully do for himself.
>
> ## 2. Whose data, and what it is
>
> The records are about **your baby**. You are the one using the app, and you give permission on her
> behalf, as her parent.
>
> The app holds:
>
> - **The meals you eat** — the foods, and the date and time. Because you are breastfeeding, what you
>   eat is recorded as part of her diary rather than yours.
> - **Skin observations** — nine areas of her body, each recorded at one of four levels, with a date
>   and time, and an optional note you write.
> - **Photographs of her skin**, if you choose to take them.
> - **One setting**: whether she is breastfed, mixed-fed, or on solids.
> - **A record of your permission**: that you gave it, when, and which revision of this notice you
>   read.
>
> All of this is **health data concerning a child** — a special category of data under Article 9 of
> the GDPR. That is why the app asks for explicit permission before it writes anything.
>
> The app asks for **nothing else**. No name, no email address, no date of birth, no account, no
> contacts, no location. There is no analytics, no crash reporting, no advertising identifier and no
> third-party tracking of any kind.
>
> ## 3. Why, and on what legal basis
>
> **Purpose: keeping the diary, and nothing else.** So that you can write entries and read them back
> later.
>
> The app does not analyse the records, does not look for patterns between meals and flare-ups, does
> not score anything and does not suggest anything. It makes no automated decisions about you or your
> baby, of any kind.
>
> **Legal basis:** your consent — Article 6(1)(a) — and, because this is health data, your explicit
> consent under Article 9(2)(a). Consent is the only basis relied on. There is no other purpose
> operating quietly beside it.
>
> Providing the data is **not** a legal or contractual requirement. Nobody obliges you to record
> anything. The only consequence of not providing it is that there is nothing to read back: an empty
> diary is the app doing its job with no input.
>
> ## 4. Where the records go
>
> ### On your phone
>
> The records are stored in the app's own store on your device.
>
> ### In your iCloud
>
> They are also copied to **your own iCloud account**, in a private database that belongs to your
> Apple account. This is how the diary survives a lost or replaced phone and how it appears on your
> other devices signed into the same account.
>
> **This cannot be switched off.** There is no setting for it. The app was built this way because the
> alternative — a diary that exists in one copy on one phone and is gone with it — was judged the
> worse outcome for a record kept over months.
>
> **`<DEVELOPER NAME>` receives no copy.** There is no server belonging to this app, no account to
> sign into, and no channel by which the records could reach him. He cannot read your diary, cannot
> recover it for you, and cannot delete it on your behalf. <!-- controllership -->
>
> ### What Apple is, in this
>
> **Apple** — Apple Inc. and Apple Distribution International Ltd. — provides the iCloud service that
> holds the copy. In data-protection terms Apple is the **recipient** of the data.
>
> Apple's own sub-processors — the companies Apple in turn uses — are **not published**, so they can
> only be described by category: providers of data-centre and cloud-infrastructure services. This is a
> real limit on what this notice can tell you, and it is stated rather than glossed.
>
> ### Outside Europe
>
> Apple decides where the data physically sits, and **it may be stored outside the European Economic
> Area**, including in the United States.
>
> Two things about that, stated plainly because they are not comfortable:
>
> - The safeguard relied on is **contractual** — the terms Apple offers developers, which include
>   model contract clauses available on request. No copy of an executed set of those clauses has been
>   obtained.
> - **Apple is not certified under the EU–US Data Privacy Framework.** Apple Inc. does not appear on
>   the official participant list. So there is no adequacy certification behind this transfer, and
>   this notice does not claim one.
>
> The practical meaning: for the copy held outside Europe, the protection your baby's records have
> rests on Apple's contractual terms and on Apple's own compliance, not on any decision by the
> European Commission that the destination is adequate.
>
> ## 5. Photographs, and the camera roll
>
> Photographs of your baby's skin are stored in the app like any other entry, and copied to your
> iCloud with the rest of the diary.
>
> **One thing happens only if you ask for it.** After you save a photograph, the app offers you the
> chance to save a copy to your **phone's photo library** — the camera roll. This is entirely up to
> you, every time; there is no setting that makes it automatic and nothing is ever copied there
> silently.
>
> If you do save a copy there, it leaves this app's control. Your photo library is synced by Apple's
> Photos service if you have that turned on, is readable by any app you have granted photo access, and
> can appear in shared albums and in Memories. **This app cannot see any of that, cannot revoke it,
> and cannot delete the copy for you** — a photograph in your library is yours to manage, and deleting
> the diary does not touch it.
>
> The reason this route exists at all: a photograph you cannot get to is not much use when you are
> sitting in front of a dermatologist.
>
> ## 6. How long the records are kept
>
> **Until you delete them.** There is no retention period, because there is no decision for
> `<DEVELOPER NAME>` to make: the records live in your app and your iCloud account, and nobody else
> holds a copy to expire.
>
> Two ways to delete them:
>
> 1. **In the app**, in Settings: *delete all data*. This removes every meal, every observation,
>    every photograph, the feeding-stage setting and the record of your permission — on this phone,
>    and in your iCloud. It cannot be undone.
> 2. **In iOS Settings**, using Apple's own route for deleting an app's iCloud data. This one still
>    works after the app has been removed from the phone, when the in-app control is no longer
>    reachable.
>
> If your device is offline when you delete everything, the local records go immediately and the
> iCloud copy is removed when the device is next online. The app will tell you when this has happened;
> opening it once more while connected is what completes it.
>
> ## 7. Your rights
>
> You have the following rights over your baby's records, exercisable on her behalf. Where a right is
> awkward or unavailable in this app, that is said rather than omitted.
>
> - **Access** — read them: they are in the app, in front of you. There is nothing held elsewhere for
>   you to request.
> - **Rectification** — correct them: edit any entry in the app.
> - **Erasure** — delete them: either route in §6.
> - **Restriction** and **objection** — the processing is your own recording, on your own devices, and
>   stops when you stop recording or delete the diary.
> - **Portability** — **the app has no export.** There is no file, no backup and no way to move the
>   records to another app. This is a real limitation and you should weigh it before you start: the
>   diary is readable in this app and nowhere else.
> - **Withdrawing your permission** — at any time, in Settings. Because permission is the only basis
>   on which the records exist, withdrawing it and deleting the diary are **the same act**. The
>   records cannot be kept afterwards, and there is no way to take them with you first.
>
> Since `<DEVELOPER NAME>` holds no copy of your data, there is nothing he can access, correct, delete
> or send you on request. Every one of these rights is exercised by you, in the app, on your own
> device. <!-- controllership -->
>
> ## 8. Complaints
>
> You can complain to the Czech data protection authority:
>
> **Úřad pro ochranu osobních údajů (ÚOOÚ)**
> Pplk. Sochora 27, 170 00 Praha 7, Czech Republic
> [uoou.gov.cz](https://uoou.gov.cz)
>
> If you live in another EU or EEA country, you may complain to your own national authority instead.
>
> You can also write to `<CONTACT EMAIL>` first, though you are under no obligation to.
>
> ## 9. Security
>
> The records sit inside the app's own storage on your phone, protected by your device passcode and
> iOS's own file protection, and the copy in iCloud is held in a private database tied to your Apple
> account.
>
> **What is protected, precisely.** The **values** in your records — the foods, the severities, your
> notes, the photographs — are encrypted in a way that leaves them unreadable to Apple. The
> **structure** is not: which observation belongs to which day, and how many entries there are, is
> visible to the service holding them. This notice says *values, not structure* rather than "your data
> is encrypted", because the shorter sentence would claim more than is true.
>
> Beyond that, the security of the copy in iCloud is Apple's, under Apple's terms.
>
> ## 10. Changes to this notice
>
> If this notice is reworded, the revision identifier at the top changes. The app keeps the text it
> shipped with, so the revision you agreed to is the one you can still read.
>
> This notice does not ask you to check back for changes.
>
> ## 11. Children
>
> The app is offered to **adults**. It is not for use by children, and it does not knowingly collect
> anything from a child using it. The data it holds is *about* a child, recorded by her parent.

### 2.2 Art. 13 coverage

Every item of Art. 13(1) and (2), and where the notice discharges it. The Tier-2 table in
`docs/research/art-9-lawful-basis.md` is the source of the list; this table only says where each
landed.

| Art. 13 | Item | Where |
| --- | --- | --- |
| 13(1)(a) | Controller identity and contact details | §1 |
| 13(1)(b) | DPO contact details | §1 — stated as not applicable, with the reason |
| 13(1)(c) | Purposes and legal basis | §3 — Art. 6(1)(a) and Art. 9(2)(a) both cited |
| 13(1)(e) | Recipients, or categories of recipients | §4 — Apple named; sub-processors at category level, with the reason |
| 13(1)(f) | Third-country transfer, and the safeguard | §4 *Outside Europe* — contractual terms, no executed SCC copy, **no DPF claim** |
| 13(2)(a) | Storage period, or the criteria | §6 — until she deletes it; no period, and why there is none |
| 13(2)(b) | Access, rectification, erasure, restriction, objection, portability | §7 — each named, portability's absence stated |
| 13(2)(c) | Right to withdraw consent | §7, last item; and on the consent screen first (`CONSENT-SAY-9`) |
| 13(2)(d) | Right to complain to a supervisory authority | §8 — ÚOOÚ named with address |
| 13(2)(e) | Whether provision is obligatory, and the consequences | §3, last paragraph |
| 13(2)(f) | Automated decision-making and the logic | §3 — stated as none, see §6 check 3 |

Not required by Art. 13 and included anyway: §5 (the camera roll — a disclosure the notice would be
misleading without, since it is the one route data leaves the app's boundary), §9 (Art. 32 measures,
included because `SET-PRIVACY-9` requires the *facts* about what Apple can see), §10 and §11.

### 2.3 What the notice does not say, and the rule that forbids it

| Not said | Rule |
| --- | --- |
| That Apple's terms fail Art. 28(3), or any characterisation of the developer's own compliance | `SET-PRIVACY-9` |
| That Apple participates in the EU–US Data Privacy Framework | `SET-PRIVACY-10` — Apple is not on the participant list at all |
| That deleting the app removes her iCloud data — **or that it preserves it** | `SET-PRIVACY-4`. §6 states the two deletion *routes* and never narrates what uninstalling does |
| *"Check back regularly for changes"* | `SET-PRIVACY-13` — barred outright by WP260 para 29 as unfair under Art. 5(1)(a) |
| That the app is, or was reviewed by, a lawyer | `SET-PRIVACY-12` — the second line of the notice says the opposite |
| That the data is "encrypted", unqualified | `CONSENT-ABSENT-4` is the screen's rule; §9 here is the notice's qualified version — values, not structure |
| Anything the app will find, conclude or suggest | `CONSENT-SAY-5`, `RUN-COPY-3`, `CAT-DERIVE-1`..`-5` |

### 2.4 Three drafting notes

**Length.** The notice runs ~1,750 words — above the ~1,500 the ticket estimated, and the overrun is
in §§4–7 (transfers, the camera roll, deletion routes, rights), which are the sections where
`SET-PRIVACY-9` requires *facts* rather than characterisations and where each fact costs a sentence.
Recorded as a measured number rather than trimmed to the estimate: cutting 250 words means cutting a
disclosure, and the ~1,500 was a size estimate, not a rule. The *In short*
opening is WP260 para 35's layered approach used in the direction that costs nothing: the first
sixty words carry the purpose, the data category and the "he never sees it" fact, so a mother who
reads no further has read the three things that matter most.

**§7 states the absence of portability as a limitation, not as a feature.** With export declined
(#683), Art. 20 portability has no in-app answer, and the honest disclosure is that the diary is
readable here and nowhere else. Framing it as "your data stays private, it never leaves" would be a
privacy claim built out of a missing capability — and the same sentence would contradict §5, where
photographs demonstrably do leave.

**§9's *values, not structure* is the narrowest true sentence available.** CloudKit field encryption
is a real Art. 32 measure, and Core Data stores relationships as plaintext foreign keys
([#714](https://github.com/jirigrill/eczema-helper/issues/714)), so which observation belongs to which
day is server-visible regardless. The notice is the one surface where that qualification fits — the
consent screen has no room for it, which is exactly why `CONSENT-ABSENT-4` keeps the claim off the
screen entirely rather than shortening it.

---

## 3. `NSPhotoLibraryAddUsageDescription`

One string, shown by iOS at the moment she first asks to save a photograph to her library
(`SKIN-PHOTO-20`). It must name *why*, not *what* — and `SKIN-PHOTO-20` requires it name what is being
saved.

### 3.1 The string

> Saves a copy of a skin photograph you have just taken into your own photo library, so you can find
> it outside this app — to show a doctor, for instance. This happens only when you ask for it, and the
> app never reads your library.

**Length: 45 words, three clauses.** If it must be shorter, the sentence that goes is the second, never
the first.

### 3.2 Why it is worded this way

| Choice | Reason |
| --- | --- |
| *"a copy of a skin photograph **you have just taken**"* | Names what is being saved, per `SKIN-PHOTO-20`, and scopes it to this moment's photo. Not "your photos" — the app never adds anything she did not just create. |
| *"so you can find it outside this app — to show a doctor"* | This is the *why*, and it is the actual why: #683 declined export, so this is the only route an image can leave, and a dermatologist's office is the case that motivated keeping it. A purpose string that says "to save your photos" says nothing and is the shape App Review rejects. |
| *"only when you ask for it"* | `SKIN-PHOTO-21` — no automatic copy, no setting that makes it so. Stating it here matters because the system sheet is where a mother decides whether granting access hands over a standing capability. |
| *"the app never reads your library"* | The single most useful sentence in the string, and it is true of `NSPhotoLibraryAddUsageDescription` by construction — add-only access cannot read. The system's own sheet does not distinguish add-only from full access in language a mother will parse, so the app says it. |

**"Baby" is deliberately absent.** *"skin photograph"* carries what is needed, and the string is
user-facing text on a store-reviewed app: #697 recorded that *"baby"* raises a Guideline 5.1.4(b)
question, and there is no reason to buy that question for one word.

**Not the camera string.** `NSCameraUsageDescription` is a different key with a different purpose and
is not this ticket's — it is not one of the four texts, and nothing here drafts it. Flagged in §8.

---

## 4. First run's two copy variants

One screen, asking one question — the feeding stage — with the copy branched on whether the record
store holds any records (`RUN-COPY-2`). It follows the consent gate (`RUN-CONSENT-1`), so consent has
already been given and explained by the time either variant is read.

### 4.1 New-user variant — the store holds no records

> ## Welcome
>
> One question before you start, and you can change the answer later.
>
> **How is your baby fed right now?**
>
> Your answer decides whose meals the diary records — yours, hers, or both.
>
> - **Breastfed** — the diary records **your** meals
> - **Mixed** — the diary records **your** meals and **hers**
> - **Solids** — the diary records **her** meals
>
> [Continue]

### 4.2 Returning-user variant — the store already holds records

> ## How is your baby fed right now?
>
> Your answer decides whose meals the diary records — yours, hers, or both. You can change it later in
> Settings.
>
> - **Breastfed** — the diary records **your** meals
> - **Mixed** — the diary records **your** meals and **hers**
> - **Solids** — the diary records **her** meals
>
> [Continue]

### 4.3 The degraded-account sentence

Shown in **addition** to either variant, in `noAccount` or `restricted` only (`RUN-ICLOUD-2`), never
in `temporarilyUnavailable` or `couldNotDetermine` (`RUN-ICLOUD-3`):

> You are not signed in to iCloud, so the diary cannot store entries yet — but your answer here is
> kept, and you will not be asked again.

### 4.4 The mapping

| Rule | How the copy satisfies it |
| --- | --- |
| `RUN-COPY-1` | Both variants state the question and what the answer governs — *"whose meals the diary records"* — and the three options spell the consequence out per stage rather than leaving her to infer it. Nothing about feeding practice, diet, elimination or a protocol appears. |
| `RUN-COPY-2` | Two variants. The new-user one **welcomes and introduces**; the returning one is the same question with the welcome removed and *"in Settings"* added, because a mother who has used the app for four months needs the route, not the introduction. |
| `RUN-COPY-3` | Neither variant says what the app will find, conclude, suggest or help her discover. Both use *"the diary records"* as the only verb for what the app does. The word *diary* is doing deliberate work — see below. |
| `RUN-PICK-1` | The three options in the fixed order `breastfed`, `mixed`, `solids`. |
| `RUN-PICK-2` | **Nothing in the copy marks any option as usual, recommended, current or default.** No *"most mothers"*, no *"if you are unsure"*, no parenthetical on `breastfed`. The three lines are deliberately parallel in shape so none reads as the expected answer. |
| `RUN-PICK-3` | *"[Continue]"* is inert until she picks. The copy does not promise otherwise — it says *"One question before you start"*, not "you can skip this". |
| `RUN-ICLOUD-1` | Both variants and the degraded sentence complete in every account state. The degraded sentence **warns**; it never says she must sign in first. |
| `RUN-ICLOUD-2`, `-5` | The sentence names the **consequence** — entries cannot be stored yet — not the technical account status, and it promises only what Apple's documentation supports: the answer persists **locally**. It does **not** say her answer will sync. |
| `RUN-ICLOUD-4` | No offer to fix the account, no simulated sign-in, no requirement to sign in. |
| `RUN-ABSENT-1`..`-3` | One question, no other question asked; no assessment, plan or expectation of what recording will achieve; no *"step 1 of 3"* and no dots. |

### 4.5 Two notes

**`RUN-COPY-2`'s known defect is not something copy can fix, and the copy is written to soften it.**
On the reinstall path the store is empty, the branch reads *new*, and a mother of four months gets
welcome copy (`first-run.md` Divergence 2 — KVS↔CloudKit ordering is undocumented, so the branch
cannot be made right). The new-user variant is therefore drafted to be **merely redundant** rather than
wrong when it lands on the wrong audience: *"Welcome"* and *"One question before you start"* are odd for
a returning mother but neither denies her records exist nor claims she is new to the app. Nothing that
would read as *apparent data loss* — no *"let's set up your diary"*, no *"you have no entries yet"* — is
in either variant.

**The word "diary" is load-bearing across all four texts.** It is what the PWA's own copy already
calls the product (*"Jednoduchý deník jídel a stavu kůže"*), it is `DECISIONS.md` entry 5's *"records;
never finds"* in one noun, and it is the working title (#697). Using it as the app's only
self-description is the cheapest available guard against `RUN-COPY-3` and `CONSENT-SAY-5`: a diary has
no opinions, so the sentence that would break the rule has nowhere to attach.

---

## 5. Controllership: the stated position

The ticket asked for a stated position on controllership, or copy true under either answer if
[#692](https://github.com/jirigrill/eczema-helper/issues/692) was still open.

**#692 is closed, and it closed without an answer.** The ÚOOÚ enquiry was **never sent** — it is on
the map under *Out of scope*, and the map's Art. 30 / DPIA fog item was amended to record that this
input *"will now never arrive"*. The three drafted enquiry documents are on `main` in the PWA repo
(`docs/research/uoou-enquiry-controllership-{cs,en}.md`, `-how-to-send.md`).

So the second branch of the ticket's instruction is the operative one, and it is **not** contingent
any more: the copy is drafted to be true under either reading, permanently, because no answer is
coming. This is the same posture `consent.md` §11 and #694 §5.7 take — both record the question as
`UNSETTLED` and state that no rule branches on it.

### 5.1 How the copy achieves it

By stating **facts about what happens to the data** and never a **characterisation of the developer's
role**. Three passages carry the load, each marked `<!-- controllership -->` in the text above:

| Passage | What it says | Why it survives either answer |
| --- | --- | --- |
| Notice §1 | *"`<DEVELOPER NAME>`, a private individual… not a company"* plus contact details | Art. 13(1)(a) identity and contact are required of a controller and are harmless if he is not one. Naming the person who made the app is true regardless. |
| Notice §4 | *"receives no copy… cannot read your diary, cannot recover it, cannot delete it on your behalf"* | A **factual** description of an app with no server. It is the practical consequence a mother needs either way, and it neither claims nor disclaims controllership. |
| Notice §7 | *"there is nothing he can access, correct, delete or send you on request"* | The rights are stated in full and are all exercisable **by her, in the app**. If he is a controller, the rights are discharged by the app's own controls; if he is not, the sentence is simply accurate. |

The consent screen needs no such care: it names the developer, the data, the two locations and the
purpose, and asks for permission. Nothing on it turns on who the controller is.

**What is deliberately absent from all four texts:** the words *controller*, *joint controller*, and
any sentence of the form *"we act as…"*. (*sub-processors* appears once, in notice §4, as the Art.
13(1)(e) category of recipient — glossed in place, and a statement about **Apple's** suppliers, not
about the developer's role.) `SET-PRIVACY-9` already forbids the app
characterising its own compliance; this extends the same discipline to the role itself, and it is the
one place where saying less is not a compromise but the accurate option.

### 5.2 If it is ever settled

Only the three marked passages need re-reading, and probably none needs changing — the **controller**
reading adds obligations discharged by controls the app already has (§6's two deletion routes, §7's
in-app rights), and the **non-controller** reading leaves every sentence still true. What *would*
change is the internal accountability file (#694 §5.7), which is not user-facing and not this
document's.

---

## 6. The consistency pass

The ticket's central requirement: the four texts describe the same processing at four lengths, so the
checks below run across all four rather than within one. Each is a check a reviewer can re-run.

**Check 1 — the eleven disclosures and the notice do not diverge.** Every Tier-1 fact appears in the
notice at greater length and **nowhere contradicted**. The pairs that could have drifted, and did not:

| Fact | Consent screen | Notice |
| --- | --- | --- |
| Purpose | *"keeps a diary… so you can look back"* | §3 *"keeping the diary, and nothing else"* |
| Data types | four bullets, photos named separately | §2, same four plus the setting and the consent record — a superset, not a different set |
| Health data about the child | stated in those words | §2 stated in those words, with the Art. 9 citation added |
| Storage | on this phone; copied to her iCloud; Apple named | §4, same three, with the private-database detail added |
| Outside the EEA | *"may keep that copy on servers outside Europe"*, risk stated | §4 *Outside Europe*, same claim, plus the contractual-safeguard and no-DPF facts |
| Withdrawal | deletes everything; nothing can be got out first | §7 last item, *"withdrawing it and deleting the diary are the same act"* |
| Adults | *"This app is for adults."* | §11, same claim |

**Check 2 — nothing anywhere claims the app derives, finds or suggests.** Verified mechanically over
the quoted copy only. *discover*, *identify*, *trigger*, *insight* and *recommend* appear **zero**
times. The five words that do appear are each inside a negation, which is the only form
`CONSENT-SAY-5` and `RUN-COPY-3` permit: *"does not **analyse** the records, does not look for
**patterns**… does not **score** anything and does not **suggest** anything"* (notice §3), and
*causing* twice, both denied — *"does not work out what is **causing**"* (consent screen) and *"tells
you nothing about what is **causing** her eczema"* (notice). There is no affirmative use of any of
them.

**Check 3 — the automated-decision statements do not contradict each other, and that asymmetry is
intentional.** The consent screen says **nothing** in either direction (`CONSENT-ABSENT-3`: para 64(v)
is conditioned on *"where relevant"*, and a *"no automated decisions"* line goes stale the moment the
insight engine ships). The notice **does** state it (§3, *"makes no automated decisions"*) because
Art. 13(2)(f) is not conditioned the same way and the notice is versioned — `SET-PRIVACY-6` means a
future revision restates it, and the consent record names the revision she read. Silence on the screen
plus a statement in a versioned notice is not a divergence; it is the layering para 72 authorises.

**Check 4 — only one of the four texts mentions encryption.** The consent screen must not
(`CONSENT-ABSENT-4`), the permission string has no reason to, first run has no reason to, and the
notice states it once, qualified (§9, values-not-structure). A reviewer adding *"and it's all
encrypted"* to the consent screen for reassurance would break `CONSENT-ABSENT-4` and would
simultaneously make the shortest text the one with the strongest claim.

**Check 5 — every text is true in a degraded iCloud state.** The consent screen reads **identically**
in every account state and says nothing about the account (`CONSENT-GATE-5`, `-6`) — its iCloud
sentences are about where records go, not about whether the account works today. First run adds one
sentence in `noAccount`/`restricted` and promises only local persistence. The notice describes the
iCloud copy in the present tense throughout, which is a description of how the app is built rather
than a claim about this phone this morning; §6's offline-deletion paragraph is the one place the
degraded case needed stating, and it states it.

**Check 6 — nothing says what uninstalling does.** `SET-PRIVACY-4` binds the notice as well as the
screen, and Apple documents the question in neither direction. Notice §6 gives the two deletion
routes and stops; §5's *"deleting the diary does not touch it"* is about a copy **she** placed in her
photo library, which is a different claim and a sourced one.

**Check 7 — the photo story is the same in all three places that tell it.** The consent screen names
photographs as their own data type; notice §5 describes the camera-roll route, that it is per-request,
and that copies there are outside the app's control; the permission string says the same in 45 words.
None of the three implies the app manages her library, and none omits that the route exists — a
consent screen that named photographs but not the camera-roll route would understate the concession,
which is why notice §5 exists rather than being folded into §4.

**Check 8 — one voice, four lengths.** *diary* throughout (never *tracker*, *log*, *journal* or
*app for eczema*); *your baby* / *her* (never *the patient*, *the subject* or *the child* in
user-facing text); *records* and *entries* (never *data points*); *you write* for her actions and
*the app stores* for its own. The word *controller* appears in none of the four texts; *sub-processors*
appears once, in notice §4, and is unavoidable — it names the category of recipient Art. 13(1)(e)
requires, and there is no plainer word for "the companies Apple in turn uses", which is why the notice
glosses it in the same sentence.

---

## 7. Before the first submission

What must happen to this copy before it ships, in the order it must happen.

1. **Owner sign-off** on all four texts. The eleven disclosures and the notice are legal
   representations by a named individual about a real person's data; an agent drafted them and cannot
   sign them.
2. **Fill the three placeholders** — `<DEVELOPER NAME>`, `<CONTACT EMAIL>`, `<NOTICE URL>`. The first
   two are a **sweep, not an edit**: the name appears **7 times** in the copy — twice on the consent
   screen, including the accept sentence, and five times in the notice (*In short*, §1, §4, §6, §7) —
   and the email **3 times**. `<NOTICE URL>` appears in **no** text a mother reads: it is a
   deployment value, set in App Store Connect and in whatever serves the page, which is step 3.
3. **Publish revision `v1` at `<NOTICE URL>`** and put that URL in App Store Connect. The URL is **not
   editable without a version submission** (`SET-PRIVACY-7`), and the served revision must never be
   older than the shipped one (`SET-PRIVACY-8`).
4. **Sweep the working title.** `Eczema Diary` is a placeholder due to be replaced before submission
   (#697). It appears in no text above — the copy says *"this app"* and *"the diary"* throughout,
   which is why the rename does not reach into any sentence a mother reads. Verified, not assumed.
5. **Declare the camera roll in the App Store privacy labels** (`skin-observation.md` §12.6). Named
   here because it is the third of the three load-bearing texts that section identified, and it is the
   one this document does not draft.

**A lawyer review is recommended and is not a gate this document imposes** (`SET-PRIVACY-12`). If it
happens it should be a **dated artifact**: #681 found that how a review is documented bears on whether
professional indemnity cover responds.

---

## 8. What this document does not contain

So an omission is not mistaken for a gap.

- **Any behavior rule.** Rules live in `docs/spec/`. This is the prose drafted against them, and where
  the two disagree the rule wins.
- **`NSCameraUsageDescription`.** A different key, not among the four texts, and unwritten. It needs
  the same treatment and is the obvious next piece of permission copy.
- **App Store listing copy** — name, subtitle, description, keywords, screenshots. Gated on
  submission, and still fog on the map. Note the listing's **adults statement** is a named open
  obligation (`consent.md` §10, #694 §6.6 item 9): `CONSENT-SAY-11` and notice §11 take the in-app
  half, and the listing half is unowned.
- **The App Store privacy labels' own content**, and **nutrition labels** / **trader status**.
- **Czech versions of anything.** `SET-PRIVACY-11`: one English text, no dialect split, no Czech.
- **The refusal screen's copy** (`CONSENT-NO-1`..`-8`) and **`SET-DELETE-*`'s confirmation copy**.
  Both are user-facing text this ticket did not name; they are the next drafting pass, and neither is
  legal-facing in the sense the four texts are. Flagged rather than silently drafted.
- **Whether the app announces a changed notice.** `SET-PRIVACY-14` / `RUN-CONSENT-4`, both **OPEN**,
  and it cannot bind the first release — which has no previous revision to have changed from. Notice
  §10 is drafted to be true today without prejudging it: it says the revision changes and that the
  shipped text is kept, and it does not promise a notification.
- **The legal analysis.** `docs/research/art-9-lawful-basis.md`, `art-13-notice-form.md`,
  `privacy-notice-hosting.md` and `settings-data-deletion.md` are the sources. This document is
  transcription against them and restates none of their reasoning.

---

_Drafted by an agent against primary-source research, for owner sign-off. **Not legal advice.**
Where a sentence above and a rule in `docs/spec/` disagree, the rule is right._
