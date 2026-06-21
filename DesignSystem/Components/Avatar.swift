import SwiftUI

/// Initials avatar; ink fill when it's "you". Loads a remote photo when present.
struct Avatar: View {
    @Environment(\.theme) private var theme
    let name: String
    var url: String? = nil
    var size: CGFloat = 40
    var isYou: Bool = false

    var body: some View {
        Group {
            if let url, let parsed = URL(string: url) {
                AsyncImage(url: parsed) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        initials
                    }
                }
            } else {
                initials
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(theme.colors.border, lineWidth: HairlineWidth))
        .accessibilityLabel(isYou ? "Your avatar" : "\(name), avatar")
    }

    private var initials: some View {
        ZStack {
            (isYou ? theme.colors.accent : theme.colors.surfaceHigh)
            Text(initialsText)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(isYou ? theme.colors.onAccent : theme.colors.text)
        }
    }

    private var initialsText: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init).joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }
}
