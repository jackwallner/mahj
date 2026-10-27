import XCTest
@testable import MahjTrainer

@MainActor
final class OrdinaryRunStoreTests: XCTestCase {
    func testQuickRunSurvivesRelaunchWithExactOrderAndHeldAnswer() throws {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let items = SessionBuilder.quickSession(seen: [], missed: [], includePro: false)
        let store = OrdinaryRunStore(defaults: defaults)
        store.save(OrdinaryRun(drill: SessionBuilder.sessionDrill, items: items, index: 3,
            score: 2, selection: 1, answers: [true, false, true, false]))
        let resumed = try XCTUnwrap(OrdinaryRunStore(defaults: defaults).inProgress)
        XCTAssertEqual(resumed.items.map(\.id), items.map(\.id))
        XCTAssertEqual(resumed.items.map(\.choices), items.map(\.choices))
        XCTAssertEqual(resumed.index, 3)
        XCTAssertEqual(resumed.selection, 1)
        XCTAssertEqual(resumed.score, 2)
        XCTAssertEqual(resumed.answers, [true, false, true, false])
        store.clear("another-drill")
        XCTAssertNotNil(store.inProgress)
        store.clear(resumed.id)
        XCTAssertNil(OrdinaryRunStore(defaults: defaults).inProgress)
    }

    func testRoomRunPreservesCharlestonSelectionAndDeckQueue() throws {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = OrdinaryRunStore(defaults: defaults)
        for room in DrillLibrary.rooms {
            for drill in room.drills {
                store.save(OrdinaryRun(drill: drill, index: 1, score: 2, answers: [true], selected: [1, 4, 7], submitted: true))
                let restored = try XCTUnwrap(OrdinaryRunStore(defaults: defaults).run(for: drill.id))
                XCTAssertEqual(restored.drill.kind.itemCount, drill.kind.itemCount)
                XCTAssertEqual(restored.selected, [1, 4, 7])
                XCTAssertTrue(restored.submitted)
                if case .flashcards(let cards) = drill.kind {
                    let queue = Array(cards.reversed())
                    store.save(OrdinaryRun(drill: drill, selection: 0, answers: [true], queue: queue, flipped: true))
                    let deck = try XCTUnwrap(OrdinaryRunStore(defaults: defaults).inProgress)
                    XCTAssertEqual(deck.queue.map(\.id), queue.map(\.id))
                    XCTAssertEqual(deck.selection, 0)
                    XCTAssertTrue(deck.flipped)
                }
            }
        }
        store.clear(store.inProgress!.id)
        XCTAssertNil(store.inProgress)
        store.save(OrdinaryRun(drill: SessionBuilder.sessionDrill))
        XCTAssertNil(store.inProgress, "Empty runs cannot be resumed or completed")
    }

    /// Opening a drill and leaving it must not wipe another drill's answers.
    func testAnUnansweredRunNeverReplacesOneWithAnswers() throws {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = OrdinaryRunStore(defaults: defaults)
        let drills = try XCTUnwrap(DrillLibrary.rooms.first?.drills)
        let halfDone = drills[0], peeked = drills[1]
        store.save(OrdinaryRun(drill: halfDone, index: 2, score: 1, answers: [true, false]))
        store.save(OrdinaryRun(drill: peeked))
        store.save(OrdinaryRun(drill: SessionBuilder.sessionDrill,
            items: SessionBuilder.quickSession(seen: [], missed: [], includePro: false)))
        XCTAssertEqual(OrdinaryRunStore(defaults: defaults).inProgress?.id, halfDone.id)
        XCTAssertEqual(store.inProgress?.answers, [true, false])
        // The first answer elsewhere is a new run, and it takes the slot.
        store.save(OrdinaryRun(drill: peeked, answers: [true]))
        XCTAssertEqual(store.inProgress?.id, peeked.id)
        // The same run undone back to nothing leaves nothing to resume.
        store.save(OrdinaryRun(drill: peeked))
        XCTAssertNil(store.inProgress)
        XCTAssertNil(OrdinaryRunStore(defaults: defaults).inProgress)
    }

    /// 1.4.1 saved a run the moment a drill opened. One of those left on
    /// disk is not a run to resume.
    func testAnEmptyRunLeftOnDiskIsDropped() throws {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let drill = try XCTUnwrap(DrillLibrary.rooms.first?.drills.first)
        defaults.set(try JSONEncoder().encode(OrdinaryRun(drill: drill)), forKey: OrdinaryRunStore.key)
        let store = OrdinaryRunStore(defaults: defaults)
        XCTAssertNil(store.inProgress)
        XCTAssertNil(store.resumable(besideOpenPane: false, isMember: true))
    }

    /// A lapsed member keeps the run but is never offered a locked drill.
    func testResumeIsNeverOfferedForALockedDrill() throws {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = OrdinaryRunStore(defaults: defaults)
        let room = try XCTUnwrap(DrillLibrary.rooms.first { $0.drills.contains(where: \.isPlus) })
        let plus = try XCTUnwrap(room.drills.first(where: \.isPlus))
        XCTAssertTrue(room.isLocked(plus, isMember: false))
        store.save(OrdinaryRun(drill: plus, answers: [true]))
        XCTAssertEqual(store.resumable(besideOpenPane: false, isMember: true)?.id, plus.id)
        XCTAssertNil(store.resumable(besideOpenPane: false, isMember: false))
        XCTAssertNotNil(store.inProgress, "Kept for when the membership comes back")

        let free = try XCTUnwrap(room.drills.first { !room.isLocked($0, isMember: false) })
        store.save(OrdinaryRun(drill: free, answers: [false]))
        XCTAssertEqual(store.resumable(besideOpenPane: false, isMember: false)?.id, free.id)

        let memberMix = SessionBuilder.quickSession(seen: [], missed: [], includePro: true)
            .filter { SessionBuilder.isMemberOnly($0.id) }
        if !memberMix.isEmpty {
            store.save(OrdinaryRun(drill: SessionBuilder.sessionDrill, items: memberMix, answers: [true]))
            XCTAssertNil(store.resumable(besideOpenPane: false, isMember: false))
        }
    }

    func testDeckUndoRetainsTheScheduleBeforeTheHeldAnswer() throws {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let records = PracticeRecordStore(defaults: defaults)
        let progress = ProgressStore(defaults: defaults)
        let card = Flashcard(id: "test-card", frontTitle: "Test", backTitle: "Answer", backBody: "Coaching")
        let drill = Drill(id: "test-deck", title: "Deck", subtitle: "", kind: .flashcards([card]))
        let before = OrdinaryRun.AnswerSnapshot(progress: progress.snapshotItem(id: card.id),
            practice: records.snapshotAnswer(itemID: card.id))
        progress.recordItem(id: card.id, correct: false)
        records.record(itemID: card.id, roomID: "tile-room", correct: false)
        let store = OrdinaryRunStore(defaults: defaults)
        store.save(OrdinaryRun(drill: drill, answers: [false], queue: [card], flipped: true,
            pendingAnswer: before, lastSwipe: OrdinaryRun.SwipeRecord(card: card, gotIt: false, answer: before)))
        let saved = try XCTUnwrap(OrdinaryRunStore(defaults: defaults).inProgress)
        let undo = try XCTUnwrap(saved.lastSwipe)
        XCTAssertNil(saved.pendingAnswer?.practice.record)
        XCTAssertEqual(undo.card.id, card.id)
        records.restoreAnswer(undo.answer.practice)
        progress.restoreItem(undo.answer.progress)
        XCTAssertNil(records.records[card.id])
        XCTAssertFalse(progress.missedItems.contains(card.id))
    }

    func testResumeHidesOnlyTheRunOpenBesideHome() throws {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = OrdinaryRunStore(defaults: defaults)
        let drill = try XCTUnwrap(DrillLibrary.rooms.first?.drills.first)
        store.save(OrdinaryRun(drill: drill, answers: [true]))
        store.setOnScreen(drill.id, true)
        XCTAssertNil(store.resumable(besideOpenPane: true, isMember: false))
        // Single column, nothing sits beside Home, so it offers the run.
        XCTAssertEqual(store.resumable(besideOpenPane: false, isMember: false)?.id, drill.id)
        store.setOnScreen("another-drill", false)
        XCTAssertNil(store.resumable(besideOpenPane: true, isMember: false))
        store.setOnScreen(drill.id, false)
        XCTAssertEqual(store.resumable(besideOpenPane: true, isMember: false)?.id, drill.id)
    }
}
