import XCTest

/// A member's first answer froze 1.4.1 for good on iOS 18: Home re-rendered
/// forever under the pushed screen. Only iOS 18 shows it, so run this with an
/// iOS 18 device when touching what Home observes.
@MainActor
final class MemberAnswerFreezeUITests: XCTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.mahj")
        app.launchArguments += [
            "-AppleLocale", "en_ID", "-AppleLanguages", "(en)",
            "-progress.hasOnboarded", "YES", "-progress.totalSessions", "4", "-progress.sessionsAtOnboarding", "1",
            "-subscription.localProOverride", "YES", "-ChallengeMonth", "2026-10-28", "-mahj.suppressWhatsNew",
            "-practice.records", "<7b226d6f72652d74696c652d666c6f7765722d636f756e74223a7b22617474656d707473223a332c22636f7272656374223a312c2273747265616b223a302c226c617374416e737765726564223a302c2264756544617465223a302c22696e74657276616c44617973223a302c2265617365223a322e352c22726f6f6d4944223a2274696c652d726f6f6d227d2c226d6f72652d74696c652d647261676f6e2d636f756e74223a7b22617474656d707473223a332c22636f7272656374223a312c2273747265616b223a302c226c617374416e737765726564223a302c2264756544617465223a302c22696e74657276616c44617973223a302c2265617365223a322e352c22726f6f6d4944223a2274696c652d726f6f6d227d2c226d6f72652d74696c652d6f6e652d62616d223a7b22617474656d707473223a332c22636f7272656374223a312c2273747265616b223a302c226c617374416e737765726564223a302c2264756544617465223a302c22696e74657276616c44617973223a302c2265617365223a322e352c22726f6f6d4944223a2274696c652d726f6f6d227d2c226d6f72652d74696c652d737761702d6a6f6b6572223a7b22617474656d707473223a332c22636f7272656374223a312c2273747265616b223a302c226c617374416e737765726564223a302c2264756544617465223a302c22696e74657276616c44617973223a302c2265617365223a322e352c22726f6f6d4944223a2274696c652d726f6f6d227d7d>"
        ]
        app.launch()
        return app
    }

    /// A hung main thread makes the accessibility snapshot throw.
    private func isResponsive(_ app: XCUIApplication) -> Bool {
        (try? app.snapshot()) != nil
    }

    private func answerOnce(_ app: XCUIApplication) -> String? {
        let navigation = ["Back", "Done", "Close", "Settings", "Skip", "Report"]
        let height = app.windows.firstMatch.frame.height
        for button in app.buttons.allElementsBoundByIndex.prefix(30) {
            guard button.exists, button.isHittable else { continue }
            let frame = button.frame
            guard frame.midY >= 200, frame.midY <= height - 20, !button.label.isEmpty else { continue }
            guard !navigation.contains(where: { button.label.contains($0) }) else { continue }
            let label = button.label
            button.tap()
            return label
        }
        return nil
    }

    private func answerStaysResponsive(entry: NSPredicate) {
        let app = launch()
        XCTAssertTrue(app.buttons.firstMatch.waitForExistence(timeout: 90))
        let link = app.buttons.matching(entry).firstMatch
        let window = app.windows.firstMatch.frame.insetBy(dx: 0, dy: 90)
        var scrolls = 0
        while !(link.exists && window.contains(CGPoint(x: link.frame.midX, y: link.frame.midY))), scrolls < 10 {
            app.swipeUp()
            scrolls += 1
        }
        XCTAssertTrue(link.exists, "no entry")
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: link.frame.midX, dy: link.frame.midY)).tap()
        sleep(3)
        XCTAssertTrue(isResponsive(app), "hung opening")
        for round in 0..<6 {
            guard let label = answerOnce(app) else { break }
            sleep(2)
            XCTAssertTrue(isResponsive(app), "hung after tap \(round) on \(label.prefix(36))")
        }
        app.terminate()
    }

    func testGetStartedAnswer() {
        answerStaysResponsive(entry: NSPredicate(format: "label BEGINSWITH 'Get Started' OR label BEGINSWITH 'Resume'"))
    }

    func testMahjMinuteAnswer() {
        answerStaysResponsive(entry: NSPredicate(format: "label CONTAINS 'Mahj Minute'"))
    }
}
