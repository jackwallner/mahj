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

    /// A hand that was started and not finished.
    ///
    /// The free hand is spent the moment play begins, which is right: a hand is
    /// a hand whether or not it is seen through. What is not right is spending
    /// it and getting nothing, and before this the whole hand lived in view
    /// state, so one stray back-swipe or a terminated app left a free player
    /// looking at `Back tomorrow` having played nothing. Saved at each turn
    /// boundary, the hand is still there when they come back.
    struct InProgressHand: Codable, Sendable {
        var rack: [Tile]
        var wall: [Tile]
        var wallIndex: Int
        var target: HandCategory
        var turn: Int
        var cleanDiscards: Int
        var drawn: Tile?
        /// Set only while a throw is on screen waiting for `Next turn`. It is
        /// what makes the graded half of a turn durable: without it the rack
        /// and the coaching came back from different moments. Optional so a
        /// hand saved by an older build still decodes.
        var grade: ThrowGrade?
    }

    /// One graded throw, in the store rather than in the view, because it has
    /// to survive termination alongside the rack it belongs to.
    struct ThrowGrade: Codable, Sendable, Equatable {
        var discard: Tile
        var wasBest: Bool
        var note: String
    }

    @Published private(set) var handsPlayed: Int
    @Published private(set) var bestStars: Int
    @Published private(set) var lastFreeHandDay: String
    @Published private(set) var inProgress: InProgressHand?

    private let defaults: UserDefaults

    private enum Keys {
        static let handsPlayed = "handplay.handsPlayed"
        static let bestStars = "handplay.bestStars"
        static let lastFreeDay = "handplay.lastFreeDay"
        static let inProgress = "handplay.inProgress"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        handsPlayed = defaults.integer(forKey: Keys.handsPlayed)
        bestStars = defaults.integer(forKey: Keys.bestStars)
        lastFreeHandDay = defaults.string(forKey: Keys.lastFreeDay) ?? ""
        if let data = defaults.data(forKey: Keys.inProgress) {
            inProgress = try? JSONDecoder().decode(InProgressHand.self, from: data)
        }
    }

    /// The calendar-day key, shared with Mahj Minute's format so both features
    /// roll over at the same moment on the same device.
    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        MahjMinuteContent.key(for: date, calendar: calendar)
    }

    /// A hand already paid for is always playable. Otherwise: members always,
    /// free players once a calendar day.
    func canPlay(isMember: Bool, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        inProgress != nil || isMember || lastFreeHandDay != Self.dayKey(for: now, calendar: calendar)
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

    /// Saves the whole turn, both halves of it: drawn-and-not-yet-thrown, and
    /// thrown-and-being-graded. The second half is why `grade` exists. Saving
    /// only the rack mid-throw WOULD resume into a state where the tile is
    /// gone but the turn has not advanced and the player spends two discards
    /// on one draw; saving the grade with it resumes onto the exact screen
    /// they left, coaching card and all.
    func saveInProgress(_ hand: InProgressHand) {
        inProgress = hand
        guard let data = try? JSONEncoder().encode(hand) else { return }
        defaults.set(data, forKey: Keys.inProgress)
    }

    func clearInProgress() {
        inProgress = nil
        defaults.removeObject(forKey: Keys.inProgress)
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
        clearInProgress()
        defaults.removeObject(forKey: Keys.handsPlayed)
        defaults.removeObject(forKey: Keys.bestStars)
        defaults.removeObject(forKey: Keys.lastFreeDay)
    }
}
