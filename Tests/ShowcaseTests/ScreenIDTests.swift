import Foundation
import Testing
@testable import Showcase

@MainActor
struct ScreenIDTests {
    @Test func launchValuesMapToScreens() {
        #expect(ScreenID.launch(1) == .explore)
        #expect(ScreenID.launch(2) == .place)
        #expect(ScreenID.launch(3) == .discover)
        #expect(ScreenID.launch(4) == .trip)
        #expect(ScreenID.launch(5) == .navigation)
        #expect(ScreenID.launch(6) == .booking)
        #expect(ScreenID.launch(7) == .discoverScrolled)
    }

    @Test func aMissingLaunchValueOpensTheLauncher() {
        // UserDefaults returns 0 when there is no `-screen` argument.
        #expect(ScreenID.launch(0) == nil)
    }

    @Test(arguments: [-1, 8, 99])
    func unknownLaunchValuesFallBackToExplore(value: Int) {
        #expect(ScreenID.launch(value) == .explore)
    }

    @Test func everyScreenHasATitleAndASummaryForTheLauncher() {
        for screen in ScreenID.allCases {
            #expect(!screen.title.isEmpty, "\(screen)")
            #expect(!screen.summary.isEmpty, "\(screen)")
        }
        #expect(Set(ScreenID.allCases.map(\.title)).count == ScreenID.allCases.count)
    }

    @Test func slugsAreTwoDigitIndexAndName() {
        #expect(ScreenID.explore.slug == "01-explore")
        #expect(ScreenID.booking.slug == "06-booking")
        #expect(ScreenID.discoverScrolled.slug == "07-discover-scrolled")
    }

    @Test func slugsMatchTheCaptureList() throws {
        let list = URL(filePath: #filePath)            // …/Tests/ShowcaseTests/ScreenIDTests.swift
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "scripts/screens.txt")
        let slugs = try String(contentsOf: list, encoding: .utf8)
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
        #expect(slugs == ScreenID.allCases.map(\.slug))
    }
}
