import SwiftUI

enum RTTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let projectTitle = Font.title2.bold()
    static let sectionTitle = Font.title3.weight(.semibold)
    static let cardTitle = Font.headline
    static let body = Font.body
    static let secondary = Font.subheadline
    static let metadata = Font.caption
}

enum RTSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40

    static func screenHorizontalPadding(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 24 : 16
    }
}

enum RTRadius {
    static let card: CGFloat = 18
    static let control: CGFloat = 14
}

enum RTLayout {
    /// Keeps content readable on wide iPad screens instead of stretching
    /// edge-to-edge.
    static let maxReadableWidth: CGFloat = 1000
}
