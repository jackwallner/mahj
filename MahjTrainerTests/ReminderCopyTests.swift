import XCTest
@testable import MahjTrainer

@MainActor
final class ReminderCopyTests: XCTestCase {
    /// Repeating reminders are static text: any number in them goes stale
    /// for the player who stops opening the app.
    func testRepeatingReminderCopyQuotesNoCount() {
        for body in [AppSettings.dailyReminderBody, AppSettings.gameNightReminderBody] {
            XCTAssertFalse(body.contains("locked in"))
            XCTAssertNil(body.rangeOfCharacter(from: .decimalDigits), body)
        }
    }

    func testCountedRemindersAreReplacedOnce() {
        let defaults = UserDefaults(suiteName: "ReminderCopyTests")!
        defaults.removePersistentDomain(forName: "ReminderCopyTests")
        defaults.set(14, forKey: "settings.reminderWeeklyGain")
        _ = AppSettings(defaults: defaults)
        XCTAssertNil(defaults.object(forKey: "settings.reminderWeeklyGain"))
    }
}
