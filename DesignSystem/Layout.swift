import CoreGraphics

/// 4pt-grid spacing scale (port of theme.ts `Spacing`).
enum Spacing {
    static let half: CGFloat = 2
    static let one: CGFloat = 4
    static let two: CGFloat = 8
    static let three: CGFloat = 16
    static let four: CGFloat = 24
    static let five: CGFloat = 32
    static let six: CGFloat = 64
}

/// Corner radii — tight and clean (port of theme.ts `Radii`).
enum Radius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 22
    static let pill: CGFloat = 999
}

/// Content column cap so iPad layouts don't stretch edge-to-edge.
let MaxContentWidth: CGFloat = 640

/// Hairline border width.
let HairlineWidth: CGFloat = 1
