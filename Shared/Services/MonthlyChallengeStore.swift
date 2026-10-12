import Foundation

struct MonthlyChallengeResult: Codable, Identifiable, Sendable {
    let monthKey: String
    let title: String
    let theme: MonthlyChallengeTheme
    let completedAt: Date
    let answers: [Bool]

    var id: String { monthKey }
    var score: Int { answers.filter { $0 }.count }
    var total: Int { answers.count }

    var shareText: String {
        let grid = answers.map { $0 ? "🟩" : "⬜️" }.joined()
        return "Mahj Trainer \(title) Challenge: \(score)/\(total)\n\(grid)\nSame questions for every player. Can you beat me? \(AppStoreLinks.productURL.absoluteString)"
    }
}

/// The first finished run of a month is the score that counts, the way a
/// shared puzzle works: the questions are the same for everyone, so a replay
/// would only be a memory test.
@MainActor
final class MonthlyChallengeStore: ObservableObject {
    static let shared = MonthlyChallengeStore()

    @Published private(set) var results: [String: MonthlyChallengeResult]

    private let defaults: UserDefaults
    private static let resultsKey = "monthlyChallenge.results"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.resultsKey),
           let decoded = try? JSONDecoder().decode([String: MonthlyChallengeResult].self, from: data) {
            results = decoded
        } else {
            results = [:]
        }
    }

    func result(for challenge: MonthlyChallenge) -> MonthlyChallengeResult? {
        results[challenge.monthKey]
    }

    @discardableResult
    func record(challenge: MonthlyChallenge, answers: [Bool], now: Date = Date()) -> MonthlyChallengeResult {
        if let existing = results[challenge.monthKey] { return existing }
        let result = MonthlyChallengeResult(
            monthKey: challenge.monthKey,
            title: challenge.monthName,
            theme: challenge.theme,
            completedAt: now,
            answers: answers
        )
        results[challenge.monthKey] = result
        persist()
        return result
    }

    func resetAll() {
        results = [:]
        defaults.removeObject(forKey: Self.resultsKey)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(results) else { return }
        defaults.set(data, forKey: Self.resultsKey)
    }
}
