import UIKit
import XCTest
@testable import ReTrace

@MainActor
final class MediaStorageTests: XCTestCase {
    func testSaveImageReturnsAStoredPath() throws {
        let temp = TemporaryMediaStore()
        defer { temp.cleanUp() }

        let projectID = UUID()
        let mediaID = UUID()
        let path = try temp.store.saveOriginal(Data([0x01, 0x02]), projectID: projectID, mediaID: mediaID)

        XCTAssertTrue(path.contains(projectID.uuidString))
        XCTAssertTrue(path.contains(mediaID.uuidString))
        XCTAssertNotNil(temp.store.loadData(atRelativePath: path))
    }

    func testGenerateThumbnailProducesData() {
        let generator = DefaultThumbnailGenerator()
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        guard let data = image.pngData() else {
            return XCTFail("Failed to render source image")
        }
        let thumbnail = generator.makeThumbnail(from: data, maxDimension: 64)
        XCTAssertNotNil(thumbnail)
    }

    func testDeleteImageRemovesBothOriginalAndThumbnail() throws {
        let temp = TemporaryMediaStore()
        defer { temp.cleanUp() }

        let projectID = UUID()
        let mediaID = UUID()
        let originalPath = try temp.store.saveOriginal(Data([0x01]), projectID: projectID, mediaID: mediaID)
        let thumbnailPath = try temp.store.saveThumbnail(Data([0x02]), projectID: projectID, mediaID: mediaID)

        temp.store.delete(atRelativePath: originalPath)
        temp.store.delete(atRelativePath: thumbnailPath)

        XCTAssertNil(temp.store.loadData(atRelativePath: originalPath))
        XCTAssertNil(temp.store.loadData(atRelativePath: thumbnailPath))
    }

    func testReadingAMissingFileReturnsNilWithoutCrashing() {
        let temp = TemporaryMediaStore()
        defer { temp.cleanUp() }
        XCTAssertNil(temp.store.loadData(atRelativePath: "Media/does-not-exist/missing.jpg"))
    }

    func testDuplicateFilenamesNeverOverwriteUnrelatedProjectMedia() throws {
        let temp = TemporaryMediaStore()
        defer { temp.cleanUp() }

        let projectA = UUID()
        let projectB = UUID()
        let mediaID = UUID() // Same media UUID reused across two different projects.

        let pathA = try temp.store.saveOriginal(Data([0xAA]), projectID: projectA, mediaID: mediaID)
        let pathB = try temp.store.saveOriginal(Data([0xBB]), projectID: projectB, mediaID: mediaID)

        XCTAssertNotEqual(pathA, pathB)
        XCTAssertEqual(temp.store.loadData(atRelativePath: pathA), Data([0xAA]))
        XCTAssertEqual(temp.store.loadData(atRelativePath: pathB), Data([0xBB]))
    }

    func testDeleteAllForProjectRemovesEveryFileUnderThatProject() throws {
        let temp = TemporaryMediaStore()
        defer { temp.cleanUp() }

        let projectID = UUID()
        let firstMedia = UUID()
        let secondMedia = UUID()
        let path1 = try temp.store.saveOriginal(Data([0x01]), projectID: projectID, mediaID: firstMedia)
        let path2 = try temp.store.saveOriginal(Data([0x02]), projectID: projectID, mediaID: secondMedia)

        temp.store.deleteAll(forProjectID: projectID)

        XCTAssertNil(temp.store.loadData(atRelativePath: path1))
        XCTAssertNil(temp.store.loadData(atRelativePath: path2))
    }
}
