import XCTest

final class OnboardingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCompletingOnboardingRevealsMainTabs() {
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting", "--reset-data"]
        app.launch()

        let continueButton = app.buttons["onboarding.continueButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10))

        // Three onboarding pages: tap through Next, Next, then Get Started.
        for _ in 0..<3 {
            XCTAssertTrue(continueButton.waitForHittable(timeout: 5))
            continueButton.tap()
        }

        XCTAssertTrue(app.tab("Projects").waitForExistence(timeout: 10))
    }

    func testOnboardingDoesNotReappearAfterRelaunch() {
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting", "--reset-data"]
        app.launch()

        let continueButton = app.buttons["onboarding.continueButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10))
        for _ in 0..<3 {
            XCTAssertTrue(continueButton.waitForHittable(timeout: 5))
            continueButton.tap()
        }
        XCTAssertTrue(app.tabBars.buttons["Projects"].waitForExistence(timeout: 10))

        // Relaunch without --reset-data: onboarding completion should persist.
        app.terminate()
        let relaunched = XCUIApplication()
        relaunched.launchArguments += ["--uitesting"]
        relaunched.launch()
        XCTAssertTrue(relaunched.tab("Projects").waitForExistence(timeout: 10))
    }
}
