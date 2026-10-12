import XCTest
@testable import MahjTrainer

@MainActor
final class ReviewPromptTrackerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ReviewPromptTracker.resetForTesting()
    }

    override func tearDown() {
        ReviewPromptTracker.resetForTesting()
        super.tearDown()
    }

    private func earnTheAsk() {
        ReviewPromptTracker.recordAppLaunch()
        ReviewPromptTracker.recordAppLaunch()
        for _ in 0..<ReviewPromptTracker.minimumPositiveMoments {
            ReviewPromptTracker.recordPositiveMoment()
        }
    }

    func testGateStaysShutUntilThePlayerHasDoneEnough() {
        ReviewPromptTracker.recordAppLaunch()
        ReviewPromptTracker.recordPositiveMoment()
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment())

        earnTheAsk()
        XCTAssertTrue(ReviewPromptTracker.shouldShowAfterPositiveMoment())
    }

    /// The sheet carries a drag indicator, so swiping it away is a first-class
    /// dismissal and it records nothing of its own. Marking the ask when it is
    /// PRESENTED is what stops the funnel re-asking after every single drill
    /// until a button finally gets tapped.
    func testAnAskThatIsPresentedSpendsTheAskEvenIfNoButtonIsTapped() {
        earnTheAsk()
        XCTAssertTrue(ReviewPromptTracker.shouldShowAfterPositiveMoment())

        // What DrillCompleteView now does at presentation time.
        ReviewPromptTracker.markShown()

        // The player swipes the sheet away. The next finished drill must not
        // put it straight back up.
        ReviewPromptTracker.recordPositiveMoment()
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment())
        ReviewPromptTracker.recordPositiveMoment()
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment())
    }

    func testNotNowHoldsTheGateShutForTheCooldown() {
        earnTheAsk()
        ReviewPromptTracker.markShown()

        let day = TimeInterval(86_400)
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: Date().addingTimeInterval(30 * day)))
        let afterCooldown = Date().addingTimeInterval(TimeInterval(ReviewPromptTracker.cooldownDays + 1) * day)
        XCTAssertTrue(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: afterCooldown))
    }

    /// "Maybe later" spends only Apple's silent prompt, so it must not cost us
    /// the full 120-day jail the way a flat "Not now" does.
    func testMaybeLaterUsesTheShortCooldown() {
        earnTheAsk()
        ReviewPromptTracker.markSoftDeferred()

        let day = TimeInterval(86_400)
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: Date().addingTimeInterval(10 * day)))
        let afterSoftCooldown = Date().addingTimeInterval(TimeInterval(ReviewPromptTracker.softDeferCooldownDays + 1) * day)
        XCTAssertTrue(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: afterSoftCooldown))
    }

    func testRatingOrFeedbackRetiresThePromptForGood() {
        earnTheAsk()
        ReviewPromptTracker.markOpenedWriteReview()

        let inTenYears = Date().addingTimeInterval(3650 * 86_400)
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: inTenYears))
        XCTAssertEqual(ReviewPromptTracker.outcome, .openedWriteReview)

        ReviewPromptTracker.resetForTesting()
        earnTheAsk()
        ReviewPromptTracker.markFeedbackSubmitted()
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: inTenYears))
        XCTAssertEqual(ReviewPromptTracker.outcome, .submittedFeedback)
    }

}

@MainActor
final class ReviewPromptTrackerEnjoyedTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ReviewPromptTracker.resetForTesting()
    }

    override func tearDown() {
        ReviewPromptTracker.resetForTesting()
        super.tearDown()
    }

    /// A "yes" fires Apple's prompt, which may show nothing. It must not
    /// retire the funnel, and it must come back on the short cooldown.
    func testEnjoyedIsASoftDeferralNotATerminalOutcome() {
        ReviewPromptTracker.recordAppLaunch()
        ReviewPromptTracker.recordAppLaunch()
        for _ in 0..<ReviewPromptTracker.minimumPositiveMoments {
            ReviewPromptTracker.recordPositiveMoment()
        }
        ReviewPromptTracker.markEnjoyed()
        XCTAssertNil(ReviewPromptTracker.outcome)
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment())
        let day = TimeInterval(86_400)
        let later = Date().addingTimeInterval(TimeInterval(ReviewPromptTracker.softDeferCooldownDays + 1) * day)
        XCTAssertTrue(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: later))
    }
}
