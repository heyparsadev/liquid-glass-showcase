import SwiftUI

/// A dimming layer under a system sheet, in dark mode only.
///
/// The sheet material takes on whatever is behind it. Over bright imagery in dark mode, even
/// primary text falls under 4.5:1 (4.2:1 measured on Explore), so the backdrop is sunk by 40%,
/// close to the 35% Apple suggests under clear glass. The liquid-glass skill says regular glass
/// needs no dimming; this is a deliberate trade for photo and map backdrops. In light mode the
/// primary text already reads, so nothing is drawn.
///
/// Place it over the content and below the sheet; it covers the bottom `coverage` of the height.
struct SheetScrim: View {
    var coverage: CGFloat = 0.58
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if scheme == .dark {
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black.opacity(0.4), location: 0.3),
                                   .init(color: .black.opacity(0.4), location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .containerRelativeFrame(.vertical) { height, _ in height * coverage }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
}
