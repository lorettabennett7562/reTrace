import SwiftData
import XCTest
@testable import ReTrace

@MainActor
final class ConnectionTests: XCTestCase {
    private func makeService() -> (ProjectMutationService, RTProject) {
        let context = TestSupport.makeInMemoryContext()
        let service = ProjectMutationService(modelContext: context, clock: FixedClock(fixedDate: .now))
        let project = service.createProject(title: "TV Setup")
        return (service, project)
    }

    func testConnectionIsSavedAndAssociatedWithProject() throws {
        let (service, project) = makeService()
        let connection = try service.addConnection(to: project, fromLabel: "HDMI Cable", toLabel: "TV HDMI 2")
        XCTAssertTrue(project.connections.contains(where: { $0.id == connection.id }))
    }

    func testConnectionCanBeAssociatedWithAStep() throws {
        let (service, project) = makeService()
        let step = service.addStep(to: project, stepType: .disconnect)
        let connection = try service.addConnection(to: project, stepID: step.id, fromLabel: "HDMI Cable", toLabel: "TV HDMI 2")
        XCTAssertEqual(connection.stepID, step.id)
    }

    func testConnectionSurvivesReload() throws {
        let container = ModelContainerFactory.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let service = ProjectMutationService(modelContext: context, clock: FixedClock(fixedDate: .now))
        let project = service.createProject(title: "TV Setup")
        _ = try service.addConnection(to: project, fromLabel: "HDMI Cable", toLabel: "TV HDMI 2")
        try context.save()

        let descriptor = FetchDescriptor<RTConnection>()
        let reloaded = try context.fetch(descriptor)
        XCTAssertEqual(reloaded.count, 1)
        XCTAssertEqual(reloaded.first?.fromLabel, "HDMI Cable")
    }

    func testConnectionIsSearchable() throws {
        let (service, project) = makeService()
        _ = try service.addConnection(to: project, fromLabel: "HDMI Cable", toLabel: "TV HDMI 2")
        XCTAssertTrue(ProjectSearchEngine.matches(project, query: "hdmi 2"))
    }

    func testEmptyFromLabelIsRejected() {
        let (service, project) = makeService()
        XCTAssertThrowsError(try service.addConnection(to: project, fromLabel: "", toLabel: "TV HDMI 2")) { error in
            XCTAssertEqual(error as? ProjectMutationError, .invalidConnection)
        }
    }

    func testEmptyToLabelIsRejected() {
        let (service, project) = makeService()
        XCTAssertThrowsError(try service.addConnection(to: project, fromLabel: "HDMI Cable", toLabel: "   ")) { error in
            XCTAssertEqual(error as? ProjectMutationError, .invalidConnection)
        }
    }

    func testLabelsAreTrimmedBeforeSaving() throws {
        let (service, project) = makeService()
        let connection = try service.addConnection(to: project, fromLabel: "  HDMI Cable  ", toLabel: "  TV HDMI 2  ")
        XCTAssertEqual(connection.fromLabel, "HDMI Cable")
        XCTAssertEqual(connection.toLabel, "TV HDMI 2")
    }
}
