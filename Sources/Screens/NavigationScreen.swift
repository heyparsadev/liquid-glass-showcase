import MapKit
import SwiftUI

/// Screen 5 · Turn-by-turn (New York).
/// Functional layer: the maneuver banner, the trip status capsule, and the End button,
/// separate glass shapes in one container, never stacked. Content layer: the map,
/// the route, the destination marker, and the location puck.
struct NavigationScreen: View {
    var body: some View {
        ZStack {
            Map(initialPosition: .camera(SampleData.manhattanCamera)) {
                MapPolyline(coordinates: SampleData.route)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                Marker("Grand Army Plaza", systemImage: "flag.checkered", coordinate: SampleData.routeDestination)
                    .tint(.red)
                Annotation("You", coordinate: SampleData.routePosition, anchor: .center) {
                    LocationPuck()
                }
                .annotationTitles(.hidden)
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .mapControlVisibility(.hidden)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ManeuverBanner()
                Spacer()
                TripBar()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }
}

private struct ManeuverBanner: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "arrow.turn.up.left")
                .font(.system(size: 36, weight: .bold))
                .frame(width: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text(SampleData.nextTurnDistance)
                    .font(.title.bold())
                    .monospacedDigit()
                Text(SampleData.nextTurnInstruction)
                    .font(.headline)
                    .foregroundStyle(.supporting)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: .rect(cornerRadius: 32))
        .accessibilityElement(children: .combine)
    }
}

/// Trip status and End: two glass shapes side by side in one container.
private struct TripBar: View {
    var body: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 22) {
                    stat(SampleData.arrivalTime, caption: "arrival")
                    stat(SampleData.remainingTime, caption: "left")
                    stat(SampleData.remainingDistance, caption: "to go")
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: .capsule)
                .accessibilityElement(children: .combine)

                Button {} label: {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.bold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .tint(.red)
                .accessibilityLabel("End Route")
            }
        }
    }

    private func stat(_ value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
            Text(caption)
                .font(.caption)
                .foregroundStyle(.supporting)
        }
    }
}

private struct LocationPuck: View {
    var body: some View {
        Circle()
            .fill(.blue)
            .frame(width: 22, height: 22)
            .overlay(Circle().stroke(.white, lineWidth: 4))
            .shadow(radius: 4)
            .accessibilityLabel("Your location")
    }
}
