import Testing

@testable import EczemaUI

/// Proves this package's test loop runs, and that the bundled string catalog is reachable
/// through `Bundle.module` — the mechanism every localized string in this target will use.
/// A resource that silently fails to bundle shows up as the key rendering instead of the
/// text, which is easy to miss and cheap to catch here.
@Suite struct Scaffolding {
    @Test func stringCatalogIsBundled() {
        let title = String(localized: "root.placeholder.title", bundle: .module)
        #expect(title != "root.placeholder.title")
    }
}
