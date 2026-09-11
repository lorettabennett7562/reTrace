import Foundation

enum ReminderOption: Equatable, Sendable {
    case laterToday
    case tomorrow
    case custom(Date)
}

struct PlannedReminder: Equatable, Sendable {
    let identifier: String
    let projectID: UUID
    let title: String
    let body: String
    let fireDate: Date

    static func identifier(for projectID: UUID) -> String {
        "project-reminder-\(projectID.uuidString)"
    }
}

protocol NotificationPlanning: Sendable {
    /// Builds the reminder to schedule, or `nil` if the resulting date would
    /// be in the past (rejected rather than silently firing immediately).
    func plan(for project: RTProject, option: ReminderOption, now: Date) -> PlannedReminder?
}

struct DefaultNotificationPlanner: NotificationPlanning {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func plan(for project: RTProject, option: ReminderOption, now: Date) -> PlannedReminder? {
        guard let fireDate = resolvedDate(for: option, now: now), fireDate > now else { return nil }

        return PlannedReminder(
            identifier: PlannedReminder.identifier(for: project.id),
            projectID: project.id,
            title: String(localized: "Restore reminder"),
            body: String(format: String(localized: "Remind me to restore this: %@"), project.title),
            fireDate: fireDate
        )
    }

    private func resolvedDate(for option: ReminderOption, now: Date) -> Date? {
        switch option {
        case .laterToday:
            return calendar.date(byAdding: .hour, value: 3, to: now)
        case .tomorrow:
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
            var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 9
            components.minute = 0
            return calendar.date(from: components)
        case .custom(let date):
            return date
        }
    }
}
