import SwiftUI

struct RTPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RTTypography.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, RTSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(RTColors.accent.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: RTRadius.control, style: .continuous))
    }
}

struct RTSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RTTypography.body.weight(.semibold))
            .foregroundStyle(RTColors.textPrimary)
            .padding(.vertical, RTSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? RTColors.surfacePressed : RTColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: RTRadius.control, style: .continuous))
    }
}

struct RTDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RTTypography.body.weight(.semibold))
            .foregroundStyle(RTColors.danger)
            .padding(.vertical, RTSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(RTColors.danger.opacity(configuration.isPressed ? 0.2 : 0.12))
            .clipShape(RoundedRectangle(cornerRadius: RTRadius.control, style: .continuous))
    }
}

extension ButtonStyle where Self == RTPrimaryButtonStyle {
    static var rtPrimary: RTPrimaryButtonStyle { RTPrimaryButtonStyle() }
}

extension ButtonStyle where Self == RTSecondaryButtonStyle {
    static var rtSecondary: RTSecondaryButtonStyle { RTSecondaryButtonStyle() }
}

extension ButtonStyle where Self == RTDestructiveButtonStyle {
    static var rtDestructive: RTDestructiveButtonStyle { RTDestructiveButtonStyle() }
}

/// A filter/chip control used across timelines and pickers.
struct RTFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RTTypography.secondary.weight(.medium))
                .padding(.horizontal, RTSpacing.sm)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? Color.white : RTColors.textPrimary)
                .background(isSelected ? RTColors.accent : RTColors.surfaceSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
