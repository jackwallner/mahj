import Foundation

/// One finished daily round.
struct MonthlyChallengeResult: Codable, Identifiable, Sendable {
    let roundKey: String
    let monthKey: String
    let day: Int
    /// "November 5"
    let title: String
    /// "November"
    let monthName: String
    let theme: MonthlyChallengeTheme
    let completedAt: Date
    let answers: [Bool]
    /// The choice index picked for each question, for the answer review.
    let picks: [Int]?
    /// What each answered question was, as `QuickItem.challengeFingerprint`.
    /// The questions are rebuilt from the content on every launch, so an
    /// update that changes a day must not quietly re-label old answers: the
    /// review is only offered while these still match.
    var fingerprints: [String]?

    var id: String { roundKey }
    var score: Int { answers.filter { $0 }.count }
    var total: Int { answers.count }

    /// True when `round` still holds exactly the questions this result
    /// answered, in the same order with the same choices.
    func matches(_ round: ChallengeRound) -> Bool {
        fingerprints == round.items.prefix(answers.count).map(\.challengeFingerprint)
    }
}

/// A round that has started but not finished. Saved after every answer, so
/// leaving mid-round resumes at the same question instead of starting over.
struct MonthlyChallengeProgress: Codable, Sendable {
    var answers: [Bool]
    var picks: [Int]
    var fingerprints: [String]?
}

/// A month so far: the best `countedDays` rounds added up.
struct MonthScore: Equatable, Sendable {
    let points: Int
    let daysPlayed: Int

    static let empty = MonthScore(points: 0, daysPlayed: 0)
}

/// Where a month score sits among every player's, from the server.
struct ChallengeStanding: Codable, Equatable, Sendable {
    let players: Int
    /// Players with fewer points.
    let below: Int
    let points: Int

    /// The server pads every month with baseline scores (27 or more, from
    /// the first day), so this only guards an empty or broken reply.
    static let minimumPlayers = 10

    /// "Top 20%", only in the top half: a bottom-half number is discouraging
    /// and tells a new player nothing they can act on.
    var topPercent: Int? {
        guard players >= Self.minimumPlayers else { return nil }
        let ahead = Double(below) / Double(players)
        guard ahead >= 0.5 else { return nil }
        return max(1, Int((1 - ahead) * 100 + 0.5))
    }
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

/// The first finished run of a day is the score that counts, the way a
/// shared puzzle works: the questions are the same for everyone, so a replay
/// would only be a memory test. A started round is saved answer by answer,
/// so backing out and starting again cannot reset a bad start either.
@MainActor
final class MonthlyChallengeStore: ObservableObject {
    static let shared = MonthlyChallengeStore()

    @Published private(set) var results: [String: MonthlyChallengeResult]
    @Published private(set) var inProgress: [String: MonthlyChallengeProgress]
    @Published private(set) var standings: [String: ChallengeStanding]

    private let defaults: UserDefaults
    private static let resultsKey = "monthlyChallenge.rounds"
    private static let progressKey = "monthlyChallenge.roundProgress"
    private static let standingsKey = "monthlyChallenge.standings"
    private static let tokensKey = "monthlyChallenge.tokens"
    /// The one-run-a-month format of pre-release builds. Only TestFlight
    /// installs ever wrote these.
    private static let legacyKeys = ["monthlyChallenge.results", "monthlyChallenge.progress"]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        Self.legacyKeys.forEach(defaults.removeObject(forKey:))
        results = Self.load(defaults, key: Self.resultsKey) ?? [:]
        inProgress = Self.load(defaults, key: Self.progressKey) ?? [:]
        standings = Self.load(defaults, key: Self.standingsKey) ?? [:]
    }

    func result(for round: ChallengeRound) -> MonthlyChallengeResult? {
        results[round.key]
    }

    func progress(for round: ChallengeRound) -> MonthlyChallengeProgress? {
        guard results[round.key] == nil else { return nil }
        return inProgress[round.key]
    }

    /// A month's finished rounds, first day first.
    func results(inMonth monthKey: String) -> [MonthlyChallengeResult] {
        results.values.filter { $0.monthKey == monthKey }.sorted { $0.day < $1.day }
    }

    func monthScore(_ monthKey: String) -> MonthScore {
        let rounds = results(inMonth: monthKey)
        let best = rounds.map(\.score).sorted(by: >).prefix(MonthlyChallengeContent.countedDays)
        return MonthScore(points: best.reduce(0, +), daysPlayed: rounds.count)
    }

    func standing(for monthKey: String) -> ChallengeStanding? {
        standings[monthKey]
    }

    func setStanding(_ standing: ChallengeStanding, for monthKey: String) {
        standings[monthKey] = standing
        save(standings, key: Self.standingsKey)
    }

    /// A random id for this install's score in one month. A fresh one each
    /// month, so nothing ties one month's score to the next.
    func scoreToken(for monthKey: String) -> String {
        var tokens: [String: String] = Self.load(defaults, key: Self.tokensKey) ?? [:]
        if let token = tokens[monthKey] { return token }
        let token = UUID().uuidString
        tokens = tokens.filter { $0.key >= monthKey }
        tokens[monthKey] = token
        save(tokens, key: Self.tokensKey)
        return token
    }

    /// Saves one more answer. The last answer finishes the round, so a round
    /// killed between the final answer and the result screen still counts.
    @discardableResult
    func recordAnswer(round: ChallengeRound, correct: Bool, pick: Int, now: Date = Date()) -> MonthlyChallengeResult? {
        guard results[round.key] == nil else { return results[round.key] }
        var run = inProgress[round.key] ?? MonthlyChallengeProgress(answers: [], picks: [], fingerprints: [])
        guard run.answers.count < round.items.count else { return finish(round, run, now: now) }
        run.fingerprints?.append(round.items[run.answers.count].challengeFingerprint)
        run.answers.append(correct)
        run.picks.append(pick)
        if run.answers.count >= round.items.count { return finish(round, run, now: now) }
        inProgress[round.key] = run
        save(inProgress, key: Self.progressKey)
        return nil
    }

    /// Finishes a round from whatever was saved. Idempotent.
    @discardableResult
    func record(round: ChallengeRound, answers: [Bool], picks: [Int]? = nil, now: Date = Date()) -> MonthlyChallengeResult {
        if let existing = results[round.key] { return existing }
        let fingerprints = round.items.prefix(answers.count).map(\.challengeFingerprint)
        return finish(round, MonthlyChallengeProgress(answers: answers, picks: picks ?? [], fingerprints: fingerprints), now: now)
    }

    /// A round left half done when its day ended keeps the answers it has.
    /// The day is over, so it cannot be finished, and dropping it would throw
    /// away points the player earned.
    func closeEarlierRounds(than current: ChallengeRound?, now: Date = Date()) {
        let stale = inProgress.keys.filter { $0 != current?.key }
        guard !stale.isEmpty else { return }
        for key in stale {
            guard let run = inProgress[key], !run.answers.isEmpty,
                  let round = MonthlyChallengeContent.round(key: key) else {
                inProgress[key] = nil
                continue
            }
            finish(round, run, now: now)
        }
        save(inProgress, key: Self.progressKey)
    }

    func resetAll() {
        results = [:]
        inProgress = [:]
        standings = [:]
        [Self.resultsKey, Self.progressKey, Self.standingsKey, Self.tokensKey].forEach(defaults.removeObject(forKey:))
    }

    @discardableResult
    private func finish(_ round: ChallengeRound, _ run: MonthlyChallengeProgress, now: Date) -> MonthlyChallengeResult {
        let result = MonthlyChallengeResult(
            roundKey: round.key,
            monthKey: round.monthKey,
            day: round.day,
            title: round.title,
            monthName: round.month.monthName,
            theme: round.month.theme,
            completedAt: now,
            answers: run.answers,
            picks: run.picks.count == run.answers.count ? run.picks : nil,
            fingerprints: run.fingerprints?.count == run.answers.count ? run.fingerprints : nil
        )
        results[round.key] = result
        inProgress[round.key] = nil
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
