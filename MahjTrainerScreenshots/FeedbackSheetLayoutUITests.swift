import XCTest

/// Measures where Send sits against the keyboard once a word is typed.
final class FeedbackSheetLayoutUITests: XCTestCase {
    private func measure(size: String?) {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.mahj")
        app.launchArguments += ["-progress.hasOnboarded", "YES", "-mahj.shot", "settings"]
        if let size { app.launchArguments += ["-UIPreferredContentSizeCategoryName", size] }
        app.launch()
        let row = app.buttons["Send Feedback"]
        for _ in 0..<6 where !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 20))
        row.tap()
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        editor.tap()
        editor.typeText("I'm ")
        sleep(2)
        let send = app.buttons["Send"]
        let keyboard = app.keyboards.firstMatch
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "feedback-\(size ?? "default")"
        shot.lifetime = .keepAlways
        add(shot)
        let kb = keyboard.exists ? keyboard.frame : .null
        print("FEEDBACK_LAYOUT size=\(size ?? "default") window=\(app.windows.firstMatch.frame) send=\(send.frame) keyboard=\(kb) gap=\(kb.isNull ? -1 : kb.minY - send.frame.maxY)")
        app.terminate()
    }

    func testDefault() { measure(size: nil) }
    func testLarge() { measure(size: "UICTContentSizeCategoryXXXL") }
    func testAccessibilityMedium() { measure(size: "UICTContentSizeCategoryAccessibilityM") }
}
