import XCTest
@testable import MahjTrainer

/// The trial flow's copy is the 1.3.2 copy; only the button wording varies,
/// and only among the wordings compiled in (`TrialCTA`).
@MainActor
final class TrialCopyTests: XCTestCase {
    func testTermsAreTheShippedLines() {
        XCTAssertEqual(
            PaywallPricing.terms(amount: "$9.99/month", plan: .monthly),
            "7 days free, then $9.99/month. Auto-renews until canceled."
        )
        XCTAssertEqual(PaywallPricing.terms(amount: nil, plan: .yearly), "Includes 7 days free. Auto-renews until canceled.")
        XCTAssertEqual(PaywallPricing.terms(amount: "$49.99", plan: .lifetime), "$49.99 one-time. Not a subscription, nothing renews.")
    }

    func testControlIsTheShippedButton() {
        XCTAssertEqual(PaywallPlan.yearly.ctaTitle(), "Start 7-Day Free Trial")
        XCTAssertEqual(PaywallPlan.monthly.ctaTitle(), "Start 7-Day Free Trial")
        XCTAssertFalse(PaywallPlan.lifetime.ctaTitle().contains("Trial"))
        XCTAssertEqual(TrialCTA.sevenDay.title(.onboarding), "Start 7-day free trial")
    }

    /// No metadata, a typo, or a non-string all mean the control.
    func testOfferingMetadataPicksOnlyAKnownArm() {
        XCTAssertEqual(TrialCTA.from(metadata: nil), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: [:]), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "mine"]), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": 1]), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "my"]), .my)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "your"]), .your)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "seven_day"]), .sevenDay)
    }

    func testEveryArmNamesTheTrialOnBothSurfaces() {
        for arm in TrialCTA.allCases {
            for surface in [TrialCTA.Surface.onboarding, .paywall] {
                let title = arm.title(surface)
                XCTAssertTrue(title.localizedCaseInsensitiveContains("free trial"), title)
                XCTAssertLessThanOrEqual(title.count, 24, title)
            }
        }
    }

    /// With no metadata every remote knob is the 1.3.2 behavior.
    func testMissingMetadataIsTheShippedTrialPage() {
        XCTAssertEqual(RemoteConfig.value(TrialTitle.metadataKey, in: nil, default: TrialTitle.tryFree), .tryFree)
        XCTAssertEqual(TrialTitle.tryFree.text, "Try Mahj+ free")
        XCTAssertEqual(TrialBenefits.reassureFirst.lines.first, "Every beginner room is free, forever")
        XCTAssertEqual(RemoteConfig.value(OnboardingPlan.metadataKey, in: [:], default: OnboardingPlan.monthly).plan, .monthly)
        XCTAssertEqual(RemoteConfig.value(OnboardingPlan.metadataKey, in: ["onboarding_plan": "weekly"], default: OnboardingPlan.monthly), .monthly)
        XCTAssertEqual(RemoteConfig.value(OnboardingPlan.metadataKey, in: ["onboarding_plan": "yearly"], default: OnboardingPlan.monthly).plan, .yearly)
        XCTAssertEqual(RemoteConfig.value(TrialBenefits.metadataKey, in: ["trial_benefits": "paid_first"], default: TrialBenefits.reassureFirst), .paidFirst)
    }

    /// Switches are on unless RevenueCat says exactly "off".
    func testSwitchesDefaultOn() {
        // The keys set in RevenueCat; renaming one would silently disarm it.
        XCTAssertEqual(RemoteSwitch.allCases.map(\.rawValue), ["att_prompt", "rating_prompt", "monthly_challenge", "trial_offer"])
        for remoteSwitch in RemoteSwitch.allCases {
            XCTAssertTrue(RemoteConfig.isOn(remoteSwitch, in: nil))
            XCTAssertTrue(RemoteConfig.isOn(remoteSwitch, in: [remoteSwitch.rawValue: "on"]))
            XCTAssertTrue(RemoteConfig.isOn(remoteSwitch, in: [remoteSwitch.rawValue: false]))
            XCTAssertFalse(RemoteConfig.isOn(remoteSwitch, in: [remoteSwitch.rawValue: "off"]))
        }
    }

    /// Variant copy follows the content rules and fits the page like the control.
    func testTrialPageVariantsFit() {
        for benefits in TrialBenefits.allCases {
            XCTAssertEqual(benefits.lines.count, 5)
            for line in benefits.lines {
                XCTAssertFalse(line.contains("\u{2014}"), line)
                XCTAssertLessThanOrEqual(line.count, 54, line)
            }
        }
        for title in TrialTitle.allCases {
            XCTAssertFalse(title.text.contains("\u{2014}"))
            XCTAssertLessThanOrEqual(title.text.count, 26, title.text)
        }
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
