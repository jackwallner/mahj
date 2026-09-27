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
        let bait = Array(dangerous.dropFirst(2).prefix(3))
        let exposures = exposed.map { Array(repeating: $0, count: 3) }

        guard let safe = safeTile(against: section, exposed: exposed, avoiding: exposed + bait, using: &generator) else { return nil }

        var choices = bait + [safe]
        choices.shuffle(using: &generator)

        let notes: [String?] = choices.map { tile in
            guard tile != safe else { return nil }
            return "The \(tile.spokenName) sits squarely inside \(section.displayName), which is where those exposures point. Late in a hand that is the discard that ends it."
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
        against section: HandCategory,
        exposed: [Tile],
        avoiding used: [Tile],
        using generator: inout R
    ) -> Tile? {
        let exposedRanks = exposed.compactMap { rank(of: $0) }
        guard let low = exposedRanks.min(), let high = exposedRanks.max() else { return nil }
        let sameParity = exposedRanks.allSatisfy { $0.isMultiple(of: 2) == low.isMultiple(of: 2) }

        let safeRanks = (1...9).filter { candidate in
            let outsideSection: Bool
            switch section {
            case .evens2468: outsideSection = !candidate.isMultiple(of: 2)
            case .odds13579: outsideSection = candidate.isMultiple(of: 2)
            case .threeSixNine: outsideSection = candidate % 3 != 0
            default: return false
            }
            let outsideRun = max(high, candidate) - min(low, candidate) > 4
            let outsideParity = !sameParity || candidate.isMultiple(of: 2) != low.isMultiple(of: 2)
            return outsideSection && outsideRun && outsideParity
        }

        var pool = safeRanks.flatMap { rank in Suit.allCases.map { Tile.suited(rank: rank, suit: $0) } }
        pool.removeAll { used.contains($0) }
        pool.shuffle(using: &generator)
        return pool.first
    }

    private static func rank(of tile: Tile) -> Int? {
        if case .suited(let rank, _) = tile { return rank }
        return nil
    }

    static func explain(exposures: [[Tile]], section: HandCategory, safe: Tile) -> String {
        let shown = exposures.compactMap(\.first).map(\.spokenName).joined(separator: " and a pung of ")
        return "A pung of \(shown) both sit inside \(section.displayName), so that is the family this player is building. The \(safe.spokenName) cannot belong to it: \(section.requires). Throw the tile their exposures rule out, and keep the ones they are clearly still collecting."
    }
}
