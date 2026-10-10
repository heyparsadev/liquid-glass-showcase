import SwiftUI

/// Screen 2 · Place (Oia, Santorini).
/// Functional layer: system toolbar items over the photo, and the action bar in a
/// `safeAreaBar`. Content layer: the photo, title, facts, and highlights.
struct PlaceScreen: View {
    private let place = SampleData.oia

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PlaceHero(place: place)
                    PlaceDetails(place: place)
                }
            }
            .ignoresSafeArea(edges: .top)
            .scrollEdgeEffectStyle(.hard, for: .bottom)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back", systemImage: "chevron.backward") {}
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Share", systemImage: "square.and.arrow.up") {}
                    Button("Save", systemImage: "heart") {}
                }
            }
            .safeAreaBar(edge: .bottom) {
                PlaceActions()
            }
        }
    }
}

private struct PlaceHero: View {
    let place: PlaceDetail

    var body: some View {
        Color.clear
            .frame(height: 400)
            .overlay {
                Image(place.photo)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .overlay(alignment: .bottom) {
                // Tall enough that the small region label sits on a dark part too: the photo is
                // all white walls at the bottom.
                LinearGradient(stops: [.init(color: .clear, location: 0),
                                       .init(color: .black.opacity(0.5), location: 0.45),
                                       .init(color: .black.opacity(0.7), location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 260)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.region.uppercased())
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(.white)
                    Text(place.name)
                        .font(.system(size: 48, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
    }
}

private struct PlaceDetails: View {
    let place: PlaceDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.orange)
                Text(place.rating, format: .number.precision(.fractionLength(1)))
                    .fontWeight(.semibold)
                Text("· \(place.reviewCount)")
                    .foregroundStyle(.supporting)
            }
            .font(.subheadline)

            Text(place.summary)
                .font(.body)

            HStack(spacing: 10) {
                ForEach(place.facts) { fact in
                    FactTile(fact: fact)
                }
            }

            Text("Highlights")
                .font(.title3.bold())
                .padding(.top, 4)

            ForEach(place.highlights) { highlight in
                HighlightRow(highlight: highlight)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
}

private struct FactTile: View {
    let fact: PlaceFact

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: fact.symbol)
                .foregroundStyle(.tint)
            Text(fact.value)
                .font(.headline)
            Text(fact.label)
                .font(.caption)
                .foregroundStyle(.supporting)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.fill.quaternary, in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}

private struct HighlightRow: View {
    let highlight: Highlight

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: highlight.symbol)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .background(.fill.quaternary, in: .rect(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(highlight.title)
                    .font(.headline)
                Text(highlight.detail)
                    .font(.subheadline)
                    .foregroundStyle(.supporting)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// One secondary and one primary action, side by side in one container.
private struct PlaceActions: View {
    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button {} label: {
                    Label("Add to Trip", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)

                Button {} label: {
                    Label("Directions", systemImage: "car.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            }
            .controlSize(.large)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}
