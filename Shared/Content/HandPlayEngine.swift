import Foundation

/// A single-player hand: commit to a section, then draw and discard your way
/// toward it while a coach grades every throw.
///
/// This is the one skill the rest of the app never tests. Reading a finished
/// rack is recognition; deciding what to let go of, turn after turn, with the
/// shape only half built, is the actual game. There are no opponents, no bots
/// and no simulated table talk, on purpose: a bot that plays badly teaches a
/// wrong model of the game, and "the AI feels rigged" is the single most
/// common complaint about every play-based app in this category. What is
/// modelled here is only what can be modelled honestly, which is the wall and
/// your own rack.
///
/// **Legal note:** the target sections are the stable card families, and the
/// engine scores a rack against the SHAPE of a family (all evens, all odds,
/// 3-6-9, a run of four adjacent numbers, honors only). It never encodes,
/// reproduces or checks against a hand from the NMJL card, and it never claims
/// a rack is a winning hand. The verdict it gives is "how much of your rack is
/// working toward this family", which is a structural fact.
enum HandPlayEngine {

    /// How many draw-and-discard turns a hand runs for. Long enough that early
    /// throws are visibly paid for later, short enough to finish on a phone in
    /// one sitting.
    static let turnCount = 12

    /// The sections a hand can be played toward: the ones whose shape can be
    /// scored without guessing. Like Numbers, Quints, Year hands and Singles
    /// and Pairs all depend on the printed card or on a joker count rather
    /// than on tile structure, so committing a player to one and then grading
    /// their discards against it would be inventing rules.
    static let playableTargets: [HandCategory] = RackGenerator.generatableCategories

    // MARK: - The set

    /// All 152 tiles: 108 numbers, 16 winds, 12 dragons, 8 flowers, 8 jokers.
    static var fullSet: [Tile] {
        var tiles: [Tile] = []
        for rank in 1...9 {
            for suit in Suit.allCases {
                tiles += Array(repeating: Tile.suited(rank: rank, suit: suit), count: 4)
            }
        }
        for wind in Wind.allCases { tiles += Array(repeating: Tile.wind(wind), count: 4) }
        for dragon in Dragon.allCases { tiles += Array(repeating: Tile.dragon(dragon), count: 4) }
        tiles += Array(repeating: .flower, count: 8)
        tiles += Array(repeating: .joker, count: 8)
        return tiles
    }

    // MARK: - Dealing

    struct Deal {
        let rack: [Tile]
        /// What is left to draw from, already shuffled.
        let wall: [Tile]
    }

    static func deal() -> Deal {
        var generator = SystemRandomNumberGenerator()
        return deal(using: &generator)
    }

    static func deal(seed: String) -> Deal {
        var generator = StableSeededGenerator(seed: seed)
        return deal(using: &generator)
    }

    static func deal<R: RandomNumberGenerator>(using generator: inout R) -> Deal {
        var tiles = fullSet
        tiles.shuffle(using: &generator)
        let rack = Array(tiles.prefix(13)).racked
        return Deal(rack: rack, wall: Array(tiles.dropFirst(13)))
    }

    // MARK: - Scoring a rack against a section

    /// Tiles that count toward a section's shape. Flowers count for every
    /// playable family: almost every hand on the card has a place for them,
    /// and teaching a beginner to throw flowers early would be teaching a bad
    /// habit for the sake of a tidy model.
    static func belongs(_ tile: Tile, to target: HandCategory, runRange: ClosedRange<Int>? = nil) -> Bool {
        switch tile {
        case .flower, .joker:
            return true
        case .wind, .dragon:
            return target == .windsDragons
        case .suited(let rank, _):
            switch target {
            case .evens2468: return [2, 4, 6, 8].contains(rank)
            case .odds13579: return [1, 3, 5, 7, 9].contains(rank)
            case .threeSixNine: return [3, 6, 9].contains(rank)
            case .consecutiveRun: return runRange?.contains(rank) ?? true
            case .windsDragons: return false
            default: return false
            }
        }
    }

    /// The four adjacent numbers a rack's run is centred on: the window where
    /// its groups are worth the most, by the same arithmetic that grades a
    /// throw. A run hand is only ever four numbers wide, so scoring one
    /// against "any number at all" would make it the right answer for every
    /// rack.
    ///
    /// Chosen by value, not by raw tile count. A count-chosen window could
    /// flip when one in-window single left, so a useless discard "raised" the
    /// rack and the coach marked the equally useless tiles wrong. Ties go to
    /// the window holding more tiles, then the lower one.
    static func bestRunRange(for tiles: [Tile]) -> ClosedRange<Int> {
        var best = 1...4
        var bestValue = -1.0
        var bestCount = -1
        for start in 1...6 {
            let range = start...(start + 3)
            let value = scoredValue(of: tiles, target: .consecutiveRun, runRange: range)
            let count = tiles.filter { tile in
                if case .suited(let rank, _) = tile { return range.contains(rank) }
                return false
            }.count
            if value > bestValue + 0.0001 || (abs(value - bestValue) <= 0.0001 && count > bestCount) {
                best = range
                bestValue = value
                bestCount = count
            }
        }
        return best
    }

    /// How much of a rack is doing work toward a section.
    ///
    /// Groups are what the card asks for, so a rack is scored by its groups
    /// rather than by loose tile counts: a kong is worth more than four
    /// scattered singles of different numbers, and a pair is worth more than
    /// twice a single because it is halfway to a pung. Tiles outside the
    /// family score nothing, which is what makes the coach throw them first.
    /// A run is scored in its best four-number window, so every throw is
    /// judged against the strongest run the rack could still become.
    static func value(of tiles: [Tile], target: HandCategory) -> Double {
        let range = target == .consecutiveRun ? bestRunRange(for: tiles) : nil
        return scoredValue(of: tiles, target: target, runRange: range)
    }

    private static func scoredValue(of tiles: [Tile], target: HandCategory, runRange range: ClosedRange<Int>?) -> Double {
        var counts: [Tile: Int] = [:]
        for tile in tiles { counts[tile, default: 0] += 1 }

        var total = 0.0
        for (tile, count) in counts {
            if case .joker = tile {
                // A joker fills any group of three or more, so it is never
                // dead weight and must never be the coach's throw.
                total += 3.2 * Double(count)
                continue
            }
            guard belongs(tile, to: target, runRange: range) else { continue }
            switch count {
            // Only four of any tile exist, so a count above four cannot
            // happen; the arithmetic is written to stay sane anyway rather
            // than to silently score a fifth copy as a second kong.
            case 4...: total += 4.2 * Double(count / 4) + groupValue(count % 4)
            case 3: total += 3.2
            case 2: total += 1.7
            default: total += 0.6
            }
        }
        return total
    }

    private static func groupValue(_ count: Int) -> Double {
        switch count {
        case 3: return 3.2
        case 2: return 1.7
        case 1: return 0.6
        default: return 0
        }
    }

    /// The sections this rack is best placed to chase, strongest first.
    static func rankedTargets(for tiles: [Tile]) -> [(target: HandCategory, value: Double)] {
        playableTargets
            .map { (target: $0, value: value(of: tiles, target: $0)) }
            .sorted { $0.value > $1.value }
    }

    // MARK: - Grading a discard

    /// Every tile whose loss costs the least. Ties are real and all of them
    /// are graded correct: two useless singles are equally useless, and
    /// insisting on one of them would be inventing a rule to have something to
    /// mark wrong.
    static func bestDiscards(from rack: [Tile], target: HandCategory) -> Set<Tile> {
        let distinct = Set(rack)
        guard !distinct.isEmpty else { return [] }
        var scored: [(tile: Tile, value: Double)] = distinct.map { tile in
            var remaining = rack
            if let index = remaining.firstIndex(of: tile) { remaining.remove(at: index) }
            return (tile, value(of: remaining, target: target))
        }
        scored.sort { $0.value > $1.value }
        guard let best = scored.first?.value else { return [] }
        // A hair of tolerance, so two throws that differ only by floating
        // point noise are not graded differently.
        return Set(scored.filter { $0.value > best - 0.0001 }.map(\.tile))
    }

    /// What one throw cost, against the cheapest throw that was available.
    static func cost(of tile: Tile, from rack: [Tile], target: HandCategory) -> Double {
        guard rack.contains(tile) else { return 0 }
        let best = Set(rack).map { candidate -> Double in
            var remaining = rack
            if let index = remaining.firstIndex(of: candidate) { remaining.remove(at: index) }
            return value(of: remaining, target: target)
        }.max() ?? 0
        var afterThrow = rack
        if let index = afterThrow.firstIndex(of: tile) { afterThrow.remove(at: index) }
        return max(0, best - value(of: afterThrow, target: target))
    }

    // MARK: - Coaching

    /// Why a throw was right, or what it cost.
    static func coachNote(
        for discard: Tile,
        rack: [Tile],
        target: HandCategory,
        wasBest: Bool
    ) -> String {
        let range = target == .consecutiveRun ? bestRunRange(for: rack) : nil
        let copies = rack.filter { $0 == discard }.count
        let fits = belongs(discard, to: target, runRange: range)

        if wasBest {
            if case .joker = discard {
                return String(localized: "That was the only throw available, but jokers are never junk. Hold them.")
            }
            if !fits {
                return String(localized: "Right. The \(discard.spokenName) is outside the \(target.displayName) shape you are building, and tiles that don't fit your shape are the ones to spend first.")
            }
            return copies == 1
                ? String(localized: "Good throw. It fits \(target.displayName), but you were holding only one of it, so it was the cheapest thing on your rack.")
                : String(localized: "Good throw. It fits \(target.displayName), but you were holding only \(copies) of it, so it was the cheapest thing on your rack.")
        }

        let best = bestDiscards(from: rack, target: target)
        let suggestion = best.sorted { $0.sortKey < $1.sortKey }.first
        var note: String
        if case .joker = discard {
            note = String(localized: "Never throw a joker. It can fill any group of three or more, which makes it the most valuable tile on your rack.")
        } else if copies >= 3 {
            note = String(localized: "You just broke a group. You were holding \(copies) of the \(discard.spokenName), and rebuilding that costs you tiles somebody else may already be collecting.")
        } else if copies == 2 {
            note = String(localized: "That was half a pair. A pair is the cheapest route to a pung, so it is worth more than the two loose tiles it looks like.")
        } else if fits {
            note = String(localized: "The \(discard.spokenName) fits \(target.displayName), so throwing it costs you a tile you would have wanted back.")
        } else {
            note = String(localized: "That tile was already outside \(target.displayName), so the throw was not wrong so much as second best.")
        }
        if let suggestion {
            note += " " + String(localized: "The cheapest throw here was the \(suggestion.spokenName).")
        }
        return note
    }

    // MARK: - Verdict

    struct Verdict {
        /// Tiles on the final rack that belong to the target section. This is
        /// the number the player is SHOWN, and it is the same measure the
        /// choose screen used, so the score speaks the vocabulary they picked
        /// their section in.
        let fitting: Int
        /// Of those, the ones already sitting in a group of two or more. Real
        /// progress, but useless as the headline: a rack can hold six evens as
        /// six singles and read as zero, which looks like a scoring bug.
        let working: Int
        let total: Int
        /// Throws that matched a cheapest discard.
        let cleanDiscards: Int
        let discards: Int
        let target: HandCategory
        let stars: Int
        let headline: String
        let body: String
    }

    /// A rack's tiles that both belong to the section and sit in a group of
    /// two or more. A lone in-family tile is not yet doing work.
    static func workingTiles(in rack: [Tile], target: HandCategory) -> Int {
        let range = target == .consecutiveRun ? bestRunRange(for: rack) : nil
        var counts: [Tile: Int] = [:]
        for tile in rack { counts[tile, default: 0] += 1 }
        return counts.reduce(0) { running, entry in
            let (tile, count) = entry
            if case .joker = tile { return running + count }
            guard belongs(tile, to: target, runRange: range), count >= 2 else { return running }
            return running + count
        }
    }

    /// Tiles that simply belong to the section, whether or not they have found
    /// a partner yet. This is the number to SHOW while a player is choosing a
    /// target: a fresh deal has almost no pairs in it, so `workingTiles` reads
    /// as the same tiny number against every section and tells them nothing.
    static func fittingTiles(in rack: [Tile], target: HandCategory) -> Int {
        let range = target == .consecutiveRun ? bestRunRange(for: rack) : nil
        return rack.filter { belongs($0, to: target, runRange: range) }.count
    }

    static func verdict(rack: [Tile], target: HandCategory, cleanDiscards: Int, discards: Int) -> Verdict {
        let fitting = fittingTiles(in: rack, target: target)
        let working = workingTiles(in: rack, target: target)
        let accuracy = discards == 0 ? 0 : Double(cleanDiscards) / Double(discards)
        // Scored on tiles that fit, not on tiles already paired up. Twelve
        // turns is not long enough to pair a rack reliably, and marking a
        // player down for the wall's generosity teaches them nothing.
        let shape = Double(fitting) / Double(max(rack.count, 1))
        let combined = accuracy * 0.6 + shape * 0.4

        let stars: Int
        switch combined {
        case 0.82...: stars = 3
        case 0.6..<0.82: stars = 2
        case 0.35..<0.6: stars = 1
        default: stars = 0
        }

        let headline: String
        switch stars {
        case 3: headline = String(localized: "That is how you build a hand")
        case 2: headline = String(localized: "Solid hand")
        case 1: headline = String(localized: "You got there in the end")
        default: headline = String(localized: "That one fought you")
        }

        let grouped = working == 0
            ? String(localized: "None of them have paired up yet, and pairs are what turn a collection into a hand.")
            : String(localized: "\(working) of them are already sitting in a group of two or more, which is the half that counts.")
        let body = [
            String(localized: "You finished with \(fitting) of \(rack.count) tiles that fit \(target.displayName)."),
            grouped,
            String(localized: "\(cleanDiscards) of your \(discards) throws were the cheapest one available, and that is the number to chase: the shape you are building toward is the whole game, and everything outside it is what you spend."),
        ].joined(separator: " ")

        return Verdict(
            fitting: fitting,
            working: working,
            total: rack.count,
            cleanDiscards: cleanDiscards,
            discards: discards,
            target: target,
            stars: stars,
            headline: headline,
            body: body
        )
    }
}
