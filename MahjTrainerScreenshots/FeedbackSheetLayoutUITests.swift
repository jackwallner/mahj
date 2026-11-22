import XCTest

/// Send used to be a big button just above the keyboard's suggestion bar. It
/// lit up after the first word, and the next reach for a suggestion landed on
/// it: players' feedback arrived as "I'm" and "The", which are exactly the
/// suggestions an empty box offers. Send now sits in the navigation bar.
/// Lives in this UI target because the MahjTrainer scheme runs unit tests only.
final class FeedbackSheetLayoutUITests: XCTestCase {
    private func checkSendIsClearOfTheKeyboard(size: String?) {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.mahj")
        app.launchArguments += ["-progress.hasOnboarded", "YES", "-mahj.shot", "settings"]
        if let size { app.launchArguments += ["-UIPreferredContentSizeCategoryName", size] }
        app.launch()
        defer { app.terminate() }
        let row = app.buttons["Send Feedback"]
        for _ in 0..<6 where !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 20))
        row.tap()
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        let send = app.navigationBars.buttons["Send"]
        XCTAssertTrue(send.waitForExistence(timeout: 5), "Send belongs in the navigation bar")
        XCTAssertFalse(send.isEnabled, "Nothing to send yet")
        editor.tap()
        editor.typeText("I'm ")
        XCTAssertTrue(send.isEnabled)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "feedback-\(size ?? "default")"
        shot.lifetime = .keepAlways
        add(shot)
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5))
        // The suggestion bar sits about 50 points above what XCUITest reports
        // as the keyboard's top; keep Send far clear of both.
        XCTAssertLessThan(send.frame.maxY, keyboard.frame.minY - 200)
        XCTAssertEqual(app.buttons.matching(identifier: "Send").count, 1, "One Send, not a second one by the keyboard")
    }

    func testDefaultSize() { checkSendIsClearOfTheKeyboard(size: nil) }
    func testAccessibilitySize() { checkSendIsClearOfTheKeyboard(size: "UICTContentSizeCategoryAccessibilityM") }
}
