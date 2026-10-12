import XCTest
@testable import MahjTrainer

@MainActor
final class MasteryLedgerTests: XCTestCase {
    private var ledger: MasteryLedger!
    private let day: TimeInterval = 86_400

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "MasteryLedgerTests")!
        defaults.removePersistentDomain(forName: "MasteryLedgerTests")
        ledger = MasteryLedger(defaults: defaults)
    }

    private func mastery(_ known: [String: Int]) -> [RoomMastery] {
        known.map { RoomMastery(roomID: $0.key, known: $0.value, total: 40, level: .learning) }
    }

    func testNoGainWithoutABaselineDay() {
        let now = Date()
        ledger.record(mastery(["tile-room": 5]), now: now)
        XCTAssertNil(ledger.weeklyGain(now: now), "the first day has nothing to measure from")
    }

    func testGainIsMeasuredFromTheOldestDayInTheWindow() {
        let now = Date()
        ledger.record(mastery(["tile-room": 5]), now: now.addingTimeInterval(-6 * day))
        ledger.record(mastery(["tile-room": 9]), now: now.addingTimeInterval(-3 * day))
        ledger.record(mastery(["tile-room": 12, "card-room": 4]), now: now)
        XCTAssertEqual(ledger.weeklyGain(now: now), 11)
        XCTAssertEqual(ledger.strongestRoom(now: now)?.roomID, "tile-room")
        XCTAssertEqual(ledger.strongestRoom(now: now)?.gain, 7)
    }

    func testEntriesOlderThanTheWindowAreNotTheBaseline() {
        let now = Date()
        ledger.record(mastery(["tile-room": 0]), now: now.addingTimeInterval(-30 * day))
        ledger.record(mastery(["tile-room": 20]), now: now.addingTimeInterval(-2 * day))
        ledger.record(mastery(["tile-room": 22]), now: now)
        XCTAssertEqual(ledger.weeklyGain(now: now), 2)
    }

    func testBackwardsWeeksAreReportedAsNothing() {
        let now = Date()
        ledger.record(mastery(["tile-room": 20]), now: now.addingTimeInterval(-4 * day))
        ledger.record(mastery(["tile-room": 15]), now: now)
        XCTAssertNil(ledger.weeklyGain(now: now))
    }

    func testSameDayRecordsOverwrite() {
        let now = Date()
        ledger.record(mastery(["tile-room": 3]), now: now.addingTimeInterval(-1 * day))
        ledger.record(mastery(["tile-room": 4]), now: now)
        ledger.record(mastery(["tile-room": 8]), now: now)
        XCTAssertEqual(ledger.weeklyGain(now: now), 5)
        XCTAssertEqual(ledger.days.count, 2)
    }

    func testPersistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: "MasteryLedgerTests")!
        let now = Date()
        ledger.record(mastery(["tile-room": 3]), now: now.addingTimeInterval(-1 * day))
        ledger.record(mastery(["tile-room": 9]), now: now)
        let reloaded = MasteryLedger(defaults: defaults)
        XCTAssertEqual(reloaded.weeklyGain(now: now), 6)
    }
}
