import XCTest

/// Release gate journeys (`qa-gate run`, ~/ios/qa/README.md). They only prove
/// each screen is reachable; FleetQA's oracles judge what is drawn.
@MainActor
final class ReleaseJourneysUITests: XCTestCase {
    private let bundle = "com.jackwallner.mahj"

    override func setUp() {
        continueAfterFailure = false
    }

    func test1FirstRunToHome() {
        let app = XCUIApplication(bundleIdentifier: bundle)
        QA.launch(app)
        // "Know the basics" skips the primer, so the journey walks the tour.
        let skill = app.buttons.containing(label("Know the basics")).firstMatch
        for page in 1...5 where !skill.exists {
            tap("Continue", in: app)
            QA.checkpoint(app, "onboarding-\(page)")
        }
        XCTAssertTrue(skill.waitForExistence(timeout: 10))
        skill.tap()
        QA.checkpoint(app, "skill")
        tap("Continue", in: app)
        XCTAssertTrue(app.buttons["Restore"].waitForExistence(timeout: 20))
        QA.checkpoint(app, "onboarding-trial", paywall: true)
        tap("Get Started", in: app)
        let skipTour = app.buttons.containing(label("Skip")).firstMatch
        XCTAssertTrue(skipTour.waitForExistence(timeout: 15), "no tour")
        QA.checkpoint(app, "tour")
        skipTour.tap()
        home("first-home", in: app)
    }

    func test2SessionChallengeUpgradeAndReturn() {
        let app = XCUIApplication(bundleIdentifier: bundle)
        QA.launch(app, arguments: [
            "-progress.hasOnboarded", "YES",
            "-mahj.hasReadPrimer", "YES",
            "-mahj.skillLevel", "some",
            // A returning player: the challenge card shows after a practice.
            "-progress.totalSessions", "3",
            "-progress.sessionsAtOnboarding", "1",
            "-handplay.lastFreeDay", "",
            "-handplay.inProgress", "",
            // Newer than any release, so What's New stays shut.
            "-whatsnew.lastSeenVersion", "99",
        ])
        home("home", in: app)

        let session = app.buttons.containing(label("Get Started")).firstMatch
        XCTAssertTrue(session.waitForExistence(timeout: 10))
        session.tap()
        QA.checkpoint(app, "quick-session")
        if answer(in: app) { QA.checkpoint(app, "quick-session-answered") }
        back(in: app)
        home("home-after-session", in: app)

        let challenge = app.buttons.containing(label("Today's Mahj Minute")).firstMatch
        XCTAssertTrue(challenge.waitForExistence(timeout: 10))
        challenge.tap()
        QA.checkpoint(app, "challenge")
        back(in: app)
        home("home-after-challenge", in: app)

        let endless = app.buttons.containing(label("Endless")).firstMatch
        XCTAssertTrue(endless.waitForExistence(timeout: 10))
        endless.tap()
        checkpoint("upgrade", button: "Close", in: app, paywall: true)
        tap("Close", in: app)
        home("home-after-upgrade", in: app)

        let room = app.buttons.containing(label("The Card Room")).firstMatch
        XCTAssertTrue(room.waitForExistence(timeout: 10))
        room.tap()
        QA.checkpoint(app, "card-room")
        back(in: app)

        tap("Settings", in: app)
        QA.checkpoint(app, "settings")
        back(in: app)
        home("home-after-settings", in: app)

        QA.interrupt(app)
        home("home-after-background", in: app)
        QA.relaunch(app)
        home("home-after-relaunch", in: app)
    }

    // MARK: - Helpers

    private func label(_ prefix: String) -> NSPredicate {
        NSPredicate(format: "label BEGINSWITH %@", prefix)
    }

    private func tap(_ name: String, in app: XCUIApplication) {
        let button = app.buttons[name].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 15), "no \(name)")
        button.tap()
    }

    private func checkpoint(_ name: String, button: String, in app: XCUIApplication, paywall: Bool? = nil) {
        XCTAssertTrue(app.buttons[button].firstMatch.waitForExistence(timeout: 15), "no \(button)")
        QA.checkpoint(app, name, paywall: paywall)
    }

    private func home(_ name: String, in app: XCUIApplication) {
        XCTAssertTrue(app.buttons["Settings"].firstMatch.waitForExistence(timeout: 20), "Home not reached")
        QA.checkpoint(app, name)
    }

    /// Picks the first answer choice on a question screen, if there is one.
    private func answer(in app: XCUIApplication) -> Bool {
        let choice = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'choice-'")).firstMatch
        guard choice.waitForExistence(timeout: 5) else { return false }
        choice.tap()
        return true
    }

    private func back(in app: XCUIApplication) {
        let bar = app.navigationBars.buttons.firstMatch
        if bar.waitForExistence(timeout: 5), bar.label != "Settings" { bar.tap(); return }
        for name in ["Close", "Done", "Back"] where app.buttons[name].exists {
            app.buttons[name].firstMatch.tap()
            return
        }
    }
}
