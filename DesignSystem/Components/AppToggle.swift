import SwiftUI

/// Custom switch — ink track when on, knob slides once via timing (no bounce).
struct AppToggle: View {
    @Environment(\.theme) private var theme
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeOut(duration: 0.16)) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? theme.colors.accent : theme.colors.surfaceHigh)
                    .frame(width: 50, height: 30)
                Circle()
                    .fill(isOn ? theme.colors.onAccent : theme.colors.text)
                    .frame(width: 24, height: 24)
                    .padding(.horizontal, 3)
            }
        }
        .buttonStyle(.plain)
    }
}

/// A labeled toggle row used in forms/settings.
struct ToggleRow: View {
    @Environment(\.theme) private var theme
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Spacing.three) {
            VStack(alignment: .leading, spacing: Spacing.half) {
                Text(title).textStyle(.bodyStrong, color: theme.colors.text)
                if let subtitle {
                    Text(subtitle).textStyle(.small, color: theme.colors.textFaint)
                }
            }
            Spacer()
            AppToggle(isOn: $isOn)
        }
    }
}
