# Food catalog — behavior specification

**Status:** written, pending owner confirmation on the three questions §13 lists as answered here
rather than cited. Written against the format settled by
[#682](https://github.com/jirigrill/eczema-helper/issues/682) — see [`TEMPLATE.md`](TEMPLATE.md) for
the rules, and [`skin-observation.md`](skin-observation.md) for the worked example.
**Behavior reference:** `jirigrill/eczema-helper` @ `4ff1c8f` (frozen PWA),
`src/lib/data/allergen-catalog/allergen-catalog.ts`, `src/lib/strings/families.ts`,
`src/lib/strings/family-sources.ts`, `src/lib/domain/preparation-rules.ts`.
**Resolves:** [#734](https://github.com/jirigrill/eczema-helper/issues/734) on the transition map
[#672](https://github.com/jirigrill/eczema-helper/issues/672).

## Overview

The catalog is the list of foods the mother can log. It ships inside the app, she cannot add to it,
and it is the only source of food identity anywhere in the product — there is no free-text tier and
no "other" food ([#662](https://github.com/jirigrill/eczema-helper/issues/662)). When a food she ate
is missing, the fix is a new app version, not a text field.

It has three levels, and the middle one is invisible. **Families** are the thirteen tiles she sees
first (`Fruit`, `Grains`, `Dairy`…). **Foods** are the hundred and sixty concrete things she taps
inside a family (`yoghurt`, `orange`, `hummus`). Between them sit thirty-eight **allergens** — the
trigger units that say what a food contains. Nothing in the shipped app displays an allergen, and
nothing in the app being built will either; they exist as data, for an analysis that is not built
yet ([INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11)).

This document states what the catalog *is* and what may be done with it, in English, without
reference to Swift, SwiftData, Svelte or the Czech interface. It does not state how the food picker
looks — that is the meal editor's (§2.4, and the answer to #734's first question).

Five things are worth knowing before the rules make sense:

1. **`allergenIds` means composition, not legal declarability.** It records what a food is
   *characteristically made of*, so the app can later correlate a food with the skin. It is **not** a
   regulatory allergen declaration, does not follow EU Annex II or FDA labelling, and must never be
   presented as one ([#702](https://github.com/jirigrill/eczema-helper/issues/702)). The type is
   still spelled *allergen*, which is why this is stated first and as a rule (`CAT-MEAN-1`): a reader
   who infers the regulatory meaning from the name gets the product wrong, as
   [#678](https://github.com/jirigrill/eczema-helper/issues/678) §2.3 did.
2. **It is bundled data, not stored data.** The catalog lives in the app binary and never enters the
   SwiftData store ([#686](https://github.com/jirigrill/eczema-helper/issues/686), owned by
   [`persistence-model.md`](persistence-model.md) `DATA-SCOPE-2`/`-3`). A logged meal keeps a
   `foodId` and resolves everything else at render, live, every time.
3. **A food's triggers are learned, not frozen.** Because resolution is live, correcting a food's
   `allergenIds` in a later version retroactively enriches every past meal of that food. That is the
   point, not a side effect — it is how a trigger eaten unknowingly becomes visible.
4. **The mapping ships populated and undisplayed.** So the largest group of rules here (§4) governs
   data nothing renders, and §7 states the prohibition on rendering it as a blanket `MUST NOT`
   rather than leaving it to the absence of a screen.
5. **Ids are the schema deadline.** A food's id is its en-GB name, kebab-cased, and it is persisted
   on every meal item. Everything else in the catalog can be revised in any later version; an id
   cannot, because additive-only promotion means a renamed id orphans records already written.

**How to read this document:** see
[`skin-observation.md` § How to read this document](skin-observation.md#how-to-read-this-document).
Rule ids here are `CAT-<group>-<n>`, permanent identity, never renumbered or reused.

### Invariant dispositions

Invariants are cited, never restated. [#691](https://github.com/jirigrill/eczema-helper/issues/691)
classified all fourteen; the ones this section touches carry their disposition here so a bare
citation cannot import a contradiction.

| Ref | Leading phrase | Disposition here |
| --- | --- | --- |
| [INV-1](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-1) | _Single device, no sync_ | **Void for iOS.** Sync is mandatory ([#705](https://github.com/jirigrill/eczema-helper/issues/705)). Bears on the catalog only through skew: the bundle version is per-device, so two devices on one account can hold different catalogs — `CAT-VER-3`. |
| [INV-2](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-2) | _No backup mechanism exists_ | **Void for iOS.** Sync carries durability ([#683](https://github.com/jirigrill/eczema-helper/issues/683)). Still load-bearing as *reasoning*: it is why an id rename would have been unrecoverable in the PWA, which is what forced the tolerant-read policy (§6). |
| [INV-5](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-5) | _Causation is derived, never recorded_ | **Holds unchanged**, and governs §7. An `allergenIds` entry is an input to a derivation nobody has built; displaying it as a finding about her baby would record causation in the copy. |
| [INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11) | _The app is a Logging Tool_ | **Holds**, and is the governing invariant of this section. All of §7. |
| [INV-12](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-12) | _Records carry types, not display strings_ | **Holds, and is the reason §5 exists.** The catalog is the type side of this split; every name is a label resolved at render. The PWA's `MealItem.name` violation ([#677](https://github.com/jirigrill/eczema-helper/issues/677)) must not be inherited — `persistence-model.md` `DATA-ABSENT-3` forbids it on the record, `CAT-LOC-2` forbids it here. |
| [INV-13](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-13) | _Food catalog is data-first and bundled_ | **Holds with two named losses.** Bundled, derived ids, and runtime-immutable all carry (`CAT-SHAPE-1`, `CAT-VER-1`). Two clauses do not: "one curated `CanonicalAllergen` record" describes the pre-three-level shape the same invariant's own glossary entry supersedes, and the dormant `protocol`/`ladder` fields **do not travel** (`CAT-ABSENT-1`, Divergence 6). |

`CONTEXT.md` also holds invariant-shaped rules **unnumbered**, in glossary prose. Six bear on this
section and are the most portable material in the whole port — they decide catalog membership and are
market-independent. All six are cited by heading, under
§ _Glossary_ → _Family / Allergen / Food — the three-level catalog_, and **never restated**:

| Principle, by its leading phrase | What it decides | Cited at |
| --- | --- | --- |
| _a food's family is presentation; its allergen is domain_ | That `familyId` and `allergenIds` are assigned independently and may diverge. | `CAT-SHAPE-4`, `CAT-MEAN-3` |
| _food-source subgroup is a second presentation axis_ | That `sourceGroup` exists, is family-scoped, and never enters the trigger path. | §3, `CAT-SRC-1` |
| _what qualifies as a Food: atomic consumption and fixed composition_ | Membership: why a dish is never a catalog food. | `CAT-MEMBER-1`, `-2` |
| _food allergen-curation is precision-biased_ | That `allergenIds` holds characteristic ingredients only, never traces. | `CAT-MEAN-4`, `-5` |
| _food granularity is earned, not exhaustive_ | When a product earns its own tile. | `CAT-MEMBER-4` |
| _the catalog is the whole set of loggable foods_ | That there is no free-text tier and no unknown-food identity. | `CAT-MEMBER-6` |

A seventh principle, _the questionnaire selects allergens; the meal log selects foods_, is **void for
iOS**: the questionnaire is parked with the protocol engine, so the allergen level has no selecting
surface at all. That is what makes §7's prohibition cheap to hold and Divergence 2 possible.
### Divergences from the PWA

This is not a 1:1 port. Per [#690](https://github.com/jirigrill/eczema-helper/issues/690),
**coherence is presumed right**: where the reference implementation does two different things, the
port takes the coherent rule, and *keeping* a wart needs a named reason. There are **nine**, marked
inline and indexed in §11. Four of them delete fields or code paths that exist in the shipped PWA
and are read by nothing.

---
## 1. Vocabulary

| Term | Meaning |
| --- | --- |
| **Catalog** | The whole bundled dataset: families, allergens, foods, and the label tables that name them. |
| **Family** | One of thirteen top-level buckets. Presentation only — it decides where a food is looked for, never what it triggers. |
| **Allergen** | A trigger unit. What a food is characteristically made of, in this app's sense only (`CAT-MEAN-1`). |
| **Food** | One concrete loggable thing. The only level a meal ever records. |
| **Trigger set** | A food's `allergenIds` — zero, one, or several. Resolved live from the catalog, never stored on a meal. |
| **Source group** | An optional second presentation axis clustering foods inside one family (`cow`, `plant`). Family-scoped: a key means nothing outside its family. |
| **Label table** | The per-locale mapping from a catalog id to the text shown for it. Ships beside the catalog, never inside it. |
| **Catalog version** | The app version a given bundled catalog shipped in. Not a field — the app's own version stands in for it (`CAT-VER-2`). |
| **Retired id** | An id whose food has been withdrawn from the catalog but which remains reserved forever (`CAT-VER-5`). |
| **Representative food** | A food that expresses an allergen, so the allergen is reachable by logging something. |

One term this section uses is shared and defined in [`GLOSSARY.md`](GLOSSARY.md): **feeding stage**,
which the catalog does not read but which gates who may log a meal at all. *Trigger set* and
*representative food* are this section's own — no other area reads them.

---

## 2. The three levels

### 2.1 What the catalog contains

**`CAT-SHAPE-1` (MUST)** — The catalog ships inside the app bundle and nothing at runtime adds to it,
removes from it, or edits it.

**`CAT-SHAPE-2` (MUST)** — It has exactly three levels: families, allergens, and foods. A family
contains allergens and foods; an allergen belongs to exactly one family; a food belongs to exactly one
family and carries a set of allergen ids.

**`CAT-SHAPE-3` (MUST)** — Every id in every level is a slug — a lowercase, kebab-cased, stable
string — not a UUID. UUIDs identify the mother's records; slugs identify bundled data
([#677](https://github.com/jirigrill/eczema-helper/issues/677)).

**`CAT-SHAPE-4` (MUST)** — A food's family and its allergen ids are assigned independently, and the
two may disagree. A food's trigger set resolves **only** through its allergen ids; its family is
absent from the trigger path.

**`CAT-SHAPE-5` (MUST NOT)** — No level carries a display string in any language. Names live in the
label tables (§5).

**`CAT-SHAPE-6` (MUST NOT)** — A food never carries a `protocol`, a ladder, an allergenicity grade, or
a provenance field. §10 states these absences with ids.

`CAT-SHAPE-4` is the rule a reader is most likely to "fix". Soy milk sits in the **dairy** family —
where a mother looks for a milk substitute — while its trigger is **soy**, whose own family is
legumes. Grouping by trigger instead would scatter the plant milks away from the shelf she is
mentally standing at. The reference catalog has five plant milks under dairy for exactly this reason.
See the principle _a food's family is presentation; its allergen is domain_.

### 2.2 The counts, and what they are not

**`CAT-SHAPE-7` (MUST)** — The port ships the reference catalog's full extent: **13** families, **38**
allergens, **160** foods. No family, allergen, or food is dropped in translation.

The numbers are stated as a rule because they are the one cheap check that a translation pass did not
quietly lose rows, and because a wrong figure has already circulated —
[#702](https://github.com/jirigrill/eczema-helper/issues/702) had to correct an earlier count of 198.
They are a **floor on the port**, not a cap on the product: `CAT-MEMBER-5` requires the two dialects to
add foods, so the shipped English catalog is expected to exceed 160.

### 2.3 What a food may be

**`CAT-MEMBER-1` (MUST)** — A food is a thing eaten as one indivisible unit *and* whose allergen set
does not vary between instances. Both tests hold, per the principle _what qualifies as a Food_.

**`CAT-MEMBER-2` (MUST NOT)** — A multi-ingredient dish assembled at eating time is never a catalog
food, however it is eaten. A stew, a pizza, a soup, a sandwich fail the fixed-composition test, so no
honest trigger set exists for them.

**`CAT-MEMBER-3` (MUST)** — A dish is logged by decomposing it into its component foods. The meal is
the composition; the food is not.

**`CAT-MEMBER-4` (MUST)** — A product earns its own food only when it differs from a sibling in its
allergen ids *or* in its likely reaction signal. Cosmetic variants of the same substance and
processing class share one canonical food, per the principle _food granularity is earned_.

**`CAT-MEMBER-5` (MUST)** — Where a dialect's market has a food the other does not, the food is added
to the catalog for both and simply named in each locale's table. Foods are catalog-wide; only labels
are per-locale.

**`CAT-MEMBER-6` (MUST NOT)** — There is no free-text food entry and no unknown-food identity. Every
`foodId` a meal holds is a catalog id.

**`CAT-MEMBER-7` (SHOULD)** — Every allergen has at least one representative food, so a trigger is
reachable by logging something concrete. §12 records that the reference catalog breaks this six times.

> **Divergence 1 — the missing-food escape hatch stays missing, and that is a decision.**
> **PWA:** the catalog is the whole set of loggable foods; free text and the `other:*` id arm were
> removed by [#662](https://github.com/jirigrill/eczema-helper/issues/662).
> **iOS:** unchanged — no free text, no unknown food.
> **Why:** listed as a divergence not because behavior changes but because it is the single most
> likely thing for an implementer to add back as a kindness. A record that asserts nothing cannot be
> reasoned about, splits one real food across many spellings, and moves the cost of a gap from the
> catalog to the analysis. The cost is accepted and named: a food outside the catalog **cannot be
> logged at all**, and the fix is a new app version.

### 2.4 What this section does not own

**`CAT-SHAPE-8` (MUST)** — The catalog defines what may be logged. How the food picker looks — the
family grid, the drill-in, tile order, grouping, sort — belongs to the meal editor.

This answers the first question [#734](https://github.com/jirigrill/eczema-helper/issues/734) put to
this section. `day-view.md` set the precedent that a screen owns its own rendering rules, and the
reference implementation agrees: `FamilyGrid.svelte` and `FamilyDrillIn.svelte` have exactly one
consumer between them, `src/routes/meal/+page.svelte`. The second consumer that once justified
treating the grid as shared — the onboarding questionnaire — is parked with the protocol engine.

The split is not clean, though, and §3 states where it falls: the *trigger* for grouping is a fact
about catalog data, so this section owns it, while the rendering it triggers is the meal editor's.

---

## 3. The source axis

**`CAT-SRC-1` (MUST)** — A food may carry one optional source group. It is presentation only: like
family, it never enters the trigger path.

**`CAT-SRC-2` (MUST)** — Source-group keys are scoped to one family. The same key in two families is
two unrelated keys, and a key means nothing outside its family.

**`CAT-SRC-3` (MUST)** — A family's source groups are an **ordered** list, and that order is
editorial, not alphabetical — the group most reached for in everyday use comes first.

**`CAT-SRC-4` (MUST)** — A family is presented grouped only when it has **at least five** foods *and*
an authored source structure. Otherwise it is presented flat. Grouping is a progressive enhancement.

**`CAT-SRC-5` (MUST)** — A food with no source group, or one whose key its family does not author,
falls into a single trailing catch-all group rendered last.

**`CAT-SRC-6` (MUST NOT)** — The catch-all group carries no safety claim, no "unclassified" meaning,
and no visual treatment implying either. It is a presentation bucket; danger stays per-food.

**`CAT-SRC-7` (MUST)** — Source-group keys are en-GB slugs, on the same rule as every other id
(`CAT-SHAPE-3`).

**`CAT-SRC-8` (MUST NOT)** — A source group is never empty. A key with no foods in it is not
authored.

`CAT-SRC-7` is the answer to #734's second question — **what `sourceGroup` becomes**. It survives,
because the axis is the one the mother actually thinks in: she looks for a milk substitute under
*plant*, not under *nuts*. But it survives **renamed and closed**. #677 found the field bilingual
within itself: of 25 distinct keys, 15 are Czech (`bobuloviny`, `korenova`, `plody-more`) and 10 are
English (`cow`, `plant`, `gluten-free`), with 39 of 160 foods carrying none. Half-translated keys in
a field that never renders are pure latent confusion, so the port normalises all of them to en-GB
and adds `CAT-SRC-8` and the audit in `CAT-LOC-7` to keep them closed.

> **Divergence 8 — source-group keys are normalised to en-GB.**
> **PWA:** the 25 authored keys are 15 Czech (`bobuloviny`, `korenova`, `plody-more`, `hlizova`) and
> 10 English (`cow`, `plant`, `gluten`, `gluten-free`), mixed inside one field on one record type.
> **iOS:** every key is an en-GB slug, on the same rule as every other id (`CAT-SHAPE-3`).
> **Why:** the field is never rendered, so the bilingualism was invisible and cost nothing to leave —
> which is exactly why it survived. It becomes a real cost the moment anyone reads the data: a curator
> cannot tell whether `plodova` and `plant` follow different conventions or the same one applied
> inconsistently. Settled by [#677](https://github.com/jirigrill/eczema-helper/issues/677), which
> found the field bilingual within itself.

Measured against the reference catalog, the rules above produce eight grouped families (`dairy`,
`grains`, `fruit`, `vegetables`, `nuts-seeds`, `fish-seafood`, `fats-oils`, `sweet`) and five flat
ones (`meat`, `eggs`, `legumes`, `spices-condiments`, `drinks`). Two of the flat five are flat only
for want of authoring: `spices-condiments` has ten foods and `drinks` eight, both over the threshold,
but neither has an authored structure — so `CAT-SRC-4`'s *and* is doing real work, and a later
version can group them without changing a rule.

> **Divergence 9 — the eliminated-group sort is deleted.**
> **PWA:** `family-sources.ts:18-22` documents that a source group whose every food carries an
> eliminated allergen sinks below the non-eliminated groups, so a mother on an active protocol
> scrolls less.
> **iOS:** no such sort. Source groups render in authored order, always.
> **Why:** the documented behavior **does not exist in the shipped code** — `FamilyDrillIn.svelte`
> sorts by authored order and nothing else. It went out with the protocol descaling
> ([INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11)) and the comment
> outlived it. Recorded as a divergence rather than silently dropped because a reader consulting the
> reference's own documentation would otherwise implement it, and it needs an elimination state that
> the app being built does not have.

---
## 4. What `allergenIds` means

**`CAT-MEAN-1` (MUST)** — A food's allergen ids record what it is **characteristically made of**, for
the purpose of correlating a food with the skin later. They are not, and must never be presented as, a
regulatory allergen declaration.

**`CAT-MEAN-2` (MUST NOT)** — The catalog does not follow, claim to follow, or imply any labelling
regime — not EU Annex II, not FDA major-allergen labelling, not any national scheme. It is not
derived from one and is not audited against one.

**`CAT-MEAN-3` (MUST)** — An allergen belongs to exactly one family, its clinical home, and that
family is independent of the families of the foods expressing it.

**`CAT-MEAN-4` (MUST)** — Allergen ids hold the characteristic ingredients of the standard product
only. Trace cross-contamination, optional emulsifiers, and brand-variable add-ins are excluded, per
the principle _food allergen-curation is precision-biased_.

**`CAT-MEAN-5` (MUST)** — A reliably-present second characteristic ingredient makes a **separate
named food**, never a widened trigger set on the plain one.

**`CAT-MEAN-6` (MUST)** — A food's trigger set may legitimately be **empty**. An empty set means "no
characteristic trigger we are sure of", which is a curated assertion, not missing data.

**`CAT-MEAN-7` (MUST)** — The food-to-allergen relation is many-to-many in both directions: one
allergen is expressed by many foods, one food may carry several allergens.

`CAT-MEAN-1` is the section's most important rule and the reason the overview leads with it. The type
is still spelled *allergen* — [#702](https://github.com/jirigrill/eczema-helper/issues/702) decided
against renaming it — so nothing in the code says which meaning is intended, and a reader who supplies
the regulatory one gets a different product: one that is wrong about `oat milk`, that owes a
completeness duty it cannot discharge, and that carries product-liability exposure this app has no
basis for. #678 §2.3 made precisely that inference. The rule exists so the next reader cannot.

`CAT-MEAN-4` and `CAT-MEAN-6` are the same policy seen from two sides, and `oat milk` is the worked
example: oats are intrinsically gluten-free, so its trigger set is **empty** even though some brands
cross-contaminate. Over-tagging it would turn the safe option red on the one screen where a mother
reaches for a substitute *specifically to avoid dairy*, and would train her to ignore warnings. Alarm
fatigue is worse for diagnosis than a rare missed trace. Fifty-seven of the reference catalog's 160
foods carry an empty set — over a third — so an implementer who treats empty as "not yet curated" will
misread a third of the data.

The recall path is what makes the precision bias safe: because triggers resolve live (§6), a genuinely
missed *characteristic* ingredient added in a later version retroactively enriches every past meal of
that food. Traces do not qualify for this; characteristic ingredients do.

**`CAT-MEAN-8` (MUST)** — The 38 allergen records ship as curated, including the ones whose grading is
known to be imperfect. `honey` keeps its `moderate` grading.

That grading is inert — nothing reads it, and §10 deletes the field that holds it — so
[#702](https://github.com/jirigrill/eczema-helper/issues/702) settled it as carried rather than
corrected. It is stated as a rule so that a future curator who finds it does not read the inconsistency
as a bug to fix under time pressure, and so that fixing it is a deliberate curation act with the
owner's sign-off (§8) rather than a drive-by edit.

---

## 5. Names, and the three localizations

**`CAT-LOC-1` (MUST)** — The app ships three localizations: `en`, `en-GB`, and `en-US`. Bare `en`
carries en-GB content.

**`CAT-LOC-2` (MUST NOT)** — No name in any language is ever stored on a record or held in the catalog
data. A name is resolved from the label table for the active locale, at render, every time.

**`CAT-LOC-3` (MUST)** — Labels diverge between dialects; **ids and allergen mappings do not**. There
is exactly one catalog and one trigger mapping, named differently in two dialects.

**`CAT-LOC-4` (MUST)** — Bare `en` exists because there is **no documented fallback** from
`en-AU`, `en-CA`, `en-IE`, `en-IN`, or `en-NZ` to a sibling dialect. Without it, an Australian device
gets the development-language table by accident rather than by decision.

**`CAT-LOC-5` (MUST)** — A food's id is its **en-GB name, kebab-cased**. This is the id-form rule, and
it is the catalog's only schema-deadlined value.

**`CAT-LOC-6` (MUST NOT)** — An id is never re-derived from a label. Once assigned, an id is fixed even
when its en-GB label later changes, so `aubergine` stays `aubergine` if the label is ever reworded.

**`CAT-LOC-7` (MUST)** — Every label table is audited for completeness against the catalog's ids, and a
missing label fails the build.

`CAT-LOC-5` is where this section meets the schema deadline that `persistence-model.md` owns. That
section's `DATA-SCOPE-6` fixes a stored `foodId` as never rewritten; this rule fixes what the id *is*.
Neither is usable alone, and together they mean a rename is not a refactor — it orphans records already
written, unrecoverably, because promotion is additive-only. The pair is why ids are en-GB even though
en-US is the larger market: one dialect had to win, and a coin was already flipped in #702.

`CAT-LOC-7` is not housekeeping. Swift has no `satisfies` equivalent, so an incomplete label table
draws **no compile-time diagnostic** — and measurement on Swift 6.4 confirmed `xcstringstool` does
**not** backfill an entry present in `en` but missing from `en-US`. Since `CAT-MEMBER-5` positively
expects the dialects to add foods (`marmite`, `grits`), one-sided coverage is a predicted authoring
slip, not a hypothetical. The reference implementation catches this class of error with
`satisfies Record<CatalogFoodId, …>` at compile time; the port must replace that guarantee with a CI
audit over an exhaustive id list, or lose it silently.

That audit is also this section's answer to the second blank-label route
[#749](https://github.com/jirigrill/eczema-helper/issues/749) raises. A food present in the catalog but
missing from one dialect's table is **prevented upstream** by `CAT-LOC-7`, and therefore has no display
rule here. It is not the same failure as an unresolvable id (§6): the catalog contains the food, so
nothing is hidden and no meal degrades — the build simply does not ship.

> **Divergence 3 — `aliases` is deleted.**
> **PWA:** every allergen and 89 foods carry an `aliases` array of Czech and English search synonyms
> (`aliases: ['celé vejce']`, `['coffee', 'tea', 'káva', 'čaj']`).
> **iOS:** the field does not exist.
> **Why:** nothing reads it. There is no food search anywhere in the shipped app — the meal page has no
> text input at all, by design ([#662](https://github.com/jirigrill/eczema-helper/issues/662)) — so the
> array is authored, maintained, and dead. Half its entries are Czech, so porting it would mean
> translating synonyms for a search that does not exist. If search is built later, aliases are
> re-authored against that feature's needs; carrying a bilingual dead field forward to save that work
> is a false economy, since the Czech half would be discarded anyway.

---
## 6. Versions, and what happens when an id does not resolve

**`CAT-VER-1` (MUST)** — The catalog is revised only by shipping a new app version. There is no
download, no remote fetch, no seeding, and no reconciliation on launch.

**`CAT-VER-2` (MUST NOT)** — The catalog carries no version field of its own. The app's version is the
catalog's version, because the two are the same artifact.

**`CAT-VER-3` (MUST)** — Two devices on one iCloud account may hold different catalog versions, and a
record written by the newer may name a food the older does not contain.

**`CAT-VER-4` (MUST)** — A food's trigger set is resolved live from the bundled catalog every time it
is needed, and is **never** snapshotted onto a meal.

**`CAT-VER-5` (MUST)** — A withdrawn food's id is **retired in place**: reserved forever, never reused
for a different food.

**`CAT-VER-6` (MUST NOT)** — An id is never recycled, and a retired id is never reassigned to a food
that merely resembles the withdrawn one.

**`CAT-VER-7` (SHOULD)** — Prefer withdrawing a food by removing it from the catalog over redefining
what an existing id means. A redefinition rewrites history silently; a withdrawal is visible.

`CAT-VER-3` is the whole reason a tolerant-read policy exists, and it is a consequence of sync
([#705](https://github.com/jirigrill/eczema-helper/issues/705)) rather than of curation. Under
[INV-1](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-1) the catalog and the
records were always the same vintage, so an unresolvable id could only come from a rename — which
[INV-2](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-2) made unrecoverable, and
which the reference implementation therefore treats as a crash: `working-meal.ts:337-343` **throws**
`food ${id} is not in the catalog` on rehydration. With mandatory sync and per-device bundles, skew is
ordinary — an older phone that has not updated yet — so throwing would mean a meal she logged on her
new phone crashes the editor on her old one.

`CAT-VER-4` is what makes the retroactive-enrichment promise real, and `CAT-VER-5`/`-6` are what keep
it honest. Live resolution means an id is a *permanent question* asked of whatever catalog is
installed — so reusing an id for a different food would silently rewrite what a past meal claims she
ate. Retirement-in-place costs nothing but a comment.

### 6.1 The unresolvable id, and where its rules live

**`CAT-VER-8` (MUST)** — A `foodId` the bundled catalog does not contain is a **recoverable display
condition**, never an error, a crash, or a reason to drop data.

**`CAT-VER-9` (MUST NOT)** — The catalog layer never deletes, rewrites, or "repairs" a record holding
an unresolvable id. The id stays on disk untouched, and the food reappears in full when the app
updates.

What the *screens* do with such an item — hide the item, degrade its meal to read-only, and render an
all-unresolvable meal as an occupied row with no food names — is settled by
[#703](https://github.com/jirigrill/eczema-helper/issues/703) and belongs to the day view and the meal
editor, not here. It is tracked at [#749](https://github.com/jirigrill/eczema-helper/issues/749). This
section states only the half that is a fact about the catalog: the condition is expected, and the data
survives it.

The two halves must not be separated, and #703 is explicit that hiding and read-only are safe **only as
a pair**. Read-only is what makes hiding non-destructive: no save path can overwrite the meal while an
item is invisible, so hiding is a display loss with a self-healing end state rather than data loss.
`CAT-VER-9` is this section's contribution to that pairing — it forbids the catalog layer from being
the thing that turns a display condition into a deletion.

> **Divergence 4 — an unknown id degrades instead of throwing.**
> **PWA:** `working-meal.ts:337-343` throws on rehydrating a meal whose `foodId` is not in the catalog.
> **iOS:** the id is a recoverable display condition (`CAT-VER-8`); nothing throws and nothing is
> dropped.
> **Why:** the PWA's choice is correct *for the PWA* — with one device and no backup, silently shrinking
> a meal she logged is worse than failing to open it. Both premises are void for iOS
> ([#705](https://github.com/jirigrill/eczema-helper/issues/705),
> [#683](https://github.com/jirigrill/eczema-helper/issues/683)), and version skew between two of her
> own devices is now an ordinary state rather than a corruption. Settled by
> [#703](https://github.com/jirigrill/eczema-helper/issues/703).

Worth knowing while implementing this: the reference *does* contain a tolerant path, and it is pointed
at the wrong source. `FamilyDrillIn.svelte:93-95` falls back to rendering the raw id as a label — but it
iterates the catalog, so the fallback is unreachable. The lenient renderer and the strict rehydrator are
deliberately coupled (`preparation-rules.ts:16-19` documents it: the renderers may be lenient *because*
rehydration is strict). Port both halves or neither.

---

## 7. Nothing displays a trigger

**`CAT-DERIVE-1` (MUST NOT)** — No screen displays a food's allergen ids, an allergen's name, or
anything derived from either. Not a chip, not a badge, not a colour, not a count, not a warning, not a
sort order the mother can perceive.

**`CAT-DERIVE-2` (MUST NOT)** — No copy anywhere frames a food, an allergen, or a mapping as evidence
about her baby — no "may be causing", no "likely trigger", no "contains an allergen you flagged".

**`CAT-DERIVE-3` (MUST NOT)** — No screen tells her a food is safe, risky, eliminated, allowed, or
recommended. The app has no such concepts.

**`CAT-DERIVE-4` (MUST)** — The allergen level exists as data only, for an analysis that is not built.
It ships fully populated and entirely unrendered.

> **Divergence 2 — the allergen level ships populated and entirely unrendered.**
> **PWA:** the onboarding questionnaire rendered allergens directly — the mother drilled into a family
> and picked an allergen, and `motherAllergies` / `babyConfirmedAllergies` / `testedAllergens` were all
> allergen ids.
> **iOS:** no surface renders an allergen, and none is planned for v1 (`CAT-DERIVE-1`).
> **Why:** the questionnaire is parked with the protocol engine
> ([INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11)), so the middle
> level of a three-level catalog arrives with no selecting surface at all. This is the divergence that
> makes the whole section's shape odd — §4 is the largest rule group and governs data nothing displays
> — and stating it as a divergence is what stops a reader concluding the mapping is vestigial. It is
> the input to the analysis [#468](https://github.com/jirigrill/eczema-helper/issues/468) will build,
> and it must be correct now because it cannot be backfilled onto meals already logged.

This is the same blanket shape `day-view.md` `DAY-DERIVE-1` uses, and for the same reason: stated as a
prohibition with an id rather than left to the absence of a screen, because the absence of a screen is
not a rule and the next contributor cannot cite it. The allergen data is *right there*, correct, and
the single most natural feature to add — which is exactly why it needs a `MUST NOT` in front of it.

Two invariants converge here.
[INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11) makes the app a
logging tool that derives nothing and instructs nothing;
[INV-5](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-5) makes causation derived
and never recorded. A trigger chip on a food tile would breach both — it would present a curation
judgment as a finding about her child, in an app with no analysis behind it and no clinician in the
loop. `skin-observation.md` `SKIN-INT-14` already forbids this framing wherever a record is displayed;
this rule forbids it at the source.

**`CAT-DERIVE-5` (MUST NOT)** — No user-facing string caveats, hedges, or explains a mapping in v1 —
no "based on typical ingredients", no disclaimer sheet.

**`CAT-DERIVE-6` (MUST NOT)** — No accessibility label, hint, trait, value, or announcement conveys a
food's allergen ids, an allergen's name, or anything derived from either. `CAT-DERIVE-1` reads
"displays"; this rule says that the assistive-technology surface is a display. A VoiceOver label of
"oat milk, contains wheat" breaches §7 exactly as a visible chip would, and is harder to notice
because no screenshot shows it.

That may read as the wrong instinct, so the reasoning is worth stating: a caveat is only honest if
there is a claim to caveat, and v1 makes no claim, because nothing renders. Shipping a disclaimer for
an invisible mapping would *create* the impression that the app asserts something about her baby's
triggers — the exact impression `CAT-DERIVE-2` exists to prevent. The caveat becomes required the
moment a mapping first reaches a screen, and that is the trigger condition
[#702](https://github.com/jirigrill/eczema-helper/issues/702) recorded: the first feature to display a
trigger owes the copy, the review, and quite possibly a lawyer.

> **Divergence 5 — the allergen-label tables are deleted, not ported.**
> **PWA:** `src/lib/strings/categories.ts` authors Czech names for all 38 allergens and their
> subitems, exhaustiveness-tested against the catalog.
> **iOS:** no allergen label table ships. Allergen ids have no names in any locale.
> **Why:** the tables are **entirely unreachable** in the shipped PWA — their only consumer is
> `getCategoryConfig`, which has zero callers, because the surface that displayed allergen names was
> the questionnaire and it is parked. Porting them would mean authoring 38 names twice (en-GB and
> en-US) for text that `CAT-DERIVE-1` forbids rendering, and every one would be a
> [#702](https://github.com/jirigrill/eczema-helper/issues/702) sign-off item. The mapping ships; its
> vocabulary does not. Whatever feature first needs to *name* an allergen authors the table then, with
> the copy review that feature owes anyway.

---
## 8. Curation and sign-off

**`CAT-SIGN-1` (MUST)** — The owner reviews the catalog before release. The review is of the catalog
source itself, in English, not of a generated report.

**`CAT-SIGN-2` (MUST)** — Provenance for a curation decision lives in **comments beside the data**, not
in a field on the record.

**`CAT-SIGN-3` (MUST NOT)** — No provenance, source, citation, confidence, or review-status field
exists on any catalog record.

**`CAT-SIGN-4` (MUST)** — The **git commit is the record** of a curation act: what changed, when, and
why. There is no separate curation log, changelog, or review database.

**`CAT-SIGN-5` (MUST)** — A change to any food's allergen ids is a curation act requiring the owner's
sign-off, because live resolution (`CAT-VER-4`) makes it retroactive across her whole history.

**`CAT-SIGN-6` (SHOULD)** — Adding a food, renaming a label, or authoring a source group does not
require the same sign-off. These do not change what any existing record asserts.

The asymmetry between `CAT-SIGN-5` and `-6` is the point of having both. Adding `marmite` cannot change
what a past meal claims; correcting `oat milk` to carry `wheat` would retroactively assert a trigger
across every oat-milk meal she ever logged, which is exactly the mechanism §4 describes as a feature and
therefore exactly the mechanism that needs a human gate. The distinction is *what an existing record
comes to mean*, not how big the diff is.

`CAT-SIGN-3` is stated as a prohibition because the alternative was considered and rejected: a
`source:` field per food would be 160 more strings to review, would go stale silently, and would invite
rendering — at which point the app is citing sources for a claim `CAT-DERIVE-1` says it does not make.
Comments cannot be rendered. That is their advantage.

---

## 9. Preparations

**`CAT-PREP-1` (MUST)** — Preparation applicability is a property of the **food**, not of a coarse form
bucket ([ADR-0028](https://github.com/jirigrill/eczema-helper/blob/main/docs/adr/0028-food-level-preparations.md)).

**`CAT-PREP-2` (MUST)** — Every food carries its own ordered list of applicable preparation methods,
and that order is the order they are offered in.

**`CAT-PREP-3` (MUST)** — An **empty** preparation list is an ordinary authored state meaning the food
takes no preparation choice at all — salt, oils, drinks. It is not missing data.

**`CAT-PREP-4` (MUST)** — The catalog's list gates only **which choices are offered**. What a logged
meal item records is not constrained by it.

**`CAT-PREP-5` (MUST NOT)** — A food absent from the catalog is never given a guessed or default
preparation list.

`CAT-PREP-4` looks like a loophole and is deliberate. The catalog can legitimately narrow a food's
preparations in a later version — dropping `fried` from a food nobody fries — and a meal recorded under
the old list must still read back exactly as she recorded it. Constraining stored values to the current
catalog would mean a curation edit silently rewrites her history, which is the same failure `CAT-VER-6`
forbids by a different route.

`CAT-PREP-5` is the pair of `CAT-VER-8`. Guessing a chip set for a food the app cannot identify would
invite a preparation to be recorded against an unknown food — ADR-0028's own complaint about the bucket
scheme, one step further on. Thirty-seven of the 160 reference foods carry an empty list, so an empty
list must render as "no choice offered" and never as "not yet authored".

---

## 9a. Accessibility

The catalog renders nothing itself, so this block is short — but it is not empty, and the reason it is
not empty is the whole point of having it. The catalog is the **source of the data §7 forbids
displaying**, and an accessibility label is a display.

**`CAT-A11Y-1` (MUST)** — Every requirement in §7 binds the accessibility surface as written in
`CAT-DERIVE-6`. Allergen ids, allergen names, trigger counts and anything derived from them are absent
from labels, hints, traits, values and announcements, in every locale.

**`CAT-A11Y-2` (MUST)** — A food is announced by its **display label** (`CAT-LOC-1`) and nothing more.
Its family, its source group, and its position in a list are structure, not content, and are conveyed
by grouping rather than by being read out as part of the food's label.

**`CAT-A11Y-3` (MUST)** — A **preparation method** (§9) is announced by its own label, and its
applicability is conveyed by the choice being **absent** rather than present-and-disabled. An empty
preparation list (`CAT-PREP-3`) means assistive technology encounters no preparation control at all,
which is the correct reading of "no choice offered" — a disabled control would announce a choice that
does not exist.

**`CAT-A11Y-4` (MUST)** — Where a food's label is missing or its id does not resolve (`CAT-VER-8`),
the degraded rendering is announced as the same neutral text it displays. The announcement never
exposes a raw id, a diagnostic, or the fact that resolution failed.

The five questions the template requires an answer on, answered for this section:

| # | Answer |
| --- | --- |
| 1 | **VoiceOver label and trait** — the catalog specifies no interactive element. Food labels and preparation labels are the strings it owns (`CAT-A11Y-2`, `-3`); the controls that carry them belong to `meal-editor.md`, which specifies their traits. |
| 2 | **Dynamic Type** — food and preparation labels are authored copy and **must never be truncated to the point of ambiguity**: `CAT-MEMBER-4` granularity means `oat milk` and `oat` are different records, so a label clipped to "oat…" is a wrong identification, not a cosmetic loss. Labels must therefore be free to wrap. The catalog authors no length limit and no abbreviated variant for either. |
| 3 | **Colour alone** — nothing in this section conveys meaning by colour. `CAT-DERIVE-1` explicitly forbids the one case that would have (a colour derived from allergens), so there is no second channel to specify. |
| 4 | **Focus order and grouping** — the catalog specifies **order** (`CAT-SRC-3`, `CAT-PREP-2`) and requires that focus order follow authored order, because that order is curated and carries meaning. Grouping of the surfaces that render it is `meal-editor.md`'s. |
| 5 | **Reduce Motion** — not applicable. This section specifies no animation or transition, so there is nothing to suppress. |

---

## 10. What the catalog does not contain

These are prohibitions with ids, not features nobody built. Each is a decision taken elsewhere that a
reader would come to this section looking for, and an implementer filling the gap with a reasonable
guess would silently reverse it.

**`CAT-ABSENT-1` (MUST NOT)** — No allergen carries a reintroduction **ladder**, a dose schedule, or an
**allergenicity** grade. No table stores an override for any of them.

**`CAT-ABSENT-2` (MUST NOT)** — No allergen or food carries a **protocol**, a phase, an elimination
state, or an ordering intended for a protocol.

**`CAT-ABSENT-3` (MUST NOT)** — No food carries a **name** in any language (`CAT-SHAPE-5`), and no
allergen carries one at all (Divergence 5).

**`CAT-ABSENT-4` (MUST NOT)** — No food carries **search synonyms** (Divergence 3).

**`CAT-ABSENT-5` (MUST NOT)** — No catalog record carries a **provenance** field (`CAT-SIGN-3`).

**`CAT-ABSENT-6` (MUST NOT)** — There is no **user-extensible** tier: no custom food, no free text, no
recently-typed list, no "other" id (`CAT-MEMBER-6`).

**`CAT-ABSENT-7` (MUST NOT)** — There is no **jurisdictional** axis. The catalog does not know which
country the app is running in, and no mapping varies by market.

`CAT-ABSENT-1` is this section's answer to #734's third question — **whether `allergenicity` and
`ladder` travel at all.** They do not.

[#686](https://github.com/jirigrill/eczema-helper/issues/686) verified both have no live consumer and
left the disposition to this section. Measured against `4ff1c8f`, the evidence is stronger than "no
consumer": 22 of the 38 allergens carry `ladder`, `allergenicity`, and `allergenOrder` together, and
nothing outside the record definitions and the parked protocol code reads any of the three. The Dexie
store even carries a `ladder_overrides` table, keyed by allergen, with no reader in the live tree. All
of it serves the elimination-protocol engine, which is parked
([INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11)) and which the iOS
product does not start with.

The case for carrying them anyway is that re-deriving 22 clinical dose ladders later is real work, and
that argument loses on two grounds. Dose ladders are the most **clinically consequential** data in the
product — a wrong rung is a real-world harm, not a display bug — so they must be re-reviewed against
current guidance whenever the protocol engine is actually built, which makes carrying them forward
unsigned-off a liability rather than a saving. And they would arrive as data the owner is asked to
sign off (§8) for a feature that does not exist. If the engine is built, its ticket re-derives them with
the clinical review it owes.

> **Divergence 6 — the ladder and allergenicity fields are deleted.**
> **PWA:** 22 allergens carry `ladder`, `allergenicity`, and `allergenOrder`; a `ladder_overrides`
> table exists in the store; `LadderAllergenId` and `LadderStepId` are derived from the
> ladder-bearing subset.
> **iOS:** none of it ships. No ladder, no grade, no order field, no overrides table, no derived
> ladder types.
> **Why:**
> [INV-13](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-13) explicitly says the
> records "retain dormant `protocol` and `ladder` fields, read only by parked code" — so this
> divergence contradicts an invariant on purpose, which is why the disposition table names it. Dormant
> data that no live code reads is indistinguishable from stale data, and this particular stale data is
> clinical. Verified as consumer-free by
> [#686](https://github.com/jirigrill/eczema-helper/issues/686) and re-verified here.

> **Divergence 7 — `allergenOrder` goes with them, and nothing replaces it.**
> **PWA:** 22 allergens carry an `allergenOrder` integer.
> **iOS:** absent. Allergens have no authored order.
> **Why:** ordering exists to render a list, and `CAT-DERIVE-1` forbids rendering allergens at all. An
> order field on invisible data is a maintenance burden with no observable behavior. Families and
> source groups keep their curated order, because those *are* rendered (`CAT-SRC-3`).

---
## 11. Divergence index

| # | Section | Summary | Class |
| --- | --- | --- | --- |
| 1 | §2.3 `CAT-MEMBER-6` | No free-text tier and no unknown-food identity; restated as a divergence because it is the likeliest thing to be added back as a kindness. | Settled by #662 |
| 2 | §2.2, §7 | The allergen level ships populated and entirely unrendered; the PWA rendered it in the questionnaire. | Forced by INV-11 |
| 3 | §5 `CAT-ABSENT-4` | `aliases` is deleted — bilingual dead data for a search that does not exist. | Defect fixed |
| 4 | §6.1 `CAT-VER-8` | An unresolvable `foodId` degrades; the PWA throws on rehydration. | Settled by #703 |
| 5 | §7 `CAT-ABSENT-3` | The allergen label tables are not ported — unreachable in the PWA and forbidden to render here. | Defect fixed |
| 6 | §10 `CAT-ABSENT-1` | `ladder`, `allergenicity`, `allergenOrder` and the overrides table are deleted, contradicting INV-13's "dormant fields" clause on purpose. | Settled by #686, resolved here |
| 7 | §10 `CAT-ABSENT-1` | `allergenOrder` specifically goes with them; nothing replaces it. | Forced by Divergence 6 |
| 8 | §3 `CAT-SRC-7` | Source-group keys are normalised to en-GB; the PWA's 25 keys are 15 Czech and 10 English. | Settled by #677 |
| 9 | §3 `CAT-SRC-3` | The eliminated-group sort is deleted — documented in the PWA's own source, implemented nowhere. | Defect fixed |

Nine divergences, of which four (3, 5, 9, and the stale half of 6) delete data or documented behavior
that no live code in the shipped PWA reads. Divergence 6 is the only one that contradicts a numbered
invariant, and it does so with the invariant's own author's verification behind it.

**Divergence 9 is the one a reader should not skim.** It is the only case here where the reference's
*documentation* and its *code* disagree, and the documentation is the more authoritative-looking of the
two — a 15-line comment block in `family-sources.ts` describing a sort that `FamilyDrillIn.svelte` does
not perform. An agent porting from comments rather than behavior would implement it, discover it needs
an elimination state, and either invent one or park the work. Comments outlive the features they
describe; this is what that looks like.

---

## 12. Verification

### Where each rule is verified today

The reference has 154 catalog-adjacent tests across six files. The split below matters more than the
count: about 19 assert **structure** and carry over unchanged, while about 135 assert **Czech catalog
curation** and must be re-derived against the English catalog or dropped. An implementer who translates
by file rather than by class will port 135 assertions about food that is not in the product.

| Rules | Existing TypeScript tests | Verdict |
| --- | --- | --- |
| `CAT-SHAPE-2`, `-3` | `allergen-catalog.test.ts:11,16,21` (id uniqueness across all three collections) | **translate** |
| `CAT-SHAPE-2` (closure) | `allergen-catalog.test.ts:33,42,50` (every allergen → known family; every food → known family; every food's allergen ids → known allergens) | **translate** — these are the referential-integrity core |
| `CAT-SHAPE-5`, `CAT-LOC-7` | `strings/categories.test.ts:8,16`; `strings/families.ts` via `satisfies Record<CatalogFoodId, …>` | **re-derive** — Swift has no `satisfies`, so the compile-time guarantee becomes a CI audit |
| `CAT-SHAPE-6`, `CAT-ABSENT-1` | `allergen-catalog.test.ts:178` (no log-only allergen carries `allergenicity`) | **do not translate** — it asserts the pairing of fields this port deletes |
| `CAT-MEAN-6` | nothing asserts that an empty trigger set is intentional | **re-derive** — 57 foods depend on this reading |
| `CAT-MEAN-7` | `allergen-catalog.test.ts:215-270` (`hummus`, `sojove-mleko` spot checks) | **re-derive** — the many-to-many *shape* holds; the named Czech foods do not |
| `CAT-MEMBER-1..4` | `curation-rules.test.ts` — 56 tests, every one naming Czech ids or Czech-market granularity policy | **do not translate**; re-derive the *rules* against the English catalog |
| `CAT-MEMBER-7` | `allergen-catalog.test.ts:186` (at least one allergen is `low`) | **do not translate** — it tests a field this port deletes; replace with a representative-food check |
| `CAT-SRC-1`, `-2`, `-7` | `strings/family-sources.test.ts:52` (every food's `sourceGroup` exists in its family's axis) | **translate** — the single highest-value test in the set |
| `CAT-SRC-3` | `family-sources.test.ts` — 6 tests pinning exact Czech key sequences | **do not translate**; re-derive the order, keep the *shape* of the assertion |
| `CAT-SRC-4`, `-5` | `FamilyDrillIn.test.ts` grouped/flat branch tests | **translate** the threshold and the catch-all; the render assertions belong to the meal editor |
| `CAT-SRC-8` | nothing | **re-derive** |
| `CAT-PREP-1`, `-2` | `allergen-catalog.test.ts:87` (every food's preparations ⊆ known methods) | **translate** |
| `CAT-PREP-2` (per-food) | `allergen-catalog.test.ts:97-120` pins 7 named Czech foods' exact preparation arrays | **do not translate**; re-derive per English food |
| `CAT-PREP-3` | nothing asserts an empty list is intentional | **re-derive** — 37 foods depend on it |
| `CAT-PREP-5` | `preparation-rules.ts:25` returns `[]` for an unknown id; no test | **re-derive** |
| `CAT-VER-4`, `-8`, `-9` | `working-meal.ts:350` **throws** — the behavior being diverged from | **do not translate** |
| `CAT-DERIVE-1..5` | nothing — there is no screen to assert against | **re-derive** as a prohibition test over the rendered surface |
| `CAT-DERIVE-6`, `CAT-A11Y-1` | nothing, and the PWA has no accessibility assertions at all | **re-derive** — extend the `CAT-DERIVE-1` prohibition test over labels, hints, traits and values, not only over rendered text |
| `CAT-A11Y-2`, `-4` | nothing | **re-derive** |
| `CAT-A11Y-3` | `preparation-rules.ts:25` returns `[]`; nothing asserts an empty list yields **no control** | **re-derive** — the assertion is about absence, which the PWA never made |
| `CAT-SIGN-1..6` | nothing, and nothing could | **do not translate** — process, not behavior |

### Rules nothing verifies today

This is the honest list, and for this section it is where the real work is.

- **Every rule in §7.** The prohibition on displaying a trigger has no test anywhere, because the PWA
  has no screen that would violate it — the questionnaire that did is parked. The port's most
  load-bearing group of rules arrives with zero inherited coverage, and `CAT-DERIVE-1` needs a test
  that asserts an *absence* across the whole rendered surface.
- **The meaning of an empty trigger set** (`CAT-MEAN-6`) and **an empty preparation list**
  (`CAT-PREP-3`). Between them these cover 57 and 37 of 160 foods, and nothing distinguishes
  "deliberately empty" from "not yet authored" in either the data or the tests. This is the single
  most likely thing for a curation pass to get wrong.
- **`CAT-MEMBER-7`, and it is currently false.** Six of the 38 allergens have no representative food:
  `grains`, `fruit`, `onion-garlic`, `other-vegetables`, `meat`, `sweeteners`. All six are umbrella
  allergens with no ladder, so nothing breaks today — but `CONTEXT.md`'s own granularity principle
  says an allergen with no neutral home still needs at least one representative food, and the catalog
  quietly breaks that six times. Recorded as a `SHOULD` for that reason, with the gap named in §13.
- **Catalog/label-table drift** (`CAT-LOC-7`). The PWA gets this free from the compiler; the port must
  build it, and until it does, a missing label is a runtime blank rather than a build failure.
- **Retirement-in-place** (`CAT-VER-5`, `-6`). Nothing in the reference tests id reuse, because with
  one device and one bundle it could not happen.
- **`CAT-SHAPE-7`'s counts.** No test asserts the catalog's extent, so a translation pass that drops a
  row fails nothing.
- **Everything in §8.** Sign-off is a procedure; it is verified by a human doing it or not.
- **Every rule in §9a.** The reference has no accessibility assertions of any kind, so the whole
  accessibility block inherits zero coverage. `CAT-A11Y-1` matters most: it is the rule that stops §7's
  prohibition being satisfied on the visible surface and breached in a label, and it is the one gap
  that a screenshot review cannot find.

---
### Acceptance pass

Instructions for a person holding a phone. Steps marked **✗ PWA** are expected to fail on the reference
implementation — those are the divergences, and they are what prove the port did something.

The catalog has no screen of its own, so this pass is mostly *looking for things that must not be
there*. That is the honest shape of a section whose largest rule group is a prohibition.

1. Open the food picker from any meal slot. Count the family tiles: there are **thirteen**
   (`CAT-SHAPE-7`).
2. Open `Dairy`. The foods are clustered under headed groups (`Cow`, `Sheep`, `Goat`, `Plant`), in that
   order — not alphabetically (`CAT-SRC-3`, `CAT-SRC-4`).
3. In that same list, find the plant milks. **Soy milk is here, under Dairy** — not under Legumes —
   and nothing on its tile mentions soy (`CAT-SHAPE-4`, `CAT-DERIVE-1`).
4. Open `Eggs`. Three foods, **no group headers at all** — it is under the five-food threshold
   (`CAT-SRC-4`).
5. Open `Vegetables`. The last group is the catch-all, it contains exactly one food (`mushroom`), and
   it carries no warning colour, no icon, and no "unclassified" wording (`CAT-SRC-5`, `CAT-SRC-6`).
6. Open `Meat`. Nine foods, flat and alphabetical, no headers (`CAT-SRC-4`).
7. Now go looking for a trigger anywhere in the picker. Tap through every family: **no tile, badge,
   chip, colour, or count anywhere tells you what a food contains** (`CAT-DERIVE-1`). **✗ PWA** — the
   reference's parked questionnaire displayed allergen names.
8. Read every string on the picker and in Settings looking for a hedge — "based on typical
   ingredients", "may contain", a disclaimer sheet. There are none (`CAT-DERIVE-5`).
9. Tap `Oat milk`. Log it. Nothing at any point suggests it is safe, risky, or dairy-free — it is a
   food you logged, and that is all (`CAT-DERIVE-3`, `CAT-MEAN-4`).
10. Tap `Salt`. It offers **no preparation choices at all** — no chip row, and no empty row where one
    would be (`CAT-PREP-3`).
11. Tap `Banana`. It offers preparations, and they are *its* preparations — there is no `fried`
    (`CAT-PREP-1`, `CAT-PREP-2`).
12. Log a meal, then go to the day view. The row shows the food's name resolved from the catalog — set
    the phone to a different English dialect where a label differs and confirm the **same logged meal**
    now reads with the other dialect's word (`CAT-LOC-2`, `CAT-LOC-3`). **✗ PWA** — the reference
    persists the display name onto the record.
13. Set the phone to English (Australia). The app is in English and every food has a name — nothing is
    blank and nothing falls back to a raw id (`CAT-LOC-1`, `CAT-LOC-4`).
14. Still in English (Australia), open a family and confirm the labels are the **British** spellings
    (`CAT-LOC-1`).
15. Search for a food. **There is no search field** — the picker is grid-and-drill-in only
    (`CAT-ABSENT-4`).
16. Try to add a food that is not in the catalog. There is no way to: no "other" tile, no free-text
    field, no recently-typed list (`CAT-MEMBER-6`, `CAT-ABSENT-6`).
17. Log a stew or a pizza. You cannot log it as one thing — you log its components (`CAT-MEMBER-2`,
    `CAT-MEMBER-3`).
18. Anywhere in the app, look for a reintroduction ladder, a dose step, or a food graded by how
    allergenic it is. There is nothing (`CAT-ABSENT-1`, `CAT-ABSENT-2`). **✗ PWA** — the reference
    ships 22 ladders in its data.
19. **Turn VoiceOver on** and swipe through a whole family's food list. Every food is announced by its
    name alone — no announcement mentions an allergen, a count, or what a food contains
    (`CAT-A11Y-1`, `CAT-DERIVE-6`). **✗ PWA** — untestable there; the reference specifies no labels.
20. Still under VoiceOver, land on `Salt`. There is **no preparation control to reach** — not a disabled
    one (`CAT-A11Y-3`). Then land on `Banana` and confirm its preparations are announced in the
    authored order, not alphabetically (§9a question 4, `CAT-PREP-2`).
21. Set Dynamic Type to the **largest accessibility size** and open `Dairy`. Every food name is fully
    readable — wrapped if it must be, never clipped to a prefix that reads as a different food
    (`CAT-A11Y-2`). `Oat milk` in particular must not render as `Oat…`.

The last two steps below need a second device or a build, so they are the owner's to run with help.


22. **Skew.** On a device with an older build, open a day holding a meal logged on a newer build that
    contains a food the older one does not. The app does not crash, the meal is still there, and
    nothing is deleted (`CAT-VER-8`, `CAT-VER-9`). **✗ PWA** — the reference throws. The item's own
    display behavior is [#749](https://github.com/jirigrill/eczema-helper/issues/749)'s.
23. **Then update that device.** The food reappears in full, in the meal where she logged it, with
    nothing re-entered (`CAT-VER-9`).

---

## 13. Open questions

**Six of thirty-eight allergens have no representative food.** `grains`, `fruit`, `onion-garlic`,
`other-vegetables`, `meat`, and `sweeteners` are referenced by no food in the reference catalog, so
nothing the mother can log expresses them. `CONTEXT.md`'s granularity principle says an allergen still
needs at least one representative food, which makes the current data quietly non-conforming. It is
harmless today because all six are umbrella allergens carrying no ladder and nothing renders them, which
is why `CAT-MEMBER-7` is a `SHOULD`. What is unknown is whether they are *intended* as umbrella
groupings that foods roll up to conceptually, or are simply unfinished — and that is a curation question
for the owner, not a porting decision. **No schema deadline:** adding a food or a mapping later is
additive.

**Whether `en` should carry en-GB or en-US content.** `CAT-LOC-1` follows
[#702](https://github.com/jirigrill/eczema-helper/issues/702) in giving bare `en` the en-GB content,
which is what makes `CAT-LOC-4`'s unlisted dialects British. That is right for `en-AU`, `en-IE`, and
`en-NZ`, and wrong for `en-CA`, which is closer to US usage in food vocabulary. #702 verified there is no
region-axis fallback in the String Catalog and no documented sibling-dialect fallback, so one dialect
must take the unlisted set wholesale. The question is only whether Canada's mismatch outweighs the other
three; it is not answerable without knowing where the app will be used, which is not decided. **No
schema deadline.**

**Whether the catalog needs a rule about foods that exist in one market only.** `CAT-MEMBER-5` says a
market-specific food is added catalog-wide and named per locale, which is the simplest thing that works
but means an American mother sees `marmite` in her picker and a British one sees `grits`. The
alternative — a per-locale food subset — would put a jurisdictional axis into the catalog, which
`CAT-ABSENT-7` forbids for good reasons. Whether a small amount of cross-market noise in the picker is
acceptable is a product judgment the owner should make once the dialect tables are drafted and the
actual overlap is visible. **No schema deadline**, but it should be settled before the first
English catalog is signed off, because unpicking it later means retiring ids.

**Three answers this section gives that were assigned to it, and which the owner should confirm rather
than assume.** All three were left open deliberately by their source tickets, so they are recorded here
as answered rather than cited: presentation belongs to the meal editor (`CAT-SHAPE-8`), `sourceGroup`
survives with en-GB keys (`CAT-SRC-7`), and the ladder and allergenicity fields do not travel
(`CAT-ABSENT-1`). The third is the one with a real cost if wrong — see §10 — and it is the one to read
first.

---

## Appendix: what this section does not contain

- **Platform types.** No Swift, no SwiftData, no `@Model`, no String Catalog mechanics. How the catalog
  is expressed in Swift is the implementer's; that it never enters the store is
  [`persistence-model.md`](persistence-model.md) `DATA-SCOPE-2`/`-3`.
- **The food picker's appearance.** Grid layout, tile size, drill-in transition, and every visual
  choice belong to the meal editor (`CAT-SHAPE-8`). This section states only which data-shape facts
  drive grouping.
- **What a screen does with an unresolvable item.** Hiding, read-only degradation, and the blank-row
  case are [#703](https://github.com/jirigrill/eczema-helper/issues/703)'s answers, and they land in
  `day-view.md` via [#749](https://github.com/jirigrill/eczema-helper/issues/749). §6.1 states only
  that the data survives.
- **The stored shape of a meal item.** `MealItem` carrying `foodId` and no label, and the immutability
  of a stored id, are `persistence-model.md`'s (`DATA-SCOPE-5`, `-6`, `DATA-ABSENT-3`).
- **Invariant text.** Cited by anchor, never restated. Four invariants are deliberately false for iOS;
  see the disposition table.
- **The Czech catalog's contents.** 160 Czech food names, 25 Czech source-group keys, and 38 Czech
  allergen names are the *input* to a translation, not part of this specification. The English catalog
  is authored under §8's sign-off, and its contents are the git history's record, not this document's.
- **The protocol engine.** Ladders, phases, reintroduction, and elimination state are parked
  ([INV-11](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-11)); §10 deletes their
  data rather than describing them.
- **`UBIQUITOUS_LANGUAGE.md`.** Not ported — 696 lines of the Czech product's vocabulary
  ([#677](https://github.com/jirigrill/eczema-helper/issues/677)). Do not consult it for English
  naming.
- **The design prototype.** `redesign-prototype.html` depicts the pre-descaling protocol UI and the
  removed custom-food surfaces (`➕ Vlastní`, free-text entry, `Dříve zadané`). For the food picker
  specifically it is **stale**: it shows a tier this section prohibits (`CAT-ABSENT-6`). Do not cite it
  for catalog behavior.
