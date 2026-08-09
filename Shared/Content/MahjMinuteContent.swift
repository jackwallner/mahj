import Foundation

enum MahjMinuteCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case rackReading
    case charleston
    case tableJudgment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rackReading: return "Rack Reading"
        case .charleston: return "Charleston"
        case .tableJudgment: return "Table Judgment"
        }
    }

    var icon: String {
        switch self {
        case .rackReading: return "square.grid.3x3.fill"
        case .charleston: return "arrow.triangle.2.circlepath"
        case .tableJudgment: return "hand.point.up.left.fill"
        }
    }
}

struct MahjMinuteQuestion: Sendable {
    let category: MahjMinuteCategory
    let item: QuickItem
}

struct MahjMinuteChallenge: Identifiable, Sendable {
    let day: Date
    let dayKey: String
    let shortDate: String
    let questions: [MahjMinuteQuestion]

    var id: String { dayKey }
    var items: [QuickItem] { questions.map(\.item) }
}

/// One shared five-question set per calendar date. Its racks are generated
/// from original section structures, while the Charleston and table calls are
/// selected from the app's authored teaching content.
enum MahjMinuteContent {
    static let questionCount = 5

    static let drill = Drill(
        id: "mahj-minute",
        title: "Mahj Minute",
        subtitle: "Today's shared five-question challenge",
        kind: .quiz([]),
        isPlus: true
    )

    static func challenge(for day: Date = Date(), calendar: Calendar = .current) -> MahjMinuteChallenge {
        let dayKey = key(for: day, calendar: calendar)
        let racks = rackQuestions(dayKey: dayKey)
        let charleston = charlestonQuestion(dayKey: dayKey)
        let table = tableQuestions(dayKey: dayKey)
        let questions = [racks[0], charleston, table[0], racks[1], table[1]]

        let parts = calendar.dateComponents([.month, .day], from: day)
        let shortDate = String(format: "%02d/%02d", parts.month ?? 1, parts.day ?? 1)
        return MahjMinuteChallenge(day: day, dayKey: dayKey, shortDate: shortDate, questions: questions)
    }

    static func key(for day: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return String(
            format: "%04d-%02d-%02d",
            parts.year ?? 1970,
            parts.month ?? 1,
            parts.day ?? 1
        )
    }

    private static func rackQuestions(dayKey: String) -> [MahjMinuteQuestion] {
        let racks = RackGenerator.batch(count: 2, seed: "mahj-minute-\(dayKey)-racks")
        return racks.enumerated().map { index, rack in
            let labels = rack.choices.map(\.displayName)
            let answerIndex = rack.choices.firstIndex(of: rack.answer) ?? 0
            let item = QuickItem(
                id: PracticeSkill.rackReading.itemPrefix + "minute-\(dayKey)-\(index)",
                prompt: "Which section is this rack chasing?",
                tiles: rack.tiles,
                choices: labels,
                answerIndex: answerIndex,
                explanation: rack.explanation,
                sourceLabel: "Mahj Minute: Rack Read",
                roomID: PracticeSkill.rackReading.roomID,
                trackingID: PracticeSkill.rackReading.rawValue,
                isReviewable: false
            )
            return MahjMinuteQuestion(category: .rackReading, item: SessionBuilder.prepared(item))
        }
    }

    private static func charlestonQuestion(dayKey: String) -> MahjMinuteQuestion {
        let scenarios = DrillLibrary.rooms.flatMap { room in
            room.drills.flatMap { drill -> [CharlestonScenario] in
                if case .charleston(let values) = drill.kind { return values }
                return []
            }
        }
        var generator = StableSeededGenerator(seed: "mahj-minute-\(dayKey)-charleston")
        let scenario = scenarios[Int(generator.next() % UInt64(scenarios.count))]
        let answer = passLabel(scenario.recommendedPass)
        let distractors = distractorPassLabels(for: scenario, seed: dayKey)
        let item = QuickItem(
            id: "mahj-minute-charleston-\(dayKey)",
            prompt: "\(scenario.situation) Which three tiles make the strongest pass?",
            tiles: scenario.deal.racked,
            choices: [answer] + distractors,
            answerIndex: 0,
            explanation: scenario.reasoning,
            sourceLabel: "Mahj Minute: Charleston",
            roomID: "charleston-room",
            trackingID: "mahj-minute-charleston",
            isReviewable: false
        )
        return MahjMinuteQuestion(category: .charleston, item: SessionBuilder.prepared(item))
    }

    private static func tableQuestions(dayKey: String) -> [MahjMinuteQuestion] {
        let pool = SessionBuilder.choiceItems(in: "table-room", includePro: true)
        let indices = ChoiceShuffle.permutation(count: pool.count, seed: "mahj-minute-\(dayKey)-table")
        return indices.prefix(2).map { index in
            MahjMinuteQuestion(category: .tableJudgment, item: SessionBuilder.prepared(pool[index]))
        }
    }

    private static func distractorPassLabels(for scenario: CharlestonScenario, seed: String) -> [String] {
        let passable = scenario.deal.enumerated().filter { _, tile in tile != .joker }
        var labels: Set<String> = []
        for first in 0..<(passable.count - 2) {
            for second in (first + 1)..<(passable.count - 1) {
                for third in (second + 1)..<passable.count {
                    labels.insert(passLabel([
                        passable[first].element,
                        passable[second].element,
                        passable[third].element,
                    ]))
                }
            }
        }
        labels.remove(passLabel(scenario.recommendedPass))
        let sorted = labels.sorted()
        let order = ChoiceShuffle.permutation(count: sorted.count, seed: "mahj-minute-\(seed)-passes")
        return order.prefix(3).map { sorted[$0] }
    }

    private static func passLabel(_ tiles: [Tile]) -> String {
        tiles.racked.map(\.spokenName).joined(separator: ", ")
    }
}
