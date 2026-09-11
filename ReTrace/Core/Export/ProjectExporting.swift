import Foundation
import UIKit

protocol ProjectExporting: Sendable {
    /// Renders the project to a PDF and returns the file's location.
    func export(_ model: PDFExportModel, mediaStore: MediaStoring) throws -> URL
}

enum ProjectExportError: Error {
    case renderFailed
}

struct PDFProjectExporter: ProjectExporting {
    func export(_ model: PDFExportModel, mediaStore: MediaStoring) throws -> URL {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 36
        let contentWidth = pageWidth - margin * 2
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReTrace-\(UUID().uuidString)")
            .appendingPathExtension("pdf")

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
        ]
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 15),
        ]
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        do {
            try renderer.writePDF(to: fileURL) { context in
                context.beginPage()
                var y: CGFloat = margin

                func draw(_ text: String, attributes: [NSAttributedString.Key: Any], spacingAfter: CGFloat = 8) {
                    let bounding = (text as NSString).boundingRect(
                        with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                        options: .usesLineFragmentOrigin,
                        attributes: attributes,
                        context: nil
                    )
                    if y + bounding.height > pageHeight - margin {
                        context.beginPage()
                        y = margin
                    }
                    (text as NSString).draw(
                        in: CGRect(x: margin, y: y, width: contentWidth, height: bounding.height),
                        withAttributes: attributes
                    )
                    y += bounding.height + spacingAfter
                }

                draw(model.projectTitle, attributes: titleAttributes)
                draw("Created \(dateFormatter.string(from: model.createdAt))", attributes: bodyAttributes, spacingAfter: 16)

                if let notes = model.notes, !notes.isEmpty {
                    draw("Notes", attributes: sectionAttributes)
                    draw(notes, attributes: bodyAttributes, spacingAfter: 16)
                }

                draw("Disassembly Timeline", attributes: sectionAttributes)
                if model.timeline.isEmpty {
                    draw("No steps recorded.", attributes: bodyAttributes)
                } else {
                    for entry in model.timeline {
                        var line = "\(entry.orderIndex + 1). \(entry.title)"
                        if let note = entry.note, !note.isEmpty {
                            line += " — \(note)"
                        }
                        draw(line, attributes: bodyAttributes, spacingAfter: 4)
                    }
                }
                y += 12

                draw("Parts", attributes: sectionAttributes)
                if model.parts.isEmpty {
                    draw("No parts recorded.", attributes: bodyAttributes)
                } else {
                    for part in model.parts {
                        var line = "\(part.quantity)× \(part.name)"
                        if let storage = part.storageLabel, !storage.isEmpty {
                            line += " (\(storage))"
                        }
                        draw(line, attributes: bodyAttributes, spacingAfter: 4)
                    }
                }
                y += 12

                draw("Connections", attributes: sectionAttributes)
                if model.connections.isEmpty {
                    draw("No connections recorded.", attributes: bodyAttributes)
                } else {
                    for connection in model.connections {
                        draw("\(connection.fromLabel) → \(connection.toLabel)", attributes: bodyAttributes, spacingAfter: 4)
                    }
                }
            }
        } catch {
            throw ProjectExportError.renderFailed
        }

        return fileURL
    }
}
