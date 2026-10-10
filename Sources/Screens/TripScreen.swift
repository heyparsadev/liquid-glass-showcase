import SwiftUI

/// Screen 4 · Trip (Iceland Ring Road).
/// Functional layer: the navigation bar with the iOS 27 pinned item, visibility
/// priority, and overflow menu, plus the `.tabs` picker. Content layer: the header and list.
struct TripScreen: View {
    @State private var section: TripSection = .itinerary
    private let trip = SampleData.ringRoad

    var body: some View {
        NavigationStack {
            List {
                TripHeader(trip: trip)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                Picker("Section", selection: $section) {
                    ForEach(TripSection.allCases) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.tabs)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                switch section {
                case .itinerary:
                    ForEach(trip.days) { day in
                        Section {
                            ForEach(day.stops) { stop in
                                StopRow(stop: stop)
                            }
                        } header: {
                            Text("Day \(day.number) · \(day.title)")
                                .foregroundStyle(.supporting)
                        }
                    }
                case .stays:
                    Section("Where you sleep") {
                        ForEach(trip.stays) { stay in
                            LabeledContent {
                                Text(stay.nights)
                            } label: {
                                Label(stay.name, systemImage: "bed.double.fill")
                            }
                        }
                    }
                case .budget:
                    Section("Estimated cost") {
                        ForEach(trip.budget) { line in
                            LabeledContent(line.label,
                                           value: line.amount.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                        }
                    }
                }
            }
            .navigationTitle(trip.name)
            .navigationSubtitle("Iceland · Jul 8–14")
            .toolbar {
                ToolbarItem(placement: .topBarPinnedTrailing) {
                    Button("Share Trip", systemImage: "square.and.arrow.up") {}
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Stop", systemImage: "plus") {}
                }
                .visibilityPriority(.high)
            }
            .toolbarOverflowMenu {
                Button("Rename Trip", systemImage: "pencil") {}
                Button("Duplicate Trip", systemImage: "plus.square.on.square") {}
                Button("Add to Calendar", systemImage: "calendar.badge.plus") {}
            }
        }
    }
}

private struct TripHeader: View {
    let trip: Trip

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 210)
                .overlay {
                    Image(trip.photo)
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(.rect(cornerRadius: 24))
                .accessibilityHidden(true)
            HStack {
                stat("\(trip.days.count)", caption: "days")
                Divider().frame(height: 28)
                stat(trip.distance, caption: "driving")
                Divider().frame(height: 28)
                stat("\(trip.days.flatMap(\.stops).count)", caption: "stops")
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func stat(_ value: String, caption: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .monospacedDigit()
            Text(caption)
                .font(.caption)
                .foregroundStyle(.supporting)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct StopRow: View {
    let stop: TripStop

    var body: some View {
        HStack(spacing: 14) {
            Text(stop.time)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.supporting)
                .frame(width: 48, alignment: .leading)
            Image(systemName: stop.symbol)
                .foregroundStyle(.tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(stop.name)
                    .font(.headline)
                Text(stop.detail)
                    .font(.subheadline)
                    .foregroundStyle(.supporting)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
