import SwiftUI

/// Screen 3 · Discover.
/// Functional layer: the system tab bar with the iOS 27 prominent Trips tab, and the
/// navigation bar. Content layer: the destination cards.
struct DiscoverScreen: View {
    var body: some View {
        TabView {
            Tab("Discover", systemImage: "sparkles") {
                NavigationStack {
                    DiscoverFeed()
                }
            }
            Tab("Map", systemImage: "map") {
                NavigationStack {
                    ContentUnavailableView("Map", systemImage: "map",
                                           description: Text("Your saved places on one map."))
                        .navigationTitle("Map")
                }
            }
            Tab("Saved", systemImage: "heart") {
                NavigationStack {
                    ContentUnavailableView("Nothing Saved Yet", systemImage: "heart",
                                           description: Text("Tap the heart on any place to keep it here."))
                        .navigationTitle("Saved")
                }
            }
            Tab("Trips", systemImage: "suitcase", role: .prominent) {
                NavigationStack {
                    ContentUnavailableView("No Trips Yet", systemImage: "suitcase",
                                           description: Text("Plan a trip from any destination."))
                        .navigationTitle("Trips")
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        // The selected tab's label takes the tint. The accent blue measured 2.1:1 (light) and
        // 3.2:1 (dark) on the glass over the photo cards; the primary color is 4.6:1 or better.
        .tint(.primary)
    }
}

private struct DiscoverFeed: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(SampleData.destinations) { destination in
                    DestinationCard(destination: destination)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollEdgeEffectStyle(.hard, for: .bottom)
        .navigationTitle("Discover")
        .navigationSubtitle("Picked for this autumn")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Profile", systemImage: "person.crop.circle") {}
            }
        }
    }
}

private struct DestinationCard: View {
    let destination: Destination

    var body: some View {
        Color.clear
            .frame(height: 400)
            .overlay {
                Image(destination.photo)
                    .resizable()
                    .scaledToFill()
            }
            .overlay(alignment: .bottom) {
                // Taller than the caption, so the small country label sits on a dark part too.
                LinearGradient(stops: [.init(color: .clear, location: 0),
                                       .init(color: .black.opacity(0.5), location: 0.4),
                                       .init(color: .black.opacity(0.7), location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 260)
            }
            .overlay(alignment: .bottomLeading) {
                caption
            }
            .clipShape(.rect(cornerRadius: 28))
            .accessibilityElement(children: .combine)
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(destination.country.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.white)
            Text(destination.name)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text(destination.tagline)
                .font(.subheadline)
                .foregroundStyle(.white)
            HStack(spacing: 8) {
                chip(destination.length, symbol: "calendar")
                chip(destination.price, symbol: "tag.fill")
            }
            .padding(.top, 6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(_ text: String, symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.35), in: .capsule)
    }
}
