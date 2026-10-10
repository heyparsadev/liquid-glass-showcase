import SwiftUI
import Testing
import UIKit
@testable import Showcase

/// Supporting text (subtitles, captions) has to reach 4.5:1 on glass. The system `.secondary`
/// measured 2.7–3.9:1 there. The backgrounds below are the palest light glass and the brightest
/// dark glass measured in the captured screenshots.
@MainActor
struct SupportingTextTests {
    typealias RGB = (r: Double, g: Double, b: Double)

    @Test func meetsAAOnTheLightestLightGlass() {
        #expect(contrast(of: .supporting, over: (235, 235, 235), style: .light) >= 4.5)
    }

    @Test func meetsAAOnTheBrightestDarkGlass() {
        #expect(contrast(of: .supporting, over: (83, 104, 132), style: .dark) >= 4.5)
    }

    @Test func staysSofterThanPrimarySoTheHierarchyReads() {
        let light: RGB = (235, 235, 235), dark: RGB = (83, 104, 132)
        #expect(contrast(of: .supporting, over: light, style: .light) < contrast(of: .primary, over: light, style: .light))
        #expect(contrast(of: .supporting, over: dark, style: .dark) < contrast(of: .primary, over: dark, style: .dark))
    }

    // MARK: WCAG contrast

    private func resolved(_ color: Color, over background: RGB, style: UIUserInterfaceStyle) -> RGB {
        let ui = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r * 255 * a + background.r * (1 - a),
                g * 255 * a + background.g * (1 - a),
                b * 255 * a + background.b * (1 - a))
    }

    private func luminance(_ c: RGB) -> Double {
        func linear(_ v: Double) -> Double {
            let s = v / 255
            return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b)
    }

    private func contrast(of color: Color, over background: RGB, style: UIUserInterfaceStyle) -> Double {
        let text = luminance(resolved(color, over: background, style: style))
        let back = luminance(background)
        return (max(text, back) + 0.05) / (min(text, back) + 0.05)
    }
}
