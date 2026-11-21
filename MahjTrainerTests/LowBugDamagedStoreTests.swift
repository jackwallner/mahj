import XCTest
@testable import MahjTrainer

/// B4: one unreadable saved record must not wipe a store's history.
extension LowBugRegressionTests {
    // MARK: B4 one unreadable record must not wipe the history

    private func record(correct: Int = 1) -> PracticeRecord {
        var record = PracticeRecord()
        record.attempts = 2
        record.correct = correct
        record.roomID = "tile-room"
        return record
    }

    private func blob<T: Encodable>(_ good: [String: T], damaged: [String: Any]) throws -> Data {
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(good)) as? [String: Any] ?? [:]
        object.merge(damaged) { _, new in new }
        return try JSONSerialization.data(withJSONObject: object)
    }

    func testOneDamagedPracticeRecordKeepsTheRestAndTheNextAnswerDoesNotWipeThem() throws {
        let defaults = freshDefaults("LowBugPracticeRecords")
        defaults.set(try blob(["tile-a": record(), "tile-b": record()], damaged: ["tile-c": ["attempts": "many"]]),
                     forKey: "practice.records")
        let store = PracticeRecordStore(defaults: defaults)
        XCTAssertEqual(Set(store.records.keys), ["tile-a", "tile-b"])
        store.record(itemID: "tile-d", roomID: "tile-room", correct: true)
        let reopened = PracticeRecordStore(defaults: defaults)
        XCTAssertEqual(Set(reopened.records.keys), ["tile-a", "tile-b", "tile-d"])
        XCTAssertNotNil(defaults.data(forKey: "practice.records.unreadable"), "the damaged blob is kept for recovery")
    }

    func testAWholeUnreadableBlobIsKeptBeforeTheFirstWrite() {
        let defaults = freshDefaults("LowBugPracticeWhole")
        let junk = Data("not json".utf8)
        defaults.set(junk, forKey: "practice.records")
        let store = PracticeRecordStore(defaults: defaults)
        XCTAssertTrue(store.records.isEmpty)
        store.record(itemID: "tile-a", roomID: "tile-room", correct: true)
        XCTAssertEqual(defaults.data(forKey: "practice.records.unreadable"), junk)
    }

    func testOneDamagedLedgerDayKeepsTheOthers() throws {
        let defaults = freshDefaults("LowBugLedger")
        defaults.set(try blob(["2026-11-01": ["tile-room": 4]], damaged: ["2026-11-02": "oops"]), forKey: "mastery.ledger")
        let ledger = MasteryLedger(defaults: defaults)
        XCTAssertEqual(ledger.days["2026-11-01"], ["tile-room": 4])
        ledger.record([], now: Date())
        XCTAssertEqual(MasteryLedger(defaults: defaults).days["2026-11-01"], ["tile-room": 4])
    }

    func testOneDamagedMahjMinuteResultKeepsTheOthers() throws {
        let defaults = freshDefaults("LowBugMinute")
        let good = MahjMinuteResult(dayKey: "2026-11-01", shortDate: "11/01", completedAt: Date(), answers: [true, false],
                                    correctByCategory: [:], totalByCategory: [:])
        defaults.set(try blob(["2026-11-01": good], damaged: ["2026-11-02": ["answers": 7]]), forKey: "mahjMinute.results")
        XCTAssertEqual(Array(MahjMinuteStore(defaults: defaults).results.keys), ["2026-11-01"])
    }

    func testOneDamagedChallengeRoundKeepsTheOthers() throws {
        let defaults = freshDefaults("LowBugChallenge")
        let good = MonthlyChallengeProgress(answers: [true], picks: [1], fingerprints: ["x"])
        defaults.set(try blob(["2026-11-01": good], damaged: ["2026-11-02": ["answers": "no"]]), forKey: "monthlyChallenge.roundProgress")
        XCTAssertEqual(Array(MonthlyChallengeStore(defaults: defaults).inProgress.keys), ["2026-11-01"])
    }
}
