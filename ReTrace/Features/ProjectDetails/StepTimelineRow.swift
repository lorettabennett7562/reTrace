import SwiftUI

struct StepTimelineRow: View {
    let step: RTStep
    let position: Int

    var body: some View {
        HStack(alignment: .top, spacing: RTSpacing.sm) {
            thumbnail
            VStack(alignment: .leading, spacing: 2) {
                Text("\(position). \(step.displayTitle)")
                    .font(RTTypography.cardTitle)
                if let note = step.note, !note.isEmpty {
                    Text(note)
                        .font(RTTypography.secondary)
                        .foregroundStyle(RTColors.textSecondary)
                        .lineLimit(2)
                }
                if !step.parts.isEmpty {
                    Label("\(step.parts.count)", systemImage: "shippingbox")
                        .font(RTTypography.metadata)
                        .foregroundStyle(RTColors.textTertiary)
                }
            }
            Spacer()
        }
        .accessibilityIdentifier("step.card.\(step.id.uuidString)")
    }

    @ViewBuilder
    private var thumbnail: some View {
        RTStoredImage(path: step.thumbnailPath ?? step.imagePath) {
            RoundedRectangle(cornerRadius: RTRadius.control, style: .continuous)
                .fill(RTColors.surfaceSecondary)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(RTColors.textTertiary)
                }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: RTRadius.control, style: .continuous))
    }
}
