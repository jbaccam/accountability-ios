import SwiftUI

struct ConfirmDialogConfig: Identifiable {
    let id = UUID()
    var title: String
    var message: String
    var confirmLabel: String = "Confirm"
    var cancelLabel: String = "Cancel"
    var destructive: Bool = false
    var onConfirm: () -> Void
}

/// Custom centered modal (not a Material/UIKit alert). Crossfades in over a scrim.
struct ConfirmDialog: View {
    @Environment(\.theme) private var theme
    let config: ConfirmDialogConfig
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            theme.colors.scrim
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            Card {
                VStack(alignment: .leading, spacing: Spacing.three) {
                    Text(config.title).textStyle(.h3, color: theme.colors.text)
                    Text(config.message).textStyle(.body, color: theme.colors.textDim)
                    HStack(spacing: Spacing.two) {
                        AppButton(config.cancelLabel, variant: .secondary, size: .md) {
                            dismiss()
                        }
                        AppButton(
                            config.confirmLabel,
                            variant: config.destructive ? .danger : .primary,
                            size: .md
                        ) {
                            config.onConfirm()
                            dismiss()
                        }
                    }
                }
            }
            .padding(Spacing.four)
            .frame(maxWidth: 420)
        }
        .transition(.opacity)
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.15)) { isPresented = false }
    }
}

extension View {
    /// Present a centered confirm dialog driven by an optional config binding.
    func confirmDialog(_ config: Binding<ConfirmDialogConfig?>) -> some View {
        overlay {
            if let cfg = config.wrappedValue {
                ConfirmDialog(
                    config: cfg,
                    isPresented: Binding(
                        get: { config.wrappedValue != nil },
                        set: { if !$0 { config.wrappedValue = nil } }
                    )
                )
            }
        }
    }
}
