import SwiftUI

/// The six screens in capture order. `rawValue` is the `-screen` launch argument.
enum ScreenID: Int, CaseIterable {
    case explore = 1, place, discover, trip, navigation, booking

    /// Missing (UserDefaults returns 0) or unknown values open Explore.
    init(launchValue: Int) {
        self = ScreenID(rawValue: launchValue) ?? .explore
    }

    /// The screenshot file stem, e.g. "01-explore". Must match scripts/screens.txt.
    var slug: String {
        let name = switch self {
        case .explore: "explore"
        case .place: "place"
        case .discover: "discover"
        case .trip: "trip"
        case .navigation: "navigation"
        case .booking: "booking"
        }
        return (rawValue < 10 ? "0" : "") + "\(rawValue)-\(name)"
    }

    @ViewBuilder
    var view: some View {
        switch self {
        case .explore: ExploreScreen()
        case .place: PlaceScreen()
        case .discover: DiscoverScreen()
        case .trip: TripScreen()
        case .navigation: NavigationScreen()
        case .booking: BookingScreen()
        }
    }
}
