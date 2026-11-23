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
        let recap = app.descendants(matching: .any).matching(identifier: "missed-question-rack-recap").firstMatch
        func readable() -> Bool {
            // Its first line under the bar, and its end above Next or, for a
            // note taller than the screen, scrolled on from the first line.
            // A missed rack question puts its recap above the note: then the
            // block scrolls on from the recap, the note right under it.
            let top = recap.exists ? recap.frame : note.frame
            return top.minY >= bar.frame.maxY - 1
                && note.frame.minY >= top.minY
                && (note.frame.maxY <= next.frame.minY
                    || (top.minY <= bar.frame.maxY + 100 && note.frame.minY <= top.maxY + 40))
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

    /// At AX5 a missed Hand Match rack's recap and the note's first line
    /// stay on screen after the scroll to the note (QA backlog Q081).
    func testMissedRackRemainsVisibleWithCoachingAtLargeText() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-progress.hasOnboarded", "YES",
            "-mahj.hasReadPrimer", "YES",
            "-mahj.suppressWhatsNew", "YES",
            "-subscription.localProOverride", "YES",
            "-reviewPrompt.launchCount", "0",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
            "-mahj.shot", "drill/hand-match",
        ]
        app.launch()

        let prompt = app.staticTexts["question-prompt"].firstMatch
        // An earlier run can leave the drill held: start it over.
        let startOver = app.buttons["Start over"].firstMatch
        if startOver.waitForExistence(timeout: 8) { startOver.tap() }
        XCTAssertTrue(prompt.waitForExistence(timeout: 20))
        let next = app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Next Rack", "Finish")).firstMatch

        for index in 0..<9 {
            let choice = app.buttons["choice-0"].firstMatch
            XCTAssertTrue(choice.waitForExistence(timeout: 10), "no choice on rack \(index + 1)")
            choice.tap()
            XCTAssertTrue(next.waitForExistence(timeout: 10), "rack \(index + 1) was not graded")

            let answer = choice.value as? String ?? ""
            if answer.contains("Your answer, wrong") {
                let recap = app.descendants(matching: .any)
                    .matching(identifier: "missed-question-rack-recap").firstMatch
                XCTAssertTrue(recap.waitForExistence(timeout: 10), "the missed rack is hidden after the coaching auto-scroll")
                let note = app.staticTexts["question-explanation"].firstMatch
                XCTAssertTrue(note.waitForExistence(timeout: 10))
                let bar = app.navigationBars.firstMatch
                let deadline = Date().addingTimeInterval(5)
                // The recap under the bar, the note right under the recap, and
                // either the whole note above Next or the block scrolled on
                // from its top (the recap) when it is taller than the screen.
                func readable() -> Bool {
                    recap.frame.minY >= bar.frame.maxY - 1
                        && recap.frame.maxY < next.frame.minY
                        && note.frame.minY >= recap.frame.maxY
                        && (note.frame.maxY <= next.frame.minY
                            || (recap.frame.minY <= bar.frame.maxY + 100 && note.frame.minY <= recap.frame.maxY + 40))
                }
                while Date() < deadline, !readable() {
                    RunLoop.current.run(until: Date().addingTimeInterval(0.25))
                }
                let shot = XCTAttachment(screenshot: app.screenshot())
                shot.name = "missed-rack-with-coaching"
                shot.lifetime = .keepAlways
                add(shot)
                XCTAssertTrue(readable(), "rack \(recap.frame), note \(note.frame), bar \(bar.frame), Next \(next.frame)")
                return
            }

            if index < 8 {
                next.tap()
                XCTAssertTrue(app.staticTexts["Rack \(index + 2) of 9"].waitForExistence(timeout: 10))
            }
        }
        XCTFail("The rack drill never produced a wrong answer")
    }
}
