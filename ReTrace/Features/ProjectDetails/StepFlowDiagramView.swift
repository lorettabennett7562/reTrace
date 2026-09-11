import SwiftUI

/// A photo-free way to review a project's sequence: every step becomes a
/// numbered block — icon, type, and note — connected top to bottom, whether
/// or not it has a picture attached.
struct StepFlowDiagramView: View {
    let steps: [RTStep]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                VStack(spacing: 0) {
                    FlowBlock(step: step, position: index + 1)
                    if index < steps.count - 1 {
                        Image(systemName: "arrow.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(RTColors.textTertiary)
                            .padding(.vertical, 2)
                    }
                }
            }
        }
    }
}

private struct FlowBlock: View {
    let step: RTStep
    let position: Int

    var body: some View {
        HStack(alignment: .top, spacing: RTSpacing.sm) {
            ZStack {
                Circle()
                    .fill(RTColors.surfaceSecondary)
                    .frame(width: 30, height: 30)
                Text("\(position)")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(RTColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: RTSpacing.xxs) {
                    Image(systemName: step.stepType.symbolName)
                        .foregroundStyle(RTColors.accent)
                    Text(step.displayTitle)
                        .font(RTTypography.cardTitle)
                }
                if let note = step.note, !note.isEmpty {
                    Text(note)
                        .font(RTTypography.secondary)
                        .foregroundStyle(RTColors.textSecondary)
                }
                if !step.parts.isEmpty {
                    Text(step.parts.map { "\($0.quantity)× \($0.name)" }.joined(separator: ", "))
                        .font(RTTypography.metadata)
                        .foregroundStyle(RTColors.textTertiary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(RTSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RTColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RTRadius.control, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RTRadius.control, style: .continuous)
                .strokeBorder(RTColors.border, lineWidth: 1)
        )
        .accessibilityIdentifier("diagram.step.\(step.id.uuidString)")
    }
}
