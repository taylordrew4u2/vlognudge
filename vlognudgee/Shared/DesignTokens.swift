import SwiftUI
import UIKit

// Social creator: camera-ready pink, coral, crisp white and editorial ink.
// Dynamic UIColors keep native bars and SwiftUI surfaces consistent in both appearances.
enum VNColor {
    private static func adaptive(_ light: String, _ dark: String) -> Color {
        let day = UIColor(Color(hex: light))
        let night = UIColor(Color(hex: dark))
        return Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? night : day })
    }

    static let porcelain = Color(hex: "FFF7F9")
    static let balticBlue = Color(hex: "D81B60")
    static let flagRed = Color(hex: "FF3D6E")
    static let brightGold = Color(hex: "FF8A4C")
    static let shadowGrey = Color(hex: "171217")

    static let dominant = adaptive("FFF7F9", "120E12")
    static let dominantLight = adaptive("FFF0F4", "1B151B")
    static let secondary = adaptive("FFFFFF", "211A21")
    static let secondaryLight = adaptive("FFE5EC", "30242B")
    static let accent = adaptive("D81B60", "FF6FA3")
    static let onAccent = adaptive("FFFFFF", "1A0A10")
    static let accentDim = accent.opacity(0.10)
    static let accentGlow = accent.opacity(0.22)
    static let textPrimary = adaptive("171217", "FFF7F9")
    static let textSecondary = adaptive("66545D", "D8C4CC")
    static let textTertiary = adaptive("7A6670", "BDA7B0")
    static let border = adaptive("F0D4DC", "49343E")
    static let success = adaptive("16845B", "56D6A0")
    static let warning = adaptive("A64B00", "FFB36B")
    static let destructive = adaptive("C51F3A", "FF7A8E")
    static let highlight = adaptive("E64A3B", "FF8A74")
    static let secondaryAccent = adaptive("1473E6", "6CB2FF")
    static let surface = secondary
    static let surfaceElevated = secondaryLight
}

enum VNFont {
    static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let title = Font.system(.title, design: .rounded).weight(.bold)
    static let title2 = Font.system(.title2, design: .rounded).weight(.bold)
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

// MARK: - Hero surfaces & motion

enum VNGradient {
    /// Bold pink-to-coral wash used behind creator-focused hero cards and CTAs.
    static let hero = LinearGradient(
        colors: [VNColor.balticBlue, VNColor.flagRed],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Sunset coral treatment for the primary record action.
    static let record = LinearGradient(
        colors: [VNColor.flagRed, VNColor.brightGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Springy press feedback for large tappable surfaces.
struct VNPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == VNPressableStyle {
    static var vnPressable: VNPressableStyle { VNPressableStyle() }
}

/// Gradient-filled hero card with white foreground.
struct VNHeroCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(VNSpacing.xxl)
            .foregroundStyle(.white)
            .background(VNGradient.hero, in: RoundedRectangle(cornerRadius: VNRadius.xl))
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(VNColor.brightGold.opacity(0.35))
                    .frame(width: 140, height: 140)
                    .blur(radius: 40)
                    .offset(x: 30, y: -40)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: VNRadius.xl))
            .shadow(color: VNColor.shadowGrey.opacity(0.25), radius: 18, y: 10)
    }
}

extension View {
    func vnHeroCard() -> some View {
        modifier(VNHeroCardModifier())
    }
}

/// Soft breathing ring used behind the record button.
struct VNPulse: View {
    var color: Color
    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: VNRadius.lg)
            .stroke(color.opacity(animate ? 0 : 0.5), lineWidth: 2)
            .scaleEffect(animate ? 1.08 : 1)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
            .allowsHitTesting(false)
    }
}

/// Circular progress ring with a gradient stroke.
struct VNProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(colors: [VNColor.brightGold, .white, VNColor.brightGold], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
    }
}
