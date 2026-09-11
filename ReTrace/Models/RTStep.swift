import Foundation
import SwiftData

@Model
final class RTStep {
    var id: UUID = UUID()
    var project: RTProject?

    var orderIndex: Int = 0

    var title: String?
    var note: String?

    var imagePath: String?
    var thumbnailPath: String?

    var createdAt: Date = Date()

    var stepTypeRawValue: String = RTStepType.custom.rawValue

    var isRestoreCompleted: Bool = false

    @Relationship(inverse: \RTPart.linkedSteps)
    var parts: [RTPart] = []

    init(
        id: UUID = UUID(),
        orderIndex: Int,
        title: String? = nil,
        note: String? = nil,
        imagePath: String? = nil,
        thumbnailPath: String? = nil,
        createdAt: Date = Date(),
        stepType: RTStepType = .custom,
        isRestoreCompleted: Bool = false
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.title = title
        self.note = note
        self.imagePath = imagePath
        self.thumbnailPath = thumbnailPath
        self.createdAt = createdAt
        self.stepTypeRawValue = stepType.rawValue
        self.isRestoreCompleted = isRestoreCompleted
    }

    var stepType: RTStepType {
        get { .from(rawValue: stepTypeRawValue) }
        set { stepTypeRawValue = newValue.rawValue }
    }

    var displayTitle: String {
        title?.isEmpty == false ? title! : stepType.displayName
    }
}
