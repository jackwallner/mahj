import XCTest
@testable import MahjTrainer

@MainActor
final class ReminderCopyTests: XCTestCase {
    func testDailyBodyMentionsTheWeekOnlyWhenThereIsAGain() {
        XCTAssertFalse(AppSettings.dailyReminderBody(weeklyGain: 0).contains("locked in"))
        XCTAssertTrue(AppSettings.dailyReminderBody(weeklyGain: 1).contains("1 question "))
        XCTAssertTrue(AppSettings.dailyReminderBody(weeklyGain: 14).contains("14 questions"))
    }

    func testGameNightBodyMentionsTheWeekOnlyWhenThereIsAGain() {
        XCTAssertFalse(AppSettings.gameNightReminderBody(weeklyGain: 0).contains("locked in"))
        XCTAssertTrue(AppSettings.gameNightReminderBody(weeklyGain: 6).contains("6 questions locked in"))
    }
}
