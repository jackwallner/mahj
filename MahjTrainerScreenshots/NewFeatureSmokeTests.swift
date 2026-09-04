import XCTest

/// A walkthrough of the screens added in this change, captured from the real
/// app so a layout that only breaks at runtime cannot pass a green unit suite.
///
/// Same rules as `ScreenshotTests`: never `XCTFail` on a missing element (a
/// failing UI test spends ten minutes collecting simulator diagnostics before
/// it tells you anything), record what could not be reached instead, and
/// attach the element tree so one run explains itself.
@MainActor
final class NewFeatureSmokeTests: XCTestCase {
    private var app: XCUIApplication!
    private var problems: [String] = []

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = [
            "-progress.hasOnboarded", "YES",
            "-mahj.hasReadPrimer", "YES",
            "-mahj.skillLevel", "some",
            // Play a Hand gives a free player ONE hand a day, and the marker
            // survives between runs, so a second run would walk into the
            // paywall instead of the deal. Clearing it keeps the walk
            // repeatable without weakening the gate itself.
            "-handplay.lastFreeDay", "",
        ]
        if let version = ProcessInfo.processInfo.environment["SCREENSHOT_APP_VERSION"] {
            app.launchArguments += ["-whatsnew.lastSeenVersion", version]
        }
        app.launch()
    }

    func testWalkTheNewScreens() {
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
        dismissWhatsNew()
        capture("10_home")

        // The reference lives in the toolbar so it costs Home no space.
        if tap(app.buttons["Reference and glossary"]) {
            capture("11_glossary")
            if tap(app.buttons["Sections"]) {
                capture("12_sections")
            }
            back()
        } else {
            problems.append("no reference button on Home")
        }

        if open("Play a") {
            capture("13_hand_deal")
            if open("2468") {
                capture("14_coach_read")
                if open("Play it out") {
                    capture("15_playing")
                }
            }
            back()
        }

        home()
        if open("The Card Room"), open("Read the Rack") {
            capture("16_rack_question")
        }

        attachTree("final")
        if !problems.isEmpty {
            let note = XCTAttachment(string: problems.joined(separator: "\n"))
            note.name = "problems"
            note.lifetime = .keepAlways
            add(note)
        }
    }

    // MARK: - Helpers

    private func dismissWhatsNew() {
        let done = app.buttons["Done"].firstMatch
        guard done.waitForExistence(timeout: 3) else { return }
        done.tap()
        settle()
    }

    @discardableResult
    private func tap(_ element: XCUIElement) -> Bool {
        guard element.waitForExistence(timeout: 6) else { return false }
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        settle()
        return true
    }

    /// Taps the first element whose label contains `label`, scrolling once if
    /// the first attempt lands off screen. Play a Hand deals a random rack, so
    /// how far down the section list starts changes between runs, and a tap at
    /// an off-screen coordinate silently does nothing.
    @discardableResult
    private func open(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for attempt in 0..<2 {
            for query in [app.buttons, app.staticTexts] {
                let match = query.matching(predicate).firstMatch
                guard match.waitForExistence(timeout: attempt == 0 ? 6 : 2) else { continue }
                // Deliberately NOT gated on isHittable: SwiftUI cards report
                // false often enough that trusting it costs a whole run. The
                // retry below is what handles a genuinely off-screen target.
                match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                settle()
                return true
            }
            app.swipeUp()
            settle()
        }
        problems.append("could not open: \(label)")
        return false
    }

    private func back() {
        let button = app.navigationBars.buttons.element(boundBy: 0)
        if button.exists, button.label != "Settings" {
            button.tap()
            settle()
        }
    }

    private func home() {
        for _ in 0..<4 {
            if app.staticTexts["Get Started"].exists || app.staticTexts["Today's session is done"].exists {
                return
            }
            back()
        }
    }

    private func settle() {
        _ = app.wait(for: .runningForeground, timeout: 2)
        RunLoop.current.run(until: Date().addingTimeInterval(1.1))
    }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func attachTree(_ name: String) {
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "tree_\(name)"
        tree.lifetime = .keepAlways
        add(tree)
    }
}
