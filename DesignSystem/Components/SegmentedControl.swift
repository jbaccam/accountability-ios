import SwiftUI

/// iOS-style segmented control with a sliding ink thumb. Thumb slides once via
/// ease-out timing (no spring), per DESIGN.md.
struct SegmentedControl<Option: Hashable>: View {
    @Environment(\.theme) private var theme
    @Namespace private var thumb

    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Text(label(option))
                    .textStyle(.small, color: isSelected ? theme.colors.onAccent : theme.colors.textDim)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: Radius.sm)
                                .fill(theme.colors.accent)
                                .matchedGeometryEffect(id: "thumb", in: thumb)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.18)) { selection = option }
                    }
            }
        }
        .padding(Spacing.half)
        .background(theme.colors.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}
