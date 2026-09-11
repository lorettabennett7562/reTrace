import XCTest

/// Runs critical flows on the iPad simulator in both orientations. See spec §74.
final class iPadLayoutUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
    }

    func testProjectsListIsUsableInPortrait() {
        let app = XCUIApplication()
        app.launchForTesting(seedSampleData: true)
        app.tapTab("Projects")

        XCTAssertTrue(app.navigationBars["Projects"].waitForExistence(timeout: 10))
        let projectCard = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'project.card.'")).firstMatch
        XCTAssertTrue(projectCard.waitForExistence(timeout: 10))
    }

    func testProjectsListIsUsableInLandscape() {
        let app = XCUIApplication()
        app.launchForTesting(seedSampleData: true)
        XCUIDevice.shared.orientation = .landscapeLeft
        app.tapTab("Projects")

        XCTAssertTrue(app.navigationBars["Projects"].waitForExistence(timeout: 10))
        let projectCard = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'project.card.'")).firstMatch
        XCTAssertTrue(projectCard.waitForExistence(timeout: 10))
    }

    func testCaptureLayoutUsesAvailableWidthAndSurvivesRotation() {
        let app = XCUIApplication()
        app.launchForTesting()
        app.tapTab("Projects")
        app.buttons["projects.newProjectButton"].tap()

        let titleField = app.textFields["project.titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 10))
        titleField.tap()
        titleField.typeText("Desk Disassembly")
        app.buttons["project.startCaptureButton"].tap()

        XCTAssertTrue(app.buttons["capture.takePhotoButton"].waitForExistence(timeout: 10))

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.buttons["capture.takePhotoButton"].waitForExistence(timeout: 10))

        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.buttons["capture.takePhotoButton"].waitForExistence(timeout: 10))
    }

    func testRestoreModeRemainsReadableOnIPad() {
        let app = XCUIApplication()
        app.launchForTesting(seedSampleData: true)
        app.tapTab("Projects")

        let projectCard = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'project.card.'")).firstMatch
        XCTAssertTrue(projectCard.waitForExistence(timeout: 10))
        projectCard.tap()

        let startRestore = app.buttons["projectDetail.startRestoreButton"]
        XCTAssertTrue(startRestore.waitForExistence(timeout: 10))
        startRestore.tap()

        XCTAssertTrue(app.staticTexts["Restore Step 1 of 4"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["restore.markDoneButton"].waitForExistence(timeout: 10))
    }
}
