import SwiftUI

/// The theme handed down through the environment. Colors switch on the system
/// color scheme; dark is primary, light is a first-class peer.
struct Theme: Equatable {
    var colors: AppColors

    static func resolve(_ scheme: ColorScheme) -> Theme {
        Theme(colors: scheme == .dark ? .dark : .light)
    }
}

extension AppColors: Equatable {
    static func == (lhs: AppColors, rhs: AppColors) -> Bool {
        lhs.scheme == rhs.scheme
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme(colors: .dark)
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

/// Injects the right Theme for the current color scheme and paints the canvas.
struct ThemedRoot<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder var content: () -> Content

    var body: some View {
        let theme = Theme.resolve(scheme)
        content()
            .environment(\.theme, theme)
            .tint(theme.colors.accent)
            .background(theme.colors.bg.ignoresSafeArea())
    }
}
