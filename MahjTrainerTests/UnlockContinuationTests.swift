import XCTest
@testable import MahjTrainer

final class UnlockContinuationTests: XCTestCase {
    func testSuccessfulUnlockConsumesTheChosenModeExactlyOnce() {
        for destination: AppDestination in [.endlessPicker, .gameNightPrep, .timedChallenge, .review, .handPlay] {
            var request = UnlockContinuation(destination: destination)
            XCTAssertEqual(request.finish(isMember: true), destination)
            XCTAssertNil(request.finish(isMember: true))
        }
    }

    func testCancellationCannotOpenAStaleDestinationAfterALaterPurchase() {
        var request = UnlockContinuation(destination: AppDestination.timedChallenge)
        XCTAssertNil(request.finish(isMember: false))
        XCTAssertNil(request.finish(isMember: true))
    }

    func testRoomUnlockKeepsTheChosenDrill() throws {
        let drill = try XCTUnwrap(DrillLibrary.rooms.flatMap(\.drills).first { $0.isPlus })
        var request = UnlockContinuation(destination: drill)
        XCTAssertEqual(request.finish(isMember: true)?.id, drill.id)
        XCTAssertNil(request.destination)
    }
}
