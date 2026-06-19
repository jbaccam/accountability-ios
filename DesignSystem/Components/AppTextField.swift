import SwiftUI

/// Filled text field — label above, helper/error below, accent focus ring.
/// No Material outline. Port of components/ui/input.tsx.
struct AppTextField: View {
    @Environment(\.theme) private var theme
    @FocusState private var focused: Bool

    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var helper: String? = nil
    var error: String? = nil
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var submitLabel: SubmitLabel = .return
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.two) {
            if !label.isEmpty {
                Text(label).textStyle(.label, color: theme.colors.textDim)
            }

            HStack(spacing: Spacing.two) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(theme.colors.textFaint)
                }
                Group {
                    if isSecure {
                        SecureField("", text: $text, prompt: prompt)
                    } else {
                        TextField("", text: $text, prompt: prompt)
                    }
                }
                .focused($focused)
                .textStyle(.body, color: theme.colors.text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .submitLabel(submitLabel)
                .onSubmit { onSubmit?() }
            }
            .padding(.horizontal, Spacing.three)
            .frame(height: 50)
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

    private var prompt: Text {
        Text(placeholder).foregroundColor(theme.colors.textFaint)
    }

    private var ringColor: Color {
        if error != nil { return theme.colors.danger }
        return focused ? theme.colors.accent : theme.colors.border
    }
}
