import SwiftUI

/// Barely-there timed press scale (DESIGN.md §Motion: no springs, ~80ms in /
/// 120ms out). Used by buttons (0.98) and pressable cards (0.99).
struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.98

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(
                .easeOut(duration: configuration.isPressed ? 0.08 : 0.12),
                value: configuration.isPressed
            )
    }
}
