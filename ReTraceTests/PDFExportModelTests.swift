import XCTest
@testable import ReTrace

@MainActor
final class PDFExportModelTests: XCTestCase {
    private func makeProject() -> RTProject {
        let context = TestSupport.makeInMemoryContext()
        let service = ProjectMutationService(modelContext: context, clock: FixedClock(fixedDate: .now))
        let project = service.createProject(title: "TV Setup", notes: "Be careful with the stand")
        let step = service.addStep(to: project, note: "Blue cable was on port 3", stepType: .disconnect, imagePath: "Media/x/y.jpg")
        service.addPart(to: project, name: "HDMI Cable", quantity: 1, storageLabel: "Bag A", linkedStep: step)
        try? service.addConnection(to: project, fromLabel: "HDMI Cable", toLabel: "TV HDMI 2")
        return project
    }

    func testModelCapturesCorrectTitle() {
        let model = PDFExportModelBuilder.build(from: makeProject())
        XCTAssertEqual(model.projectTitle, "TV Setup")
    }

    func testModelCapturesChronologicalCaptureOrder() {
        let context = TestSupport.makeInMemoryContext()
        let service = ProjectMutationService(modelContext: context, clock: FixedClock(fixedDate: .now))
        let project = service.createProject(title: "Desk Disassembly")
        service.addStep(to: project, title: "Remove top", stepType: .remove)
        service.addStep(to: project, title: "Remove legs", stepType: .remove)

        let model = PDFExportModelBuilder.build(from: project)
        XCTAssertEqual(model.timeline.map(\.title), ["Remove top", "Remove legs"])
        XCTAssertEqual(model.timeline.map(\.orderIndex), [0, 1])
    }

    func testModelCapturesNotes() {
        let model = PDFExportModelBuilder.build(from: makeProject())
        XCTAssertEqual(model.notes, "Be careful with the stand")
    }

    func testModelCapturesParts() {
        let model = PDFExportModelBuilder.build(from: makeProject())
        XCTAssertEqual(model.parts, [PDFExportModel.PartEntry(name: "HDMI Cable", quantity: 1, storageLabel: "Bag A")])
    }

    func testModelCapturesConnections() {
        let model = PDFExportModelBuilder.build(from: makeProject())
        XCTAssertEqual(model.connections, [PDFExportModel.ConnectionEntry(fromLabel: "HDMI Cable", toLabel: "TV HDMI 2", note: nil)])
    }

    func testModelCapturesImageReferences() {
        let model = PDFExportModelBuilder.build(from: makeProject())
        XCTAssertEqual(model.timeline.first?.imagePath, "Media/x/y.jpg")
    }

    func testExportingProducesANonEmptyFile() throws {
        let model = PDFExportModelBuilder.build(from: makeProject())
        let exporter = PDFProjectExporter()
        let url = try exporter.export(model, mediaStore: TemporaryMediaStore().store)
        defer { try? FileManager.default.removeItem(at: url) }

        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = attributes[.size] as? Int ?? 0
        XCTAssertGreaterThan(size, 0)
    }
}
