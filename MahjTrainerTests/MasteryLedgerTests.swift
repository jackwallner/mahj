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

    // MARK: - Membership changes are not learning (state machine audit SM-03)

    private func freshDefaults(_ name: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private var plusOnlyIDs: [String] {
        let all = DrillLibrary.rooms.flatMap { PracticeRecordStore.trackableItemIDs(in: $0, isMember: true) }
        let open = Set(DrillLibrary.rooms.flatMap { PracticeRecordStore.trackableItemIDs(in: $0, isMember: false) })
        return all.filter { !open.contains($0) }.sorted()
    }

    private func knowTwoPlusQuestions(_ store: PracticeRecordStore, at when: Date) {
        for id in plusOnlyIDs.prefix(2) {
            store.record(itemID: id, roomID: "tile-room", correct: true, now: when)
            store.record(itemID: id, roomID: "tile-room", correct: true, now: when)
        }
    }

    /// A former member knew two Mahj+ questions, opened Home on free days,
    /// then rejoined. Nothing was answered since the baseline day, so Home
    /// must not say "2 questions locked in this week".
    func testRejoiningIsNotAWeeklyGain() {
        let t0 = Date().addingTimeInterval(-10 * day)
        let store = PracticeRecordStore(defaults: freshDefaults("MasteryLedgerTests.records"))
        let ledger = MasteryLedger(defaults: freshDefaults("MasteryLedgerTests.rejoin"))
        XCTAssertGreaterThanOrEqual(plusOnlyIDs.count, 2)
        knowTwoPlusQuestions(store, at: t0)
        for offset in 1...3 {
            ledger.record(from: store, now: t0.addingTimeInterval(Double(offset) * day))
        }
        XCTAssertNil(ledger.weeklyGain(now: t0.addingTimeInterval(3 * day)))
    }

    func testRealAnswersStillCount() {
        let t0 = Date().addingTimeInterval(-10 * day)
        let store = PracticeRecordStore(defaults: freshDefaults("MasteryLedgerTests.records"))
        let ledger = MasteryLedger(defaults: freshDefaults("MasteryLedgerTests.answers"))
        ledger.record(from: store, now: t0.addingTimeInterval(day))
        knowTwoPlusQuestions(store, at: t0.addingTimeInterval(2 * day))
        ledger.record(from: store, now: t0.addingTimeInterval(3 * day))
        XCTAssertEqual(ledger.weeklyGain(now: t0.addingTimeInterval(3 * day)), 2)
    }

    /// Upgrade: days an older build wrote for a player who knows no Mahj+
    /// question read the same under the new rule, so they stay the baseline.
    func testOlderDaysStayTheBaselineWhenTheyCountTheSame() {
        let t0 = Date().addingTimeInterval(-10 * day)
        let defaults = freshDefaults("MasteryLedgerTests.upgrade")
        let store = PracticeRecordStore(defaults: freshDefaults("MasteryLedgerTests.records"))
        MasteryLedger(defaults: defaults).record(store.masteryByRoom(isMember: false, now: t0.addingTimeInterval(day)),
                                                 now: t0.addingTimeInterval(day))
        let free = DrillLibrary.rooms.flatMap { PracticeRecordStore.trackableItemIDs(in: $0, isMember: false) }.sorted()
        for id in free.prefix(3) {
            store.record(itemID: id, roomID: "tile-room", correct: true, now: t0.addingTimeInterval(2 * day))
            store.record(itemID: id, roomID: "tile-room", correct: true, now: t0.addingTimeInterval(2 * day))
        }
        let upgraded = MasteryLedger(defaults: defaults)
        upgraded.record(from: store, now: t0.addingTimeInterval(3 * day))
        XCTAssertEqual(upgraded.weeklyGain(now: t0.addingTimeInterval(3 * day)), 3)
        XCTAssertEqual(upgraded.days.count, 2, "nothing an older build wrote is dropped")
    }

    /// Upgrade: a lapsed member's older days counted only the free questions.
    /// Measured against a count that includes their Mahj+ questions they would
    /// fake a gain, so the baseline starts from the upgrade instead.
    func testOlderDaysThatCountedLessAreNotTheBaseline() {
        let t0 = Date().addingTimeInterval(-10 * day)
        let defaults = freshDefaults("MasteryLedgerTests.upgradeLapsed")
        let store = PracticeRecordStore(defaults: freshDefaults("MasteryLedgerTests.records"))
        knowTwoPlusQuestions(store, at: t0)
        MasteryLedger(defaults: defaults).record(store.masteryByRoom(isMember: false, now: t0.addingTimeInterval(day)),
                                                 now: t0.addingTimeInterval(day))
        let upgraded = MasteryLedger(defaults: defaults)
        upgraded.record(from: store, now: t0.addingTimeInterval(3 * day))
        XCTAssertNil(upgraded.weeklyGain(now: t0.addingTimeInterval(3 * day)))
        XCTAssertEqual(upgraded.days.count, 2, "nothing an older build wrote is dropped")
        XCTAssertNil(MasteryLedger(defaults: defaults).weeklyGain(now: t0.addingTimeInterval(3 * day)),
                     "the floor survives a relaunch")
    }
}
