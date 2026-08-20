# Docs

Documentation for the native iOS eczema-recording app.

## Overview

This directory holds the app's own documentation. Right now that is almost entirely **the behavior spec** in `spec/` — the artifact this project is being planned around, written before any Swift.

Docs here describe what exists or what the app must do. Anything forward-looking — open questions, decisions not yet made — lives on the [Wayfinder map](https://github.com/jirigrill/eczema-helper/issues/672), not here.

## Layout

- `spec/` — platform-neutral behavior specifications. One document per behavior area, each written so tests fall out of it. This is the primary deliverable of the current phase.

## What lives in the frozen PWA repo instead

[`jirigrill/eczema-helper`](https://github.com/jirigrill/eczema-helper) is frozen stable history and holds the reference material. Reference it by link; never copy it here — a duplicated finding is one that goes stale.

- [`CONTEXT.md`](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md) — domain invariants `INV-1..14`, permanently stable ids with HTML anchors, so [`CONTEXT.md#inv-4`](https://github.com/jirigrill/eczema-helper/blob/main/CONTEXT.md#inv-4) resolves from here. Roughly 15 further invariant-shaped rules sit unnumbered in its glossary prose — cite those by heading.
- [`docs/adr/0028`](https://github.com/jirigrill/eczema-helper/blob/main/docs/adr/0028-food-level-preparations.md) — food-level preparations, the one live **domain** decision there. Untouched by the platform change, so it ports intact: each food carries its own preparation list rather than picking a coarse form bucket. Cite it from the catalog spec section.
- [`docs/adr/0001`](https://github.com/jirigrill/eczema-helper/blob/main/docs/adr/0001-single-device-v1.md) (single-device) and [`docs/adr/0029`](https://github.com/jirigrill/eczema-helper/blob/main/docs/adr/0029-no-crypto-no-backup.md) (no crypto / no backup) — **PWA-scoped history, not guidance for this app.** Both stay true of the PWA and both were decided the other way here: this product syncs through a CloudKit private database, and CloudKit field encryption is available and cheap. Read them for the trade-offs they record; each carries a `**Scope:**` line marking the boundary. The iOS positions live on the map ([#688](https://github.com/jirigrill/eczema-helper/issues/688), [#693](https://github.com/jirigrill/eczema-helper/issues/693), [#683](https://github.com/jirigrill/eczema-helper/issues/683)).
- [`docs/spec/meal-editor-state-machine.md`](https://github.com/jirigrill/eczema-helper/blob/main/docs/spec/meal-editor-state-machine.md) — the meal editor, already extracted: three cooperating state machines, with every rule mapped to its current test.
- [`docs/research/`](https://github.com/jirigrill/eczema-helper/tree/main/docs/research) — primary-source findings behind this transition: App Store 5.1.3(ii) and CloudKit, CloudKit photo and asset limits, behavior when iCloud is unavailable, the GDPR DPIA assessment, Art. 9 lawful basis, professional indemnity insurance, and sources for an English-market infant allergen catalog.
- [`UBIQUITOUS_LANGUAGE.md`](https://github.com/jirigrill/eczema-helper/blob/main/UBIQUITOUS_LANGUAGE.md) — the Czech glossary. **Not ported**; it freezes there. This repo has [`docs/spec/GLOSSARY.md`](spec/GLOSSARY.md) instead, holding only the terms used by more than one spec section. It is not seeded from `INV-1..14` — invariants are cited by anchor rather than restated as vocabulary ([#707](https://github.com/jirigrill/eczema-helper/issues/707)).

## Where decisions are recorded

On the map's tickets, at [`jirigrill/eczema-helper#672`](https://github.com/jirigrill/eczema-helper/issues/672). Each closed ticket carries its resolution as a comment, and the map body indexes them. That stays true after the Swift work moves here: new planning tickets are filed on the frozen repo as children of the map, because GitHub transfers drop the parent/child and dependency wiring that gives the map its value.

This repo grows its own `adr/` when it has a decision that **outlives a ticket** — not before, and the directory stays uncreated until then ([#688](https://github.com/jirigrill/eczema-helper/issues/688)). Two candidates are already visible, both waiting on their own content: a sync decision (gated on [#705](https://github.com/jirigrill/eczema-helper/issues/705)) and a field-encryption decision (gated on [#714](https://github.com/jirigrill/eczema-helper/issues/714), deadlined at CloudKit production-schema promotion). Whether either warrants an ADR rather than a log entry is [#721](https://github.com/jirigrill/eczema-helper/issues/721). Do not pre-write them: a stub restating an open ticket is the cross-repo duplicate this layout exists to avoid.
