import Foundation

/// Play a Hand's local state: how many hands have been played, the best
/// verdict so far, and the one free hand a day.
///
/// The free hand is deliberate. Play a Hand is the strongest thing Mahj+ owns,
/// and a feature nobody has tried does not sell anything. One hand a day is a
/// real, complete use of the mode rather than a teaser that stops halfway, and
/// a player who wants a second one that day is exactly the player the
/// membership is for.
@MainActor
final class HandPlayStore: ObservableObject {
    static let shared = HandPlayStore()

    @Published private(set) var handsPlayed: Int
    @Published private(set) var bestStars: Int
    @Published private(set) var lastFreeHandDay: String

    private let defaults: UserDefaults

    private enum Keys {
        static let handsPlayed = "handplay.handsPlayed"
        static let bestStars = "handplay.bestStars"
        static let lastFreeDay = "handplay.lastFreeDay"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        handsPlayed = defaults.integer(forKey: Keys.handsPlayed)
        bestStars = defaults.integer(forKey: Keys.bestStars)
        lastFreeHandDay = defaults.string(forKey: Keys.lastFreeDay) ?? ""
    }

    /// The calendar-day key, shared with Mahj Minute's format so both features
    /// roll over at the same moment on the same device.
    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        MahjMinuteContent.key(for: date, calendar: calendar)
    }

    func canPlay(isMember: Bool, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        isMember || lastFreeHandDay != Self.dayKey(for: now, calendar: calendar)
    }

    /// Called when a hand actually starts, not when the screen opens. Backing
    /// out of the deal without playing must not spend the free hand.
    func recordStart(isMember: Bool, now: Date = Date(), calendar: Calendar = .current) {
        handsPlayed += 1
        defaults.set(handsPlayed, forKey: Keys.handsPlayed)
        guard !isMember else { return }
        lastFreeHandDay = Self.dayKey(for: now, calendar: calendar)
        defaults.set(lastFreeHandDay, forKey: Keys.lastFreeDay)
    }

    func recordVerdict(stars: Int) {
        guard stars > bestStars else { return }
        bestStars = stars
        defaults.set(stars, forKey: Keys.bestStars)
    }

    func resetAll() {
        handsPlayed = 0
        bestStars = 0
        lastFreeHandDay = ""
        defaults.removeObject(forKey: Keys.handsPlayed)
        defaults.removeObject(forKey: Keys.bestStars)
        defaults.removeObject(forKey: Keys.lastFreeDay)
    }
}
