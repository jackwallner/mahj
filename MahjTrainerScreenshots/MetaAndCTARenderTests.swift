import XCTest

/// Captures for the October 2026 Meta prep and the trial button wordings.
///
/// - Every `TrialCTA` wording on both purchase surfaces (`-mahj.trialCTA`).
/// - Apple's tracking prompt: absent through onboarding, shown on Home after
///   it (`-mahj.previewMetaATT` stands in for a Meta app id).
///
/// Run: scripts/capture-meta-cta.sh <udid> <out-dir>. Reinstall first: the
/// ATT answer survives relaunches of the same install.
///
/// Findings go into a `checks` attachment instead of XCTFail, for the same
/// reason as `PaywallRenderTests`.
@MainActor
final class MetaAndCTARenderTests: XCTestCase {
    private var app: XCUIApplication!
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    private var checks: [String] = []

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
    }

    override func tearDown() {
        let note = XCTAttachment(string: checks.joined(separator: "\n"))
        note.name = "checks_\(name.replacingOccurrences(of: " ", with: "_"))"
        note.lifetime = .keepAlways
        add(note)
    }

    func testCTAArms() {
        let arms: [(raw: String, onboarding: String, paywall: String)] = [
            ("seven_day", "Start 7-day free trial", "Start 7-Day Free Trial"),
            ("my", "Start my free trial", "Start My Free Trial"),
            ("your", "Start your free trial", "Start Your Free Trial"),
        ]
        for arm in arms {
            launch(onboarded: false, extra: ["-mahj.trialCTA", arm.raw])
            walkToTrialPage()
            capture("cta_\(arm.raw)_onboarding")
            check("onboarding CTA reads '\(arm.onboarding)'",
                  app.buttons[arm.onboarding].waitForExistence(timeout: 4))
            app.terminate()

            launch(onboarded: true, extra: ["-mahj.trialCTA", arm.raw])
            if openPaywall() {
                settle()
                capture("cta_\(arm.raw)_paywall")
                let title = arm.paywall
                check("paywall CTA reads '\(title)'", app.buttons[title].waitForExistence(timeout: 4))
            } else {
                check("paywall opened", false)
            }
            app.terminate()
        }
    }

    func testTrackingPromptAfterOnboarding() {
        launch(onboarded: false, extra: ["-mahj.previewMetaATT"])
        check("no tracking prompt on the first onboarding page", !trackingAlert.waitForExistence(timeout: 3))
        walkToTrialPage()
        check("no tracking prompt on the trial page", !trackingAlert.waitForExistence(timeout: 3))
        capture("att_none_during_onboarding")
        app.terminate()

        launch(onboarded: true, extra: ["-mahj.previewMetaATT"])
        let shown = trackingAlert.waitForExistence(timeout: 8)
        check("tracking prompt shown on Home after onboarding", shown)
        guard shown else { return }
        capture("att_prompt_home")
        let text = trackingAlert.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " | ")
        checks.append("prompt text: \(text)")
        check("prompt carries our usage copy", text.contains("Facebook or Instagram ad"))
        trackingAlert.buttons["Allow"].tap()
        settle()
        check("prompt gone after answering", !trackingAlert.exists)
        capture("att_after_allow")
        app.terminate()

        launch(onboarded: true, extra: ["-mahj.previewMetaATT"])
        check("never asked twice", !trackingAlert.waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    private var trackingAlert: XCUIElement {
        springboard.alerts.matching(NSPredicate(format: "label CONTAINS %@", "track")).firstMatch
    }

    private func launch(onboarded: Bool, extra: [String]) {
        app.launchArguments = [
            "-progress.hasOnboarded", onboarded ? "YES" : "NO",
            "-mahj.hasReadPrimer", "YES",
            "-mahj.suppressWhatsNew",
            "-subscription.localProOverride", "NO",
        ] + (onboarded ? ["-mahj.skillLevel", "some"] : []) + extra
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
    }

    /// Taps through onboarding until the trial CTA is on screen, picking a
    /// skill level when that page gates Continue.
    private func walkToTrialPage() {
        let trialCTA = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "free trial")).firstMatch
        for _ in 0..<8 {
            if trialCTA.exists { break }
            let basics = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Know the basics")).firstMatch
            if basics.exists { basics.tap(); settle(0.5) }
            _ = tap("Continue")
            settle(1.0)
        }
        if !trialCTA.waitForExistence(timeout: 3) { checks.append("NOTE did not reach the trial page") }
    }

    private func openPaywall() -> Bool {
        let gear = app.navigationBars.buttons["Settings"].firstMatch
        guard gear.waitForExistence(timeout: 6) else { return false }
        gear.tap()
        settle(1.0)
        let upgrade = app.buttons["Get Mahj+"].firstMatch
        guard upgrade.waitForExistence(timeout: 4) else { return false }
        upgrade.tap()
        return true
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

    private func check(_ what: String, _ ok: Bool) {
        checks.append("\(ok ? "PASS" : "FAIL") \(what)")
    }

    private func settle(_ seconds: TimeInterval = 1.6) {
        Thread.sleep(forTimeInterval: seconds)
    }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
