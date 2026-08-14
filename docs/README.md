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
- [`docs/adr/`](https://github.com/jirigrill/eczema-helper/tree/main/docs/adr) — live decisions `0001` (single-device), `0028` (food-level preparations), `0029` (no crypto / no backup).
- [`docs/spec/meal-editor-state-machine.md`](https://github.com/jirigrill/eczema-helper/blob/main/docs/spec/meal-editor-state-machine.md) — the meal editor, already extracted: three cooperating state machines, with every rule mapped to its current test.
- [`docs/research/`](https://github.com/jirigrill/eczema-helper/tree/main/docs/research) — primary-source findings behind this transition: App Store 5.1.3(ii) and CloudKit, CloudKit photo and asset limits, behavior when iCloud is unavailable, the GDPR DPIA assessment, Art. 9 lawful basis, professional indemnity insurance, and sources for an English-market infant allergen catalog.
- [`UBIQUITOUS_LANGUAGE.md`](https://github.com/jirigrill/eczema-helper/blob/main/UBIQUITOUS_LANGUAGE.md) — the Czech glossary. **Not ported**; it freezes there. This repo grows its own short English glossary seeded from `INV-1..14`.

## Where decisions are recorded

On the map's tickets, at [`jirigrill/eczema-helper#672`](https://github.com/jirigrill/eczema-helper/issues/672). Each closed ticket carries its resolution as a comment, and the map body indexes them. That stays true after the Swift work moves here: new planning tickets are filed on the frozen repo as children of the map, because GitHub transfers drop the parent/child and dependency wiring that gives the map its value.

Whether this repo grows its own ADR series is not yet decided.
