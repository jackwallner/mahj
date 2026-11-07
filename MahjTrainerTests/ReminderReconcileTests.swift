import UserNotifications
import XCTest
@testable import MahjTrainer

/// A reminder toggle that reads ON must be one iOS will deliver. State
/// machine audit SM-02 (2026-11-06): the toggles never looked at the
/// permission or the scheduled requests after they were set.
@MainActor
final class ReminderReconcileTests: XCTestCase {
    private let suite = "ReminderReconcileTests"

    private func settings(daily: Bool, gameNight: Bool) -> AppSettings {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defaults.set(daily, forKey: "settings.reminderEnabled")
        defaults.set(gameNight, forKey: "settings.gameNightReminderEnabled")
        return AppSettings(defaults: defaults)
    }

    override func tearDown() {
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    /// Settings > Mahj Trainer > Notifications switched off in iOS Settings.
    func testNotificationsSwitchedOffReadOff() {
        let settings = settings(daily: true, gameNight: true)
        settings.reconcileReminders(status: .denied, pendingIDs: ["mahj.dailyReminder", "mahj.gameNightReminder"])
        XCTAssertFalse(settings.reminderEnabled)
        XCTAssertFalse(settings.gameNightReminderEnabled)
        XCTAssertFalse(UserDefaults(suiteName: suite)!.bool(forKey: "settings.reminderEnabled"))
    }

    /// A restore to a new phone: the settings came across, the permission did not.
    func testNeverAllowedOnThisPhoneReadsOff() {
        let settings = settings(daily: true, gameNight: false)
        settings.reconcileReminders(status: .notDetermined, pendingIDs: [])
        XCTAssertFalse(settings.reminderEnabled)
    }

    func testAllowedAndScheduledStaysOn() {
        let settings = settings(daily: true, gameNight: true)
        settings.reconcileReminders(status: .authorized, pendingIDs: ["mahj.dailyReminder", "mahj.gameNightReminder"])
        XCTAssertTrue(settings.reminderEnabled)
        XCTAssertTrue(settings.gameNightReminderEnabled)
    }

    func testTogglesThatAreOffStayOff() {
        let settings = settings(daily: false, gameNight: false)
        settings.reconcileReminders(status: .authorized, pendingIDs: [])
        XCTAssertFalse(settings.reminderEnabled)
        XCTAssertFalse(settings.gameNightReminderEnabled)
    }

    /// The review's check, against the real notification center: ON in the
    /// stored settings with no request behind it must end either scheduled
    /// or reading OFF.
    func testRestoredOnFlagWithNoPendingRequestIsReconciled() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["mahj.dailyReminder"])
        let settings = settings(daily: true, gameNight: false)
        await settings.reconcileReminders()
        let pending = await AppSettings.pendingRequestIDs()
        XCTAssertTrue(!settings.reminderEnabled || pending.contains("mahj.dailyReminder"),
                      "Toggle reads ON but no daily reminder request exists")
        center.removePendingNotificationRequests(withIdentifiers: ["mahj.dailyReminder"])
    }
}
