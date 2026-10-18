import Foundation

/// Sends a month score and reads back where it sits among every player's.
///
/// Anonymous by construction: the row is an app name, the month, a random
/// token that changes every month (`MonthlyChallengeStore.scoreToken`), the
/// points and the days played. No account, device id or anything else. The
/// server keeps the best score per token and answers with how many players
/// there are and how many are below, which is all a percentage needs.
@MainActor
enum ChallengeStandingService {
    private static let url = URL(string: "https://ucoveqbyfuxqvpysmixu.supabase.co/rest/v1/rpc/challenge_submit")!

    /// After a finished round, and when the challenge screen opens with a
    /// score older than an hour. Failures are silent: the standing is a
    /// nicety, and the last one shown stays until a newer one arrives.
    static func refresh(monthKey: String, store: MonthlyChallengeStore = .shared, force: Bool = false) async {
        let score = store.monthScore(monthKey)
        guard score.daysPlayed > 0 else { return }
        #if DEBUG
        if let pinned = debugStanding(points: score.points) {
            store.setStanding(pinned, for: monthKey)
            return
        }
        #endif
        // A simulator or test run must not put scores into the real spread.
        guard !isSimulator else { return }
        if !force, let known = store.standing(for: monthKey), known.points == score.points,
           let fetched = lastFetch[monthKey], Date().timeIntervalSince(fetched) < 3600 {
            return
        }
        let body: [String: Any] = [
            "p_app": FeedbackService.appID,
            "p_month": monthKey,
            "p_player": store.scoreToken(for: monthKey),
            "p_points": score.points,
            "p_days": score.daysPlayed,
        ]
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(FeedbackEndpoint.production.apiKey, forHTTPHeaderField: "apikey")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let reply = try? JSONDecoder().decode(Reply.self, from: data)
        else { return }
        lastFetch[monthKey] = Date()
        store.setStanding(ChallengeStanding(players: reply.players, below: reply.below, points: score.points), for: monthKey)
    }

    private struct Reply: Decodable {
        let players: Int
        let below: Int
    }

    private static var lastFetch: [String: Date] = [:]

    private static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    #if DEBUG
    /// Captures only: `-mahj.standing 240,190` pins 240 players, 190 below.
    private static func debugStanding(points: Int) -> ChallengeStanding? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-mahj.standing"), index + 1 < arguments.count else { return nil }
        let parts = arguments[index + 1].split(separator: ",").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return ChallengeStanding(players: parts[0], below: parts[1], points: points)
    }
    #endif
}
