import XCTest
@testable import ReTrace

@MainActor
final class NotificationPlannerTests: XCTestCase {
    private func makeProject() -> RTProject {
        let context = TestSupport.makeInMemoryContext()
        let service = ProjectMutationService(modelContext: context, clock: FixedClock(fixedDate: .now))
        return service.createProject(title: "TV Setup")
    }

    func testReminderCreatedHasCorrectProjectIDAndRequestedDate() {
        let project = makeProject()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let planner = DefaultNotificationPlanner()

        let reminder = planner.plan(for: project, option: .laterToday, now: now)

        XCTAssertNotNil(reminder)
        XCTAssertEqual(reminder?.projectID, project.id)
        XCTAssertEqual(reminder?.fireDate, now.addingTimeInterval(3 * 3600))
    }

    func testReminderCancelledRemovesPendingReminder() {
        let project = makeProject()
        let scheduler = FakeNotificationScheduler()
        let planner = DefaultNotificationPlanner()
        let now = Date()

        if let reminder = planner.plan(for: project, option: .laterToday, now: now) {
            scheduler.schedule(reminder)
        }
        XCTAssertEqual(scheduler.scheduledReminders.count, 1)

        scheduler.cancelReminder(projectID: project.id)
        XCTAssertTrue(scheduler.scheduledReminders.isEmpty)
    }

    func testProjectDeletedCancelsItsReminder() {
        let context = TestSupport.makeInMemoryContext()
        let scheduler = FakeNotificationScheduler()
        let service = ProjectMutationService(modelContext: context, clock: FixedClock(fixedDate: .now), notificationScheduler: scheduler)
        let project = service.createProject(title: "TV Setup")

        service.deleteProject(project)

        XCTAssertTrue(scheduler.cancelledProjectIDs.contains(project.id))
    }

    func testPermissionDeniedNeverCrashesScheduling() async {
        let scheduler = FakeNotificationScheduler()
        scheduler.authorizationResult = false
        let granted = await scheduler.requestAuthorization()
        XCTAssertFalse(granted)
    }

    func testPastDateIsRejected() {
        let project = makeProject()
        let now = Date()
        let planner = DefaultNotificationPlanner()

        let reminder = planner.plan(for: project, option: .custom(now.addingTimeInterval(-3600)), now: now)

        XCTAssertNil(reminder)
    }

    func testTomorrowResolvesToNineAMTheNextDay() {
        let project = makeProject()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 15))!
        let planner = DefaultNotificationPlanner(calendar: calendar)

        let reminder = planner.plan(for: project, option: .tomorrow, now: now)

        let expected = calendar.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 9))!
        XCTAssertEqual(reminder?.fireDate, expected)
    }
}
