import XCTest

@MainActor
final class ReleaseJourneyTests: XCTestCase {
    private let app = XCUIApplication(bundleIdentifier: "com.jackwallner.mahj")

    private func launch(onboarded: Bool = true, ax5: Bool = false, upgradeChurn: Bool = false) {
        app.launchArguments = [
            "-progress.hasOnboarded", onboarded ? "YES" : "NO",
            "-subscription.localProOverride", "NO",
            "-mahj.hasReadPrimer", "NO",
            "-reviewPrompt.outcome", "openedWriteReview",
            "-membership.pendingChurnMoment", upgradeChurn ? "trialLapsed" : "",
        ]
        if onboarded { app.launchArguments += ["-mahj.skillLevel", "some"] }
        if upgradeChurn {
            app.launchArguments += ["-whatsnew.lastSeenVersion", "1.3.2"]
        } else {
            app.launchArguments += ["-mahj.suppressWhatsNew"]
        }
        if ax5 {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
        Thread.sleep(forTimeInterval: 1)
    }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = name + "-tree"
        tree.lifetime = .keepAlways
        add(tree)
    }

    private func button(_ text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func tap(_ text: String) {
        let target = button(text)
        XCTAssertTrue(target.waitForExistence(timeout: 5), text)
        for _ in 0..<6 {
            if target.isHittable { break }
            app.swipeUp()
        }
        target.tap()
        Thread.sleep(forTimeInterval: 0.4)
    }

    private func answer() {
        let candidate = app.scrollViews.buttons.allElementsBoundByIndex.first {
            $0.isHittable && !$0.label.contains("Something wrong")
        }
        XCTAssertNotNil(candidate, app.debugDescription)
        candidate?.tap()
        XCTAssertTrue(button("Next").waitForExistence(timeout: 3) || button("Finish").exists)
    }

    func testChallengeInterruptAndFinishPersistence() {
        launch()
        capture("free-home")
        tap("CHALLENGE")
        tap("Start the Challenge")
        answer()
        capture("challenge-first-answer")
        app.terminate()
        app.launch()
        tap("CHALLENGE")
        XCTAssertTrue(button("Resume at Question 2").exists)
        capture("challenge-resume")
        tap("Resume at Question 2")
        for index in 2...12 {
            answer()
            if index < 12 { tap("Next") }
        }
        capture("challenge-final-answer-before-finish")
        app.terminate()
        app.launch()
        tap("CHALLENGE")
        XCTAssertTrue(button("See Your Results").exists)
        tap("See Your Results")
        capture("challenge-saved-results")
    }

    func testNewPlayerAX5FreeExit() {
        launch(onboarded: false, ax5: true)
        capture("new-player-introduction-ax5")
        for _ in 0..<3 { tap("Continue") }
        capture("new-player-skill-ax5")
        tap("Brand new")
        tap("Continue")
        capture("new-player-trial-ax5")
        tap("Get Started")
        capture("new-player-primer-ax5")
        tap("Skip for now")
        capture("new-player-home-ax5")
        XCTAssertTrue(app.navigationBars.buttons["Settings"].exists)
    }

    func testUpgradeWithPendingChurn() {
        launch(upgradeChurn: true)
        Thread.sleep(forTimeInterval: 2)
        capture("upgrade-simultaneous-prompts")
        if button("Done").exists { tap("Done") }
        Thread.sleep(forTimeInterval: 1)
        capture("upgrade-after-whats-new")
    }
}
