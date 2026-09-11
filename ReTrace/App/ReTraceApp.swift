import SwiftData
import SwiftUI

@main
struct ReTraceApp: App {
    @State private var container: AppContainer
    @State private var router = AppRouter()

    init() {
        _container = State(initialValue: ReTraceApp.buildContainer())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .environment(router)
                .modelContainer(container.modelContainer)
                .preferredColorScheme(container.settingsStore.colorSchemePreference.colorScheme)
        }
    }

    @MainActor
    private static func buildContainer() -> AppContainer {
        let inMemory = LaunchEnvironment.isUITesting
        if LaunchEnvironment.resetPersistentData, let bundleID = Bundle.main.bundleIdentifier {
            // Guarantees a UI test starts from a truly clean slate, regardless
            // of what earlier runs left in the simulator.
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        let modelContainer = ModelContainerFactory.makeContainer(inMemory: inMemory)
        let settingsStore = AppSettingsStore()

        // Only forces onboarding to be skipped when explicitly requested —
        // never forces it back to incomplete, so a UI test can relaunch the
        // app and still see onboarding-completed state it just persisted.
        if LaunchEnvironment.skipOnboarding {
            settingsStore.hasCompletedOnboarding = true
        }

        return AppContainer(modelContainer: modelContainer, settingsStore: settingsStore)
    }
}
