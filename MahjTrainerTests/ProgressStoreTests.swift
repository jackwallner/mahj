import XCTest
@testable import MahjTrainer

@MainActor
final class ProgressStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: ProgressStore!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "ProgressStoreTests")
        defaults.removePersistentDomain(forName: "ProgressStoreTests")
        store = ProgressStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "ProgressStoreTests")
        super.tearDown()
    }

    func testRecordSessionIncrementsCounts() {
        store.recordSession(drillID: "meet-tiles")
        store.recordSession(drillID: "meet-tiles")
        XCTAssertEqual(store.completions(for: "meet-tiles"), 2)
        XCTAssertEqual(store.totalSessions, 2)
    }

    /// The tour's closing practice is recorded before onboarding ends, so
    /// Home's extras wait for a practice the player starts after it.
    func testTourPracticeDoesNotCountTowardHomeExtras() {
        XCTAssertFalse(store.hasPracticedSinceOnboarding)
        store.recordSession(drillID: "quick-session")
        store.sessionsAtOnboarding = store.totalSessions
        XCTAssertFalse(store.hasPracticedSinceOnboarding)
        store.recordSession(drillID: "meet-tiles")
        XCTAssertTrue(store.hasPracticedSinceOnboarding)
    }

    /// Players who onboarded before 1.4.1 have no stored mark, so any
    /// finished practice counts, as before.
    func testUpgradersCountEveryPractice() {
        store.recordSession(drillID: "meet-tiles")
        XCTAssertTrue(store.hasPracticedSinceOnboarding)
    }

    /// A 1.3.2 player who only did the tour: its practice is taken off once,
    /// so the trial sheet's two practices are their own. Never twice.
    func testUpgraderBaselineTakesOffTheTourOnce() {
        defaults.set(true, forKey: "progress.hasOnboarded")
        defaults.set(1, forKey: "progress.totalSessions")
        var upgraded = ProgressStore(defaults: defaults)
        XCTAssertEqual(upgraded.sessionsAtOnboarding, 1)
        XCTAssertFalse(upgraded.hasPracticedSinceOnboarding)
        upgraded.recordSession(drillID: "meet-tiles")
        upgraded = ProgressStore(defaults: defaults)
        XCTAssertEqual(upgraded.sessionsAtOnboarding, 1)
        XCTAssertTrue(upgraded.hasPracticedSinceOnboarding)
    }

    /// A 1.3.2 player who skipped the tour has nothing to take off.
    func testUpgraderWithNoPracticeKeepsZero() {
        defaults.set(true, forKey: "progress.hasOnboarded")
        XCTAssertEqual(ProgressStore(defaults: defaults).sessionsAtOnboarding, 0)
    }

    func testStreakStartsAtOne() {
        store.recordSession(drillID: "a")
        XCTAssertEqual(store.streakCount, 1)
    }

    func testSameDaySessionsKeepStreak() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "b", now: day1.addingTimeInterval(3600))
        XCTAssertEqual(store.streakCount, 1)
    }

    func testConsecutiveDaysGrowStreak() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        XCTAssertEqual(store.streakCount, 2)
    }

    func testGapResetsStreakToOne() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400 * 3))
        XCTAssertEqual(store.streakCount, 1)
    }

    func testCurrentStreakHoldsThroughTheNextDay() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        XCTAssertEqual(store.currentStreak(now: day1.addingTimeInterval(86_400 * 2)), 2)
    }

    func testCurrentStreakDropsToZeroAfterAMissedDay() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        XCTAssertEqual(store.currentStreak(now: day1.addingTimeInterval(86_400 * 5)), 0)
    }

    func testClockGoingBackwardsDoesNotRewindTheLastDay() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        XCTAssertEqual(store.streakCount, 2, "Returning to the real date must not count the same day twice")
    }

    func testRoomProgress() {
        guard let room = DrillLibrary.rooms.first else { return XCTFail("no rooms") }
        XCTAssertEqual(store.roomProgress(room), 0)
        store.recordSession(drillID: room.drills[0].id)
        XCTAssertEqual(store.roomProgress(room), 1 / Double(room.drills.count), accuracy: 0.001)
    }

    func testRecordItemTracksSeenAndMissed() {
        store.recordItem(id: "q1", correct: false)
        XCTAssertTrue(store.seenItems.contains("q1"))
        XCTAssertTrue(store.missedItems.contains("q1"))
        store.recordItem(id: "q1", correct: true)
        XCTAssertTrue(store.seenItems.contains("q1"))
        XCTAssertFalse(store.missedItems.contains("q1"), "A correct answer clears the miss")
    }

    func testItemTrackingPersists() {
        store.recordItem(id: "q1", correct: false)
        let reloaded = ProgressStore(defaults: defaults)
        XCTAssertTrue(reloaded.seenItems.contains("q1"))
        XCTAssertTrue(reloaded.missedItems.contains("q1"))
    }

    func testUndoRestoresSeenAndMissedStateAcrossRelaunch() {
        let unseen = store.snapshotItem(id: "new")
        store.recordItem(id: "new", correct: false)
        store.restoreItem(unseen)
        store.recordItem(id: "missed", correct: false)
        let missed = store.snapshotItem(id: "missed")
        store.recordItem(id: "missed", correct: true)
        store.recordItem(id: "other", correct: true)
        store.restoreItem(missed)
        let reloaded = ProgressStore(defaults: defaults)
        XCTAssertEqual(reloaded.seenItems, ["missed", "other"])
        XCTAssertEqual(reloaded.missedItems, ["missed"])
    }

    func testResetAllClearsEverythingButOnboarding() {
        store.hasOnboarded = true
        store.recordSession(drillID: "a")
        store.recordItem(id: "q1", correct: false)
        store.resetAll()
        XCTAssertEqual(store.streakCount, 0)
        XCTAssertEqual(store.totalSessions, 0)
        XCTAssertEqual(store.completions(for: "a"), 0)
        XCTAssertTrue(store.seenItems.isEmpty)
        XCTAssertTrue(store.missedItems.isEmpty)
        XCTAssertTrue(store.hasOnboarded, "Reset must not re-trigger onboarding")
    }

    // The rating ask lives in ReviewPromptTracker; see ReviewPromptTrackerTests.
}
