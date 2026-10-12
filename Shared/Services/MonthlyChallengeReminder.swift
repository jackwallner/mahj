import Foundation
import UserNotifications

/// "Tell me when the next one opens": one local notification on the morning
/// of the 1st for each of the next three months. Only ever set by the player
/// tapping the button, never silently, and re-laid on every launch so the
/// three always run ahead of today.
@MainActor
enum MonthlyChallengeReminder {
    private static let enabledKey = "monthlyChallenge.reminder"
    private static let idPrefix = "mahj.monthlyChallenge."
    private static let monthsAhead = 3

    static var isOn: Bool { UserDefaults.standard.bool(forKey: enabledKey) }

    /// Asks for permission if needed, then schedules. `completion` reports
    /// whether the reminder is actually set.
    static func enable(completion: @escaping @MainActor (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                UserDefaults.standard.set(granted, forKey: enabledKey)
                if granted { schedule() }
                completion(granted)
            }
        }
    }

    static func disable() {
        UserDefaults.standard.set(false, forKey: enabledKey)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers())
    }

    /// Called on launch: keeps the next three months scheduled while on.
    static func refresh() {
        guard isOn else { return }
        schedule()
    }

    private static func schedule(now: Date = Date(), calendar: Calendar = .current) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers())
        var challenge = MonthlyChallengeContent.challenge(for: now, calendar: calendar)
        for _ in 0..<monthsAhead {
            challenge = MonthlyChallengeContent.next(after: challenge, calendar: calendar)
            var parts = calendar.dateComponents([.year, .month, .day], from: challenge.start)
            parts.hour = 10
            parts.minute = 0
            let content = UNMutableNotificationContent()
            content.title = "The \(challenge.monthName) Challenge is here"
            content.body = "\(challenge.theme.title): \(challenge.theme.blurb) Twelve questions, free."
            content.sound = .default
            content.userInfo = [AppNotification.routeKey: AppNotification.monthlyChallengeValue]
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            center.add(UNNotificationRequest(identifier: idPrefix + challenge.monthKey, content: content, trigger: trigger))
        }
    }

    /// Every id this could have scheduled around now, so a disable clears them.
    private static func identifiers(now: Date = Date(), calendar: Calendar = .current) -> [String] {
        (-1...monthsAhead + 1).compactMap { offset -> String? in
            guard let date = calendar.date(byAdding: .month, value: offset, to: now) else { return nil }
            let parts = calendar.dateComponents([.year, .month], from: date)
            return idPrefix + MonthlyChallengeContent.key(year: parts.year ?? 0, month: parts.month ?? 0)
        }
    }
}
