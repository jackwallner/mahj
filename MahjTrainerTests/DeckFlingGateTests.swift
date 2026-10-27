import XCTest
@testable import MahjTrainer

/// A double tap on Next during the throw must not grade the next card.
final class DeckFlingGateTests: XCTestCase {
    func testASecondThrowDuringTheFlingIsRefused() {
        var gate = DeckFlingGate()
        XCTAssertTrue(gate.begin())
        XCTAssertFalse(gate.begin())
        XCTAssertTrue(gate.isFlinging)
    }

    func testTheNextCardCanBeThrownOnceTheFlingLands() {
        var gate = DeckFlingGate()
        XCTAssertTrue(gate.begin())
        gate.end()
        XCTAssertFalse(gate.isFlinging)
        XCTAssertTrue(gate.begin())
    }
}

/// Two Next taps before the button hides: the second must find nothing to
/// advance, on every question and on the last one.
final class DrillNextTests: XCTestCase {
    /// The quiz, hand match and Charleston drills' advance, as state.
    private struct Drill {
        let count: Int
        var index = 0
        var answered = false
        var finished = false

        mutating func next() {
            guard DrillNext.allowed(answered: answered, finished: finished) else { return }
            if index + 1 < count {
                index += 1
                answered = false
            } else {
                finished = true
            }
        }
    }

    func testADoubleTapAdvancesOnce() {
        var drill = Drill(count: 3)
        drill.answered = true
        drill.next()
        drill.next()
        XCTAssertEqual(drill.index, 1)
        XCTAssertFalse(drill.finished)
    }

    func testADoubleTapOnTheSecondToLastNeverFinishesTheDrill() {
        var drill = Drill(count: 2)
        drill.answered = true
        drill.next()
        drill.next()
        XCTAssertEqual(drill.index, 1)
        XCTAssertFalse(drill.finished, "the last question was never answered")
        drill.answered = true
        drill.next()
        drill.next()
        XCTAssertTrue(drill.finished)
        XCTAssertEqual(drill.index, 1)
    }
}
