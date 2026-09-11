import SwiftUI

/// Central semantic color palette — the "gray mix" visual language. Feature
/// views must reference these tokens instead of hardcoding RGB values, so
/// Light/Dark Mode stay consistent and state is never communicated by shade
/// alone.
enum RTColors {
    static let background = Color("Background", bundle: .main)
    static let backgroundElevated = Color("BackgroundElevated", bundle: .main)
    static let surface = Color("Surface", bundle: .main)
    static let surfaceSecondary = Color("SurfaceSecondary", bundle: .main)
    static let surfacePressed = Color("SurfacePressed", bundle: .main)

    static let border = Color("Border", bundle: .main)
    static let divider = Color("Divider", bundle: .main)

    static let textPrimary = Color("TextPrimary", bundle: .main)
    static let textSecondary = Color("TextSecondary", bundle: .main)
    static let textTertiary = Color("TextTertiary", bundle: .main)

    static let accent = Color("AccentColor", bundle: .main)
    static let accentSecondary = Color("AccentSecondary", bundle: .main)

    static let success = Color("SuccessColor", bundle: .main)
    static let warning = Color("WarningColor", bundle: .main)
    static let danger = Color("DangerColor", bundle: .main)
}
