import XCTest

/// Persona audit: a tired player is interrupted mid-task (home button, app
/// kill) and comes back later. Each test records what survives. Failures here
/// are findings, not regressions, so most checks attach evidence and log
/// rather than assert.
@MainActor
final class InterruptedPlayerTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
    }

    private func baseArgs(onboarded: Bool) -> [String] {
        var args = ["-mahj.suppressWhatsNew", "-subscription.localProOverride", "NO",
                    "-ChallengeMonth", "2026-11-05", "-reviewPrompt.launchCount", "0"]
        if onboarded {
            args += ["-progress.hasOnboarded", "YES", "-mahj.hasReadPrimer", "YES",
                     "-mahj.skillLevel", "some", "-progress.totalSessions", "1",
                     "-progress.sessionsAtOnboarding", "0"]
        }
        return args
    }

    private func launch(onboarded: Bool) {
        app.launchArguments = baseArgs(onboarded: onboarded)
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle(2)
    }

    /// Home button, a long wait, back to the app (no kill).
    private func backgroundAndReturn(_ name: String) {
        XCUIDevice.shared.press(.home)
        settle(4)
        app.activate()
        settle(2)
        shot("\(name)_after_background")
    }

    /// Kill and cold launch with the same defaults.
    private func killAndRelaunch(_ name: String, onboarded: Bool) {
        app.terminate()
        settle(1)
        launch(onboarded: onboarded)
        shot("\(name)_after_relaunch")
    }

    private func answerChoice() {
        let candidates = app.buttons.allElementsBoundByIndex.filter {
            $0.isHittable && $0.frame.minY > 250 && !["Close", "Next", "Finish"].contains($0.label)
        }
        XCTAssertFalse(candidates.isEmpty, "no answer choices found")
        candidates.first?.tap()
        settle(1)
    }

    // MARK: - Onboarding

    func testOnboardingInterrupted() {
        launch(onboarded: false)
        shot("onb_00_first")
        for step in 1...2 {
            app.buttons["Continue"].tap()
            settle(1)
            shot("onb_0\(step)_page")
        }
        backgroundAndReturn("onb")
        killAndRelaunch("onb", onboarded: false)
    }

    // MARK: - Get Started session

    func testGetStartedInterrupted() {
        launch(onboarded: true)
        shot("gs_00_home")
        let start = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Get Started")).firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 10), "no Get Started")
        start.tap()
        settle(2)
        shot("gs_01_q1")
        answerChoice()
        shot("gs_02_answered")
        if app.buttons["Next"].exists { app.buttons["Next"].tap() }
        settle(1)
        shot("gs_03_q2")
        answerChoice()
        shot("gs_04_q2_answered")
        backgroundAndReturn("gs")
        killAndRelaunch("gs", onboarded: true)
    }

    // MARK: - Mahj Minute (the one flow with resume)

    func testMahjMinuteInterrupted() {
        launch(onboarded: true)
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Mahj Minute")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "no Mahj Minute card")
        shot("mm_00_home")
        card.tap()
        settle(2)
        shot("mm_01_challenge")
        let play = app.buttons["Play Today's Mahj Minute"]
        XCTAssertTrue(play.waitForExistence(timeout: 5), "no play button")
        play.tap()
        settle(2)
        shot("mm_02_q1")
        answerChoice()
        shot("mm_03_answered")
        backgroundAndReturn("mm")
        killAndRelaunch("mm", onboarded: true)
        let card2 = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Mahj Minute")).firstMatch
        if card2.waitForExistence(timeout: 10) { card2.tap(); settle(2); shot("mm_04_challenge_again") }
    }

    private func settle(_ s: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(s))
    }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = "shot_\(name)"
        a.lifetime = .keepAlways
        add(a)
    }
}
