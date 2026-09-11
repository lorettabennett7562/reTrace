import Foundation

/// Plain data model describing everything a project export needs. Kept
/// separate from PDF rendering so the model itself is deterministically
/// testable without touching `UIGraphicsPDFRenderer`.
struct PDFExportModel: Equatable {
    struct TimelineEntry: Equatable {
        let orderIndex: Int
        let title: String
        let note: String?
        let imagePath: String?
    }

    struct PartEntry: Equatable {
        let name: String
        let quantity: Int
        let storageLabel: String?
    }

    struct ConnectionEntry: Equatable {
        let fromLabel: String
        let toLabel: String
        let note: String?
    }

    let projectTitle: String
    let createdAt: Date
    let timeline: [TimelineEntry]
    let notes: String?
    let parts: [PartEntry]
    let connections: [ConnectionEntry]
}

enum PDFExportModelBuilder {
    static func build(from project: RTProject) -> PDFExportModel {
        PDFExportModel(
            projectTitle: project.title,
            createdAt: project.createdAt,
            timeline: RestoreSequenceEngine.captureOrder(from: project.steps).map { step in
                PDFExportModel.TimelineEntry(
                    orderIndex: step.orderIndex,
                    title: step.displayTitle,
                    note: step.note,
                    imagePath: step.imagePath
                )
            },
            notes: project.notes,
            parts: project.parts.map { part in
                PDFExportModel.PartEntry(name: part.name, quantity: part.quantity, storageLabel: part.storageLabel)
            },
            connections: project.connections.map { connection in
                PDFExportModel.ConnectionEntry(
                    fromLabel: connection.fromLabel,
                    toLabel: connection.toLabel,
                    note: connection.note
                )
            }
        )
    }
}
