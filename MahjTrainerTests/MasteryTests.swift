import XCTest
@testable import MahjTrainer

/// Mastery drives the ring on every room card, so what counts and what stops
/// counting has to be exact. The two rules worth defending: one lucky answer
/// is not knowledge, and a player who practises weekly must not watch their
/// rooms un-learn themselves between sessions.
@MainActor
final class MasteryTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: PracticeRecordStore!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "MasteryTests")!
        defaults.removePersistentDomain(forName: "MasteryTests")
        store = PracticeRecordStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "MasteryTests")
        super.tearDown()
    }

    private var tileRoom: Room { DrillLibrary.room(id: "tile-room")! }

    // MARK: - What counts as known

    func testOneCorrectAnswerIsNotKnown() {
        var record = PracticeRecord()
        record.streak = 1
        XCTAssertFalse(record.isKnown())
    }

    func testTwoInARowIsKnown() {
        var record = PracticeRecord()
        record.streak = 2
        XCTAssertTrue(record.isKnown())
    }

    /// Being due for review is not the same as being forgotten. An item stays
    /// known until it is a whole interval past due, so a week between sessions
    /// does not wipe a room.
    func testKnownSurvivesGoingJustPastDue() {
        var record = PracticeRecord()
        record.streak = 3
        record.intervalDays = 10
        record.dueDate = Date().addingTimeInterval(-2 * 86_400)
        XCTAssertTrue(record.isKnown())
    }

    func testKnownLapsesAFullIntervalPastDue() {
        var record = PracticeRecord()
        record.streak = 3
        record.intervalDays = 10
        record.dueDate = Date().addingTimeInterval(-11 * 86_400)
        XCTAssertFalse(record.isKnown())
    }

    // MARK: - Levels

    func testLevelThresholds() {
        XCTAssertEqual(MasteryLevel.level(known: 0, total: 10), .untouched)
        XCTAssertEqual(MasteryLevel.level(known: 1, total: 10), .learning)
        XCTAssertEqual(MasteryLevel.level(known: 5, total: 10), .solid)
        XCTAssertEqual(MasteryLevel.level(known: 9, total: 10), .sharp)
        XCTAssertEqual(MasteryLevel.level(known: 0, total: 0), .untouched)
    }

    // MARK: - Rooms

    func testUnpractisedRoomIsUntouched() {
        let mastery = store.mastery(for: tileRoom, isMember: true)
        XCTAssertEqual(mastery.level, .untouched)
        XCTAssertEqual(mastery.known, 0)
        XCTAssertGreaterThan(mastery.total, 0)
    }

    /// The ring has to be closeable by whoever is looking at it, so a free
    /// player's denominator excludes the locked Mahj+ set.
    func testFreePlayerDenominatorExcludesLockedDrills() {
        let free = store.mastery(for: tileRoom, isMember: false).total
        let member = store.mastery(for: tileRoom, isMember: true).total
        XCTAssertLessThan(free, member)
    }

    func testAnsweringRightTwiceMovesTheRing() {
        let ids = PracticeRecordStore.trackableItemIDs(in: tileRoom, isMember: false)
        let target = Array(ids.prefix(3))
        XCTAssertEqual(target.count, 3, "The tile room should have questions to count")

        for id in target {
            store.record(itemID: id, roomID: tileRoom.id, correct: true)
        }
        XCTAssertEqual(store.mastery(for: tileRoom, isMember: false).known, 0, "One right answer is not knowledge")

        for id in target {
            store.record(itemID: id, roomID: tileRoom.id, correct: true)
        }
        XCTAssertEqual(store.mastery(for: tileRoom, isMember: false).known, 3)
    }

    func testAMissDropsAnItemBackOut() {
        let id = PracticeRecordStore.trackableItemIDs(in: tileRoom, isMember: false)[0]
        store.record(itemID: id, roomID: tileRoom.id, correct: true)
        store.record(itemID: id, roomID: tileRoom.id, correct: true)
        XCTAssertEqual(store.mastery(for: tileRoom, isMember: false).known, 1)

        store.record(itemID: id, roomID: tileRoom.id, correct: false)
        XCTAssertEqual(store.mastery(for: tileRoom, isMember: false).known, 0)
    }

    /// Generated practice rolls up into one row per skill, and that row is not
    /// an authored question, so it must never leak into a room's mastery.
    func testGeneratedPracticeDoesNotInflateMastery() {
        for _ in 0..<6 {
            store.record(
                itemID: PracticeSkill.rackReading.itemPrefix + UUID().uuidString,
                roomID: "card-room",
                correct: true
            )
        }
        let cardRoom = DrillLibrary.room(id: "card-room")!
        XCTAssertEqual(store.mastery(for: cardRoom, isMember: true).known, 0)
    }

    // MARK: - Where to go next

    func testRoomToWorkOnIgnoresRoomsNeverOpened() {
        XCTAssertNil(store.roomToWorkOn(isMember: true), "A room nobody has opened is new, not weak")

        let id = PracticeRecordStore.trackableItemIDs(in: tileRoom, isMember: true)[0]
        store.record(itemID: id, roomID: tileRoom.id, correct: true)
        store.record(itemID: id, roomID: tileRoom.id, correct: true)
        XCTAssertEqual(store.roomToWorkOn(isMember: true)?.roomID, tileRoom.id)
    }

    func testEveryRoomReportsMastery() {
        XCTAssertEqual(store.masteryByRoom(isMember: true).count, DrillLibrary.rooms.count)
        for mastery in store.masteryByRoom(isMember: true) {
            XCTAssertGreaterThan(mastery.total, 0, "\(mastery.roomID) has nothing gradeable to master")
        }
    }
}
