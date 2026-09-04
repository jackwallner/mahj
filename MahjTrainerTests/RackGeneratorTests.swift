import XCTest
@testable import MahjTrainer

/// The generator is the only content in the app nobody proofreads, so it has
/// to be provable rather than spot-checked. The ambiguity tests matter most:
/// a rack that reads as two sections at once is a question with two right
/// answers, and grading one of them wrong teaches a player to distrust the app.
final class RackGeneratorTests: XCTestCase {

    // MARK: - Reading

    func testReadsPureEvens() {
        let tiles: [Tile] = [.c(2), .c(2), .c(2), .b(4), .b(4), .b(4),
                             .d(6), .d(6), .d(6), .b(8), .b(8), .flower, .flower]
        XCTAssertEqual(RackGenerator.category(for: tiles), .evens2468)
    }

    func testReadsPureOdds() {
        let tiles: [Tile] = [.c(1), .c(1), .c(1), .b(3), .b(3), .b(3),
                             .d(5), .d(5), .d(5), .b(9), .b(9), .flower, .flower]
        XCTAssertEqual(RackGenerator.category(for: tiles), .odds13579)
    }

    /// 369 has to carry a 6 plus a 3 or a 9, which is what keeps it from also
    /// reading as pure evens or pure odds.
    func testReadsThreeSixNine() {
        let tiles: [Tile] = [.c(3), .c(3), .c(3), .b(6), .b(6), .b(6),
                             .d(9), .d(9), .d(9), .d(6), .d(6), .flower, .flower]
        XCTAssertEqual(RackGenerator.category(for: tiles), .threeSixNine)
        XCTAssertFalse(RackGenerator.fits(tiles, .evens2468))
        XCTAssertFalse(RackGenerator.fits(tiles, .odds13579))
    }

    func testReadsConsecutiveRun() {
        let tiles: [Tile] = [.c(3), .c(3), .c(3), .c(4), .c(4), .c(4),
                             .c(5), .c(5), .c(5), .b(6), .b(6), .flower, .flower]
        XCTAssertEqual(RackGenerator.category(for: tiles), .consecutiveRun)
    }

    func testReadsWindsAndDragons() {
        let tiles: [Tile] = [.wind(.north), .wind(.north), .wind(.north),
                             .wind(.east), .wind(.east), .wind(.east),
                             .dragon(.red), .dragon(.red), .dragon(.red),
                             .dragon(.green), .dragon(.green), .flower, .flower]
        XCTAssertEqual(RackGenerator.category(for: tiles), .windsDragons)
    }

    /// A rack of one repeated number is evens (or odds) AND like numbers at
    /// once. It must read as nothing rather than be graded.
    func testSingleNumberRackIsAmbiguous() {
        let tiles: [Tile] = [.c(6), .c(6), .c(6), .b(6), .b(6), .b(6),
                             .d(6), .d(6), .d(6), .d(6), .flower, .flower, .flower]
        XCTAssertNil(RackGenerator.category(for: tiles))
    }

    func testHonorsAndNumbersTogetherReadAsNothing() {
        let tiles: [Tile] = [.c(2), .c(2), .c(2), .b(4), .b(4), .b(4),
                             .wind(.east), .wind(.east), .wind(.east),
                             .dragon(.red), .dragon(.red), .flower, .flower]
        XCTAssertNil(RackGenerator.category(for: tiles))
    }

    /// The whole distractor scheme rests on these five never overlapping.
    func testGeneratableCategoriesAreMutuallyExclusive() {
        for target in RackGenerator.generatableCategories {
            guard let rack = RackGenerator.rack(for: target) else {
                XCTFail("Could not deal a rack for \(target.displayName)")
                continue
            }
            let matches = RackGenerator.generatableCategories.filter { RackGenerator.fits(rack.tiles, $0) }
            XCTAssertEqual(matches, [target], "\(target.displayName) rack also reads as \(matches)")
        }
    }

    // MARK: - Dealing

    func testGeneratedRacksAreLegal() {
        for target in RackGenerator.generatableCategories {
            for _ in 0..<20 {
                guard let rack = RackGenerator.rack(for: target) else {
                    XCTFail("Could not deal a rack for \(target.displayName)")
                    break
                }
                XCTAssertEqual(rack.tiles.count, 13, "\(target.displayName) rack is not 13 tiles")

                var counts: [Tile: Int] = [:]
                for tile in rack.tiles where tile != .flower && tile != .joker {
                    counts[tile, default: 0] += 1
                }
                for (tile, count) in counts {
                    XCTAssertLessThanOrEqual(count, 4, "\(count)x \(tile.shortLabel); only 4 exist")
                }

                XCTAssertTrue(rack.choices.contains(rack.answer))
                XCTAssertGreaterThanOrEqual(rack.choices.count, 3)
                XCTAssertEqual(Set(rack.choices).count, rack.choices.count, "Duplicate choices")
                // Every distractor must be a section this rack does NOT read as.
                for choice in rack.choices where choice != rack.answer {
                    XCTAssertFalse(RackGenerator.fits(rack.tiles, choice), "\(choice.displayName) is also a correct answer")
                }
                XCTAssertFalse(rack.explanation.isEmpty)
                XCTAssertFalse(rack.explanation.contains("—"), "No em dashes in copy")
            }
        }
    }

    func testBatchCoversEverySection() {
        let racks = RackGenerator.batch(count: 60)
        XCTAssertGreaterThan(racks.count, 40, "Rejection sampling should still fill most of a batch")
        XCTAssertEqual(Set(racks.map(\.answer)).count, RackGenerator.generatableCategories.count)
    }

    // MARK: - Generated practice items

    func testEndlessItemsAreWellFormed() {
        for skill in PracticeSkill.endlessCases {
            let items = EndlessPractice.items(for: skill, count: 12)
            XCTAssertEqual(items.count, 12, "\(skill.rawValue) came up short")
            for item in items {
                XCTAssertTrue(item.id.hasPrefix(skill.itemPrefix))
                XCTAssertEqual(PracticeSkill.skill(forItemID: item.id), skill)
                XCTAssertGreaterThanOrEqual(item.choices.count, 3)
                XCTAssertTrue(item.choices.indices.contains(item.answerIndex))
                XCTAssertEqual(Set(item.choices).count, item.choices.count, "Duplicate answer labels")
                XCTAssertFalse(item.explanation.isEmpty)
                XCTAssertNotNil(DrillLibrary.room(id: item.roomID))
            }
        }
    }

    /// Four of every countable tile exist, so held + exposed + remaining must
    /// always come to four. An off-by-one here would teach players to wait on
    /// tiles that are already gone.
    func testTileCountingArithmeticAlwaysSumsToFour() {
        let items = EndlessPractice.items(for: .tileCounting, count: 40)
        for item in items {
            let answer = Int(item.choices[item.answerIndex])
            XCTAssertNotNil(answer)
            XCTAssertTrue((1...4).contains(answer!), "Remaining count out of range: \(answer!)")
        }
    }

    /// Drawn large on purpose: `mixedItems` trims the tail to hit the count,
    /// and a batch barely bigger than the skill count could drop one skill
    /// entirely and fail at random.
    func testMixedItemsDrawFromEverySkill() {
        let items = EndlessPractice.mixedItems(count: 200)
        XCTAssertEqual(items.count, 200)
        XCTAssertEqual(Set(items.compactMap { PracticeSkill.skill(forItemID: $0.id) }).count,
                       PracticeSkill.endlessCases.count)
    }
}
