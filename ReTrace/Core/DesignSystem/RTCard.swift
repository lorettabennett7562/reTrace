import SwiftUI

/// The standard quiet, minimal-shadow card container used across ReTrace.
struct RTCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(RTSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RTColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: RTRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RTRadius.card, style: .continuous)
                    .strokeBorder(RTColors.border, lineWidth: 1)
            )
    }
}

/// Constrains content to a comfortable reading width on large iPad screens.
struct ReadableWidthContainer<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            content
                .frame(maxWidth: RTLayout.maxReadableWidth)
            Spacer(minLength: 0)
        }
    }
}

/// Small pill used to communicate project/status state via a label, never by
/// color alone.
struct RTStatusBadge: View {
    let text: String
    var tint: Color = RTColors.textSecondary

    var body: some View {
        Text(text)
            .font(RTTypography.metadata.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, RTSpacing.xs)
            .padding(.vertical, 4)
            .background(tint.opacity(0.14))
            .clipShape(Capsule())
    }
}
