import Foundation
import SwiftData
import Observation

/// Single composition root. Every screen reads its dependencies from here
/// (via the SwiftUI environment) instead of reaching for singletons, so
/// tests and previews can swap in fakes.
@MainActor
@Observable
final class AppContainer {
    let modelContainer: ModelContainer
    let settingsStore: AppSettingsStore

    let clock: ClockProviding
    let mediaStore: MediaStoring
    let thumbnailGenerator: ThumbnailGenerating
    let notificationScheduler: NotificationScheduling
    let notificationPlanner: NotificationPlanning
    let exporter: ProjectExporting

    init(
        modelContainer: ModelContainer,
        settingsStore: AppSettingsStore? = nil,
        clock: ClockProviding? = nil,
        mediaStore: MediaStoring? = nil,
        thumbnailGenerator: ThumbnailGenerating? = nil,
        notificationScheduler: NotificationScheduling? = nil,
        notificationPlanner: NotificationPlanning? = nil,
        exporter: ProjectExporting? = nil
    ) {
        self.modelContainer = modelContainer
        self.settingsStore = settingsStore ?? AppSettingsStore()
        self.clock = clock ?? SystemClock()
        self.mediaStore = mediaStore ?? FileSystemMediaStore()
        self.thumbnailGenerator = thumbnailGenerator ?? DefaultThumbnailGenerator()
        self.notificationScheduler = notificationScheduler ?? NotificationCoordinator()
        self.notificationPlanner = notificationPlanner ?? DefaultNotificationPlanner()
        self.exporter = exporter ?? PDFProjectExporter()
    }

    func mutationService(context: ModelContext) -> ProjectMutationService {
        ProjectMutationService(
            modelContext: context,
            clock: clock,
            mediaStore: mediaStore,
            notificationScheduler: notificationScheduler
        )
    }

    @MainActor
    static func makeDefault() -> AppContainer {
        let modelContainer = ModelContainerFactory.makeContainer()
        return AppContainer(modelContainer: modelContainer)
    }

    @MainActor
    static func makePreview() -> AppContainer {
        let modelContainer = ModelContainerFactory.makeContainer(inMemory: true)
        return AppContainer(
            modelContainer: modelContainer,
            settingsStore: AppSettingsStore(defaults: UserDefaults(suiteName: "preview") ?? .standard)
        )
    }
}
