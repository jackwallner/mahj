import XCTest
@testable import MahjTrainer

/// Play a Hand grades a decision rather than a fact, so the grading has to be
/// defensible tile by tile. These tests pin the coach's judgment: an off-family
/// single is always the cheapest throw, a joker is never the throw, and
/// breaking a group always costs more than spending a loose tile.
final class HandPlayEngineTests: XCTestCase {

    // MARK: - The set

    func testFullSetIsOneHundredFiftyTwoTiles() {
        XCTAssertEqual(HandPlayEngine.fullSet.count, 152)
    }

    func testFullSetHasFourOfEveryTileAndEightWilds() {
        var counts: [Tile: Int] = [:]
        for tile in HandPlayEngine.fullSet { counts[tile, default: 0] += 1 }
        XCTAssertEqual(counts[.flower], 8)
        XCTAssertEqual(counts[.joker], 8)
        for rank in 1...9 {
            for suit in Suit.allCases {
                XCTAssertEqual(counts[.suited(rank: rank, suit: suit)], 4, "\(rank)\(suit) should have 4 copies")
            }
        }
        for wind in Wind.allCases { XCTAssertEqual(counts[.wind(wind)], 4) }
        for dragon in Dragon.allCases { XCTAssertEqual(counts[.dragon(dragon)], 4) }
    }

    func testDealTakesThirteenAndLeavesTheRestAsWall() {
        let deal = HandPlayEngine.deal(seed: "test-deal")
        XCTAssertEqual(deal.rack.count, 13)
        XCTAssertEqual(deal.wall.count, 152 - 13)
        XCTAssertEqual(deal.rack.count + deal.wall.count, 152)
    }

    /// The wall must be the rest of the set, not a fresh random draw, or a
    /// player can be dealt a fifth copy of a tile they already hold.
    func testWallNeverYieldsAFifthCopy() {
        for seed in 0..<25 {
            let deal = HandPlayEngine.deal(seed: "wall-\(seed)")
            var counts: [Tile: Int] = [:]
            for tile in deal.rack + deal.wall { counts[tile, default: 0] += 1 }
            for (tile, count) in counts {
                let limit = (tile == .flower || tile == .joker) ? 8 : 4
                XCTAssertLessThanOrEqual(count, limit, "\(tile) appeared \(count) times")
            }
        }
    }

    func testDealIsReproducibleFromASeed() {
        XCTAssertEqual(HandPlayEngine.deal(seed: "same").rack, HandPlayEngine.deal(seed: "same").rack)
    }

    // MARK: - Reading a rack

    func testRunRangeCoversTheMostTiles() {
        let tiles: [Tile] = [.c(4), .c(5), .b(6), .b(7), .d(7), .c(1)]
        XCTAssertEqual(HandPlayEngine.bestRunRange(for: tiles), 4...7)
    }

    func testFlowersCountTowardEverySection() {
        for target in HandPlayEngine.playableTargets {
            XCTAssertTrue(HandPlayEngine.belongs(.flower, to: target), "\(target) should keep flowers")
        }
    }

    func testHonorsOnlyBelongToWindsAndDragons() {
        XCTAssertTrue(HandPlayEngine.belongs(.dragon(.red), to: .windsDragons))
        XCTAssertFalse(HandPlayEngine.belongs(.dragon(.red), to: .evens2468))
        XCTAssertFalse(HandPlayEngine.belongs(.c(4), to: .windsDragons))
    }

    func testRankedTargetsPutsTheObviousReadFirst() {
        let evens: [Tile] = [.c(2), .c(2), .c(2), .b(4), .b(4), .b(4),
                             .d(6), .d(6), .d(6), .d(8), .d(8), .d(8), .flower]
        XCTAssertEqual(HandPlayEngine.rankedTargets(for: evens).first?.target, .evens2468)
    }

    // MARK: - Grading a discard

    /// The whole coaching model rests on this: the tile that serves nothing is
    /// the tile to spend.
    func testCheapestThrowIsTheOffSectionSingle() {
        let rack: [Tile] = [.c(2), .c(2), .c(2), .b(4), .b(4), .b(4),
                            .d(6), .d(6), .d(6), .d(8), .d(8), .d(8), .flower, .b(5)]
        let best = HandPlayEngine.bestDiscards(from: rack, target: .evens2468)
        XCTAssertEqual(best, [.b(5)])
    }

    func testJokerIsNeverTheCheapestThrow() {
        let rack: [Tile] = [.c(2), .c(2), .c(2), .b(4), .b(4), .b(4),
                            .d(6), .d(6), .d(6), .d(8), .d(8), .joker, .flower, .b(5)]
        XCTAssertFalse(HandPlayEngine.bestDiscards(from: rack, target: .evens2468).contains(.joker))
    }

    func testBreakingAPungCostsMoreThanSpendingASingle() {
        let rack: [Tile] = [.c(2), .c(2), .c(2), .b(4), .b(4), .b(4),
                            .d(6), .d(6), .d(6), .d(8), .d(8), .d(8), .c(4), .b(5)]
        let pungCost = HandPlayEngine.cost(of: .c(2), from: rack, target: .evens2468)
        let singleCost = HandPlayEngine.cost(of: .c(4), from: rack, target: .evens2468)
        XCTAssertGreaterThan(pungCost, singleCost)
        XCTAssertEqual(HandPlayEngine.cost(of: .b(5), from: rack, target: .evens2468), 0, accuracy: 0.0001)
    }

    /// Two equally useless tiles are equally right. Picking one of them as the
    /// only answer would be a rule invented so the app has something to mark
    /// wrong.
    func testEquallyUselessTilesAreBothGradedRight() {
        let rack: [Tile] = [.c(2), .c(2), .c(2), .b(4), .b(4), .b(4),
                            .d(6), .d(6), .d(6), .d(8), .d(8), .d(8), .b(5), .c(7)]
        let best = HandPlayEngine.bestDiscards(from: rack, target: .evens2468)
        XCTAssertEqual(best, [.b(5), .c(7)])
    }

    func testEveryDealHasSomeCheapestThrow() {
        for seed in 0..<40 {
            let deal = HandPlayEngine.deal(seed: "grade-\(seed)")
            let rack = deal.rack + [deal.wall[0]]
            for target in HandPlayEngine.playableTargets {
                XCTAssertFalse(
                    HandPlayEngine.bestDiscards(from: rack, target: target).isEmpty,
                    "\(target) left the coach with no answer"
                )
            }
        }
    }

    // MARK: - Verdict

    func testWorkingTilesIgnoresLoneTiles() {
        let rack: [Tile] = [.c(2), .c(2), .c(2), .b(4), .b(5)]
        // The pung counts, the lone 4 does not, and the 5 is not even evens.
        XCTAssertEqual(HandPlayEngine.workingTiles(in: rack, target: .evens2468), 3)
    }

    /// The number shown while a player is choosing a target has to move
    /// between sections. `workingTiles` does not on a fresh deal: a random
    /// thirteen has almost no pairs, so every section reads the same.
    func testFittingTilesSeparatesSectionsOnAFreshDeal() {
        let scattered: [Tile] = [.c(1), .c(4), .b(9), .d(2), .d(3), .d(5), .d(6),
                                 .d(7), .d(9), .dragon(.soap), .wind(.east), .flower, .joker]
        XCTAssertEqual(HandPlayEngine.fittingTiles(in: scattered, target: .evens2468), 5)
        XCTAssertEqual(HandPlayEngine.fittingTiles(in: scattered, target: .odds13579), 8)
        XCTAssertEqual(HandPlayEngine.fittingTiles(in: scattered, target: .windsDragons), 4)
        XCTAssertNotEqual(
            HandPlayEngine.fittingTiles(in: scattered, target: .evens2468),
            HandPlayEngine.fittingTiles(in: scattered, target: .odds13579)
        )
    }

    func testWorkingTilesCountsJokers() {
        XCTAssertEqual(HandPlayEngine.workingTiles(in: [.joker, .joker, .b(5)], target: .evens2468), 2)
    }

    func testVerdictReportsFitAndGroupsSeparately() {
        // Six evens, none of them paired. The headline number must not read
        // zero here: a rack visibly full of the right tiles scoring 0 looks
        // like a scoring bug, which is why `fitting` is what is shown.
        let scattered: [Tile] = [.c(2), .b(4), .d(6), .c(8), .b(2), .d(4), .c(1), .b(3)]
        let verdict = HandPlayEngine.verdict(rack: scattered, target: .evens2468, cleanDiscards: 6, discards: 12)
        XCTAssertEqual(verdict.fitting, 6)
        XCTAssertEqual(verdict.working, 0)
        XCTAssertGreaterThan(verdict.fitting, verdict.working)
        XCTAssertFalse(verdict.body.contains("—"))
    }

    func testPerfectPlayEarnsThreeStarsAndNothingEarnsNone() {
        let strong: [Tile] = [.c(2), .c(2), .c(2), .b(4), .b(4), .b(4),
                              .d(6), .d(6), .d(6), .d(8), .d(8), .d(8), .flower]
        let good = HandPlayEngine.verdict(rack: strong, target: .evens2468, cleanDiscards: 12, discards: 12)
        XCTAssertEqual(good.stars, 3)

        let junk: [Tile] = [.c(1), .b(3), .d(5), .c(7), .b(9), .wind(.east),
                            .dragon(.red), .c(3), .b(1), .d(9), .c(5), .b(7), .d(3)]
        let bad = HandPlayEngine.verdict(rack: junk, target: .evens2468, cleanDiscards: 0, discards: 12)
        XCTAssertEqual(bad.stars, 0)
    }

    func testVerdictReportsTheRealCounts() {
        let rack: [Tile] = [.c(2), .c(2), .c(2), .b(5)]
        let verdict = HandPlayEngine.verdict(rack: rack, target: .evens2468, cleanDiscards: 7, discards: 12)
        XCTAssertEqual(verdict.total, 4)
        XCTAssertEqual(verdict.working, 3)
        XCTAssertEqual(verdict.fitting, 3)
        XCTAssertEqual(verdict.cleanDiscards, 7)
        XCTAssertEqual(verdict.discards, 12)
    }

    // MARK: - Coaching copy

    func testCoachNotesAvoidEmDashes() {
        let rack: [Tile] = [.c(2), .c(2), .c(2), .b(4), .b(4), .b(4),
                            .d(6), .d(6), .d(6), .d(8), .d(8), .d(8), .b(5), .joker]
        for tile in Set(rack) {
            let wasBest = HandPlayEngine.bestDiscards(from: rack, target: .evens2468).contains(tile)
            let note = HandPlayEngine.coachNote(for: tile, rack: rack, target: .evens2468, wasBest: wasBest)
            XCTAssertFalse(note.isEmpty)
            XCTAssertFalse(note.contains("—"), "Coach note for \(tile) has an em dash")
        }
    }

    func testThrowingAJokerIsAlwaysCorrected() {
        let rack: [Tile] = [.c(2), .c(2), .c(2), .b(4), .b(4), .b(4),
                            .d(6), .d(6), .d(6), .d(8), .d(8), .d(8), .b(5), .joker]
        let note = HandPlayEngine.coachNote(for: .joker, rack: rack, target: .evens2468, wasBest: false)
        XCTAssertTrue(note.lowercased().contains("joker"))
    }
}

/// The one free hand a day is the only place in the app where a free player
/// gets a whole Mahj+ mode, so the gate has to open and close exactly on the
/// calendar day and never on the screen simply being opened.
@MainActor
final class HandPlayStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: HandPlayStore!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "HandPlayStoreTests")!
        defaults.removePersistentDomain(forName: "HandPlayStoreTests")
        store = HandPlayStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "HandPlayStoreTests")
        super.tearDown()
    }

    func testFirstHandOfTheDayIsFree() {
        XCTAssertTrue(store.canPlay(isMember: false))
    }

    func testSecondHandTheSameDayNeedsMembership() {
        let now = Date()
        store.recordStart(isMember: false, now: now)
        XCTAssertFalse(store.canPlay(isMember: false, now: now))
        XCTAssertTrue(store.canPlay(isMember: true, now: now))
    }

    func testTheFreeHandComesBackTomorrow() {
        let today = Date()
        store.recordStart(isMember: false, now: today)
        let tomorrow = today.addingTimeInterval(26 * 3600)
        XCTAssertTrue(store.canPlay(isMember: false, now: tomorrow))
    }

    /// A member's hands must never stamp the free-hand marker, or cancelling a
    /// membership would silently cost them that day's free hand.
    func testMemberHandsDoNotSpendTheFreeHand() {
        store.recordStart(isMember: true)
        XCTAssertTrue(store.canPlay(isMember: false))
        XCTAssertEqual(store.handsPlayed, 1)
    }

    func testBestVerdictOnlyClimbs() {
        store.recordVerdict(stars: 2)
        store.recordVerdict(stars: 1)
        XCTAssertEqual(store.bestStars, 2)
        store.recordVerdict(stars: 3)
        XCTAssertEqual(store.bestStars, 3)
    }

    func testResetClearsEverything() {
        store.recordStart(isMember: false)
        store.recordVerdict(stars: 3)
        store.resetAll()
        XCTAssertEqual(store.handsPlayed, 0)
        XCTAssertEqual(store.bestStars, 0)
        XCTAssertTrue(store.canPlay(isMember: false))
    }
}
