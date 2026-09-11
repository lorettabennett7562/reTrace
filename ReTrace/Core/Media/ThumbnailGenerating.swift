import Foundation
import UIKit

protocol ThumbnailGenerating: Sendable {
    func makeThumbnail(from originalData: Data, maxDimension: CGFloat) -> Data?
}

struct DefaultThumbnailGenerator: ThumbnailGenerating {
    func makeThumbnail(from originalData: Data, maxDimension: CGFloat = 320) -> Data? {
        guard let image = UIImage(data: originalData) else { return nil }
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }

        let scale = min(maxDimension / size.width, maxDimension / size.height, 1)
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.7)
    }
}

enum ImageProcessing {
    /// Downscales/compresses a full-resolution capture based on the user's
    /// chosen media quality setting. Runs off the main thread.
    static func processedOriginal(from data: Data, quality: RTImageQuality) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            guard let image = UIImage(data: data) else { return data }
            let maxDimension = quality.maxDimension
            let size = image.size
            guard size.width > maxDimension || size.height > maxDimension else {
                return image.jpegData(compressionQuality: quality.compressionQuality) ?? data
            }
            let scale = min(maxDimension / size.width, maxDimension / size.height)
            let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
            let resized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
            return resized.jpegData(compressionQuality: quality.compressionQuality) ?? data
        }.value
    }
}

enum RTImageQuality: String, Codable, Sendable, CaseIterable {
    case standard
    case high

    var maxDimension: CGFloat {
        switch self {
        case .standard: return 1280
        case .high: return 2048
        }
    }

    var compressionQuality: CGFloat {
        switch self {
        case .standard: return 0.6
        case .high: return 0.85
        }
    }

    var displayName: String {
        switch self {
        case .standard: return String(localized: "Standard")
        case .high: return String(localized: "High")
        }
    }
}
