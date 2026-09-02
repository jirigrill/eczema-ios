# eczema-ios

A native iOS app for recording an infant's atopic eczema: what was eaten, and how the skin looked.

`eczema-ios` is a placeholder name — the product's English name is still undecided ([#697](https://github.com/jirigrill/eczema-helper/issues/697)). GitHub redirects the old path after a rename.

## What this app does

It is a **diary**. The mother records meals and per-region skin observations, with photos. The app stores those records, shows them back on a day view, and syncs them to her own iCloud account so a new phone picks up where the old one left off.

The app does not analyse the record, rank foods, score risk, suggest what to remove or reintroduce, or tell her what any of it means. Reading the diary is her job and her doctor's.

> **Note for anyone writing copy for this repo, the App Store listing, or a commit message:** describe *recording*, never *finding*. A sentence like "discover which foods trigger flare-ups" claims the app draws a clinical inference, and that re-qualifies a record-only diary as a medical device — with no change to a single line of code. This applies to this README, because a public repo is a marketing surface.

## Status

**Scaffolded, with no behavior.** The Xcode project builds for the iOS Simulator and the package tests run, but nothing is implemented — no domain models, no schema, no screens.

The behavior spec is being written first, in `docs/spec/`, and deliberately does not wait on the Apple Developer Program enrolment ([#676](https://github.com/jirigrill/eczema-helper/issues/676)).

## Where the planning lives

This app is a port of a working Czech SvelteKit PWA, which serves as its behavior reference. That PWA lives at **[jirigrill/eczema-helper](https://github.com/jirigrill/eczema-helper)** and is **frozen** — it receives no further updates and is kept as stable history.

The port is being planned on a Wayfinder map on that repo: **[Map: PWA → native iOS](https://github.com/jirigrill/eczema-helper/issues/672)**. New planning tickets are filed there, as children of that map, not here. Read the map before starting work — it holds every decision made so far and why.

## Docs

See [`docs/README.md`](docs/README.md).

## Platform

SwiftUI · SwiftData · CloudKit private database · iOS 26 minimum · English-only. No backend, no accounts of our own, single child, one user.
