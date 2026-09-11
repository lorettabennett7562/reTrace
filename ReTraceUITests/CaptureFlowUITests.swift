import XCTest

final class CaptureFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func createProjectAndEnterCapture(_ app: XCUIApplication, title: String = "TV Setup") {
        app.launchForTesting()
        app.tapTab("Projects")
        app.buttons["projects.newProjectButton"].tap()

        let titleField = app.textFields["project.titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 10))
        titleField.tap()
        titleField.typeText(title)
        app.buttons["project.startCaptureButton"].tap()

        XCTAssertTrue(app.buttons["capture.takePhotoButton"].waitForExistence(timeout: 10))
    }

    private func captureStep(_ app: XCUIApplication, type: String, note: String) {
        app.buttons["capture.takePhotoButton"].scrollToAndTap(in: app)

        let typeChip = app.buttons["capture.stepType.\(type)"]
        XCTAssertTrue(typeChip.waitForExistence(timeout: 10))
        typeChip.scrollToAndTap(in: app)

        let noteField = app.textFields["capture.noteField"]
        if noteField.waitForExistence(timeout: 5) {
            noteField.scrollToAndTap(in: app)
            noteField.typeText(note)
        }

        let saveButton = app.buttons["capture.saveStepButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.scrollToAndTap(in: app)
    }

    func testCapturingAPhotoStepAppearsInTheTimeline() {
        let app = XCUIApplication()
        createProjectAndEnterCapture(app)

        captureStep(app, type: "disconnect", note: "HDMI 2")

        XCTAssertTrue(app.staticTexts["Step 2"].waitForExistence(timeout: 10))
    }

    func testMultipleStepsAreRecordedInOrder() {
        let app = XCUIApplication()
        createProjectAndEnterCapture(app)

        captureStep(app, type: "disconnect", note: "HDMI 2")
        XCTAssertTrue(app.staticTexts["Step 2"].waitForExistence(timeout: 10))

        captureStep(app, type: "unplug", note: "Power cable")
        XCTAssertTrue(app.staticTexts["Step 3"].waitForExistence(timeout: 10))

        // Finish disassembly and verify both steps show up in the timeline in order.
        app.buttons["capture.finishButton"].scrollToAndTap(in: app)
        app.buttons["capture.confirmFinishButton"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts["1. Disconnected"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["2. Unplugged"].waitForExistence(timeout: 10))
    }

    func testAddingAPartDuringCapture() {
        let app = XCUIApplication()
        createProjectAndEnterCapture(app)

        app.buttons["capture.addPartButton"].scrollToAndTap(in: app)
        let nameField = app.textFields["part.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText("Short Screw")
        app.buttons["part.saveButton"].tap()

        XCTAssertFalse(nameField.waitForExistence(timeout: 5))
    }
}
