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
                store.save(OrdinaryRun(drill: drill, index: 1, score: 2, selected: [1, 4, 7], submitted: true))
                let restored = try XCTUnwrap(OrdinaryRunStore(defaults: defaults).run(for: drill.id))
                XCTAssertEqual(restored.drill.kind.itemCount, drill.kind.itemCount)
                XCTAssertEqual(restored.selected, [1, 4, 7])
                XCTAssertTrue(restored.submitted)
                if case .flashcards(let cards) = drill.kind {
                    let queue = Array(cards.reversed())
                    store.save(OrdinaryRun(drill: drill, selection: 0, queue: queue, flipped: true))
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

}
