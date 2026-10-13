import Foundation

struct MonthlyChallengeResult: Codable, Identifiable, Sendable {
    let monthKey: String
    let title: String
    let theme: MonthlyChallengeTheme
    let completedAt: Date
    let answers: [Bool]
    /// The choice index picked for each question, for the answer review.
    /// Optional because results saved before 1.4.0 shipped did not carry it.
    let picks: [Int]?
    /// What each answered question was, as `QuickItem.challengeFingerprint`.
    /// The questions are rebuilt from the content on every launch, so an
    /// update that changes a month must not quietly re-label old answers:
    /// the review is only offered while these still match. Nil for results
    /// saved before build 43, whose questions cannot be confirmed.
    var fingerprints: [String]? = nil

    var id: String { monthKey }
    var score: Int { answers.filter { $0 }.count }
    var total: Int { answers.count }

    /// True when `challenge` still holds exactly the questions this result
    /// answered, in the same order with the same choices.
    func matches(_ challenge: MonthlyChallenge) -> Bool {
        fingerprints == challenge.items.map(\.challengeFingerprint)
    }

    var shareText: String {
        let grid = stride(from: 0, to: answers.count, by: 6).map { start in
            answers[start..<min(start + 6, answers.count)].map { $0 ? "🟩" : "⬜️" }.joined()
        }.joined(separator: "\n")
        return "Mahj Trainer \(title) Challenge (\(theme.title)): \(score)/\(total)\n\(grid)\n🟩 = right. Everyone gets the same twelve questions this month. Try it free: \(AppStoreLinks.productURL.absoluteString)"
    }
}

/// A run that has started but not finished. Saved after every answer, so
/// leaving mid-run resumes at the same question instead of starting over.
struct MonthlyChallengeProgress: Codable, Sendable {
    var answers: [Bool]
    var picks: [Int]
    var fingerprints: [String]? = nil
}

extension QuickItem {
    /// Everything that decides what an answer meant: the question, its rack,
    /// the choices in their shown order and the answer. Plain text rather
    /// than a hash, because `Hasher` is reseeded on every launch.
    var challengeFingerprint: String {
        [id, prompt, tiles.map(\.shortLabel).joined(separator: " "), choices.joined(separator: "/"), String(answerIndex)]
            .joined(separator: "|")
    }
}

/// The first finished run of a month is the score that counts, the way a
/// shared puzzle works: the questions are the same for everyone, so a replay
/// would only be a memory test. A started run is saved answer by answer, so
/// backing out and starting again cannot reset a bad start either.
@MainActor
final class MonthlyChallengeStore: ObservableObject {
    static let shared = MonthlyChallengeStore()

    @Published private(set) var results: [String: MonthlyChallengeResult]
    @Published private(set) var inProgress: [String: MonthlyChallengeProgress]

    private let defaults: UserDefaults
    private static let resultsKey = "monthlyChallenge.results"
    private static let progressKey = "monthlyChallenge.progress"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        results = Self.load(defaults, key: Self.resultsKey) ?? [:]
        inProgress = Self.load(defaults, key: Self.progressKey) ?? [:]
    }

    func result(for challenge: MonthlyChallenge) -> MonthlyChallengeResult? {
        results[challenge.monthKey]
    }

    func progress(for challenge: MonthlyChallenge) -> MonthlyChallengeProgress? {
        guard results[challenge.monthKey] == nil else { return nil }
        return inProgress[challenge.monthKey]
    }

    /// Saves one more answer. The last answer finishes the run, so a run
    /// killed between the final answer and the result screen still counts.
    @discardableResult
    func recordAnswer(challenge: MonthlyChallenge, correct: Bool, pick: Int, now: Date = Date()) -> MonthlyChallengeResult? {
        guard results[challenge.monthKey] == nil else { return results[challenge.monthKey] }
        var run = inProgress[challenge.monthKey] ?? MonthlyChallengeProgress(answers: [], picks: [], fingerprints: [])
        guard run.answers.count < challenge.items.count else { return finish(challenge, run, now: now) }
        // A run started before build 43 has no fingerprints for its earlier
        // answers; it stays nil, so its review is never offered.
        run.fingerprints?.append(challenge.items[run.answers.count].challengeFingerprint)
        run.answers.append(correct)
        run.picks.append(pick)
        if run.answers.count >= challenge.items.count { return finish(challenge, run, now: now) }
        inProgress[challenge.monthKey] = run
        save(inProgress, key: Self.progressKey)
        return nil
    }

    /// Finishes a run from whatever was saved. Idempotent.
    @discardableResult
    func record(challenge: MonthlyChallenge, answers: [Bool], picks: [Int]? = nil, now: Date = Date()) -> MonthlyChallengeResult {
        if let existing = results[challenge.monthKey] { return existing }
        let fingerprints = challenge.items.prefix(answers.count).map(\.challengeFingerprint)
        return finish(challenge, MonthlyChallengeProgress(answers: answers, picks: picks ?? [], fingerprints: fingerprints), now: now)
    }

    func resetAll() {
        results = [:]
        inProgress = [:]
        defaults.removeObject(forKey: Self.resultsKey)
        defaults.removeObject(forKey: Self.progressKey)
    }

    private func finish(_ challenge: MonthlyChallenge, _ run: MonthlyChallengeProgress, now: Date) -> MonthlyChallengeResult {
        let result = MonthlyChallengeResult(
            monthKey: challenge.monthKey,
            title: challenge.monthName,
            theme: challenge.theme,
            completedAt: now,
            answers: run.answers,
            picks: run.picks.count == run.answers.count ? run.picks : nil,
            fingerprints: run.fingerprints?.count == run.answers.count ? run.fingerprints : nil
        )
        results[challenge.monthKey] = result
        inProgress[challenge.monthKey] = nil
        save(results, key: Self.resultsKey)
        save(inProgress, key: Self.progressKey)
        return result
    }

    private static func load<T: Decodable>(_ defaults: UserDefaults, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
