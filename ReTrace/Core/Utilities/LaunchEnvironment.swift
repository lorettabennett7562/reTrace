import Foundation

/// Launch-argument switches used exclusively by XCUITest to make the app
/// deterministic: a clean in-memory store instead of real camera/persistence.
enum LaunchEnvironment {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    static var seedSampleData: Bool {
        ProcessInfo.processInfo.arguments.contains("--seed-sample-data")
    }

    static var skipOnboarding: Bool {
        ProcessInfo.processInfo.arguments.contains("--skip-onboarding")
    }

    /// Wipes real `UserDefaults` at launch so a UI test never inherits state
    /// left behind by an earlier test run.
    static var resetPersistentData: Bool {
        ProcessInfo.processInfo.arguments.contains("--reset-data")
    }

    /// UI tests can't reliably drive the system camera/photo picker across
    /// processes, so Capture feeds itself a placeholder image when this is set.
    static var useMockCamera: Bool {
        ProcessInfo.processInfo.arguments.contains("-useMockCamera")
            || ProcessInfo.processInfo.arguments.contains("--use-mock-camera")
    }
}
