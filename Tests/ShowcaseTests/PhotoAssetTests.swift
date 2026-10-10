import Testing
import UIKit
@testable import Showcase

@MainActor
struct PhotoAssetTests {
    nonisolated static let photos = ["kyoto", "santorini", "iceland-waterfall", "iceland-road", "new-york", "iceland-cabin"]

    @Test(arguments: photos)
    func photoAssetExists(name: String) {
        // TEMPORARY: the Kyoto photo has not been supplied yet. Delete this wrapper when it is.
        withKnownIssue("the Kyoto photo has not been supplied yet", isIntermittent: true) {
            #expect(UIImage(named: name) != nil, "missing image asset \(name)")
        } when: {
            name == "kyoto"
        }
    }

    @Test func sampleDataOnlyUsesKnownPhotos() {
        let used = SampleData.destinations.map(\.photo)
            + [SampleData.oia.photo, SampleData.ringRoad.photo, SampleData.booking.photo]
        #expect(Set(used).isSubset(of: Set(Self.photos)))
    }
}
