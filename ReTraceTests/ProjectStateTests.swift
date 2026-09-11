import XCTest
@testable import ReTrace

@MainActor
final class ProjectStateTests: XCTestCase {
    private func makeService() -> (ProjectMutationService, RTProject) {
        let context = TestSupport.makeInMemoryContext()
        let service = ProjectMutationService(modelContext: context, clock: FixedClock(fixedDate: .now))
        let project = service.createProject(title: "TV Setup")
        return (service, project)
    }

    func testDraftToCapturing() throws {
        let (service, project) = makeService()
        try service.startCapture(project)
        XCTAssertEqual(project.status, .capturing)
    }

    func testCapturingToDisassembled() throws {
        let (service, project) = makeService()
        try service.startCapture(project)
        try service.finishDisassembly(project)
        XCTAssertEqual(project.status, .disassembled)
    }

    func testDisassembledToRestoring() throws {
        let (service, project) = makeService()
        try service.startCapture(project)
        try service.finishDisassembly(project)
        try service.startRestore(project)
        XCTAssertEqual(project.status, .restoring)
    }

    func testRestoringToCompleted() throws {
        let (service, project) = makeService()
        try service.startCapture(project)
        try service.finishDisassembly(project)
        try service.startRestore(project)
        try service.completeProject(project)
        XCTAssertEqual(project.status, .completed)
        XCTAssertNotNil(project.completedAt)
    }

    func testCompletedProjectCannotSilentlyBecomeCapturing() throws {
        let (service, project) = makeService()
        try service.startCapture(project)
        try service.finishDisassembly(project)
        try service.startRestore(project)
        try service.completeProject(project)

        XCTAssertThrowsError(try service.transition(project, to: .capturing)) { error in
            XCTAssertEqual(error as? ProjectMutationError, .invalidTransition)
        }
        XCTAssertEqual(project.status, .completed)
    }

    func testCompletedProjectCanBeArchived() throws {
        let (service, project) = makeService()
        try service.startCapture(project)
        try service.finishDisassembly(project)
        try service.startRestore(project)
        try service.completeProject(project)
        try service.archiveProject(project)
        XCTAssertEqual(project.status, .archived)
    }

    func testDraftCannotJumpDirectlyToDisassembled() {
        let (service, project) = makeService()
        XCTAssertThrowsError(try service.transition(project, to: .disassembled))
        XCTAssertEqual(project.status, .draft)
    }

    func testAddingAStepFromDraftAutoStartsCapturing() {
        let (service, project) = makeService()
        XCTAssertEqual(project.status, .draft)
        service.addStep(to: project, stepType: .reference)
        XCTAssertEqual(project.status, .capturing)
    }
}
