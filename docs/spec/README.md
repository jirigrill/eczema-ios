# Behavior spec

The behavior spec for the iOS app: platform-neutral, owner-confirmed, and complete enough that a Swift developer or agent can build the port and derive tests from it without further discovery.

**This directory is deliberately near-empty.** The section template — how a spec document is structured, and how a rule is phrased so a test falls out of it — is decided by [Behavior spec format and section template](https://github.com/jirigrill/eczema-helper/issues/682). Do not invent a format ahead of it; that ticket exists so every section shares one.

Once the template exists, the spec sections graduate one at a time: skin observation, day view, first-run and feeding stage, settings, and the SwiftData model plus CloudKit schema.

## Already written, elsewhere

The meal editor is the one area already extracted, and it lives on the frozen PWA repo alongside the code it was read out of: [`docs/spec/meal-editor-state-machine.md`](https://github.com/jirigrill/eczema-helper/blob/main/docs/spec/meal-editor-state-machine.md). It documents three cooperating state machines (per-food, session, exit), maps every rule to its current TypeScript test, marks what translates to Swift, and lists its own open questions. Reference it; do not copy it here.
