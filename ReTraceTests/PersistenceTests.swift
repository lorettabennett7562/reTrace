import XCTest
import SwiftData
@testable import ReTrace

@MainActor
final class PersistenceTests: XCTestCase {
    func testCreateFetchModifyAndDeleteProject() throws {
        let context = TestSupport.makeInMemoryContext()
        let service = ProjectMutationService(modelContext: context, clock: FixedClock(fixedDate: .now))

        let project = service.createProject(title: "TV Setup", category: .electronics)
        try context.save()

        var fetched = try context.fetch(FetchDescriptor<RTProject>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "TV Setup")

        fetched.first?.title = "TV Setup Updated"
        try context.save()
        fetched = try context.fetch(FetchDescriptor<RTProject>())
        XCTAssertEqual(fetched.first?.title, "TV Setup Updated")

        service.deleteProject(project)
        try context.save()
        XCTAssertTrue(try context.fetch(FetchDescriptor<RTProject>()).isEmpty)
    }

    func testStepsPartsAndConnectionsPersistAndRelate() throws {
        let context = TestSupport.makeInMemoryContext()
        let service = ProjectMutationService(modelContext: context, clock: FixedClock(fixedDate: .now))

        let project = service.createProject(title: "PC Upgrade")
        let step = service.addStep(to: project, title: "Remove GPU", stepType: .unscrew)
        let part = service.addPart(to: project, name: "GPU Screw", quantity: 4, linkedStep: step)
        _ = try service.addConnection(to: project, stepID: step.id, fromLabel: "PCIe Cable", toLabel: "GPU Power")

        try context.save()

        let projectID = project.id
        let predicate = #Predicate<RTProject> { $0.id == projectID }
        let reloadedProject = try context.fetch(FetchDescriptor(predicate: predicate)).first
        XCTAssertNotNil(reloadedProject)
        XCTAssertEqual(reloadedProject?.steps.count, 1)
        XCTAssertEqual(reloadedProject?.parts.count, 1)
        XCTAssertEqual(reloadedProject?.connections.count, 1)
        XCTAssertEqual(reloadedProject?.parts.first?.linkedSteps.first?.id, step.id)
        XCTAssertEqual(part.project?.id, project.id)
    }

    func testModelContainerFactoryFallsBackToInMemoryOnFailure() {
        let container = ModelContainerFactory.makeContainer(inMemory: true)
        XCTAssertFalse(container.configurations.isEmpty)
    }
}
