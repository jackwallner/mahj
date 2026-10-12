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
        XCTAssertEqual(defense.count, 6)
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
        XCTAssertTrue(first.shareText.contains("November Challenge: 2/3"))
    }

    func testChallengeLinkParses() {
        XCTAssertEqual(AppDestination(url: URL(string: "mahj://challenge")!), .monthlyChallenge)
        XCTAssertNil(AppDestination(url: URL(string: "mahj://elsewhere")!))
        XCTAssertNil(AppDestination(url: URL(string: "https://challenge")!))
        XCTAssertTrue(AppDestination.monthlyChallenge.isFree)
        XCTAssertFalse(AppDestination.gameNightPrepSession.isFree)
    }
}
