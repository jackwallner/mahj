import XCTest
@testable import MahjTrainer

/// The game night reminder is a member surface. State machine audit SM-01
/// (2026-11-06): a membership that ended while the app was closed never
/// moved `isPro`, so the reminder kept firing weekly into a paywall.
@MainActor
final class MemberReminderTests: XCTestCase {
    private let suite = "MemberReminderTests"
    private let day: TimeInterval = 86_400

    private func settingsWithGameNightOn() -> AppSettings {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defaults.set(true, forKey: "settings.gameNightReminderEnabled")
        return AppSettings(defaults: defaults)
    }

    override func tearDown() {
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    /// Cold launch after a lapse: `isPro` was false from the start, so only
    /// the resolved record can end the reminder.
    func testAKnownNonMemberLosesTheGameNightReminder() {
        let settings = settingsWithGameNightOn()
        settings.endMemberReminders(membershipResolved: true, isMember: false)
        XCTAssertFalse(settings.gameNightReminderEnabled)
        XCTAssertFalse(UserDefaults(suiteName: suite)!.bool(forKey: "settings.gameNightReminderEnabled"))
    }

    func testAnUnknownMembershipKeepsTheReminder() {
        let settings = settingsWithGameNightOn()
        settings.endMemberReminders(membershipResolved: false, isMember: false)
        XCTAssertTrue(settings.gameNightReminderEnabled, "before the record loads, every member reads as free")
    }

    func testAMemberKeepsTheReminder() {
        let settings = settingsWithGameNightOn()
        settings.endMemberReminders(membershipResolved: true, isMember: true)
        XCTAssertTrue(settings.gameNightReminderEnabled)
    }

    // MARK: - A cached record past RevenueCat's three-day grace

    /// Fetched while the period was running, read four days later: the player
    /// may have renewed or left, so the record must not settle membership (it
    /// would end a renewed member's reminder and send their notification tap
    /// to the paywall).
    func testAStaleRecordOfARunningPeriodSettlesNothing() {
        let fetched = Date().addingTimeInterval(-5 * day)
        XCTAssertFalse(SubscriptionService.recordSettlesMembership(
            isActive: false, expirationDate: fetched.addingTimeInterval(day), requestDate: fetched))
    }

    func testARecordThatSawTheLapseSettlesIt() {
        let fetched = Date().addingTimeInterval(-5 * day)
        XCTAssertTrue(SubscriptionService.recordSettlesMembership(
            isActive: false, expirationDate: fetched.addingTimeInterval(-day), requestDate: fetched))
    }

    func testActiveAndNeverSubscribedRecordsSettleIt() {
        let now = Date()
        XCTAssertTrue(SubscriptionService.recordSettlesMembership(
            isActive: true, expirationDate: now.addingTimeInterval(day), requestDate: now))
        XCTAssertTrue(SubscriptionService.recordSettlesMembership(
            isActive: false, expirationDate: nil, requestDate: now))
    }
}
