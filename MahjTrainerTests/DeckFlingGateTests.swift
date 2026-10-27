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
