import XCTest

final class ProjectCreationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCreatingAProjectOpensCaptureForIt() {
        let app = XCUIApplication()
        app.launchForTesting()
        app.tapTab("Projects")

        app.buttons["projects.newProjectButton"].tap()

        let titleField = app.textFields["project.titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 10))
        titleField.tap()
        titleField.typeText("TV Setup")

        app.buttons["project.startCaptureButton"].tap()

        // Start Capture dismisses the sheet and switches to the Capture tab
        // for the newly created project.
        XCTAssertTrue(app.staticTexts["TV Setup"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["capture.takePhotoButton"].waitForExistence(timeout: 10))
    }

    func testProjectRequiresATitleBeforeStartingCapture() {
        let app = XCUIApplication()
        app.launchForTesting()
        app.tapTab("Projects")
        app.buttons["projects.newProjectButton"].tap()

        let startCaptureButton = app.buttons["project.startCaptureButton"]
        XCTAssertTrue(startCaptureButton.waitForExistence(timeout: 10))
        XCTAssertFalse(startCaptureButton.isEnabled)
    }
}
