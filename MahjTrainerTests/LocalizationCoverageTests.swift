import XCTest
@testable import MahjTrainer

/// Every piece of authored teaching content has a translation in every
/// shipped language. The models look their English up in the Content table
/// at init, so a sentence edited in Swift without its catalog entry would
/// silently show English to a German player; this catches it.
final class LocalizationCoverageTests: XCTestCase {
    static let languages = ["de", "es", "fr", "id", "vi"]

    func testEveryContentStringIsTranslated() throws {
        let strings = Set(Self.contentStrings.filter { $0.rangeOfCharacter(from: .letters) != nil })
        XCTAssertGreaterThan(strings.count, 1000)
        for language in Self.languages {
            let bundle = try Self.bundle(language)
            let missing = strings.filter { !Self.isTranslated($0, in: bundle) }.sorted()
            XCTAssertTrue(missing.isEmpty, "\(language) is missing \(missing.count): \(missing.prefix(5))")
        }
    }

    func testPaywallCopyIsTranslated() throws {
        for language in Self.languages {
            let bundle = try Self.bundle(language)
            for key in ["Restore", "Terms of Use", "Privacy Policy", "7 days free, then %@. Auto-renews until canceled."] {
                let value = bundle.localizedString(forKey: key, value: Self.missing, table: nil)
                XCTAssertNotEqual(value, Self.missing, "\(language): \(key)")
            }
        }
    }

    private static let missing = "\u{0}missing"

    private static func bundle(_ language: String) throws -> Bundle {
        let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"), "no \(language).lproj")
        return try XCTUnwrap(Bundle(path: path))
    }

    private static func isTranslated(_ english: String, in bundle: Bundle) -> Bool {
        bundle.localizedString(forKey: english, value: missing, table: "Content") != missing
            || bundle.localizedString(forKey: english, value: missing, table: nil) != missing
    }

    /// The English the tests see is the source text: the test host runs in
    /// English, so `ContentText` hands every string back unchanged.
    private static var contentStrings: [String] {
        var out: [String] = []
        for room in DrillLibrary.rooms {
            out += [room.name, room.tagline]
            for drill in room.drills {
                out += [drill.title, drill.subtitle]
                switch drill.kind {
                case .flashcards(let cards):
                    for card in cards {
                        out += [card.frontTitle, card.backTitle] + [card.frontSubtitle].compactMap { $0 }
                        out += card.choice?.options ?? []
                        // Section cards append a sentence to `howToSpot`; each
                        // piece is translated, the joined text is not a key.
                        if let category = HandCategory.allCases.first(where: { card.backBody.hasPrefix($0.howToSpot) }) {
                            out.append(String(card.backBody.dropFirst(category.howToSpot.count + 1)))
                        } else {
                            out.append(card.backBody)
                        }
                    }
                case .quiz(let questions):
                    for question in questions { out += [question.prompt, question.explanation] + question.choices }
                case .handMatch(let questions):
                    out += questions.map(\.explanation)
                case .charleston(let scenarios):
                    out += scenarios.flatMap(scenarioStrings)
                }
            }
        }
        out += ReferenceContent.glossary.flatMap { [$0.term, $0.definition] }
        out += ReferenceContent.sections.map(\.watchOut)
        out += HowToPlayContent.pages.flatMap { [$0.title, $0.body] + [$0.tip].compactMap { $0 } }
        out += MonthlyChallengeContent.extraRacks.map(\.explanation)
        out += MonthlyChallengeContent.extraPasses.flatMap(scenarioStrings)
        for item in MonthlyChallengeContent.extraDefense + MonthlyChallengeContent.defenseQuestions {
            out += [item.prompt, item.explanation, item.sourceLabel] + item.choices + item.choiceNotes.compactMap { $0 }
        }
        return out
    }

    private static func scenarioStrings(_ scenario: CharlestonScenario) -> [String] {
        [scenario.situation, scenario.situationStem, scenario.reasoning, scenario.tip]
    }
}
