import Foundation
import Testing
@testable import Showcase

@MainActor
struct ScreenIDTests {
    @Test func launchValuesMapToScreens() {
        #expect(ScreenID(launchValue: 1) == .explore)
        #expect(ScreenID(launchValue: 2) == .place)
        #expect(ScreenID(launchValue: 3) == .discover)
        #expect(ScreenID(launchValue: 4) == .trip)
        #expect(ScreenID(launchValue: 5) == .navigation)
        #expect(ScreenID(launchValue: 6) == .booking)
    }

    @Test(arguments: [0, -1, 7, 99])
    func unknownLaunchValuesFallBackToExplore(value: Int) {
        #expect(ScreenID(launchValue: value) == .explore)
    }

    @Test func slugsAreTwoDigitIndexAndName() {
        #expect(ScreenID.explore.slug == "01-explore")
        #expect(ScreenID.booking.slug == "06-booking")
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
