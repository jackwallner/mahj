import XCTest

/// Second pass of the interrupted-player audit. The first pass hung on a
/// full-tree `allElementsBoundByIndex` filter in Get Started, so these tests
/// resolve one lazy query at a time and tap by coordinate. Like the first
/// pass they attach evidence rather than assert on product behaviour, but
/// every navigation step asserts it reached the intended screen before its
/// screenshot is taken (run B once passed 3/3 while the captures showed the
/// Reference screen, because the gear was found by position).
@MainActor
final class InterruptedPlayerLightTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch() {
        app.launchArguments = ["-mahj.suppressWhatsNew", "-subscription.localProOverride", "NO",
                               "-ChallengeMonth", "2026-11-05", "-reviewPrompt.launchCount", "0",
                               "-progress.hasOnboarded", "YES", "-mahj.hasReadPrimer", "YES",
                               "-mahj.skillLevel", "some", "-progress.totalSessions", "1",
                               "-progress.sessionsAtOnboarding", "0",
                               "-handplay.lastFreeDay", "", "-handplay.inProgress", ""]
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle(2)
    }

    private func relaunchKeepingDefaults() {
        app.terminate()
        settle(1)
        // Launch arguments live in the argument domain and are not persisted,
        // so the onboarding flags must be repeated or the relaunch looks like
        // a first run. Hand play and quick-session keys are left alone, so
        // what the app persisted by itself is what the player sees.
        app.launchArguments = ["-mahj.suppressWhatsNew", "-subscription.localProOverride", "NO",
                               "-ChallengeMonth", "2026-11-05", "-reviewPrompt.launchCount", "0",
                               "-progress.hasOnboarded", "YES", "-mahj.hasReadPrimer", "YES",
                               "-mahj.skillLevel", "some", "-progress.totalSessions", "1",
                               "-progress.sessionsAtOnboarding", "0"]
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle(2)
    }

    /// Home is the lobby: the gear and the book are both present and no
    /// Settings or Reference title is showing.
    private func assertHome(_ context: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 20), "\(context): Home gear missing", file: file, line: line)
        XCTAssertTrue(app.buttons["Reference and glossary"].exists, "\(context): Home book button missing", file: file, line: line)
        XCTAssertFalse(app.navigationBars["Reference"].exists, "\(context): Reference is showing", file: file, line: line)
        XCTAssertFalse(app.navigationBars["Settings"].exists, "\(context): Settings is showing", file: file, line: line)
    }

    private func assertQuestionCounter(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let counter = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", text)).firstMatch
        XCTAssertTrue(counter.waitForExistence(timeout: 8), "question counter '\(text)' not showing", file: file, line: line)
    }

    private func note(_ name: String, _ text: String) {
        let a = XCTAttachment(string: text)
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func background() {
        XCUIDevice.shared.press(.home)
        settle(4)
        app.activate()
        settle(2)
    }

    private func tapCard(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for attempt in 0..<2 {
            let match = app.buttons.matching(predicate).firstMatch
            if match.waitForExistence(timeout: attempt == 0 ? 8 : 2) {
                match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                settle(1.5)
                return true
            }
            app.swipeUp()
            settle(0.8)
        }
        return false
    }

    /// First button inside a scroll view is the first answer row; the
    /// navigation bar buttons live outside it.
    private func answerFirstChoice() {
        let row = app.scrollViews.descendants(matching: .button).element(boundBy: 0)
        if row.waitForExistence(timeout: 6) {
            row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55)).tap()
        }
        settle(1.2)
    }

    func testGetStartedKillMidSession() {
        launch()
        assertHome("gs launch")
        shot("gs_00_home")
        XCTAssertTrue(tapCard("Get Started"), "no Get Started card")
        assertQuestionCounter("1 of 10")
        shot("gs_01_q1")
        answerFirstChoice()
        shot("gs_02_q1_answered")
        let next = app.buttons["Next"]
        XCTAssertTrue(next.waitForExistence(timeout: 4), "Next did not appear after answering")
        next.tap()
        settle(1.5)
        assertQuestionCounter("2 of 10")
        shot("gs_03_q2")
        answerFirstChoice()
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 4), "question 2 was not answered")
        shot("gs_04_q2_answered")
        background()
        assertQuestionCounter("2 of 10")
        XCTAssertTrue(app.buttons["Next"].exists, "answered state lost after background")
        shot("gs_05_after_background")
        relaunchKeepingDefaults()
        assertHome("gs after kill")
        shot("gs_06_after_kill_home")
        XCTAssertTrue(tapCard("Get Started"), "no Get Started card after kill")
        let first = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "1 of ")).firstMatch.waitForExistence(timeout: 8)
        let second = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "2 of ")).firstMatch.exists
        note("gs_after_kill_counter", "restarts at 1 of 10: \(first); resumes at 2 of 10: \(second)")
        XCTAssertTrue(first || second, "after kill, Get Started opened no question screen")
        shot("gs_07_after_kill_session")
    }

    func testPlayAHandKillMidHand() {
        launch()
        assertHome("ph launch")
        XCTAssertTrue(tapCard("Play a"), "no Play a Hand card")
        XCTAssertFalse(app.buttons["Settings"].exists, "Play a Hand did not push a screen")
        shot("ph_01_sections")
        XCTAssertTrue(tapCard("2468 (Evens)"), "no 2468 (Evens) section")
        shot("ph_02_section")
        XCTAssertTrue(tapCard("Play it out"), "no Play it out button")
        let rackTiles = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'rack-tile-'"))
        XCTAssertTrue(rackTiles.firstMatch.waitForExistence(timeout: 8), "no rack tiles after Play it out")
        shot("ph_03_dealt")
        let tilesBefore = rackTiles.count
        rackTiles.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        settle(2)
        note("ph_rack_tile_counts", "rack tile buttons before throw: \(tilesBefore), after: \(rackTiles.count)")
        shot("ph_04_threw")
        background()
        XCTAssertTrue(rackTiles.firstMatch.waitForExistence(timeout: 6), "rack gone after background")
        shot("ph_05_after_background")
        relaunchKeepingDefaults()
        assertHome("ph after kill")
        shot("ph_06_after_kill_home")
        XCTAssertTrue(tapCard("Play a"), "no Play a Hand card after kill")
        XCTAssertFalse(app.buttons["Settings"].exists, "Play a Hand did not push a screen after kill")
        note("ph_after_kill_rack", "rack tile buttons after kill and reopen: \(rackTiles.count), sections visible: \(app.buttons["2468 (Evens)"].exists)")
        shot("ph_07_after_kill_play")
    }

    func testFeedbackDraftSurvivesBackground() {
        launch()
        assertHome("fb launch")
        let gear = app.buttons["Settings"]
        gear.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 8), "Settings sheet did not open")
        settle(1)
        shot("fb_01_settings")
        XCTAssertTrue(tapCard("Send Feedback"), "no Send Feedback row in Settings")
        XCTAssertTrue(app.navigationBars["Help us improve"].waitForExistence(timeout: 8), "feedback sheet did not open")
        shot("fb_02_sheet")
        let draft = "The tile images look small on my phone"
        let field = app.textViews.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 4), "no feedback text field")
        field.tap()
        field.typeText(draft)
        settle(1)
        shot("fb_03_typed_keyboard")
        // Resign the field first: pressing Home with the keyboard up timed out
        // on the simulator's background assertion in run A. Nothing is sent.
        let caption = app.staticTexts["Goes straight to the developer, a real person. No account, no email needed."]
        caption.tap()
        if app.keyboards.count > 0 {
            caption.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.97)))
        }
        settle(1)
        note("fb_keyboard_before_home", "keyboards showing: \(app.keyboards.count)")
        background()
        XCTAssertTrue(app.navigationBars["Help us improve"].waitForExistence(timeout: 6), "feedback sheet gone after background")
        XCTAssertTrue((app.textViews.firstMatch.value as? String)?.contains(draft) == true, "draft text lost after background")
        shot("fb_04_after_background")
        relaunchKeepingDefaults()
        assertHome("fb after kill")
        shot("fb_05_after_kill_home")
        gear.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 8), "Settings sheet did not reopen")
        XCTAssertTrue(tapCard("Send Feedback"), "no Send Feedback row after kill")
        XCTAssertTrue(app.navigationBars["Help us improve"].waitForExistence(timeout: 8), "feedback sheet did not reopen")
        let restored = (app.textViews.firstMatch.value as? String)?.contains(draft) == true
        note("fb_draft_after_kill", "draft restored after kill: \(restored)")
        shot("fb_06_reopened_after_kill")
    }

    private func settle(_ s: TimeInterval) { Thread.sleep(forTimeInterval: s) }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = "shot_\(name)"
        a.lifetime = .keepAlways
        add(a)
    }
}
