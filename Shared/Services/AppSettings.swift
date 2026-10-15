import SwiftUI
import UserNotifications

/// User-configurable app settings, persisted in UserDefaults.
/// Appearance defaults to the warm light theme regardless of the device style.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    enum Appearance: String, CaseIterable, Identifiable {
        case light, dark, system

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "Match Device"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }

    enum GameNightDay: Int, CaseIterable, Identifiable {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

        var id: Int { rawValue }

        var displayName: String {
            switch self {
            case .sunday: return "Sunday"
            case .monday: return "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
            }
        }
    }

    private enum Keys {
        static let appearance = "settings.appearance"
        static let haptics = "settings.haptics"
        static let sound = "settings.sound"
        static let reminderEnabled = "settings.reminderEnabled"
        static let reminderHour = "settings.reminderHour"
        static let reminderMinute = "settings.reminderMinute"
        static let gameNightReminderEnabled = "settings.gameNightReminderEnabled"
        static let gameNightDay = "settings.gameNightDay"
        static let gameNightHour = "settings.gameNightHour"
        static let gameNightMinute = "settings.gameNightMinute"
        /// 1.4.0 baked this count into the repeating reminders. Only read
        /// to find those installs and rewrite their reminders.
        static let legacyWeeklyGain = "settings.reminderWeeklyGain"
    }

    private static let reminderID = "mahj.dailyReminder"
    private static let gameNightReminderID = "mahj.gameNightReminder"
    private static let trialEndReminderID = "mahj.trialEndReminder"

    @Published var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.sound) }
    }

    @Published var reminderEnabled: Bool {
        didSet {
            defaults.set(reminderEnabled, forKey: Keys.reminderEnabled)
            if reminderEnabled {
                requestPermissionAndSchedule()
            } else {
                cancelReminder()
            }
        }
    }

    /// True when the player asked for a reminder but iOS notifications are off
    /// for the app. Without this the toggle just silently flips back, which
    /// looks like the app is broken.
    @Published var reminderPermissionDenied = false

    @Published var reminderTime: Date {
        didSet {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            defaults.set(parts.hour ?? 9, forKey: Keys.reminderHour)
            defaults.set(parts.minute ?? 0, forKey: Keys.reminderMinute)
            if reminderEnabled { scheduleReminder() }
        }
    }

    @Published var gameNightReminderEnabled: Bool {
        didSet {
            defaults.set(gameNightReminderEnabled, forKey: Keys.gameNightReminderEnabled)
            if gameNightReminderEnabled {
                requestPermissionAndScheduleGameNight()
            } else {
                cancelGameNightReminder()
            }
        }
    }

    @Published var gameNightDay: GameNightDay {
        didSet {
            defaults.set(gameNightDay.rawValue, forKey: Keys.gameNightDay)
            if gameNightReminderEnabled { scheduleGameNightReminder() }
        }
    }

    @Published var gameNightReminderTime: Date {
        didSet {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: gameNightReminderTime)
            defaults.set(parts.hour ?? 17, forKey: Keys.gameNightHour)
            defaults.set(parts.minute ?? 0, forKey: Keys.gameNightMinute)
            if gameNightReminderEnabled { scheduleGameNightReminder() }
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .light
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? true
        reminderEnabled = defaults.bool(forKey: Keys.reminderEnabled)
        let hour = defaults.object(forKey: Keys.reminderHour) as? Int ?? 9
        let minute = defaults.object(forKey: Keys.reminderMinute) as? Int ?? 0
        reminderTime = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
        gameNightReminderEnabled = defaults.bool(forKey: Keys.gameNightReminderEnabled)
        let savedDay = defaults.integer(forKey: Keys.gameNightDay)
        gameNightDay = GameNightDay(rawValue: savedDay) ?? .thursday
        let gameHour = defaults.object(forKey: Keys.gameNightHour) as? Int ?? 17
        let gameMinute = defaults.object(forKey: Keys.gameNightMinute) as? Int ?? 0
        gameNightReminderTime = Calendar.current.date(
            from: DateComponents(hour: gameHour, minute: gameMinute)
        ) ?? Date()
        replaceCountedReminders()
    }

    // MARK: - Reminder copy

    /// Generic on purpose. A repeating notification is static text, and 1.4.0
    /// baked "You locked in 14 questions this week" into it: true the day it
    /// was written, then repeated every day to exactly the player who had
    /// stopped opening the app. The weekly count lives on Home and Your
    /// Progress, where it is always current.
    static let dailyReminderBody = "Five minutes of practice keeps your Charleston calm and your rack reading sharp."
    static let gameNightReminderBody = "Five personalized minutes now can make the table feel calmer later."

    /// Rewrites the reminders a 1.4.0 install scheduled with a count in them.
    /// Runs once: the legacy key is the marker.
    private func replaceCountedReminders() {
        guard defaults.object(forKey: Keys.legacyWeeklyGain) != nil else { return }
        defaults.removeObject(forKey: Keys.legacyWeeklyGain)
        if reminderEnabled { scheduleReminder() }
        if gameNightReminderEnabled { scheduleGameNightReminder() }
    }

    // MARK: - Trial-end reminder

    /// One local notification two days before a free week ends. Offered right
    /// after a trial ACTUALLY starts, never scheduled silently: a reminder
    /// nobody asked for reads as a nag, and the same reminder they chose reads
    /// as honesty. Timed from the trial's real end (RevenueCat's expiration
    /// date), never from "now plus seven days". Needs notification
    /// permission; the caller handles a refusal.
    func scheduleTrialEndReminder(trialEndsAt end: Date, daysBefore: Int = 2, now: Date = Date()) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.trialEndReminderID])
        guard let fireAt = Self.trialReminderFireDate(trialEndsAt: end, daysBefore: daysBefore, now: now) else { return }
        let content = UNMutableNotificationContent()
        content.title = "Your \(Membership.name) trial ends in \(daysBefore) days"
        content.body = "Keep it and nothing changes. Not for you? Cancel in Settings > Apple Account > Subscriptions and you won't be charged."
        content.sound = .default
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        center.add(UNNotificationRequest(identifier: Self.trialEndReminderID, content: content, trigger: trigger))
    }

    /// 10am local, `daysBefore` days before the trial ends, or nil when that
    /// moment has already passed (a "two days left" note after that is false).
    static func trialReminderFireDate(trialEndsAt end: Date, daysBefore: Int = 2, now: Date = Date()) -> Date? {
        let calendar = Calendar.current
        guard let day = calendar.date(byAdding: .day, value: -daysBefore, to: end),
              let fireAt = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: day) else { return nil }
        // Never later than the true "two days before" moment.
        let latest = end.addingTimeInterval(-TimeInterval(daysBefore) * 86_400)
        let chosen = min(fireAt, latest)
        return chosen > now ? chosen : nil
    }

    /// The trial converted, ended, or will not renew: the reminder's promise
    /// no longer holds.
    static func cancelTrialEndReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [trialEndReminderID])
    }

    /// Asks for permission if needed, then schedules. `completion` reports
    /// whether the reminder is actually set.
    func requestTrialEndReminder(trialEndsAt end: Date, completion: @escaping @MainActor (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                // No "Notifications are off" alert here: the player just
                // answered the system prompt on the offer screen, and the
                // shared flag would otherwise fire on their first Settings visit.
                guard granted else {
                    completion(false)
                    return
                }
                self.scheduleTrialEndReminder(trialEndsAt: end)
                completion(true)
            }
        }
    }

    // MARK: - Daily reminder

    private func requestPermissionAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                if granted {
                    self.scheduleReminder()
                } else {
                    self.reminderEnabled = false
                    self.reminderPermissionDenied = true
                }
            }
        }
    }

    private func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderID])

        let content = UNMutableNotificationContent()
        content.title = "Time for a quick drill"
        content.body = Self.dailyReminderBody
        content.sound = .default

        var parts = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        parts.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        center.add(UNNotificationRequest(identifier: Self.reminderID, content: content, trigger: trigger))
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.reminderID])
    }

    // MARK: - Game night reminder

    private func requestPermissionAndScheduleGameNight() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                if granted {
                    self.scheduleGameNightReminder()
                } else {
                    self.gameNightReminderEnabled = false
                    self.reminderPermissionDenied = true
                }
            }
        }
    }

    private func scheduleGameNightReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.gameNightReminderID])

        let content = UNMutableNotificationContent()
        content.title = "Your game night prep is ready"
        content.body = Self.gameNightReminderBody
        content.sound = .default
        content.userInfo = [AppNotification.routeKey: AppNotification.gameNightPrepValue]

        let time = Calendar.current.dateComponents([.hour, .minute], from: gameNightReminderTime)
        var parts = DateComponents()
        parts.weekday = gameNightDay.rawValue
        parts.hour = time.hour
        parts.minute = time.minute
        parts.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        center.add(UNNotificationRequest(identifier: Self.gameNightReminderID, content: content, trigger: trigger))
    }

    func cancelGameNightReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.gameNightReminderID])
    }
}
