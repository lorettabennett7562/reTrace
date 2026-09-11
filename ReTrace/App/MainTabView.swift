import SwiftUI

struct MainTabView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.projectsPath) {
                ProjectsView()
                    .navigationDestination(for: ReTraceRoute.self, destination: destination)
            }
            .tabItem { Label(AppTab.projects.title, systemImage: AppTab.projects.symbolName) }
            .tag(AppTab.projects)
            .accessibilityIdentifier("tab.projects")

            NavigationStack {
                CaptureView()
            }
            .tabItem { Label(AppTab.capture.title, systemImage: AppTab.capture.symbolName) }
            .tag(AppTab.capture)
            .accessibilityIdentifier("tab.capture")

            NavigationStack(path: $router.partsPath) {
                PartsView()
                    .navigationDestination(for: ReTraceRoute.self, destination: destination)
            }
            .tabItem { Label(AppTab.parts.title, systemImage: AppTab.parts.symbolName) }
            .tag(AppTab.parts)
            .accessibilityIdentifier("tab.parts")

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.symbolName) }
            .tag(AppTab.settings)
            .accessibilityIdentifier("tab.settings")
        }
        .tint(RTColors.accent)
    }

    @ViewBuilder
    private func destination(for route: ReTraceRoute) -> some View {
        switch route {
        case .projectDetail(let projectID):
            ProjectDetailView(projectID: projectID)
        case .restore(let projectID):
            RestoreView(projectID: projectID)
        }
    }
}
