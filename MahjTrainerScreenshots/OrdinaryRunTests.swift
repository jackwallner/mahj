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
        app.launchArguments = arguments + ["-practice.ordinaryRun", "", "-practice.ordinaryRuns", ""]
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

    /// At AX3 the graded coaching note scrolls up above Next, from its first
    /// line. It stayed behind Next in the 1.4.2 release gate's AX3 shots.
    func testCoachingNoteScrollsAboveNextAtAX3() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-progress.hasOnboarded", "YES", "-mahj.hasReadPrimer", "YES",
            "-mahj.suppressWhatsNew", "YES", "-practice.ordinaryRun", "", "-practice.ordinaryRuns", "", "-progress.lastQuickSessionDay", "",
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
        let deadline = Date().addingTimeInterval(5)
        let bar = app.navigationBars.firstMatch
        // A miss on a tall question puts a small copy of its rack above the
        // note (1.4.6); the note then starts right under that instead.
        let recap = app.descendants(matching: .any)["missed-question-rack-recap"].firstMatch
        func readable() -> Bool {
            // Its first line under the bar, and its end above Next or, for a
            // note taller than the screen, scrolled on from the first line.
            let top = recap.exists ? recap.frame.maxY : bar.frame.maxY
            return note.frame.minY >= bar.frame.maxY - 1
                && (note.frame.maxY <= next.frame.minY || note.frame.minY <= top + 100)
        }
        while Date() < deadline, !readable() {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "ax3-coaching-note"
        shot.lifetime = .keepAlways
        add(shot)
        XCTAssertTrue(readable(), "note \(note.frame), bar \(bar.frame), Next \(next.frame)")
    }

    /// At AX5 a missed Hand Match question opens its graded block from the
    /// top: the small rack recap and the coaching note's first line sit
    /// under the bar. The iOS 18 bottom anchor used to hold the block's end
    /// instead, leaving the recap at y=-1246 (release gate, 2026-11-22).
    func testMissedRackRemainsVisibleWithCoachingAtLargeText() {
        continueAfterFailure = false
        let app = XCUIApplication()
        var recap: XCUIElement!
        // The shuffle is fixed per question, so one of the first two choices
        // is a miss.
        for pick in 0..<2 {
            app.launchArguments = [
                "-progress.hasOnboarded", "YES", "-mahj.hasReadPrimer", "YES",
                "-mahj.suppressWhatsNew", "YES", "-reviewPrompt.launchCount", "0",
                "-practice.ordinaryRun", "", "-practice.ordinaryRuns", "",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
                "-mahj.shot", "drill/hand-match",
            ]
            app.launch()
            let choice = app.buttons["choice-\(pick)"].firstMatch
            XCTAssertTrue(choice.waitForExistence(timeout: 20))
            choice.tap()
            XCTAssertTrue(nextRack(app).waitForExistence(timeout: 10))
            recap = app.descendants(matching: .any)["missed-question-rack-recap"].firstMatch
            if recap.waitForExistence(timeout: 3) { break }
            app.terminate()
        }
        XCTAssertTrue(recap.exists, "neither of the first two choices was a miss")
        let note = app.staticTexts["question-explanation"].firstMatch
        let next = nextRack(app)
        let bar = app.navigationBars.firstMatch
        func readable() -> Bool {
            recap.frame.minY >= bar.frame.maxY - 1 && recap.frame.maxY <= next.frame.minY
                && note.frame.minY >= bar.frame.maxY - 1 && note.frame.minY < next.frame.minY - 20
        }
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline, !readable() {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "ax5-missed-rack-recap"
        shot.lifetime = .keepAlways
        add(shot)
        XCTAssertTrue(readable(), "recap \(recap.frame), note \(note.frame), bar \(bar.frame), Next \(next.frame)")
    }

    private func nextRack(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Next")).firstMatch
    }
}
