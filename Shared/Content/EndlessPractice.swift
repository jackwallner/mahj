import Foundation

/// The generated-practice catalogue. Each skill turns a procedural generator
/// into the same `QuickItem` shape the authored drills already produce, so the
/// session runner never has to know whether a question was written by hand or
/// dealt a second ago.
///
/// This is the answer to the finite-content problem: authored sets are a pile a
/// player finishes, generated skills are a machine that keeps going.
enum PracticeSkill: String, CaseIterable, Identifiable, Sendable {
    case rackReading
    case tileCounting
    case charlestonPass
    case defense
    /// Play a Hand. It is not a question stream like the others, so it never
    /// appears in the Endless picker or the Timed Challenge; it is a member of
    /// this enum purely so its graded throws roll up into ONE stats row
    /// instead of minting an unbounded record per turn.
    case handPlay

    var id: String { rawValue }

    /// The skills that are actually a stream of generated questions.
    static var endlessCases: [PracticeSkill] {
        allCases.filter { $0 != .handPlay }
    }

    var title: String {
        switch self {
        case .rackReading: return "Read the Rack"
        case .tileCounting: return "Count What's Left"
        case .charlestonPass: return "Pass the Junk"
        case .defense: return "Read the Exposures"
        case .handPlay: return "Play a Hand"
        }
    }

    var subtitle: String {
        switch self {
        case .rackReading: return "Freshly dealt racks, unlimited reps"
        case .tileCounting: return "Track the tiles still in play"
        case .charlestonPass: return "Find the tile that fits nothing"
        case .defense: return "Discard without feeding the table"
        case .handPlay: return "Commit to a section and play it out"
        }
    }

    var icon: String {
        switch self {
        case .rackReading: return "square.grid.3x3.fill"
        case .tileCounting: return "number.circle.fill"
        case .charlestonPass: return "arrow.triangle.2.circlepath"
        case .defense: return "shield.lefthalf.filled"
        case .handPlay: return "hand.draw.fill"
        }
    }

    /// The room this skill practises, for the stats breakdown.
    var roomID: String {
        switch self {
        case .rackReading: return "card-room"
        case .tileCounting: return "table-room"
        case .charlestonPass: return "charleston-room"
        case .defense: return "table-room"
        case .handPlay: return "card-room"
        }
    }

    /// Every generated item carries this prefix so `PracticeRecordStore` can
    /// roll an unbounded stream of one-off ids up into one row of stats.
    var itemPrefix: String { "gen-\(rawValue)-" }

    static func skill(forItemID id: String) -> PracticeSkill? {
        allCases.first { id.hasPrefix($0.itemPrefix) }
    }
}

enum EndlessPractice {

    /// A finished endless run is still a "drill" for the completion screen.
    static func drill(for skill: PracticeSkill) -> Drill {
        Drill(id: "endless-\(skill.rawValue)", title: skill.title, subtitle: skill.subtitle, kind: .quiz([]))
    }

    static let challengeDrill = Drill(
        id: "timed-challenge",
        title: "Timed Challenge",
        subtitle: "Beat the clock",
        kind: .quiz([])
    )

    static func items(for skill: PracticeSkill, count: Int) -> [QuickItem] {
        switch skill {
        case .rackReading: return rackItems(count: count)
        case .tileCounting: return countingItems(count: count)
        case .charlestonPass: return passItems(count: count)
        case .defense: return defenseItems(count: count)
        // Play a Hand is a whole screen of its own, not a question stream.
        case .handPlay: return []
        }
    }

    /// A mixed batch across every skill, for the timed challenge.
    static func mixedItems(count: Int) -> [QuickItem] {
        let skills = PracticeSkill.endlessCases
        let perSkill = max(1, count / skills.count + 1)
        return skills.flatMap { items(for: $0, count: perSkill) }.shuffled().prefix(count).map { $0 }
    }

    // MARK: - Rack reading

    private static func rackItems(count: Int) -> [QuickItem] {
        RackGenerator.batch(count: count).map { rackItem($0) }
    }

    static func rackItem(
        _ rack: RackGenerator.GeneratedRack,
        id: String = PracticeSkill.rackReading.itemPrefix + UUID().uuidString,
        sourceLabel: String = "Endless Practice"
    ) -> QuickItem {
        QuickItem(
            id: id,
            prompt: "Which section is this rack chasing?",
            tiles: rack.tiles,
            choices: rack.choices.map(\.displayName),
            answerIndex: rack.choices.firstIndex(of: rack.answer) ?? 0,
            explanation: rack.explanation,
            sourceLabel: sourceLabel,
            roomID: PracticeSkill.rackReading.roomID,
            choiceNotes: RackGenerator.missNotes(tiles: rack.tiles, choices: rack.choices, answer: rack.answer)
        )
    }

    // MARK: - Tile counting

    /// Four of every suited tile, wind and dragon exist. Knowing how many are
    /// still live is the difference between waiting on a tile that is coming
    /// and waiting on one that is already gone, which is the single most
    /// useful counting habit at a real table.
    private static func countingItems(count: Int) -> [QuickItem] {
        var items: [QuickItem] = []
        while items.count < count {
            if Int.random(in: 0..<4) == 0 {
                items.append(jokerCountingItem())
                continue
            }
            let tile = randomCountableTile()
            let held = Int.random(in: 0...2)
            let exposed = Int.random(in: 0...(4 - held - 1))
            let remaining = 4 - held - exposed

            var values = Set([remaining])
            for offset in [-2, -1, 1, 2] where (0...4).contains(remaining + offset) {
                values.insert(remaining + offset)
            }
            let sorted = Array(values.sorted().prefix(4))
            guard let answerIndex = sorted.firstIndex(of: remaining), sorted.count >= 3 else { continue }

            let heldPhrase = held == 0 ? "none on your rack" : "\(held) on your rack"
            let exposedPhrase = exposed == 0 ? "none showing on the table" : "\(exposed) exposed on other racks"

            items.append(QuickItem(
                id: PracticeSkill.tileCounting.itemPrefix + UUID().uuidString,
                prompt: "You have \(heldPhrase) and can see \(exposedPhrase). How many \(tile.spokenName)s are still unaccounted for?",
                // Exactly what the prompt says is on the rack. Forcing one tile
                // when `held` is zero put a tile on screen directly under the
                // words "none on your rack"; the prompt already names the tile
                // in words, so nothing is lost by showing an empty rack.
                tiles: Array(repeating: tile, count: held),
                choices: sorted.map(String.init),
                answerIndex: answerIndex,
                explanation: "Four of every tile exist. \(held) held plus \(exposed) exposed leaves \(remaining) unaccounted for. Jokers cannot stand in for a tile in a pair, so counting matters most when you are waiting on one.",
                sourceLabel: "Endless Practice",
                roomID: PracticeSkill.tileCounting.roomID
            ))
        }
        return items
    }

    /// Jokers follow their own arithmetic: eight in the set, and a discarded
    /// one is dead for good. Knowing how many are still out there tells you
    /// whether a joker-hungry hand is a plan or a wish.
    static func jokerCountingItem() -> QuickItem {
        let held = Int.random(in: 0...2)
        let exposed = Int.random(in: 0...3)
        // At most 2 + 3 + 2 seen, so at least one is always still out there.
        let discarded = Int.random(in: 0...2)
        let remaining = 8 - held - exposed - discarded

        var values = Set([remaining])
        for offset in [-2, -1, 1, 2] where (0...8).contains(remaining + offset) {
            values.insert(remaining + offset)
        }
        let sorted = Array(values.sorted().prefix(4))
        let answerIndex = sorted.firstIndex(of: remaining) ?? 0

        let heldPhrase = held == 0 ? "no jokers" : held == 1 ? "1 joker" : "\(held) jokers"
        let exposedPhrase = exposed == 0 ? "none" : "\(exposed)"
        let discardedPhrase = discarded == 0 ? "none" : "\(discarded)"
        return QuickItem(
            id: PracticeSkill.tileCounting.itemPrefix + UUID().uuidString,
            prompt: "You hold \(heldPhrase). You can see \(exposedPhrase) in exposures and \(discardedPhrase) in the discards. How many jokers are still unseen?",
            tiles: Array(repeating: .joker, count: held),
            choices: sorted.map(String.init),
            answerIndex: answerIndex,
            explanation: "Eight jokers are in the set. \(held) held, \(exposed) exposed and \(discarded) discarded leaves \(remaining) unseen. The exposed ones are not gone: hold the matching real tile and you can swap one out on your turn.",
            sourceLabel: "Endless Practice",
            roomID: PracticeSkill.tileCounting.roomID
        )
    }

    // MARK: - Charleston passes

    /// The generated Charleston question is a single-tile pass decision, not
    /// the full three-tile pass. See `CharlestonGenerator` for why: a
    /// three-tile ranking is not gradeable without a coach, and the authored
    /// Charleston drills still teach the whole pass.
    private static func passItems(count: Int) -> [QuickItem] {
        CharlestonGenerator.batch(count: count).map { passItem($0) }
    }

    static func passItem(
        _ pass: CharlestonGenerator.GeneratedPass,
        id: String = PracticeSkill.charlestonPass.itemPrefix + UUID().uuidString,
        sourceLabel: String = "Endless Practice",
        prompt: String? = nil
    ) -> QuickItem {
        QuickItem(
            id: id,
            prompt: prompt ?? "The first pass is coming. Which tile is the first to go?",
            tiles: pass.tiles,
            choices: pass.choices.map(\.spokenName),
            answerIndex: pass.choices.firstIndex(of: pass.answer) ?? 0,
            explanation: pass.explanation,
            sourceLabel: sourceLabel,
            roomID: PracticeSkill.charlestonPass.roomID,
            choiceNotes: pass.choiceNotes
        )
    }

    // MARK: - Defense

    private static func defenseItems(count: Int) -> [QuickItem] {
        DefenseGenerator.batch(count: count).map { defenseItem($0) }
    }

    static func defenseItem(
        _ question: DefenseGenerator.GeneratedDefense,
        id: String = PracticeSkill.defense.itemPrefix + UUID().uuidString,
        sourceLabel: String = "Endless Practice"
    ) -> QuickItem {
        let shown = question.exposures
            .compactMap(\.first)
            .map { "a pung of \($0.spokenName)" }
            .joined(separator: " and ")
        return QuickItem(
            id: id,
            prompt: "Only one player has tiles out: \(shown). Which discard is safest?",
            // The exposed groups themselves, so the read is on the table
            // rather than buried in the sentence above it.
            tiles: question.exposures.flatMap { $0 },
            choices: question.choices.map(\.spokenName),
            answerIndex: question.choices.firstIndex(of: question.answer) ?? 0,
            explanation: question.explanation,
            sourceLabel: sourceLabel,
            roomID: PracticeSkill.defense.roomID,
            choiceNotes: question.choiceNotes
        )
    }

    /// Flowers and jokers are excluded: eight of each exist, so they do not
    /// follow the four-of-a-kind arithmetic. Jokers get their own question
    /// (`jokerCountingItem`).
    private static func randomCountableTile() -> Tile {
        let suited: [Tile] = (1...9).flatMap { rank in
            Suit.allCases.map { Tile.suited(rank: rank, suit: $0) }
        }
        let honors: [Tile] = Wind.allCases.map { Tile.wind($0) } + Dragon.allCases.map { Tile.dragon($0) }
        return (suited + honors).randomElement() ?? .c(1)
    }
}
