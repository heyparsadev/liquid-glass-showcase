import Testing
import UIKit
@testable import Showcase

/// Prominent glass buttons carry a white label on the accent color. The system blue gives only
/// 3.2-3.5:1 there, so the app ships its own accent, #0066CC.
@MainActor
struct AccentColorTests {
    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func whiteLabelOnTheAccentColorMeetsAA(style: UIUserInterfaceStyle) throws {
        let accent = try #require(UIColor(named: "AccentColor"), "AccentColor asset is missing")
        let resolved = accent.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(a == 1)
        #expect(1.05 / (luminance(r, g, b) + 0.05) >= 4.5)
    }

    nonisolated static func linear(_ v: CGFloat) -> CGFloat {
        v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }

    private func luminance(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGFloat {
        0.2126 * Self.linear(r) + 0.7152 * Self.linear(g) + 0.0722 * Self.linear(b)
    }
}
