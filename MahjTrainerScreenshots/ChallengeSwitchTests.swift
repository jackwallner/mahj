import XCTest

/// The `monthly_challenge` remote switch, end to end on a real build. The
/// launch argument `-mahj.rc.monthly_challenge` pins the same value the
/// offering metadata would carry.
///
/// Off: no Home card, `mahj://challenge` (the App Store event's link) stays
/// on Home, and the What's New sheet drops the challenge line. On, or with
/// no value at all: all three are back. Runs pinned to November 5, 2026
/// (`-ChallengeMonth`, DEBUG only), so it does not depend on today's date.
@MainActor
final class ChallengeSwitchTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testSwitchedOff() {
        launch(switchValue: "off")
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 20), "Home did not load")
        attachScreenshot("off_home")
        XCTAssertFalse(challengeCard.exists, "challenge card still on Home")

        app.open(URL(string: "mahj://challenge")!)
        settle(3)
        attachScreenshot("off_after_link")
        XCTAssertFalse(challengeScreen.exists, "the event link opened the challenge")
        XCTAssertTrue(app.buttons["Settings"].exists, "the event link left Home")
    }

    func testSwitchedOn() {
        for value in [nil, "on"] as [String?] {
            launch(switchValue: value)
            XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 20), "Home did not load")
            XCTAssertTrue(challengeCard.waitForExistence(timeout: 5), "no challenge card (\(value ?? "unset"))")
            attachScreenshot("on_home_\(value ?? "unset")")

            app.open(URL(string: "mahj://challenge")!)
            XCTAssertTrue(challengeScreen.waitForExistence(timeout: 10), "the event link did not open the challenge (\(value ?? "unset"))")
            attachScreenshot("on_after_link_\(value ?? "unset")")
            app.terminate()
        }
    }

    func testWhatsNewFollowsSwitch() {
        for (value, expected) in [("off", false), ("on", true)] {
            launch(switchValue: value, showWhatsNew: true)
            let anchor = app.staticTexts["Your week, counted"]
            XCTAssertTrue(anchor.waitForExistence(timeout: 20), "What's New did not show (\(value))")
            attachScreenshot("whatsnew_\(value)")
            XCTAssertEqual(app.staticTexts["A challenge every month"].exists, expected, "challenge line with switch \(value)")
            app.terminate()
        }
    }

    /// A brand-new player's Home stays the 1.3.2 lobby until a first
    /// practice; the event link still opens the challenge for them.
    func testCardWaitsForAFirstPractice() {
        launch(switchValue: nil, sessions: 0)
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 20), "Home did not load")
        attachScreenshot("new_player_home")
        XCTAssertFalse(challengeCard.exists, "challenge card shown before any practice")

        app.open(URL(string: "mahj://challenge")!)
        XCTAssertTrue(challengeScreen.waitForExistence(timeout: 10), "the event link did not open the challenge for a new player")
        attachScreenshot("new_player_after_link")
    }

    /// Before the first month (October 2026) the link says when it starts
    /// rather than showing nothing.
    func testBeforeTheFirstMonthTheLinkSaysWhenItStarts() {
        launch(switchValue: nil, day: "2026-09-28")
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 20), "Home did not load")
        XCTAssertFalse(challengeCard.exists, "challenge card shown before it opens")
        app.open(URL(string: "mahj://challenge")!)
        let starts = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Starts ")).firstMatch
        XCTAssertTrue(starts.waitForExistence(timeout: 10), "no start date before the first month")
        attachScreenshot("before_first_month")
    }

    // MARK: - Helpers

    private let monthName = "November"

    private var challengeCard: XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "\(monthName.uppercased()) CHALLENGE"))
            .firstMatch
    }

    private var challengeScreen: XCUIElement {
        app.navigationBars["\(monthName) Challenge"]
    }

    private func launch(switchValue: String?, showWhatsNew: Bool = false, sessions: Int = 1, day: String = "2026-11-05") {
        app.launchArguments = [
            "-progress.hasOnboarded", "YES",
            "-mahj.hasReadPrimer", "YES",
            "-mahj.skillLevel", "some",
            "-subscription.localProOverride", "NO",
            "-progress.totalSessions", "\(sessions)",
            "-ChallengeMonth", day,
            "-reviewPrompt.launchCount", "0",
        ]
        app.launchArguments += showWhatsNew ? ["-whatsnew.lastSeenVersion", "1.3.2"] : ["-mahj.suppressWhatsNew"]
        if let switchValue { app.launchArguments += ["-mahj.rc.monthly_challenge", switchValue] }
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle(2)
    }

    private func settle(_ seconds: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    private func attachScreenshot(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "shot_\(name)"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
