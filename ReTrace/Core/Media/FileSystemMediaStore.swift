import Foundation

/// Stores media under `<root>/Media/<ProjectUUID>/<MediaUUID>.jpg` and
/// `<root>/Thumbnails/<ProjectUUID>/<MediaUUID>.jpg`, using UUID-based
/// filenames only — never a user-entered project title — so unrelated
/// projects can never collide on disk.
final class FileSystemMediaStore: MediaStoring {
    private let rootDirectory: URL
    private let fileManager: FileManager

    init(rootDirectory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let rootDirectory {
            self.rootDirectory = rootDirectory
        } else {
            let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.rootDirectory = base.appendingPathComponent("ReTrace", isDirectory: true)
        }
    }

    @discardableResult
    func saveOriginal(_ data: Data, projectID: UUID, mediaID: UUID) throws -> String {
        try save(data, subdirectory: "Media", projectID: projectID, mediaID: mediaID)
    }

    @discardableResult
    func saveThumbnail(_ data: Data, projectID: UUID, mediaID: UUID) throws -> String {
        try save(data, subdirectory: "Thumbnails", projectID: projectID, mediaID: mediaID)
    }

    func loadData(atRelativePath path: String) -> Data? {
        fileManager.contents(atPath: absoluteURL(for: path).path)
    }

    func delete(atRelativePath path: String) {
        try? fileManager.removeItem(at: absoluteURL(for: path))
    }

    func deleteAll(forProjectID projectID: UUID) {
        for subdirectory in ["Media", "Thumbnails"] {
            let directory = rootDirectory
                .appendingPathComponent(subdirectory, isDirectory: true)
                .appendingPathComponent(projectID.uuidString, isDirectory: true)
            try? fileManager.removeItem(at: directory)
        }
    }

    private func save(_ data: Data, subdirectory: String, projectID: UUID, mediaID: UUID) throws -> String {
        let directory = rootDirectory
            .appendingPathComponent(subdirectory, isDirectory: true)
            .appendingPathComponent(projectID.uuidString, isDirectory: true)
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw MediaStoreError.writeFailed
        }

        let relativePath = "\(subdirectory)/\(projectID.uuidString)/\(mediaID.uuidString).jpg"
        let fileURL = absoluteURL(for: relativePath)
        guard fileManager.createFile(atPath: fileURL.path, contents: data) else {
            throw MediaStoreError.writeFailed
        }
        return relativePath
    }

    private func absoluteURL(for relativePath: String) -> URL {
        rootDirectory.appendingPathComponent(relativePath)
    }
}
