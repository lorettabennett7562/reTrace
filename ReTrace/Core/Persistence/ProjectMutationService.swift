import Foundation
import SwiftData

enum ProjectMutationError: Error, Equatable {
    case invalidTransition
    case invalidQuantity
    case invalidConnection
}

/// Centralizes every state transition and mutation a project can go through,
/// so the rules (valid statuses, cascading deletes, orphan-media cleanup)
/// live in one tested place instead of being duplicated across views.
@MainActor
struct ProjectMutationService {
    let modelContext: ModelContext
    let clock: ClockProviding
    let mediaStore: MediaStoring
    let notificationScheduler: NotificationScheduling?

    init(
        modelContext: ModelContext,
        clock: ClockProviding = SystemClock(),
        mediaStore: MediaStoring = FileSystemMediaStore(),
        notificationScheduler: NotificationScheduling? = nil
    ) {
        self.modelContext = modelContext
        self.clock = clock
        self.mediaStore = mediaStore
        self.notificationScheduler = notificationScheduler
    }

    // MARK: - Status transitions

    @discardableResult
    func transition(_ project: RTProject, to newStatus: RTProjectStatus) throws -> RTProject {
        guard project.status.canTransition(to: newStatus) else { throw ProjectMutationError.invalidTransition }
        project.status = newStatus
        project.updatedAt = clock.now
        if newStatus == .completed {
            project.completedAt = clock.now
        }
        return project
    }

    func startCapture(_ project: RTProject) throws {
        try transition(project, to: .capturing)
    }

    func finishDisassembly(_ project: RTProject) throws {
        try transition(project, to: .disassembled)
    }

    func startRestore(_ project: RTProject) throws {
        try transition(project, to: .restoring)
    }

    func completeProject(_ project: RTProject) throws {
        try transition(project, to: .completed)
        notificationScheduler?.cancelReminder(projectID: project.id)
    }

    func archiveProject(_ project: RTProject) throws {
        try transition(project, to: .archived)
    }

    // MARK: - Steps

    @discardableResult
    func addStep(
        to project: RTProject,
        title: String? = nil,
        note: String? = nil,
        stepType: RTStepType,
        imagePath: String? = nil,
        thumbnailPath: String? = nil
    ) -> RTStep {
        let step = RTStep(
            orderIndex: RestoreSequenceEngine.nextOrderIndex(for: project.steps),
            title: title,
            note: note,
            imagePath: imagePath,
            thumbnailPath: thumbnailPath,
            createdAt: clock.now,
            stepType: stepType
        )
        step.project = project
        modelContext.insert(step)
        project.updatedAt = clock.now
        if project.status == .draft {
            project.status = .capturing
        }
        return step
    }

    func deleteStep(_ step: RTStep) {
        if let path = step.imagePath { mediaStore.delete(atRelativePath: path) }
        if let path = step.thumbnailPath { mediaStore.delete(atRelativePath: path) }
        if let project = step.project {
            project.updatedAt = clock.now
            project.steps.removeAll { $0.id == step.id }
        }
        modelContext.delete(step)
    }

    func markRestoreStepDone(_ step: RTStep, done: Bool) {
        step.isRestoreCompleted = done
        step.project?.updatedAt = clock.now
    }

    // MARK: - Parts

    @discardableResult
    func addPart(
        to project: RTProject,
        name: String,
        quantity: Int = 1,
        storageLabel: String? = nil,
        note: String? = nil,
        imagePath: String? = nil,
        linkedStep: RTStep? = nil
    ) -> RTPart {
        let part = RTPart(
            name: name,
            quantity: max(0, quantity),
            storageLabel: storageLabel,
            note: note,
            imagePath: imagePath,
            createdAt: clock.now
        )
        part.project = project
        if let linkedStep {
            part.linkedSteps.append(linkedStep)
        }
        modelContext.insert(part)
        project.updatedAt = clock.now
        return part
    }

    func updatePartQuantity(_ part: RTPart, to quantity: Int) throws {
        guard quantity >= 0 else { throw ProjectMutationError.invalidQuantity }
        part.quantity = quantity
        part.project?.updatedAt = clock.now
    }

    func deletePart(_ part: RTPart) {
        if let path = part.imagePath { mediaStore.delete(atRelativePath: path) }
        if let project = part.project {
            project.updatedAt = clock.now
            project.parts.removeAll { $0.id == part.id }
        }
        modelContext.delete(part)
    }

    // MARK: - Connections

    @discardableResult
    func addConnection(
        to project: RTProject,
        stepID: UUID? = nil,
        fromLabel: String,
        toLabel: String,
        note: String? = nil,
        imagePath: String? = nil
    ) throws -> RTConnection {
        let trimmedFrom = fromLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTo = toLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFrom.isEmpty, !trimmedTo.isEmpty else { throw ProjectMutationError.invalidConnection }

        let connection = RTConnection(
            stepID: stepID,
            fromLabel: trimmedFrom,
            toLabel: trimmedTo,
            note: note,
            imagePath: imagePath,
            createdAt: clock.now
        )
        connection.project = project
        modelContext.insert(connection)
        project.updatedAt = clock.now
        return connection
    }

    func deleteConnection(_ connection: RTConnection) {
        if let path = connection.imagePath { mediaStore.delete(atRelativePath: path) }
        if let project = connection.project {
            project.updatedAt = clock.now
            project.connections.removeAll { $0.id == connection.id }
        }
        modelContext.delete(connection)
    }

    // MARK: - Project lifecycle

    @discardableResult
    func createProject(
        title: String,
        category: RTProjectCategory = .other,
        notes: String? = nil,
        coverImagePath: String? = nil
    ) -> RTProject {
        let project = RTProject(
            title: title,
            category: category,
            status: .draft,
            createdAt: clock.now,
            updatedAt: clock.now,
            coverImagePath: coverImagePath,
            notes: notes
        )
        modelContext.insert(project)
        return project
    }

    /// Deletes a project and every dependent record. SwiftData's cascade
    /// delete rules remove the child rows; this additionally cleans up local
    /// media and pending notifications so nothing orphaned is left behind.
    func deleteProject(_ project: RTProject) {
        if let path = project.coverImagePath { mediaStore.delete(atRelativePath: path) }
        mediaStore.deleteAll(forProjectID: project.id)
        notificationScheduler?.cancelReminder(projectID: project.id)
        modelContext.delete(project)
    }
}
