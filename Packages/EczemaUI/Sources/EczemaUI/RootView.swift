import SwiftUI

/// The app's root view.
///
/// Scaffolding only. This is a placeholder so the app shell has something to present and
/// the shell → package link path is exercised by the simulator build; it is not a spec
/// view. `docs/spec/` decides what actually renders here, and none of it is confirmed yet.
public struct RootView: View {
    public init() {}

    public var body: some View {
        ContentUnavailableView(
            String(localized: "root.placeholder.title", bundle: .module),
            systemImage: "square.dashed",
            description: Text("root.placeholder.description", bundle: .module)
        )
    }
}

#Preview {
    RootView()
}
