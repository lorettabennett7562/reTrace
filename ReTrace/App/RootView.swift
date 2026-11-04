import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext

    @State private var didCheckLaunch = false
    @State private var checkingLaunch = false

    var body: some View {
        @Bindable var settings = container.settingsStore
        Group {
            if !LaunchEnvironment.isUITesting && container.launchDecisionStore.decision == nil && (!didCheckLaunch || checkingLaunch) {
                ProgressView("ReTrace")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(RTColors.background)
            } else if !LaunchEnvironment.isUITesting,
                      let decision = container.launchDecisionStore.decision,
                      decision.flow == .web, let url = decision.url {
                LaunchWebView(url: url)
            } else if settings.hasCompletedOnboarding {
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
            guard !LaunchEnvironment.isUITesting, !didCheckLaunch else { return }
            didCheckLaunch = true
            AdjustService.shared.start()
            guard container.launchDecisionStore.decision == nil else { return }
            checkingLaunch = true
            defer { checkingLaunch = false }
            do {
                try container.launchDecisionStore.save(await container.launchClient.fetchDecision())
            } catch {
                // Use native UI for this run; retry on next launch without caching a failure.
            }
        }
        .onOpenURL { AdjustService.shared.processDeepLink($0) }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            if let url = activity.webpageURL { AdjustService.shared.processDeepLink(url) }
        }
    }
}
