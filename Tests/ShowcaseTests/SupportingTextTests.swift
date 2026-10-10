import SwiftUI
import Testing
import UIKit
@testable import Showcase

/// Supporting text (subtitles, captions) on opaque content has to reach 4.5:1. The system
/// `.secondary` measures 3.3:1 on the light grouped background. On glass the style is not used:
/// the skill asks for the system's vibrant styles there. The backgrounds below are the system
/// backgrounds this style sits on in the captured screens.
@MainActor
struct SupportingTextTests {
    typealias RGB = (r: Double, g: Double, b: Double)

    private let lightBackgrounds: [RGB] = [(255, 255, 255), (242, 242, 247)]
    private let darkBackgrounds: [RGB] = [(0, 0, 0), (28, 28, 30)]

    @Test func meetsAAOnTheLightBackgrounds() {
        for background in lightBackgrounds {
            #expect(contrast(of: .supporting, over: background, style: .light) >= 4.5, "\(background)")
        }
    }

    @Test func meetsAAOnTheDarkBackgrounds() {
        for background in darkBackgrounds {
            #expect(contrast(of: .supporting, over: background, style: .dark) >= 4.5, "\(background)")
        }
    }

    @Test func staysSofterThanPrimarySoTheHierarchyReads() {
        for (background, style) in lightBackgrounds.map({ ($0, UIUserInterfaceStyle.light) })
                                 + darkBackgrounds.map({ ($0, UIUserInterfaceStyle.dark) }) {
            #expect(contrast(of: .supporting, over: background, style: style)
                    < contrast(of: .primary, over: background, style: style), "\(background)")
        }
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
