import XCTest

/// Quitting in the tour after the trial decision must not send the player back
/// to the first intro page.
@MainActor
final class OnboardingResumeTests: XCTestCase {
    private let base = [
        "-subscription.localProOverride", "NO",
        "-reviewPrompt.launchCount", "0", "-mahj.suppressWhatsNew",
    ]

    func testRelaunchInTheTourResumesTheTour() {
        continueAfterFailure = false
        let app = XCUIApplication()
        // Start clean whatever an earlier test left behind: the override is
        // dropped on the relaunch below, which then reads what the app saved.
        app.launchArguments = base + ["-progress.onboardingStage", ""]
        app.launch()

        let skill = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Know the basics")).firstMatch
        for _ in 1...5 where !skill.exists {
            XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 20))
            app.buttons["Continue"].tap()
        }
        XCTAssertTrue(skill.waitForExistence(timeout: 10))
        skill.tap()
        app.buttons["Continue"].tap()
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 20), "no trial page")
        getStarted.tap()
        let skipTour = app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@",
            "Skip the tour", "Skip it, take me to the app")).firstMatch
        XCTAssertTrue(skipTour.waitForExistence(timeout: 15), "the tour did not open")
        app.terminate()

        app.launchArguments = base
        app.launch()
        XCTAssertTrue(skipTour.waitForExistence(timeout: 20), "the relaunch did not resume the tour")
        XCTAssertFalse(app.buttons["Continue"].exists, "the relaunch started at the first intro page")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "relaunch_in_tour"
        shot.lifetime = .keepAlways
        add(shot)
        skipTour.tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 20), "skipping the tour did not reach Home")
    }
}
