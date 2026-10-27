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

    /// Shapes that read as a section on paper but invite a second read at a
    /// real table, so a generated rack never shows them:
    /// - more than five of one number across the suits reads as Like Numbers
    ///   (seven 5s is a like-numbers start whatever else is on the rack);
    /// - an odds rack of nothing but 3s and 9s reads as 369 just as well.
    static func isClean(_ tiles: [Tile], for section: HandCategory) -> Bool {
        var counts: [Int: Int] = [:]
        for tile in tiles {
            if case .suited(let rank, _) = tile { counts[rank, default: 0] += 1 }
        }
        if (counts.values.max() ?? 0) > 5 { return false }
        if section == .odds13579, Set(counts.keys).isSubset(of: [3, 9]) { return false }
        return true
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
    private static func palette<R: RandomNumberGenerator>(
        for category: HandCategory,
        using generator: inout R
    ) -> [Tile] {
        func suited(_ ranks: [Int]) -> [Tile] {
            ranks.flatMap { rank in Suit.allCases.map { Tile.suited(rank: rank, suit: $0) } }
        }
        switch category {
        case .evens2468: return suited([2, 4, 6, 8])
        case .odds13579: return suited([1, 3, 5, 7, 9])
        case .threeSixNine: return suited([3, 6, 9])
        case .consecutiveRun:
            let start = Int.random(in: 1...6, using: &generator)
            return suited(Array(start...(start + 3)))
        case .windsDragons:
            return Wind.allCases.map { Tile.wind($0) } + Dragon.allCases.map { Tile.dragon($0) }
        default: return []
        }
    }

    /// Deals one rack for a section, or nil if this attempt came out ambiguous.
    /// Only four of any tile exist, so no group ever exceeds a kong and no tile
    /// is used twice.
    private static func deal<R: RandomNumberGenerator>(
        _ category: HandCategory,
        using generator: inout R
    ) -> [Tile]? {
        var available = palette(for: category, using: &generator)
        available.shuffle(using: &generator)
        guard let partition = groupPartitions.randomElement(using: &generator) else { return nil }
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

    private static func rack<R: RandomNumberGenerator>(
        for target: HandCategory,
        attempts: Int = 200,
        using generator: inout R
    ) -> GeneratedRack? {
        for _ in 0..<attempts {
            guard let tiles = deal(target, using: &generator), category(for: tiles) == target,
                  isClean(tiles, for: target) else { continue }
            // Distractors must be sections this rack does NOT read as, or the
            // question would have two right answers.
            var distractors = generatableCategories
                .filter { $0 != target && !fits(tiles, $0) }
            distractors.shuffle(using: &generator)
            let pickedDistractors = distractors.prefix(3)
            guard pickedDistractors.count >= 2 else { continue }
            var choices = [target] + Array(pickedDistractors)
            choices.shuffle(using: &generator)
            return GeneratedRack(
                tiles: tiles,
                answer: target,
                choices: choices,
                explanation: explain(tiles, answer: target)
            )
        }
        return nil
    }

    static func rack(for target: HandCategory, attempts: Int = 200) -> GeneratedRack? {
        var generator = SystemRandomNumberGenerator()
        return rack(for: target, attempts: attempts, using: &generator)
    }

    /// A reproducible rack for one section, for the dated monthly challenge.
    static func rack(for target: HandCategory, seed: String) -> GeneratedRack? {
        var generator = StableSeededGenerator(seed: seed)
        return rack(for: target, using: &generator)
    }

    /// A batch spread evenly across the sections rather than at their natural
    /// frequency, so no one section dominates a practice run.
    static func batch(count: Int) -> [GeneratedRack] {
        var generator = SystemRandomNumberGenerator()
        return batch(count: count, using: &generator)
    }

    /// A reproducible batch for a dated shared challenge. The same app build
    /// and seed produce the same original racks on every device.
    static func batch(count: Int, seed: String) -> [GeneratedRack] {
        var generator = StableSeededGenerator(seed: seed)
        return batch(count: count, using: &generator)
    }

    private static func batch<R: RandomNumberGenerator>(
        count: Int,
        using generator: inout R
    ) -> [GeneratedRack] {
        var targets: [HandCategory] = []
        while targets.count < count {
            var pass = generatableCategories
            pass.shuffle(using: &generator)
            targets += pass
        }
        var racks = targets.prefix(count).compactMap { rack(for: $0, using: &generator) }
        racks.shuffle(using: &generator)
        return racks
    }

    // MARK: - Explanation

    /// Why a wrong section does not fit THIS rack, naming the tiles that rule
    /// it out. A fixed line per section was often untrue for the rack on
    /// screen ("a single odd tile" on a rack with no numbers at all).
    static func missNotes(tiles: [Tile], choices: [HandCategory], answer: HandCategory) -> [String?] {
        choices.map { choice in choice == answer ? nil : missNote(tiles: tiles, choice: choice, answer: answer) }
    }

    /// Why a wrong section does not fit this rack. When nothing on the rack
    /// rules the section out, the note says the answer is the stronger read
    /// instead of restating what the section wants, which on a rack that
    /// half fits it would argue for the wrong answer.
    static func missNote(tiles: [Tile], choice: HandCategory, answer: HandCategory) -> String {
        let ranks = suitedRanks(tiles).sorted()
        let generic = String(localized: "\(choice.displayName) could use some of these tiles, but more of them point to \(answer.displayName).")
        let noNumbers = String(localized: "This rack has no numbered tiles at all, and \(choice.displayName) is built from numbers.")
        switch choice {
        case .evens2468:
            let odd = ranks.filter { !$0.isMultiple(of: 2) }
            if ranks.isEmpty { return noNumbers }
            return odd.isEmpty ? generic : String(localized: "This rack holds \(plural(odd)), and a finished 2468 hand never uses an odd number.")
        case .odds13579:
            let even = ranks.filter { $0.isMultiple(of: 2) }
            if ranks.isEmpty { return noNumbers }
            return even.isEmpty ? generic : String(localized: "This rack holds \(plural(even)), and a finished 13579 hand never uses an even number.")
        case .threeSixNine:
            let outside = ranks.filter { $0 % 3 != 0 }
            if ranks.isEmpty { return noNumbers }
            if !outside.isEmpty { return String(localized: "This rack holds \(plural(outside)), and a finished 369 hand never uses them.") }
            return ranks.contains(6) ? generic : String(localized: "There is no 6 here, and 369 needs the 6 to read as anything other than odds.")
        case .consecutiveRun:
            if ranks.isEmpty { return String(localized: "A run is all numbers stepping up in order, and this rack has no numbered tiles.") }
            if ranks.count < 3 { return String(localized: "A run steps up with no gaps, and this rack only has \(plural(ranks)).") }
            // Any three numbers in a row is the start of a run, so only a rack
            // without one is ruled out by its gaps.
            let hasThreeInARow = ranks.contains { ranks.contains($0 + 1) && ranks.contains($0 + 2) }
            return hasThreeInARow ? generic : String(localized: "The numbers here (\(ranks.map(String.init).joined(separator: ", "))) never make three in a row, and a run steps up with no gaps.")
        case .windsDragons:
            let suited = tiles.filter { if case .suited = $0 { return true }; return false }.count
            let honors = tiles.filter { tile in
                if case .wind = tile { return true }
                if case .dragon = tile { return true }
                return false
            }.count
            guard suited > honors else { return generic }
            switch honors {
            case 0: return String(localized: "This rack has \(suited) numbered tiles and no winds or dragons, so it has little to build a Winds & Dragons hand from.")
            case 1: return String(localized: "This rack has \(suited) numbered tiles and only one wind or dragon, so it has little to build a Winds & Dragons hand from.")
            default: return String(localized: "This rack has \(suited) numbered tiles and only \(honors) winds or dragons, so it has little to build a Winds & Dragons hand from.")
            }
        case .likeNumbers:
            if ranks.isEmpty { return noNumbers }
            if ranks.count >= 3 { return String(localized: "Like Numbers repeats one number across the suits, and this rack spreads across \(plural(ranks)).") }
            let numbered = tiles.filter { if case .suited = $0 { return true }; return false }.count
            if numbered == 1 { return String(localized: "Like Numbers is built from one number in several suits, and this rack has only 1 number tile.") }
            if numbered < 5 { return String(localized: "Like Numbers is built from one number in several suits, and this rack has only \(numbered) number tiles.") }
            return generic
        case .year:
            // The digits change with every card, so the note never names them.
            return ranks.isEmpty ? noNumbers : generic
        case .quints:
            let jokers = tiles.filter { $0 == .joker }.count
            switch jokers {
            case 0: return String(localized: "Quints need five of a kind, which takes jokers, and this rack has none.")
            case 1: return String(localized: "Quints need five of a kind, which takes jokers, and this rack has just one.")
            default: return generic
            }
        case .singlesAndPairs:
            // Flowers are left out: a third flower is just a spare, not a pung.
            let counts = Dictionary(grouping: tiles.filter { $0 != .joker && $0 != .flower }, by: { $0 }).mapValues(\.count)
            if let pung = counts.filter({ $0.value >= 3 }).keys.sorted(by: { $0.englishName < $1.englishName }).first {
                return String(localized: "This rack holds three or more \(pung.spokenName), and Singles & Pairs never uses a pung.")
            }
            if tiles.contains(.joker) {
                return String(localized: "Singles & Pairs never takes jokers, so the joker on this rack could not help it.")
            }
            return generic
        }
    }

    /// "5s", "5s and 7s", "1s, 3s and 7s".
    private static func plural(_ ranks: [Int]) -> String {
        PhraseList.and(ranks.map { String(localized: "\($0)s", comment: "A number as a group of tiles, as in 'this rack holds 5s'") })
    }

    static func explain(_ tiles: [Tile], answer: HandCategory) -> String {
        let ranks = suitedRanks(tiles).sorted()
        let list = ranks.map(String.init).joined(separator: ", ")

        switch answer {
        case .evens2468:
            return String(localized: "Every number on this rack is even (\(list)), with no honors at all. That is 2468 territory, and every odd tile you pick up is dead weight for it.")
        case .odds13579:
            return String(localized: "Every number here is odd (\(list)). That points straight at 13579, the mirror image of the evens section.")
        case .threeSixNine:
            return String(localized: "Every number here is a 3, 6 or 9. The 6 rules out a pure odds hand and the 3 or 9 rules out a pure evens hand, so 369 is the read.")
        case .consecutiveRun:
            return String(localized: "The numbers step up in order (\(list)). A run mixes odd and even by definition, so it cannot be an evens or odds hand: this is a Consecutive Run.")
        case .windsDragons:
            return String(localized: "Nothing but winds and dragons, with no numbered tiles anywhere. When honors pile up like this, Winds and Dragons is where to look.")
        default:
            return HandCategory.year.howToSpot
        }
    }
}
