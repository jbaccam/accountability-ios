import SwiftUI

// Weight-based type scale on system SF (port of DESIGN.md typography + text.tsx).
// No display font. Numeric styles use tabular figures.

enum TextStyleToken {
    case display     // 34 / 800
    case stat        // 40 / 800, tabular
    case h1          // 28 / 700
    case h2          // 22 / 700
    case h3          // 18 / 600
    case title       // 16 / 600
    case body        // 15 / 400
    case bodyStrong  // 15 / 600
    case small       // 13 / 400
    case label       // 12 / 600 uppercase, tracked
    case caption     // 11 / 400
    case mono        // 15 / 500 tabular (numbers)

    var size: CGFloat {
        switch self {
        case .display: return 34
        case .stat: return 40
        case .h1: return 28
        case .h2: return 22
        case .h3: return 18
        case .title: return 16
        case .body, .bodyStrong, .mono: return 15
        case .small: return 13
        case .label: return 12
        case .caption: return 11
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display, .stat: return .heavy
        case .h1, .h2: return .bold
        case .h3, .title, .bodyStrong, .label: return .semibold
        case .mono: return .medium
        case .body, .small, .caption: return .regular
        }
    }

    var lineSpacing: CGFloat {
        switch self {
        case .display: return 6
        case .stat: return 6
        case .h1: return 6
        case .h2: return 6
        case .h3: return 6
        case .title: return 6
        case .body, .bodyStrong: return 7
        case .small: return 6
        case .label: return 2
        case .caption: return 4
        case .mono: return 7
        }
    }

    var tracking: CGFloat {
        switch self {
        case .display, .stat, .h1, .h2: return -0.5 // tight negative on headings
        case .label: return 0.8                      // light tracking, uppercase
        default: return 0
        }
    }

    var uppercase: Bool { self == .label }
    var monospacedDigits: Bool { self == .stat || self == .mono }
}

private struct TextStyleModifier: ViewModifier {
    let token: TextStyleToken
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: token.size, weight: token.weight))
            .modifier(MonoDigits(on: token.monospacedDigits))
            .tracking(token.tracking)
            .lineSpacing(token.lineSpacing)
            .foregroundStyle(color)
            .textCase(token.uppercase ? .uppercase : nil)
    }
}

private struct MonoDigits: ViewModifier {
    let on: Bool
    func body(content: Content) -> some View {
        if on { content.monospacedDigit() } else { content }
    }
}

extension View {
    /// Apply a token text style with an explicit color.
    func textStyle(_ token: TextStyleToken, color: Color) -> some View {
        modifier(TextStyleModifier(token: token, color: color))
    }
}
