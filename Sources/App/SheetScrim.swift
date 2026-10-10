import SwiftUI

/// The system sheet material takes on whatever is behind it. Mid-tone imagery there leaves the
/// sheet's text under 4.5:1, so lift the backdrop in light mode and sink it in dark mode.
/// Place it over the content, below the sheet; it covers the bottom `coverage` of the height.
struct SheetScrim: View {
    var coverage: CGFloat = 0.58
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let tint: Color = scheme == .dark ? .black.opacity(0.6) : .white.opacity(0.55)
        LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: tint, location: 0.3),
                               .init(color: tint, location: 1)],
                       startPoint: .top, endPoint: .bottom)
            .containerRelativeFrame(.vertical) { height, _ in height * coverage }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
