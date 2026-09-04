import XCTest
@testable import MahjTrainer

/// The reference is the one screen a player reads while a real game is
/// waiting on them, so a wrong entry there is worse than a wrong drill
/// question: they will act on it at the table.
final class ReferenceContentTests: XCTestCase {

    // MARK: - Sections

    func testEverySectionHasAReferenceEntry() {
        for category in HandCategory.allCases {
            XCTAssertNotNil(ReferenceContent.section(for: category), "\(category) has no reference entry")
        }
        XCTAssertEqual(ReferenceContent.sections.count, HandCategory.allCases.count)
    }

    func testExampleRacksAreThirteenTiles() {
        for reference in ReferenceContent.sections {
            XCTAssertEqual(reference.exampleRack.count, 13, "\(reference.id) example is not a rack")
        }
    }

    func testExampleRacksNeverUseAFifthCopy() {
        for reference in ReferenceContent.sections {
            var counts: [Tile: Int] = [:]
            for tile in reference.exampleRack { counts[tile, default: 0] += 1 }
            for (tile, count) in counts {
                let limit = (tile == .flower || tile == .joker) ? 8 : 4
                XCTAssertLessThanOrEqual(count, limit, "\(reference.id) uses \(count) of \(tile)")
            }
        }
    }

    /// Singles and Pairs is the one section that forbids jokers outright, and
    /// an example rack that broke that rule would teach the opposite of the
    /// entry sitting next to it.
    func testSinglesAndPairsExampleHasNoJokers() {
        let reference = ReferenceContent.section(for: .singlesAndPairs)
        XCTAssertNotNil(reference)
        XCTAssertFalse(reference?.exampleRack.contains(.joker) ?? true)
    }

    /// Quints cannot exist without jokers, so the example has to show them.
    func testQuintsExampleShowsJokers() {
        let reference = ReferenceContent.section(for: .quints)
        XCTAssertTrue(reference?.exampleRack.contains(.joker) ?? false)
    }

    // MARK: - Glossary

    func testGlossaryIDsAreUnique() {
        let ids = ReferenceContent.glossary.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate glossary id")
    }

    func testEveryGroupHasEntries() {
        for group in GlossaryGroup.allCases {
            XCTAssertFalse(ReferenceContent.terms(in: group).isEmpty, "\(group.title) is empty")
        }
    }

    func testNoEmDashesAnywhereInTheReference() {
        for term in ReferenceContent.glossary {
            XCTAssertFalse(term.definition.contains("—"), "Em dash in \(term.id)")
            XCTAssertFalse(term.term.contains("—"), "Em dash in \(term.id)")
        }
        for reference in ReferenceContent.sections {
            XCTAssertFalse(reference.watchOut.contains("—"), "Em dash in \(reference.id)")
        }
    }

    // MARK: - Search

    func testSearchIsEmptyQueryFriendly() {
        XCTAssertEqual(ReferenceContent.terms(matching: "").count, ReferenceContent.glossary.count)
        XCTAssertEqual(ReferenceContent.sections(matching: "").count, ReferenceContent.sections.count)
    }

    /// Nicknames are what a beginner actually types. "Soap" has to find the
    /// White Dragon even though the word "soap" is the entry's own title, and
    /// "news" has to find the winds.
    func testNicknamesFindTheirTerms() {
        XCTAssertTrue(ReferenceContent.terms(matching: "soap").contains { $0.id == "g-soap" })
        XCTAssertTrue(ReferenceContent.terms(matching: "white dragon").contains { $0.id == "g-soap" })
        XCTAssertTrue(ReferenceContent.terms(matching: "news").contains { $0.id == "g-winds" })
        XCTAssertTrue(ReferenceContent.terms(matching: "wild").contains { $0.id == "g-joker" })
        XCTAssertTrue(ReferenceContent.terms(matching: "blind").contains { $0.id == "g-blind-pass" })
    }

    func testSearchIsCaseInsensitive() {
        XCTAssertEqual(
            ReferenceContent.terms(matching: "KONG").map(\.id),
            ReferenceContent.terms(matching: "kong").map(\.id)
        )
    }

    func testSectionSearchFindsAShortName() {
        XCTAssertTrue(ReferenceContent.sections(matching: "369").contains { $0.category == .threeSixNine })
    }

    func testUnmatchedSearchReturnsNothingRatherThanEverything() {
        XCTAssertTrue(ReferenceContent.terms(matching: "zzzznotaterm").isEmpty)
        XCTAssertTrue(ReferenceContent.sections(matching: "zzzznotasection").isEmpty)
    }

    // MARK: - The section coaching used across the app

    func testEverySectionExplainsWhatItRequires() {
        for category in HandCategory.allCases {
            XCTAssertFalse(category.requires.isEmpty, "\(category) has no requirement line")
            XCTAssertFalse(category.requires.contains("—"), "Em dash in \(category) requirement")
        }
    }
}
