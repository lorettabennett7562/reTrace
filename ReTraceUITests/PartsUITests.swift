import XCTest

final class PartsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAddPartFromCaptureAppearsInPartsTab() {
        let app = XCUIApplication()
        app.launchForTesting()
        app.tapTab("Projects")
        app.buttons["projects.newProjectButton"].tap()

        let titleField = app.textFields["project.titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 10))
        titleField.tap()
        titleField.typeText("PC Upgrade")
        app.buttons["project.startCaptureButton"].tap()

        XCTAssertTrue(app.buttons["capture.addPartButton"].waitForExistence(timeout: 10))
        app.buttons["capture.addPartButton"].scrollToAndTap(in: app)

        let nameField = app.textFields["part.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText("Short Screw")

        let stepper = app.steppers["part.quantityStepper"]
        XCTAssertTrue(stepper.waitForExistence(timeout: 10))
        // A SwiftUI Stepper's two controls are exposed as
        // "<identifier>-Increment"/"-Decrement", with the current value
        // folded into their accessibility label — so match by identifier.
        let incrementButton = app.buttons["part.quantityStepper-Increment"]
        XCTAssertTrue(incrementButton.waitForExistence(timeout: 5))
        incrementButton.tap()
        incrementButton.tap()
        incrementButton.tap()

        let storageField = app.textFields["part.storageField"]
        storageField.tap()
        storageField.typeText("Bag A")

        app.buttons["part.saveButton"].tap()

        app.tapTab("Parts")
        XCTAssertTrue(app.staticTexts["4× Short Screw"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Bag A"].waitForExistence(timeout: 10))
    }

    func testPartsTabShowsEmptyStateWithNoParts() {
        let app = XCUIApplication()
        app.launchForTesting()
        app.tapTab("Parts")
        XCTAssertTrue(app.staticTexts["No parts recorded."].waitForExistence(timeout: 10))
    }
}
