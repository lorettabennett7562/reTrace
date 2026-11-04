import SwiftUI

/// Puts two blocks side by side once the container is wide enough, otherwise stacks them.
/// Keyed on the container's measured width (not idiom or size class) so it follows
/// resizable windows and fold/unfold on iPhone Duo.
struct AdaptiveSplit<Leading: View, Trailing: View>: View {
    var breakpoint: CGFloat = 640
    var spacing: CGFloat = RTSpacing.lg
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    @State private var width: CGFloat = 0

    var body: some View {
        Group {
            if width >= breakpoint {
                HStack(alignment: .top, spacing: spacing) {
                    leading.frame(maxWidth: .infinity)
                    trailing.frame(maxWidth: .infinity)
                }
            } else {
                VStack(alignment: .leading, spacing: spacing) {
                    leading
                    trailing
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }
}

/// Wraps children onto new rows at their natural width, so labels never break mid-word.
struct FlowLayout: Layout {
    var spacing: CGFloat = RTSpacing.xs

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, usedWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            usedWidth = max(usedWidth, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: usedWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
