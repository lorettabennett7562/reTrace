import Foundation
import UserNotifications

/// Real `UNUserNotificationCenter`-backed scheduler. Never crashes or blocks
/// the app if permission is denied — scheduling is simply a no-op.
final class NotificationCoordinator: NotificationScheduling, @unchecked Sendable {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func schedule(_ reminder: PlannedReminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body

        let interval = max(1, reminder.fireDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    func cancelReminder(projectID: UUID) {
        let identifier = PlannedReminder.identifier(for: projectID)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
