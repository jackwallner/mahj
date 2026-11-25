import XCTest

/// The teacher's class card on Home, pinned without the network and joined
/// for real through `mahj://class/MAHJTEST` (the QA class on the server).
@MainActor
final class ClassCodeUITests: XCTestCase {
    private let app = XCUIApplication(bundleIdentifier: "com.jackwallner.mahj")

    private func launch(_ extra: [String]) {
        app.launchArguments = [
            "-progress.hasOnboarded", "YES",
            "-mahj.hasReadPrimer", "YES",
            "-mahj.skillLevel", "some",
            "-mahj.suppressWhatsNew",
            // Starts with no class, whatever an earlier run joined.
            "-classCode.current", "",
        ] + extra
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
    }

    /// The simulator's StoreKit can raise an Apple Account sign-in over the
    /// app; it is not part of the flow under test.
    private func dismissSignIn() {
        for owner in [app, XCUIApplication(bundleIdentifier: "com.apple.springboard")] {
            let cancel = owner.alerts.buttons["Cancel"]
            if cancel.waitForExistence(timeout: 2) { cancel.tap() }
        }
    }

    private func attach(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testPinnedClassShowsItsFocusRoomAndOpensIt() {
        launch(["-mahj.class", "OK_Lets_Mahjong,charleston-room"])
        defer { app.terminate() }
        let caption = app.staticTexts["OK LETS MAHJONG · THIS WEEK"]
        XCTAssertTrue(caption.waitForExistence(timeout: 20))
        attach("class-card-home")
        caption.tap()
        XCTAssertTrue(app.navigationBars["The Charleston Room"].waitForExistence(timeout: 10)
            || app.staticTexts["The Charleston Room"].waitForExistence(timeout: 2))
        attach("class-card-opened-room")
    }

    func testCardLinkJoinsThroughTheServerAndSettingsCanLeave() {
        launch([])
        defer { app.terminate() }
        XCTAssertFalse(app.staticTexts["TEST CLASS · THIS WEEK"].waitForExistence(timeout: 3))
        app.open(URL(string: "mahj://class/mahjtest")!)
        let caption = app.staticTexts["TEST CLASS · THIS WEEK"]
        XCTAssertTrue(caption.waitForExistence(timeout: 30), "The server's QA class should appear on Home")
        dismissSignIn()
        attach("class-joined-by-link")

        app.buttons["Settings"].firstMatch.tap()
        // The row reads "Class Code, Test Class" once joined. It sits near the
        // top of Settings, and the list drops rows scrolled far off screen,
        // so look before scrolling, one swipe at a time.
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Class Code'")).firstMatch
        for _ in 0..<3 where !row.waitForExistence(timeout: 3) || !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        attach("class-settings-joined")
        let leave = app.buttons["Leave Class"]
        XCTAssertTrue(leave.waitForExistence(timeout: 10))
        leave.tap()
        XCTAssertTrue(app.textFields["Code"].waitForExistence(timeout: 10))
        attach("class-settings-entry")
    }
}
