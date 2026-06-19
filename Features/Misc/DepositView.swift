import SwiftUI

/// Add simulated practice funds. Port of deposit.tsx. The balance is play money —
/// nothing is charged, held, or withdrawable — so the copy leans hard on that.
/// Pushed inside a NavTab stack; pops itself after a successful top-up.
struct DepositView: View {
    @Environment(\.theme) private var theme
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    private let presets: [Double] = [10, 25, 50, 100]
    private let maxDeposit: Double = 10_000

    @State private var amountText = "50"
    @State private var error: String?
    @State private var toast: String?
    @State private var isSubmitting = false

    private var amount: Double { Format.parseMoney(amountText) }
    private var balance: Double { session.profile?.simulatedBalance ?? 0 }
    private var isInvalid: Bool { amount <= 0 || amount > maxDeposit }

    var body: some View {
        Screen(title: "Add funds") {
            balanceCard
            presetRow
            amountField

            AppButton(
                "Add \(Format.money(isInvalid ? 0 : amount))",
                icon: "plus",
                isLoading: isSubmitting,
                isDisabled: isSubmitting || isInvalid,
                action: submit
            )

            Text(Copy.simulatedBalanceNote)
                .textStyle(.small, color: theme.colors.textFaint)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
    }

    // MARK: - Balance

    private var balanceCard: some View {
        Card(tone: .flat) {
            VStack(alignment: .leading, spacing: Spacing.one) {
                Text(Copy.simulatedBalanceLabel)
                    .textStyle(.label, color: theme.colors.textFaint)
                Text(Format.money(balance))
                    .textStyle(.stat, color: theme.colors.text)
                HStack(spacing: 4) {
                    Text("New balance after this top-up:")
                        .textStyle(.small, color: theme.colors.textDim)
                    Text(Format.money(isInvalid ? balance : balance + amount))
                        .textStyle(.bodyStrong, color: isInvalid ? theme.colors.textDim : theme.colors.success)
                }
            }
        }
    }

    // MARK: - Presets

    private var presetRow: some View {
        HStack(spacing: Spacing.two) {
            ForEach(presets, id: \.self) { preset in
                presetButton(preset)
            }
        }
    }

    private func presetButton(_ preset: Double) -> some View {
        let active = amount == preset
        return Button {
            amountText = String(Int(preset))
            error = nil
        } label: {
            Text(Format.money(preset))
                .textStyle(.title, color: active ? theme.colors.onAccent : theme.colors.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.three)
                .background(active ? theme.colors.accent : theme.colors.surfaceAlt)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(active ? theme.colors.accent : theme.colors.border, lineWidth: HairlineWidth)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(PressScaleStyle(scale: 0.98))
    }

    // MARK: - Amount

    private var amountField: some View {
        AppTextField(
            label: "Amount",
            text: $amountText,
            placeholder: "0",
            helper: "Practice funds only — added instantly to your simulated balance.",
            error: error ?? (amount > maxDeposit ? "Single top-ups are capped at \(Format.money(maxDeposit))." : nil),
            keyboard: .decimalPad
        )
        .onChange(of: amountText) { error = nil }
    }

    // MARK: - Actions

    private func submit() {
        guard !isInvalid, !isSubmitting else { return }
        isSubmitting = true
        error = nil
        let value = amount
        Task {
            defer { isSubmitting = false }
            do {
                _ = try await ProfileService.simulatedDeposit(amount: value)
                await session.refreshProfile()
                toast = "Added \(Format.money(value)) in practice funds."
                try? await Task.sleep(for: .seconds(0.6))
                dismiss()
            } catch {
                self.error = Format.errorMessage(error)
            }
        }
    }
}
