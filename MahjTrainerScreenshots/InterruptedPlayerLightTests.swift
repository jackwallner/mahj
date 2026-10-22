import XCTest

/// Second pass of the interrupted-player audit. The first pass hung on a
/// full-tree `allElementsBoundByIndex` filter in Get Started, so these tests
/// resolve one lazy query at a time and tap by coordinate. Like the first
/// pass they attach evidence rather than assert on product behaviour.
@MainActor
final class InterruptedPlayerLightTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
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
        shot("gs_00_home")
        XCTAssertTrue(tapCard("Get Started"), "no Get Started card")
        shot("gs_01_q1")
        answerFirstChoice()
        shot("gs_02_q1_answered")
        let next = app.buttons["Next"]
        if next.waitForExistence(timeout: 4) { next.tap() }
        settle(1.5)
        shot("gs_03_q2")
        answerFirstChoice()
        shot("gs_04_q2_answered")
        background()
        shot("gs_05_after_background")
        relaunchKeepingDefaults()
        shot("gs_06_after_kill_home")
        if tapCard("Get Started") { shot("gs_07_after_kill_session") }
    }

    func testPlayAHandKillMidHand() {
        launch()
        guard tapCard("Play a") else { shot("ph_00_nocard"); return }
        shot("ph_01_sections")
        guard tapCard("2468 (Evens)") else { shot("ph_02_nosection"); return }
        shot("ph_02_section")
        guard tapCard("Play it out") else { shot("ph_03_noplay"); return }
        shot("ph_03_dealt")
        let tile = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'rack-tile-'")).firstMatch
        if tile.waitForExistence(timeout: 5) {
            tile.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle(2)
        }
        shot("ph_04_threw")
        background()
        shot("ph_05_after_background")
        relaunchKeepingDefaults()
        shot("ph_06_after_kill_home")
        if tapCard("Play a") { shot("ph_07_after_kill_play") }
    }

    func testFeedbackDraftSurvivesBackground() {
        launch()
        let gear = app.navigationBars.buttons.element(boundBy: 0)
        guard gear.waitForExistence(timeout: 6) else { shot("fb_00_nogear"); return }
        gear.tap()
        settle(1.5)
        shot("fb_01_settings")
        guard tapCard("Send Feedback") else { shot("fb_02_nofeedback"); return }
        shot("fb_02_sheet")
        let field = app.textViews.firstMatch
        if field.waitForExistence(timeout: 4) {
            field.tap()
            field.typeText("The tile images look small on my phone")
            settle(1)
            shot("fb_03_typed_keyboard")
        }
        background()
        shot("fb_04_after_background")
        relaunchKeepingDefaults()
        shot("fb_05_after_kill_home")
    }

    private func settle(_ s: TimeInterval) { Thread.sleep(forTimeInterval: s) }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = "shot_\(name)"
        a.lifetime = .keepAlways
        add(a)
    }
}
