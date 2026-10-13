import XCTest
@testable import MahjTrainer

/// The free week is only ever promised to an Apple Account that gets it.
@MainActor
final class TrialCopyTests: XCTestCase {
    func testTermsNameTheFreeWeekOnlyWhenEligible() {
        XCTAssertEqual(
            PaywallPricing.terms(amount: "$9.99/month", plan: .monthly, freeTrial: true),
            "7 days free, then $9.99/month. Auto-renews until canceled."
        )
        let plain = PaywallPricing.terms(amount: "$9.99/month", plan: .monthly, freeTrial: false)
        XCTAssertEqual(plain, "$9.99/month. Auto-renews until canceled.")
        XCTAssertFalse(plain.localizedCaseInsensitiveContains("free"))
        XCTAssertFalse(PaywallPricing.terms(amount: nil, plan: .yearly, freeTrial: false).localizedCaseInsensitiveContains("free"))
        XCTAssertTrue(PaywallPricing.terms(amount: "$49.99", plan: .lifetime, freeTrial: true).contains("one-time"))
    }

    func testCTANamesTheTrialOnlyWhenEligible() {
        XCTAssertEqual(PaywallPlan.monthly.ctaTitle(freeTrial: true), "Start 7-Day Free Trial")
        XCTAssertEqual(PaywallPlan.yearly.ctaTitle(freeTrial: false), "Subscribe")
        XCTAssertFalse(PaywallPlan.lifetime.ctaTitle(freeTrial: true).contains("Trial"))
    }

    /// Unknown eligibility (no RevenueCat, as on every simulator run) is not
    /// "eligible": plain pricing until Apple answers.
    func testOnlyAppleSaysEligibleOffersATrial() {
        XCTAssertTrue(SubscriptionService.offersFreeTrial(.monthly, eligibility: .eligible))
        XCTAssertFalse(SubscriptionService.offersFreeTrial(.monthly, eligibility: nil))
        XCTAssertFalse(SubscriptionService.offersFreeTrial(.monthly, eligibility: .unknown))
        XCTAssertFalse(SubscriptionService.offersFreeTrial(.yearly, eligibility: .ineligible))
        XCTAssertFalse(SubscriptionService.offersFreeTrial(.yearly, eligibility: .noIntroOfferExists))
        XCTAssertFalse(SubscriptionService.offersFreeTrial(.lifetime, eligibility: .eligible))
    }

    func testTrialReminderIsTimedFromTheRealEnd() throws {
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 15))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 15))!
        let fire = try XCTUnwrap(AppSettings.trialReminderFireDate(trialEndsAt: end, now: now))
        XCTAssertEqual(calendar.dateComponents([.month, .day, .hour], from: fire), DateComponents(month: 10, day: 17, hour: 10))

        // Never later than two full days before the end.
        let earlyEnd = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 8))!
        let earlyFire = try XCTUnwrap(AppSettings.trialReminderFireDate(trialEndsAt: earlyEnd, now: now))
        XCTAssertLessThanOrEqual(earlyFire, earlyEnd.addingTimeInterval(-2 * 86_400))

        // A trial with under two days left gets no "two days left" note.
        let soon = now.addingTimeInterval(36 * 3600)
        XCTAssertNil(AppSettings.trialReminderFireDate(trialEndsAt: soon, now: now))
    }
}
