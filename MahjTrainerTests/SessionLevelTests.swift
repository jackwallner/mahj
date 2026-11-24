import XCTest
@testable import MahjTrainer

/// Sessions fit the player: the onboarding answer sets where they start,
/// accuracy opens the next tier, and nothing ever takes a tier away.
@MainActor
final class SessionLevelTests: XCTestCase {
    private let suite = "SessionLevelTests"
    private var defaults: UserDefaults!
    private var store: ProgressStore!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
        store = ProgressStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    // MARK: - The tags

    private var libraryIDs: [String] {
        DrillLibrary.rooms.flatMap(\.drills).flatMap { drill -> [String] in
            switch drill.kind {
            case .flashcards(let cards): return cards.map(\.id)
            case .quiz(let questions): return questions.map(\.id)
            case .handMatch(let questions): return questions.map(\.id)
            case .charleston(let scenarios): return scenarios.map(\.id)
            }
        }
    }

    func testEveryLibraryItemHasExactlyOneTier() {
        let tagged = ItemDifficulty.table.flatMap(\.1)
        XCTAssertEqual(tagged.count, Set(tagged).count, "An id is listed in more than one tier")
        let missing = Set(libraryIDs).subtracting(tagged)
        XCTAssertTrue(missing.isEmpty, "Untagged items: \(missing.sorted())")
        let stray = Set(tagged).subtracting(libraryIDs)
        XCTAssertTrue(stray.isEmpty, "Tagged ids not in the library: \(stray.sorted())")
    }

    /// A first-lesson player meets pung, kong and quint only in the questions
    /// that teach those words.
    func testBasicQuestionsDoNotAssumeGroupWords() {
        let teaching: Set<String> = ["quiz-pung", "plus-tq-kong"]
        let words = ["pung", "kong", "quint", "sextet"]
        let basic = SessionBuilder.quickSession(count: 1000, seen: [], missed: [], includePro: true, ceiling: .basic)
            .filter { ItemDifficulty.of($0.id) == .basic }
        XCTAssertGreaterThanOrEqual(basic.count, 20)
        for item in basic where !teaching.contains(item.id) {
            let text = ([item.prompt] + item.choices).joined(separator: " ").lowercased()
            for word in words {
                XCTAssertFalse(text.contains(word), "\(item.id) is basic but asks about a \(word)")
            }
        }
    }

    func testFreeBasicPoolFillsMoreThanOneSession() {
        let basic = SessionBuilder.poolIDs(includePro: false).filter { ItemDifficulty.of($0) == .basic }
        XCTAssertGreaterThanOrEqual(basic.count, 15, "A new free player needs more than one session of basics")
    }

    // MARK: - The seed

    func testSeedFollowsOnboarding() {
        XCTAssertEqual(SessionLevel.seed(forSkillLevel: "new"), .basic)
        XCTAssertEqual(SessionLevel.seed(forSkillLevel: "basics"), .intermediate)
        XCTAssertEqual(SessionLevel.seed(forSkillLevel: "played"), .challenging)
        XCTAssertEqual(SessionLevel.seed(forSkillLevel: ""), .challenging, "A player from before the question keeps the full mix")
    }

    // MARK: - Sessions

    /// Plays sessions the way Home builds them, answering every question
    /// right, and returns the items each session showed.
    private func playSessions(_ number: Int, skillLevel: String, includePro: Bool) -> [[QuickItem]] {
        defaults.set(skillLevel, forKey: "mahj.skillLevel")
        return (0..<number).map { _ in
            let items = SessionBuilder.quickSession(
                seen: store.seenItems, missed: store.missedItems, includePro: includePro,
                ceiling: store.sessionCeiling(includePro: includePro))
            for item in items { store.recordItem(id: item.id, correct: true) }
            return items
        }
    }

    func testNewPlayerFirstSessionsAreBasicThenNeverChallenging() {
        for includePro in [false, true] {
            defaults.removePersistentDomain(forName: suite)
            store = ProgressStore(defaults: defaults)
            let sessions = playSessions(3, skillLevel: "new", includePro: includePro)
            for item in sessions[0] + sessions[1] {
                XCTAssertEqual(ItemDifficulty.of(item.id), .basic, "\(item.id) reached a new player's first two sessions")
            }
            for item in sessions.joined() {
                XCTAssertNotEqual(ItemDifficulty.of(item.id), .challenging, "\(item.id) reached a new player in the first sessions")
            }
            XCTAssertEqual(sessions.joined().count, 30)
        }
    }

    func testPlayedPlayerGetsTheFullMix() {
        defaults.set("played", forKey: "mahj.skillLevel")
        let ceiling = store.sessionCeiling(includePro: true)
        XCTAssertEqual(ceiling, .challenging)
        let mix = SessionBuilder.quickSession(count: 500, seen: [], missed: [], includePro: true, ceiling: ceiling)
        XCTAssertEqual(Set(mix.map { ItemDifficulty.of($0.id) }), Set(Difficulty.allCases))
        XCTAssertEqual(mix.count, SessionBuilder.poolIDs(includePro: true).count)
    }

    func testBasicsPlayerStartsWithIntermediateButNoChallenging() {
        defaults.set("basics", forKey: "mahj.skillLevel")
        let ceiling = store.sessionCeiling(includePro: false)
        XCTAssertEqual(ceiling, .intermediate)
        let eligible = SessionBuilder.poolIDs(includePro: false).filter { ItemDifficulty.of($0) <= .intermediate }
        let mix = SessionBuilder.quickSession(count: eligible.count, seen: [], missed: [], includePro: false, ceiling: ceiling)
        XCTAssertEqual(Set(mix.map { ItemDifficulty.of($0.id) }), [.basic, .intermediate])
        XCTAssertEqual(Set(mix.map(\.id)), Set(eligible))
    }

    /// Answers `fraction` of the tier's pool, getting `accuracy` of them right.
    private func answer(_ tier: Difficulty, fraction: Double, accuracy: Double, includePro: Bool) {
        let ids = SessionBuilder.poolIDs(includePro: includePro).filter { ItemDifficulty.of($0) == tier }
        let answered = ids.prefix(Int((Double(ids.count) * fraction).rounded(.up)))
        let right = Int((Double(answered.count) * accuracy).rounded(.up))
        for (index, id) in answered.enumerated() {
            store.recordItem(id: id, correct: index < right)
        }
    }

    func testEightyPercentOnBasicOpensIntermediate() {
        defaults.set("new", forKey: "mahj.skillLevel")
        answer(.basic, fraction: 0.6, accuracy: 0.8, includePro: false)
        let ceiling = store.sessionCeiling(includePro: false)
        XCTAssertEqual(ceiling, .intermediate)
        let next = SessionBuilder.quickSession(
            seen: store.seenItems, missed: store.missedItems, includePro: false, ceiling: ceiling)
        XCTAssertTrue(next.contains { ItemDifficulty.of($0.id) == .intermediate }, "Intermediate should start showing up")
        XCTAssertFalse(next.contains { ItemDifficulty.of($0.id) == .challenging })
    }

    func testWeakAccuracyOrThinCoverageStaysBasic() {
        defaults.set("new", forKey: "mahj.skillLevel")
        answer(.basic, fraction: 1, accuracy: 0.6, includePro: false)
        XCTAssertEqual(store.sessionCeiling(includePro: false), .basic, "60% right is not most of the tier")

        store.resetAll()
        answer(.basic, fraction: 0.3, accuracy: 1, includePro: false)
        XCTAssertEqual(store.sessionCeiling(includePro: false), .basic, "Three perfect answers are not a tier")
    }

    func testMissesComeBackFirstInsideTheCeiling() throws {
        defaults.set("new", forKey: "mahj.skillLevel")
        let missedID = try XCTUnwrap(SessionBuilder.poolIDs(includePro: false).first { ItemDifficulty.of($0) == .basic })
        store.recordItem(id: missedID, correct: false)
        let next = SessionBuilder.quickSession(
            seen: store.seenItems, missed: store.missedItems, includePro: false,
            ceiling: store.sessionCeiling(includePro: false))
        XCTAssertEqual(next.first?.id, missedID)
    }

    func testCeilingNeverDrops() {
        defaults.set("new", forKey: "mahj.skillLevel")
        answer(.basic, fraction: 1, accuracy: 1, includePro: false)
        XCTAssertEqual(store.sessionCeiling(includePro: false), .intermediate)
        answer(.basic, fraction: 1, accuracy: 0, includePro: false)
        XCTAssertEqual(store.sessionCeiling(includePro: false), .intermediate, "A bad day keeps the tier already earned")

        store.resetAll()
        XCTAssertEqual(store.sessionCeiling(includePro: false), .basic, "Resetting progress goes back to the onboarding seed")
    }

    func testCeilingNeverFallsBelowTheSeed() {
        defaults.set("basics", forKey: "mahj.skillLevel")
        answer(.basic, fraction: 1, accuracy: 0, includePro: false)
        XCTAssertEqual(store.sessionCeiling(includePro: false), .intermediate)
    }

    func testIntermediateMasteryOpensChallenging() {
        defaults.set("new", forKey: "mahj.skillLevel")
        answer(.basic, fraction: 1, accuracy: 1, includePro: true)
        answer(.intermediate, fraction: 0.7, accuracy: 0.9, includePro: true)
        XCTAssertEqual(store.sessionCeiling(includePro: true), .challenging)
    }

    func testSmallPoolPadsWithTheEasiestTierAbove() {
        let basicCount = SessionBuilder.poolIDs(includePro: false).filter { ItemDifficulty.of($0) == .basic }.count
        let session = SessionBuilder.quickSession(count: basicCount + 5, seen: [], missed: [], includePro: false, ceiling: .basic)
        XCTAssertEqual(session.count, basicCount + 5)
        XCTAssertEqual(session.prefix(basicCount).filter { ItemDifficulty.of($0.id) == .basic }.count, basicCount)
        for item in session.suffix(5) {
            XCTAssertEqual(ItemDifficulty.of(item.id), .intermediate, "Padding takes the next tier up first")
        }
    }

    func testGameNightPrepKeepsFreshMaterialUnderTheCeiling() throws {
        let challenging = try XCTUnwrap(SessionBuilder.poolIDs(includePro: true).first { ItemDifficulty.of($0) == .challenging })
        let session = SessionBuilder.gameNightPrep(
            count: 10, seen: [], missed: [challenging], dueIDs: [],
            weakestRoomID: "table-room", ceiling: .basic)
        XCTAssertEqual(session.first?.id, challenging, "A player's own miss still comes back")
        for item in session.dropFirst() {
            XCTAssertEqual(ItemDifficulty.of(item.id), .basic, "\(item.id) is above a basic player's ceiling")
        }
    }
}
