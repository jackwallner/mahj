import XCTest
@testable import MahjTrainer

final class ContentValidityTests: XCTestCase {

    // MARK: - Hand match

    func testHandMatchQuestionsHaveThirteenTiles() {
        for question in CategoryContent.handMatch {
            XCTAssertEqual(question.tiles.count, 13, "\(question.id) must show a 13-tile rack")
        }
    }

    func testHandMatchAnswerIsAmongChoices() {
        for question in CategoryContent.handMatch {
            XCTAssertTrue(question.choices.contains(question.answer), "\(question.id) answer missing from choices")
            XCTAssertEqual(Set(question.choices).count, question.choices.count, "\(question.id) has duplicate choices")
        }
    }

    // MARK: - Charleston

    func testCharlestonDealsAreThirteenTiles() {
        for scenario in CharlestonContent.scenarios {
            XCTAssertEqual(scenario.deal.count, 13, "\(scenario.id) deal must be 13 tiles")
        }
    }

    func testCharlestonRecommendsExactlyThreePassableTiles() {
        for scenario in CharlestonContent.scenarios {
            XCTAssertEqual(scenario.recommendedPass.count, 3, "\(scenario.id) must recommend exactly 3 tiles")
            XCTAssertFalse(scenario.recommendedPass.contains(.joker), "\(scenario.id) recommends passing a joker (illegal)")
        }
    }

    func testCharlestonRecommendedPassComesFromDeal() {
        for scenario in CharlestonContent.scenarios {
            var pool = scenario.deal
            for tile in scenario.recommendedPass {
                guard let index = pool.firstIndex(of: tile) else {
                    XCTFail("\(scenario.id) recommends passing \(tile.shortLabel), which isn't in the deal")
                    continue
                }
                pool.remove(at: index)
            }
        }
    }

    func testNoDealExceedsFourCopiesOfATile() {
        for scenario in CharlestonContent.scenarios {
            var counts: [Tile: Int] = [:]
            for tile in scenario.deal where tile != .flower && tile != .joker {
                counts[tile, default: 0] += 1
            }
            for (tile, count) in counts {
                XCTAssertLessThanOrEqual(count, 4, "\(scenario.id) has \(count)× \(tile.shortLabel); only 4 exist")
            }
        }
    }

    // MARK: - Quiz

    func testQuizAnswerIndicesAreValid() {
        for question in TileBasicsContent.tileQuiz {
            XCTAssertTrue(question.choices.indices.contains(question.answerIndex), "\(question.id) has out-of-range answer")
            XCTAssertGreaterThanOrEqual(question.choices.count, 2, "\(question.id) needs at least 2 choices")
        }
    }

    // MARK: - Library integrity

    func testAllContentIDsAreUnique() {
        var ids: [String] = []
        for room in DrillLibrary.rooms {
            ids.append(room.id)
            for drill in room.drills {
                ids.append(drill.id)
                switch drill.kind {
                case .flashcards(let cards): ids += cards.map(\.id)
                case .quiz(let questions): ids += questions.map(\.id)
                case .handMatch(let questions): ids += questions.map(\.id)
                case .charleston(let scenarios): ids += scenarios.map(\.id)
                }
            }
        }
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate content IDs found")
    }

    func testEveryRoomHasDrillsAndFirstRoomIsFree() {
        XCTAssertFalse(DrillLibrary.rooms.isEmpty)
        for room in DrillLibrary.rooms {
            XCTAssertFalse(room.drills.isEmpty, "\(room.id) has no drills")
            for drill in room.drills {
                XCTAssertGreaterThan(drill.kind.itemCount, 0, "\(drill.id) is empty")
            }
        }
        XCTAssertTrue(DrillLibrary.rooms.first?.isFree == true, "First room must be free")
    }

    func testNoEmDashesInPlayerFacingCopy() {
        var copy: [String] = []
        for room in DrillLibrary.rooms {
            copy.append(room.name)
            copy.append(room.tagline)
            for drill in room.drills {
                copy.append(drill.title)
                copy.append(drill.subtitle)
                switch drill.kind {
                case .flashcards(let cards):
                    copy += cards.flatMap { [$0.frontTitle, $0.frontSubtitle ?? "", $0.backTitle, $0.backBody] }
                case .quiz(let questions):
                    copy += questions.flatMap { [$0.prompt, $0.explanation] + $0.choices }
                case .handMatch(let questions):
                    copy += questions.map(\.explanation)
                case .charleston(let scenarios):
                    copy += scenarios.flatMap { [$0.situation, $0.reasoning, $0.tip] }
                }
            }
        }
        for text in copy {
            XCTAssertFalse(text.contains("\u{2014}"), "Em dash found in copy: \(text)")
        }
    }
}
