import XCTest
@testable import MahjTrainer

final class MonthlyChallengeTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    func testChallengeIsTheSameAllMonth() {
        let first = MonthlyChallengeContent.challenge(for: date(2026, 11, 1), calendar: calendar)
        let last = MonthlyChallengeContent.challenge(for: date(2026, 11, 30), calendar: calendar)

        XCTAssertEqual(first.monthKey, "2026-11")
        XCTAssertEqual(first.items.map(\.id), last.items.map(\.id))
        XCTAssertEqual(first.items.map(\.choices), last.items.map(\.choices))
        XCTAssertEqual(first.items.map(\.tiles), last.items.map(\.tiles))
    }

    func testThemesRotateFromTheCharlestonInNovember2026() {
        XCTAssertEqual(MonthlyChallengeContent.theme(year: 2026, month: 10), .rackReading)
        XCTAssertEqual(MonthlyChallengeContent.theme(year: 2026, month: 11), .charleston)
        XCTAssertEqual(MonthlyChallengeContent.theme(year: 2026, month: 12), .defense)
        XCTAssertEqual(MonthlyChallengeContent.theme(year: 2027, month: 1), .rackReading)
        XCTAssertEqual(MonthlyChallengeContent.theme(year: 2027, month: 2), .charleston)
    }

    /// The month seed is fixed, so a month that came up short would be short
    /// for every player. Sweep five years of real months.
    func testEveryMonthHasTwelveLegalGradeableQuestions() {
        for year in 2026...2031 {
            for month in 1...12 {
                let challenge = MonthlyChallengeContent.challenge(for: date(year, month, 15), calendar: calendar)
                let key = challenge.monthKey
                XCTAssertEqual(challenge.items.count, MonthlyChallengeContent.questionCount, "\(key) is short")
                XCTAssertEqual(Set(challenge.items.map(\.id)).count, challenge.items.count, "\(key) repeats an id")
                for item in challenge.items {
                    XCTAssertGreaterThanOrEqual(item.choices.count, 2, "\(item.id)")
                    XCTAssertTrue(item.choices.indices.contains(item.answerIndex), "\(item.id)")
                    XCTAssertEqual(Set(item.choices).count, item.choices.count, "\(item.id) repeats a choice")
                    let copies = Dictionary(grouping: item.tiles.filter { $0 != .joker && $0 != .flower }, by: { $0 })
                    XCTAssertLessThanOrEqual(copies.values.map(\.count).max() ?? 0, 4, "\(item.id) shows a fifth copy")
                    XCTAssertFalse(item.prompt.contains("\u{2014}") || item.explanation.contains("\u{2014}"), "\(item.id) em dash")
                }
            }
        }
    }

    func testThemedMonthLeansOnItsSkill() {
        let challenge = MonthlyChallengeContent.challenge(for: date(2026, 12, 10), calendar: calendar)
        let defense = challenge.items.filter { $0.id.hasPrefix(PracticeSkill.defense.itemPrefix) }
        XCTAssertEqual(defense.count, 5)
    }

    /// The hand-written closers rotate: within one pass through a theme's
    /// pool, no month repeats a question an earlier month already used.
    func testAuthoredClosersDoNotRepeatAcrossMonths() {
        for theme in MonthlyChallengeTheme.allCases {
            var seen: Set<String> = []
            var month = date(2026, 11, 10)
            var checked = 0
            while checked < 2 {
                let challenge = MonthlyChallengeContent.challenge(for: month, calendar: calendar)
                if challenge.theme == theme {
                    let authored = challenge.items.suffix(3).map { $0.id.hasPrefix("monthly-charleston-") ? String($0.id.split(separator: "-").last!) : $0.id }
                    for id in authored { XCTAssertTrue(seen.insert(id).inserted, "\(challenge.monthKey) repeats \(id)") }
                    checked += 1
                }
                month = calendar.date(byAdding: .month, value: 1, to: month)!
            }
        }
    }

    /// The first nine never put the same kind of question back to back, and
    /// the free-points all-honors rack shows up at most once a month.
    func testMonthsAreVaried() {
        for offset in 0..<24 {
            let month = calendar.date(byAdding: .month, value: offset, to: date(2026, 10, 10))!
            let challenge = MonthlyChallengeContent.challenge(for: month, calendar: calendar)
            let skills = challenge.items.prefix(9).map(MonthlyChallengeContent.skill(of:))
            for (a, b) in zip(skills, skills.dropFirst()) where a != challenge.theme {
                XCTAssertNotEqual(a, b, "\(challenge.monthKey) repeats a skill back to back")
            }
            let honorRacks = challenge.items.filter {
                $0.id.hasPrefix(PracticeSkill.rackReading.itemPrefix) && $0.tiles.allSatisfy { tile in
                    if case .suited = tile { return false }
                    return true
                }
            }
            XCTAssertLessThanOrEqual(honorRacks.count, 1, challenge.monthKey)
        }
    }

    func testPastMonthsStartAtTheFirstChallenge() {
        XCTAssertEqual(MonthlyChallengeContent.pastMonths(before: date(2026, 10, 20), calendar: calendar).count, 0)
        let past = MonthlyChallengeContent.pastMonths(before: date(2027, 1, 5), calendar: calendar)
        XCTAssertEqual(past.map { calendar.component(.month, from: $0) }, [12, 11, 10])
    }

    func testDaysLeftCountsToTheEndOfTheMonth() {
        let challenge = MonthlyChallengeContent.challenge(for: date(2026, 11, 1), calendar: calendar)
        XCTAssertEqual(challenge.daysLeft(now: date(2026, 11, 1), calendar: calendar), 30)
        XCTAssertEqual(challenge.daysLeft(now: date(2026, 11, 30), calendar: calendar), 1)
    }

    @MainActor
    func testFirstRunIsTheOneThatCounts() {
        let defaults = UserDefaults(suiteName: "MonthlyChallengeTests")!
        defaults.removePersistentDomain(forName: "MonthlyChallengeTests")
        let store = MonthlyChallengeStore(defaults: defaults)
        let challenge = MonthlyChallengeContent.challenge(for: date(2026, 11, 3), calendar: calendar)

        let first = store.record(challenge: challenge, answers: [true, false, true])
        let second = store.record(challenge: challenge, answers: [true, true, true])

        XCTAssertEqual(first.score, 2)
        XCTAssertEqual(second.score, 2)
        XCTAssertEqual(MonthlyChallengeStore(defaults: defaults).result(for: challenge)?.score, 2)
        XCTAssertTrue(first.shareText.contains("November Challenge (The Charleston): 2/3"))
    }

    @MainActor
    func testARunResumesAndTheLastAnswerFinishesIt() {
        let defaults = UserDefaults(suiteName: "MonthlyChallengeResume")!
        defaults.removePersistentDomain(forName: "MonthlyChallengeResume")
        let store = MonthlyChallengeStore(defaults: defaults)
        let challenge = MonthlyChallengeContent.challenge(for: date(2026, 11, 3), calendar: calendar)

        XCTAssertNil(store.recordAnswer(challenge: challenge, correct: true, pick: 0))
        XCTAssertNil(store.recordAnswer(challenge: challenge, correct: false, pick: 2))
        let reloaded = MonthlyChallengeStore(defaults: defaults)
        XCTAssertEqual(reloaded.progress(for: challenge)?.answers, [true, false])
        XCTAssertEqual(reloaded.progress(for: challenge)?.picks, [0, 2])

        var result: MonthlyChallengeResult?
        for _ in 2..<challenge.items.count {
            result = reloaded.recordAnswer(challenge: challenge, correct: true, pick: 1)
        }
        XCTAssertEqual(result?.total, challenge.items.count)
        XCTAssertEqual(result?.score, challenge.items.count - 1)
        XCTAssertEqual(result?.picks?.prefix(2), [0, 2])
        XCTAssertNil(reloaded.progress(for: challenge))
        XCTAssertEqual(MonthlyChallengeStore(defaults: defaults).result(for: challenge)?.score, challenge.items.count - 1)
    }

    func testTheThemeIsMostOfTheMonth() {
        for (month, theme) in [(11, MonthlyChallengeTheme.charleston), (12, .defense)] {
            let challenge = MonthlyChallengeContent.challenge(for: date(2026, month, 5), calendar: calendar)
            let onTheme = challenge.items.filter { MonthlyChallengeContent.skill(of: $0) == theme }
            XCTAssertGreaterThanOrEqual(onTheme.count, 8, "\(challenge.monthKey)")
        }
    }

    func testMonthKeysRoundTripAndNextFollows() {
        let november = MonthlyChallengeContent.challenge(for: date(2026, 11, 5), calendar: calendar)
        XCTAssertEqual(MonthlyChallengeContent.challenge(monthKey: "2026-11", calendar: calendar)?.items.map(\.id),
                       november.items.map(\.id))
        XCTAssertNil(MonthlyChallengeContent.challenge(monthKey: "nonsense", calendar: calendar))
        XCTAssertEqual(MonthlyChallengeContent.next(after: november, calendar: calendar).monthKey, "2026-12")
        XCTAssertTrue(november.items.allSatisfy { $0.sourceLabel == "November Challenge" })
    }

    func testChallengeLinkParses() {
        XCTAssertEqual(AppDestination(url: URL(string: "mahj://challenge")!), .monthlyChallenge)
        XCTAssertNil(AppDestination(url: URL(string: "mahj://elsewhere")!))
        XCTAssertNil(AppDestination(url: URL(string: "https://challenge")!))
        XCTAssertTrue(AppDestination.monthlyChallenge.isFree)
        XCTAssertFalse(AppDestination.gameNightPrepSession.isFree)
    }
}

/// Writes every question for a run of months as JSON when
/// `TEST_RUNNER_CHALLENGE_DUMP` names a path, for content review outside Xcode.
final class MonthlyChallengeDumpTests: XCTestCase {
    func testDumpChallengesForReview() throws {
        guard let path = ProcessInfo.processInfo.environment["CHALLENGE_DUMP"] else { return }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var months: [[String: Any]] = []
        for (year, month) in [(2026, 10), (2026, 11), (2026, 12), (2027, 1), (2027, 2), (2027, 3)] {
            let date = calendar.date(from: DateComponents(year: year, month: month, day: 15))!
            let challenge = MonthlyChallengeContent.challenge(for: date, calendar: calendar)
            months.append([
                "month": challenge.monthKey,
                "theme": challenge.theme.title,
                "questions": challenge.items.enumerated().map { index, item in
                    [
                        "number": index + 1,
                        "id": item.id,
                        "eyebrow": item.sourceLabel,
                        "prompt": item.prompt,
                        "tiles": item.tiles.map(\.spokenName),
                        "choices": item.choices,
                        "answer": item.choices[item.answerIndex],
                        "explanation": item.explanation,
                        "wrongChoiceNotes": item.choiceNotes.map { $0 ?? "" },
                    ] as [String: Any]
                },
            ])
        }
        let data = try JSONSerialization.data(withJSONObject: months, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: path))
    }
}
