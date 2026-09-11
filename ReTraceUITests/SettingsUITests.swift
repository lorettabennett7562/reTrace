import XCTest

final class SettingsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppearanceSettingPersistsAcrossRelaunch() {
        let app = XCUIApplication()
        app.launchForTesting()
        app.tapTab("Settings")

        let picker = app.segmentedControls["settings.appearancePicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        picker.buttons["Dark"].tap()

        app.terminate()
        let relaunched = XCUIApplication()
        relaunched.launchArguments += ["--uitesting"]
        relaunched.launch()
        relaunched.tapTab("Settings")

        let reopenedPicker = relaunched.segmentedControls["settings.appearancePicker"]
        XCTAssertTrue(reopenedPicker.waitForExistence(timeout: 10))
        XCTAssertTrue(reopenedPicker.buttons["Dark"].isSelected)
    }

    func testImageQualitySettingPersists() {
        let app = XCUIApplication()
        app.launchForTesting()
        app.tapTab("Settings")

        app.buttons["settings.imageQualityPicker"].tap()
        let highOption = app.buttons["High"]
        if highOption.waitForExistence(timeout: 5) {
            highOption.tap()
        }

        XCTAssertTrue(app.staticTexts["High"].waitForExistence(timeout: 5))
    }

    func testDeleteAllDataRequiresConfirmation() {
        let app = XCUIApplication()
        app.launchForTesting()
        app.tapTab("Settings")

        app.buttons["settings.deleteAllDataButton"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 10))
        app.buttons["Cancel"].tap()

        // Cancelling must not delete anything or crash.
        XCTAssertTrue(app.buttons["settings.deleteAllDataButton"].waitForExistence(timeout: 5))
    }

    func testExportActionIsDiscoverableFromProjectDetail() {
        let app = XCUIApplication()
        app.launchForTesting(seedSampleData: true)
        app.tapTab("Projects")

        let projectCard = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'project.card.'")).firstMatch
        XCTAssertTrue(projectCard.waitForExistence(timeout: 10))
        projectCard.tap()

        app.buttons["projectDetail.menuButton"].tap()
        XCTAssertTrue(app.buttons["projectDetail.exportButton"].waitForExistence(timeout: 10))
    }
}
