//
//  DesignTokens.swift
//  VlogNudge
//
//  6:3:1 Color System + ADHD-optimized design tokens.
//  Dominant 60% → backgrounds, canvas, status bar
//  Secondary 30% → cards, nav, headers, panels
//  Accent 10% → CTAs, icons, active states, progress
//

import SwiftUI

// MARK: - Color Palette

// Brand palette — Coral Red accent on Shadow Grey, with Porcelain text and
// Baltic Blue / Bright Gold as supporting colors. Coral Red matches the app icon.
enum VNColor {
    // Brand swatches
    static let porcelain  = Color(hex: "FDFFFC")
    static let balticBlue = Color(hex: "235789")
    static let coral      = Color(hex: "EF5350")
    static let flagRed    = Color(hex: "C1292E")
    static let brightGold = Color(hex: "F1D302")
    static let shadowGrey = Color(hex: "161925")

    // 60% — Dominant: main backgrounds, screens, canvas
    static let dominant = shadowGrey
    static let dominantLight = Color(hex: "1E2433")

    // 30% — Secondary: cards, navigation, headers, panels
    static let secondary = Color(hex: "212838")
    static let secondaryLight = Color(hex: "2B3346")

    // 10% — Accent: CTAs, active borders, icons, progress, links
    static let accent = coral
    static let accentDim = accent.opacity(0.15)
    static let accentGlow = accent.opacity(0.3)

    // Text hierarchy on the dark canvas (Porcelain)
    static let textPrimary = porcelain
    static let textSecondary = porcelain.opacity(0.6)
    static let textTertiary = porcelain.opacity(0.4)

    // Semantic colors
    static let success = balticBlue
    static let warning = brightGold
    static let destructive = flagRed

    // Supporting accents (available for highlights / secondary actions)
    static let highlight = brightGold
    static let secondaryAccent = balticBlue

    // Surface for elevated elements (sheets, overlays)
    static let surface = secondary
    static let surfaceElevated = secondaryLight
}

// MARK: - Typography Presets

enum VNFont {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
    static let subheadline = Font.system(size: 15, weight: .medium, design: .rounded)
    static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)
    static let heroNumber = Font.system(size: 48, weight: .heavy, design: .rounded)
    static let bigTime = Font.system(size: 44, weight: .bold, design: .rounded)
}

// MARK: - Spacing (8pt grid for ADHD-friendly rhythm)

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

// MARK: - Corner Radius

enum VNRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 999
}

// MARK: - Reusable Card Modifier

struct VNCardModifier: ViewModifier {
    var padding: CGFloat = VNSpacing.lg
    var cornerRadius: CGFloat = VNRadius.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(VNColor.secondary, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func vnCard(padding: CGFloat = VNSpacing.lg, cornerRadius: CGFloat = VNRadius.lg) -> some View {
        modifier(VNCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}


