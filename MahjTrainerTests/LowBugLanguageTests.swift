import XCTest
@testable import MahjTrainer

/// B6: a language change must not orphan the day's saved Mahj Minute answers.
extension LowBugRegressionTests {
    // MARK: B6 a language change must not orphan the day's saved answers

    private func roundItems(german: Bool) -> [QuickItem] {
        (0..<MonthlyChallengeContent.questionsPerRound).map { index in
            QuickItem(
                id: "lang-\(index)",
                prompt: german ? "Welcher Abschnitt? \(index)" : "Which section? \(index)",
                tiles: [.c(2), .c(4), .c(6), .c(8)],
                choices: german ? ["Gerade", "Ungerade", "Winde"] : ["Evens", "Odds", "Winds"],
                answerIndex: index % 3,
                explanation: german ? "Darum." : "Because.",
                sourceLabel: "Monthly Challenge",
                roomID: "card-room"
            )
        }
    }

    private func pinned(german: Bool) -> ChallengeRound {
        let month = MonthlyChallengeContent.challenge(for: Date(timeIntervalSince1970: 1_793_000_000))
        return ChallengeRound(month: month, day: 5, items: roundItems(german: german))
    }

    func testSavedMinuteAnswersSurviveAChangeOfLanguage() {
        let store = MonthlyChallengeStore(defaults: freshDefaults("LowBugLanguageProgress"))
        let english = pinned(german: false), german = pinned(german: true)
        store.recordAnswer(round: english, correct: true, pick: 0)
        store.recordAnswer(round: english, correct: false, pick: 2)
        XCTAssertEqual(store.progress(for: german)?.answers, [true, false])
        store.recordAnswer(round: german, correct: true, pick: 2)
        XCTAssertEqual(store.progress(for: german)?.answers, [true, false, true], "the third answer adds to the first two")
    }

    func testAFinishedMinuteKeepsItsAnswerReviewAfterAChangeOfLanguage() {
        let store = MonthlyChallengeStore(defaults: freshDefaults("LowBugLanguageResult"))
        let english = pinned(german: false), german = pinned(german: true)
        let result = store.record(round: english, answers: [true, false, true, true, false], picks: [0, 1, 2, 0, 1])
        XCTAssertTrue(result.matches(english))
        XCTAssertTrue(result.matches(german))
    }

    func testAnUpdateThatChangesTheQuestionsStillDropsTheSavedAnswers() {
        let store = MonthlyChallengeStore(defaults: freshDefaults("LowBugChangedQuestions"))
        let before = pinned(german: false)
        store.recordAnswer(round: before, correct: true, pick: 0)
        var changed = roundItems(german: false)
        changed[0] = QuickItem(id: "lang-other", prompt: "New", tiles: [.b(1)], choices: ["A", "B", "C"], answerIndex: 0,
                               explanation: "x", sourceLabel: "Monthly Challenge", roomID: "card-room")
        let month = MonthlyChallengeContent.challenge(for: Date(timeIntervalSince1970: 1_793_000_000))
        XCTAssertNil(store.progress(for: ChallengeRound(month: month, day: 5, items: changed)))
    }

    /// A run saved before this fix carries the old fingerprints; it keeps
    /// resuming in the language it was made in.
    func testARunSavedWithTheOldFingerprintsStillResumes() {
        let defaults = freshDefaults("LowBugLegacyFingerprint")
        let store = MonthlyChallengeStore(defaults: defaults)
        let round = pinned(german: false)
        let old = round.items.prefix(2).map { item in
            [item.id, item.prompt, item.tiles.map(\.shortLabel).joined(separator: " "),
             item.choices.joined(separator: "/"), String(item.answerIndex)].joined(separator: "|")
        }
        let progress = MonthlyChallengeProgress(answers: [true, false], picks: [0, 1], fingerprints: old)
        let data = try! JSONEncoder().encode([round.key: progress])
        defaults.set(data, forKey: "monthlyChallenge.roundProgress")
        let reopened = MonthlyChallengeStore(defaults: defaults)
        XCTAssertEqual(reopened.progress(for: round)?.answers, [true, false])
        reopened.recordAnswer(round: round, correct: true, pick: 2)
        XCTAssertEqual(reopened.progress(for: round)?.answers, [true, false, true])
    }
}
