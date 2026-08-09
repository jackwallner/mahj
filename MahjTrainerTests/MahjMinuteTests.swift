import XCTest
@testable import MahjTrainer

final class MahjMinuteContentTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    func testChallengeIsStableAndSharedForACalendarDay() {
        let day = date(2026, 8, 8)
        let first = MahjMinuteContent.challenge(for: day, calendar: calendar)
        let second = MahjMinuteContent.challenge(for: day, calendar: calendar)

        XCTAssertEqual(first.dayKey, "2026-08-08")
        XCTAssertEqual(first.items.map(\.id), second.items.map(\.id))
        XCTAssertEqual(first.items.map(\.choices), second.items.map(\.choices))
        XCTAssertEqual(first.items.map(\.tiles), second.items.map(\.tiles))
    }

    func testChallengeHasThePromisedFiveQuestionMix() {
        let challenge = MahjMinuteContent.challenge(for: date(2026, 8, 8), calendar: calendar)
        let categories = Dictionary(grouping: challenge.questions, by: \.category).mapValues(\.count)

        XCTAssertEqual(challenge.questions.count, 5)
        XCTAssertEqual(categories[.rackReading], 2)
        XCTAssertEqual(categories[.charleston], 1)
        XCTAssertEqual(categories[.tableJudgment], 2)
    }

    func testEveryDailyQuestionIsLegalAndGradeable() {
        let challenge = MahjMinuteContent.challenge(for: date(2026, 8, 8), calendar: calendar)

        for question in challenge.questions {
            let item = question.item
            if question.category != .tableJudgment {
                XCTAssertEqual(item.tiles.count, 13, "\(item.id) must show a 13-tile rack")
            }
            XCTAssertGreaterThanOrEqual(item.choices.count, 2)
            XCTAssertTrue(item.choices.indices.contains(item.answerIndex))
            XCTAssertEqual(Set(item.choices).count, item.choices.count)

            var counts: [Tile: Int] = [:]
            for tile in item.tiles where tile != .flower && tile != .joker {
                counts[tile, default: 0] += 1
            }
            XCTAssertTrue(counts.values.allSatisfy { $0 <= 4 })

            if question.category == .charleston {
                XCTAssertEqual(item.choices.count, 4)
                XCTAssertFalse(item.choices[item.answerIndex].localizedCaseInsensitiveContains("joker"))
            }
        }
    }
}

final class MahjMinuteStoreTests: XCTestCase {
    private let suiteName = "MahjMinuteStoreTests"

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @MainActor
    private func freshStore() -> (UserDefaults, MahjMinuteStore) {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, MahjMinuteStore(defaults: defaults))
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @MainActor
    func testFirstDailyResultWinsAndBreakdownPersists() {
        let (defaults, store) = freshStore()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let day = date(2026, 8, 8)
        let challenge = MahjMinuteContent.challenge(for: day, calendar: calendar)
        let answers = [true, false, true, true, false]
        let first = store.record(challenge: challenge, answers: answers, now: day)
        let replay = store.record(challenge: challenge, answers: Array(repeating: true, count: 5), now: day)
        let reloaded = MahjMinuteStore(defaults: defaults)

        XCTAssertEqual(first.score, 3)
        XCTAssertEqual(replay.score, 3)
        XCTAssertEqual(first.total(in: .rackReading), 2)
        XCTAssertEqual(first.total(in: .charleston), 1)
        XCTAssertEqual(first.total(in: .tableJudgment), 2)
        XCTAssertEqual(reloaded.result(for: day, calendar: calendar)?.score, 3)
        XCTAssertTrue(first.shareText.contains("Mahj Minute 08/08: 3/5"))
    }

    @MainActor
    func testWeeklyRhythmCountsFiveCompletedChallenges() {
        let (defaults, store) = freshStore()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let days = (3...7).map { date(2026, 8, $0) }
        for day in days {
            store.record(
                challenge: MahjMinuteContent.challenge(for: day, calendar: calendar),
                answers: Array(repeating: true, count: 5),
                now: day
            )
        }

        XCTAssertEqual(store.completedThisWeek(now: date(2026, 8, 7), calendar: calendar), 5)
    }
}
