import SwiftUI

/// Screen 6 · Booking (North Iceland).
/// Functional layer: the system sheet with Cancel and the one prominent Reserve (a task
/// sheet). Content layer: the photo, the lodge title, and the form rows.
struct BookingScreen: View {
    @State private var detent: PresentationDetent = .medium
    private let booking = SampleData.booking

    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .overlay {
                    // The house sits just under the middle of the photo, which the half-height
                    // sheet would cover. Scale about the bottom edge to lift it into view.
                    Image(booking.photo)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(1.42, anchor: .bottom)
                }
                .overlay(alignment: .top) {
                    // Keeps the white title readable wherever the photo is bright.
                    LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 300)
                }
                .clipped()
                .ignoresSafeArea()

            SheetScrim()

            LodgeTitle(booking: booking)
        }
        .sheet(isPresented: .constant(true)) {
            BookingSheet(booking: booking)
                .presentationDetents([.medium, .large], selection: $detent)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .interactiveDismissDisabled()
        }
    }
}

private struct LodgeTitle: View {
    let booking: Booking
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 40.0

    var body: some View {
        VStack(spacing: 6) {
            Text(booking.location.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.2)
            Text(booking.lodge)
                .font(.system(size: titleSize, weight: .bold, design: .serif))
            Label {
                Text("\(booking.rating, format: .number.precision(.fractionLength(1))) · \(booking.reviewCount)")
            } icon: {
                Image(systemName: "star.fill")
            }
            .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.45), radius: 12)
        .padding(.top, 24)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct BookingSheet: View {
    let booking: Booking

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    row("Dates", booking.dates)
                    row("Guests", booking.guests)
                    row("Room", booking.room)
                }
                Section {
                    row("\(dollars(booking.nightlyRate)) × \(booking.nights) nights", dollars(booking.roomTotal))
                    row("Taxes and fees", dollars(booking.fees))
                    LabeledContent {
                        Text(dollars(booking.total))
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    } label: {
                        Text("Total")
                            .fontWeight(.semibold)
                    }
                } header: {
                    Text("Price details")
                        .foregroundStyle(Color.primary)
                }
            }
            .scrollContentBackground(.hidden)
            .listSectionSpacing(.compact)
            .environment(\.defaultMinListRowHeight, 38)
            .contentMargins(.top, 8, for: .scrollContent)
            .navigationTitle("Your Stay")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {}
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {} label: {
                        // In dark mode the toolbar draws this label black (4.0:1 on the accent).
                        Text("Reserve").foregroundStyle(.white)
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        LabeledContent(label) {
            Text(value)
                .foregroundStyle(.primary)
        }
    }

    private func dollars(_ amount: Int) -> String {
        amount.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}
