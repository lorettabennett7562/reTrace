import SwiftData
import XCTest
@testable import ReTrace

@MainActor
final class ProjectDeletionTests: XCTestCase {
    func testDeletingAProjectRemovesStepsPartsConnectionsAndMedia() throws {
        let context = TestSupport.makeInMemoryContext()
        let mediaStore = TemporaryMediaStore()
        defer { mediaStore.cleanUp() }
        let notificationScheduler = FakeNotificationScheduler()

        let service = ProjectMutationService(
            modelContext: context,
            clock: FixedClock(fixedDate: .now),
            mediaStore: mediaStore.store,
            notificationScheduler: notificationScheduler
        )

        let project = service.createProject(title: "TV Setup")
        let mediaID = UUID()
        let imagePath = try mediaStore.store.saveOriginal(Data([0x01]), projectID: project.id, mediaID: mediaID)
        let thumbPath = try mediaStore.store.saveThumbnail(Data([0x02]), projectID: project.id, mediaID: mediaID)

        service.addStep(to: project, stepType: .reference, imagePath: imagePath, thumbnailPath: thumbPath)
        service.addPart(to: project, name: "Screw", quantity: 4)
        try service.addConnection(to: project, fromLabel: "HDMI Cable", toLabel: "TV HDMI 2")

        let planner = DefaultNotificationPlanner()
        if let reminder = planner.plan(for: project, option: .tomorrow, now: .now) {
            notificationScheduler.schedule(reminder)
        }

        let projectID = project.id
        service.deleteProject(project)
        try context.save()

        XCTAssertTrue(try context.fetch(FetchDescriptor<RTProject>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<RTStep>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<RTPart>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<RTConnection>()).isEmpty)

        XCTAssertNil(mediaStore.store.loadData(atRelativePath: imagePath))
        XCTAssertNil(mediaStore.store.loadData(atRelativePath: thumbPath))
        XCTAssertTrue(notificationScheduler.cancelledProjectIDs.contains(projectID))
    }

    func testDeletingAProjectWithNoChildRecordsDoesNotCrash() {
        let context = TestSupport.makeInMemoryContext()
        let service = ProjectMutationService(modelContext: context, clock: FixedClock(fixedDate: .now))
        let project = service.createProject(title: "Empty Project")
        service.deleteProject(project)
        XCTAssertTrue((try? context.fetch(FetchDescriptor<RTProject>()))?.isEmpty ?? false)
    }
}
