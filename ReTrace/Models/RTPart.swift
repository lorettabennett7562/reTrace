import Foundation
import SwiftData

@Model
final class RTPart {
    var id: UUID = UUID()
    var project: RTProject?

    var name: String = ""
    var quantity: Int = 1

    var storageLabel: String?
    var note: String?

    var imagePath: String?

    var createdAt: Date = Date()

    @Relationship
    var linkedSteps: [RTStep] = []

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Int = 1,
        storageLabel: String? = nil,
        note: String? = nil,
        imagePath: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.quantity = max(0, quantity)
        self.storageLabel = storageLabel
        self.note = note
        self.imagePath = imagePath
        self.createdAt = createdAt
    }
}
