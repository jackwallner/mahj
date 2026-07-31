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

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rackReading: return "Read the Rack"
        case .tileCounting: return "Count What's Left"
        }
    }

    var subtitle: String {
        switch self {
        case .rackReading: return "Freshly dealt racks, unlimited reps"
        case .tileCounting: return "Track the tiles still in play"
        }
    }

    var icon: String {
        switch self {
        case .rackReading: return "square.grid.3x3.fill"
        case .tileCounting: return "number.circle.fill"
        }
    }

    /// The room this skill practises, for the stats breakdown.
    var roomID: String {
        switch self {
        case .rackReading: return "card-room"
        case .tileCounting: return "table-room"
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
        }
    }

    /// A mixed batch across every skill, for the timed challenge.
    static func mixedItems(count: Int) -> [QuickItem] {
        let skills = PracticeSkill.allCases
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
                roomID: PracticeSkill.rackReading.roomID
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
                tiles: Array(repeating: tile, count: max(held, 1)),
                choices: sorted.map(String.init),
                answerIndex: answerIndex,
                explanation: "Four of every tile exist. \(held) held plus \(exposed) exposed leaves \(remaining) unaccounted for. Jokers cannot stand in for a tile in a pair, so counting matters most when you are waiting on one.",
                sourceLabel: "Endless Practice",
                roomID: PracticeSkill.tileCounting.roomID
            ))
        }
        return items
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
