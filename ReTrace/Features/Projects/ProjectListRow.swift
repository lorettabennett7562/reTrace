import SwiftUI

struct ProjectListRow: View {
    let project: RTProject

    var body: some View {
        RTCard {
            VStack(alignment: .leading, spacing: RTSpacing.xs) {
                HStack {
                    Text(project.title)
                        .font(RTTypography.cardTitle)
                        .foregroundStyle(RTColors.textPrimary)
                    Spacer()
                    if project.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(RTColors.warning)
                            .accessibilityLabel("Favorite")
                    }
                }

                HStack(spacing: RTSpacing.sm) {
                    Label("\(project.steps.count)", systemImage: "square.stack.3d.up")
                    Label("\(project.parts.count)", systemImage: "shippingbox")
                }
                .font(RTTypography.metadata)
                .foregroundStyle(RTColors.textSecondary)

                HStack {
                    RTStatusBadge(text: project.status.displayName, tint: statusTint)
                    Spacer()
                    Text(project.updatedAt, style: .relative)
                        .font(RTTypography.metadata)
                        .foregroundStyle(RTColors.textTertiary)
                }
            }
        }
        .accessibilityIdentifier("project.card.\(project.id.uuidString)")
    }

    private var statusTint: Color {
        switch project.status {
        case .completed: return RTColors.success
        case .disassembled, .restoring: return RTColors.warning
        case .archived: return RTColors.textTertiary
        case .draft, .capturing: return RTColors.accentSecondary
        }
    }
}
