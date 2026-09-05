import XCTest

/// Captures the App Store screenshot set from the real app, on whatever
/// destination `xcodebuild test` is pointed at. Exists because the iPad shots
/// have to be re-captured whenever a drill layout changes, and re-shooting six
/// screens by hand is how you end up shipping a stale set.
///
/// Run: scripts/capture-screenshots.sh <udid> <out-dir> [prefix]
///
/// Not part of the MahjTrainer scheme's test action — it lives on its own
/// `Screenshots` scheme so the unit-test loop stays fast.
///
/// The test never fails on a missing element. A hard XCTFail makes Xcode spend
/// ten minutes collecting simulator diagnostics before it reports anything,
/// which turns every navigation typo into a very slow question. Instead it
/// records what it could not find and attaches the element tree, so one run
/// tells you both what you got and why the rest is missing.
@MainActor
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!
    private var problems: [String] = []

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        // The `-key value` form lands in UserDefaults' argument domain, so the
        // app boots past onboarding without a debug hook in shipping code.
        app.launchArguments = [
            "-progress.hasOnboarded", "YES",
            "-mahj.hasReadPrimer", "YES",
            "-mahj.skillLevel", "some",
            // Play a Hand spends a free player's one hand a day the moment
            // play begins, and saves an unfinished hand across launches. Both
            // markers survive between runs, so without clearing them the
            // second capture run of the day photographs the paywall or resumes
            // somebody else's half-played rack instead of a fresh deal.
            "-handplay.lastFreeDay", "",
            "-handplay.inProgress", "",
        ]
        // The What's New sheet fires on the first launch after a version bump
        // and covers Home. Marking the CURRENT version as already seen is what
        // suppresses it — any other value still counts as an upgrade — so the
        // capture script passes the real marketing version in.
        if let version = ProcessInfo.processInfo.environment["SCREENSHOT_APP_VERSION"] {
            app.launchArguments += ["-whatsnew.lastSeenVersion", version]
        }
        app.launch()
    }

    func testCaptureAppStoreSet() {
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
        dismissWhatsNew()
        capture("06_home")
        attachTree("home")

        if open("Get Started") {
            capture("01_quick_session")
        }
        home()

        // Second in the set on purpose. Play a Hand is what 1.3 added and the
        // only screen that shows the app judging a decision rather than
        // testing recognition, and the first three frames are the ones that
        // appear in search results.
        capturePlayAHand()
        home()

        if open("The Card Room"), open("Read the Rack") {
            capture("03_hand_match")
        }
        home()

        if open("The Table Room"), open("Keep or Throw") {
            capture("04_keep_or_throw")
        }
        home()

        if open("The Charleston Room"), open("Pick Your Pass") {
            capture("05_charleston")
        }
        home()

        captureReference()
        home()

        if open("The Tile Room") {
            capture("08_tile_room")
        }

        if !problems.isEmpty {
            let note = XCTAttachment(string: problems.joined(separator: "\n"))
            note.name = "problems"
            note.lifetime = .keepAlways
            add(note)
        }
    }

    /// The graded throw, not the deal. The deal is thirteen tiles and a list of
    /// section names, which reads like every other rack screen in the set; the
    /// frame worth having is the one where the coach has just marked a discard
    /// and said why, because that is the thing no other drill in the app does.
    private func capturePlayAHand() {
        // "Play a" and not "Play a Hand": the Home tile wraps the title, so the
        // accessibility label carries a real newline between the two words and
        // the full string matches nothing.
        guard open("Play a") else { return }
        guard open("2468 (Evens)"), open("Play it out") else {
            problems.append("could not start the hand for the Play a Hand shot")
            attachTree("play_a_hand")
            return
        }
        guard throwATile() else {
            problems.append("no rack tile to throw for the Play a Hand shot")
            attachTree("play_a_hand_rack")
            return
        }
        capture("02_play_a_hand")
    }

    /// Tapped through the element types a rack tile can surface as. It is a
    /// real button first (the rack carries an accessibility action), and the
    /// rest are the fallback for a rack that is only being displayed.
    private func throwATile() -> Bool {
        let predicate = NSPredicate(format: "identifier BEGINSWITH 'rack-tile-'")
        for query in [app.buttons, app.otherElements, app.images, app.staticTexts] {
            let tile = query.matching(predicate).firstMatch
            guard tile.waitForExistence(timeout: 3) else { continue }
            tile.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            return true
        }
        return false
    }

    /// The Sections tab with one card open, not the glossary list. Both are the
    /// same feature, but an expanded section draws a real example rack, and
    /// tiles are the only illustration this app has.
    private func captureReference() {
        guard tap(app.buttons["Reference and glossary"]) else {
            problems.append("no reference button on Home")
            return
        }
        if tap(app.buttons["Sections"]), open("2468 (Evens)") {
            capture("07_reference")
        } else {
            problems.append("could not open a reference section")
            attachTree("reference")
        }
    }

    @discardableResult
    private func tap(_ element: XCUIElement) -> Bool {
        guard element.waitForExistence(timeout: 6) else { return false }
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        settle()
        return true
    }

    // MARK: - Navigation

    /// The What's New sheet fires on the first launch after a version bump and
    /// covers Home completely. Pinning `whatsnew.lastSeenVersion` from the
    /// launch arguments would mean hardcoding the marketing version here and
    /// re-breaking capture on every release, so just dismiss it.
    private func dismissWhatsNew() {
        // Belt and braces for a version the script could not resolve. Dismissing
        // does not mark the release seen, so the sheet returns every time Home
        // reappears; the launch argument above is the real fix.
        let done = app.buttons["Done"].firstMatch
        guard done.waitForExistence(timeout: 3) else { return }
        done.tap()
        settle()
    }

    /// Taps the first hittable element whose label starts with `label`.
    /// Home's cards are NavigationLinks with stacked title + subtitle, so the
    /// accessibility label is the whole card, not just the title.
    @discardableResult
    private func open(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        // Two passes: as found, then again after one scroll. Home grew a
        // training row and a fourth room card, so the card being reached for is
        // no longer guaranteed to be above the fold on a 6.1-inch phone, and a
        // coordinate tap at an off-screen frame silently does nothing.
        for attempt in 0..<2 {
            for query in [app.buttons, app.staticTexts] {
                let match = query.matching(predicate).firstMatch
                guard match.waitForExistence(timeout: attempt == 0 ? 6 : 2) else { continue }
                guard match.isHittable || attempt == 1 else { continue }
                // Tap the centre of the frame rather than the element. SwiftUI
                // cards report isHittable false often enough that trusting it
                // costs a whole capture run, and a coordinate tap lands the
                // same place.
                match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                settle()
                return true
            }
            guard attempt == 0 else { break }
            app.swipeUp()
            settle(0.8)
        }
        problems.append("could not open: \(label)")
        return false
    }

    /// Pops back to the root, recognising Home by its Get Started card.
    ///
    /// Do NOT just tap navigation-bar button 0 until it runs out: on Home that
    /// button is the Settings gear, so the extra tap opens Settings, and every
    /// later coordinate tap then lands on the Settings sheet while the elements
    /// underneath still answer queries. That failure looks exactly like a
    /// mislabelled drill row, which is a slow thing to debug.
    private func home() {
        for _ in 0..<4 {
            if atHome { return }
            let done = app.buttons["Done"].firstMatch
            if done.exists {
                done.tap()
                settle(0.6)
                continue
            }
            let back = app.navigationBars.buttons.element(boundBy: 0)
            guard back.exists, back.identifier != "gearshape" else { return }
            back.tap()
            settle(0.6)
        }
    }

    private var atHome: Bool {
        app.staticTexts.matching(NSPredicate(format: "label == %@", "THE ROOMS")).firstMatch.exists
    }

    /// Let the push transition and any entrance animation finish before the
    /// shutter: a mid-transition frame is a blurred, half-offset screenshot.
    private func settle(_ seconds: TimeInterval = 1.6) {
        Thread.sleep(forTimeInterval: seconds)
    }

    // MARK: - Capture

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
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
