import XCTest

@MainActor
final class OrdinaryRunTests: XCTestCase {
    func testQuickSessionResumesHeldAnswerAfterRelaunchFromGetStarted() {
        continueAfterFailure = false
        let app = XCUIApplication()
        let arguments = [
            "-progress.hasOnboarded", "YES", "-mahj.hasReadPrimer", "YES",
            "-mahj.suppressWhatsNew", "-subscription.localProOverride", "YES",
            "-progress.lastQuickSessionDay", "", "-reviewPrompt.launchCount", "0"
        ]
        app.launchArguments = arguments + ["-practice.ordinaryRun", ""]
        app.launch()
        let getStarted = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Get Started")).firstMatch
        XCTAssertTrue(getStarted.waitForExistence(timeout: 15))
        getStarted.tap()
        let choice = app.buttons["choice-0"].firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 10))
        choice.tap()
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 10))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["2 of 10"].waitForExistence(timeout: 10))
        app.buttons["choice-0"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 10))
        let prompt = app.staticTexts["question-prompt"].firstMatch.label
        app.terminate()

        app.launchArguments = arguments
        app.launch()
        // The Get Started card itself resumes, straight into the run.
        let resumeCard = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Resume Quick Session")).firstMatch
        XCTAssertTrue(resumeCard.waitForExistence(timeout: 15))
        XCTAssertFalse(getStarted.exists)
        resumeCard.tap()
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["question-prompt"].firstMatch.label, prompt)
        XCTAssertTrue((app.buttons["choice-0"].firstMatch.value as? String)?.contains("Your answer") == true)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "resumed-held-answer"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["3 of 10"].waitForExistence(timeout: 10))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(resumeCard.waitForExistence(timeout: 10))
        resumeCard.tap()
        XCTAssertTrue(app.staticTexts["3 of 10"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["choice-0"].firstMatch.isEnabled)
    }

    /// At AX3 the graded coaching note scrolls up above Next. It stayed
    /// behind Next in the 1.4.2 release gate's AX3 screenshots.
    func testCoachingNoteScrollsAboveNextAtAX3() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-progress.hasOnboarded", "YES", "-mahj.hasReadPrimer", "YES",
            "-mahj.suppressWhatsNew", "YES", "-practice.ordinaryRun", "", "-progress.lastQuickSessionDay", "",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ]
        app.launch()
        let getStarted = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Get Started")).firstMatch
        XCTAssertTrue(getStarted.waitForExistence(timeout: 15))
        getStarted.tap()
        let choice = app.buttons["choice-0"].firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 10))
        choice.tap()
        let next = app.buttons["Next"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        let note = app.staticTexts["question-explanation"].firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 10))
        let above = expectation(for: NSPredicate { _, _ in
            note.frame.maxY <= next.frame.minY && note.frame.minY > 0
        }, evaluatedWith: nil)
        wait(for: [above], timeout: 5)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "ax3-coaching-note"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
