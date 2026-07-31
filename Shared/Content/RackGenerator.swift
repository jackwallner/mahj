import Foundation

/// Deals random 13-tile racks that are unambiguously chasing one card section,
/// so Endless Practice can produce rack-reading questions forever instead of
/// shipping a finite pile of hand-written deals.
///
/// **Legal note, and it is the important one:** nothing here reproduces a hand
/// from the NMJL card. The generator works from the STRUCTURE of the stable
/// sections (all evens, all odds, 3-6-9, a consecutive run, honors only) and
/// deals original tile groups that fit that structure. A section is a shape,
/// not a copyrighted line, and shape is what a player actually has to learn.
///
/// Ambiguity is the other constraint. A rack of nothing but 6s is "evens" and
/// "like numbers" and "369" all at once, and grading one of those as the only
/// right answer teaches a player to distrust the app. So every generated rack
/// is checked against `fits` for every section, and a rack that reads as more
/// than one is thrown away rather than shown.
enum RackGenerator {

    /// The sections this generator can deal unambiguously. Like Numbers and
    /// Quints are deliberately absent: a single-number rack always doubles as
    /// evens or odds, and a quint rack is really a joker-count question.
    /// Both stay hand-authored.
    static let generatableCategories: [HandCategory] = [
        .evens2468, .odds13579, .threeSixNine, .consecutiveRun, .windsDragons
    ]

    // MARK: - Reading a rack

    /// The suited ranks on a rack, ignoring flowers and jokers (which are
    /// neutral) and honors (which are counted separately).
    private static func suitedRanks(_ tiles: [Tile]) -> Set<Int> {
        Set(tiles.compactMap { tile in
            if case .suited(let rank, _) = tile { return rank }
            return nil
        })
    }

    private static func hasHonors(_ tiles: [Tile]) -> Bool {
        tiles.contains { tile in
            if case .wind = tile { return true }
            if case .dragon = tile { return true }
            return false
        }
    }

    private static func hasSuited(_ tiles: [Tile]) -> Bool {
        tiles.contains { tile in
            if case .suited = tile { return true }
            return false
        }
    }

    /// Whether a rack plausibly reads as chasing this section. Written to be
    /// mutually exclusive across `generatableCategories`, which is what makes
    /// the distractors safe.
    static func fits(_ tiles: [Tile], _ category: HandCategory) -> Bool {
        let ranks = suitedRanks(tiles)
        let honors = hasHonors(tiles)

        switch category {
        case .windsDragons:
            return honors && !hasSuited(tiles)
        case .evens2468:
            return !honors && !ranks.isEmpty && ranks.isSubset(of: [2, 4, 6, 8]) && ranks.count >= 2
        case .odds13579:
            return !honors && !ranks.isEmpty && ranks.isSubset(of: [1, 3, 5, 7, 9]) && ranks.count >= 2
        case .threeSixNine:
            // Requiring the 6 plus a 3 or a 9 is what stops a 369 rack from
            // also reading as pure evens or pure odds.
            return !honors && ranks.isSubset(of: [3, 6, 9]) && ranks.contains(6)
                && (ranks.contains(3) || ranks.contains(9))
        case .consecutiveRun:
            guard !honors, ranks.count >= 3, let low = ranks.min(), let high = ranks.max() else { return false }
            // A true block: every number between the ends is present. Three in
            // a row always mixes odd and even, so it can never read as either.
            return high - low == ranks.count - 1
        case .year, .likeNumbers, .quints, .singlesAndPairs:
            return false
        }
    }

    /// The one section a rack reads as, or nil if it reads as none or several.
    static func category(for tiles: [Tile]) -> HandCategory? {
        let matches = generatableCategories.filter { fits(tiles, $0) }
        return matches.count == 1 ? matches[0] : nil
    }

    // MARK: - Dealing

    struct GeneratedRack {
        let tiles: [Tile]
        let answer: HandCategory
        let choices: [HandCategory]
        let explanation: String
    }

    /// Group shapes that add up to a 13-tile rack. Real racks are pungs, kongs
    /// and pairs, so a generated rack is built the same way rather than as 13
    /// loose tiles.
    private static let groupPartitions: [[Int]] = [
        [4, 3, 3, 3],
        [3, 3, 3, 2, 2],
        [4, 4, 3, 2],
        [2, 2, 3, 3, 3],
        [4, 4, 2, 3],
        [3, 2, 2, 3, 3],
        [4, 2, 2, 2, 3],
    ]

    /// The distinct tiles a section is allowed to draw from.
    private static func palette(for category: HandCategory) -> [Tile] {
        func suited(_ ranks: [Int]) -> [Tile] {
            ranks.flatMap { rank in Suit.allCases.map { Tile.suited(rank: rank, suit: $0) } }
        }
        switch category {
        case .evens2468: return suited([2, 4, 6, 8])
        case .odds13579: return suited([1, 3, 5, 7, 9])
        case .threeSixNine: return suited([3, 6, 9])
        case .consecutiveRun:
            let start = Int.random(in: 1...6)
            return suited(Array(start...(start + 3)))
        case .windsDragons:
            return Wind.allCases.map { Tile.wind($0) } + Dragon.allCases.map { Tile.dragon($0) }
        default: return []
        }
    }

    /// Deals one rack for a section, or nil if this attempt came out ambiguous.
    /// Only four of any tile exist, so no group ever exceeds a kong and no tile
    /// is used twice.
    private static func deal(_ category: HandCategory) -> [Tile]? {
        var available = palette(for: category).shuffled()
        guard let partition = groupPartitions.randomElement() else { return nil }
        guard available.count >= partition.count else { return nil }

        var tiles: [Tile] = []
        for size in partition {
            guard !available.isEmpty else { return nil }
            let tile = available.removeFirst()
            tiles += Array(repeating: tile, count: size)
        }
        guard tiles.count == 13 else { return nil }
        return tiles.racked
    }

    static func rack(for target: HandCategory, attempts: Int = 200) -> GeneratedRack? {
        for _ in 0..<attempts {
            guard let tiles = deal(target), category(for: tiles) == target else { continue }
            // Distractors must be sections this rack does NOT read as, or the
            // question would have two right answers.
            let distractors = generatableCategories
                .filter { $0 != target && !fits(tiles, $0) }
                .shuffled()
                .prefix(3)
            guard distractors.count >= 2 else { continue }
            let choices = ([target] + distractors).shuffled()
            return GeneratedRack(
                tiles: tiles,
                answer: target,
                choices: choices,
                explanation: explain(tiles, answer: target)
            )
        }
        return nil
    }

    /// A batch spread evenly across the sections rather than at their natural
    /// frequency, so no one section dominates a practice run.
    static func batch(count: Int) -> [GeneratedRack] {
        var targets: [HandCategory] = []
        while targets.count < count {
            targets += generatableCategories.shuffled()
        }
        return targets.prefix(count).compactMap { rack(for: $0) }.shuffled()
    }

    // MARK: - Explanation

    static func explain(_ tiles: [Tile], answer: HandCategory) -> String {
        let ranks = suitedRanks(tiles).sorted()
        let list = ranks.map(String.init).joined(separator: ", ")

        switch answer {
        case .evens2468:
            return "Every number on this rack is even (\(list)), with no honors at all. That is 2468 territory, and every odd tile you pick up is dead weight for it."
        case .odds13579:
            return "Every number here is odd (\(list)). That points straight at 13579, the mirror image of the evens section."
        case .threeSixNine:
            return "The rack holds only 3s, 6s and 9s (\(list)). The 6 rules out a pure odds hand and the 3 or 9 rules out a pure evens hand, so 369 is the read."
        case .consecutiveRun:
            return "The numbers step up in order (\(list)). A run mixes odd and even by definition, so it cannot be an evens or odds hand: this is a Consecutive Run."
        case .windsDragons:
            return "Nothing but winds and dragons, with no numbered tiles anywhere. When honors pile up like this, Winds and Dragons is where to look."
        default:
            return HandCategory.year.howToSpot
        }
    }
}
