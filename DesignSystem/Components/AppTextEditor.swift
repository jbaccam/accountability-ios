import SwiftUI

/// Multiline filled text input, styled to match AppTextField. Label above,
/// helper/error below, accent focus ring. For longer free-text (rules, notes).
struct AppTextEditor: View {
    @Environment(\.theme) private var theme
    @FocusState private var focused: Bool

    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var helper: String? = nil
    var error: String? = nil
    var minHeight: CGFloat = 96

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            if !label.isEmpty {
                Text(label).textStyle(.label, color: theme.colors.textDim)
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .textStyle(.body, color: theme.colors.textFaint)
                        .padding(.horizontal, Spacing.three)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .focused($focused)
                    .textStyle(.body, color: theme.colors.text)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, Spacing.two)
                    .padding(.vertical, Spacing.one)
                    .frame(minHeight: minHeight)
            }
            .background(theme.colors.surfaceAlt)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(ringColor, lineWidth: focused ? 2 : HairlineWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .animation(.easeOut(duration: 0.15), value: focused)

            if let error {
                Text(error).textStyle(.small, color: theme.colors.danger)
            } else if let helper {
                Text(helper).textStyle(.small, color: theme.colors.textFaint)
            }
        }
    }

    private var ringColor: Color {
        if error != nil { return theme.colors.danger }
        return focused ? theme.colors.accent : theme.colors.border
    }
}
