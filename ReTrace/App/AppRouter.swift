import Foundation
import Observation

enum AppTab: String, CaseIterable, Identifiable {
    case projects
    case capture
    case parts
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .projects: return String(localized: "Projects")
        case .capture: return String(localized: "Capture")
        case .parts: return String(localized: "Parts")
        case .settings: return String(localized: "Settings")
        }
    }

    var symbolName: String {
        switch self {
        case .projects: return "square.stack.3d.up"
        case .capture: return "camera.viewfinder"
        case .parts: return "shippingbox"
        case .settings: return "gearshape"
        }
    }
}

enum ReTraceRoute: Hashable {
    case projectDetail(projectID: UUID)
    case restore(projectID: UUID)
}

@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .projects

    var projectsPath: [ReTraceRoute] = []
    var partsPath: [ReTraceRoute] = []

    /// The project Capture currently continues into, if any. `nil` means
    /// Capture offers to start a brand-new project.
    var activeProjectID: UUID?

    func openProjectDetail(_ projectID: UUID, from tab: AppTab? = nil) {
        let targetTab = tab ?? selectedTab
        selectedTab = targetTab
        switch targetTab {
        case .projects: projectsPath.append(.projectDetail(projectID: projectID))
        case .parts: partsPath.append(.projectDetail(projectID: projectID))
        case .capture, .settings: projectsPath.append(.projectDetail(projectID: projectID))
        }
    }

    func continueCapture(for projectID: UUID) {
        activeProjectID = projectID
        selectedTab = .capture
    }

    func openRestore(for projectID: UUID) {
        selectedTab = .projects
        projectsPath.append(.restore(projectID: projectID))
    }
}
