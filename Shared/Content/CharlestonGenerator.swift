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

    /// One pass for a chosen section, for the monthly challenge, which
    /// takes the sections in turn: picking one at random per attempt let the
    /// sections that build most easily crowd out the rest (Winds & Dragons
    /// was half of every month). iOS only, like the rest of the challenge.
    static func pass(section: HandCategory, seed: String, twoSingles: Bool = false) -> GeneratedPass? {
        var generator = StableSeededGenerator(seed: seed)
        for _ in 0..<3000 {
            let built = twoSingles
                ? buildTwoSingles(section: section, using: &generator)
                : build(section: section, using: &generator)
            if let built, isUnarguable(built) { return built }
        }
        return nil
    }

    /// The stricter test the monthly challenge and Endless Practice apply on
    /// top of `build` (2026-10-18 answer audit): the stray must be nothing
    /// to any hand a player could argue for.
    /// - Addition hands: not when a number stray and every other number on
    ///   the rack are digits of one sum (4, 9, 1 and 3 read as 4 + 9 = 13),
    ///   with or without a two-singles rack's keeper.
    /// - Year hands: never a Soap stray beside a 2, 6 or 7, since the Soap
    ///   writes the year's zero, and never a 2, 6 or 7 stray beside Soaps
    ///   or on a Winds & Dragons rack, and never a wind or dragon stray
    ///   beside a 2 and a 6 or 7 (2026, 2027).
    static func isUnarguable(_ pass: GeneratedPass) -> Bool {
        let ranks = Set(pass.tiles.compactMap { tile -> Int? in
            if case .suited(let rank, _) = tile { return rank }
            return nil
        })
        if case .suited = pass.answer, ranks.count >= 3, DefenseGenerator.fitsOneSum(ranks) { return false }
        // A two-singles rack must not fit one sum without its keeper either:
        // 4 + 8 = 12 holds a stray 1 once the keeper 6 goes, and then passing
        // the keeper is just as right.
        if case .suited = pass.answer {
            let otherSingles = pass.tiles.filter { tile in tile != pass.answer && pass.tiles.filter { $0 == tile }.count == 1 }
            for single in otherSingles {
                var rest = pass.tiles
                if let index = rest.firstIndex(of: single) { rest.remove(at: index) }
                let restRanks = Set(rest.compactMap { tile -> Int? in
                    if case .suited(let rank, _) = tile { return rank }
                    return nil
                })
                if restRanks.count >= 3, DefenseGenerator.fitsOneSum(restRanks) { return false }
            }
        }
        if pass.answer == .dragon(.soap), !ranks.isDisjoint(with: [2, 6, 7]) { return false }
        // A 2 with a 6 or 7 on the rack is two of the year's digits, so
        // neither is a stray.
        if case .suited(let rank, _) = pass.answer, [2, 6, 7].contains(rank),
           ranks.contains(2), !ranks.isDisjoint(with: [6, 7]) { return false }
        // A 2, 6 or 7 on an honors rack could be a year written beside winds.
        if pass.section == .windsDragons, case .suited(let rank, _) = pass.answer, [2, 6, 7].contains(rank) { return false }
        // The mirror case: a 2, 6 or 7 stray beside Soaps reads as a year start.
        if pass.tiles.contains(.dragon(.soap)), case .suited(let rank, _) = pass.answer, [2, 6, 7].contains(rank) { return false }
        // And a wind or dragon stray beside a 2 and a 6 or 7: the year can be
        // written beside honors, so the stray is not nothing.
        switch pass.answer {
        case .wind, .dragon:
            if ranks.contains(2), !ranks.isDisjoint(with: [6, 7]) { return false }
        default:
            break
        }
        return true
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
        // The core has to read as this section and nothing else. A 369 core
        // dealt without a 6 is just 3s and 9s, which reads as odds too, and an
        // odd stray then fits the hand: two right answers. A run core that
        // spans only two numbers is not a run at all.
        guard RackGenerator.category(for: core) == section,
              RackGenerator.isClean(core, for: section) else { return nil }

        // Exactly one stray. A second one used to ride along to make the rack
        // look like a real pre-Charleston mess, but only the first was ever
        // offered as an answer, so the explanation's closing promise ("every
        // other tile here is already part of a group") was false about a tile
        // sitting in plain sight on the rack.
        guard let strays = outsiders(for: section, count: 1, using: &generator) else { return nil }
        let rack = (core + strays).racked
        guard rack.count == 13 else { return nil }
        // The stray must not change what the rack reads as. A 3 Dot beside
        // 2s and 4s turns an evens rack into a run, and then the "junk" tile
        // is the keystone. Any three-in-a-row it completes is the same trap.
        let fullRead = RackGenerator.category(for: rack)
        guard fullRead == nil || fullRead == section,
              !completesRun(strays[0], core: core) else { return nil }

        let answer = strays[0]
        groupLeaders.shuffle(using: &generator)
        let distractors = Array(groupLeaders.prefix(3))
        guard distractors.count == 3 else { return nil }

        var choices = [answer] + distractors
        choices.shuffle(using: &generator)

        let notes: [String?] = choices.map { tile in
            guard tile != answer else { return nil }
            return note(passing: tile, held: rack.filter { $0 == tile }.count)
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

    // MARK: - Two singles (the monthly challenge)

    /// The harder shape: the rack holds TWO single tiles, one that fits the
    /// section and one that does not, so the question is reading the hand
    /// rather than counting copies. iOS only for now; the Android port has no
    /// monthly challenge to use it.
    static func twoSinglesBatch(count: Int, seed: String) -> [GeneratedPass] {
        var generator = StableSeededGenerator(seed: seed)
        return (0..<count).compactMap { _ in
            for _ in 0..<300 {
                guard let section = twoSinglesSections.randomElement(using: &generator),
                      let built = buildTwoSingles(section: section, using: &generator) else { continue }
                return built
            }
            return nil
        }
    }

    /// Runs are left out: their only clean stray is an honor, and an honor
    /// against a number single is a judgment call, not a reading question.
    static let twoSinglesSections: [HandCategory] = [.evens2468, .odds13579, .threeSixNine, .windsDragons]

    private static let twoSinglesPartitions: [[Int]] = [
        [3, 3, 3, 2, 1],
        [4, 3, 2, 2, 1],
        [4, 4, 3, 1],
    ]

    private static func buildTwoSingles<R: RandomNumberGenerator>(
        section: HandCategory,
        using generator: inout R
    ) -> GeneratedPass? {
        var palette = inPalette(for: section, using: &generator)
        palette.shuffle(using: &generator)
        guard let partition = twoSinglesPartitions.randomElement(using: &generator),
              palette.count >= partition.count else { return nil }
        var core: [Tile] = []
        var groupLeaders: [Tile] = []
        var keeper: Tile?
        for size in partition {
            let tile = palette.removeFirst()
            core += Array(repeating: tile, count: size)
            if size >= 3 { groupLeaders.append(tile) }
            if size == 1 { keeper = tile }
        }
        guard let keeper, core.count == 12, groupLeaders.count >= 2,
              RackGenerator.category(for: core) == section,
              RackGenerator.isClean(core, for: section) else { return nil }

        // A number stray for number sections: an honor against a number
        // single invites "dragons go in number hands too", which is a fair
        // argument and therefore a bad question.
        var pool: [Tile] = (1...9).flatMap { rank in Suit.allCases.map { Tile.suited(rank: rank, suit: $0) } }
        if section != .windsDragons {
            let fitting = Set(inPaletteRanks(section))
            pool = pool.filter { tile in
                if case .suited(let rank, _) = tile { return !fitting.contains(rank) }
                return false
            }
        }
        pool.shuffle(using: &generator)
        guard let stray = pool.first(where: { !completesRun($0, core: core) }) else { return nil }
        let rack = (core + [stray]).racked
        let fullRead = RackGenerator.category(for: rack)
        guard fullRead == nil || fullRead == section else { return nil }

        // Real cards put a few numbers in Winds & Dragons hands, so a lone
        // number there is the weakest fit, not an impossible one.
        let honorsRack = section == .windsDragons
        groupLeaders.shuffle(using: &generator)
        var choices = [stray, keeper] + Array(groupLeaders.prefix(2))
        choices.shuffle(using: &generator)
        let notes: [String?] = choices.map { tile in
            if tile == stray { return nil }
            if tile == keeper {
                return honorsRack
                    ? String(localized: "The \(keeper.spokenName) is a single too, but it fits \(section.displayName): one more draw makes it a pair. The \(stray.spokenName) is a lone number, the tile this rack has least use for.")
                    : String(localized: "The \(keeper.spokenName) is a single too, but it fits \(section.displayName): one more draw makes it a pair. The \(stray.spokenName) is a number \(section.displayName) never uses.")
            }
            return note(passing: tile, held: rack.filter { $0 == tile }.count)
        }
        let explanation = honorsRack
            ? String(localized: "This rack is pointed at \(section.displayName), and two tiles are singles. The \(keeper.spokenName) fits that plan and can still grow into a pair or a pung. The \(stray.spokenName) is a lone number, the tile this rack has least use for, so it is the one to pass. Keep the single that can still help.")
            : String(localized: "This rack is pointed at \(section.displayName), and two tiles are singles. The \(keeper.spokenName) fits that plan and can still grow into a pair or a pung. The \(stray.spokenName) is a number \(section.displayName) never uses, so it is the one to pass. Keep the single that can still help.")
        return GeneratedPass(tiles: rack, section: section, answer: stray, choices: choices, explanation: explanation, choiceNotes: notes)
    }

    /// Whether a numbered stray would sit in a three-in-a-row with the core's
    /// numbers, any suits. Honors never do.
    static func completesRun(_ stray: Tile, core: [Tile]) -> Bool {
        guard case .suited(let rank, _) = stray else { return false }
        let ranks = Set(core.compactMap { tile -> Int? in
            if case .suited(let value, _) = tile { return value }
            return nil
        } + [rank])
        return (rank - 2...rank).contains { start in
            (start...start + 2).allSatisfy { ranks.contains($0) }
        }
    }

    static func note(passing tile: Tile, held: Int) -> String {
        switch held {
        case 4...:
            return String(localized: "You hold \(held) of the \(tile.spokenName). Passing one turns a kong back into a pung, when another tile on this rack costs you nothing.")
        case 3:
            return String(localized: "You hold \(held) of the \(tile.spokenName). Passing one breaks up a pung you have already made, when another tile on this rack costs you nothing.")
        default:
            return String(localized: "You hold \(held) of the \(tile.spokenName). Passing one splits a pair, when another tile on this rack costs you nothing.")
        }
    }

    static func explain(rack: [Tile], section: HandCategory, answer: Tile) -> String {
        let copies = rack.filter { $0 == answer }.count
        if copies == 1 {
            return String(localized: "This rack is pointed at \(section.displayName). The \(answer.spokenName) is your only single tile. It might fit some hand, but every other choice is part of a group you have already built, so it is the one tile you can pass without breaking anything. Junk goes on the first pass.")
        }
        return String(localized: "This rack is pointed at \(section.displayName). The \(answer.spokenName) is \(copies) of a tile nothing else on the rack works with. It might fit some hand, but every other choice is part of a group you have already built, so it is the one tile you can pass without breaking anything. Junk goes on the first pass.")
    }
}
