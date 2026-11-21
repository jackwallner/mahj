import XCTest

/// Temporary coverage pass for the 2026-11-20 experience audit. Never fails:
/// everything it sees goes into screenshots, accessibility trees and a notes
/// attachment. Not committed to the app repo.
@MainActor
final class AuditCoverageTests: XCTestCase {
    private var app: XCUIApplication!
    private var notes: [String] = []

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
    }

    override func tearDown() {
        let note = XCTAttachment(string: notes.joined(separator: "\n"))
        note.name = "notes-\(name)"
        note.lifetime = .keepAlways
        add(note)
    }

    // MARK: - Clean install: onboarding to Home, then watch Home settle

    func test0CleanInstallArrival() {
        launch(onboarded: false)
        for level in ["Brand new"] {
            walkOnboarding(level: level)
        }
    }

    private func walkOnboarding(level: String) {
        let skill = app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", level)).firstMatch
        for _ in 0..<6 where !skill.exists {
            tapIf("Continue")
            settle(0.8)
        }
        shot("onb-skill")
        guard skill.exists else { note("no skill option \(level)"); tree("onb-missing"); return }
        skill.tap()
        tapIf("Continue")
        settle(2)
        shot("onb-trial")
        tree("onb-trial")
        audit("onb-trial")
        tapIf("Get Started")
        settle(1.5)
        // Primer (Brand new reads it), then the tour.
        for page in 0..<8 {
            if app.buttons["Skip the tour"].exists || app.buttons["Skip it, take me to the app"].exists { break }
            shot("onb-after-trial-\(page)")
            if app.buttons["Take your seat"].exists { app.buttons["Take your seat"].tap() }
            else if app.buttons["Continue"].exists { app.buttons["Continue"].tap() }
            else if app.buttons["Show me"].exists { break }
            settle(0.8)
        }
        shot("onb-tour")
        tree("onb-tour")
        let skip = app.buttons.matching(NSPredicate(format: "label == 'Skip the tour' OR label == 'Skip it, take me to the app'")).firstMatch
        guard skip.waitForExistence(timeout: 10) else { note("no tour skip"); tree("onb-noskip"); return }
        skip.tap()
        let start = Date()
        for delay in [0.1, 0.3, 0.6, 1.0, 1.6, 2.5, 4.0] {
            let wait = delay - Date().timeIntervalSince(start)
            if wait > 0 { Thread.sleep(forTimeInterval: wait) }
            shot("arrival-\(Int(delay * 1000))ms")
            let get = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Get Started'")).firstMatch
            let gear = app.buttons["Settings"].firstMatch
            note("arrival \(delay)s: GetStarted=\(get.exists ? "\(get.frame)" : "-") hittable=\(get.exists && get.isHittable) gear=\(gear.exists ? "\(gear.frame)" : "-")")
        }
        tree("arrival-home")
        audit("arrival-home")
    }

    // MARK: - VoiceOver proxy: accessibility tree and Apple's audit per screen

    func test1AccessibilityScreens() {
        let screens = ["home", "stats", "reference", "settings", "paywall", "challenge", "quick", "handplay",
                       "room/tile-room", "drill/meet-tiles", "drill/tile-quiz", "drill/hand-match",
                       "drill/charleston-pass", "drill/judgment-cards"]
        for screen in screens {
            launch(shot: screen == "home" ? nil : screen)
            settle(screen == "home" ? 2 : 4)
            let name = screen.replacingOccurrences(of: "/", with: "-")
            shot("ax-\(name)")
            tree("ax-\(name)")
            audit("ax-\(name)")
            app.terminate()
        }
        // States the routes do not open: a graded answer, a flipped card,
        // an expanded section, a coached throw, a selected pass.
        launch(shot: "drill/tile-quiz"); settle(4)
        if answer() { settle(1.5); shot("ax-quiz-graded"); tree("ax-quiz-graded"); audit("ax-quiz-graded") }
        app.terminate()
        launch(shot: "drill/meet-tiles"); settle(4)
        let card = app.buttons.matching(NSPredicate(format: "identifier CONTAINS[c] 'card' OR label CONTAINS[c] 'flip'")).firstMatch
        if card.exists { card.tap() } else { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap() }
        settle(1.2); shot("ax-deck-back"); tree("ax-deck-back"); audit("ax-deck-back")
        app.terminate()
        launch(shot: "reference"); settle(4)
        let section = app.buttons.containing(NSPredicate(format: "label BEGINSWITH '2468'")).firstMatch
        if section.exists { section.tap(); settle(1); tree("ax-reference-open"); shot("ax-reference-open") }
        app.terminate()
        launch(shot: "drill/charleston-pass"); settle(4)
        let tiles = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'tile-' OR label CONTAINS[c] 'Crak' OR label CONTAINS[c] 'Bam' OR label CONTAINS[c] 'Dot' OR label CONTAINS[c] 'Joker'"))
        note("charleston tile buttons: \(tiles.count)")
        let joker = tiles.matching(NSPredicate(format: "label CONTAINS[c] 'Joker'")).firstMatch
        if joker.exists { joker.tap(); settle(0.6); shot("ax-charleston-joker-tap"); tree("ax-charleston-joker-tap") }
        for index in 0..<min(4, tiles.count) where !tiles.element(boundBy: index).label.localizedCaseInsensitiveContains("joker") {
            tiles.element(boundBy: index).tap(); settle(0.3)
        }
        shot("ax-charleston-selected"); tree("ax-charleston-selected")
        app.terminate()
        launch(shot: "handplay"); settle(4)
        let section2 = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Consecutive' OR label CONTAINS '2468' OR label CONTAINS 'Like Numbers'")).firstMatch
        if section2.exists {
            section2.tap(); settle(1)
            tapIf("Play it out"); settle(2)
            shot("ax-hand-playing"); tree("ax-hand-playing")
            let rackTile = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Crak' OR label CONTAINS[c] 'Bam' OR label CONTAINS[c] 'Dot' OR label CONTAINS[c] 'Wind' OR label CONTAINS[c] 'Dragon'")).firstMatch
            if rackTile.exists { rackTile.tap(); settle(1.2); shot("ax-hand-thrown"); tree("ax-hand-thrown"); audit("ax-hand-thrown") }
        } else { tree("ax-hand-nosection") }
        app.terminate()
    }

    // MARK: - Purchase sheet through RevenueCat's Test Store (no real money)

    func test2PurchaseSheet() {
        // Plain simulator first: no store at all.
        launch(shot: "paywall"); settle(4)
        shot("buy-nostore-paywall")
        if let cta = purchaseButton() { cta.tap(); settle(3); shot("buy-nostore-tapped"); tree("buy-nostore-tapped") }
        app.terminate()

        // Test Store: the onboarding trial page, cancel, then buy.
        app.launchEnvironment["RC_PROBE_USER"] = "audit-\(UUID().uuidString.prefix(8))"
        launch(onboarded: false, extra: ["-rcfunnelprobe"])
        let skill = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Know the basics'")).firstMatch
        for _ in 0..<6 where !skill.exists { tapIf("Continue"); settle(0.8) }
        skill.tap()
        tapIf("Continue")
        settle(5)
        shot("buy-trial-page"); tree("buy-trial-page")
        guard let cta = purchaseButton() else { note("no trial CTA"); return }
        note("trial CTA label: \(cta.label)")
        cta.tap()
        settle(4)
        shot("buy-sheet-1"); tree("buy-sheet-1")
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        note("app alerts=\(app.alerts.count) sheets=\(app.sheets.count) springboard alerts=\(springboard.alerts.count)")
        if !cancelSheet(springboard) { note("could not find a cancel control") }
        settle(3)
        shot("buy-after-cancel"); tree("buy-after-cancel")
        guard let again = purchaseButton() else { note("no CTA after cancel"); return }
        again.tap()
        settle(4)
        shot("buy-sheet-2")
        if !confirmSheet(springboard) { note("could not find a buy control"); tree("buy-sheet-2-tree") }
        settle(6)
        shot("buy-after-purchase"); tree("buy-after-purchase")
        settle(4)
        shot("buy-after-purchase-later")
    }

    private func purchaseButton() -> XCUIElement? {
        let predicate = NSPredicate(format: "label CONTAINS[c] 'trial' OR label CONTAINS[c] 'Subscribe' OR label CONTAINS[c] 'Continue' OR label CONTAINS[c] 'Get Mahj+' OR label CONTAINS[c] 'Unlock' OR label CONTAINS[c] 'Buy'")
        let match = app.buttons.matching(predicate)
        for index in 0..<match.count {
            let element = match.element(boundBy: index)
            if element.isHittable, !element.label.contains("Restore") { return element }
        }
        return nil
    }

    private func cancelSheet(_ springboard: XCUIApplication) -> Bool {
        for root in [app!, springboard] {
            for name in ["Cancel", "Close", "Test cancelled purchase", "Cancel purchase"] {
                let button = root.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch
                if button.exists { note("cancel via \(name)"); button.tap(); return true }
            }
        }
        return false
    }

    private func confirmSheet(_ springboard: XCUIApplication) -> Bool {
        for root in [app!, springboard] {
            for name in ["Test valid purchase", "valid", "Purchase", "Subscribe", "Confirm", "Buy"] {
                let button = root.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch
                if button.exists { note("buy via \(button.label)"); button.tap(); return true }
            }
        }
        return false
    }

    // MARK: - Arabic with Egypt and UAE regions

    func test3ArabicRegions() {
        for locale in ["ar_EG", "ar_AE"] {
            let lang = ["-AppleLanguages", "(ar)", "-AppleLocale", locale]
            for screen in ["home", "drill/meet-tiles", "handplay", "stats", "paywall", "settings", "reference",
                           "drill/charleston-pass", "drill/tile-quiz", "challenge", "room/card-room"] {
                launch(shot: screen == "home" ? nil : screen, extra: lang)
                settle(screen == "home" ? 2 : 4)
                shot("ar-\(locale)-\(screen.replacingOccurrences(of: "/", with: "-"))")
                app.terminate()
            }
            launch(shot: "drill/tile-quiz", extra: lang); settle(4)
            if answer() { settle(1.5); shot("ar-\(locale)-quiz-graded") }
            app.terminate()
            for page in [0, 3, 4] {
                launch(onboarded: false, extra: lang + ["-mahj.onboardingPage", "\(page)"])
                settle(3)
                shot("ar-\(locale)-onboarding-\(page)")
                app.terminate()
            }
        }
    }

    // MARK: - Restored answers in Read the Rack and Get Started

    func test4ResumeOtherHosts() {
        launch(shot: "drill/hand-match"); settle(4)
        tapIf("Start over"); settle(1)
        if answer() {
            settle(1.6); shot("resume-rack-live")
            app.terminate()
            launch(); settle(2)
            let resume = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Resume'")).firstMatch
            if resume.waitForExistence(timeout: 8) { resume.tap(); settle(2.5); shot("resume-rack-restored") }
            else { note("no resume card for rack"); shot("resume-rack-home") }
        } else { note("no rack choices"); tree("resume-rack-tree") }
        app.terminate()

        launch(); settle(2)
        let get = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Get Started' OR label BEGINSWITH 'Resume'")).firstMatch
        if get.waitForExistence(timeout: 8) {
            get.tap(); settle(2)
            tapIf("Start over"); settle(1)
            if answer() {
                settle(1.6); shot("resume-quick-live")
                app.terminate()
                launch(); settle(2)
                let resume = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Resume'")).firstMatch
                if resume.waitForExistence(timeout: 8) { resume.tap(); settle(2.5); shot("resume-quick-restored") }
                else { note("no resume card for quick"); shot("resume-quick-home") }
            } else { note("no quick choices") }
        }
        app.terminate()
    }

    // MARK: - iPad landscape, keyboard; Duo unfolded (same walk)

    func test5IPadLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(2)
        walkLayouts(prefix: "land")
        XCUIDevice.shared.orientation = .portrait
        sleep(2)
        keyboard(prefix: "port")
    }

    func test6DuoUnfolded() {
        walkLayouts(prefix: "duo")
        keyboard(prefix: "duo")
    }

    private func walkLayouts(prefix: String) {
        for screen in ["home", "room/tile-room", "drill/meet-tiles", "drill/tile-quiz", "drill/hand-match",
                       "drill/charleston-pass", "handplay", "stats", "reference", "settings", "paywall", "challenge", "quick"] {
            launch(shot: screen == "home" ? nil : screen)
            settle(screen == "home" ? 2 : 4)
            let name = screen.replacingOccurrences(of: "/", with: "-")
            shot("\(prefix)-\(name)")
            if screen == "paywall" {
                app.swipeUp(); settle(1); shot("\(prefix)-paywall-scrolled")
            }
            if screen == "drill/tile-quiz", answer() { settle(1.5); shot("\(prefix)-quiz-graded") }
            app.terminate()
        }
        for page in [0, 3, 4] {
            launch(onboarded: false, extra: ["-mahj.onboardingPage", "\(page)"])
            settle(3)
            shot("\(prefix)-onboarding-\(page)")
            app.terminate()
        }
    }

    private func keyboard(prefix: String) {
        launch(shot: "settings"); settle(4)
        let feedback = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'Feedback'")).firstMatch
        for _ in 0..<3 where !feedback.isHittable { app.swipeUp(); settle(0.6) }
        guard feedback.exists else { note("no feedback row"); return }
        feedback.tap(); settle(2)
        let editor = app.textViews.firstMatch
        if editor.waitForExistence(timeout: 5) {
            editor.tap(); settle(1)
            editor.typeText("Audit check, two sentences. Please ignore.")
            settle(1)
            shot("\(prefix)-feedback-keyboard"); tree("\(prefix)-feedback-keyboard")
        } else { note("no text editor"); tree("\(prefix)-feedback-tree") }
        app.terminate()
    }

    // MARK: - Helpers

    private func launch(onboarded: Bool = true, shot: String? = nil, extra: [String] = []) {
        var args = ["-settings.shareUsageData", "NO", "-reviewPrompt.launchCount", "0",
                    "-mahj.suppressWhatsNew", "YES", "-whatsnew.lastSeenVersion", "99",
                    "-subscription.localProOverride", "NO",
                    "-mahj.rc.trial_offer", "off", "-mahj.rc.rating_prompt", "off"]
        if onboarded {
            args += ["-progress.hasOnboarded", "YES", "-mahj.hasReadPrimer", "YES", "-mahj.skillLevel", "some"]
        } else {
            args += ["-progress.hasOnboarded", "NO"]
        }
        if let shot { args += ["-mahj.shot", shot] }
        app.launchArguments = args + extra
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle(1)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        if alert.exists {
            note("system alert: \(alert.label)")
            let deny = alert.buttons.matching(NSPredicate(format: "label IN %@", ["Don’t Allow", "Don't Allow", "Not Now", "Ask App Not to Track"])).firstMatch
            if deny.exists { deny.tap() }
        }
    }

    @discardableResult
    private func answer() -> Bool {
        let choice = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'choice-'")).firstMatch
        guard choice.waitForExistence(timeout: 6) else { return false }
        choice.tap()
        return true
    }

    private func tapIf(_ name: String) {
        let button = app.buttons[name].firstMatch
        if button.waitForExistence(timeout: 2), button.isHittable { button.tap() }
    }

    private func settle(_ seconds: TimeInterval) { Thread.sleep(forTimeInterval: seconds) }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func tree(_ name: String) {
        let attachment = XCTAttachment(string: app.debugDescription)
        attachment.name = "tree-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func note(_ text: String) { notes.append(text) }

    private func audit(_ name: String) {
        var found: [String] = []
        do {
            try app.performAccessibilityAudit(for: .all) { issue in
                let element = issue.element.map { "\($0.elementType.rawValue) '\($0.label)' id=\($0.identifier) \($0.frame)" } ?? "-"
                found.append("[\(issue.auditType.rawValue)] \(issue.compactDescription) | \(element) | \(issue.detailedDescription)")
                return true
            }
        } catch {
            found.append("audit error: \(error)")
        }
        let attachment = XCTAttachment(string: found.joined(separator: "\n"))
        attachment.name = "audit-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        note("audit \(name): \(found.count) issues")
    }
}
