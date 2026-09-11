import XCTest
@testable import ReTrace

@MainActor
final class StepOrderingTests: XCTestCase {
    private func makeService() -> (ProjectMutationService, RTProject) {
        let context = TestSupport.makeInMemoryContext()
        let service = ProjectMutationService(modelContext: context, clock: FixedClock(fixedDate: .now))
        let project = service.createProject(title: "Desk Disassembly")
        return (service, project)
    }

    func testNewStepReceivesNextOrderIndex() {
        let (service, project) = makeService()
        let first = service.addStep(to: project, stepType: .reference)
        let second = service.addStep(to: project, stepType: .remove)
        XCTAssertEqual(first.orderIndex, 0)
        XCTAssertEqual(second.orderIndex, 1)
    }

    func testDeletingAStepDoesNotBreakRemainingOrder() {
        let (service, project) = makeService()
        let first = service.addStep(to: project, stepType: .reference)
        let second = service.addStep(to: project, stepType: .remove)
        let third = service.addStep(to: project, stepType: .disconnect)

        service.deleteStep(second)

        let remainingOrder = RestoreSequenceEngine.captureOrder(from: project.steps).map(\.orderIndex)
        XCTAssertEqual(remainingOrder, [first.orderIndex, third.orderIndex])
        XCTAssertEqual(project.steps.count, 2)
    }

    func testNextOrderIndexIsBasedOnRemainingStepsAfterDeletion() {
        let (service, project) = makeService()
        let first = service.addStep(to: project, stepType: .reference)
        let second = service.addStep(to: project, stepType: .remove)
        service.deleteStep(second)

        // Only `first` (orderIndex 0) remains, so the next step reuses index 1
        // rather than continuing to climb past a step that no longer exists.
        let third = service.addStep(to: project, stepType: .disconnect)
        XCTAssertEqual(third.orderIndex, first.orderIndex + 1)
    }

    func testTimelineSortsAscending() {
        let (service, project) = makeService()
        service.addStep(to: project, stepType: .reference)
        service.addStep(to: project, stepType: .remove)
        service.addStep(to: project, stepType: .disconnect)

        let ordered = project.orderedSteps.map(\.orderIndex)
        XCTAssertEqual(ordered, ordered.sorted())
    }

    func testRestoreSortsDescending() {
        let (service, project) = makeService()
        service.addStep(to: project, stepType: .reference)
        service.addStep(to: project, stepType: .remove)
        service.addStep(to: project, stepType: .disconnect)

        let restoreOrder = project.restoreSteps.map(\.orderIndex)
        XCTAssertEqual(restoreOrder, restoreOrder.sorted(by: >))
    }
}
