import Foundation

/// A two-option self-test on a card's front ("Keep" / "Throw"). Answering
/// flips the card and grades the pick before the explanation lands.
struct CardChoice: Codable, Sendable {
    let options: [String]
    let answerIndex: Int

    init(_ first: String, _ second: String, answerIndex: Int) {
        options = ContentText.localized([first, second])
        self.answerIndex = answerIndex
    }
}

struct Flashcard: Codable, Identifiable, Sendable {
    let id: String
    let frontTitle: String
    let frontTiles: [Tile]
    let frontSubtitle: String?
    let backTitle: String
    let backBody: String
    let choice: CardChoice?

    init(id: String, frontTitle: String, frontTiles: [Tile] = [], frontSubtitle: String? = nil,
         backTitle: String, backBody: String, choice: CardChoice? = nil) {
        self.id = id
        self.frontTitle = ContentText.localized(frontTitle)
        self.frontTiles = frontTiles
        self.frontSubtitle = ContentText.localized(frontSubtitle)
        self.backTitle = ContentText.localized(backTitle)
        self.backBody = ContentText.localized(backBody)
        self.choice = choice
    }
}

struct QuizQuestion: Codable, Identifiable, Sendable {
    let id: String
    let prompt: String
    let tiles: [Tile]
    let choices: [String]
    let answerIndex: Int
    let explanation: String

    init(id: String, prompt: String, tiles: [Tile] = [], choices: [String], answerIndex: Int,
         explanation: String) {
        self.id = id
        self.prompt = ContentText.localized(prompt)
        self.tiles = tiles
        self.choices = ContentText.localized(choices)
        self.answerIndex = answerIndex
        self.explanation = ContentText.localized(explanation)
    }
}

struct HandMatchQuestion: Codable, Identifiable, Sendable {
    let id: String
    let tiles: [Tile]
    let choices: [HandCategory]
    let answer: HandCategory
    let explanation: String

    init(id: String, tiles: [Tile], choices: [HandCategory], answer: HandCategory, explanation: String) {
        self.id = id
        self.tiles = tiles
        self.choices = choices
        self.answer = answer
        self.explanation = ContentText.localized(explanation)
    }
}

struct CharlestonScenario: Codable, Identifiable, Sendable {
    let id: String
    let situation: String
    let deal: [Tile]
    let recommendedPass: [Tile]
    let reasoning: String
    let tip: String
    /// The situation without its "Pick 3" cue, for prompts that ask the
    /// question in their own words.
    let situationStem: String

    init(id: String, situation: String, deal: [Tile], recommendedPass: [Tile], reasoning: String, tip: String) {
        self.id = id
        self.situation = ContentText.localized(situation)
        self.deal = deal
        self.recommendedPass = recommendedPass
        self.reasoning = ContentText.localized(reasoning)
        self.tip = ContentText.localized(tip)
        let stem = situation
            .replacingOccurrences(of: " Pick 3 tiles to pass.", with: "")
            .replacingOccurrences(of: " Pick 3.", with: "")
        situationStem = ContentText.localized(stem)
    }
}

enum DrillKind: Codable, Sendable {
    case flashcards([Flashcard])
    case quiz([QuizQuestion])
    case handMatch([HandMatchQuestion])
    case charleston([CharlestonScenario])

    var itemCount: Int {
        switch self {
        case .flashcards(let cards): return cards.count
        case .quiz(let questions): return questions.count
        case .handMatch(let questions): return questions.count
        case .charleston(let scenarios): return scenarios.count
        }
    }
}

struct Drill: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let kind: DrillKind
    /// Extra practice sets inside an otherwise-free room: same mechanics, more
    /// original questions, locked behind Mahj+. Nothing that was free became
    /// paid; these are additions.
    let isPlus: Bool

    init(id: String, title: String, subtitle: String, kind: DrillKind, isPlus: Bool = false) {
        self.id = id
        self.title = ContentText.localized(title)
        self.subtitle = ContentText.localized(subtitle)
        self.kind = kind
        self.isPlus = isPlus
    }
}

struct Room: Identifiable, Sendable {
    let id: String
    let name: String
    let tagline: String
    let icon: String
    /// A free room still opens for everyone; individual `isPlus` drills inside
    /// it are the locked extras. A non-free room is locked whole.
    let isFree: Bool
    let drills: [Drill]

    init(id: String, name: String, tagline: String, icon: String, isFree: Bool, drills: [Drill]) {
        self.id = id
        self.name = ContentText.localized(name)
        self.tagline = ContentText.localized(tagline)
        self.icon = icon
        self.isFree = isFree
        self.drills = drills
    }

    /// Drills a member unlocks here: the whole room if it's paid, otherwise
    /// just the extra sets.
    var plusDrillCount: Int {
        isFree ? drills.filter(\.isPlus).count : drills.count
    }

    func isLocked(_ drill: Drill, isMember: Bool) -> Bool {
        guard !isMember else { return false }
        return !isFree || drill.isPlus
    }
}
