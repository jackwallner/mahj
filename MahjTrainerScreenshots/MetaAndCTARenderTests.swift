import XCTest

/// Captures for the trial button wordings: every `TrialCTA` wording on both
/// purchase surfaces (`-mahj.rc.trial_cta`).
///
/// Run: scripts/capture-meta-cta.sh <udid> <out-dir>.
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
            launch(onboarded: false, extra: ["-mahj.rc.trial_cta", arm.raw])
            walkToTrialPage()
            capture("cta_\(arm.raw)_onboarding")
            check("onboarding CTA reads '\(arm.onboarding)'",
                  app.buttons[arm.onboarding].waitForExistence(timeout: 4))
            app.terminate()

            launch(onboarded: true, extra: ["-mahj.rc.trial_cta", arm.raw])
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

    /// The trial page with every RevenueCat variant switched on at once.
    func testTrialPageVariants() {
        launch(onboarded: false, extra: [
            "-mahj.rc.trial_title", "game_night",
            "-mahj.rc.trial_benefits", "paid_first",
            "-mahj.rc.onboarding_plan", "yearly",
            "-mahj.rc.trial_cta", "my",
        ])
        walkToTrialPage()
        capture("variants_onboarding")
        check("title variant", app.staticTexts["Get ready for game night"].waitForExistence(timeout: 4))
        check("benefits variant", app.staticTexts["Game Night Prep, five minutes built from your misses"].exists)
        check("yearly price line", app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "/year")).firstMatch.exists)
        check("button variant", app.buttons["Start my free trial"].exists)
        app.terminate()
    }

    // MARK: - Helpers

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
