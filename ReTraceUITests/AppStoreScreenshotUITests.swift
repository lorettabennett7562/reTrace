import XCTest

/// Not part of the mandatory suites — captures App Store-ready screenshots
/// using seeded sample data, one run per target device/size class.
final class AppStoreScreenshotUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func snapshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCaptureAppStoreScreenshots() {
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting", "--reset-data", "--skip-onboarding", "--seed-sample-data", "-useMockCamera"]
        app.launch()

        XCTAssertTrue(app.tab("Projects").waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1)
        snapshot("AS-01-projects")

        let projectCard = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'project.card.'")).firstMatch
        XCTAssertTrue(projectCard.waitForExistence(timeout: 10))
        projectCard.tap()
        XCTAssertTrue(app.buttons["projectDetail.startRestoreButton"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1)
        snapshot("AS-02-project-detail")

        app.buttons["projectDetail.startRestoreButton"].tap()
        XCTAssertTrue(app.staticTexts["Restore Step 1 of 4"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1)
        snapshot("AS-03-restore")

        app.tapTab("Parts")
        XCTAssertTrue(app.staticTexts["1× HDMI Cable"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1)
        snapshot("AS-04-parts")

        app.tapTab("Settings")
        let appearancePicker = app.segmentedControls["settings.appearancePicker"]
        XCTAssertTrue(appearancePicker.waitForExistence(timeout: 10))
        appearancePicker.buttons["Dark"].tap()
        XCTAssertTrue(appearancePicker.buttons["Dark"].waitForHittable(timeout: 5))
        Thread.sleep(forTimeInterval: 1)
        snapshot("AS-05-dark")
    }
}
