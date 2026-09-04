import Foundation

/// Deals original Charleston decisions: a rack with a clear direction and one
/// tile that plainly does not belong.
///
/// **Legal note:** as with `RackGenerator`, nothing here reproduces a hand
/// from the NMJL card. A rack is assembled from the SHAPE of a stable section
/// (all evens, all odds, 3-6-9, a run, honors only) and then deliberately
/// polluted with a tile from outside it. The teaching point is the tile that
/// fits nothing, which is a structural fact about the rack rather than a fact
/// about any published hand.
///
/// Why one tile and not three: the real pass is three tiles, and the authored
/// scenarios still drill that whole decision. A generated question has to be
/// gradeable without a coach, and "rank these three against these three" is
/// not. "Which of these four is the one you can lose for free" is, as long as
/// the rack is built so that exactly one answer is defensible: every distractor
/// is part of a group of three or more inside the rack's own section, so
/// passing it breaks something real.
enum CharlestonGenerator {

    struct GeneratedPass {
        let tiles: [Tile]
        let section: HandCategory
        /// The tile that belongs to nothing.
        let answer: Tile
        /// The answer plus three tiles that are each part of a made group.
        let choices: [Tile]
        let explanation: String
        /// Per-choice coaching, parallel to `choices`.
        let choiceNotes: [String?]
    }

    /// Group shapes for the 12 in-section tiles. Two rules hold every shape
    /// here together, and the explanation depends on both:
    ///
    /// 1. No singletons. The coaching sentence tells the player that every
    ///    other tile in the rack is already part of a group, so a lone tile
    ///    inside the "in-section" core would make the question a lie the
    ///    player can see through by counting.
    /// 2. At least three groups of 3 or more, because every distractor has to
    ///    be a tile whose loss genuinely breaks something.
    ///
    /// Twelve, not eleven, because the rack now carries exactly ONE stray.
    private static let corePartitions: [[Int]] = [
        [4, 4, 4],
        [3, 3, 3, 3],
        [4, 3, 3, 2],
        [3, 4, 3, 2],
    ]

    static func pass(attempts: Int = 200) -> GeneratedPass? {
        var generator = SystemRandomNumberGenerator()
        return pass(attempts: attempts, using: &generator)
    }

    static func batch(count: Int) -> [GeneratedPass] {
        var generator = SystemRandomNumberGenerator()
        return (0..<count).compactMap { _ in pass(using: &generator) }
    }

    static func batch(count: Int, seed: String) -> [GeneratedPass] {
        var generator = StableSeededGenerator(seed: seed)
        return (0..<count).compactMap { _ in pass(using: &generator) }
    }

    private static func pass<R: RandomNumberGenerator>(
        attempts: Int = 200,
        using generator: inout R
    ) -> GeneratedPass? {
        for _ in 0..<attempts {
            guard let section = RackGenerator.generatableCategories.randomElement(using: &generator),
                  let built = build(section: section, using: &generator) else { continue }
            return built
        }
        return nil
    }

    private static func build<R: RandomNumberGenerator>(
        section: HandCategory,
        using generator: inout R
    ) -> GeneratedPass? {
        var palette = inPalette(for: section, using: &generator)
        palette.shuffle(using: &generator)
        guard let partition = corePartitions.randomElement(using: &generator),
              palette.count >= partition.count else { return nil }

        var core: [Tile] = []
        var groupLeaders: [Tile] = []
        for size in partition {
            guard !palette.isEmpty else { return nil }
            let tile = palette.removeFirst()
            core += Array(repeating: tile, count: size)
            if size >= 3 { groupLeaders.append(tile) }
        }
        guard core.count == 12, groupLeaders.count >= 3 else { return nil }

        // Exactly one stray. A second one used to ride along to make the rack
        // look like a real pre-Charleston mess, but only the first was ever
        // offered as an answer, so the explanation's closing promise ("every
        // other tile here is already part of a group") was false about a tile
        // sitting in plain sight on the rack.
        guard let strays = outsiders(for: section, count: 1, using: &generator) else { return nil }
        let rack = (core + strays).racked
        guard rack.count == 13 else { return nil }

        let answer = strays[0]
        groupLeaders.shuffle(using: &generator)
        let distractors = Array(groupLeaders.prefix(3))
        guard distractors.count == 3 else { return nil }

        var choices = [answer] + distractors
        choices.shuffle(using: &generator)

        let notes: [String?] = choices.map { tile in
            guard tile != answer else { return nil }
            let held = rack.filter { $0 == tile }.count
            return "You are holding \(held) of the \(tile.spokenName). Passing one breaks a group you have already built, and you would have to rebuild it from a suit somebody else may be collecting."
        }

        return GeneratedPass(
            tiles: rack,
            section: section,
            answer: answer,
            choices: choices,
            explanation: explain(rack: rack, section: section, answer: answer),
            choiceNotes: notes
        )
    }

    /// Tiles that fit the section's shape.
    private static func inPalette<R: RandomNumberGenerator>(
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
        case .consecutiveRun:
            let start = Int.random(in: 1...6, using: &generator)
            return suited(Array(start...(start + 3)))
        case .windsDragons:
            return Wind.allCases.map { Tile.wind($0) } + Dragon.allCases.map { Tile.dragon($0) }
        default: return []
        }
    }

    /// Distinct single tiles that plainly do not fit the section. Flowers and
    /// jokers are never strays: a flower is wanted by most hands and a joker
    /// can never legally be passed at all.
    private static func outsiders<R: RandomNumberGenerator>(
        for section: HandCategory,
        count: Int,
        using generator: inout R
    ) -> [Tile]? {
        let suitedAll: [Tile] = (1...9).flatMap { rank in
            Suit.allCases.map { Tile.suited(rank: rank, suit: $0) }
        }
        let honors: [Tile] = Wind.allCases.map { Tile.wind($0) } + Dragon.allCases.map { Tile.dragon($0) }
        var pool: [Tile]
        switch section {
        case .windsDragons:
            // Honors-only hand: any numbered tile is a stray.
            pool = suitedAll
        default:
            let fitting = Set(inPaletteRanks(section))
            pool = suitedAll.filter { tile in
                if case .suited(let rank, _) = tile { return !fitting.contains(rank) }
                return false
            } + honors
        }
        pool.shuffle(using: &generator)
        var picked: [Tile] = []
        for tile in pool where !picked.contains(tile) {
            picked.append(tile)
            if picked.count == count { return picked }
        }
        return nil
    }

    /// The ranks a section accepts. Runs are handled by their own palette, so
    /// this is only used to exclude, never to build.
    private static func inPaletteRanks(_ section: HandCategory) -> [Int] {
        switch section {
        case .evens2468: return [2, 4, 6, 8]
        case .odds13579: return [1, 3, 5, 7, 9]
        case .threeSixNine: return [3, 6, 9]
        // A run's own palette is four adjacent numbers, but excluding only
        // those four would let a stray land one step outside the run, which a
        // player could reasonably want to keep. Excluding every number keeps
        // the stray unarguable: it will be an honor.
        case .consecutiveRun: return Array(1...9)
        default: return []
        }
    }

    static func explain(rack: [Tile], section: HandCategory, answer: Tile) -> String {
        let copies = rack.filter { $0 == answer }.count
        let loneness = copies == 1
            ? "You hold exactly one of it"
            : "You hold \(copies) of it and nothing else that pairs with them"
        return "This rack is pointed at \(section.displayName): \(section.requires). The \(answer.spokenName) fits none of that. \(loneness), so it is the tile you can lose for free, and the first pass is where junk should go. Every other tile here is already part of a group you have built."
    }
}
