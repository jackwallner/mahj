import XCTest
@testable import MahjTrainer

/// Home's training row has no "swipe for more" label: the tile cut off at
/// the trailing edge is the cue that it scrolls, so one must be cut at
/// every phone width.
final class HomeLayoutTests: XCTestCase {
    func testTheTrainingRowAlwaysEndsPartwayThroughATile() {
        // iPhone SE and 13 mini up to the Pro Max, plus compact iPad widths.
        for width in [375, 390, 393, 402, 414, 428, 430, 440, 507, 694] as [CGFloat] {
            let tile = TrainingCarousel.tileWidth(rowWidth: width)
            XCTAssertGreaterThanOrEqual(tile, TrainingCarousel.minimumTileWidth, "at \(width)")
            let stride = tile + TrainingCarousel.spacing
            let shown = (width - TrainingCarousel.leadingInset + TrainingCarousel.spacing) / stride
            let cut = shown - shown.rounded(.down)
            XCTAssertGreaterThan(cut, 0.25, "at \(width) the last tile is almost hidden")
            XCTAssertLessThan(cut, 0.6, "at \(width) the last tile reads as whole")
        }
    }
}
