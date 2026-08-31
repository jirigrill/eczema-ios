# Spec section template

How a behavior spec section is written, so every section reads the same way and Swift tests fall
out of it. Settled by [#682](https://github.com/jirigrill/eczema-helper/issues/682).

**The template is a worked example, not a form.** Read
[`skin-observation.md`](skin-observation.md) — it is the first section and demonstrates every rule
below. This file states the rules concisely; that file shows them working.

## One file per behavior area

`docs/spec/<area>.md`. Areas are the mother's screens and tasks, not modules: skin observation, day
view, first run and feeding stage, meal editor, settings, plus one for the persistence model.

No spine document, no cross-cutting index. Sections reference each other by link, and each is
readable alone — an agent should be able to build a screen from one file plus the invariants it
cites, without loading the rest.

## Front matter

Every section opens with:

1. **Status** — whether it is owner-confirmed, and what it was extracted from (repo, commit).
2. **Overview** — plain language, no rule ids, for someone who has never seen the product. Ends with
   the two or three things a reader must know before the rules make sense.
3. **How to read this document** — only in the template section; later sections link here.
4. **Invariant dispositions** — the table described below.
5. **Divergences** — a pointer to the inline marks and the index.

## Vocabulary

Every section opens its numbered content with a **§1 Vocabulary** table: the terms that section
uses, defined once, so no rule has to define a word mid-sentence.

Keep it to the terms the section **owns**. A term used by more than one section belongs in
[`GLOSSARY.md`](GLOSSARY.md), cited from the sections that use it — never copied into two tables,
which is how two definitions of one word start drifting apart. Where a shared term needs an
area-specific detail, the glossary states the question and the section states its own answer, as
*pending work* does.

## Rules

### Ids

`<AREA>-<GROUP>-<n>`, e.g. `SKIN-WIT-3`, `SKIN-PHOTO-12`.

Ids are **permanent identity, not position** — the same convention
[#689](https://github.com/jirigrill/eczema-helper/issues/689) established for `INV-n`. Assigned
once, never reused, never renumbered. A new rule appends the next unused number in its group and
need not be last, so inserting a rule cannot retarget a citation in a test name or a commit
message.

Groups are short and meaningful within the area (`ENTRY`, `REC`, `REG`, `LVL`, `WIT`, `VIS`,
`PHOTO`, `INT`, `SAVE`, `UNDO`, `DEL`, `VIEW` in the skin section). They exist so a reader can tell
from an id roughly what a rule is about.

### One rule, one claim

A rule states **one** testable thing, in one or two sentences, in the present tense, about the
app's observable behavior. If it needs "and" between two independent claims, it is two rules.

Rules describe **what the mother can observe**, not how it is implemented. "The record never holds
a subset" is a rule; "the save function maps over the region array" is not.

### Strength marks

Every rule carries exactly one:

| Mark | Meaning |
| --- | --- |
| **MUST** | Required. A Swift test asserts it. |
| **MUST NOT** | Prohibited. Prefer making it unrepresentable over testing it. |
| **SHOULD** | Strong default; departing needs a recorded reason. |
| **PWA** | Reference implementation only — does **not** carry to iOS. |
| **OPEN** | Genuinely undecided. Listed in the section's Open questions with its ticket. |

`PWA` and `OPEN` are the two marks that make this work honest. Without `PWA`, a reader cannot tell
description from requirement. Without `OPEN`, an implementer fills a gap with a guess and nobody
knows a decision was made.

**An implementer never silently resolves an `OPEN` rule.** That is a map ticket.

### Every section carries an `ABSENT` group

A section's rules say what the app does. Its `<AREA>-ABSENT-n` rules say what it **deliberately does
not**, as `MUST NOT`s with ids — *"prohibitions with ids, not features nobody built"*.

The group is not optional, and it is not the same as the section's scope list. A scope list answers
*which document owns this* and routes the reader elsewhere; an `ABSENT` rule answers *this was
considered and rejected, and adding it back is a change*. Two tests for membership, and a rule needs
only one:

- The reference implementation **has** it and the port drops it. It also gets a divergence row.
- A competent implementer would **add** it as an obvious improvement, unaware a decision was taken.

Absences earn ids for the same reason anything else does: without one, the prohibition never reaches
the verification table, so nothing guards it and the next contributor restores it in good faith. Where
one is worth a test, say so there — an absence check is usually one assertion and it is the cheapest
regression guard in the section.

### Prose between rules is allowed, and load-bearing

After a group of rules, a short paragraph may explain *why* — especially where a rule looks
arbitrary or inefficient and a future contributor would "fix" it. The activate-then-cycle rule
(`SKIN-INT-2`) costs an extra tap and exists because the screen is used one-handed while holding a
baby; without that sentence it reads like an oversight.

Keep it to a paragraph, and never put a requirement in it. If it constrains behavior, it is a rule
with an id.

## Invariants: cite, never restate

The numbered `INV-n` list in the frozen repo's `CONTEXT.md` is the single home for invariant text.
Cite as [`CONTEXT.md#inv-4`](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-4) —
the anchors are explicit HTML and resolve from this repo.

Citation alone is **not sufficient**, because four invariants are deliberately false for iOS
(INV-1 single-device, INV-2 no-backup, INV-9 unencrypted, INV-10 Dexie). A bare `INV-n` reference
would import a contradiction.

So every section carries an **invariant disposition table**: each invariant it touches, its leading
phrase, and its status here — *holds unchanged*, *holds with a named loss*, *void for iOS*, or
*enforcement moved*. [#691](https://github.com/jirigrill/eczema-helper/issues/691) already
classified all fourteen; cite that rather than re-deriving it.

The roughly fifteen **unnumbered** invariant-shaped rules in `CONTEXT.md` glossary prose are cited
**by heading**. Where one is ambiguous, the section resolves it and records the resolution as an
open question against the source — as `skin-observation.md` §12.1 does.

## Accessibility block

Every section carries a numbered **Accessibility** block, placed after the area's behavior rules and
**before** its *What this does not contain* list, its divergence index, and its verification section.
Settled by [#755](https://github.com/jirigrill/eczema-helper/issues/755).

**It takes a lettered section number**, e.g. `§9a` in a section whose behavior rules end at `§9`.
This is the same reasoning [#689](https://github.com/jirigrill/eczema-helper/issues/689) applied to
rule ids and `DAY-NAV-9a` applies within a group: a heading number is *position*, and sections cite
each other by `§n` heavily enough that renumbering the tail of seven files would silently retarget
those citations. A letter inserts the block where it belongs without moving anything after it.

It exists because accessibility is the one class of requirement that is **invisible in a screenshot
and absent from a test unless it is specified**. A section without this block yields a screen that
looks right and is unusable under VoiceOver, and neither the rules nor the verification table
fail — which is exactly what happened to the three most interactive sections before this block
existed.

**Requirements carry ids, in an `A11Y` group** — `<AREA>-A11Y-n`, with the same strength marks as
any other rule. That is the whole point of a block rather than a paragraph: an id can appear in the
verification table and take a *translate / re-derive / do not translate* verdict, and prose cannot.
A requirement written as prose is not verifiable and does not count as an answer here.

The block **must force an answer on all five** of the following. Where one does not apply, it says
so explicitly and says why — "this section has no animation, so there is nothing for Reduce Motion
to suppress" is an answer; silence is not.

| # | What the block must answer |
| --- | --- |
| 1 | **VoiceOver label and trait** for every interactive element the section specifies, and what each label reads. |
| 2 | **Dynamic Type** up to the largest accessibility sizes: what reflows, what may truncate, and what must **never** truncate. |
| 3 | **Colour alone**: whether any rule in the section conveys meaning by colour, and the second channel that carries it. |
| 4 | **Focus order and grouping** for composite rows — whether a row is one element to assistive technology or several, and in what order. |
| 5 | **Reduce Motion**, wherever a rule specifies an animation or a transition. |

**An accessibility label is a conveyance channel.** Anything a rule elsewhere forbids *displaying*
is equally forbidden in a label, a hint, a trait or an announcement — a prohibition written against
the visual surface alone has a hole in it, and this block is where it is closed. See
[`catalog.md`](catalog.md) `CAT-DERIVE-6`, which closes it for the allergen mapping.

**Not a design document, still.** The block specifies what must be *announced*, *readable* and
*reachable* — never type sizes, contrast ratios, or layout. Those belong to the iOS UI work, which
is not this spec's.

## Divergences

This is not a 1:1 port, and per [#690](https://github.com/jirigrill/eczema-helper/issues/690)
**coherence is presumed right**: where the PWA does two different things, the port picks the
coherent rule, and *keeping* a wart needs a named reason.

Each divergence appears **twice**:

1. **Inline**, as a block quote at the rule it affects, with three parts — *PWA:* what the
   reference does, *iOS:* what this app does, *Why:* the reason. Numbered within the section.
2. **In a divergence index** near the end: number, section, one-line summary, and a class
   (*defect fixed*, *forced by platform*, *settled by #nnn*, *deliberately given up*).

*Deliberately given up* is for a behaviour the reference **has** and the port drops on purpose —
distinct from *obsolete*, which is for one the port has no place for. A drop of that kind is the one
class of divergence a reader is most likely to mistake for an oversight, so it also earns a
`DECISIONS.md` entry when a competent implementer would otherwise re-add it.

**The twice rule has one exception**, and it is the *absences*. A row covering a whole rule group —
`SET-ABSENT-1`..`-7`, `MEAL-ABSENT-1`..`-6` — has no single rule to hang an inline block on, and
repeating one at each member would say the same thing six times. Those rows live in the index alone,
and their reasoning lives in the prose under each prohibition. Every row naming **one** rule carries
its inline block.

The index is what a reviewer reads to confirm the port did not drift by accident. It is also the
honest measure of the port: if a section has no divergences, either the area was coherent or
nobody looked.

## Verification section

Every section ends with two things before its open questions.

**Where each rule is verified today** — a table mapping rule groups to the existing TypeScript
tests, with an explicit *translate / re-derive / do not translate* verdict. Tests that assert a
platform guarantee iOS does not have (a storage transaction, say) must be marked **do not
translate**, or the port will inherit an assertion it cannot satisfy.

Then, separately and explicitly: **rules nothing verifies today**. This list is the most valuable
paragraph in a section, because it is where a port would otherwise assume test coverage equals
specification. Name them.

**Acceptance pass** — a numbered list of things to *do on a device*, in order, each mapped to the
rules it exercises. The owner cannot review Swift, so this list is what stands in for a code review
of the section. Write it as instructions to a person holding a phone, not as test names. Mark any
step that is expected to **fail on the PWA** — those are the divergences, and they are the steps
that prove the port did something.

## Open questions

Recorded rather than guessed, per the map's cite-or-don't-claim rule. Each gets a paragraph: what is
unknown, why it is not answerable here, what depends on it, and its ticket if it has one. Flag which
ones carry a **schema deadline** — additive-only promotion means a field never recorded cannot be
backfilled, so those are the only ones that cannot wait.

## Appendix: what the section does not contain

A short list, so a reader does not mistake an omission for a gap. Typically: platform types, layout
and visual design, invariant text, adjacent areas, and any stale reference that should not be
consulted.

**On the design prototype specifically:** `redesign-prototype.html` in the frozen repo is a
Czech-web artifact with three known-stale areas, and staleness is **per screen** — the skin screens,
for instance, are two-thirds parked protocol UI. A section that cites the prototype must say which
variant is live, or not cite it.

## What a section is not

- **Not a schema.** Field lists appear where they carry behavior (identity, immutability,
  absent-vs-empty). Types, migrations, and CloudKit configuration are the persistence section's.
- **Not a design document.** No layout, no colour, no component names.
- **Not a test file.** Rules are claims about behavior; a test is one way to check a claim. One rule
  may need several tests, and some are better served by making the wrong state unrepresentable.
- **Not a changelog.** Divergences are stated as the current rule plus why, not as a history of
  what was decided when. That history lives on the map's tickets.
