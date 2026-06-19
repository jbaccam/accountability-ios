import SwiftUI

/// Slim progress bar — the quiet hero for standings (not big-number stat tiles).
struct SlimProgressBar: View {
    @Environment(\.theme) private var theme
    /// 0...1
    let progress: Double
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(theme.colors.track)
                Capsule()
                    .fill(theme.colors.accent)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
                    .animation(.easeOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
}

/// Lightweight toast (Snackbar replacement). Drive with `.toast($message)`.
struct ToastView: View {
    @Environment(\.theme) private var theme
    let message: String

    var body: some View {
        Text(message)
            .textStyle(.small, color: theme.colors.bg)
            .padding(.horizontal, Spacing.three)
            .padding(.vertical, Spacing.two)
            .background(theme.colors.text)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
            .padding(.bottom, Spacing.five)
    }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View {
        overlay(alignment: .bottom) {
            if let msg = message.wrappedValue {
                ToastView(message: msg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2.5))
                        withAnimation(.easeOut(duration: 0.2)) { message.wrappedValue = nil }
                    }
            }
        }
        .animation(.easeOut(duration: 0.2), value: message.wrappedValue)
    }
}

/// Centered spinner for full-screen loading.
struct LoadingState: View {
    @Environment(\.theme) private var theme
    var body: some View {
        VStack { ProgressView().tint(theme.colors.accent) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Empty/zero state with an icon, title, and optional message.
struct EmptyState: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: Spacing.two) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(theme.colors.textFaint)
            Text(title).textStyle(.h3, color: theme.colors.text)
            if let message {
                Text(message)
                    .textStyle(.body, color: theme.colors.textDim)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.six)
    }
}

/// A simple labeled row (key/value) used in detail screens.
struct InfoRow: View {
    @Environment(\.theme) private var theme
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).textStyle(.body, color: theme.colors.textDim)
            Spacer()
            Text(value).textStyle(.bodyStrong, color: theme.colors.text)
        }
    }
}
