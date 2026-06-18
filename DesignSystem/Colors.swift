import SwiftUI

extension Color {
    /// Hex string -> Color. Supports "#RRGGBB" / "RRGGBB".
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    /// Black/white translucent helper for the rgba(...) tokens.
    static func ink(_ white: Double, _ opacity: Double) -> Color {
        Color(.sRGB, red: white, green: white, blue: white, opacity: opacity)
    }

    static func rgba(_ r: Double, _ g: Double, _ b: Double, _ a: Double) -> Color {
        Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
    }
}

/// The custom token set every screen reads (port of `theme.ui` in theme.ts).
/// Values are verbatim from DESIGN.md / theme.ts.
struct AppColors {
    let scheme: ColorScheme

    // Canvas + surfaces
    let bg: Color
    let bgElevated: Color
    let surface: Color
    let surfaceAlt: Color
    let surfaceHigh: Color
    let border: Color
    let borderStrong: Color
    // Text
    let text: Color
    let textDim: Color
    let textFaint: Color
    let onAccent: Color
    // Accent (ink — black in light, white in dark)
    let accent: Color
    let accentBright: Color
    let accentGlow: Color
    let accentSoft: Color
    // Status
    let success: Color
    let successSoft: Color
    let onSuccess: Color
    let warning: Color
    let warningSoft: Color
    let onWarning: Color
    let danger: Color
    let dangerSoft: Color
    let onDanger: Color
    let info: Color
    let infoSoft: Color
    // Misc
    let scrim: Color
    let track: Color

    static let dark = AppColors(
        scheme: .dark,
        bg: Color(hex: "#0A0A0B"),
        bgElevated: Color(hex: "#141416"),
        surface: Color(hex: "#161618"),
        surfaceAlt: Color(hex: "#1F1F22"),
        surfaceHigh: Color(hex: "#2A2A2E"),
        border: Color(hex: "#2A2A2E"),
        borderStrong: Color(hex: "#3A3A40"),
        text: Color(hex: "#FFFFFF"),
        textDim: Color(hex: "#A6A6AD"),
        textFaint: Color(hex: "#8E8E95"),
        onAccent: Color(hex: "#0A0A0B"),
        accent: Color(hex: "#FFFFFF"),
        accentBright: Color(hex: "#E2E2E5"),
        accentGlow: .ink(1, 0.12),
        accentSoft: .ink(1, 0.10),
        success: Color(hex: "#34C77B"),
        successSoft: .rgba(52, 199, 123, 0.14),
        onSuccess: Color(hex: "#052012"),
        warning: Color(hex: "#E0A33A"),
        warningSoft: .rgba(224, 163, 58, 0.14),
        onWarning: Color(hex: "#241700"),
        danger: Color(hex: "#F46B7A"),
        dangerSoft: .rgba(244, 107, 122, 0.14),
        onDanger: Color(hex: "#2A0006"),
        info: Color(hex: "#5B8DEF"),
        infoSoft: .rgba(91, 141, 239, 0.14),
        scrim: .ink(0, 0.64),
        track: Color(hex: "#26262A")
    )

    static let light = AppColors(
        scheme: .light,
        bg: Color(hex: "#F6F6F7"),
        bgElevated: Color(hex: "#FFFFFF"),
        surface: Color(hex: "#FFFFFF"),
        surfaceAlt: Color(hex: "#F1F1F3"),
        surfaceHigh: Color(hex: "#EAEAEC"),
        border: Color(hex: "#E3E3E6"),
        borderStrong: Color(hex: "#CACAD0"),
        text: Color(hex: "#0B0B0C"),
        textDim: Color(hex: "#5C5C62"),
        textFaint: Color(hex: "#6E6E74"),
        onAccent: Color(hex: "#FFFFFF"),
        accent: Color(hex: "#0B0B0C"),
        accentBright: Color(hex: "#2A2A2E"),
        accentGlow: .ink(0, 0.10),
        accentSoft: .ink(0, 0.06),
        success: Color(hex: "#1A7F4B"),
        successSoft: .rgba(26, 127, 75, 0.10),
        onSuccess: Color(hex: "#FFFFFF"),
        warning: Color(hex: "#9A6700"),
        warningSoft: .rgba(154, 103, 0, 0.10),
        onWarning: Color(hex: "#FFFFFF"),
        danger: Color(hex: "#C5283D"),
        dangerSoft: .rgba(197, 40, 61, 0.09),
        onDanger: Color(hex: "#FFFFFF"),
        info: Color(hex: "#2D6CDF"),
        infoSoft: .rgba(45, 108, 223, 0.09),
        scrim: .ink(0, 0.42),
        track: Color(hex: "#E8E8EA")
    )
}
