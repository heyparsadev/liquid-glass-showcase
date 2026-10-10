import SwiftUI

/// What the app shows when it is opened without a `-screen` argument: a list of the screens.
/// Tapping one opens it full screen; the "Screens" pill at the top comes back. The capture
/// script always passes `-screen N`, so none of this appears in a screenshot.
struct Launcher: View {
    @State private var opened: ScreenID?

    var body: some View {
        NavigationStack {
            List(ScreenID.allCases) { screen in
                Button {
                    opened = screen
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(screen.rawValue). \(screen.title)")
                            .font(.headline)
                        Text(screen.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Showcase")
            .navigationSubtitle("Tap a screen. Tap Screens at the top to come back.")
        }
        .fullScreenCover(item: $opened) { screen in
            screen.view
                .overlay(alignment: .top) {
                    BackToList { opened = nil }
                        .ignoresSafeArea(edges: .top)
                }
        }
    }
}

/// A small pill under the Dynamic Island. It is a browsing aid, not part of the showcase UI,
/// so it uses a plain material, never glass.
private struct BackToList: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Screens", systemImage: "chevron.backward")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.regularMaterial, in: .capsule)
        }
        .buttonStyle(.plain)
        .padding(.top, 52)
    }
}
