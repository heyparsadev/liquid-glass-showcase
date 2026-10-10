import CoreLocation
import Testing
@testable import Showcase

@MainActor
struct SampleDataTests {
    @Test func kyotoPlacesSitInHigashiyama() {
        #expect(SampleData.kyotoPlaces.count == 5)
        for place in SampleData.kyotoPlaces {
            #expect((34.98...35.01).contains(place.coordinate.latitude), "\(place.name)")
            #expect((135.77...135.79).contains(place.coordinate.longitude), "\(place.name)")
        }
    }

    @Test func routeStaysInMidtownManhattanAndEndsAtTheDestination() {
        #expect(SampleData.route.count == 9)
        for point in SampleData.route {
            #expect((40.75...40.77).contains(point.latitude))
            #expect((-73.99 ... -73.96).contains(point.longitude))
        }
        let last = SampleData.route[SampleData.route.count - 1]
        #expect(last.latitude == SampleData.routeDestination.latitude)
        #expect(last.longitude == SampleData.routeDestination.longitude)
    }

    @Test func positionLiesOnTheMadisonAvenueLeg() {
        let a = SampleData.route[1], b = SampleData.route[2], p = SampleData.routePosition
        let cross = (b.longitude - a.longitude) * (p.latitude - a.latitude)
                  - (b.latitude - a.latitude) * (p.longitude - a.longitude)
        #expect(abs(cross) < 1e-7)
        #expect((a.latitude...b.latitude).contains(p.latitude))
    }

    @Test func tripHasSevenDaysOfThreeStops() {
        #expect(SampleData.ringRoad.days.map(\.number) == Array(1...7))
        #expect(SampleData.ringRoad.days.allSatisfy { $0.stops.count == 3 })
    }

    @Test func identifiersAreUnique() {
        let stopIDs = SampleData.ringRoad.days.flatMap(\.stops).map(\.id)
        #expect(Set(stopIDs).count == stopIDs.count)
        let destinationIDs = SampleData.destinations.map(\.id)
        #expect(Set(destinationIDs).count == destinationIDs.count)
        let placeIDs = SampleData.kyotoPlaces.map(\.id)
        #expect(Set(placeIDs).count == placeIDs.count)
    }

    @Test func bookingTotalsAddUp() {
        #expect(SampleData.booking.roomTotal == 1_020)
        #expect(SampleData.booking.total == 1_078)
    }

    @Test func budgetAddsUpToTwentyFiveHundred() {
        #expect(SampleData.ringRoad.budget.map(\.amount).reduce(0, +) == 2_500)
    }
}
