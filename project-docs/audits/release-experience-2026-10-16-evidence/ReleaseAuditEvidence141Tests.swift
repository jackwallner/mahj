import SwiftUI
import UIKit
import XCTest
@testable import MahjTrainer

@MainActor
final class ReleaseAuditEvidenceTests: XCTestCase {
    func testReunlockingPaidMasteryLooksLikeNewWeeklyLearning() {
        let suite = "ReleaseAuditEvidenceTests.mastery"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let records = PracticeRecordStore(defaults: defaults)
        let ledger = MasteryLedger(defaults: defaults)
        let earlier = Date().addingTimeInterval(-86400)
        records.record(itemID: "plus-tq-set-size", roomID: "tile-room", correct: true, now: earlier)
        records.record(itemID: "plus-tq-set-size", roomID: "tile-room", correct: true, now: earlier)
        ledger.record(records.masteryByRoom(isMember: false, now: earlier), now: earlier)
        let attemptsBefore = records.totalAttempts
        ledger.record(records.masteryByRoom(isMember: true), now: Date())
        XCTAssertEqual(records.totalAttempts, attemptsBefore)
        XCTAssertEqual(ledger.weeklyGain(), 1)
        let attachment = XCTAttachment(string: "An existing paid item was already known yesterday. Recording free membership yesterday and active membership today produces weeklyGain = 1 with zero additional answers. Re-exposing paid mastery is counted as new weekly learning.")
        attachment.name = "membership-weekly-gain-proof"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testOldNonGregorianMinuteResultIsHiddenAfterUpdate() {
        let suite = "ReleaseAuditEvidenceTests.calendar"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let now = Date()
        var oldCalendar = Calendar(identifier: .buddhist)
        oldCalendar.timeZone = .current
        let legacyKey = MahjMinuteContent.key(for: now, calendar: oldCalendar)
        let saved = MahjMinuteResult(dayKey: legacyKey, shortDate: "Oct 16", completedAt: now,
            answers: [true, true, false, true, true], correctByCategory: [:], totalByCategory: [:])
        defaults.set(try! JSONEncoder().encode([legacyKey: saved]), forKey: "mahjMinute.results")
        let store = MahjMinuteStore(defaults: defaults)
        XCTAssertEqual(store.results.count, 1)
        XCTAssertNil(store.result(for: now), "Old result is retained but no longer found by date")
        XCTAssertNotNil(store.result(for: now, calendar: oldCalendar))
        let attachment = XCTAttachment(string: "Legacy Buddhist key: \(legacyKey). Current lookup key: \(MahjMinuteContent.key(for: now)). Stored results: \(store.results.count). Current lookup: nil. Legacy-calendar lookup: found. The old app keyed by Calendar.current; the new app keys by gregorianLocal without migrating saved results.")
        attachment.name = "calendar-migration-proof"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testReminderNormalCapture() async throws {
        try await capture(size: .large, name: "trial-reminder-normal")
    }

    func testReminderAX5Capture() async throws {
        try await capture(size: .accessibilityExtraExtraExtraLarge, name: "trial-reminder-ax5")
    }

    func testHistoricalCacheDoesNotBecomeTheFirstBaseline() {
        let suite = "ReleaseAuditEvidenceTests.freshness"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = SubscriptionService.shared
        service.consumeChurnMoment()
        defer { service.consumeChurnMoment() }
        let old = MembershipSnapshot(isActive: true, isTrial: false, willRenew: true)
        service.observe(old, answeredAt: Date().addingTimeInterval(-86400), defaults: defaults)
        service.observe(.none, defaults: defaults)
        XCTAssertNil(service.pendingChurnMoment)
    }

    func testRenewingAgainLeavesCancellationQuestionPending() {
        let suite = "ReleaseAuditEvidenceTests.returned"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = SubscriptionService.shared
        service.consumeChurnMoment()
        defer { service.consumeChurnMoment() }
        let renewing = MembershipSnapshot(isActive: true, isTrial: true, willRenew: true)
        service.observe(renewing, defaults: defaults)
        service.observe(MembershipSnapshot(isActive: true, isTrial: true, willRenew: false), defaults: defaults)
        XCTAssertEqual(service.pendingChurnMoment, .trialRenewalOff)
        service.observe(renewing, defaults: defaults)
        XCTAssertEqual(service.pendingChurnMoment, .trialRenewalOff,
            "The service still holds the cancellation question after renewal is on again")
    }

    private func capture(size: ContentSizeCategory, name: String) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let controller = UIHostingController(rootView:
            TrialReminderOfferView(onAccept: {}, onDecline: {})
                .environment(\.sizeCategory, size)
                .preferredColorScheme(.light)
        )
        controller.traitOverrides.preferredContentSizeCategory = size == .large
            ? .large : .accessibilityExtraExtraExtraLarge
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds
        window.rootViewController = controller
        window.windowLevel = .normal + 1
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            previous?.makeKeyAndVisible()
        }
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(400))
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertGreaterThan(image.size.height, 0)
    }
}
