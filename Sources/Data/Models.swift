import CoreLocation
import SwiftUI

struct NearbyPlace: Identifiable {
    let id: String
    let name: String
    let category: String
    let symbol: String
    let tint: Color
    let distance: String
    let rating: Double
    let coordinate: CLLocationCoordinate2D
}

struct PlaceFact: Identifiable {
    let id: String
    let label: String
    let value: String
    let symbol: String
}

struct Highlight: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
}

struct PlaceDetail {
    let name: String
    let region: String
    let photo: String
    let rating: Double
    let reviewCount: String
    let summary: String
    let facts: [PlaceFact]
    let highlights: [Highlight]
}

struct Destination: Identifiable {
    let id: String
    let name: String
    let country: String
    let tagline: String
    let length: String
    let price: String
    let photo: String
}

struct TripStop: Identifiable {
    let id: String
    let time: String
    let name: String
    let detail: String
    let symbol: String
}

struct TripDay: Identifiable {
    let number: Int
    let title: String
    let stops: [TripStop]
    var id: Int { number }
}

struct Stay: Identifiable {
    let id: String
    let name: String
    let nights: String
}

struct BudgetLine: Identifiable {
    let id: String
    let label: String
    let amount: Int          // US dollars
}

struct Trip {
    let name: String
    let photo: String
    let distance: String
    let days: [TripDay]
    let stays: [Stay]
    let budget: [BudgetLine]
}

enum TripSection: String, CaseIterable, Identifiable {
    case itinerary, stays, budget
    var id: Self { self }
    var title: String { rawValue.capitalized }
}

struct Booking {
    let lodge: String
    let location: String
    let photo: String
    let rating: Double
    let reviewCount: String
    let dates: String
    let guests: String
    let room: String
    let nightlyRate: Int     // US dollars
    let nights: Int
    let fees: Int            // US dollars
    var roomTotal: Int { nightlyRate * nights }
    var total: Int { roomTotal + fees }
}
