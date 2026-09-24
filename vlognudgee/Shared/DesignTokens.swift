import SwiftUI
import UIKit

// Field Notes: warm paper, deep teal and restrained terracotta.
// Dynamic UIColors keep native bars and SwiftUI surfaces in the same appearance.
enum VNColor {
    private static func adaptive(_ light: String, _ dark: String) -> Color {
        let day = UIColor(Color(hex: light))
        let night = UIColor(Color(hex: dark))
        return Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? night : day })
    }

    static let porcelain = Color(hex: "F5F2EA")
    static let balticBlue = Color(hex: "17665B")
    static let flagRed = Color(hex: "B53D38")
    static let brightGold = Color(hex: "C96B43")
    static let shadowGrey = Color(hex: "182F2C")

    static let dominant = adaptive("F5F2EA", "101F1C")
    static let dominantLight = adaptive("EBEDE5", "172B26")
    static let secondary = adaptive("FFFFFF", "1B302A")
    static let secondaryLight = adaptive("E4EBE3", "29443B")
    static let accent = adaptive("17665B", "94D8BF")
    static let onAccent = adaptive("FFFFFF", "102D24")
    static let accentDim = accent.opacity(0.10)
    static let accentGlow = accent.opacity(0.20)
    static let textPrimary = adaptive("182F2C", "F5F2EA")
    static let textSecondary = adaptive("536660", "B7C9BF")
    static let textTertiary = adaptive("5B6B64", "A0B5AA")
    static let border = adaptive("D8DDD5", "365046")
    static let success = accent
    static let warning = adaptive("91501F", "F1BB80")
    static let destructive = adaptive("B53D38", "FF9B93")
    static let highlight = adaptive("A24E2B", "EAA37F")
    static let secondaryAccent = accent
    static let surface = secondary
    static let surfaceElevated = secondaryLight
}

enum VNFont {
    static let largeTitle = Font.system(.largeTitle, design: .serif).weight(.semibold)
    static let title = Font.system(.title, design: .serif).weight(.semibold)
    static let title2 = Font.system(.title2, design: .serif).weight(.semibold)
    static let title3 = Font.system(.title3).weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let callout = Font.callout
    static let subheadline = Font.subheadline.weight(.medium)
    static let footnote = Font.footnote
    static let caption = Font.caption.weight(.medium)
    static let caption2 = Font.caption2
    static let heroNumber = Font.system(.largeTitle, design: .serif).weight(.bold)
    static let bigTime = Font.system(.largeTitle, design: .rounded).weight(.semibold)
}

enum VNSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 48
}

enum VNRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 28
    static let full: CGFloat = 999
}

struct VNCardModifier: ViewModifier {
    var padding: CGFloat = VNSpacing.lg
    var cornerRadius: CGFloat = VNRadius.lg
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(VNColor.secondary, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(VNColor.border.opacity(0.6), lineWidth: 1)
            }
    }
}

extension View {
    func vnCard(padding: CGFloat = VNSpacing.lg, cornerRadius: CGFloat = VNRadius.lg) -> some View {
        modifier(VNCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}
