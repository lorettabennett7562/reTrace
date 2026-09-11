import XCTest

final class ProjectDeletionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func openSeededProjectDetail(_ app: XCUIApplication) {
        app.launchForTesting(seedSampleData: true)
        app.tapTab("Projects")

        let projectCard = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'project.card.'")).firstMatch
        XCTAssertTrue(projectCard.waitForExistence(timeout: 10))
        projectCard.tap()
    }

    func testCancellingDeletionKeepsTheProject() {
        let app = XCUIApplication()
        openSeededProjectDetail(app)

        app.buttons["projectDetail.menuButton"].tap()
        app.buttons["projectDetail.deleteButton"].tap()

        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 10))
        app.buttons["Cancel"].tap()

        XCTAssertTrue(app.staticTexts["TV Setup"].waitForExistence(timeout: 10))
    }

    func testDeletingReturnsToProjectsSafely() {
        let app = XCUIApplication()
        openSeededProjectDetail(app)

        app.buttons["projectDetail.menuButton"].tap()
        app.buttons["projectDetail.deleteButton"].tap()

        let confirmButton = app.buttons["projectDetail.confirmDeleteButton"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 10))
        confirmButton.tap()

        XCTAssertTrue(app.navigationBars["Projects"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Nothing here yet."].waitForExistence(timeout: 10))
    }
}
