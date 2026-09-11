import Foundation

/// Thin abstraction over `UNUserNotificationCenter` so business logic and
/// tests never depend on the real notification system.
protocol NotificationScheduling: Sendable {
    func requestAuthorization() async -> Bool
    func schedule(_ reminder: PlannedReminder)
    func cancelReminder(projectID: UUID)
}
