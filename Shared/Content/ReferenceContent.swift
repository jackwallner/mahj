import Foundation

/// One looked-up term. Kept deliberately short: this is read standing at a
/// table with a rack in front of you, not studied.
struct GlossaryTerm: Identifiable, Sendable {
    let id: String
    let term: String
    /// Extra spellings and nicknames a player might search for. Never shown,
    /// only matched, so "soap" finds the White Dragon entry.
    let aliases: [String]
    let definition: String
    let group: GlossaryGroup

    init(id: String, term: String, aliases: [String] = [], group: GlossaryGroup, definition: String) {
        self.id = id
        self.term = term
        self.aliases = aliases
        self.group = group
        self.definition = definition
    }

    func matches(_ query: String) -> Bool {
        let needle = query.lowercased()
        guard !needle.isEmpty else { return true }
        if term.lowercased().contains(needle) { return true }
        if aliases.contains(where: { $0.lowercased().contains(needle) }) { return true }
        return definition.lowercased().contains(needle)
    }
}

enum GlossaryGroup: String, CaseIterable, Identifiable, Sendable {
    case tiles
    case groups
    case charleston
    case play

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tiles: return "Tiles"
        case .groups: return "Groups & Hands"
        case .charleston: return "The Charleston"
        case .play: return "At the Table"
        }
    }

    var icon: String {
        switch self {
        case .tiles: return "square.grid.3x3.fill"
        case .groups: return "rectangle.stack.fill"
        case .charleston: return "arrow.triangle.2.circlepath"
        case .play: return "hand.point.up.left.fill"
        }
    }
}

/// One card section, as a reference entry rather than a drill question.
struct SectionReference: Identifiable, Sendable {
    let category: HandCategory
    /// An ORIGINAL 13-tile teaching rack for the shape. Never a card hand.
    let exampleRack: [Tile]
    let watchOut: String

    var id: String { category.rawValue }
}

/// The at-the-table reference: a searchable glossary and a page per card
/// section. Free for everyone, on purpose. A player who cannot look up "soap"
/// mid-game closes the app and does not come back to it.
///
/// **Legal note:** every example rack here is an ORIGINAL teaching hand built
/// from the stable section structure. Nothing on this screen reproduces a hand
/// from the NMJL card, and the sections themselves are described by shape, not
/// by any year's printed line.
enum ReferenceContent {

    // MARK: - Sections

    static let sections: [SectionReference] = [
        SectionReference(
            category: .year,
            exampleRack: [.d(2), .d(2), .dragon(.soap), .dragon(.soap), .d(2), .d(2),
                          .b(2), .b(2), .b(2), .flower, .flower, .flower, .flower],
            watchOut: "Soaps do double duty as zeros, so they get scarce fast. If two are already showing on other racks, the year hand you are chasing may already be out of reach."
        ),
        SectionReference(
            category: .evens2468,
            exampleRack: [.c(2), .c(2), .c(2), .c(4), .c(4), .c(4), .b(6), .b(6), .b(6),
                          .d(8), .d(8), .d(8), .d(8)],
            watchOut: "Every odd tile you pick up is dead weight. If half your rack is odd after the Charleston, you are in the wrong section."
        ),
        SectionReference(
            category: .likeNumbers,
            exampleRack: [.c(7), .c(7), .c(7), .b(7), .b(7), .b(7), .d(7), .d(7), .d(7),
                          .flower, .flower, .flower, .flower],
            watchOut: "You need the same number in all three suits, and only four of each exist. Losing one suit usually means losing the hand, so count what has been discarded before you commit."
        ),
        SectionReference(
            category: .quints,
            exampleRack: [.b(3), .b(3), .b(3), .b(3), .joker, .c(5), .c(5), .c(5), .c(5),
                          .joker, .joker, .flower, .flower],
            watchOut: "Five of a kind, when only four of any tile exist. A quint hand is really a joker-count question: without jokers in hand it is not a plan, it is a wish."
        ),
        SectionReference(
            category: .consecutiveRun,
            exampleRack: [.b(3), .b(3), .b(3), .b(4), .b(4), .b(4), .b(5), .b(5), .b(5),
                          .b(6), .b(6), .b(6), .b(6)],
            watchOut: "The most forgiving section on the card, because the run can slide up or down a number while you wait. That flexibility is also the trap: keep sliding and you never actually commit."
        ),
        SectionReference(
            category: .odds13579,
            exampleRack: [.d(1), .d(1), .d(1), .d(3), .d(3), .d(3), .d(5), .d(5), .d(5),
                          .d(9), .d(9), .d(9), .d(9)],
            watchOut: "The mirror of the evens family, and usually the better bet early: odd tiles include the 1s and 9s that other players throw away without thinking."
        ),
        SectionReference(
            category: .windsDragons,
            exampleRack: [.wind(.north), .wind(.north), .wind(.north), .wind(.east), .wind(.east),
                          .wind(.east), .wind(.west), .wind(.west), .wind(.west),
                          .wind(.south), .wind(.south), .dragon(.red), .dragon(.red)],
            watchOut: "Only sixteen winds and twelve dragons exist in the whole set, so honors dry up quickly. If nobody is discarding them, somebody else is collecting them too."
        ),
        SectionReference(
            category: .threeSixNine,
            exampleRack: [.c(3), .c(3), .c(3), .c(6), .c(6), .c(6), .b(9), .b(9), .b(9),
                          .d(6), .d(6), .d(9), .d(9)],
            watchOut: "A narrow family: three numbers across three suits. The upside is that it reads clearly, so you know early whether you are in it. The downside is there is nowhere to slide."
        ),
        SectionReference(
            category: .singlesAndPairs,
            exampleRack: [.c(1), .c(2), .b(3), .b(4), .d(5), .d(6), .c(7), .c(8),
                          .b(9), .b(9), .d(1), .d(1), .dragon(.green)],
            watchOut: "NO JOKERS, anywhere, ever. That is exactly why these hands pay the most and why you should not start one unless the tiles are already falling your way."
        ),
    ]

    static func section(for category: HandCategory) -> SectionReference? {
        sections.first { $0.category == category }
    }

    static func sections(matching query: String) -> [SectionReference] {
        let needle = query.lowercased()
        guard !needle.isEmpty else { return sections }
        return sections.filter {
            $0.category.displayName.lowercased().contains(needle)
                || $0.category.shortName.lowercased().contains(needle)
                || $0.category.howToSpot.lowercased().contains(needle)
                || $0.watchOut.lowercased().contains(needle)
        }
    }

    // MARK: - Glossary

    static func terms(matching query: String) -> [GlossaryTerm] {
        glossary.filter { $0.matches(query) }
    }

    static func terms(in group: GlossaryGroup, matching query: String = "") -> [GlossaryTerm] {
        terms(matching: query).filter { $0.group == group }
    }

    static let glossary: [GlossaryTerm] = [

        // MARK: Tiles

        GlossaryTerm(
            id: "g-crak", term: "Crak", aliases: ["character", "wan", "craks"], group: .tiles,
            definition: "One of the three number suits, marked with Chinese characters and usually printed in red. Nine numbers, four of each, and the Red Dragon is the crak family's dragon."
        ),
        GlossaryTerm(
            id: "g-bam", term: "Bam", aliases: ["bamboo", "sticks", "bams"], group: .tiles,
            definition: "The bamboo suit, drawn as sticks. The 1 Bam is usually a bird rather than a single stick, which surprises new players. The Green Dragon is the bam family's dragon."
        ),
        GlossaryTerm(
            id: "g-dot", term: "Dot", aliases: ["circle", "dots", "balls"], group: .tiles,
            definition: "The circle suit, drawn as rings of dots. The White Dragon, called the soap, is the dot family's dragon."
        ),
        GlossaryTerm(
            id: "g-soap", term: "Soap", aliases: ["white dragon", "zero", "blank"], group: .tiles,
            definition: "The White Dragon, so called because the plain-faced version looks like a bar of soap. It is the dot suit's dragon, and it also stands in for a zero in year hands, which makes it one of the most contested tiles on the table."
        ),
        GlossaryTerm(
            id: "g-red-dragon", term: "Red Dragon", aliases: ["chung", "rd"], group: .tiles,
            definition: "The dragon paired with the crak suit. Any hand asking for a suit plus its dragon wants Red with craks."
        ),
        GlossaryTerm(
            id: "g-green-dragon", term: "Green Dragon", aliases: ["fa", "gd"], group: .tiles,
            definition: "The dragon paired with the bam suit. Any hand asking for a suit plus its dragon wants Green with bams."
        ),
        GlossaryTerm(
            id: "g-winds", term: "Winds", aliases: ["north", "east", "west", "south", "news"], group: .tiles,
            definition: "North, East, West and South, four of each. They are honors, not numbers, so they never belong to a suit and never join a numeric run."
        ),
        GlossaryTerm(
            id: "g-flower", term: "Flower", aliases: ["flowers", "season"], group: .tiles,
            definition: "Eight flower tiles come in the set, and for card purposes they are interchangeable: a flower is a flower. They are never part of a numbered run, and many hands ask for two, three or four of them."
        ),
        GlossaryTerm(
            id: "g-joker", term: "Joker", aliases: ["jokers", "wild"], group: .tiles,
            definition: "Eight wild tiles. A joker can stand in for a tile inside a group of three or more (a pung, kong, quint or sextet). It can NEVER be a pair, a single, or part of a Singles and Pairs hand, and it can never be passed in the Charleston."
        ),
        GlossaryTerm(
            id: "g-honors", term: "Honors", aliases: ["honor tiles"], group: .tiles,
            definition: "The winds and dragons together. They carry no number, so a rack full of honors is almost always looking at the Winds and Dragons section."
        ),
        GlossaryTerm(
            id: "g-set-count", term: "The 152 tiles", aliases: ["how many tiles", "tile count"], group: .tiles,
            definition: "An American set is 152 tiles: 108 numbers (three suits, nine numbers, four each), 16 winds, 12 dragons, 8 flowers and 8 jokers. Knowing four of each number exist is the whole basis of counting what is still live."
        ),

        // MARK: Groups

        GlossaryTerm(
            id: "g-pair", term: "Pair", group: .groups,
            definition: "Two identical tiles. A pair can never be completed by calling a discard, except as the winning tile, and it can never contain a joker."
        ),
        GlossaryTerm(
            id: "g-pung", term: "Pung", aliases: ["three of a kind"], group: .groups,
            definition: "Three identical tiles. This is the smallest group you may call a discard for, and calling it means exposing the whole group on your rack."
        ),
        GlossaryTerm(
            id: "g-kong", term: "Kong", aliases: ["four of a kind"], group: .groups,
            definition: "Four identical tiles. Jokers are allowed inside one, so a kong is often two naturals and two jokers."
        ),
        GlossaryTerm(
            id: "g-quint", term: "Quint", aliases: ["five of a kind"], group: .groups,
            definition: "Five identical tiles, which is impossible without jokers because only four of any tile exist. Never plan a quint hand unless you are already holding jokers."
        ),
        GlossaryTerm(
            id: "g-single", term: "Single", group: .groups,
            definition: "One lone tile the hand actually requires. Like a pair, it cannot hold a joker and cannot be called for, except as the tile that finishes your hand."
        ),
        GlossaryTerm(
            id: "g-exposure", term: "Exposure", aliases: ["expose", "exposed"], group: .groups,
            definition: "A called group laid face up on the front of your rack for everyone to see. It is the single biggest piece of information you give away, and the best information you get from other players."
        ),
        GlossaryTerm(
            id: "g-concealed", term: "Concealed hand", aliases: ["closed hand"], group: .groups,
            definition: "A hand the card requires you to complete without exposing anything. You may still pick up the winning tile from a discard, but you may not call to expose a group along the way."
        ),
        GlossaryTerm(
            id: "g-section", term: "Section", aliases: ["category", "family", "line"], group: .groups,
            definition: "One family of hands on the card, such as the evens family or the consecutive runs. Reading which section a rack is chasing is the core skill this app drills."
        ),

        // MARK: Charleston

        GlossaryTerm(
            id: "g-charleston", term: "Charleston", group: .charleston,
            definition: "The tile-passing ritual before play begins. The first Charleston is required and goes right, then across, then left. A second Charleston, left then across then right, happens only if every player agrees to it."
        ),
        GlossaryTerm(
            id: "g-first-right", term: "First right", aliases: ["first pass"], group: .charleston,
            definition: "The opening pass of three tiles to the player on your right. It is the one pass you must make from tiles you have actually looked at, so it is the moment to dump your most isolated junk."
        ),
        GlossaryTerm(
            id: "g-blind-pass", term: "Blind pass", aliases: ["blind"], group: .charleston,
            definition: "Passing along tiles you have not looked at, taken straight from the set you were just handed. It is allowed in the second and third passes of a Charleston, not the first, and it is what you do when you genuinely have nothing to spare."
        ),
        GlossaryTerm(
            id: "g-courtesy", term: "Courtesy pass", aliases: ["optional pass", "across"], group: .charleston,
            definition: "The last exchange, across the table only, of anywhere from zero to three tiles by mutual agreement. Both players have to pass the same number, so ask before you count on it."
        ),
        GlossaryTerm(
            id: "g-steal", term: "Stealing the pass", aliases: ["steal"], group: .charleston,
            definition: "Keeping a tile out of the three you were handed and substituting one of your own before passing them on. Legal only in the passes where a blind pass is legal."
        ),
        GlossaryTerm(
            id: "g-no-jokers-passed", term: "Jokers are never passed", aliases: ["passing jokers"], group: .charleston,
            definition: "A joker may not leave your rack in any Charleston pass, blind or otherwise. If you find one in a blind pass you received, it is yours."
        ),

        // MARK: Play

        GlossaryTerm(
            id: "g-call", term: "Call", aliases: ["calling", "take the discard"], group: .play,
            definition: "Claiming the tile just discarded, before the next player picks, to complete a pung, kong or quint that you then expose. You cannot call a discard for a pair or a single unless it wins the hand for you."
        ),
        GlossaryTerm(
            id: "g-dead-hand", term: "Dead hand", group: .play,
            definition: "A hand that can no longer legally win, usually because of an illegal exposure or an exposure that no card hand can match. A dead hand stays in the game to discard, but cannot win."
        ),
        GlossaryTerm(
            id: "g-wall-game", term: "Wall game", aliases: ["draw", "no winner"], group: .play,
            definition: "Nobody declares mah jongg before the tiles run out. It happens more often than beginners expect, and it is why chasing a hopeless hand to the end costs you nothing but also earns you nothing."
        ),
        GlossaryTerm(
            id: "g-joker-swap", term: "Joker swap", aliases: ["redemption", "redeem"], group: .play,
            definition: "Trading a natural tile from your own rack for a joker sitting in somebody's exposed group. You need the exact matching tile, and the joker becomes yours to use."
        ),
        GlossaryTerm(
            id: "g-hot-tile", term: "Hot tile", aliases: ["dangerous discard"], group: .play,
            definition: "A tile that plainly helps somebody at the table, usually because their exposures point at it. Late in a hand, throwing a hot tile is how a good rack still loses."
        ),
        GlossaryTerm(
            id: "g-safe-tile", term: "Safe tile", aliases: ["safe discard"], group: .play,
            definition: "A tile no live hand seems to want: one already discarded twice with no reaction, or one that clashes with every exposure on the table. Keeping one in reserve for the endgame is a habit worth building."
        ),
        GlossaryTerm(
            id: "g-mahjongg-call", term: "Mah Jongg", aliases: ["declaring", "win"], group: .play,
            definition: "The call you make when your fourteenth tile completes a hand on the card. Say it before you expose your rack, and be sure: an incorrect declaration kills your hand."
        ),
        GlossaryTerm(
            id: "g-rack", term: "Rack", group: .play,
            definition: "The stand holding your thirteen tiles, with the shelf in front where exposures go. Racked means in your hand, exposed means on the shelf where everyone can see it."
        ),
        GlossaryTerm(
            id: "g-wall", term: "Wall", group: .play,
            definition: "The face-down tiles everyone draws from. As it shrinks, the odds of anybody finishing shrink with it, which is when defense starts to matter more than your own hand."
        ),
        GlossaryTerm(
            id: "g-east", term: "East", aliases: ["dealer"], group: .play,
            definition: "The dealer's seat. East deals, starts with an extra tile, and throws the first discard. The seat rotates after each hand."
        ),
    ]
}
