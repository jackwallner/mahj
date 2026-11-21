import XCTest
@testable import MahjTrainer

/// B12: a stored last-shown date from a clock that ran ahead.
extension LowBugRegressionTests {
    // MARK: B12 a clock that ran ahead once

    func testReviewAskIsNotBlockedByAStampFromAClockThatRanAhead() {
        ReviewPromptTracker.resetForTesting()
        defer { ReviewPromptTracker.resetForTesting() }
        ReviewPromptTracker.recordAppLaunch()
        ReviewPromptTracker.recordAppLaunch()
        let now = Date()
        ReviewPromptTracker.markShown(now: now.addingTimeInterval(400 * 86_400))
        XCTAssertTrue(ReviewPromptTracker.shouldRequestReview(now: now))
        // The cooldown still runs from a stamp that is not in the future.
        ReviewPromptTracker.markShown(now: now)
        XCTAssertFalse(ReviewPromptTracker.shouldRequestReview(now: now.addingTimeInterval(86_400)))
    }

    func testTrialOfferIsNotBlockedByAStampFromAClockThatRanAhead() {
        let defaults = freshDefaults("LowBugTrialFuture")
        let now = Date()
        let installed = now.addingTimeInterval(-60 * 86_400)
        defaults.set(now.addingTimeInterval(31 * 86_400), forKey: TrialOfferPacer.lastShownKey)
        XCTAssertTrue(TrialOfferPacer.autoOfferDue(practicesSinceOnboarding: 5, installedAt: installed, now: now, defaults: defaults))
        XCTAssertFalse(TrialOfferPacer.autoShownRecently(now: now, defaults: defaults))
        // A stamp in the past still holds the gap.
        defaults.set(now.addingTimeInterval(-86_400), forKey: TrialOfferPacer.lastShownKey)
        XCTAssertFalse(TrialOfferPacer.autoOfferDue(practicesSinceOnboarding: 5, installedAt: installed, now: now, defaults: defaults))
    }
}
