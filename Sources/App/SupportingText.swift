import SwiftUI
import UIKit

extension ShapeStyle where Self == Color {
    /// Supporting text (subtitles, captions): softer than `.primary`, but 4.5:1 or better on
    /// glass in both appearances. The system `.secondary` measured 2.7–3.9:1 there.
    static var supporting: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.88)
                : UIColor.black.withAlphaComponent(0.72)
        })
    }
}
