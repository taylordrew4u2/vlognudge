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

enum VNColor {
    // 60% — Dominant: main backgrounds, screens, canvas
    static let dominant = Color(hex: "0F172A")
    static let dominantLight = Color(hex: "141D32")

    // 30% — Secondary: cards, navigation, headers, panels
    static let secondary = Color(hex: "1E2937")
    static let secondaryLight = Color(hex: "263344")

    // 10% — Accent: CTAs, active borders, icons, progress, links
    static let accent = Color(hex: "E8553A")
    static let accentDim = accent.opacity(0.15)
    static let accentGlow = accent.opacity(0.3)

    // Text hierarchy on dark backgrounds (WCAG AA compliant)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.38)

    // Semantic colors
    static let success = Color(hex: "22C55E")
    static let warning = Color(hex: "F59E0B")
    static let destructive = Color(hex: "EF4444")

    // Surface for elevated elements (sheets, overlays)
    static let surface = Color(hex: "1E2937")
    static let surfaceElevated = Color(hex: "263344")
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


