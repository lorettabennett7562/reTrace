import XCTest

final class SearchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func createProject(_ app: XCUIApplication, title: String) {
        app.tapTab("Projects")
        app.buttons["projects.newProjectButton"].tap()
        let titleField = app.textFields["project.titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 10))
        titleField.tap()
        titleField.typeText(title)
        app.buttons["project.startCaptureButton"].tap()
        XCTAssertTrue(app.buttons["capture.takePhotoButton"].waitForExistence(timeout: 10))
    }

    func testSearchFindsProjectByNoteContent() {
        let app = XCUIApplication()
        app.launchForTesting()

        createProject(app, title: "TV Setup")
        app.buttons["capture.takePhotoButton"].tap()
        app.buttons["capture.stepType.disconnect"].scrollToAndTap(in: app)
        let noteField = app.textFields["capture.noteField"]
        noteField.scrollToAndTap(in: app)
        noteField.typeText("HDMI 2")
        app.buttons["capture.saveStepButton"].scrollToAndTap(in: app)
        XCTAssertTrue(app.staticTexts["Step 2"].waitForExistence(timeout: 10))

        app.tapTab("Projects")
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        searchField.tap()
        searchField.typeText("HDMI")

        XCTAssertTrue(app.staticTexts["TV Setup"].waitForExistence(timeout: 10))
    }

    func testSearchFindsProjectByPartName() {
        let app = XCUIApplication()
        app.launchForTesting()

        createProject(app, title: "PC Upgrade")
        app.buttons["capture.addPartButton"].scrollToAndTap(in: app)
        let nameField = app.textFields["part.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText("GPU Screw")
        app.buttons["part.saveButton"].tap()

        app.tapTab("Projects")
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        searchField.tap()
        searchField.typeText("GPU")

        XCTAssertTrue(app.staticTexts["PC Upgrade"].waitForExistence(timeout: 10))
    }

    func testSearchWithNoMatchesShowsNoProjects() {
        let app = XCUIApplication()
        app.launchForTesting()
        createProject(app, title: "TV Setup")

        app.tapTab("Projects")
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        searchField.tap()
        searchField.typeText("zzzznonexistent")

        XCTAssertFalse(app.staticTexts["TV Setup"].exists)
    }
}
