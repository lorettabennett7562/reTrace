import Foundation
import SwiftData

@Model
final class RTConnection {
    var id: UUID = UUID()
    var project: RTProject?
    var stepID: UUID?

    var fromLabel: String = ""
    var toLabel: String = ""

    var note: String?
    var imagePath: String?

    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        stepID: UUID? = nil,
        fromLabel: String,
        toLabel: String,
        note: String? = nil,
        imagePath: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.stepID = stepID
        self.fromLabel = fromLabel
        self.toLabel = toLabel
        self.note = note
        self.imagePath = imagePath
        self.createdAt = createdAt
    }

    var isValid: Bool {
        !fromLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !toLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
