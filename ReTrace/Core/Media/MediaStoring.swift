import Foundation

enum MediaStoreError: Error, Equatable {
    case writeFailed
    case notFound
}

/// Persists step/part/connection reference photos to local disk. Paths
/// returned are relative to the store's root so they remain valid across
/// app container moves between OS versions.
protocol MediaStoring: Sendable {
    @discardableResult
    func saveOriginal(_ data: Data, projectID: UUID, mediaID: UUID) throws -> String

    @discardableResult
    func saveThumbnail(_ data: Data, projectID: UUID, mediaID: UUID) throws -> String

    func loadData(atRelativePath path: String) -> Data?

    func delete(atRelativePath path: String)

    /// Removes every original and thumbnail stored for a project. Called
    /// when a project is deleted so no orphan media is left behind.
    func deleteAll(forProjectID projectID: UUID)
}
