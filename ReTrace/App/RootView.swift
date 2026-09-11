import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var settings = container.settingsStore
        Group {
            if settings.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    settings.hasCompletedOnboarding = true
                }
            }
        }
        .task {
            if LaunchEnvironment.isUITesting && LaunchEnvironment.seedSampleData {
                SampleDataSeeder.seed(into: modelContext, now: container.clock.now)
            }
        }
    }
}
