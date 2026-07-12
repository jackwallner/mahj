import Foundation

@MainActor
final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    @Published private(set) var streakCount: Int
    @Published private(set) var totalSessions: Int
    @Published private(set) var completions: [String: Int]

    private let defaults: UserDefaults

    private enum Keys {
        static let streakCount = "progress.streakCount"
        static let lastActiveDay = "progress.lastActiveDay"
        static let totalSessions = "progress.totalSessions"
        static let completions = "progress.completions"
        static let hasOnboarded = "progress.hasOnboarded"
        static let reviewGateShown = "progress.reviewGateShown"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        streakCount = defaults.integer(forKey: Keys.streakCount)
        totalSessions = defaults.integer(forKey: Keys.totalSessions)
        completions = (defaults.dictionary(forKey: Keys.completions) as? [String: Int]) ?? [:]
    }

    var hasOnboarded: Bool {
        get { defaults.bool(forKey: Keys.hasOnboarded) }
        set { defaults.set(newValue, forKey: Keys.hasOnboarded) }
    }

    func completions(for drillID: String) -> Int {
        completions[drillID] ?? 0
    }

    func roomProgress(_ room: Room) -> Double {
        guard !room.drills.isEmpty else { return 0 }
        let done = room.drills.filter { completions(for: $0.id) > 0 }.count
        return Double(done) / Double(room.drills.count)
    }

    func recordSession(drillID: String, now: Date = Date()) {
        completions[drillID, default: 0] += 1
        totalSessions += 1
        bumpStreak(now: now)
        defaults.set(completions, forKey: Keys.completions)
        defaults.set(totalSessions, forKey: Keys.totalSessions)
    }

    /// Streak counts consecutive calendar days with at least one finished drill.
    private func bumpStreak(now: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let last = defaults.object(forKey: Keys.lastActiveDay) as? Date

        if let last {
            let lastDay = calendar.startOfDay(for: last)
            let gap = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if gap == 1 {
                streakCount += 1
            } else if gap > 1 {
                streakCount = 1
            } // gap == 0: same day, streak unchanged
        } else {
            streakCount = 1
        }
        defaults.set(today, forKey: Keys.lastActiveDay)
        defaults.set(streakCount, forKey: Keys.streakCount)
    }

    /// Review funnel: fire the enjoyment gate once, after the third finished session.
    func shouldShowEnjoymentGate() -> Bool {
        guard totalSessions >= 3, !defaults.bool(forKey: Keys.reviewGateShown) else { return false }
        defaults.set(true, forKey: Keys.reviewGateShown)
        return true
    }
}
