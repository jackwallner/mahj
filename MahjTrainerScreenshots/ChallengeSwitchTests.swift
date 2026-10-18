import XCTest

/// The `monthly_challenge` remote switch, end to end on a real build. The
/// launch argument `-mahj.rc.monthly_challenge` pins the same value the
/// offering metadata would carry.
///
/// Off: no Home card, `mahj://challenge` (the App Store event's link) stays
/// on Home, and the What's New sheet drops the challenge line. On, or with
/// no value at all: all three are back.
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
            XCTAssertEqual(app.staticTexts["A new challenge every month"].exists, expected, "challenge line with switch \(value)")
            app.terminate()
        }
    }

    // MARK: - Helpers

    /// "OCTOBER CHALLENGE" on Home's card, for whatever month the run lands in.
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "LLLL"
        return formatter.string(from: Date())
    }

    private var challengeCard: XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "\(monthName.uppercased()) CHALLENGE"))
            .firstMatch
    }

    private var challengeScreen: XCUIElement {
        app.navigationBars[monthName]
    }

    private func launch(switchValue: String?, showWhatsNew: Bool = false) {
        app.launchArguments = [
            "-progress.hasOnboarded", "YES",
            "-mahj.hasReadPrimer", "YES",
            "-mahj.skillLevel", "some",
            "-subscription.localProOverride", "NO",
            "-progress.totalSessions", "0",
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
