import Foundation
import Testing

@testable import EczemaUI

@Suite struct Scaffolding {
    /// Proves this package's test loop runs and that the string catalog reaches
    /// `Bundle.module` — the mechanism every localized string in this target will use.
    /// A resource that silently fails to bundle renders as its key, which is easy to miss.
    ///
    /// It deliberately does **not** assert that the key resolves to its text. Whether a
    /// `.xcstrings` is compiled to `.strings` or copied verbatim depends on the SwiftPM
    /// running it: Xcode 27 compiles it, and an Xcode 26 toolchain copies it — under the
    /// copy the lookup legitimately falls back to the key. CI pins Xcode 27, so only one
    /// of those is exercised there today; asserting the rendered text would still encode
    /// a toolchain version rather than a property of this code.
    /// Rendering is a mechanical UI claim, and per CLAUDE.md those belong to the
    /// UI-automation evidence layer against a real simulator, not to a host unit test.
    @Test func stringCatalogIsBundled() {
        let compiled = Bundle.module.url(
            forResource: "Localizable",
            withExtension: "strings",
            subdirectory: nil,
            localization: "en"
        )
        let verbatim = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings")

        #expect(
            compiled != nil || verbatim != nil,
            "Localizable.xcstrings did not reach Bundle.module in any form."
        )
    }
}
