import XCTest
@testable import ReTrace

@MainActor
final class ProjectSearchTests: XCTestCase {
    private func makeProjects() -> [RTProject] {
        let context = TestSupport.makeInMemoryContext()
        let service = ProjectMutationService(modelContext: context, clock: FixedClock(fixedDate: .now))

        let tvSetup = service.createProject(title: "TV Setup")
        try? service.addConnection(to: tvSetup, fromLabel: "HDMI Cable", toLabel: "TV HDMI 2")

        let pcUpgrade = service.createProject(title: "PC Upgrade")
        service.addPart(to: pcUpgrade, name: "GPU Screw", quantity: 4, storageLabel: "Bag A")

        let deskDisassembly = service.createProject(title: "Desk Disassembly")

        return [tvSetup, pcUpgrade, deskDisassembly]
    }

    func testSearchByProjectName() {
        let projects = makeProjects()
        let results = ProjectSearchEngine.search(projects, query: "tv")
        XCTAssertEqual(results.map(\.title), ["TV Setup"])
    }

    func testSearchByConnectionLabel() {
        let projects = makeProjects()
        let results = ProjectSearchEngine.search(projects, query: "HDMI")
        XCTAssertEqual(results.map(\.title), ["TV Setup"])
    }

    func testSearchByPartName() {
        let projects = makeProjects()
        let results = ProjectSearchEngine.search(projects, query: "screw")
        XCTAssertEqual(results.map(\.title), ["PC Upgrade"])
    }

    func testSearchByStorageLabel() {
        let projects = makeProjects()
        let results = ProjectSearchEngine.search(projects, query: "bag a")
        XCTAssertEqual(results.map(\.title), ["PC Upgrade"])
    }

    func testSearchIsCaseInsensitive() {
        let projects = makeProjects()
        XCTAssertEqual(ProjectSearchEngine.search(projects, query: "TV SETUP").count, 1)
        XCTAssertEqual(ProjectSearchEngine.search(projects, query: "tv setup").count, 1)
    }

    func testSearchTrimsWhitespace() {
        let projects = makeProjects()
        let results = ProjectSearchEngine.search(projects, query: "  tv  ")
        XCTAssertEqual(results.map(\.title), ["TV Setup"])
    }

    func testEmptySearchReturnsAllProjects() {
        let projects = makeProjects()
        XCTAssertEqual(ProjectSearchEngine.search(projects, query: "").count, projects.count)
    }

    func testSearchWithNoMatchesReturnsEmpty() {
        let projects = makeProjects()
        XCTAssertTrue(ProjectSearchEngine.search(projects, query: "nonexistent").isEmpty)
    }
}
