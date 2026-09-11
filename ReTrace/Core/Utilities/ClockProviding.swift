import Foundation

/// Injectable date source so business logic never reads `Date()` directly,
/// keeping calculations deterministic and testable.
protocol ClockProviding: Sendable {
    var now: Date { get }
}

struct SystemClock: ClockProviding {
    var now: Date { Date() }
}

struct FixedClock: ClockProviding {
    let fixedDate: Date
    var now: Date { fixedDate }
}
