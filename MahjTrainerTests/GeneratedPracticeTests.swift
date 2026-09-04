import XCTest
@testable import MahjTrainer

/// The generated Charleston and defense questions nobody proofreads, same as
/// the rack generator. What has to hold: exactly one defensible answer, no
/// illegal tile in a pass, and every wrong choice genuinely wrong.
final class GeneratedPracticeTests: XCTestCase {

    // MARK: - Charleston passes

    private var passes: [CharlestonGenerator.GeneratedPass] {
        CharlestonGenerator.batch(count: 60, seed: "charleston-tests")
    }

    func testGeneratorProducesPasses() {
        XCTAssertGreaterThan(passes.count, 40, "Rejection sampling should still fill a batch")
    }

    func testPassRacksAreLegalThirteenTileDeals() {
        for pass in passes {
            XCTAssertEqual(pass.tiles.count, 13, "A deal is thirteen tiles")
            var counts: [Tile: Int] = [:]
            for tile in pass.tiles { counts[tile, default: 0] += 1 }
            for (tile, count) in counts {
                let limit = (tile == .flower || tile == .joker) ? 8 : 4
                XCTAssertLessThanOrEqual(count, limit, "\(tile) appears \(count) times")
            }
        }
    }

    /// Jokers can never be passed in a Charleston, so one must never be
    /// offered as an answer or sit in a generated pre-Charleston rack that the
    /// question then asks a player to pass from.
    func testNoJokerIsEverOfferedAsAPass() {
        for pass in passes {
            XCTAssertFalse(pass.choices.contains(.joker), "A joker was offered as a pass")
            XCTAssertNotEqual(pass.answer, .joker)
        }
    }

    func testTheAnswerIsTheOnlyTileOutsideTheSection() {
        for pass in passes {
            let range = pass.section == .consecutiveRun
                ? HandPlayEngine.bestRunRange(for: pass.tiles)
                : nil
            XCTAssertFalse(
                HandPlayEngine.belongs(pass.answer, to: pass.section, runRange: range),
                "The answer \(pass.answer) fits \(pass.section)"
            )
            for choice in pass.choices where choice != pass.answer {
                XCTAssertTrue(
                    HandPlayEngine.belongs(choice, to: pass.section, runRange: range),
                    "Distractor \(choice) is outside \(pass.section), so it is also a fair pass"
                )
            }
        }
    }

    /// Every wrong choice has to cost something real, or the question has more
    /// than one right answer.
    func testEveryDistractorIsPartOfAMadeGroup() {
        for pass in passes {
            for choice in pass.choices where choice != pass.answer {
                let copies = pass.tiles.filter { $0 == choice }.count
                XCTAssertGreaterThanOrEqual(copies, 3, "\(choice) is not part of a group worth keeping")
            }
        }
    }

    /// The explanation ends by telling the player that every other tile in the
    /// rack is already part of a group they have built. That sentence used to
    /// be false: the generator dealt two strays and offered only the first, so
    /// a second ungrouped tile sat in plain sight, and some core shapes carried
    /// a singleton on top of that. The whole rack has to back the claim, not
    /// just the four choices.
    func testTheAnswerIsTheOnlyUngroupedTileInTheWholeRack() {
        for pass in passes {
            var counts: [Tile: Int] = [:]
            for tile in pass.tiles { counts[tile, default: 0] += 1 }
            let ungrouped = counts.filter { $0.value < 2 }.map(\.key)
            XCTAssertEqual(
                ungrouped, [pass.answer],
                "Rack \(pass.tiles) has ungrouped tiles \(ungrouped) but offers only \(pass.answer)"
            )
        }
    }

    func testPassChoicesAreDistinctAndFour() {
        for pass in passes {
            XCTAssertEqual(pass.choices.count, 4)
            XCTAssertEqual(Set(pass.choices).count, 4, "Duplicate choices give a question two identical answers")
            XCTAssertTrue(pass.choices.contains(pass.answer))
        }
    }

    func testPassCoachingIsWrittenForEveryWrongChoice() {
        for pass in passes {
            XCTAssertEqual(pass.choiceNotes.count, pass.choices.count)
            for (index, choice) in pass.choices.enumerated() {
                if choice == pass.answer {
                    XCTAssertNil(pass.choiceNotes[index], "The right answer needs no correction")
                } else {
                    XCTAssertNotNil(pass.choiceNotes[index], "\(choice) has no coaching")
                }
            }
            XCTAssertFalse(pass.explanation.contains("—"), "Em dash in a generated explanation")
        }
    }

    // MARK: - Defense

    private var defenses: [DefenseGenerator.GeneratedDefense] {
        DefenseGenerator.batch(count: 60, seed: "defense-tests")
    }

    func testGeneratorProducesDefenseQuestions() {
        XCTAssertGreaterThan(defenses.count, 40)
    }

    func testExposuresAreTwoPungsOfDifferentTiles() {
        for question in defenses {
            XCTAssertEqual(question.exposures.count, 2)
            for exposure in question.exposures {
                XCTAssertEqual(exposure.count, 3, "An exposed pung is three tiles")
                XCTAssertEqual(Set(exposure).count, 1, "A pung is three of the SAME tile")
            }
            XCTAssertNotEqual(question.exposures[0].first, question.exposures[1].first)
        }
    }

    /// Two pungs of the same number in different suits reads as Like Numbers,
    /// not as evens or odds, and the safe discard would then be a different
    /// tile. Those deals must be rejected rather than shown.
    func testExposedPungsNeverShareANumber() {
        for question in defenses {
            let ranks = question.exposures.compactMap { exposure -> Int? in
                if case .suited(let rank, _) = exposure[0] { return rank }
                return nil
            }
            if ranks.count == 2 {
                XCTAssertNotEqual(ranks[0], ranks[1], "Same number in two suits is a Like Numbers read")
            }
        }
    }

    func testTheSafeDiscardIsTheOnlyOneOutsideTheSection() {
        for question in defenses {
            XCTAssertFalse(
                HandPlayEngine.belongs(question.answer, to: question.impliedSection),
                "The safe tile \(question.answer) belongs to \(question.impliedSection)"
            )
            for choice in question.choices where choice != question.answer {
                XCTAssertTrue(
                    HandPlayEngine.belongs(choice, to: question.impliedSection),
                    "\(choice) is also safe against \(question.impliedSection)"
                )
            }
        }
    }

    func testDefenseChoicesAreDistinctAndFour() {
        for question in defenses {
            XCTAssertEqual(question.choices.count, 4)
            XCTAssertEqual(Set(question.choices).count, 4)
            XCTAssertTrue(question.choices.contains(question.answer))
        }
    }

    /// A choice must never be a tile the opponent already has three of, or the
    /// question is asking about a tile with only one copy left in the game.
    func testChoicesAreNotTheExposedTiles() {
        for question in defenses {
            let exposed = Set(question.exposures.compactMap(\.first))
            for choice in question.choices {
                XCTAssertFalse(exposed.contains(choice), "\(choice) is already exposed three times")
            }
        }
    }

    func testDefenseCoachingIsWrittenForEveryWrongChoice() {
        for question in defenses {
            XCTAssertEqual(question.choiceNotes.count, question.choices.count)
            for (index, choice) in question.choices.enumerated() {
                if choice == question.answer {
                    XCTAssertNil(question.choiceNotes[index])
                } else {
                    XCTAssertNotNil(question.choiceNotes[index])
                }
            }
            XCTAssertFalse(question.explanation.contains("—"))
        }
    }

    // MARK: - The QuickItem wrapping

    func testEveryEndlessSkillProducesUsableItems() {
        for skill in PracticeSkill.endlessCases {
            let items = EndlessPractice.items(for: skill, count: 6)
            XCTAssertFalse(items.isEmpty, "\(skill.rawValue) produced nothing")
            for item in items {
                XCTAssertTrue(item.id.hasPrefix(skill.itemPrefix), "\(item.id) will not roll up into one stats row")
                XCTAssertEqual(PracticeSkill.skill(forItemID: item.id), skill)
                XCTAssertGreaterThanOrEqual(item.choices.count, 3)
                XCTAssertTrue(item.choices.indices.contains(item.answerIndex))
                XCTAssertFalse(item.explanation.isEmpty)
                XCTAssertFalse(item.prompt.contains("—"))
                XCTAssertFalse(DrillLibrary.rooms.filter { $0.id == item.roomID }.isEmpty, "Unknown room \(item.roomID)")
            }
        }
    }

    /// Play a Hand is in the skill enum only so its throws roll up into one
    /// stats row. It must never show up as a question stream.
    func testHandPlayIsNotAnEndlessMode() {
        XCTAssertFalse(PracticeSkill.endlessCases.contains(.handPlay))
        XCTAssertTrue(EndlessPractice.items(for: .handPlay, count: 5).isEmpty)
    }

    func testTimedChallengeMixesEverySkill() {
        // Deliberately large: `mixedItems` trims the tail to hit the count, and
        // a small draw could drop one skill entirely and fail at random.
        let items = EndlessPractice.mixedItems(count: 200)
        let skills = Set(items.compactMap { PracticeSkill.skill(forItemID: $0.id) })
        XCTAssertEqual(skills, Set(PracticeSkill.endlessCases))
    }

    // MARK: - Per-choice coaching survives the shuffle

    /// `SessionBuilder.prepared` reorders the choices. If the notes do not ride
    /// the same permutation they start explaining somebody else's wrong answer.
    func testCoachingFollowsTheChoiceShuffle() {
        let item = QuickItem(
            id: "shuffle-test",
            prompt: "Which one?",
            tiles: [],
            choices: ["A", "B", "C", "D"],
            answerIndex: 0,
            explanation: "Because A.",
            sourceLabel: "Test",
            roomID: "tile-room",
            choiceNotes: [nil, "note B", "note C", "note D"]
        )
        let prepared = SessionBuilder.prepared(item)
        XCTAssertEqual(prepared.choices[prepared.answerIndex], "A")
        for (index, label) in prepared.choices.enumerated() {
            if label == "A" {
                XCTAssertNil(prepared.choiceNotes[index])
            } else {
                XCTAssertEqual(prepared.note(forPick: index), "note \(label)")
            }
        }
    }

    func testMissNotesCoverEveryWrongSection() {
        let choices: [HandCategory] = [.evens2468, .odds13579, .threeSixNine]
        let notes = HandCategory.missNotes(for: choices, answer: .odds13579)
        XCTAssertNil(notes[1])
        XCTAssertNotNil(notes[0])
        XCTAssertNotNil(notes[2])
        XCTAssertTrue(notes[0]?.contains("2468") ?? false)
    }
}
