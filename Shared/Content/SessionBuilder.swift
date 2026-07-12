import Foundation

/// One item inside a Get Started mixed session.
enum MixedItem: Identifiable, Sendable {
    case flashcard(Flashcard)
    case quiz(QuizQuestion)
    case handMatch(HandMatchQuestion)

    var id: String {
        switch self {
        case .flashcard(let card): return card.id
        case .quiz(let question): return question.id
        case .handMatch(let question): return question.id
        }
    }
}

/// Builds the Get Started session: a short mix of flashcards and questions
/// pulled from the whole library, weighted so misses come back first and
/// unseen material beats review.
enum SessionBuilder {

    static let sessionDrill = Drill(
        id: "daily-mix",
        title: "Quick Session",
        subtitle: "A short mix of what you need next",
        kind: .flashcards([])
    )

    static func dailyMix(
        count: Int = 10,
        seen: Set<String>,
        missed: Set<String>,
        includePro: Bool
    ) -> [MixedItem] {
        var pool: [MixedItem] = []
        for room in DrillLibrary.rooms where room.isFree || includePro {
            for drill in room.drills {
                switch drill.kind {
                case .flashcards(let cards):
                    pool += cards.map { .flashcard($0) }
                case .quiz(let questions):
                    pool += questions.map { .quiz($0) }
                case .handMatch(let questions):
                    pool += questions.map { .handMatch($0) }
                case .charleston:
                    break // Too interaction-heavy for a quick mix.
                }
            }
        }

        // Priority tiers: missed first, unseen next, review last.
        func tier(_ item: MixedItem) -> Int {
            if missed.contains(item.id) { return 0 }
            if !seen.contains(item.id) { return 1 }
            return 2
        }
        let picked = Dictionary(grouping: pool.shuffled(), by: tier)
            .sorted { $0.key < $1.key }
            .flatMap(\.value)
            .prefix(count)

        return interleaved(Array(picked))
    }

    /// Alternate cards and questions where possible so the session has rhythm.
    private static func interleaved(_ items: [MixedItem]) -> [MixedItem] {
        var cards: [MixedItem] = []
        var questions: [MixedItem] = []
        for item in items {
            if case .flashcard = item { cards.append(item) } else { questions.append(item) }
        }
        var result: [MixedItem] = []
        while !cards.isEmpty || !questions.isEmpty {
            if let card = cards.first { result.append(card); cards.removeFirst() }
            if let question = questions.first { result.append(question); questions.removeFirst() }
        }
        return result
    }
}
