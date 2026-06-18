import SwiftUI

enum CardTone {
    case `default`, flat, accent, success, warning, danger
}

/// The surface primitive. Hairline border, radius xl. No nested cards.
struct Card<Content: View>: View {
    @Environment(\.theme) private var theme

    var tone: CardTone = .default
    var padding: CGFloat = Spacing.three
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl)
                    .stroke(stroke, lineWidth: HairlineWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
    }

    private var fill: Color {
        switch tone {
        case .default: return theme.colors.surface
        case .flat: return theme.colors.bg
        case .accent: return theme.colors.accentSoft
        case .success: return theme.colors.successSoft
        case .warning: return theme.colors.warningSoft
        case .danger: return theme.colors.dangerSoft
        }
    }

    private var stroke: Color {
        switch tone {
        case .accent: return theme.colors.accent.opacity(0.25)
        case .success: return theme.colors.success.opacity(0.3)
        case .warning: return theme.colors.warning.opacity(0.3)
        case .danger: return theme.colors.danger.opacity(0.3)
        default: return theme.colors.border
        }
    }
}

/// A card that responds to taps with a timed 0.99 press scale.
struct PressableCard<Content: View>: View {
    var tone: CardTone = .default
    var padding: CGFloat = Spacing.three
    let action: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        Button(action: action) {
            Card(tone: tone, padding: padding, content: content)
        }
        .buttonStyle(PressScaleStyle(scale: 0.99))
    }
}
