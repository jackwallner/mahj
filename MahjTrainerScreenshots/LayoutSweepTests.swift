import XCTest

/// Layout and accessibility capture sweep: walks every player-facing screen at
/// one text size and orientation and attaches a screenshot of each, so a
/// release can be checked on every device class people download on.
///
/// Run: scripts/layout-sweep.sh (creates throwaway simulators per device,
/// loops the text sizes, exports the PNGs).
///
/// Configuration comes from the test runner's environment (pass it to
/// xcodebuild as `TEST_RUNNER_<NAME>`):
/// - `SWEEP_SIZE`: `L` (default), `XXXL`, `AX3` or `AX5`.
/// - `SWEEP_ORIENT`: `portrait` (default) or `landscape`.
/// - `SWEEP_SCOPE`: `full` (default), `compare` (trial page, paywall, Home and What's New
///   only, for the 1.3.2 side by side), `att` (the real first-run tracking
///   prompt flow; needs a fresh install), `flashcard` (the Tile Room and one
///   flashcard, front and back) or `rest` (everything after Settings).
///
/// Like the other capture tests it never calls XCTFail: a failing UI test
/// spends ten minutes collecting diagnostics. Anything it could not reach,
/// and any text frame that runs past the screen edge, goes into a `notes`
/// attachment instead.
@MainActor
final class LayoutSweepTests: XCTestCase {
    private var app: XCUIApplication!
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    private var notes: [String] = []
    private var currentStep = ""

    private var env: [String: String] { ProcessInfo.processInfo.environment }
    private var size: String { env["SWEEP_SIZE"] ?? "L" }
    private var landscape: Bool { env["SWEEP_ORIENT"] == "landscape" }
    private var scope: String { env["SWEEP_SCOPE"] ?? "full" }
    private var isAccessibilitySize: Bool { size.hasPrefix("AX") }

    private var sizeCategory: String? {
        switch size {
        case "XXXL": return "UICTContentSizeCategoryXXXL"
        case "AX3": return "UICTContentSizeCategoryAccessibilityXL"
        case "AX5": return "UICTContentSizeCategoryAccessibilityXXXL"
        default: return nil
        }
    }

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        XCUIDevice.shared.orientation = landscape ? .landscapeLeft : .portrait
    }

    override func tearDown() {
        let note = XCTAttachment(string: notes.joined(separator: "\n"))
        note.name = "notes"
        note.lifetime = .keepAlways
        add(note)
    }

    func testSweep() {
        switch scope {
        case "compare":
            step("onboarding") { onboardingToTrial(continueThrough: false) }
            step("paywall") { paywall() }
            step("home_free") { homeFree() }
            step("whatsnew") { whatsNew() }
        case "att":
            step("att") { attFlow() }
        case "rerun":
            // The flows a first pass could not finish, without the screens
            // that already captured cleanly.
            step("onboarding") { onboardingToTrial(continueThrough: true) }
            step("paywall") { paywall() }
            step("settings_free") { settings(member: false) }
            step("quiz") { quiz() }
            step("challenge") { challenge() }
            step("playhand") { playHand() }
        case "new":
            // Only the 1.4 screens, for a loaded Mac that cannot finish a full run.
            step("whatsnew") { whatsNew() }
            step("home_free") { homeFree() }
            step("settings_free") { settings(member: false) }
            step("challenge") { challenge() }
            step("home_member") { memberScreens(full: false) }
        case "probe":
            step("probe") { probe() }
        case "flashcard":
            step("room") { roomAndFlashcards() }
        case "rest":
            // Everything after Settings, for a full run that stopped there.
            step("room") { roomAndFlashcards() }
            step("quiz") { quiz() }
            step("charleston") { charleston() }
            step("challenge") { challenge() }
            step("member") { memberScreens(full: true) }
        case "ipad_landscape":
            step("onboarding") { onboardingToTrial(continueThrough: false) }
            step("paywall") { paywall() }
            step("home_free") { homeFree() }
            step("home_member") { memberScreens(full: false) }
            step("room") { roomAndFlashcards() }
            step("quiz") { quiz() }
            step("charleston") { charleston() }
            step("challenge") { challenge() }
        default:
            step("onboarding") { onboardingToTrial(continueThrough: true) }
            step("whatsnew") { whatsNew() }
            step("paywall") { paywall() }
            step("home_free") { homeFree() }
            step("settings_free") { settings(member: false) }
            step("room") { roomAndFlashcards() }
            step("quiz") { quiz() }
            step("charleston") { charleston() }
            step("challenge") { challenge() }
            step("member") { memberScreens(full: true) }
        }
    }

    // MARK: - Flows

    /// Onboarding pages, the skill page, the trial page, and (when asked) the
    /// primer and the feature tour behind the free "Get Started" exit.
    private func onboardingToTrial(continueThrough: Bool) {
        launch(fresh: true)
        captureScrolled("onb_1")
        for page in 2...3 {
            guard tapButton("Continue") else { note("no Continue before onboarding page \(page)"); return }
            captureScrolled("onb_\(page)")
        }
        guard tapButton("Continue") else { note("no Continue before the skill page"); return }
        captureScrolled("onb_4_skill")
        if !tapContaining("Brand new"), !tapContaining("Know the basics") {
            note("could not pick a skill level")
        }
        capture("onb_4_skill_picked")
        guard tapButton("Continue") else { note("no Continue before the trial page"); return }
        settle()
        captureScrolled("onb_5_trial", max: 12)
        guard continueThrough else { return }

        // Back to the top of the trial page before reaching for the soft exit.
        scrollToTop()
        guard tapButton("Get Started") else { note("trial page: Get Started not reachable"); return }
        settle()
        // Primer (Brand new players only).
        for page in 1...8 {
            if app.buttons["Take your seat"].exists || app.buttons["Skip for now"].exists {
                captureScrolled("primer_\(page)", max: 4)
                if app.buttons["Take your seat"].exists {
                    _ = tapButton("Take your seat")
                    break
                }
                guard tapButton("Continue") else { note("primer page \(page): Continue not reachable"); break }
            } else {
                if page == 1 { note("primer did not appear") }
                break
            }
        }
        settle()
        // Feature tour.
        for page in 1...6 {
            if app.buttons["Show me"].exists {
                captureScrolled("tour_\(page)", max: 4)
                guard tapButton("Show me") else { note("tour page \(page): Show me not reachable"); break }
            } else if app.buttons["Start my first session"].exists || app.buttons["Skip it, take me to the app"].exists {
                captureScrolled("tour_\(page)_last", max: 4)
                if !tapButton("Skip it, take me to the app") {
                    note("tour last page: skip not reachable")
                }
                break
            } else {
                if page == 1 { note("tour did not appear") }
                break
            }
        }
        settle()
        capture("home_after_onboarding")
    }

    private func whatsNew() {
        launch(onboarded: true, member: false, whatsNew: true)
        let title = app.staticTexts["What's New"].firstMatch
        guard title.waitForExistence(timeout: 6) else { note("What's New sheet did not appear"); return }
        settle()
        captureScrolled("whatsnew", max: 8)
    }

    private func paywall() {
        launch(onboarded: true, member: false)
        guard openSettings() else { note("paywall: no Settings gear"); return }
        guard reach(app.buttons["Get Mahj+"].firstMatch, swipes: 8) else { note("paywall: no Get Mahj+ row"); return }
        app.buttons["Get Mahj+"].firstMatch.tap()
        settle(2.2)
        captureScrolled("paywall", max: 10)
    }

    private func homeFree() {
        launch(onboarded: true, member: false)
        captureScrolled("home_free", max: 16)
    }

    private func settings(member: Bool) {
        launch(onboarded: true, member: member)
        let tag = member ? "member" : "free"
        guard openSettings() else { note("settings: no gear"); return }
        captureScrolled("settings_\(tag)", max: 10)
        guard !member else { return }
        let feedback = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Send Feedback")).firstMatch
        guard reach(feedback, swipes: 10) else { note("settings: Send Feedback not reachable"); return }
        // The row can scroll away between the check and the tap; a tap on a
        // vanished element fails the whole run, so look again first.
        guard feedback.waitForExistence(timeout: 2), feedback.isHittable else {
            note("settings: Send Feedback gone before the tap"); return
        }
        feedback.tap()
        settle()
        captureScrolled("feedback_sheet", max: 4)
    }

    private func roomAndFlashcards() {
        launch(onboarded: true, member: false)
        guard openContaining("The Tile Room") else { return }
        captureScrolled("room_tile", max: 6)
        scrollToTop()
        guard openContaining("Meet the Tiles") else { return }
        settle()
        capture("flashcard_front")
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
        settle(1.4)
        capture("flashcard_back")
    }

    /// Get Started: the first question, then a WRONG answer with its miss note,
    /// then the drill-complete screen.
    private func quiz() {
        launch(onboarded: true, member: false)
        guard openContaining("Get Started") else { return }
        settle()
        captureScrolled("quiz_question", max: 4)
        var capturedWrong = false
        var capturedWrongWithNote = false
        for questionIndex in 0..<20 {
            if isOnCompletion { break }
            let choices = choiceButtons()
            guard !choices.isEmpty else {
                note("quiz: no choice buttons on question \(questionIndex + 1)")
                attachTree("quiz_no_choices_\(questionIndex)")
                break
            }
            // The last row is wrong more often than not on a 3 or 4 choice item.
            choices[choices.count - 1].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle(1.6)
            let wrong = app.buttons.matching(NSPredicate(format: "value == %@", "Your answer, wrong")).firstMatch.exists
            let hasNote = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Why not")).firstMatch.exists
            if wrong && (!capturedWrongWithNote && (hasNote || !capturedWrong)) {
                capture(hasNote ? "quiz_wrong_note" : "quiz_wrong")
                captureScrolledFromCurrent(hasNote ? "quiz_wrong_note_scrolled" : "quiz_wrong_scrolled", max: 4)
                capturedWrong = true
                if hasNote { capturedWrongWithNote = true }
            }
            let next = app.buttons["Next"].firstMatch
            let finish = app.buttons["Finish"].firstMatch
            if finish.exists {
                tapElement(finish)
                break
            } else if next.exists {
                tapElement(next)
            } else {
                note("quiz: no Next/Finish after question \(questionIndex + 1)")
                break
            }
        }
        if !capturedWrong { note("quiz: never landed a wrong answer") }
        if !capturedWrongWithNote { note("quiz: no wrong answer carried a miss note") }
        settle(2.0)
        captureScrolled("drill_complete", max: 4)
    }

    private var isOnCompletion: Bool {
        app.buttons["Done"].exists && app.staticTexts["right"].exists
    }

    private func charleston() {
        launch(onboarded: true, member: false)
        guard openContaining("The Charleston Room"), openContaining("Pick Your Pass") else { return }
        settle()
        capture("charleston_deal")
        var picked = 0
        for tile in tileButtons() where picked < 3 {
            tile.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle(0.5)
            picked += 1
        }
        if picked < 3 { note("charleston: only \(picked) tiles found"); attachTree("charleston") }
        capture("charleston_selected")
        guard tapButton("Pass These 3") else { note("charleston: Pass These 3 not reachable"); return }
        settle(2.0)
        capture("charleston_passed")
        captureScrolledFromCurrent("charleston_passed_scrolled", max: 4)
    }

    private func challenge() {
        // The Home card waits for a first finished practice.
        launch(onboarded: true, member: false, sessions: 1)
        guard openContaining("CHALLENGE") else { return }
        settle()
        captureScrolled("challenge_intro", max: 6)
        let start = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Today's Round")).firstMatch
        guard reach(start, swipes: 8) else { note("challenge: Start not reachable"); return }
        start.tap()
        settle()
        captureScrolled("challenge_question", max: 4)
        for questionIndex in 0..<20 {
            let choices = choiceButtons()
            guard !choices.isEmpty else {
                note("challenge: no choices on question \(questionIndex + 1)")
                attachTree("challenge_no_choices_\(questionIndex)")
                return
            }
            choices[0].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle(1.2)
            if questionIndex == 0 { capture("challenge_answered") }
            let finish = app.buttons["Finish"].firstMatch
            let next = app.buttons["Next"].firstMatch
            if finish.exists { tapElement(finish); break }
            guard next.exists else { note("challenge: no Next after question \(questionIndex + 1)"); return }
            tapElement(next)
        }
        settle(2.0)
        captureScrolled("challenge_result", max: 8)
        // Done goes back to the challenge, which now shows today as played,
        // and Home trades the card for the chip.
        if tapButton("Done") {
            settle(1.5)
            captureScrolled("challenge_done", max: 6)
        }
        launch(onboarded: true, member: false, sessions: 1)
        capture("home_after_round")
    }

    private func memberScreens(full: Bool) {
        launch(onboarded: true, member: true)
        captureScrolled("home_member", max: 16)
        guard full else { return }
        settings(member: true)

        launch(onboarded: true, member: true)
        if tapElement(app.buttons["Reference and glossary"].firstMatch) {
            captureScrolled("reference", max: 4)
            if tapElement(app.buttons["Sections"].firstMatch), openContaining("2468 (Evens)") {
                capture("reference_section")
                captureScrolledFromCurrent("reference_section_scrolled", max: 4)
            }
        } else {
            note("no Reference button on Home")
        }

        playHand()

        launch(onboarded: true, member: true)
        if openContaining("Today's Mahj Minute") {
            captureScrolled("mahjminute", max: 6)
            let start = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Today's Mahj Minute")).firstMatch
            if reach(start, swipes: 6) {
                start.tap()
                settle()
                capture("mahjminute_question")
            }
        }
    }

    private func playHand() {
        launch(onboarded: true, member: true)
        if openContaining("Play a") {
            captureScrolled("playhand_deal", max: 6)
            scrollToTop()
            if openContaining("2468 (Evens)") {
                capture("playhand_section_picked")
                if tapButton("Play it out") {
                    settle()
                    capture("playhand_rack")
                    let predicate = NSPredicate(format: "identifier BEGINSWITH 'rack-tile-'")
                    let tile = app.descendants(matching: .any).matching(predicate).firstMatch
                    if tile.waitForExistence(timeout: 3) {
                        tile.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                        settle()
                        capture("playhand_thrown")
                        captureScrolledFromCurrent("playhand_thrown_scrolled", max: 4)
                    } else {
                        note("play a hand: no rack tile")
                    }
                } else {
                    note("play a hand: Play it out not reachable")
                }
            }
        }

    }

    /// The real first-run flow: fresh install, onboard through the free exit,
    /// no tracking prompt on Home, finish one drill, prompt on Home after.
    private func attFlow() {
        app.launchArguments = ["-mahj.previewMetaATT", "-reviewPrompt.launchCount", "0"]
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
        check("no tracking prompt on the first onboarding page", !trackingAlert.waitForExistence(timeout: 3))
        for _ in 0..<3 { _ = tapButton("Continue") }
        if !tapContaining("Know the basics") { note("att: could not pick skill") }
        _ = tapButton("Continue")
        settle()
        check("no tracking prompt on the trial page", !trackingAlert.waitForExistence(timeout: 3))
        capture("att_trial_page")
        guard tapButton("Get Started") else { note("att: no Get Started"); return }
        settle()
        if app.buttons["Skip the tour"].waitForExistence(timeout: 4) {
            _ = tapButton("Skip the tour")
        } else if app.buttons["Skip it, take me to the app"].exists {
            _ = tapButton("Skip it, take me to the app")
        } else {
            note("att: no tour skip")
            attachTree("att_tour")
        }
        settle()
        let onHome = app.staticTexts["THE ROOMS"].waitForExistence(timeout: 6)
        check("reached Home after onboarding", onHome)
        check("no tracking prompt on Home before a finished practice", !trackingAlert.waitForExistence(timeout: 6))
        capture("att_home_before")

        // Finish one drill: Tile Check in the Tile Room.
        guard openContaining("The Tile Room"), openContaining("Tile Check") else { attachTree("att_drill"); return }
        check("no tracking prompt inside a drill", !trackingAlert.exists)
        for questionIndex in 0..<30 {
            let choices = choiceButtons()
            guard !choices.isEmpty else { note("att: no choices on q\(questionIndex + 1)"); attachTree("att_q"); break }
            choices[0].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle(1.0)
            if app.buttons["Finish"].exists { tapElement(app.buttons["Finish"]); break }
            guard app.buttons["Next Question"].exists else { note("att: no Next Question"); break }
            tapElement(app.buttons["Next Question"])
        }
        settle()
        capture("att_drill_complete")
        check("no tracking prompt on the drill-complete screen", !trackingAlert.waitForExistence(timeout: 3))
        _ = tapButton("Done")
        settle()
        // Back to Home if the room is still on top.
        for _ in 0..<3 where !app.staticTexts["THE ROOMS"].exists {
            let back = app.navigationBars.buttons.element(boundBy: 0)
            guard back.exists, back.label != "Settings" else { break }
            back.tap()
            settle(1.0)
        }
        check("back on Home", app.staticTexts["THE ROOMS"].waitForExistence(timeout: 4))
        let shown = trackingAlert.waitForExistence(timeout: 10)
        check("tracking prompt shown on Home after the finished drill", shown)
        capture("att_home_after")
        if shown {
            let text = trackingAlert.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " | ")
            notes.append("prompt text: \(text)")
            let deny = trackingAlert.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Ask App")).firstMatch
            if deny.exists { deny.tap() } else { trackingAlert.buttons.element(boundBy: 0).tap() }
            settle()
        }
    }

    private var trackingAlert: XCUIElement {
        springboard.alerts.matching(NSPredicate(format: "label CONTAINS %@", "track")).firstMatch
    }

    /// Times the primitives the sweep leans on, for debugging a stall.
    private func probe() {
        launch(fresh: true)
        timed("signature") { _ = signature() }
        timed("capture") { capture("probe_1") }
        timed("checkEdges") { checkEdges("probe") }
        timed("scroll") { scroll(up: true) }
        timed("signature2") { _ = signature() }
        timed("tapContinue") { _ = tapButton("Continue") }
        timed("capture2") { capture("probe_2") }
    }

    private func timed(_ label: String, _ body: () -> Void) {
        let start = Date()
        notes.append("start \(label)")
        body()
        notes.append("\(label): \(String(format: "%.1f", Date().timeIntervalSince(start)))s")
    }

    // MARK: - Launch

    private func launch(fresh: Bool = false, onboarded: Bool = true, member: Bool = false, whatsNew: Bool = false, sessions: Int? = nil) {
        app.terminate()
        var args: [String] = ["-reviewPrompt.launchCount", "0", "-ChallengeMonth", "2026-11"]
        if !fresh {
            args += [
                "-progress.hasOnboarded", onboarded ? "YES" : "NO",
                "-subscription.localProOverride", member ? "YES" : "NO",
                "-mahj.skillLevel", "some",
                "-mahj.hasReadPrimer", "YES",
            ]
            // An upgrader: onboarded, no stored marker.
            args += whatsNew ? ["-whatsnew.lastSeenVersion", ""] : ["-mahj.suppressWhatsNew"]
            if let sessions { args += ["-progress.totalSessions", "\(sessions)", "-progress.sessionsAtOnboarding", "0"] }
        } else {
            args += ["-subscription.localProOverride", "NO"]
        }
        if let sizeCategory {
            args += ["-UIPreferredContentSizeCategoryName", sizeCategory]
        }
        app.launchArguments = args
        XCUIDevice.shared.orientation = landscape ? .landscapeLeft : .portrait
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle(2.0)
        dismissSystemAlerts()
    }

    private func dismissSystemAlerts() {
        let alert = springboard.alerts.firstMatch
        guard alert.exists else { return }
        note("system alert at launch: \(alert.label)")
        let deny = alert.buttons.matching(NSPredicate(format: "label IN %@", ["Don’t Allow", "Don't Allow", "Ask App Not to Track", "Not Now"])).firstMatch
        if deny.exists { deny.tap() }
        settle(0.6)
    }

    // MARK: - Navigation helpers

    private func openSettings() -> Bool {
        let gear = app.navigationBars.buttons["Settings"].firstMatch
        guard gear.waitForExistence(timeout: 6) else { return false }
        gear.tap()
        settle(1.4)
        return true
    }

    /// Taps the first element whose label contains `label`, scrolling down to
    /// find it if it is not hittable.
    @discardableResult
    private func openContaining(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            guard match.waitForExistence(timeout: 5) else { continue }
            if reach(match, swipes: 14) {
                match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                settle()
                return true
            }
        }
        note("could not open: \(label)")
        attachTree("open_\(label.replacingOccurrences(of: " ", with: "_"))")
        return false
    }

    @discardableResult
    private func tapContaining(_ label: String) -> Bool {
        let match = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch
        guard match.waitForExistence(timeout: 3) else { return false }
        guard reach(match, swipes: 6) else { return false }
        match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        settle(0.8)
        return true
    }

    /// Taps a button by exact label. Records when it exists but cannot be
    /// brought on screen: that is an unreachable control.
    @discardableResult
    private func tapButton(_ label: String) -> Bool {
        let button = app.buttons[label].firstMatch
        guard button.waitForExistence(timeout: 5) else { return false }
        guard reach(button, swipes: 8) else {
            note("UNREACHABLE button '\(label)' frame=\(button.frame)")
            capture("unreachable_\(label.replacingOccurrences(of: " ", with: "_"))")
            return false
        }
        button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        settle(1.0)
        return true
    }

    @discardableResult
    private func tapElement(_ element: XCUIElement) -> Bool {
        guard element.waitForExistence(timeout: 5) else { return false }
        guard reach(element, swipes: 6) else {
            note("UNREACHABLE '\(element.label)' frame=\(element.frame)")
            return false
        }
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        settle(1.0)
        return true
    }

    /// Scrolls until the element is fully inside the window.
    private func reach(_ element: XCUIElement, swipes: Int) -> Bool {
        guard element.exists else { return false }
        for _ in 0...swipes {
            if isOnScreen(element) { return true }
            let window = app.windows.firstMatch.frame
            if element.frame.minY < window.minY + 60 {
                scroll(up: false)
            } else {
                scroll(up: true)
            }
        }
        return isOnScreen(element)
    }

    /// Buttons that live in a pinned footer, where the footer clearance below
    /// does not apply.
    private let pinnedLabels: Set<String> = [
        "Continue", "Show me", "Take your seat", "Next", "Finish", "Next Question", "Pass These 3",
        "Next Deal", "Next turn", "Play it out", "Start my first session", "Skip for now",
        "Skip the tour", "Skip it, take me to the app", "Done", "See how you did",
    ]

    private func isOnScreen(_ element: XCUIElement) -> Bool {
        // Frame-based: SwiftUI reports isHittable false for plenty of
        // tappable controls, which made a visible button read as unreachable.
        guard element.exists else { return false }
        let frame = element.frame
        guard !frame.isEmpty else { return false }
        guard !landscape else { return true }
        let window = app.windows.firstMatch.frame
        // Clear of the pinned footers too: a frame that is "on screen" but
        // under a pinned Continue / trial button passes the tap through to it.
        let footer: CGFloat = pinnedLabels.contains(element.label) ? 4 : (isAccessibilitySize ? 200 : 140)
        return frame.midY > window.minY + 90 && frame.midY < window.maxY - footer
            && frame.midX > window.minX && frame.midX < window.maxX
    }

    /// A precise, momentum-free drag: about half a screen per call.
    private func scroll(up: Bool) {
        let window = app.windows.firstMatch
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.72 : 0.30))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.30 : 0.72))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.15)
        settle(0.5)
    }

    private func scrollToTop() {
        var last = signature()
        for _ in 0..<20 {
            scroll(up: false)
            let now = signature()
            if same(now, last) { return }
            last = now
        }
    }

    /// Visible choice rows in a question: wide buttons in the content area.
    private func choiceButtons() -> [XCUIElement] {
        let window = app.windows.firstMatch.frame
        let excluded: Set<String> = ["Next", "Finish", "Close", "Back", "Settings", "Done", "Next Question"]
        var result: [XCUIElement] = []
        for attempt in 0..<4 {
            result = app.buttons.allElementsBoundByIndex.filter { element in
                let label = element.label
                guard !label.isEmpty, !excluded.contains(label), !label.contains("wrong?") else { return false }
                let frame = element.frame
                return frame.width > window.width * 0.3
                    && frame.minY > window.minY + 80
                    && frame.midY < window.maxY - (isAccessibilitySize ? 200 : 140)
            }
            if !result.isEmpty || attempt == 3 { break }
            scroll(up: true)
        }
        return result
    }

    private func tileButtons() -> [XCUIElement] {
        app.buttons.allElementsBoundByIndex.filter { element in
            let frame = element.frame
            return !element.label.isEmpty && frame.width < 90 && frame.height < 130 && frame.width > 20
                && frame.minY > 120 && frame.maxY < app.windows.firstMatch.frame.maxY - 20
                && !["Settings", "Back", "Close"].contains(element.label)
        }
    }

    // MARK: - Capture

    private func step(_ name: String, _ body: () -> Void) {
        currentStep = name
        let start = Date()
        body()
        notes.append("step \(name) took \(Int(Date().timeIntervalSince(start)))s")
    }

    private func note(_ text: String) {
        notes.append("[\(currentStep)] \(text)")
    }

    private func check(_ what: String, _ ok: Bool) {
        notes.append("\(ok ? "PASS" : "FAIL") \(what)")
    }

    private func captureScrolled(_ name: String, max: Int = 6) {
        captureScrolledFrom(name, start: 0, max: max)
    }

    private func captureScrolledFromCurrent(_ name: String, max: Int) {
        // Only adds frames when there is somewhere to scroll.
        let before = signature()
        scroll(up: true)
        guard !same(signature(), before) else { return }
        captureScrolledFrom(name, start: 1, max: max)
    }

    private func captureScrolledFrom(_ name: String, start: Int, max: Int) {
        var last = signature()
        capture(start == 0 ? name : "\(name)_p\(start)")
        checkEdges(name)
        for page in (start + 1)..<(start + max) {
            scroll(up: true)
            let now = signature()
            if same(now, last) { break }
            last = now
            capture("\(name)_p\(page)")
            checkEdges("\(name)_p\(page)")
        }
    }

    /// A cheap fingerprint of the screen: a 24x48 grayscale thumbnail. Two
    /// thumbnails that barely differ mean a scroll moved nothing. (A full
    /// accessibility snapshot took 30 to 90 seconds per call here.)
    private func signature() -> [UInt8] {
        let image = XCUIScreen.main.screenshot().image
        guard let cgImage = image.cgImage else { return [] }
        let width = 24, height = 48
        var pixels = [UInt8](repeating: 0, count: width * height)
        let space = CGColorSpaceCreateDeviceGray()
        pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width, space: space, bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else { return }
            context.interpolationQuality = .medium
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return pixels
    }

    private func same(_ a: [UInt8], _ b: [UInt8]) -> Bool {
        guard a.count == b.count, !a.isEmpty else { return false }
        var total = 0
        for index in a.indices { total += abs(Int(a[index]) - Int(b[index])) }
        return Double(total) / Double(a.count) < 1.5
    }

    /// Kept as a no-op hook: the accessibility snapshot it needed was too slow.
    private func checkEdges(_ name: String) {}

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "shot_\(name)"
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func attachTree(_ name: String) {
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "tree_\(name)"
        tree.lifetime = .keepAlways
        add(tree)
    }

    private func settle(_ seconds: TimeInterval = 1.6) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
