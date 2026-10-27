import Foundation

/// The local calendar day as a token views can watch. Home and the challenge
/// screen read "today" when they draw, and nothing redrew them at midnight
/// or on a resume the next morning, so Nov 1 kept showing Oct 31. The app
/// calls `refresh()` on iOS's significant time change and whenever the scene
/// becomes active.
@MainActor
final class DayClock: ObservableObject {
    static let shared = DayClock()

    @Published private(set) var dayKey: String

    init(now: Date = MonthlyChallengeContent.today, calendar: Calendar = .gregorianLocal) {
        dayKey = Self.key(for: now, calendar: calendar)
    }

    /// Publishes only when the day changed, so a resume within the same day
    /// redraws nothing. The calendar is read fresh: a time zone change moves
    /// the day too.
    @discardableResult
    func refresh(now: Date = MonthlyChallengeContent.today, calendar: Calendar = .gregorianLocal) -> Bool {
        let key = Self.key(for: now, calendar: calendar)
        guard key != dayKey else { return false }
        dayKey = key
        return true
    }

    /// "YYYY-MM-DD", the same shape as a challenge round key.
    nonisolated static func key(for date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let month = MonthlyChallengeContent.key(year: parts.year ?? 0, month: parts.month ?? 0)
        return MonthlyChallengeContent.roundKey(monthKey: month, day: parts.day ?? 0)
    }
}
