import SwiftUI

enum ButtonVariant {
    case primary    // solid ink fill, inverted label
    case secondary  // surfaceHigh + border
    case ghost      // accent text, no fill
    case danger     // dangerSoft fill + danger text
}

enum ButtonSize {
    case lg, md, sm

    var height: CGFloat {
        switch self {
        case .lg: return 54
        case .md: return 46
        case .sm: return 38
        }
    }

    var token: TextStyleToken {
        switch self {
        case .lg: return .title
        case .md: return .bodyStrong
        case .sm: return .small
        }
    }

    var hPadding: CGFloat {
        switch self {
        case .lg: return Spacing.four
        case .md: return Spacing.three
        case .sm: return Spacing.three
        }
    }
}

/// Pill button — solid, springy-but-not-spring (timed press scale). PayPal-clean.
struct AppButton: View {
    @Environment(\.theme) private var theme

    let title: String
    var variant: ButtonVariant = .primary
    var size: ButtonSize = .lg
    var icon: String? = nil
    var fullWidth: Bool = true
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    init(
        _ title: String,
        variant: ButtonVariant = .primary,
        size: ButtonSize = .lg,
        icon: String? = nil,
        fullWidth: Bool = true,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.icon = icon
        self.fullWidth = fullWidth
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            if variant == .primary || variant == .danger { Haptics.impact(.light) }
            action()
        }) {
            HStack(spacing: Spacing.two) {
                if isLoading {
                    ProgressView().tint(foreground)
                } else {
                    if let icon { Image(systemName: icon) }
                    Text(title)
                }
            }
            .textStyle(size.token, color: foreground)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.hPadding)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.pill)
                    .stroke(strokeColor, lineWidth: HairlineWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
            .opacity(isDisabled ? 0.5 : 1)
        }
        .buttonStyle(PressScaleStyle(scale: 0.98))
        .disabled(isDisabled || isLoading)
    }

    private var foreground: Color {
        switch variant {
        case .primary: return theme.colors.onAccent
        case .secondary: return theme.colors.text
        case .ghost: return theme.colors.accent
        case .danger: return theme.colors.danger
        }
    }

    private var background: Color {
        switch variant {
        case .primary: return theme.colors.accent
        case .secondary: return theme.colors.surfaceHigh
        case .ghost: return .clear
        case .danger: return theme.colors.dangerSoft
        }
    }

    private var strokeColor: Color {
        switch variant {
        case .secondary: return theme.colors.border
        default: return .clear
        }
    }
}
