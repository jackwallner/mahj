import Foundation

/// When a result screen may raise the one-tap trial sheet on its own.
///
/// Jack (2026-10-19): a free player who said "not now" on the onboarding
/// trial page should meet the trial again at a good moment, one tap from
/// Apple's sheet, the way Vitals does it. Paced by app session on install
/// day and the day after, then by days, because trials are front-loaded:
/// RevenueCat puts 78 to 90 percent of trial starts on install day, Mahj had
/// 56 of 57 on the onboarding page, and a free player's chance of still being
/// around falls fast in week one. So in those two days a player can see it
/// once per visit, three times a day at most (after their second practice of
/// their own), and after that at most once in 3 days, then 7, then every 14
/// for as long as they play.
/// A tap on a Mahj+ card is the player asking, so it ignores this pacing;
/// `trial_offer: off` stops the automatic asks without a release.
enum TrialOfferPacer {
    /// Practices of their own before the first automatic ask.
    static let practicesBeforeFirstAsk = 2
    /// Install day and the next: once per app session.
    static let sessionPacedDays = 2
    /// Most asks in one of those days.
    static let sessionPacedDailyCap = 3
    /// After that, the wait since the last ask, by how many came before.
    static let dayGaps: [TimeInterval] = [3, 7, 14].map { $0 * 24 * 60 * 60 }
    /// Back after this long away counts as a new session.
    static let sessionBreak: TimeInterval = 30 * 60

    static let lastShownKey = "trialOffer.lastAutoShown"
    static let lastShownSessionKey = "trialOffer.lastAutoShownSession"
    static let dayPacedCountKey = "trialOffer.dayPacedCount"
    static let sessionKey = "trialOffer.session"
    static let leftAtKey = "trialOffer.leftAt"
    static let askDayKey = "trialOffer.askDay"
    static let askDayCountKey = "trialOffer.askDayCount"

    static func autoOfferDue(
        practicesSinceOnboarding: Int,
        installedAt: Date?,
        now: Date = Date(),
        calendar: Calendar = .current,
        defaults: UserDefaults = .standard
    ) -> Bool {
        guard practicesSinceOnboarding >= practicesBeforeFirstAsk else { return false }
        if isSessionPaced(installedAt: installedAt, now: now, calendar: calendar) {
            guard asksToday(now: now, calendar: calendar, defaults: defaults) < sessionPacedDailyCap else { return false }
            guard defaults.object(forKey: lastShownSessionKey) != nil else { return true }
            return defaults.integer(forKey: lastShownSessionKey) < defaults.integer(forKey: sessionKey)
        }
        guard let last = defaults.object(forKey: lastShownKey) as? Date else { return true }
        let gap = dayGaps[min(defaults.integer(forKey: dayPacedCountKey), dayGaps.count - 1)]
        return now.timeIntervalSince(last) >= gap
    }

    static func markAutoShown(
        installedAt: Date?,
        now: Date = Date(),
        calendar: Calendar = .current,
        defaults: UserDefaults = .standard
    ) {
        defaults.set(asksToday(now: now, calendar: calendar, defaults: defaults) + 1, forKey: askDayCountKey)
        defaults.set(calendar.startOfDay(for: now), forKey: askDayKey)
        defaults.set(now, forKey: lastShownKey)
        defaults.set(defaults.integer(forKey: sessionKey), forKey: lastShownSessionKey)
        if !isSessionPaced(installedAt: installedAt, now: now, calendar: calendar) {
            defaults.set(defaults.integer(forKey: dayPacedCountKey) + 1, forKey: dayPacedCountKey)
        }
    }

    static func asksToday(now: Date, calendar: Calendar = .current, defaults: UserDefaults = .standard) -> Int {
        guard let day = defaults.object(forKey: askDayKey) as? Date,
              calendar.isDate(day, inSameDayAs: now) else { return 0 }
        return defaults.integer(forKey: askDayCountKey)
    }

    /// Install day or the calendar day after it.
    static func isSessionPaced(installedAt: Date?, now: Date, calendar: Calendar = .current) -> Bool {
        let start = calendar.startOfDay(for: installedAt ?? now)
        let days = calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: now)).day ?? 0
        return days < sessionPacedDays
    }

    /// The app came to the foreground. A first launch, or a return after
    /// `sessionBreak` away, starts a new session. Safe to call twice for one
    /// return (launch and scene phase both report it).
    static func noteForeground(now: Date = Date(), defaults: UserDefaults = .standard) {
        let session = defaults.integer(forKey: sessionKey)
        guard let left = defaults.object(forKey: leftAtKey) as? Date else {
            if session == 0 { defaults.set(1, forKey: sessionKey) }
            return
        }
        defaults.removeObject(forKey: leftAtKey)
        if now.timeIntervalSince(left) >= sessionBreak { defaults.set(session + 1, forKey: sessionKey) }
    }

    static func noteBackground(now: Date = Date(), defaults: UserDefaults = .standard) {
        defaults.set(now, forKey: leftAtKey)
    }

    /// True right after an automatic ask, so the rating prompt does not land
    /// on the same result: one ask per moment.
    static func autoShownRecently(within seconds: TimeInterval = 120, now: Date = Date(),
                                  defaults: UserDefaults = .standard) -> Bool {
        guard let last = defaults.object(forKey: lastShownKey) as? Date else { return false }
        return now.timeIntervalSince(last) < seconds
    }
}
