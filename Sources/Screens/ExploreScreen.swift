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
                        .safeAreaPadding(.bottom, 470)
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
        .toolbarColorScheme(.light, for: .statusBar)
        .sheet(isPresented: .constant(true)) {
            NearbySheet()
                .presentationDetents([.height(120), .medium, .large], selection: $detent)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .interactiveDismissDisabled()
        }
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
            .overlay { Circle().stroke(.white, lineWidth: 2) }
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
                    // Color.primary, not .primary: a section header would dim the hierarchical one.
                    Text("Nearby in Higashiyama")
                        .foregroundStyle(Color.primary)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            // The sheet doesn't clip its content to its rounded corners, so end the list between
            // two rows and leave the corner area empty.
            .padding(.bottom, 24)
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
            }
            Spacer()
            Label {
                Text(place.rating, format: .number.precision(.fractionLength(1)))
            } icon: {
                Image(systemName: "star.fill")
            }
            .font(.subheadline.weight(.semibold))
        }
        .accessibilityElement(children: .combine)
    }
}
