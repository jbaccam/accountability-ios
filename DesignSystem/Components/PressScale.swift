import SwiftUI

/// Barely-there timed press scale (DESIGN.md §Motion: no springs, ~80ms in /
/// 120ms out). Used by buttons (0.98) and pressable cards (0.99). Honors the
/// system Reduce Motion setting.
struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.98

    func makeBody(configuration: Configuration) -> some View {
        PressScaleBody(configuration: configuration, scale: scale)
    }

    private struct PressScaleBody: View {
        let configuration: Configuration
        let scale: CGFloat
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
                .animation(
                    reduceMotion ? nil
                        : .easeOut(duration: configuration.isPressed ? 0.08 : 0.12),
                    value: configuration.isPressed
                )
        }
    }
}
