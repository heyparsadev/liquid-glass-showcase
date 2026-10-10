import SwiftUI
import UIKit

extension ShapeStyle where Self == Color {
    /// Supporting text (subtitles, captions) on opaque content: softer than `.primary`, but 4.5:1
    /// or better in both appearances. The system `.secondary` measures 3.3:1 on the light grouped
    /// background. Not for glass: there the liquid-glass skill asks for the system's vibrant
    /// styles, so use `.primary` and carry the hierarchy with size and weight.
    static var supporting: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.88)
                : UIColor.black.withAlphaComponent(0.72)
        })
    }
}
