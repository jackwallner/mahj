import XCTest

/// Skeptical free user: what is paid, how to leave, Restore, Close. Records
/// screenshots and trees only; never taps a purchase button.
@MainActor
final class SubscriptionAuditTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
    }

    private func launch(onboarded: Bool) {
        app.launchArguments = [
            "-progress.hasOnboarded", onboarded ? "YES" : "NO",
            "-mahj.hasReadPrimer", "YES",
            "-mahj.suppressWhatsNew",
            "-subscription.localProOverride", "NO",
        ]
        if onboarded { app.launchArguments += ["-mahj.skillLevel", "some"] }
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
    }

    func testOnboardingExitPath() {
        launch(onboarded: false)
        settle(1.0)
        capture("o0_first")
        for i in 1...3 {
            guard tap("Continue") else { break }
            settle(0.8); capture("o\(i)_continue")
        }
        _ = tap("Know the basics")
        settle(0.5); _ = tap("Continue")
        settle(1.5)
        capture("o4_trial"); tree("o4_trial")
        // Soft exit above the primary CTA.
        _ = tap("Get Started")
        settle(1.5)
        capture("o5_after_exit"); tree("o5_after_exit")
    }

    func testFreeUserLockedAndPaywallExit() {
        launch(onboarded: true)
        settle(1.5)
        capture("p0_home"); tree("p0_home")
        // Open the Table room, then a locked drill.
        for room in ["Master Tables", "Tile Room"] {
            if tap(room) { settle(1.0); capture("p1_\(room)"); tree("p1_\(room)"); break }
        }
        if let locked = firstLocked() {
            locked.tap(); settle(1.5)
            capture("p2_locked_tap"); tree("p2_locked_tap")
        }
        // Paywall interactions if present.
        if app.buttons["Restore"].exists {
            _ = tap("Monthly"); settle(0.6); capture("p3_monthly")
            _ = tap("Lifetime"); settle(0.6); capture("p4_lifetime")
            app.buttons["Restore"].tap(); settle(2.5)
            capture("p5_restore"); tree("p5_restore")
            let ok = app.alerts.buttons["OK"]
            if ok.exists { ok.tap(); settle(0.6) }
            _ = tap("Close"); settle(1.2)
            capture("p6_after_close")
        }
        // Settings membership.
        let gear = app.navigationBars.buttons["Settings"].firstMatch
        if gear.waitForExistence(timeout: 4) {
            gear.tap(); settle(1.2)
            capture("s0_settings"); tree("s0_settings")
            app.swipeUp(); settle(0.6); capture("s1_settings_scrolled")
        }
    }

    private func firstLocked() -> XCUIElement? {
        let p = NSPredicate(format: "label CONTAINS[c] 'locked' OR label CONTAINS 'Mahj+'")
        let m = app.buttons.matching(p).firstMatch
        return m.waitForExistence(timeout: 3) ? m : nil
    }

    @discardableResult
    private func tap(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            guard match.waitForExistence(timeout: 4) else { continue }
            match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return true
        }
        return false
    }

    private func settle(_ s: TimeInterval = 1.6) { Thread.sleep(forTimeInterval: s) }

    private func capture(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name; a.lifetime = .keepAlways; add(a)
    }

    private func tree(_ name: String) {
        let a = XCTAttachment(string: app.debugDescription)
        a.name = "tree_\(name)"; a.lifetime = .keepAlways; add(a)
    }
}
