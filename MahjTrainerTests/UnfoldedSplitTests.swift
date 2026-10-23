import XCTest
@testable import MahjTrainer

/// The unfolded iPhone Duo puts Home and the room it opened on opposite
/// sides of the fold. Everything else keeps the phone's single column.
final class UnfoldedSplitTests: XCTestCase {
    func testCompactWidthNeverSplits() {
        // The folded Duo's outer display, and every other iPhone.
        XCTAssertNil(UnfoldedSplit.make(width: 466, isRegularWidth: false, fold: nil))
        XCTAssertNil(UnfoldedSplit.make(width: 951, isRegularWidth: false, fold: 470...481))
    }

    func testRegularWidthTooNarrowForTwoPanesStaysOneColumn() {
        // The unfolded Duo held in portrait: two halves under 360 pt each.
        XCTAssertNil(UnfoldedSplit.make(width: 669, isRegularWidth: true, fold: nil))
        XCTAssertNil(UnfoldedSplit.make(width: 719, isRegularWidth: true, fold: nil))
    }

    func testPanesMeetTheFoldEdges() {
        let split = UnfoldedSplit.make(width: 951, isRegularWidth: true, fold: 470...481)
        XCTAssertEqual(split, UnfoldedSplit(primaryWidth: 470, secondaryX: 481, secondaryWidth: 470))
    }

    func testNoReportedFoldSplitsEvenly() {
        let split = UnfoldedSplit.make(width: 951, isRegularWidth: true, fold: nil)
        XCTAssertEqual(split, UnfoldedSplit(primaryWidth: 475, secondaryX: 475, secondaryWidth: 476))
    }

    func testFoldThatLeavesANarrowPaneFallsBackToEvenSplit() {
        // A fold off to one side would squeeze a pane under the phone width.
        let split = UnfoldedSplit.make(width: 951, isRegularWidth: true, fold: 300...310)
        XCTAssertEqual(split, UnfoldedSplit(primaryWidth: 475, secondaryX: 475, secondaryWidth: 476))
    }

    func testPanesNeverOverlapOrSpillPastTheWidth() {
        for width in stride(from: CGFloat(720), through: 1400, by: 37) {
            for fold in [nil, (width / 2 - 6)...(width / 2 + 6)] as [ClosedRange<CGFloat>?] {
                guard let split = UnfoldedSplit.make(width: width, isRegularWidth: true, fold: fold) else {
                    return XCTFail("no split at \(width)")
                }
                XCTAssertGreaterThanOrEqual(split.primaryWidth, UnfoldedSplit.minimumPaneWidth)
                XCTAssertGreaterThanOrEqual(split.secondaryWidth, UnfoldedSplit.minimumPaneWidth)
                XCTAssertGreaterThanOrEqual(split.secondaryX, split.primaryWidth)
                XCTAssertEqual(split.secondaryX + split.secondaryWidth, width, accuracy: 0.001)
            }
        }
    }
}
