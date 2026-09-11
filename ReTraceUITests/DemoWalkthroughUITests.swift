import XCTest

/// Not part of the mandatory suites — a scripted, full-feature walkthrough
/// used only to produce a narrated screen recording of the app for
/// demonstration purposes (Xcode automatically records UI test sessions).
final class DemoWalkthroughUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Holds on a screen briefly so the recording is watchable by a human,
    /// rather than moving at raw automated-test speed.
    private func pause(_ seconds: TimeInterval = 1.4) {
        Thread.sleep(forTimeInterval: seconds)
    }

    /// Saves a named, permanently-kept screenshot for use as marketing
    /// material (App Store screenshots, website), attached to the test
    /// result rather than written to disk directly.
    private func snapshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testFullProductWalkthrough() {
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting", "--reset-data", "-useMockCamera"]
        app.launch()

        // MARK: Onboarding
        let continueButton = app.buttons["onboarding.continueButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10))
        for _ in 0..<3 {
            XCTAssertTrue(continueButton.waitForHittable(timeout: 5))
            continueButton.tap()
        }
        XCTAssertTrue(app.tab("Projects").waitForExistence(timeout: 10))
        pause()

        // MARK: Create a project
        app.buttons["projects.newProjectButton"].tap()
        let titleField = app.textFields["project.titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 10))
        titleField.tap()
        titleField.typeText("TV Setup")
        app.buttons["project.startCaptureButton"].tap()
        XCTAssertTrue(app.buttons["capture.takePhotoButton"].waitForExistence(timeout: 10))

        // MARK: Step 1 — with a photo
        app.buttons["capture.takePhotoButton"].tap()
        let disconnectChip = app.buttons["capture.stepType.disconnect"]
        XCTAssertTrue(disconnectChip.waitForExistence(timeout: 10))
        disconnectChip.scrollToAndTap(in: app)
        let noteField = app.textFields["capture.noteField"]
        XCTAssertTrue(noteField.waitForExistence(timeout: 10))
        noteField.scrollToAndTap(in: app)
        noteField.typeText("HDMI 2")
        snapshot("02-capture")
        app.buttons["capture.saveStepButton"].scrollToAndTap(in: app)
        XCTAssertTrue(app.staticTexts["Step 2"].waitForExistence(timeout: 10))
        pause()

        // MARK: Step 2 — no photo at all, just a type + note
        let unplugChip = app.buttons["capture.stepType.unplug"]
        XCTAssertTrue(unplugChip.waitForExistence(timeout: 10))
        unplugChip.scrollToAndTap(in: app)
        XCTAssertTrue(noteField.waitForExistence(timeout: 10))
        noteField.scrollToAndTap(in: app)
        noteField.typeText("Power cable")
        app.buttons["capture.saveStepButton"].scrollToAndTap(in: app)
        XCTAssertTrue(app.staticTexts["Step 3"].waitForExistence(timeout: 10))
        pause()

        // MARK: Add a part
        app.buttons["capture.addPartButton"].scrollToAndTap(in: app)
        let partNameField = app.textFields["part.nameField"]
        XCTAssertTrue(partNameField.waitForExistence(timeout: 10))
        partNameField.tap()
        partNameField.typeText("HDMI Cable")
        let storageField = app.textFields["part.storageField"]
        storageField.tap()
        storageField.typeText("Bag A")
        app.buttons["part.saveButton"].tap()
        XCTAssertFalse(partNameField.waitForExistence(timeout: 5))

        // MARK: Add a connection
        app.buttons["capture.addConnectionButton"].scrollToAndTap(in: app)
        let fromField = app.textFields["connection.fromField"]
        XCTAssertTrue(fromField.waitForExistence(timeout: 10))
        fromField.tap()
        fromField.typeText("HDMI Cable")
        let toField = app.textFields["connection.toField"]
        toField.tap()
        toField.typeText("TV HDMI 2")
        app.buttons["connection.saveButton"].tap()
        XCTAssertFalse(fromField.waitForExistence(timeout: 5))

        // MARK: Finish disassembly
        app.buttons["capture.finishButton"].scrollToAndTap(in: app)
        app.buttons["capture.confirmFinishButton"].firstMatch.tap()
        XCTAssertTrue(app.buttons["projectDetail.startRestoreButton"].waitForExistence(timeout: 10))
        pause()
        snapshot("03-project-detail")

        // MARK: Show the photo-free flow diagram view
        let diagramToggle = app.buttons["flowchart"]
        if diagramToggle.waitForExistence(timeout: 5) {
            diagramToggle.tap()
            _ = app.images.matching(NSPredicate(format: "identifier BEGINSWITH 'diagram.step.'")).firstMatch.waitForExistence(timeout: 5)
            pause()
            snapshot("04-flow-diagram")
        }

        // MARK: Restore Mode — reverse order
        app.buttons["projectDetail.startRestoreButton"].tap()
        XCTAssertTrue(app.staticTexts["Restore Step 1 of 2"].waitForExistence(timeout: 10))
        pause()
        snapshot("05-restore")
        app.buttons["restore.markDoneButton"].tap()
        XCTAssertTrue(app.staticTexts["Restore Step 2 of 2"].waitForExistence(timeout: 10))
        pause()
        app.buttons["restore.markDoneButton"].tap()
        XCTAssertTrue(app.buttons["restore.completeProjectButton"].waitForExistence(timeout: 10))
        pause()

        // MARK: Final comparison
        app.buttons["restore.compareFinalStateButton"].tap()
        XCTAssertTrue(app.navigationBars["Final Comparison"].waitForExistence(timeout: 10))
        if app.buttons["Take Photo"].waitForExistence(timeout: 5) {
            app.buttons["Take Photo"].tap()
        }
        pause()
        app.buttons["Done"].tap()

        // MARK: Complete the project — returns straight to the project list
        app.buttons["restore.completeProjectButton"].tap()
        app.buttons["restore.confirmCompleteButton"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["TV Setup"].waitForExistence(timeout: 10))
        pause()
        snapshot("06-projects")

        // MARK: Parts tab — cross-project inventory
        app.tapTab("Parts")
        XCTAssertTrue(app.staticTexts["1× HDMI Cable"].waitForExistence(timeout: 10))
        pause()
        snapshot("07-parts")

        // MARK: Settings — Dark Mode
        app.tapTab("Settings")
        let appearancePicker = app.segmentedControls["settings.appearancePicker"]
        XCTAssertTrue(appearancePicker.waitForExistence(timeout: 10))
        appearancePicker.buttons["Dark"].tap()
        XCTAssertTrue(appearancePicker.buttons["Dark"].waitForHittable(timeout: 5))
        pause()

        app.tapTab("Projects")
        XCTAssertTrue(app.staticTexts["TV Setup"].waitForExistence(timeout: 15))
        pause()
        snapshot("08-projects-dark")
    }
}
