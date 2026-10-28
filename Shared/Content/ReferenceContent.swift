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
        self.term = ContentText.localized(term)
        self.aliases = aliases
        self.group = group
        self.definition = ContentText.localized(definition)
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
        case .tiles: return String(localized: "Tiles")
        case .groups: return String(localized: "Groups & Hands")
        case .charleston: return String(localized: "The Charleston")
        case .play: return String(localized: "At the Table")
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

    init(category: HandCategory, exampleRack: [Tile], watchOut: String) {
        self.category = category
        self.exampleRack = exampleRack
        self.watchOut = ContentText.localized(watchOut)
    }

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
                          .d(6), .d(6), .b(2), .b(2), .b(2), .flower, .flower],
            watchOut: "Soaps do double duty as zeros, so they get scarce fast. If two are already showing on other racks, the year hand you are chasing may already be out of reach."
        ),
        SectionReference(
            category: .evens2468,
            exampleRack: [.c(2), .c(2), .c(4), .c(4), .c(4), .b(6), .b(6), .b(6), .b(6),
                          .d(8), .d(8), .flower, .flower],
            watchOut: "Every odd tile you pick up is dead weight. If half your rack is odd after the Charleston, you are in the wrong section."
        ),
        SectionReference(
            category: .likeNumbers,
            exampleRack: [.c(7), .c(7), .c(7), .b(7), .b(7), .b(7), .d(7), .d(7), .d(7),
                          .flower, .flower, .flower, .flower],
            watchOut: "You need the same number across different suits, and only four of each exist. Losing one suit usually means losing the hand, so count what has been discarded before you commit."
        ),
        SectionReference(
            category: .quints,
            exampleRack: [.b(3), .b(3), .b(3), .b(3), .joker, .c(5), .c(5), .c(5), .c(5),
                          .joker, .joker, .flower, .flower],
            watchOut: "Five of a kind, when only four of any tile exist. A quint hand is really a joker-count question. Without jokers in hand it is a hope, not a plan."
        ),
        SectionReference(
            category: .consecutiveRun,
            exampleRack: [.b(3), .b(3), .b(3), .b(4), .b(4), .b(4), .b(5), .b(5), .b(5),
                          .b(6), .b(6), .b(6), .b(6)],
            watchOut: "A flexible section, because the run can slide up or down a number while you wait, unless a line's note names its numbers. That flexibility is also a trap, since if you keep sliding you never commit."
        ),
        SectionReference(
            category: .odds13579,
            exampleRack: [.d(1), .d(1), .d(1), .d(3), .d(3), .d(3), .d(5), .d(5), .d(5),
                          .d(9), .d(9), .d(9), .d(9)],
            watchOut: "The mirror of the evens family, with five numbers to build from instead of four."
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
            watchOut: "A narrow family built on three numbers across three suits. It reads clearly, so you know early whether you are in it. The downside is that there is nowhere to slide."
        ),
        SectionReference(
            category: .singlesAndPairs,
            exampleRack: [.c(1), .c(2), .b(3), .b(4), .d(5), .d(6), .c(7), .c(8),
                          .b(9), .b(9), .d(1), .d(1), .dragon(.green)],
            watchOut: "No jokers, anywhere. Because nothing can be called except the winning tile, you should not start one unless the tiles are already falling your way."
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
            definition: "The bamboo suit, drawn as sticks. The 1 Bam is usually a bird rather than a single stick. The Green Dragon is the bam family's dragon."
        ),
        GlossaryTerm(
            id: "g-dot", term: "Dot", aliases: ["circle", "dots", "balls"], group: .tiles,
            definition: "The circle suit, drawn as rings of dots. The White Dragon, called the soap, is the dot family's dragon."
        ),
        GlossaryTerm(
            id: "g-soap", term: "Soap", aliases: ["white dragon", "zero", "blank"], group: .tiles,
            definition: "The White Dragon, so called because the plain-faced version looks like a bar of soap. It is the dot suit's dragon, and it also stands in for a zero in year hands."
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
            definition: "Eight flower tiles come in the set, and for card purposes any flower can stand in for any other. They are never part of a numbered run. Wherever the card shows an F, any flower works."
        ),
        GlossaryTerm(
            id: "g-joker", term: "Joker", aliases: ["jokers", "wild"], group: .tiles,
            definition: "Eight wild tiles. A joker can stand in for a tile inside a group of three or more (a pung, kong or quint). It can never be a pair, a single, or part of a Singles and Pairs hand, and it can never be passed in the Charleston."
        ),
        GlossaryTerm(
            id: "g-honors", term: "Honors", aliases: ["honor tiles"], group: .tiles,
            definition: "The winds and dragons together. They carry no number, so a rack full of honors points to the Winds and Dragons section."
        ),
        GlossaryTerm(
            id: "g-set-count", term: "The 152 tiles", aliases: ["how many tiles", "tile count"], group: .tiles,
            definition: "An American set has 152 tiles. That is 108 numbers (three suits, nine numbers, four each), 16 winds, 12 dragons, 8 flowers and 8 jokers. Knowing that four of each tile exist is the basis of counting what is still live."
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
            definition: "Four identical tiles. Jokers are allowed inside one, so a kong can be part natural tiles and part jokers."
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
            definition: "A called group laid face up on top of your rack for everyone to see. It tells the table which hands you can still make, and it shows you what other players are building."
        ),
        GlossaryTerm(
            id: "g-concealed", term: "Concealed hand", aliases: ["closed hand"], group: .groups,
            definition: "A hand the card requires you to complete without exposing anything. You may still pick up the winning tile from a discard, but you may not call to expose a group along the way."
        ),
        GlossaryTerm(
            id: "g-section", term: "Section", aliases: ["category", "family"], group: .groups,
            definition: "One family of hands on the card, such as the evens family or the consecutive runs. Reading which section a rack is chasing is the core skill this app drills."
        ),
        GlossaryTerm(
            id: "g-line", term: "Line", aliases: ["hand on the card", "card hand"], group: .groups,
            definition: "One hand printed on the card, read left to right. Each section holds several lines, and the value beside each line says what it pays and whether it is X (exposures allowed) or C (concealed)."
        ),

        // MARK: Charleston

        GlossaryTerm(
            id: "g-charleston", term: "Charleston", group: .charleston,
            definition: "The tile-passing ritual before play begins. The first Charleston is required and goes right, then across, then left. A second Charleston, left then across then right, happens only if every player agrees to it."
        ),
        GlossaryTerm(
            id: "g-first-right", term: "First right", aliases: ["first pass"], group: .charleston,
            definition: "The opening pass of three tiles to the player on your right. Like every pass except the last one of each Charleston, it must come from tiles you have looked at, so it is a good moment to pass your most isolated tiles."
        ),
        GlossaryTerm(
            id: "g-blind-pass", term: "Blind pass", aliases: ["blind"], group: .charleston,
            definition: "Passing along tiles you have not looked at, taken straight from the set you were just handed. It is allowed only on the last pass of each Charleston (the first Left and the second Right), and it is useful when you have nothing to spare."
        ),
        GlossaryTerm(
            id: "g-courtesy", term: "Courtesy pass", aliases: ["optional pass", "across"], group: .charleston,
            definition: "The last exchange, across the table only, of anywhere from zero to three tiles by mutual agreement. Both players have to pass the same number, so ask before you count on it."
        ),
        GlossaryTerm(
            id: "g-steal", term: "Stealing the pass", aliases: ["steal"], group: .charleston,
            definition: "Another name for the blind pass, meaning sending on some or all of the tiles you were just handed without looking at them. Allowed only on the last pass of each Charleston (the first Left and the second Right)."
        ),
        GlossaryTerm(
            id: "g-no-jokers-passed", term: "Jokers are never passed", aliases: ["passing jokers"], group: .charleston,
            definition: "A joker may not leave your rack in any Charleston pass, blind or otherwise, or in the courtesy pass."
        ),

        // MARK: Play

        GlossaryTerm(
            id: "g-call", term: "Call", aliases: ["calling", "take the discard"], group: .play,
            definition: "Claiming the tile just discarded to complete a pung, kong or quint that you then expose, or to win. You can call until the next player racks the tile they drew (or discards, or starts a joker swap). You cannot call a discard for a pair or a single unless it wins the hand for you."
        ),
        GlossaryTerm(
            id: "g-dead-hand", term: "Dead hand", group: .play,
            definition: "A hand that can no longer legally win, usually because of an exposure that no card hand can match or a wrong mah jongg laid down. Once another player calls it dead and the tiles prove it, you stop drawing and discarding for the rest of the hand, but you still pay the winner. Nobody calls their own hand dead, so until someone does, keep playing and discard defensively."
        ),
        GlossaryTerm(
            id: "g-wall-game", term: "Wall game", aliases: ["draw", "no winner"], group: .play,
            definition: "Nobody declares mah jongg before the tiles run out. Until it ends, any opponent can still win and collect from you, so keep discarding carefully."
        ),
        GlossaryTerm(
            id: "g-joker-swap", term: "Joker swap", aliases: ["redemption", "redeem", "joker exchange"], group: .play,
            definition: "On your turn, after you draw or call and before you discard, trade a natural tile from your rack for a joker in any exposed group, your own included. The tile must be exactly the one the joker stands for, and the joker becomes yours to use. You may swap more than one in a turn."
        ),
        GlossaryTerm(
            id: "g-hot-tile", term: "Hot tile", aliases: ["dangerous discard"], group: .play,
            definition: "A tile that plainly helps somebody at the table, usually because their exposures point at it. Late in a hand, throwing a hot tile can hand someone the win."
        ),
        GlossaryTerm(
            id: "g-safe-tile", term: "Safe tile", aliases: ["safe discard"], group: .play,
            definition: "A tile no live hand seems to want, such as one already discarded twice with no reaction or one that clashes with every exposure on the table. Keeping one in reserve for the endgame is a habit worth building."
        ),
        GlossaryTerm(
            id: "g-mahjongg-call", term: "Mah Jongg", aliases: ["mahjong", "mah jong", "mahj", "maj", "declaring", "win"], group: .play,
            definition: "The call you make when your fourteenth tile completes a hand on the card. Say it before you expose your rack, and be sure, because laying down a wrong hand kills it."
        ),
        GlossaryTerm(
            id: "g-rack", term: "Rack", group: .play,
            definition: "The stand holding your tiles. Your concealed tiles rest on the sloped front; exposures sit on top of the rack where everyone can see them. Racked means in your hand, exposed means on top of the rack."
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
