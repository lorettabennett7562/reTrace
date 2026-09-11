import XCTest

extension XCUIApplication {
    /// Launches with a clean, in-memory data store so UI tests never touch
    /// real user data and never depend on prior test runs.
    func launchForTesting(skipOnboarding: Bool = true, seedSampleData: Bool = false, useMockCamera: Bool = true) {
        launchArguments += ["--uitesting", "--reset-data"]
        if skipOnboarding { launchArguments += ["--skip-onboarding"] }
        if seedSampleData { launchArguments += ["--seed-sample-data"] }
        if useMockCamera { launchArguments += ["-useMockCamera"] }
        launch()
    }

    /// iOS's floating tab bar isn't always exposed as an
    /// `XCUIElementType.tabBar` container, so this falls back to matching
    /// the tab's SF Symbol identifier or a plain button/cell by label.
    func tab(_ label: String) -> XCUIElement {
        let symbols = [
            "Projects": "square.stack.3d.up", "Capture": "camera.viewfinder",
            "Parts": "shippingbox", "Settings": "gearshape",
        ]
        let candidates = [
            tabBars.buttons[label].firstMatch,
            symbols[label].map { buttons[$0].firstMatch },
            buttons[label].firstMatch,
            cells[label].firstMatch,
            otherElements[label].firstMatch,
        ].compactMap { $0 }

        for candidate in candidates where candidate.waitForExistence(timeout: 3) {
            return candidate
        }
        return tabBars.buttons[label]
    }

    /// Finds and taps a tab bar item. Uses a coordinate-based tap since the
    /// floating tab bar's overlapping duplicate elements can otherwise
    /// silently eat a plain `.tap()`.
    func tapTab(_ label: String) {
        tab(label).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
}

extension XCUIElement {
    /// Polls until the element is both present and hittable (e.g. no longer
    /// obscured by a lingering keyboard), rather than just existing.
    @discardableResult
    func waitForHittable(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// The Capture screen's composer can grow taller than the viewport (e.g.
    /// once a photo preview is showing), so a control further down can start
    /// out below the fold — this nudges just the scroll view up until the
    /// control is actually tappable, rather than swiping the whole app.
    func scrollToAndTap(in app: XCUIApplication, maxAttempts: Int = 3) {
        if waitForHittable(timeout: 2) {
            tap()
            return
        }
        var attempts = 0
        let scrollView = app.scrollViews.firstMatch
        while !waitForHittable(timeout: 1) && attempts < maxAttempts {
            scrollView.swipeUp()
            attempts += 1
        }
        tap()
    }
}
