import XCTest

@MainActor
final class ReleaseUpgradeTests: XCTestCase {
    private let app = XCUIApplication(bundleIdentifier: "com.jackwallner.mahj")

    private func launch() {
        app.launchArguments = [
            "-progress.hasOnboarded", "YES",
            "-mahj.hasReadPrimer", "YES",
            "-mahj.skillLevel", "some",
            "-subscription.localProOverride", "NO",
            "-mahj.suppressWhatsNew",
            "-membership.pendingChurnMoment", "",
            "-reviewPrompt.outcome", "openedWriteReview",
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
    }

    private func button(_ label: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch
    }

    private func tap(_ label: String) {
        let target = button(label)
        XCTAssertTrue(target.waitForExistence(timeout: 5), label)
        for _ in 0..<5 {
            if target.isHittable { break }
            app.swipeUp()
        }
        target.tap()
        Thread.sleep(forTimeInterval: 0.4)
    }

    private func capture(_ name: String) {
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = name + "-tree"
        tree.lifetime = .keepAlways
        add(tree)
    }

    func testBuild45ChallengeScoreSurvivesBuild46Install() {
        launch()
        tap("CHALLENGE")
        XCTAssertTrue(button("See Your Results").exists)
        tap("See Your Results")
        capture("upgrade46-saved-challenge")
        if button("See What You Missed").exists {
            tap("See What You Missed")
            capture("upgrade46-answer-review")
        }
    }

    func testFreeQuickSessionAndReportComposer() {
        launch()
        tap("Get Started")
        for index in 1...10 {
            let candidate = app.scrollViews.buttons.allElementsBoundByIndex.first {
                $0.isHittable && !$0.label.contains("Something wrong")
            }
            XCTAssertNotNil(candidate, app.debugDescription)
            candidate?.tap()
            XCTAssertTrue(button("Next").waitForExistence(timeout: 3) || button("Finish").exists)
            if index == 1 {
                tap("Something wrong with this question?")
                capture("upgrade46-question-report")
                tap("Not now")
            }
            tap(index < 10 ? "Next" : "Finish")
        }
        capture("upgrade46-quick-complete")
        tap("Done")
        capture("upgrade46-home-after-quick-session")
    }
}
