import SwiftUI

struct ReminderSheet: View {
    let project: RTProject

    @Environment(AppContainer.self) private var container
    @Environment(\.dismiss) private var dismiss

    @State private var customDate = Date().addingTimeInterval(3600)
    @State private var confirmationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(String(localized: "Later Today")) {
                        schedule(.laterToday)
                    }
                    .accessibilityIdentifier("reminder.laterTodayButton")

                    Button(String(localized: "Tomorrow")) {
                        schedule(.tomorrow)
                    }
                    .accessibilityIdentifier("reminder.tomorrowButton")
                }

                Section(String(localized: "Custom")) {
                    DatePicker(String(localized: "Date & Time"), selection: $customDate, in: Date()...)
                    Button(String(localized: "Schedule")) {
                        schedule(.custom(customDate))
                    }
                    .accessibilityIdentifier("reminder.scheduleCustomButton")
                }

                if let confirmationMessage {
                    Section {
                        Label(confirmationMessage, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(RTColors.success)
                    }
                }
            }
            .navigationTitle("Restore Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Close")) { dismiss() }
                }
            }
        }
    }

    private func schedule(_ option: ReminderOption) {
        Task {
            let granted = await container.notificationScheduler.requestAuthorization()
            guard granted else {
                confirmationMessage = String(localized: "Notifications are turned off for ReTrace.")
                return
            }
            guard let reminder = container.notificationPlanner.plan(for: project, option: option, now: container.clock.now) else {
                confirmationMessage = String(localized: "Please choose a time in the future.")
                return
            }
            container.notificationScheduler.schedule(reminder)
            confirmationMessage = String(localized: "Reminder set.")
        }
    }
}
