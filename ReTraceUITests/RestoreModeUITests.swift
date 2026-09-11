import XCTest

/// Release-blocking: Restore Mode must always play the capture sequence back
/// in reverse. See spec §68/§96.
final class RestoreModeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func openSeededProjectRestore(_ app: XCUIApplication) {
        app.launchForTesting(seedSampleData: true)
        app.tapTab("Projects")

        let projectCard = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'project.card.'")).firstMatch
        XCTAssertTrue(projectCard.waitForExistence(timeout: 10))
        projectCard.tap()

        let startRestore = app.buttons["projectDetail.startRestoreButton"]
        XCTAssertTrue(startRestore.waitForExistence(timeout: 10))
        startRestore.tap()
    }

    func testRestoreShowsStepsInReverseCaptureOrder() {
        let app = XCUIApplication()
        openSeededProjectRestore(app)

        XCTAssertTrue(app.staticTexts["Restore Step 1 of 4"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Soundbar optical cable removed'")).firstMatch.waitForExistence(timeout: 10))
    }

    func testMarkingEachStepDoneAdvancesToCompletion() {
        let app = XCUIApplication()
        openSeededProjectRestore(app)

        let markDoneButton = app.buttons["restore.markDoneButton"]

        // Step 1 of 4: Soundbar
        XCTAssertTrue(app.staticTexts["Restore Step 1 of 4"].waitForExistence(timeout: 10))
        markDoneButton.tap()

        // Step 2 of 4: Power cable
        XCTAssertTrue(app.staticTexts["Restore Step 2 of 4"].waitForExistence(timeout: 10))
        markDoneButton.tap()

        // Step 3 of 4: HDMI cable
        XCTAssertTrue(app.staticTexts["Restore Step 3 of 4"].waitForExistence(timeout: 10))
        markDoneButton.tap()

        // Step 4 of 4: Original Setup
        XCTAssertTrue(app.staticTexts["Restore Step 4 of 4"].waitForExistence(timeout: 10))
        markDoneButton.tap()

        XCTAssertTrue(app.staticTexts["restore.completionTitle"].waitForExistence(timeout: 10)
            || app.otherElements["restore.completionTitle"].waitForExistence(timeout: 10)
            || app.staticTexts["Restoration complete"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["restore.completeProjectButton"].waitForExistence(timeout: 10))
    }

    func testPreviousNavigationPreservesCompletedState() {
        let app = XCUIApplication()
        openSeededProjectRestore(app)

        XCTAssertTrue(app.staticTexts["Restore Step 1 of 4"].waitForExistence(timeout: 10))
        app.buttons["restore.markDoneButton"].tap()

        XCTAssertTrue(app.staticTexts["Restore Step 2 of 4"].waitForExistence(timeout: 10))
        app.buttons["restore.previousButton"].tap()

        // Back on step 1; it must still show as completed, with no progress corruption.
        XCTAssertTrue(app.staticTexts["Restore Step 1 of 4"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Completed"].waitForExistence(timeout: 5))
    }

    func testCompletingRestoreMarksProjectComplete() {
        let app = XCUIApplication()
        openSeededProjectRestore(app)

        for _ in 0..<4 {
            app.buttons["restore.markDoneButton"].tap()
        }

        let completeButton = app.buttons["restore.completeProjectButton"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 10))
        completeButton.tap()
        app.buttons["restore.confirmCompleteButton"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts["This project is complete."].waitForExistence(timeout: 10))
    }
}
