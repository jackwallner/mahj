import XCTest

/// A challenge link (the App Store event's `mahj://challenge`, the same route
/// a reminder tap takes) while something else is open. It must show the
/// challenge, and never throw away what the player was doing.
@MainActor
final class RouteOverOpenScreenTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch(member: Bool) {
        app.launchArguments = [
            "-progress.hasOnboarded", "YES",
            "-mahj.hasReadPrimer", "YES",
            "-mahj.skillLevel", "some",
            "-subscription.localProOverride", member ? "YES" : "NO",
            "-progress.totalSessions", "1",
            "-progress.sessionsAtOnboarding", "0",
            "-ChallengeMonth", "2026-11-05",
            "-reviewPrompt.launchCount", "0",
            "-mahj.suppressWhatsNew",
        ]
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 20), "Home did not load")
    }

    private var challengeScreen: XCUIElement { app.navigationBars["November Challenge"] }

    /// B10 (disproven on iOS 27.2): with Settings up, the link opens the
    /// challenge in front of it. Kept as a guard.
    func testChallengeLinkWhileSettingsIsOpenShowsTheChallenge() {
        launch(member: false)
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10), "Settings did not open")

        app.open(URL(string: "mahj://challenge")!)

        XCTAssertTrue(challengeScreen.waitForExistence(timeout: 15), "the challenge never came to the front")
        XCTAssertFalse(app.navigationBars["Settings"].exists, "Settings is still over the challenge")
        attach("challenge_over_settings")
    }

    /// B1: a Timed Challenge in progress was replaced by the route. Back from
    /// the challenge now returns to it.
    func testChallengeLinkWhileATimedChallengeRunsKeepsTheRun() {
        launch(member: true)
        let tile = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Timed Challenge")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 10), "no Timed Challenge tile")
        scrollSideways(to: tile)
        tile.tap()
        let start = app.buttons["Start the clock"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        XCTAssertTrue(app.buttons["choice-0"].firstMatch.waitForExistence(timeout: 10), "the run did not start")

        app.open(URL(string: "mahj://challenge")!)

        XCTAssertTrue(challengeScreen.waitForExistence(timeout: 15), "the challenge never opened")
        attach("challenge_over_timed_run")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Timed Challenge"].waitForExistence(timeout: 10),
                      "Back from the challenge did not return to the Timed Challenge")
        attach("back_to_timed_run")
    }

    /// The Training row scrolls sideways and ends each tile part way in.
    private func scrollSideways(to element: XCUIElement) {
        for _ in 0..<6 where element.frame.maxX > app.frame.width - 8 {
            let row = element.frame.midY / app.frame.height
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: row))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: row)))
        }
    }

    /// The link while the challenge is already on top: the open question is
    /// left alone, not rebuilt.
    func testChallengeLinkInsideTheChallengeLeavesTheOpenQuestion() {
        launch(member: false)
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "NOVEMBER CHALLENGE")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "no challenge card")
        card.tap()
        let play = app.buttons["Play Today's Mahj Minute"]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        play.tap()
        let choice = app.buttons["choice-0"].firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 10))
        choice.tap()
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 10), "no graded question")

        app.open(URL(string: "mahj://challenge")!)
        RunLoop.current.run(until: Date().addingTimeInterval(4))

        XCTAssertTrue(app.buttons["Next"].exists, "the open question was rebuilt by the link")
        attach("challenge_link_in_challenge")
    }

    private func attach(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
