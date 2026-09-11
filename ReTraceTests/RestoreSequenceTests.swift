import XCTest
@testable import ReTrace

@MainActor
final class RestoreSequenceTests: XCTestCase {
    private func makeSteps(orderIndices: [Int]) -> [RTStep] {
        orderIndices.map { RTStep(orderIndex: $0, stepType: .custom) }
    }

    func testFiveStepsReverseCompletely() {
        let steps = makeSteps(orderIndices: [0, 1, 2, 3, 4])
        let restoreOrder = RestoreSequenceEngine.restoreOrder(from: steps).map(\.orderIndex)
        XCTAssertEqual(restoreOrder, [4, 3, 2, 1, 0])
    }

    func testEmptyProjectProducesEmptyRestoreSequence() {
        XCTAssertEqual(RestoreSequenceEngine.restoreOrder(from: []), [])
    }

    func testSingleStepRestoresAsSingleStep() {
        let steps = makeSteps(orderIndices: [0])
        let restoreOrder = RestoreSequenceEngine.restoreOrder(from: steps).map(\.orderIndex)
        XCTAssertEqual(restoreOrder, [0])
    }

    func testStepsWithMissingVisualAssetsRemainInValidOrder() {
        let steps = [
            RTStep(orderIndex: 0, imagePath: nil, stepType: .reference),
            RTStep(orderIndex: 1, imagePath: "some/path.jpg", stepType: .disconnect),
            RTStep(orderIndex: 2, imagePath: nil, stepType: .unplug),
        ]
        let restoreOrder = RestoreSequenceEngine.restoreOrder(from: steps).map(\.orderIndex)
        XCTAssertEqual(restoreOrder, [2, 1, 0])
    }

    func testDeletedMiddleStepStillProducesAValidNoncrashingSequence() {
        // Capture order 0, 1, 3, 4 (index 2 was deleted).
        let steps = makeSteps(orderIndices: [0, 1, 3, 4])
        let restoreOrder = RestoreSequenceEngine.restoreOrder(from: steps).map(\.orderIndex)
        XCTAssertEqual(restoreOrder, [4, 3, 1, 0])
    }

    func testCaptureOrderIsAscending() {
        let steps = makeSteps(orderIndices: [3, 1, 2, 0])
        let captureOrder = RestoreSequenceEngine.captureOrder(from: steps).map(\.orderIndex)
        XCTAssertEqual(captureOrder, [0, 1, 2, 3])
    }
}
