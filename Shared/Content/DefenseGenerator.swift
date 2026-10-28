import Foundation

/// Deals original defensive-discard questions: one opponent's exposures point
/// somewhere obvious, and the player has to find the discard that does not
/// feed them.
///
/// **Legal note:** the exposures here are generic groups (a pung of one tile,
/// a pung of another) chosen to imply a stable section by their SHAPE. No hand
/// from the NMJL card is reproduced or implied, and the question never asks
/// what hand the opponent holds, only which family their exposures point at.
///
/// Only one opponent ever has exposures. Reading a table with three live hands
/// is a judgment call with no single right answer, and grading a judgment call
/// as if it were arithmetic is how a teaching app loses a player's trust.
enum DefenseGenerator {

    struct GeneratedDefense {
        /// What the opponent has face up, in the order they called them.
        let exposures: [[Tile]]
        let impliedSection: HandCategory
        /// The safe discard.
        let answer: Tile
        /// The answer plus three tiles that all feed the implied section.
        let choices: [Tile]
        let explanation: String
        let choiceNotes: [String?]
    }

    /// The sections a pair of exposures can point at without ambiguity.
    ///
    /// Consecutive runs are out: two pungs of adjacent numbers read as a run,
    /// as like numbers, or as a plain number hand, and there is no safe
    /// discard to name while the read itself is arguable. Like Numbers is out
    /// for a duller reason: only three tiles in the whole set are dangerous
    /// against it, which is not enough to build a question whose wrong answers
    /// are all genuinely wrong. Winds & Dragons is out because real cards put
    /// number tiles in that section too, so no number is provably safe
    /// against a player showing winds and dragons.
    static let readableSections: [HandCategory] = [
        .evens2468, .odds13579, .threeSixNine,
    ]

    static func question() -> GeneratedDefense? {
        var generator = SystemRandomNumberGenerator()
        return question(using: &generator)
    }

    static func batch(count: Int) -> [GeneratedDefense] {
        var generator = SystemRandomNumberGenerator()
        return (0..<count).compactMap { _ in question(using: &generator) }
    }

    static func batch(count: Int, seed: String) -> [GeneratedDefense] {
        var generator = StableSeededGenerator(seed: seed)
        return (0..<count).compactMap { _ in question(using: &generator) }
    }

    private static func question<R: RandomNumberGenerator>(
        attempts: Int = 60,
        using generator: inout R
    ) -> GeneratedDefense? {
        for _ in 0..<attempts {
            guard let section = readableSections.randomElement(using: &generator),
                  let built = build(section, using: &generator) else { continue }
            return built
        }
        return nil
    }

    private static func build<R: RandomNumberGenerator>(
        _ section: HandCategory,
        using generator: inout R
    ) -> GeneratedDefense? {
        var dangerous = dangerousTiles(for: section, using: &generator)
        dangerous.shuffle(using: &generator)
        // Two exposed groups plus three tiles still to offer as bait, all
        // distinct so no tile ever needs a fifth copy.
        guard dangerous.count >= 5 else { return nil }

        let exposed = Array(dangerous.prefix(2))
        // Two pungs of the SAME number in different suits is a Like Numbers
        // table, not an evens or odds one, and the safe discard would then be
        // a different tile entirely. Reject the deal rather than teach the
        // wrong read.
        if let first = rank(of: exposed[0]), let second = rank(of: exposed[1]), first == second {
            return nil
        }
        // Exposures can fit more than one section (3 and 9 read as 369 AND as
        // odds). Every bait tile has to feed ALL of those readings, or a player
        // who reads the table the other way throws a tile that is genuinely
        // safe and gets marked wrong.
        let readings = sectionsFitting(exposed)
        let bait = Array(dangerous.dropFirst(2).filter { tile in
            readings.allSatisfy { fits(tile, $0) }
        }.prefix(3))
        guard bait.count == 3 else { return nil }
        let exposures = exposed.map { Array(repeating: $0, count: 3) }

        guard let safe = safeTile(against: readings, exposed: exposed, avoiding: exposed + bait, using: &generator) else { return nil }

        var choices = bait + [safe]
        choices.shuffle(using: &generator)

        let notes: [String?] = choices.map { tile in
            guard tile != safe else { return nil }
            return String(localized: "The \(tile.spokenName) fits \(readingNames(readings)), which is where those exposures point. Late in a hand it could be the tile that hands them the game.")
        }

        return GeneratedDefense(
            exposures: exposures,
            impliedSection: section,
            answer: safe,
            choices: choices,
            explanation: explain(exposures: exposures, section: section, safe: safe),
            choiceNotes: notes
        )
    }

    /// Tiles that belong to the section, used both for the exposures and for
    /// the bait choices.
    private static func dangerousTiles<R: RandomNumberGenerator>(
        for section: HandCategory,
        using generator: inout R
    ) -> [Tile] {
        func suited(_ ranks: [Int]) -> [Tile] {
            ranks.flatMap { rank in Suit.allCases.map { Tile.suited(rank: rank, suit: $0) } }
        }
        switch section {
        case .evens2468: return suited([2, 4, 6, 8])
        case .odds13579: return suited([1, 3, 5, 7, 9])
        case .threeSixNine: return suited([3, 6, 9])
        default: return []
        }
    }

    /// A number tile that cannot plausibly belong to the implied section, or
    /// to any other hand those two exposures could be part of.
    ///
    /// Honors are never offered as safe: real cards put winds and dragons in
    /// the evens, odds and 369 sections. Two further traps are filtered out.
    /// Two pungs a couple of numbers apart can also be a run (6 and 8 Bam
    /// want the 7), so the safe tile must sit outside any five-number window
    /// holding both exposures. And two pungs of the same parity (3 and 9) fit
    /// the matching odds or evens family too, so the safe tile must be the
    /// other parity.
    private static func safeTile<R: RandomNumberGenerator>(
        against readings: [HandCategory],
        exposed: [Tile],
        avoiding used: [Tile],
        using generator: inout R
    ) -> Tile? {
        let exposedRanks = exposed.compactMap { rank(of: $0) }
        guard !readings.isEmpty, let low = exposedRanks.min(), let high = exposedRanks.max() else { return nil }
        let sameParity = exposedRanks.allSatisfy { $0.isMultiple(of: 2) == low.isMultiple(of: 2) }

        let safeRanks = (1...9).filter { candidate in
            let outsideSections = readings.allSatisfy { !fits(rank: candidate, $0) }
            let outsideRun = max(high, candidate) - min(low, candidate) > 4
            let outsideParity = !sameParity || candidate.isMultiple(of: 2) != low.isMultiple(of: 2)
            return outsideSections && outsideRun && outsideParity
        }

        var pool = safeRanks.flatMap { rank in Suit.allCases.map { Tile.suited(rank: rank, suit: $0) } }
        pool.removeAll { used.contains($0) }
        pool.shuffle(using: &generator)
        return pool.first
    }

    /// The stricter test the monthly challenge and Endless Practice apply on
    /// top of `build`, for readings a card can still hold (2026-10-18 content
    /// audit):
    /// - Addition hands: no safe tile that makes a sum with the two exposed
    ///   numbers (5 and 7 with a 2, or 1 and 7 with a 2, read as 5 + 7 = 12).
    /// - Runs: the safe tile and both exposures span seven numbers or more,
    ///   wider than any run that has room for two pungs.
    /// - Year: never pungs of 2s and 6s, which also spell 2026.
    static func isUnarguable(_ question: GeneratedDefense) -> Bool {
        let exposed = question.exposures.compactMap(\.first).compactMap { rank(of: $0) }
        guard exposed.count == 2, let safe = rank(of: question.answer) else { return false }
        let all = exposed + [safe]
        guard (all.max() ?? 0) - (all.min() ?? 0) >= 6 else { return false }
        guard Set(exposed) != [2, 6] else { return false }
        return !makesSum(exposed[0], exposed[1], safe)
    }

    /// Whether three numbers can all sit in one written sum a + b = c, the
    /// digits of c included: 5 + 7 = 12 holds a 1, 2, 5 and 7, so any three
    /// of those can be argued into an addition hand.
    static func makesSum(_ x: Int, _ y: Int, _ z: Int) -> Bool {
        (1...9).contains { a in
            (a...9).contains { b in
                var digits = [a, b] + String(a + b).compactMap(\.wholeNumberValue)
                return [x, y, z].allSatisfy { number in
                    guard let hit = digits.firstIndex(of: number) else { return false }
                    digits.remove(at: hit)
                    return true
                }
            }
        }
    }

    /// Whether every number on a rack is a digit of one written sum (4, 9,
    /// 1 and 3 are 4 + 9 = 13), so an addition hand could want them all.
    static func fitsOneSum(_ ranks: Set<Int>) -> Bool {
        guard !ranks.isEmpty else { return false }
        return (1...9).contains { a in
            (a...9).contains { b in
                ranks.isSubset(of: Set([a, b] + String(a + b).compactMap(\.wholeNumberValue)))
            }
        }
    }

    /// Every readable section that holds all the exposed tiles.
    static func sectionsFitting(_ exposed: [Tile]) -> [HandCategory] {
        readableSections.filter { section in exposed.allSatisfy { fits($0, section) } }
    }

    static func fits(_ tile: Tile, _ section: HandCategory) -> Bool {
        guard let rank = rank(of: tile) else { return false }
        return fits(rank: rank, section)
    }

    private static func fits(rank: Int, _ section: HandCategory) -> Bool {
        switch section {
        case .evens2468: return rank.isMultiple(of: 2)
        case .odds13579: return !rank.isMultiple(of: 2)
        case .threeSixNine: return rank % 3 == 0
        default: return false
        }
    }

    /// The suit both tiles are in, or nil when they differ.
    private static func sharedSuit(_ tiles: [Tile]) -> Suit? {
        let suits = tiles.compactMap { tile -> Suit? in
            if case .suited(_, let suit) = tile { return suit }
            return nil
        }
        guard suits.count == tiles.count, let first = suits.first, suits.allSatisfy({ $0 == first }) else { return nil }
        return first
    }

    private static func rank(of tile: Tile) -> Int? {
        if case .suited(let rank, _) = tile { return rank }
        return nil
    }

    /// The harder version for the monthly challenge: when the two pungs sit
    /// two apart, the tile between them goes in as bait, because it feeds a
    /// run through both. Returns nil when the exposures are not that close.
    static func withRunBait(_ question: GeneratedDefense) -> GeneratedDefense? {
        let exposed = question.exposures.compactMap(\.first)
        // Only pungs in one suit: a run is one suit, so the tile between a
        // 2 Bam and a 4 Dot (or a Crak between two Dots) feeds no run at all.
        guard exposed.count == 2,
              let low = exposed.compactMap({ rank(of: $0) }).min(),
              let high = exposed.compactMap({ rank(of: $0) }).max(),
              high - low == 2,
              let suit = sharedSuit(exposed) else { return nil }
        let runTile = Tile.suited(rank: low + 1, suit: suit)
        guard !question.choices.contains(runTile),
              let bait = question.choices.firstIndex(where: { $0 != question.answer })
        else { return nil }
        var choices = question.choices
        choices[bait] = runTile
        var notes = question.choiceNotes
        let shown = PhraseList.chained(exposed.map(\.spokenName))
        notes[bait] = String(localized: "The \(runTile.spokenName) sits right between their \(shown), so it could feed a run through both pungs. That makes it a trap, not a safe throw.")
        return GeneratedDefense(
            exposures: question.exposures,
            impliedSection: question.impliedSection,
            answer: question.answer,
            choices: choices,
            explanation: question.explanation,
            choiceNotes: notes
        )
    }

    /// "369", or "369 and 13579 (Odds)" when the exposures fit both.
    static func readingNames(_ readings: [HandCategory]) -> String {
        PhraseList.chained(readings.map(\.displayName))
    }

    static func explain(exposures: [[Tile]], section: HandCategory, safe: Tile) -> String {
        let shown = exposures.compactMap(\.first).map(\.spokenName).reduce("") { list, name in
            list.isEmpty ? name : String(localized: "\(list) and a pung of \(name)", comment: "Joins two exposed tiles after 'A pung of'")
        }
        let readings = sectionsFitting(exposures.compactMap(\.first))
        let exposedRanks = exposures.compactMap(\.first).compactMap { rank(of: $0) }
        // Pungs in one suit within five numbers of each other can also sit in
        // a run, and the safe tile is always chosen outside that span. A run
        // is one suit, so pungs in two suits get no run sentence.
        let runSuit = sharedSuit(exposures.compactMap(\.first))
        let runPossible = runSuit != nil && (exposedRanks.max() ?? 0) - (exposedRanks.min() ?? 0) <= 4
        var read = readings.count > 1
            ? String(localized: "A pung of \(shown) fit both \(readingNames(readings)), so read the table both ways.")
            : String(localized: "A pung of \(shown) both sit inside \(section.displayName), so that is the family their exposures point to.")
        if runPossible, let suit = runSuit, let low = exposedRanks.min(), let high = exposedRanks.max() {
            read += " " + String(localized: "A Consecutive Run in \(suit.pluralName) from \(low) to \(high) could hold both, too.")
        }
        let value = rank(of: safe) ?? 0
        var never = readings.map { reading in
            value == 8
                ? String(localized: "\(reading.displayName) never uses an 8")
                : String(localized: "\(reading.displayName) never uses a \(value)")
        }
        if runPossible {
            never.append(value == 8
                ? String(localized: "no run through both of them reaches an 8")
                : String(localized: "no run through both of them reaches a \(value)"))
        }
        let list = never.dropFirst().reduce(never.first ?? "") { list, item in
            String(localized: "\(list), and \(item)", comment: "Joins reasons a tile is safe")
        }
        return String(localized: "\(read) The \(safe.spokenName) fits none of it: \(list). Of these four it is the safest throw, because every other choice feeds what they are showing.")
    }
}
