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
        RackGenerator.batch(count: count).map { rack in
            let labels = rack.choices.map(\.displayName)
            let answerIndex = rack.choices.firstIndex(of: rack.answer) ?? 0
            return QuickItem(
                id: PracticeSkill.rackReading.itemPrefix + UUID().uuidString,
                prompt: "Which section is this rack chasing?",
                tiles: rack.tiles,
                choices: labels,
                answerIndex: answerIndex,
                explanation: rack.explanation,
                sourceLabel: "Endless Practice",
                roomID: PracticeSkill.rackReading.roomID,
                choiceNotes: HandCategory.missNotes(for: rack.choices, answer: rack.answer)
            )
        }
    }

    // MARK: - Tile counting

    /// Four of every suited tile, wind and dragon exist. Knowing how many are
    /// still live is the difference between waiting on a tile that is coming
    /// and waiting on one that is already gone, which is the single most
    /// useful counting habit at a real table.
    private static func countingItems(count: Int) -> [QuickItem] {
        var items: [QuickItem] = []
        while items.count < count {
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

    // MARK: - Charleston passes

    /// The generated Charleston question is a single-tile pass decision, not
    /// the full three-tile pass. See `CharlestonGenerator` for why: a
    /// three-tile ranking is not gradeable without a coach, and the authored
    /// Charleston drills still teach the whole pass.
    private static func passItems(count: Int) -> [QuickItem] {
        CharlestonGenerator.batch(count: count).map { pass in
            let labels = pass.choices.map(\.spokenName)
            let answerIndex = pass.choices.firstIndex(of: pass.answer) ?? 0
            return QuickItem(
                id: PracticeSkill.charlestonPass.itemPrefix + UUID().uuidString,
                prompt: "First pass, three tiles going right. Which of these can you lose for free?",
                tiles: pass.tiles,
                choices: labels,
                answerIndex: answerIndex,
                explanation: pass.explanation,
                sourceLabel: "Endless Practice",
                roomID: PracticeSkill.charlestonPass.roomID,
                choiceNotes: pass.choiceNotes
            )
        }
    }

    // MARK: - Defense

    private static func defenseItems(count: Int) -> [QuickItem] {
        DefenseGenerator.batch(count: count).map { question in
            let labels = question.choices.map(\.spokenName)
            let answerIndex = question.choices.firstIndex(of: question.answer) ?? 0
            let shown = question.exposures
                .compactMap(\.first)
                .map { "a pung of \($0.spokenName)" }
                .joined(separator: " and ")
            return QuickItem(
                id: PracticeSkill.defense.itemPrefix + UUID().uuidString,
                prompt: "The only player with exposures has \(shown) on their rack. Which discard is safest?",
                // The exposed groups themselves, so the read is on the table
                // rather than buried in the sentence above it.
                tiles: question.exposures.flatMap { $0 },
                choices: labels,
                answerIndex: answerIndex,
                explanation: question.explanation,
                sourceLabel: "Endless Practice",
                roomID: PracticeSkill.defense.roomID,
                choiceNotes: question.choiceNotes
            )
        }
    }

    /// Flowers and jokers are excluded: eight of each exist, so they do not
    /// follow the four-of-a-kind arithmetic this drill teaches.
    private static func randomCountableTile() -> Tile {
        let suited: [Tile] = (1...9).flatMap { rank in
            Suit.allCases.map { Tile.suited(rank: rank, suit: $0) }
        }
        let honors: [Tile] = Wind.allCases.map { Tile.wind($0) } + Dragon.allCases.map { Tile.dragon($0) }
        return (suited + honors).randomElement() ?? .c(1)
    }
}
