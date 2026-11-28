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

    private var nextButton: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == 'Next' OR label BEGINSWITH 'Next ' OR label == 'Finish'")).firstMatch
    }

    private func openChallengeLink() {
        let process = appProcessID()
        XCTAssertGreaterThan(process, 0)
        // XCUIApplication.open launches the target. Deliver through the OS so
        // these tests exercise a warm link, not a fresh process with lost state.
        XCUIDevice.shared.system.open(URL(string: "mahj://challenge")!)
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))
        XCTAssertEqual(appProcessID(), process, "URL delivery relaunched the app instead of routing over it")
    }

    private func appProcessID() -> Int {
        let header = String(app.debugDescription.split(whereSeparator: \.isNewline).first ?? "")
        guard let range = header.range(of: #"pid:\s*\d+"#, options: .regularExpression) else { return -1 }
        return Int(header[range].filter(\.isNumber)) ?? -1
    }

    /// Route into the presented stack, not underneath it. Back keeps the
    /// Settings screen the player was using.
    func testChallengeLinkWhileSettingsIsOpenShowsTheChallenge() {
        launch(member: false)
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10), "Settings did not open")

        openChallengeLink()

        XCTAssertTrue(challengeScreen.waitForExistence(timeout: 15), "the challenge never came to the front")
        XCTAssertFalse(app.navigationBars["Settings"].exists, "Settings is still over the challenge")
        XCTAssertTrue(challengeScreen.isHittable, "the challenge is behind the sheet")
        attach("challenge_over_settings")
        challengeScreen.buttons["BackButton"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10), "Back lost Settings")
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

        openChallengeLink()

        XCTAssertTrue(challengeScreen.waitForExistence(timeout: 15), "the challenge never opened")
        attach("challenge_over_timed_run")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Timed Challenge"].waitForExistence(timeout: 10),
                      "Back from the challenge did not return to the Timed Challenge")
        XCTAssertFalse(start.exists, "the timed run restarted after the link")
        attach("back_to_timed_run")
    }

    func testChallengeLinkOverAnEndlessRunKeepsTheHeldAnswer() {
        launch(member: true)
        let tile = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Endless Practice")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        scrollSideways(to: tile)
        tile.tap()
        let skill = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Read the Rack")).firstMatch
        XCTAssertTrue(skill.waitForExistence(timeout: 10))
        skill.tap()
        let choice = app.buttons["choice-0"].firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 10))
        choice.tap()
        XCTAssertTrue(nextButton.waitForExistence(timeout: 10))
        let prompt = app.staticTexts["question-prompt"].firstMatch.label
        let heldAnswer = choice.value as? String

        openChallengeLink()
        XCTAssertTrue(challengeScreen.waitForExistence(timeout: 15))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.navigationBars["Read the Rack"].waitForExistence(timeout: 10))
        XCTAssertTrue(nextButton.exists, "the generated question's held answer was lost")
        XCTAssertEqual(app.staticTexts["question-prompt"].firstMatch.label, prompt)
        XCTAssertEqual(app.buttons["choice-0"].firstMatch.value as? String, heldAnswer)
        attach("back_to_held_endless_answer")
    }

    func testChallengeLinkOverARoomDrillKeepsTheHeldAnswer() {
        launch(member: false)
        let room = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "The Tile Room")).firstMatch
        XCTAssertTrue(room.waitForExistence(timeout: 10))
        room.tap()
        let drill = app.buttons.matching(NSPredicate(
            format: "label BEGINSWITH %@ AND NOT (label CONTAINS %@)", "Tile Check", "Extra Reps"
        )).firstMatch
        XCTAssertTrue(drill.waitForExistence(timeout: 10))
        drill.tap()
        if app.buttons["Start over"].waitForExistence(timeout: 2) { app.buttons["Start over"].tap() }
        let choice = app.buttons["choice-0"].firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 10))
        choice.tap()
        XCTAssertTrue(nextButton.waitForExistence(timeout: 10))
        let prompt = app.staticTexts["question-prompt"].firstMatch.label
        let heldAnswer = choice.value as? String
        attach("room_drill_before_challenge")

        openChallengeLink()
        XCTAssertTrue(challengeScreen.waitForExistence(timeout: 15))
        attach("challenge_over_room_drill")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.navigationBars["Tile Check"].waitForExistence(timeout: 10),
                      "Back from the challenge discarded the room drill")
        XCTAssertTrue(nextButton.exists, "the held answer was lost")
        XCTAssertEqual(app.staticTexts["question-prompt"].firstMatch.label, prompt)
        XCTAssertEqual(app.buttons["choice-0"].firstMatch.value as? String, heldAnswer)
        attach("back_to_held_room_answer")
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
        XCTAssertTrue(nextButton.waitForExistence(timeout: 10), "no graded question")

        openChallengeLink()
        RunLoop.current.run(until: Date().addingTimeInterval(4))

        XCTAssertTrue(nextButton.exists, "the open question was rebuilt by the link")
        attach("challenge_link_in_challenge")
    }

    private func attach(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
