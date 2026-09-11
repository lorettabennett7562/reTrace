import XCTest
@testable import ReTrace

@MainActor
final class PartInventoryTests: XCTestCase {
    private func makeService() -> (ProjectMutationService, RTProject) {
        let context = TestSupport.makeInMemoryContext()
        let service = ProjectMutationService(modelContext: context, clock: FixedClock(fixedDate: .now))
        let project = service.createProject(title: "PC Upgrade")
        return (service, project)
    }

    func testAddPartStoresFieldsCorrectly() {
        let (service, project) = makeService()
        let part = service.addPart(to: project, name: "Short Screw", quantity: 4)
        XCTAssertEqual(part.name, "Short Screw")
        XCTAssertEqual(part.quantity, 4)
        XCTAssertTrue(project.parts.contains(where: { $0.id == part.id }))
    }

    func testUpdateQuantity() throws {
        let (service, project) = makeService()
        let part = service.addPart(to: project, name: "Short Screw", quantity: 4)
        try service.updatePartQuantity(part, to: 3)
        XCTAssertEqual(part.quantity, 3)
    }

    func testZeroQuantityIsAllowedAndRepresentsAnEmptiedPart() throws {
        let (service, project) = makeService()
        let part = service.addPart(to: project, name: "Short Screw", quantity: 4)
        try service.updatePartQuantity(part, to: 0)
        XCTAssertEqual(part.quantity, 0)
    }

    func testNegativeQuantityIsNeverPersisted() {
        let (service, project) = makeService()
        let part = service.addPart(to: project, name: "Short Screw", quantity: 4)
        XCTAssertThrowsError(try service.updatePartQuantity(part, to: -1)) { error in
            XCTAssertEqual(error as? ProjectMutationError, .invalidQuantity)
        }
        XCTAssertEqual(part.quantity, 4)
    }

    func testAddingAPartWithNegativeInitialQuantityClampsToZero() {
        let (service, project) = makeService()
        let part = service.addPart(to: project, name: "Bracket", quantity: -5)
        XCTAssertEqual(part.quantity, 0)
    }

    func testPartsWithTheSameNameAreNotAutomaticallyMerged() {
        let (service, project) = makeService()
        let first = service.addPart(to: project, name: "Screw", quantity: 2)
        let second = service.addPart(to: project, name: "Screw", quantity: 3)
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(project.parts.count, 2)
    }

    func testLinkedPartSurvivesPersistence() {
        let (service, project) = makeService()
        let step = service.addStep(to: project, stepType: .unscrew)
        let part = service.addPart(to: project, name: "Left Bracket", quantity: 1, linkedStep: step)

        XCTAssertTrue(part.linkedSteps.contains(where: { $0.id == step.id }))
        XCTAssertTrue(step.parts.contains(where: { $0.id == part.id }))
    }

    func testDeletingAPartRemovesItFromTheProject() {
        let (service, project) = makeService()
        let part = service.addPart(to: project, name: "Screw", quantity: 1)
        service.deletePart(part)
        XCTAssertFalse(project.parts.contains(where: { $0.id == part.id }))
    }
}
