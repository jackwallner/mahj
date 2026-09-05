import XCTest
@testable import MahjTrainer

@MainActor
final class PracticeRecordStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: PracticeRecordStore!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "PracticeRecordStoreTests")!
        defaults.removePersistentDomain(forName: "PracticeRecordStoreTests")
        store = PracticeRecordStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "PracticeRecordStoreTests")
        super.tearDown()
    }

    private let room = "tile-room"

    func testUndoThenReanswerDoesNotCreateMastery() {
        let snapshot = store.snapshotAnswer(itemID: "q1")
        store.record(itemID: "q1", roomID: room, correct: true)
        store.restoreAnswer(snapshot)
        XCTAssertNil(PracticeRecordStore(defaults: defaults).records["q1"])
        store.record(itemID: "q1", roomID: room, correct: true)
        XCTAssertEqual(store.records["q1"]?.attempts, 1)
        XCTAssertEqual(store.records["q1"]?.streak, 1)
        XCTAssertFalse(store.records["q1"]!.isKnown())
    }

    func testUndoRestoresMissAndFullScheduleWithoutChangingOtherAnswers() throws {
        store.record(itemID: "q1", roomID: room, correct: false)
        let snapshot = store.snapshotAnswer(itemID: "q1")
        let original = try XCTUnwrap(snapshot.record)
        store.record(itemID: "q1", roomID: room, correct: true)
        store.record(itemID: "q2", roomID: room, correct: true)
        store.restoreAnswer(snapshot)
        let reloaded = PracticeRecordStore(defaults: defaults)
        let restored = try XCTUnwrap(reloaded.records["q1"])
        XCTAssertEqual(restored.attempts, original.attempts)
        XCTAssertEqual(restored.correct, original.correct)
        XCTAssertEqual(restored.streak, original.streak)
        XCTAssertEqual(restored.dueDate, original.dueDate)
        XCTAssertEqual(restored.ease, original.ease)
        XCTAssertEqual(restored.intervalDays, original.intervalDays)
        XCTAssertEqual(reloaded.reviewQueue(), ["q1"])
        XCTAssertEqual(reloaded.records["q2"]?.attempts, 1)
    }

    func testRecordsAccuracy() {
        store.record(itemID: "q1", roomID: room, correct: true)
        store.record(itemID: "q1", roomID: room, correct: false)
        let record = store.records["q1"]
        XCTAssertEqual(record?.attempts, 2)
        XCTAssertEqual(record?.correct, 1)
        XCTAssertEqual(record?.accuracy, 0.5)
    }

    /// A missed item goes into the queue; two clean answers retire it. Without
    /// the second condition an item would either nag forever or vanish on the
    /// first lucky guess.
    func testMissedItemEntersAndLeavesTheQueue() {
        store.record(itemID: "q1", roomID: room, correct: false)
        XCTAssertEqual(store.reviewQueue(), ["q1"])

        store.record(itemID: "q1", roomID: room, correct: true)
        XCTAssertEqual(store.reviewQueue(), [], "One correct answer schedules it a day out")

        store.record(itemID: "q1", roomID: room, correct: true)
        XCTAssertFalse(store.records["q1"]!.needsReview, "Two in a row retires it")
    }

    func testQueueRanksWorstFirst() {
        // q1: 1 of 3. q2: 2 of 3. Both due, q1 should lead.
        for correct in [false, false, false] {
            store.record(itemID: "q1", roomID: room, correct: correct)
        }
        store.record(itemID: "q2", roomID: room, correct: true)
        store.record(itemID: "q2", roomID: room, correct: false)
        XCTAssertEqual(store.reviewQueue().first, "q1")
    }

    /// Generated items mint a new id per question. They must roll up onto one
    /// per-skill row and must never enter the review queue, or the queue would
    /// fill with questions that can never be shown again.
    func testGeneratedItemsCollapseAndStayOutOfTheQueue() {
        let prefix = PracticeSkill.rackReading.itemPrefix
        store.record(itemID: prefix + "a", roomID: room, correct: false)
        store.record(itemID: prefix + "b", roomID: room, correct: true)

        XCTAssertEqual(store.records.count, 1)
        XCTAssertEqual(store.records[PracticeSkill.rackReading.rawValue]?.attempts, 2)
        XCTAssertTrue(store.reviewQueue().isEmpty)
        XCTAssertEqual(store.dueCount(), 0)
    }

    func testOneOffDailyItemContributesToStatsWithoutEnteringReview() {
        store.record(itemID: "mahj-minute-charleston", roomID: "charleston-room", correct: false, isReviewable: false)

        XCTAssertEqual(store.records["mahj-minute-charleston"]?.attempts, 1)
        XCTAssertTrue(store.reviewQueue().isEmpty)
        XCTAssertEqual(store.dueCount(), 0)
    }

    /// Every drill records its misses, but Fix My Mistakes only speaks
    /// single-select. A miss on a plain flip card or a Charleston pass must
    /// not be counted as due, or the Home badge offers a session that opens
    /// with no questions in it.
    func testQueueOnlyCountsItemsTheRunnerCanPresent() {
        store.record(itemID: "q1", roomID: room, correct: false)
        store.record(itemID: "charleston-scenario", roomID: "charleston-room", correct: false)

        XCTAssertEqual(store.dueCount(), 2, "Both misses are still remembered")
        let presentable: Set<String> = ["q1"]
        XCTAssertEqual(store.dueCount(among: presentable), 1)
        XCTAssertEqual(store.reviewQueue(among: presentable), ["q1"])
    }

    /// Real ids from the real library, so the filter cannot silently pass
    /// everything (or nothing) when content changes shape.
    func testReviewableIDsExcludeContentTheRunnerCannotAsk() {
        let free = SessionBuilder.reviewableIDs(includePro: false)
        let member = SessionBuilder.reviewableIDs(includePro: true)

        XCTAssertFalse(free.isEmpty)
        XCTAssertTrue(free.isSubset(of: member))
        XCTAssertGreaterThan(member.count, free.count, "Mahj+ adds askable items")

        for room in DrillLibrary.rooms {
            for drill in room.drills {
                switch drill.kind {
                case .charleston(let scenarios):
                    for scenario in scenarios {
                        XCTAssertFalse(member.contains(scenario.id), "A three-tile pass is not single-select")
                    }
                case .flashcards(let cards):
                    for card in cards where card.choice == nil {
                        XCTAssertFalse(member.contains(card.id), "A plain flip card has no gradeable question")
                    }
                default:
                    break
                }
            }
        }
    }

    func testRoomStatsAggregate() {
        store.record(itemID: "q1", roomID: "tile-room", correct: true)
        store.record(itemID: "q2", roomID: "tile-room", correct: false)
        store.record(itemID: "q3", roomID: "card-room", correct: true)

        let stats = store.roomStats()
        XCTAssertEqual(stats.count, 2)
        let cardRoom = stats.first { $0.id == "tile-room" }
        XCTAssertEqual(cardRoom?.attempts, 2)
        XCTAssertEqual(cardRoom?.accuracy, 0.5)
        XCTAssertEqual(store.overallAccuracy, 2.0 / 3.0, accuracy: 0.0001)
    }

    func testChallengeScoreKeepsTheBest() {
        store.recordChallengeScore(12)
        store.recordChallengeScore(7)
        XCTAssertEqual(store.bestChallengeScore, 12)
    }

    func testPersistsAcrossInstances() {
        store.record(itemID: "q1", roomID: room, correct: true)
        let reloaded = PracticeRecordStore(defaults: defaults)
        XCTAssertEqual(reloaded.records["q1"]?.attempts, 1)
    }

    func testResetClearsEverything() {
        store.record(itemID: "q1", roomID: room, correct: true)
        store.recordChallengeScore(9)
        store.resetAll()
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertEqual(store.bestChallengeScore, 0)
        XCTAssertTrue(PracticeRecordStore(defaults: defaults).records.isEmpty)
    }
}

final class WhatsNewTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "WhatsNewTests")!
        defaults.removePersistentDomain(forName: "WhatsNewTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "WhatsNewTests")
        super.tearDown()
    }

    func testNeverShownBeforeOnboarding() {
        XCTAssertFalse(WhatsNew.shouldPresent(hasOnboarded: false, defaults: defaults))
    }

    /// A player updating from a build that predates the feature has no stored
    /// marker at all. That is exactly who the sheet is for, but only when the
    /// running version actually has notes: a patch release with nothing
    /// player-visible ships no entry, and must show no sheet.
    func testShownToAnUpgraderWithNoMarker() {
        XCTAssertEqual(
            WhatsNew.shouldPresent(hasOnboarded: true, defaults: defaults),
            WhatsNew.currentRelease != nil
        )
    }

    func testShownOnlyOnce() {
        WhatsNew.markSeen(defaults: defaults)
        XCTAssertFalse(WhatsNew.shouldPresent(hasOnboarded: true, defaults: defaults))
    }

    func testFreshInstallBaselineSuppressesIt() {
        WhatsNew.markCurrentAsBaseline(defaults: defaults)
        XCTAssertFalse(WhatsNew.shouldPresent(hasOnboarded: true, defaults: defaults))
    }

    /// Checks every entry, not just the running version's. A patch release with
    /// no notes is legitimate, and `try!` on a nil unwrap used to trap and take
    /// the rest of the test process down with it.
    func testReleaseNotesAreWellFormed() {
        XCTAssertFalse(WhatsNew.releases.isEmpty)
        XCTAssertEqual(
            Set(WhatsNew.releases.map(\.version)).count,
            WhatsNew.releases.count,
            "One entry per version"
        )
        for release in WhatsNew.releases {
            XCTAssertFalse(release.items.isEmpty, release.version)
            XCTAssertEqual(
                Set(release.items.map(\.id)).count,
                release.items.count,
                "Duplicate item id in \(release.version)"
            )
            for item in release.items {
                XCTAssertFalse(item.title.isEmpty, release.version)
                XCTAssertFalse(item.body.isEmpty, release.version)
                XCTAssertFalse(item.body.contains("—"), "No em dashes in copy")
                XCTAssertFalse(item.title.contains("—"), "No em dashes in copy")
            }
        }
    }

    /// The sheet reads `currentRelease`, so an entry whose version string does
    /// not match the bundle's would be authored but never shown.
    func testCurrentReleaseMatchesTheRunningVersion() {
        guard let release = WhatsNew.currentRelease else { return }
        XCTAssertEqual(release.version, WhatsNew.currentVersion)
    }
}
