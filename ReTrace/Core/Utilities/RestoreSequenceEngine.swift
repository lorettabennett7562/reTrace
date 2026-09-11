import Foundation

/// The core product invariant: Restore Mode is always the capture sequence
/// played back in reverse. Never persisted separately — always derived.
enum RestoreSequenceEngine {
    /// Returns steps sorted by capture order (ascending `orderIndex`).
    static func captureOrder(from steps: [RTStep]) -> [RTStep] {
        steps.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// Returns steps in the order the user must reverse them: last captured,
    /// first restored. Sorting (rather than assuming contiguous indices)
    /// keeps this safe even if a middle step was deleted.
    static func restoreOrder(from steps: [RTStep]) -> [RTStep] {
        steps.sorted { $0.orderIndex > $1.orderIndex }
    }

    /// Next order index to assign to a newly captured step.
    static func nextOrderIndex(for steps: [RTStep]) -> Int {
        (steps.map(\.orderIndex).max() ?? -1) + 1
    }
}
