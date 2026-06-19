import SwiftUI

/// Page shell — flat canvas, optional big-title header, safe-area aware, content
/// capped + centered for iPad. Wrap screen content in this.
struct Screen<Content: View>: View {
    @Environment(\.theme) private var theme
    var title: String? = nil
    var subtitle: String? = nil
    var scroll: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            theme.colors.bg.ignoresSafeArea()
            Group {
                if scroll {
                    ScrollView { inner }
                } else {
                    inner
                }
            }
        }
    }

    private var inner: some View {
        VStack(alignment: .leading, spacing: Spacing.four) {
            if let title {
                VStack(alignment: .leading, spacing: Spacing.one) {
                    Text(title).textStyle(.h1, color: theme.colors.text)
                    if let subtitle {
                        Text(subtitle).textStyle(.body, color: theme.colors.textDim)
                    }
                }
            }
            content()
        }
        .padding(Spacing.three)
        .frame(maxWidth: MaxContentWidth)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Auth page shell — centered, big title, no tab chrome.
struct AuthScreen<Content: View>: View {
    @Environment(\.theme) private var theme
    var title: String
    var subtitle: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            theme.colors.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.four) {
                    VStack(alignment: .leading, spacing: Spacing.two) {
                        Text(title).textStyle(.display, color: theme.colors.text)
                        if let subtitle {
                            Text(subtitle).textStyle(.body, color: theme.colors.textDim)
                        }
                    }
                    .padding(.top, Spacing.six)
                    content()
                }
                .padding(Spacing.four)
                .frame(maxWidth: MaxContentWidth)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
