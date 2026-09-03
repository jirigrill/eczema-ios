import Testing

@testable import EczemaCatalog
@testable import EczemaDomain
@testable import EczemaPersistence

/// Proves the package test loop runs end to end: `just test` resolves the graph, builds
/// every target and executes a test. Without one executed test, "no tests written yet"
/// and "the runner is silently broken" look identical from the outside.
///
/// There are deliberately no behavior tests here. Spec-derived tests are the durable
/// verification layer and they land with the rules they encode — the schema and the
/// domain models are still on a spec deadline that has not closed.
@Suite struct Scaffolding {
    /// The assertion is the import list above and the fact that this body runs at all:
    /// the suite fails to compile if a target is renamed, dropped from the manifest or
    /// stops building, and fails to run if the test binary does not link. There is
    /// nothing to `#expect` yet because there is no behavior yet.
    @Test func coreTargetsBuildAndLink() {}
}
