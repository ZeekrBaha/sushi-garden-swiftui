import SwiftUI

enum AppFont {
    static func sen(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "Sen-Bold" : "Sen-Regular", size: size)
    }
    /// SF Rounded for stepper glyphs — same round character as the original Mugesta.
    static func mugesta(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    // Semantic styles (sizes from Figma)
    static var price: Font { sen(19.3, bold: true) }
    static var productTitle: Font { sen(16.6, bold: true) }
    static var sectionHeader: Font { sen(15.8, bold: true) }
    static var weight: Font { sen(14.2) }
    static var tabLabel: Font { sen(11.8) }
}
