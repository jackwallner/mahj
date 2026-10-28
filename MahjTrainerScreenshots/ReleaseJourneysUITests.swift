import XCTest

/// Release gate journeys (`qa-gate run`, ~/ios/qa/README.md). They only prove
/// each screen is reachable; FleetQA's oracles judge what is drawn.
@MainActor
final class ReleaseJourneysUITests: XCTestCase {
    private let bundle = "com.jackwallner.mahj"

    override func setUp() {
        continueAfterFailure = false
    }

    func test1FirstRunToHome() {
        let app = XCUIApplication(bundleIdentifier: bundle)
        QA.launch(app)
        // "Know the basics" skips the primer, so the journey walks the tour.
        let skill = app.buttons.containing(label(t("Know the basics"))).firstMatch
        for page in 1...5 where !skill.exists {
            tap(t("Continue"), in: app)
            QA.checkpoint(app, "onboarding-\(page)")
        }
        XCTAssertTrue(skill.waitForExistence(timeout: 10))
        skill.tap()
        QA.checkpoint(app, "skill")
        tap(t("Continue"), in: app)
        XCTAssertTrue(app.buttons[t("Restore")].waitForExistence(timeout: 20))
        QA.checkpoint(app, "onboarding-trial", paywall: true)
        tap(t("Get Started"), in: app)
        let skipTour = app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@",
            t("Skip the tour"), t("Skip it, take me to the app"))).firstMatch
        XCTAssertTrue(skipTour.waitForExistence(timeout: 15), "no tour")
        QA.checkpoint(app, "tour")
        skipTour.tap()
        home("first-home", in: app)
    }

    func test2SessionChallengeUpgradeAndReturn() {
        let app = XCUIApplication(bundleIdentifier: bundle)
        QA.launch(app, arguments: [
            "-progress.hasOnboarded", "YES",
            "-mahj.hasReadPrimer", "YES",
            "-mahj.skillLevel", "some",
            // A returning player: the challenge card shows after a practice.
            "-progress.totalSessions", "3",
            "-progress.sessionsAtOnboarding", "1",
            "-handplay.lastFreeDay", "",
            "-handplay.inProgress", "",
            // Newer than any release, so What's New stays shut.
            "-whatsnew.lastSeenVersion", "99",
        ])
        home("home", in: app)
        XCTAssertTrue(app.buttons[t("Reference and glossary")].firstMatch.exists, "the Reference button reads its symbol name")

        // "Resume Quick Session" when an earlier test left a run.
        let session = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
            t("Get Started"), t("Resume %@", t("Quick Session")))).firstMatch
        XCTAssertTrue(session.waitForExistence(timeout: 10))
        session.tap()
        QA.checkpoint(app, "quick-session")
        if answer(in: app) { QA.checkpoint(app, "quick-session-answered") }
        back(in: app)
        home("home-after-session", in: app)

        let challenge = app.buttons.containing(label(t("Today's Mahj Minute"))).firstMatch
        XCTAssertTrue(challenge.waitForExistence(timeout: 10))
        challenge.tap()
        QA.checkpoint(app, "challenge")
        back(in: app)
        home("home-after-challenge", in: app)

        let endless = app.buttons.containing(label(String(t("Endless\nPractice").prefix { !$0.isWhitespace }))).firstMatch
        XCTAssertTrue(endless.waitForExistence(timeout: 10))
        endless.tap()
        checkpoint("upgrade", button: t("Close"), in: app, paywall: true)
        tap(t("Close"), in: app)
        home("home-after-upgrade", in: app)

        let room = app.buttons.containing(label(t("The Card Room"))).firstMatch
        XCTAssertTrue(room.waitForExistence(timeout: 10))
        room.tap()
        QA.checkpoint(app, "card-room")
        back(in: app)

        tap(t("Settings"), in: app)
        QA.checkpoint(app, "settings")
        back(in: app)
        home("home-after-settings", in: app)

        QA.interrupt(app)
        home("home-after-background", in: app)
        QA.relaunch(app)
        home("home-after-relaunch", in: app)
    }

    /// The core loop. A room drill saves its run at the first answer and
    /// Home offers it back on that same question (1.4.2); then a whole Get
    /// Started session runs to its result, and Home shows the day's session
    /// done, one more drill counted and a streak, still there after a relaunch.
    func testCoreLoopPracticeFinishesAndResumes() {
        let app = XCUIApplication(bundleIdentifier: bundle)
        QA.launch(app, arguments: [
            "-progress.hasOnboarded", "YES",
            "-mahj.hasReadPrimer", "YES",
            "-mahj.skillLevel", "some",
            "-whatsnew.lastSeenVersion", "99",
            // The result screen's trial sheet and rating ask have journeys
            // of their own; here they would only cover Done.
            "-mahj.rc.trial_offer", "off",
            "-mahj.rc.rating_prompt", "off",
        ])
        home("core-home", in: app)
        let drillsBefore = number("%lld drills done", in: app)

        tapButton(t("The Tile Room"), in: app)
        QA.checkpoint(app, "core-room")
        let drill = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@ AND NOT (label BEGINSWITH %@)",
            t("Tile Check"), t("Tile Check: Extra Reps"))).firstMatch
        XCTAssertTrue(drill.waitForExistence(timeout: 10), "no Tile Check")
        drill.tap()
        // A run left from an earlier pass of this journey.
        if app.buttons[t("Start over")].waitForExistence(timeout: 2) { app.buttons[t("Start over")].tap() }
        let prompt = app.staticTexts["question-prompt"].firstMatch
        XCTAssertTrue(prompt.waitForExistence(timeout: 10), "no question")
        let question = prompt.label
        XCTAssertTrue(answer(in: app), "no choices")
        XCTAssertTrue(nextButton(in: app).waitForExistence(timeout: 10), "not graded")
        QA.checkpoint(app, "core-drill-answered")

        // Leave the drill (unfolded, the room stays in the pane beside Home).
        back(in: app)
        toHome(in: app)
        let resume = app.buttons.containing(label(t("Resume %@", t("Tile Check")))).firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: 10), "Home offers no Resume")
        QA.checkpoint(app, "core-resume-offered")
        resume.tap()
        XCTAssertTrue(prompt.waitForExistence(timeout: 10), "Resume opened no question")
        XCTAssertEqual(prompt.label, question, "Resume opened a different question")
        let held = app.buttons["choice-0"].firstMatch.value as? String ?? ""
        XCTAssertTrue(held.contains(t("Your answer, correct")) || held.contains(t("Your answer, wrong")),
                      "the answer was not held")
        QA.checkpoint(app, "core-resumed")

        toHome(in: app)
        tapButton(t("Get Started"), in: app)
        QA.checkpoint(app, "core-session")
        var answered = 0
        while answered < 20 {
            XCTAssertTrue(answer(in: app), "no choices on question \(answered + 1)")
            let next = nextButton(in: app)
            XCTAssertTrue(next.waitForExistence(timeout: 10), "question \(answered + 1) not graded")
            answered += 1
            if answered == 1 { QA.checkpoint(app, "core-session-answered") }
            let finishing = next.label == t("Finish")
            next.tap()
            if finishing { break }
        }
        let streak = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", pattern("%lld-day streak"))).firstMatch
        XCTAssertTrue(streak.waitForExistence(timeout: 15), "no result after \(answered) questions")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES '[0-9]+/[0-9]+'"))
            .firstMatch.exists, "the result shows no score")
        checkpoint("core-result", button: t("Done"), in: app)
        app.buttons[t("Done")].firstMatch.tap()

        home("core-home-after-session", in: app)
        assertSessionBanked(drillsBefore: drillsBefore, in: app)
        QA.relaunch(app)
        home("core-home-after-relaunch", in: app)
        assertSessionBanked(drillsBefore: drillsBefore, in: app)
    }

    // MARK: - Helpers

    /// Home after the finished session: the day's Get Started is spent, the
    /// session counted, the streak running, and no run left to resume.
    private func assertSessionBanked(drillsBefore: Int, in app: XCUIApplication,
                                     file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.staticTexts[t("Today's session is done")].waitForExistence(timeout: 10),
                      "Get Started is not marked done", file: file, line: line)
        XCTAssertEqual(number("%lld drills done", in: app), drillsBefore + 1, "the session was not counted",
                       file: file, line: line)
        XCTAssertGreaterThanOrEqual(number("%lld day streak", in: app), 1, "no streak", file: file, line: line)
        XCTAssertFalse(app.buttons.containing(label(t("Resume"))).firstMatch.exists, "a finished run is still offered",
                       file: file, line: line)
    }

    /// The number a stats chip reads, from its label ("12 drills done",
    /// "1 drill done").
    private func number(_ key: String, in app: XCUIApplication) -> Int {
        let chip = app.descendants(matching: .any).matching(NSPredicate(format: "label MATCHES %@",
            ".*(\(pattern(key))).*")).firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: 10), "no \(key)")
        guard let range = chip.label.range(of: pattern(key), options: .regularExpression) else { return -1 }
        return Int(chip.label[range].filter(\.isNumber)) ?? -1
    }

    private func nextButton(in app: XCUIApplication) -> XCUIElement {
        let next = ["Next", "Next Question", "Next Rack", "Next Deal"].map { label(t($0)) }
        let finish = NSPredicate(format: "label == %@", t("Finish"))
        return app.buttons.matching(NSCompoundPredicate(orPredicateWithSubpredicates: next + [finish])).firstMatch
    }

    private func tapButton(_ prefix: String, in app: XCUIApplication) {
        let button = app.buttons.containing(label(prefix)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10), "no \(prefix)")
        button.tap()
    }

    /// Back until Home's Settings button is on screen. Unfolded, Home is
    /// always beside the pane, so this goes nowhere.
    private func toHome(in app: XCUIApplication) {
        let settings = app.buttons[t("Settings")].firstMatch
        for _ in 0..<3 where !settings.isHittable { back(in: app) }
    }

    private func label(_ prefix: String) -> NSPredicate {
        NSPredicate(format: "label BEGINSWITH %@", prefix)
    }

    private func tap(_ name: String, in app: XCUIApplication) {
        let button = app.buttons[name].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 15), "no \(name)")
        button.tap()
    }

    private func checkpoint(_ name: String, button: String, in app: XCUIApplication, paywall: Bool? = nil,
                            journey: String = #function) {
        XCTAssertTrue(app.buttons[button].firstMatch.waitForExistence(timeout: 15), "no \(button)")
        QA.checkpoint(app, name, paywall: paywall, journey: journey)
    }

    private func home(_ name: String, in app: XCUIApplication, journey: String = #function) {
        XCTAssertTrue(app.buttons[t("Settings")].firstMatch.waitForExistence(timeout: 20), "Home not reached")
        QA.checkpoint(app, name, journey: journey)
    }

    /// Picks the first answer choice on a question screen, if there is one.
    private func answer(in app: XCUIApplication) -> Bool {
        let choice = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'choice-'")).firstMatch
        guard choice.waitForExistence(timeout: 5) else { return false }
        choice.tap()
        return true
    }

    private func back(in app: XCUIApplication) {
        // The iPhone Duo draws a pushed screen's back button in a bar down
        // the side, named only by its identifier; the navigation bar's first
        // button there is Home's.
        let side = app.buttons["BackButton"].firstMatch
        if side.exists, side.isHittable { side.tap(); return }
        let bar = app.navigationBars.buttons.firstMatch
        if bar.waitForExistence(timeout: 5), bar.label != t("Settings") { bar.tap(); return }
        for name in ["Close", "Done", "Back"].map({ t($0) }) where app.buttons[name].exists {
            app.buttons[name].firstMatch.tap()
            return
        }
    }

    // MARK: - Localized labels

    /// The persona's UI language, from the launch arguments FleetQA applies.
    private static let language: String = {
        let arguments = (try? JSONDecoder().decode([String].self,
            from: Data((QA.env["QA_LAUNCH_ARGUMENTS"] ?? "[]").utf8))) ?? []
        guard let index = arguments.firstIndex(of: "-AppleLanguages"), index + 1 < arguments.count else { return "en" }
        return arguments[index + 1].trimmingCharacters(in: CharacterSet(charactersIn: "()\" "))
    }()

    /// The app's String Catalogs, read from the source tree beside this file.
    private static let catalogs: [[String: Any]] = ["Localizable", "Content"].compactMap { name in
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("MahjTrainer/Resources/\(name).xcstrings")
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["strings"] as? [String: Any]
    }

    /// Every form the app can draw for a key in the persona's language
    /// (plural variants included), then in English, then the key itself.
    private func forms(_ key: String) -> [String] {
        for language in [Self.language, "en"] {
            for table in Self.catalogs {
                let localizations = (table[key] as? [String: Any])?["localizations"] as? [String: Any]
                let localization = localizations?[language] as? [String: Any] ?? [:]
                if let value = Self.value(localization) { return [value] }
                let plural = (localization["variations"] as? [String: Any])?["plural"] as? [String: Any] ?? [:]
                let values = plural.values.compactMap { Self.value($0 as? [String: Any] ?? [:]) }
                if !values.isEmpty { return values }
            }
        }
        return [key]
    }

    private static func value(_ variant: [String: Any]) -> String? {
        (variant["stringUnit"] as? [String: Any])?["value"] as? String
    }

    /// The label the app draws for a catalog key, with `%@` filled in order.
    private func t(_ key: String, _ arguments: String...) -> String {
        var text = forms(key)[0]
        for (index, argument) in arguments.enumerated() {
            text = text.replacingOccurrences(of: "%\(index + 1)$@", with: argument)
            if let range = text.range(of: "%@") { text.replaceSubrange(range, with: argument) }
        }
        return text
    }

    /// A regex matching any plural form of a `%lld` key.
    private func pattern(_ key: String) -> String {
        forms(key).map { NSRegularExpression.escapedPattern(for: $0).replacingOccurrences(of: "%lld", with: "[0-9]+") }
            .joined(separator: "|")
    }
}
