import EczemaUI
import SwiftUI

/// The whole app target, and it should stay roughly this size.
///
/// Everything with logic lives in `Packages/`. That is not tidiness: a fat app target
/// would make the effectively-unmaintained `xcode-build-server` a hard dependency for
/// the agent editing path, and it would push every test behind a simulator boot.
@main
struct EczemaApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
