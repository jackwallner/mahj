import XCTest
@testable import MahjTrainer

/// The 2026-11-20 low-severity bug catalog. Each test is a customer scenario
/// that failed before its fix. Only APIs that predate the fixes are used, so
/// the files also run against the base commit to show the failure. One file
/// per cause (`LowBug*Tests.swift`) extends this class.
@MainActor
final class LowBugRegressionTests: XCTestCase {
    func freshDefaults(_ name: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }

    func inTimeZone(_ id: String, _ body: (Calendar) -> Void) {
        let saved = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: id)!
        defer { NSTimeZone.default = saved }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: id)!
        body(calendar)
    }

    // MARK: B2 one saved run per drill

    func testAnswerInAnotherDrillDoesNotDropAHalfFinishedQuickSession() throws {
        let defaults = freshDefaults("LowBugRuns")
        let store = OrdinaryRunStore(defaults: defaults)
        let items = SessionBuilder.quickSession(seen: [], missed: [], includePro: false)
        store.save(OrdinaryRun(drill: SessionBuilder.sessionDrill, items: items, index: 3, score: 2,
                               answers: [true, false, true]))
        let tileCheck = try XCTUnwrap(DrillLibrary.rooms.first?.drills.first)
        store.save(OrdinaryRun(drill: tileCheck, index: 1, score: 1, answers: [true]))
        let reopened = OrdinaryRunStore(defaults: defaults)
        XCTAssertEqual(reopened.run(for: SessionBuilder.sessionDrill.id)?.index, 3)
        XCTAssertEqual(reopened.run(for: SessionBuilder.sessionDrill.id)?.items.map(\.id), items.map(\.id))
        XCTAssertEqual(reopened.run(for: tileCheck.id)?.answers, [true])
    }
}
