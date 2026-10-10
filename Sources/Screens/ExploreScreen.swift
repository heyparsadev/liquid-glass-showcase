import MapKit
import SwiftUI

/// Screen 1 · Explore (Kyoto).
/// Functional layer: the map controls (custom glass: one container, one union) and the
/// system sheet. Content layer: the satellite map, its place pins and the place rows.
struct ExploreScreen: View {
    @State private var detent: PresentationDetent = .medium
    /// Screen positions of the pins, filled in once the map camera has settled.
    @State private var pinPoints: [String: CGPoint] = [:]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // MapKit draws no markers or annotations on the realistic imagery style in the
            // iOS 27 simulator, so the pins are SwiftUI views placed with the map proxy.
            MapReader { proxy in
                ZStack {
                    Map(initialPosition: .camera(SampleData.kyotoCamera))
                        .mapStyle(.imagery(elevation: .realistic))
                        .mapControlVisibility(.hidden)
                        .onMapCameraChange(frequency: .onEnd) { _ in
                            for place in SampleData.kyotoPlaces {
                                pinPoints[place.id] = proxy.convert(place.coordinate, to: .local)
                            }
                        }
                    ForEach(SampleData.kyotoPlaces) { place in
                        if let point = pinPoints[place.id] {
                            PlacePin(place: place)
                                .position(point)
                        }
                    }
                }
            }
            .ignoresSafeArea()

            SheetScrim()

            MapControls()
                .padding(.top, 8)
                .padding(.trailing, 16)
        }
        .sheet(isPresented: .constant(true)) {
            NearbySheet()
                .presentationDetents([.height(120), .medium, .large], selection: $detent)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .interactiveDismissDisabled()
        }
    }
}

/// The system sheet material takes on whatever is behind it. Imagery that is mid-gray there
/// leaves the sheet's secondary text under 4.5:1, so lift it in light and sink it in dark.
private struct SheetScrim: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let tint: Color = scheme == .dark ? .black.opacity(0.6) : .white.opacity(0.55)
        LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: tint, location: 0.3),
                               .init(color: tint, location: 1)],
                       startPoint: .top, endPoint: .bottom)
            .containerRelativeFrame(.vertical) { height, _ in height * 0.58 }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

/// A map pin: content, so no glass.
private struct PlacePin: View {
    let place: NearbyPlace

    var body: some View {
        Image(systemName: place.symbol)
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(place.tint.gradient, in: .circle)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
            .accessibilityLabel(place.name)
    }
}

/// Two controls that read as one glass body: same shape and variant, one union.
private struct MapControls: View {
    @Namespace private var controls

    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 0) {
                control("map", label: "Map Style")
                control("location.fill", label: "Show My Location")
            }
        }
    }

    private func control(_ symbol: String, label: String) -> some View {
        Button {} label: {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        .glassEffectUnion(id: "map-controls", namespace: controls)
        .accessibilityLabel(label)
    }
}

/// The persistent bottom sheet: system glass, plain content rows.
private struct NearbySheet: View {
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(SampleData.kyotoPlaces) { place in
                        NearbyRow(place: place)
                    }
                } header: {
                    Text("Nearby in Higashiyama")
                        .foregroundStyle(Color.primary.opacity(0.72))
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .navigationTitle("Kyoto")
            .toolbarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search Kyoto")
        }
    }
}

private struct NearbyRow: View {
    let place: NearbyPlace

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: place.symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(place.tint.gradient, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .font(.headline)
                Text("\(place.category) · \(place.distance)")
                    .font(.subheadline)
                    .foregroundStyle(Color.primary.opacity(0.72))
            }
            Spacer()
            Label {
                Text(place.rating, format: .number.precision(.fractionLength(1)))
            } icon: {
                Image(systemName: "star.fill")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.primary.opacity(0.72))
        }
        .accessibilityElement(children: .combine)
    }
}
