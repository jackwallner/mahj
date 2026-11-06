import XCTest
@testable import MahjTrainer

/// State machine audit repro suite (2026-11-06). Failing tests are expected:
/// each `testBug...` asserts the promised behaviour and fails on HEAD, each
/// `testControl...` passes in the same suite to show the harness is sound.
@MainActor
final class StateMachineAuditRepro: XCTestCase {
    private var suites: [String] = []

    override func tearDown() {
        suites.forEach { UserDefaults(suiteName: $0)?.removePersistentDomain(forName: $0) }
        suites = []
        super.tearDown()
    }

    private func freshDefaults() -> UserDefaults {
        let name = "StateMachineAuditRepro-\(UUID().uuidString)"
        suites.append(name)
        return UserDefaults(suiteName: name)!
    }

    // Fixed instant, mid-June: no DST edge inside the test's week.
    private let t0 = Date(timeIntervalSince1970: 1_781_000_000)
    private let day: TimeInterval = 86_400

    // MARK: - SM-03 weekly gain counts regained access as learning

    private func trackable(isMember: Bool) -> Set<String> {
        Set(DrillLibrary.rooms.flatMap { PracticeRecordStore.trackableItemIDs(in: $0, isMember: isMember) })
    }

    private func answerTwiceRight(_ store: PracticeRecordStore, ids: [String], at when: Date) {
        for id in ids {
            store.record(itemID: id, roomID: "tile-room", correct: true, now: when)
            store.record(itemID: id, roomID: "tile-room", correct: true, now: when)
        }
    }

    /// A former member knew two Mahj+ questions. They lapsed (a week of free
    /// ledger days), then rejoin. They answered nothing since the baseline
    /// day, yet Home would say "Up 2 this week".
    func testBugWeeklyGainCountsRegainedAccess() {
        let plusOnly = trackable(isMember: true).subtracting(trackable(isMember: false)).sorted()
        XCTAssertGreaterThanOrEqual(plusOnly.count, 2)
        let store = PracticeRecordStore(defaults: freshDefaults())
        let ledger = MasteryLedger(defaults: freshDefaults())
        answerTwiceRight(store, ids: Array(plusOnly.prefix(2)), at: t0)

        let lapsed1 = t0.addingTimeInterval(1 * day)
        let lapsed2 = t0.addingTimeInterval(2 * day)
        let rejoined = t0.addingTimeInterval(3 * day)
        ledger.record(store.masteryByRoom(isMember: false, now: lapsed1), now: lapsed1)
        ledger.record(store.masteryByRoom(isMember: false, now: lapsed2), now: lapsed2)
        ledger.record(store.masteryByRoom(isMember: true, now: rejoined), now: rejoined)

        XCTAssertNil(ledger.weeklyGain(now: rejoined),
                     "No question was answered after the baseline day, so there is no weekly gain to report")
    }

    /// Control: the same ledger and store, membership unchanged, nothing answered.
    func testControlWeeklyGainIsNilWhenNothingChanges() {
        let plusOnly = trackable(isMember: true).subtracting(trackable(isMember: false)).sorted()
        let store = PracticeRecordStore(defaults: freshDefaults())
        let ledger = MasteryLedger(defaults: freshDefaults())
        answerTwiceRight(store, ids: Array(plusOnly.prefix(2)), at: t0)
        for offset in 1...3 {
            let when = t0.addingTimeInterval(Double(offset) * day)
            ledger.record(store.masteryByRoom(isMember: true, now: when), now: when)
        }
        XCTAssertNil(ledger.weeklyGain(now: t0.addingTimeInterval(3 * day)))
    }

    /// Control: a real answer between baseline and today is reported.
    func testControlWeeklyGainCountsRealAnswers() {
        let free = trackable(isMember: false).sorted()
        let store = PracticeRecordStore(defaults: freshDefaults())
        let ledger = MasteryLedger(defaults: freshDefaults())
        let baseline = t0.addingTimeInterval(1 * day)
        ledger.record(store.masteryByRoom(isMember: false, now: baseline), now: baseline)
        answerTwiceRight(store, ids: Array(free.prefix(2)), at: t0.addingTimeInterval(2 * day))
        let today = t0.addingTimeInterval(3 * day)
        ledger.record(store.masteryByRoom(isMember: false, now: today), now: today)
        XCTAssertEqual(ledger.weeklyGain(now: today), 2)
    }

    // MARK: - SM-05 (product call) one saved-run slot

    private func twoDrills() throws -> (Drill, Drill) {
        let drills = DrillLibrary.rooms.flatMap(\.drills).filter { $0.kind.itemCount > 0 }
        XCTAssertGreaterThanOrEqual(drills.count, 2)
        return (try XCTUnwrap(drills.first), try XCTUnwrap(drills.dropFirst().first))
    }

    /// Answering one question in drill B replaces the half-done run of drill A.
    func testBugAnsweringAnotherDrillDiscardsTheHalfDoneRun() throws {
        let (a, b) = try twoDrills()
        let store = OrdinaryRunStore(defaults: freshDefaults())
        store.save(OrdinaryRun(drill: a, index: 3, score: 3, answers: [true, true, true]))
        store.save(OrdinaryRun(drill: b, index: 1, score: 1, answers: [true]))
        XCTAssertNotNil(store.run(for: a.id), "Drill A had three answers saved and was never finished")
    }

    /// Control: merely opening B (no answers) does not replace A.
    func testControlOpeningAnotherDrillKeepsTheHalfDoneRun() throws {
        let (a, b) = try twoDrills()
        let store = OrdinaryRunStore(defaults: freshDefaults())
        store.save(OrdinaryRun(drill: a, index: 3, score: 3, answers: [true, true, true]))
        store.save(OrdinaryRun(drill: b))
        XCTAssertNotNil(store.run(for: a.id))
    }

    // MARK: - SM-04 (product call) Reset Progress mints a second challenge player

    /// The score token is the server's player identity for the month. Reset
    /// Progress deletes it, so the same person replays the month under a new
    /// identity and the old row stays on the server.
    func testBugResetProgressChangesTheChallengePlayerIdentity() {
        let store = MonthlyChallengeStore(defaults: freshDefaults())
        let before = store.scoreToken(for: "2026-11")
        store.resetAll()
        XCTAssertEqual(store.scoreToken(for: "2026-11"), before,
                       "One person, one month, one server row")
    }

    /// Control: without a reset the token is stable across launches.
    func testControlTokenIsStableWithoutReset() {
        let defaults = freshDefaults()
        let before = MonthlyChallengeStore(defaults: defaults).scoreToken(for: "2026-11")
        XCTAssertEqual(MonthlyChallengeStore(defaults: defaults).scoreToken(for: "2026-11"), before)
    }
}
