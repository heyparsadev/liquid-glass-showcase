import SwiftUI

/// The screens in capture order. `rawValue` is the `-screen` launch argument. The seventh is
/// Discover scrolled down, which shows the lower cards.
enum ScreenID: Int, CaseIterable, Identifiable {
    case explore = 1, place, discover, trip, navigation, booking, discoverScrolled

    var id: Int { rawValue }

    /// What the `-screen N` launch argument asks for. A missing argument (UserDefaults returns 0)
    /// is `nil`: the app shows the launcher. Any other unknown value opens Explore.
    static func launch(_ value: Int) -> ScreenID? {
        value == 0 ? nil : ScreenID(rawValue: value) ?? .explore
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
        case .discoverScrolled: "discover-scrolled"
        }
        return (rawValue < 10 ? "0" : "") + "\(rawValue)-\(name)"
    }

    /// The launcher's row title.
    var title: String {
        switch self {
        case .explore: "Explore"
        case .place: "Place"
        case .discover: "Discover"
        case .trip: "Trip"
        case .navigation: "Navigation"
        case .booking: "Booking"
        case .discoverScrolled: "Discover, scrolled"
        }
    }

    /// The launcher's row subtitle.
    var summary: String {
        switch self {
        case .explore: "Kyoto · satellite map, glass controls, sheet"
        case .place: "Oia · photo hero, glass toolbar, prominent action"
        case .discover: "Photo cards and the iOS 27 prominent Trips tab"
        case .trip: "Iceland Ring Road · iOS 27 toolbar and tabs picker"
        case .navigation: "New York · glass banner and trip bar over a route"
        case .booking: "A task sheet over a photo"
        case .discoverScrolled: "The lower cards, with New York"
        }
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
        case .discoverScrolled: DiscoverScreen(scrollsTo: "new-york")
        }
    }
}
