import CoreLocation
import MapKit
import SwiftUI

/// Every value the six screens show. Fixed strings: no `Date()`, no network.
enum SampleData {
    // MARK: Screen 1 · Explore (Kyoto, Higashiyama)

    static let kyotoCamera = MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 34.9998, longitude: 135.7822),
        distance: 2600, heading: 0, pitch: 55)

    static let kyotoPlaces: [NearbyPlace] = [
        NearbyPlace(id: "kiyomizu", name: "Kiyomizu-dera", category: "Temple",
                    symbol: "building.columns.fill", tint: .orange, distance: "0.4 km", rating: 4.8,
                    coordinate: CLLocationCoordinate2D(latitude: 34.994856, longitude: 135.785046)),
        NearbyPlace(id: "yasaka-pagoda", name: "Yasaka Pagoda", category: "Landmark",
                    symbol: "camera.fill", tint: .pink, distance: "0.6 km", rating: 4.7,
                    coordinate: CLLocationCoordinate2D(latitude: 34.998590, longitude: 135.779650)),
        NearbyPlace(id: "ninenzaka", name: "Ninenzaka", category: "Old street",
                    symbol: "figure.walk", tint: .teal, distance: "0.7 km", rating: 4.6,
                    coordinate: CLLocationCoordinate2D(latitude: 34.997900, longitude: 135.781300)),
        NearbyPlace(id: "kodaiji", name: "Kōdai-ji", category: "Temple and garden",
                    symbol: "leaf.fill", tint: .green, distance: "1.0 km", rating: 4.6,
                    coordinate: CLLocationCoordinate2D(latitude: 35.000830, longitude: 135.781250)),
        NearbyPlace(id: "yasaka-shrine", name: "Yasaka Shrine", category: "Shrine",
                    symbol: "sparkles", tint: .red, distance: "1.3 km", rating: 4.5,
                    coordinate: CLLocationCoordinate2D(latitude: 35.003660, longitude: 135.778550)),
    ]

    // MARK: Screen 2 · Place (Oia, Santorini)

    static let oia = PlaceDetail(
        name: "Oia",
        region: "Santorini, Greece",
        photo: "santorini",
        rating: 4.9,
        reviewCount: "2,184 reviews",
        summary: "A cliffside village of whitewashed houses and blue domes above the caldera, famous for the most photographed sunset in the Aegean.",
        facts: [
            PlaceFact(id: "season", label: "Best time", value: "May–Oct", symbol: "sun.max.fill"),
            PlaceFact(id: "sunset", label: "Sunset", value: "8:21 PM", symbol: "sunset.fill"),
            PlaceFact(id: "fira", label: "From Fira", value: "25 min", symbol: "car.fill"),
        ],
        highlights: [
            Highlight(id: "castle", title: "Castle of Oia", detail: "The classic sunset viewpoint",
                      symbol: "binoculars.fill"),
            Highlight(id: "ammoudi", title: "Ammoudi Bay", detail: "Fish tavernas at the water's edge",
                      symbol: "water.waves"),
            Highlight(id: "trail", title: "Fira–Oia trail", detail: "10 km along the caldera rim",
                      symbol: "figure.hiking"),
        ])

    // MARK: Screen 3 · Discover

    static let destinations: [Destination] = [
        Destination(id: "kyoto", name: "Kyoto", country: "Japan",
                    tagline: "Temples, tea houses and autumn maples",
                    length: "5 days", price: "from $1,240", photo: "kyoto"),
        Destination(id: "iceland", name: "Ring Road", country: "Iceland",
                    tagline: "Waterfalls, black beaches and glaciers",
                    length: "7 days", price: "from $1,890", photo: "iceland-waterfall"),
        Destination(id: "new-york", name: "New York", country: "United States",
                    tagline: "Rooftops, museums and late-night pizza",
                    length: "4 days", price: "from $980", photo: "new-york"),
        Destination(id: "santorini", name: "Santorini", country: "Greece",
                    tagline: "Blue domes above the caldera",
                    length: "4 days", price: "from $1,120", photo: "santorini"),
    ]

    // MARK: Screen 4 · Trip (Iceland Ring Road)

    static let ringRoad = Trip(
        name: "Ring Road",
        photo: "iceland-road",
        distance: "1,332 km",
        days: [
            TripDay(number: 1, title: "Reykjavík to Vík", stops: [
                TripStop(id: "1a", time: "09:00", name: "Pick up the car", detail: "Keflavík Airport", symbol: "car.fill"),
                TripStop(id: "1b", time: "12:30", name: "Seljalandsfoss", detail: "Walk behind the falls", symbol: "drop.fill"),
                TripStop(id: "1c", time: "15:00", name: "Skógafoss", detail: "Stairs to the top", symbol: "figure.hiking"),
            ]),
            TripDay(number: 2, title: "Vík to Höfn", stops: [
                TripStop(id: "2a", time: "09:30", name: "Reynisfjara", detail: "Black sand beach", symbol: "beach.umbrella.fill"),
                TripStop(id: "2b", time: "13:00", name: "Fjaðrárgljúfur", detail: "Canyon walk", symbol: "mountain.2.fill"),
                TripStop(id: "2c", time: "16:30", name: "Jökulsárlón", detail: "Glacier lagoon", symbol: "snowflake"),
            ]),
            TripDay(number: 3, title: "Höfn to Egilsstaðir", stops: [
                TripStop(id: "3a", time: "10:00", name: "Stokksnes", detail: "Vestrahorn viewpoint", symbol: "camera.fill"),
                TripStop(id: "3b", time: "13:30", name: "Djúpivogur", detail: "Harbour lunch", symbol: "fork.knife"),
                TripStop(id: "3c", time: "17:00", name: "Egilsstaðir", detail: "Check in", symbol: "bed.double.fill"),
            ]),
            TripDay(number: 4, title: "Egilsstaðir to Mývatn", stops: [
                TripStop(id: "4a", time: "09:00", name: "Dettifoss", detail: "Europe's most powerful falls", symbol: "drop.fill"),
                TripStop(id: "4b", time: "14:00", name: "Hverir", detail: "Geothermal field", symbol: "flame.fill"),
                TripStop(id: "4c", time: "18:00", name: "Mývatn Nature Baths", detail: "Evening soak", symbol: "figure.pool.swim"),
            ]),
            TripDay(number: 5, title: "Mývatn to Akureyri", stops: [
                TripStop(id: "5a", time: "10:00", name: "Goðafoss", detail: "Waterfall of the gods", symbol: "drop.fill"),
                TripStop(id: "5b", time: "13:00", name: "Akureyri", detail: "Botanical garden", symbol: "leaf.fill"),
                TripStop(id: "5c", time: "22:30", name: "Midnight sun", detail: "Golden light all evening", symbol: "sunset.fill"),
            ]),
            TripDay(number: 6, title: "Akureyri to Borgarnes", stops: [
                TripStop(id: "6a", time: "09:30", name: "Glaumbær", detail: "Turf farmhouses", symbol: "house.fill"),
                TripStop(id: "6b", time: "14:00", name: "Hraunfossar", detail: "Lava falls", symbol: "drop.fill"),
                TripStop(id: "6c", time: "17:30", name: "Borgarnes", detail: "Settlement Center", symbol: "building.columns.fill"),
            ]),
            TripDay(number: 7, title: "Borgarnes to Reykjavík", stops: [
                TripStop(id: "7a", time: "10:00", name: "Kirkjufell", detail: "Iconic mountain", symbol: "mountain.2.fill"),
                TripStop(id: "7b", time: "15:00", name: "Reykjavík", detail: "Hallgrímskirkja", symbol: "building.fill"),
                TripStop(id: "7c", time: "19:00", name: "Return the car", detail: "Keflavík Airport", symbol: "car.fill"),
            ]),
        ],
        stays: [
            Stay(id: "vik", name: "Black Sand Guesthouse, Vík", nights: "Night 1"),
            Stay(id: "hofn", name: "Glacier View Lodge, Höfn", nights: "Night 2"),
            Stay(id: "egilsstadir", name: "Lakeside Cabins, Egilsstaðir", nights: "Night 3"),
            Stay(id: "myvatn", name: "Crater Inn, Mývatn", nights: "Night 4"),
            Stay(id: "akureyri", name: "Harbour Rooms, Akureyri", nights: "Night 5"),
            Stay(id: "borgarnes", name: "Fjord House, Borgarnes", nights: "Night 6"),
        ],
        budget: [
            BudgetLine(id: "car", label: "Car rental", amount: 620),
            BudgetLine(id: "lodging", label: "Lodging", amount: 1_140),
            BudgetLine(id: "fuel", label: "Fuel", amount: 260),
            BudgetLine(id: "food", label: "Food", amount: 480),
        ])

    // MARK: Screen 5 · Navigation (New York)
    // Generated once on 2026-10-10 with MKDirections (driving, 6th Ave & W 42nd St →
    // Grand Army Plaza) and simplified with Douglas–Peucker. Steps: left onto Madison Ave
    // after 329 m, left onto E 60th St after 1,612 m, destination on the left after 317 m.

    static let route: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 40.752960, longitude: -73.983662),
        CLLocationCoordinate2D(latitude: 40.751524, longitude: -73.980234),
        CLLocationCoordinate2D(latitude: 40.764213, longitude: -73.970963),
        CLLocationCoordinate2D(latitude: 40.764781, longitude: -73.972334),
        CLLocationCoordinate2D(latitude: 40.764986, longitude: -73.972666),
        CLLocationCoordinate2D(latitude: 40.765107, longitude: -73.972973),
        CLLocationCoordinate2D(latitude: 40.765107, longitude: -73.973126),
        CLLocationCoordinate2D(latitude: 40.765035, longitude: -73.973276),
        CLLocationCoordinate2D(latitude: 40.764335, longitude: -73.973849),
    ]
    static let routeDestination = CLLocationCoordinate2D(latitude: 40.764335, longitude: -73.973849)
    /// 38% of the way up the Madison Avenue leg (route[1] → route[2]): 1,000 m to the turn.
    static let routePosition = CLLocationCoordinate2D(latitude: 40.756346, longitude: -73.976711)
    static let manhattanCamera = MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 40.7590, longitude: -73.9755),
        distance: 2400, heading: 29, pitch: 50)
    static let nextTurnDistance = "0.6 mi"
    static let nextTurnInstruction = "Turn left onto E 60th St"
    static let arrivalTime = "9:47"
    static let remainingTime = "6 min"
    static let remainingDistance = "0.8 mi"

    // MARK: Screen 6 · Booking (North Iceland)

    static let booking = Booking(
        lodge: "Fjordside Cottage",
        location: "North Iceland",
        photo: "iceland-cabin",
        rating: 4.9,
        reviewCount: "412 reviews",
        dates: "Aug 2 – 5",
        guests: "2 adults",
        room: "Entire cottage",
        nightlyRate: 340,
        nights: 3,
        fees: 58)
}
