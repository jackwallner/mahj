import XCTest

/// Walks the screens added in 1.3 in the real app, all the way through rather
/// than to the first interesting frame, because a green unit suite says nothing
/// about a view that only breaks when it is actually reached. Specifically: a
/// whole twelve-turn hand to its verdict, a deliberately WRONG answer so the
/// miss coaching renders, and the stats screen after enough practice to have
/// something to show.
///
/// Same rules as `ScreenshotTests`: never `XCTFail` on a missing element (a
/// failing UI test spends ten minutes collecting simulator diagnostics before
/// it tells you anything), record what could not be reached instead, and
/// attach the element tree so one run explains itself.
@MainActor
final class NewFeatureSmokeTests: XCTestCase {
    /// xcodebuild's `TEST_RUNNER_FOO=bar` did not reach this process under
    /// either spelling, and an `XCTSkip` on a missing variable still reports
    /// the run as a pass, so the member walk skipped silently twice while the
    /// command said EXIT=0. Which walk this is now comes from the test's own
    /// name, which cannot go missing.
    private var isMemberWalk: Bool { name.contains("Member") }

    private static func setting(_ name: String) -> String? {
        let environment = ProcessInfo.processInfo.environment
        return environment[name] ?? environment["TEST_RUNNER_\(name)"]
    }

    private var app: XCUIApplication!
    private var problems: [String] = []

    /// Mirrors `HandPlayEngine.turnCount`, which a UI test target cannot import.
    private let handPlayTurns = 12

    /// The defaults key holding an unfinished hand, as a launch-argument
    /// override. Present, it hides any saved hand; absent, the real one is read.
    private static let resumeArgument = "-handplay.inProgress"

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
            // Likewise a hand left unfinished by an earlier test or an earlier
            // run: it would resume straight into play and every walk that
            // expects the deal would find no sections to commit to. The one
            // test that WANTS the saved hand drops this argument for its
            // second launch (see `resumeArgument`).
            Self.resumeArgument, "",
        ]
        if let version = Self.setting("SCREENSHOT_APP_VERSION") {
            app.launchArguments += ["-whatsnew.lastSeenVersion", version]
        }
        if isMemberWalk {
            // The same defaults key the Settings dev toggle writes, so the
            // member walk exercises the real gate rather than a parallel one.
            app.launchArguments += ["-subscription.localProOverride", "YES"]
        }
        app.launch()
    }

    // MARK: - The free player's walk

    func testWalkTheNewScreens() {
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
        dismissWhatsNew()
        capture("10_home")

        walkTheReference()
        playAWholeHand()
        answerARackQuestionWrong()
        readTheStats()

        attachTree("final")
        reportProblems()
    }

    private func walkTheReference() {
        guard tap(app.buttons["Reference and glossary"]) else {
            problems.append("no reference button on Home")
            return
        }
        capture("11_glossary")

        // The search field is the whole point of a glossary: a term nobody can
        // find is a term nobody reads.
        let field = app.searchFields.firstMatch
        if field.waitForExistence(timeout: 4) {
            field.tap()
            field.typeText("soap")
            settle()
            capture("12_glossary_search")
            if !app.staticTexts["Soap"].exists {
                problems.append("searching 'soap' did not surface the Soap entry")
            }
            let clear = app.buttons["Clear text"].firstMatch
            if clear.exists { clear.tap() }
            settle()
        } else {
            problems.append("no search field in the reference")
        }

        if tap(app.buttons["Sections"]) {
            capture("13_sections")
            // The section cards are collapsed; the example rack only exists
            // once one is opened.
            if open("2468 (Evens)") {
                capture("14_section_expanded")
                if !app.staticTexts["AN EXAMPLE OF THE SHAPE"].exists {
                    problems.append("expanding a section did not reveal its example rack")
                }
            }
        }
        back()
    }

    /// The whole point of this file. Plays every turn through to the verdict.
    private func playAWholeHand() {
        home()
        guard open("Play a") else {
            problems.append("could not open Play a Hand")
            return
        }
        capture("20_hand_deal")

        guard open("2468 (Evens)") else {
            problems.append("could not commit to a section")
            return
        }
        capture("21_coach_read")

        guard open("Play it out") else {
            problems.append("could not start the hand")
            return
        }

        for turn in 1...handPlayTurns {
            guard throwATile() else {
                problems.append("turn \(turn): no tile to throw")
                attachTree("stuck_in_hand")
                return
            }
            if turn == 1 { capture("22_first_throw_graded") }

            let isLast = turn == handPlayTurns
            let next = isLast ? "See how you did" : "Next turn"
            guard open(next) else {
                problems.append("turn \(turn): no '\(next)' button")
                return
            }
        }

        capture("23_verdict")
        // The verdict screen is the payoff, and the only screen the unit tests
        // cannot see at all.
        for expected in ["tiles fit", "clean throws", "YOUR FINAL RACK"] where !exists(expected) {
            problems.append("verdict screen is missing '\(expected)'")
        }
        if !exists("That was today's free hand") {
            problems.append("free player did not get the spent-hand upsell after their hand")
        }
        capture("24_after_verdict")
        back()
    }

    /// Taps a rack tile. Which one does not matter here: what is being checked
    /// is that a throw grades, coaches, and lets the hand continue.
    ///
    /// `buttons` comes first because a throwable tile IS a button: the rack
    /// carries a real accessibility action and a selected state, so VoiceOver
    /// and Switch Control can play the mode. The other queries stay as a
    /// fallback for racks that are only being displayed.
    ///
    /// Queried through these element types and NEVER through
    /// `descendants(matching: .any)`. The unbounded query walks the whole
    /// accessibility tree on every `exists`, and at fourteen tiles times twelve
    /// turns that alone runs the test past the harness timeout.
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

    /// Every section name the card system has. A hand-match question offers
    /// only three or four of them, and which ones depends on the question, so
    /// a hardcoded shortlist finds nothing on most of them.
    private static let allSections = [
        "Year Hands", "2468 (Evens)", "Any Like Numbers", "Quints",
        "Consecutive Run", "13579 (Odds)", "Winds & Dragons", "369",
        "Singles & Pairs",
    ]

    /// Taps whichever section choice this question actually offers, starting
    /// the search at a rotating offset.
    ///
    /// The rotation is the point. Scanning a fixed list from the top picked
    /// "2468 (Evens)" on every question, which is a common right answer, so
    /// six attempts in a row came back correct and the miss path went
    /// unexercised while the run reported success.
    @discardableResult
    private func tapASectionChoice(offset: Int) -> String? {
        let order = (0..<Self.allSections.count).map { Self.allSections[($0 + offset) % Self.allSections.count] }
        for label in order {
            let button = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch
            guard button.exists else { continue }
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            return label
        }
        return nil
    }

    /// Deliberately picks a section the rack cannot be, so the "Why not X?"
    /// card and the review chip render. Neither appears on a correct answer.
    private func answerARackQuestionWrong() {
        home()
        guard open("The Card Room"), open("Read the Rack") else {
            problems.append("could not open Read the Rack")
            return
        }
        settle()

        // Keep answering until one lands wrong. Picking blind gets it right
        // often enough that a single attempt is not a test of the miss path.
        var sawAMiss = false
        var answers = 0
        for attempt in 0..<6 {
            guard tapASectionChoice(offset: attempt * 2) != nil else {
                if attempt == 0 { problems.append("no section buttons on the rack question") }
                break
            }
            answers += 1
            if attempt == 0 { capture("30_answer_graded") }

            if exists("Why not") {
                sawAMiss = true
                capture("31_miss_coaching")
                // The reason is no longer behind a disclosure, so the whole
                // card, last line included, has to be legible without a tap.
                if !exists("Saved to Fix My Mistakes") {
                    problems.append("a miss did not show the review chip")
                }
                if !open("Next Rack") { break }
            } else if !open("Next Rack") {
                break
            }
        }
        if answers == 0 {
            return
        }
        if !sawAMiss {
            problems.append("never managed a wrong answer in 6 tries, so the miss coaching went unchecked")
        }
        home()
    }

    private func readTheStats() {
        home()
        capture("40_home_after_practice")
        let chips = app.buttons.matching(NSPredicate(format: "label CONTAINS 'streak'")).firstMatch
        guard chips.waitForExistence(timeout: 5) else {
            problems.append("could not find the stats chips on Home")
            return
        }
        chips.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        settle()
        capture("41_stats")
        if !exists("WHAT IS HOLDING") {
            problems.append("Your Progress is missing the mastery breakdown")
        }
        app.swipeUp()
        settle()
        capture("42_stats_scrolled")
        back()
    }

    // MARK: - Regressions the unit tests cannot reach

    /// A started hand has already cost a free player their hand for the day, so
    /// walking out of it, or having the app killed, must not take the hand with
    /// it. Terminates the app outright rather than backing out, because a back
    /// swipe would not prove the state survives anywhere but memory.
    func testAnAbandonedHandIsWaitingOnTheNextLaunch() {
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
        dismissWhatsNew()

        guard open("Play a") else {
            problems.append("could not open Play a Hand")
            reportProblems()
            return
        }
        capture("59_hand_setup")
        // A hand left over from an earlier run opens straight into play, which
        // is the very behaviour under test, so only deal a fresh one when the
        // setup screen is actually there.
        if exists("COMMIT TO A SECTION") {
            guard open("2468 (Evens)"), open("Play it out") else {
                problems.append("could not start the hand")
                attachTree("failed_start")
                reportProblems()
                return
            }
        }
        capture("60_hand_in_progress")

        // Relaunch WITHOUT the override, so the app reads the hand it actually
        // saved. This is the whole test.
        if let index = app.launchArguments.firstIndex(of: Self.resumeArgument) {
            app.launchArguments.removeSubrange(index...(index + 1))
        }
        app.terminate()
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
        dismissWhatsNew()
        capture("61_home_after_kill")

        if !exists("Resume") {
            problems.append("Home does not offer to resume the hand that was already paid for")
        }
        guard open("Play a") else {
            problems.append("the started hand could not be reopened at all")
            reportProblems()
            return
        }
        capture("62_hand_resumed")
        if !exists("Turn ") {
            problems.append("reopening did not land back in the hand; it re-dealt or showed the setup")
            attachTree("failed_resume")
            reportProblems()
            return
        }

        // The other half of the same promise. A throw is graded, coached, and
        // counted in the player's stats the instant it lands, so being killed
        // while the coaching card is up must not rewind to before the throw:
        // that hands the same turn back to be answered, and counted, twice.
        guard throwATile() else {
            problems.append("could not throw a tile in the resumed hand")
            attachTree("failed_resumed_throw")
            reportProblems()
            return
        }
        capture("63_throw_graded")
        guard exists("Next turn") || exists("See how you did") else {
            problems.append("the throw did not grade")
            reportProblems()
            return
        }

        app.terminate()
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
        dismissWhatsNew()
        guard open("Play a") else {
            problems.append("the graded hand could not be reopened")
            reportProblems()
            return
        }
        capture("64_graded_throw_resumed")
        if exists("Tap the tile you want to throw") {
            problems.append("resuming rewound past a graded throw; the player has to answer it again")
            attachTree("failed_grade_resume")
        }
        if !exists("Next turn") && !exists("See how you did") {
            problems.append("the coaching card for the graded throw did not survive termination")
            attachTree("failed_grade_card")
        }
        reportProblems()
    }

    /// The clock used to start with the screen, so the first read of the first
    /// question came out of the ninety seconds. Timed Challenge is Mahj+ gated,
    /// hence the member name.
    func testMemberStartsTheTimedClockThemselves() {
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
        dismissWhatsNew()

        guard openTrainingTile("Timed") else {
            problems.append("could not reach Timed Challenge on Home")
            reportProblems()
            return
        }
        capture("63_timed_ready")
        if !exists("Ready?") {
            problems.append("Timed Challenge did not wait for the player before starting the clock")
        }
        guard open("Start the clock") else {
            problems.append("the ready screen had no way to start")
            reportProblems()
            return
        }
        settle()
        capture("64_timed_running")
        if !exists("correct") {
            problems.append("no running clock or score after starting")
        }
        back()
        reportProblems()
    }

    /// The training row scrolls sideways, so `open` (which only swipes up, and
    /// deliberately taps whether or not the target is hittable) cannot reach
    /// the tiles past the second one. Here hittability is exactly the question,
    /// so this one does gate on it.
    private func openTrainingTile(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        let tile = app.buttons.matching(predicate).firstMatch
        guard tile.waitForExistence(timeout: 6) else { return false }
        for _ in 0..<5 {
            if tile.isHittable {
                tile.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                settle()
                return true
            }
            app.scrollViews.element(boundBy: 1).swipeLeft()
            settle()
        }
        return false
    }

    // MARK: - The member's walk

    /// Endless Practice is Mahj+ gated, so the free walk can only ever see its
    /// lock. The two generated skills added in 1.3 live behind it.
    func testMemberSeesTheNewEndlessSkills() {
        // No skip guard and no environment switch: this test IS the member
        // walk, and `setUp` gives it the entitlement from its own name.
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
        dismissWhatsNew()
        capture("50_member_home")

        guard open("Endless") else {
            problems.append("Endless Practice did not open for a member")
            reportProblems()
            return
        }
        capture("51_endless_picker")
        for skill in ["Pass the Junk", "Read the Exposures"] where !exists(skill) {
            problems.append("Endless picker is missing \(skill)")
        }

        for (skill, shot) in [("Pass the Junk", "52_generated_pass"), ("Read the Exposures", "54_generated_defense")] {
            guard open(skill) else {
                problems.append("could not open \(skill)")
                continue
            }
            capture(shot)
            answerAnything()
            capture("\(shot)_graded")
            // An endless run has no natural end, so Finish is its only exit.
            if !open("Finish") { problems.append("\(skill) had no way out") }
            settle()
            // Finish lands on the completion screen; from there back to the
            // picker, which is where the next skill lives.
            if !open("Done") { back() }
            settle()
            // Get all the way back to the picker before the next skill. Under a
            // long run the completion screen sometimes needs a second back, and
            // one missed step made the NEXT skill report itself as missing when
            // the only thing wrong was where the test was standing.
            for _ in 0..<3 where !exists("Read the Rack") {
                back()
                settle()
            }
            if !exists("Read the Rack") {
                home()
                _ = open("Endless")
            }
        }

        attachTree("member_final")
        reportProblems()
    }

    /// Taps the first answer row of a generated question, right or wrong.
    ///
    /// Everything in the navigation bar is excluded BY POSITION, not by a list
    /// of labels. The label list missed the back button, so the first thing
    /// this tapped was Back: the run left the drill, reported "no way out",
    /// and then could not find the next skill either. Two failures, one cause,
    /// neither of them in the app.
    private func answerAnything() {
        let chrome = Set(app.navigationBars.buttons.allElementsBoundByIndex.map(\.label)
            + ["Finish", "Close", "Next", "Done"])
        for button in app.buttons.allElementsBoundByIndex {
            let label = button.label
            guard !label.isEmpty, !chrome.contains(label), button.isHittable else { continue }
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            return
        }
        problems.append("no answer row to tap")
    }

    // MARK: - Helpers

    private func dismissWhatsNew() {
        let done = app.buttons["Done"].firstMatch
        guard done.waitForExistence(timeout: 3) else { return }
        done.tap()
        settle()
    }

    /// Text on screen, wherever it lives. SwiftUI puts a label on a static text
    /// or on the button wrapping it depending on the container, so checking one
    /// query is how a present string reads as missing.
    private func exists(_ text: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        for query in [app.staticTexts, app.buttons, app.otherElements] where
            query.matching(predicate).firstMatch.exists {
            return true
        }
        return false
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
                guard match.waitForExistence(timeout: attempt == 0 ? 4 : 1) else { continue }
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
        return false
    }

    private func back() {
        let button = app.navigationBars.buttons.element(boundBy: 0)
        if button.exists, !["Settings", "Reference and glossary"].contains(button.label) {
            button.tap()
            settle()
        }
    }

    private func home() {
        for _ in 0..<5 {
            if app.staticTexts["Get Started"].exists || app.staticTexts["Today's session is done"].exists {
                return
            }
            back()
        }
    }

    private func settle() {
        _ = app.wait(for: .runningForeground, timeout: 2)
        RunLoop.current.run(until: Date().addingTimeInterval(0.9))
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

    private func reportProblems() {
        guard !problems.isEmpty else { return }
        let note = XCTAttachment(string: problems.joined(separator: "\n"))
        note.name = "problems"
        note.lifetime = .keepAlways
        add(note)
    }
}
