import Foundation
import SwiftData

@Model
final class RTProject {
    var id: UUID = UUID()
    var title: String = ""
    var categoryRawValue: String = RTProjectCategory.other.rawValue
    var statusRawValue: String = RTProjectStatus.draft.rawValue

    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var completedAt: Date?

    var coverImagePath: String?
    var notes: String?

    var isFavorite: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \RTStep.project)
    var steps: [RTStep] = []

    @Relationship(deleteRule: .cascade, inverse: \RTPart.project)
    var parts: [RTPart] = []

    @Relationship(deleteRule: .cascade, inverse: \RTConnection.project)
    var connections: [RTConnection] = []

    init(
        id: UUID = UUID(),
        title: String,
        category: RTProjectCategory = .other,
        status: RTProjectStatus = .draft,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        coverImagePath: String? = nil,
        notes: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.categoryRawValue = category.rawValue
        self.statusRawValue = status.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.coverImagePath = coverImagePath
        self.notes = notes
        self.isFavorite = isFavorite
    }

    var category: RTProjectCategory {
        get { .from(rawValue: categoryRawValue) }
        set { categoryRawValue = newValue.rawValue }
    }

    var status: RTProjectStatus {
        get { .from(rawValue: statusRawValue) }
        set { statusRawValue = newValue.rawValue }
    }

    var orderedSteps: [RTStep] {
        steps.sorted { $0.orderIndex < $1.orderIndex }
    }

    var restoreSteps: [RTStep] {
        RestoreSequenceEngine.restoreOrder(from: steps)
    }

    var completedRestoreStepCount: Int {
        steps.filter(\.isRestoreCompleted).count
    }

    var isReadyToRestore: Bool {
        status == .disassembled || status == .restoring
    }
}
