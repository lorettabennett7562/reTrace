import Foundation
import SwiftData
@testable import ReTrace

enum TestSupport {
    @MainActor
    static func makeInMemoryContext() -> ModelContext {
        let container = ModelContainerFactory.makeContainer(inMemory: true)
        return ModelContext(container)
    }
}

/// In-memory media store rooted at a fresh temporary directory per instance,
/// so `MediaStorageTests` never touches the real filesystem location.
final class TemporaryMediaStore {
    let store: FileSystemMediaStore
    let rootDirectory: URL

    init() {
        rootDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReTraceTests-\(UUID().uuidString)", isDirectory: true)
        store = FileSystemMediaStore(rootDirectory: rootDirectory)
    }

    func cleanUp() {
        try? FileManager.default.removeItem(at: rootDirectory)
    }
}

final class FakeNotificationScheduler: NotificationScheduling, @unchecked Sendable {
    private(set) var scheduledReminders: [PlannedReminder] = []
    private(set) var cancelledProjectIDs: [UUID] = []
    var authorizationResult = true

    func requestAuthorization() async -> Bool { authorizationResult }

    func schedule(_ reminder: PlannedReminder) {
        scheduledReminders.append(reminder)
    }

    func cancelReminder(projectID: UUID) {
        cancelledProjectIDs.append(projectID)
        scheduledReminders.removeAll { $0.projectID == projectID }
    }
}
