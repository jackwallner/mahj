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
    /// the network's answer can end the reminder.
    func testAConfirmedLapseEndsTheGameNightReminder() {
        let settings = settingsWithGameNightOn()
        settings.endMemberReminders(lapseConfirmed: true)
        XCTAssertFalse(settings.gameNightReminderEnabled)
        XCTAssertFalse(UserDefaults(suiteName: suite)!.bool(forKey: "settings.gameNightReminderEnabled"))
    }

    func testAnUnconfirmedLapseKeepsTheReminder() {
        let settings = settingsWithGameNightOn()
        settings.endMemberReminders(lapseConfirmed: false)
        XCTAssertTrue(settings.gameNightReminderEnabled)
    }

    /// Notification removal makes a synchronous XPC call. A stalled system
    /// service must not block RevenueCat's main-actor update or the first tap.
    func testTrialReminderCancellationRunsOffTheUIThread() async {
        let removed = expectation(description: "legacy trial reminder removed")
        let expectedID = "mahj.trialEndReminder"
        AppSettings.cancelTrialEndReminder { identifiers in
            XCTAssertFalse(Thread.isMainThread, "notification service calls must not block the UI thread")
            XCTAssertEqual(identifiers, [expectedID])
            removed.fulfill()
        }
        await fulfillment(of: [removed], timeout: 5)
    }

    func testNotificationUpdatesKeepSubmissionOrder() async {
        let cancelled = expectation(description: "old requests cancelled")
        let scheduled = expectation(description: "replacement requests scheduled")
        NotificationRequests.perform { cancelled.fulfill() }
        NotificationRequests.perform { scheduled.fulfill() }
        await fulfillment(of: [cancelled, scheduled], timeout: 5, enforceOrder: true)
    }

    // MARK: - Which records confirm a lapse

    func testAFreshNonMemberRecordConfirmsTheLapse() {
        let now = Date()
        XCTAssertTrue(SubscriptionService.confirmsLapse(isMember: false, answeredAt: now.addingTimeInterval(-10), now: now))
    }

    /// RevenueCat judges a cached record against now once it is more than
    /// three days old, so a member who renewed while away reads as lapsed.
    /// That must not end their reminder.
    func testAnOldCachedNonMemberRecordConfirmsNothing() {
        let now = Date()
        XCTAssertFalse(SubscriptionService.confirmsLapse(isMember: false, answeredAt: now.addingTimeInterval(-4 * day), now: now))
    }

    func testAMemberRecordConfirmsNothing() {
        let now = Date()
        XCTAssertFalse(SubscriptionService.confirmsLapse(isMember: true, answeredAt: now, now: now))
    }
}
