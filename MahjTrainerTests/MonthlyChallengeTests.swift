import XCTest
@testable import MahjTrainer

final class MonthlyChallengeTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func round(_ year: Int, _ month: Int, _ day: Int) -> ChallengeRound {
        MonthlyChallengeContent.challenge(for: date(year, month, day), calendar: calendar).round(day: day)
    }

    func testARoundIsTheSameAllDayAndNewTheNext() {
        let morning = MonthlyChallengeContent.currentRound(now: date(2026, 11, 5, hour: 1), calendar: calendar)
        let night = MonthlyChallengeContent.currentRound(now: date(2026, 11, 5, hour: 23), calendar: calendar)
        let tomorrow = MonthlyChallengeContent.currentRound(now: date(2026, 11, 6), calendar: calendar)

        XCTAssertEqual(morning?.key, "2026-11-05")
        XCTAssertEqual(morning?.items.map(\.challengeFingerprint), night?.items.map(\.challengeFingerprint))
        XCTAssertEqual(tomorrow?.key, "2026-11-06")
        XCTAssertNotEqual(Set(morning?.items.map(\.id) ?? []), Set(tomorrow?.items.map(\.id) ?? []))
    }

    func testTheChallengeOpensInOctober2026() {
        XCTAssertNil(MonthlyChallengeContent.currentRound(now: date(2026, 9, 30, hour: 23), calendar: calendar))
        XCTAssertFalse(MonthlyChallengeContent.isOpen(on: date(2026, 9, 30, hour: 23), calendar: calendar))
        XCTAssertEqual(MonthlyChallengeContent.currentRound(now: date(2026, 10, 1, hour: 0), calendar: calendar)?.day, 1)
        XCTAssertEqual(MonthlyChallengeContent.currentRound(now: date(2026, 10, 18), calendar: calendar)?.key, "2026-10-18")
        XCTAssertEqual(MonthlyChallengeContent.theme(year: 2026, month: 10), .rackReading)
        XCTAssertEqual(MonthlyChallengeContent.firstChallenge(calendar: calendar).monthKey, "2026-10")
    }

    func testThemesRotateFromTheCharlestonInNovember2026() {
        XCTAssertEqual(MonthlyChallengeContent.theme(year: 2026, month: 11), .charleston)
        XCTAssertEqual(MonthlyChallengeContent.theme(year: 2026, month: 12), .defense)
        XCTAssertEqual(MonthlyChallengeContent.theme(year: 2027, month: 1), .rackReading)
        XCTAssertEqual(MonthlyChallengeContent.theme(year: 2027, month: 2), .charleston)
    }

    /// Every day's seed is fixed, so a day that came up short would be short
    /// for every player. Sweep every day of two years.
    func testEveryDayHasThreeLegalGradeableQuestions() {
        for offset in 0..<24 {
            let month = MonthlyChallengeContent.challenge(
                for: calendar.date(byAdding: .month, value: offset, to: date(2026, 10, 15))!, calendar: calendar)
            for day in 1...month.dayCount {
                let round = month.round(day: day)
                XCTAssertEqual(round.items.count, MonthlyChallengeContent.questionsPerRound, "\(round.key) is short")
                XCTAssertEqual(Set(round.items.map(\.id)).count, round.items.count, "\(round.key) repeats an id")
                for item in round.items {
                    XCTAssertGreaterThanOrEqual(item.choices.count, 2, "\(item.id)")
                    XCTAssertTrue(item.choices.indices.contains(item.answerIndex), "\(item.id)")
                    XCTAssertEqual(Set(item.choices).count, item.choices.count, "\(item.id) repeats a choice")
                    let copies = Dictionary(grouping: item.tiles.filter { $0 != .joker && $0 != .flower }, by: { $0 })
                    XCTAssertLessThanOrEqual(copies.values.map(\.count).max() ?? 0, 4, "\(item.id) shows a fifth copy")
                    XCTAssertFalse(item.prompt.contains("\u{2014}") || item.explanation.contains("\u{2014}"), "\(item.id) em dash")
                    XCTAssertEqual(item.sourceLabel, "\(month.monthName) Challenge", item.id)
                }
            }
        }
    }

    /// Two of three on the theme, one from another skill, and the other two
    /// skills take turns, so a month touches all three.
    func testEachRoundLeansOnTheTheme() {
        let month = MonthlyChallengeContent.challenge(for: date(2026, 12, 10), calendar: calendar)
        var sides: Set<MonthlyChallengeTheme> = []
        for day in 1...month.dayCount {
            let skills = month.round(day: day).items.map(MonthlyChallengeContent.skill(of:))
            XCTAssertEqual(skills.filter { $0 == .defense }.count, 2, "day \(day): \(skills)")
            XCTAssertEqual(skills.first, .defense)
            sides.insert(skills[1])
        }
        XCTAssertEqual(sides, [.charleston, .rackReading])
    }

    /// Every third day closes on a hand-written question, and a month does
    /// not use one twice while its pool lasts.
    func testHandWrittenClosersRotateThroughTheMonth() {
        for monthDate in [date(2026, 11, 5), date(2026, 12, 5), date(2027, 1, 5)] {
            let month = MonthlyChallengeContent.challenge(for: monthDate, calendar: calendar)
            let closers = stride(from: 3, through: month.dayCount, by: 3).map { month.round(day: $0).items[2] }
            for closer in closers {
                XCTAssertFalse(PracticeSkill.allCases.contains { closer.id.hasPrefix($0.itemPrefix) }, "\(month.monthKey) \(closer.id)")
            }
            XCTAssertGreaterThanOrEqual(Set(closers.map(\.id)).count, 4, month.monthKey)
            let generatedCloser = month.round(day: 4).items[2]
            XCTAssertTrue(PracticeSkill.allCases.contains { generatedCloser.id.hasPrefix($0.itemPrefix) }, month.monthKey)
        }
    }

    /// Each theme's pool covers the four months it gets in a year, so no
    /// hand-written closer comes back for a year (October 2026 to
    /// September 2027 checked). Charleston ids carry the month, so passes
    /// compare by what the player sees.
    func testNoClosingQuestionRepeatsForAYear() {
        var seen: [String: String] = [:]
        for offset in 0..<12 {
            let month = MonthlyChallengeContent.challenge(
                for: calendar.date(byAdding: .month, value: offset, to: date(2026, 10, 15))!, calendar: calendar)
            for day in stride(from: 3, through: month.dayCount, by: 3) {
                let closer = month.round(day: day).items[2]
                let key = closer.prompt + closer.tiles.map(\.spokenName).joined(separator: ",")
                XCTAssertNil(seen[key], "\(month.monthKey) day \(day) repeats a closer from \(seen[key] ?? "")")
                seen[key] = month.monthKey
            }
        }
        XCTAssertEqual(MonthlyChallengeContent.charlestonPool.count, 40)
        XCTAssertEqual(MonthlyChallengeContent.defensePool.count, 40)
        XCTAssertEqual(MonthlyChallengeContent.rackPool.count, 40)
    }

    /// Year content names the 2026 card, which a new card replaces each
    /// spring, so the challenge never uses it.
    func testNoYearBoundContentInTheChallenge() {
        XCTAssertFalse(MonthlyChallengeContent.rackPool.contains { $0.choices[$0.answerIndex] == HandCategory.year.displayName })
        XCTAssertFalse(MonthlyChallengeContent.charlestonPool.contains { MonthlyChallengeContent.yearBoundIDs.contains($0.id) })
        for item in MonthlyChallengeContent.extraDefense + MonthlyChallengeContent.defensePool {
            XCTAssertFalse((item.prompt + item.explanation).contains("2026"), item.id)
        }
    }

    /// The challenge-only racks and passes obey the same rules as the
    /// library's (ContentValidityTests only sees `DrillLibrary`).
    func testChallengeOnlyContentIsLegal() {
        let libraryIDs = Set(DrillLibrary.rooms.flatMap { SessionBuilder.choiceItems(in: $0.id, includePro: true) }.map(\.id)
            + MahjMinuteContent.allCharlestonScenarios.map(\.id))
        var ids: Set<String> = []
        for rack in MonthlyChallengeContent.extraRacks {
            XCTAssertEqual(rack.tiles.count, 13, rack.id)
            XCTAssertTrue(rack.choices.contains(rack.answer), rack.id)
            XCTAssertEqual(Set(rack.choices).count, rack.choices.count, rack.id)
            XCTAssertNotEqual(rack.answer, .year, rack.id)
            let copies = Dictionary(grouping: rack.tiles.filter { $0 != .joker && $0 != .flower }, by: { $0 })
            XCTAssertLessThanOrEqual(copies.values.map(\.count).max() ?? 0, 4, rack.id)
            XCTAssertLessThanOrEqual(rack.tiles.filter { $0 == .joker }.count, 8, rack.id)
            XCTAssertLessThanOrEqual(rack.tiles.filter { $0 == .flower }.count, 8, rack.id)
            if rack.answer == .singlesAndPairs { XCTAssertFalse(rack.tiles.contains(.joker), rack.id) }
            XCTAssertFalse(rack.explanation.contains("\u{2014}"), rack.id)
            XCTAssertTrue(ids.insert(rack.id).inserted, rack.id)
        }
        for pass in MonthlyChallengeContent.extraPasses {
            XCTAssertEqual(pass.deal.count, 13, pass.id)
            XCTAssertEqual(pass.recommendedPass.count, 3, pass.id)
            XCTAssertFalse(pass.recommendedPass.contains(.joker), pass.id)
            var deal = pass.deal
            for tile in pass.recommendedPass {
                guard let index = deal.firstIndex(of: tile) else { return XCTFail("\(pass.id) passes a tile it was not dealt") }
                deal.remove(at: index)
            }
            let copies = Dictionary(grouping: pass.deal.filter { $0 != .joker && $0 != .flower }, by: { $0 })
            XCTAssertLessThanOrEqual(copies.values.map(\.count).max() ?? 0, 4, pass.id)
            for text in [pass.situation, pass.reasoning, pass.tip] {
                XCTAssertFalse(text.contains("\u{2014}"), pass.id)
            }
            XCTAssertTrue(ids.insert(pass.id).inserted, pass.id)
        }
        for item in MonthlyChallengeContent.extraDefense {
            XCTAssertEqual(item.choiceNotes.count, item.choices.count, item.id)
            XCTAssertNil(item.choiceNotes[item.answerIndex], item.id)
            XCTAssertTrue(item.choiceNotes.enumerated().allSatisfy { $0.offset == item.answerIndex || $0.element != nil }, item.id)
            XCTAssertEqual(Set(item.choices).count, item.choices.count, item.id)
            for text in [item.prompt, item.explanation] + item.choices + item.choiceNotes.compactMap({ $0 }) {
                XCTAssertFalse(text.contains("\u{2014}"), item.id)
            }
            XCTAssertTrue(ids.insert(item.id).inserted, item.id)
        }
        XCTAssertTrue(ids.isDisjoint(with: libraryIDs))
    }

    /// Generated defense in the challenge: never a table that reads another
    /// way (sums, long runs, the year), and never the same table and safe
    /// tile twice in a month.
    func testChallengeDefenseTablesAreUnarguableAndNeverRepeat() {
        for offset in 0..<12 {
            let month = MonthlyChallengeContent.challenge(
                for: calendar.date(byAdding: .month, value: offset, to: date(2026, 10, 15))!, calendar: calendar)
            var tables: Set<String> = []
            for day in 1...month.dayCount {
                for item in month.round(day: day).items where item.id.hasPrefix(PracticeSkill.defense.itemPrefix) {
                    let exposed = Set(item.tiles).compactMap { tile -> Int? in
                        if case .suited(let rank, _) = tile { return rank }
                        return nil
                    }
                    let safe = Int(item.choices[item.answerIndex].prefix(1)) ?? 0
                    XCTAssertEqual(exposed.count, 2, item.id)
                    let all = exposed + [safe]
                    XCTAssertGreaterThanOrEqual(all.max()! - all.min()!, 6, "\(month.monthKey) day \(day)")
                    XCTAssertFalse(DefenseGenerator.makesSum(exposed[0], exposed[1], safe), "\(month.monthKey) day \(day)")
                    XCTAssertNotEqual(Set(exposed), [2, 6], "\(month.monthKey) day \(day)")
                    let table = Set(item.tiles).map(\.spokenName).sorted().joined(separator: ",") + "|" + item.choices[item.answerIndex]
                    XCTAssertTrue(tables.insert(table).inserted, "\(month.monthKey) day \(day) repeats \(table)")
                }
            }
        }
    }

    func testSumsAreCaught() {
        XCTAssertTrue(DefenseGenerator.makesSum(5, 7, 2))
        XCTAssertTrue(DefenseGenerator.makesSum(2, 4, 6))
        XCTAssertTrue(DefenseGenerator.makesSum(9, 4, 1))
        XCTAssertFalse(DefenseGenerator.makesSum(2, 4, 9))
        XCTAssertFalse(DefenseGenerator.makesSum(5, 9, 2))
        // One addend and both digits of the total: 5 + 7 = 12.
        XCTAssertTrue(DefenseGenerator.makesSum(1, 7, 2))
        XCTAssertFalse(DefenseGenerator.makesSum(2, 8, 9))
        // A whole rack's numbers: 4 + 9 = 13.
        XCTAssertTrue(DefenseGenerator.fitsOneSum([1, 3, 4, 9]))
        XCTAssertFalse(DefenseGenerator.fitsOneSum([1, 3, 5, 7, 9]))
    }

    /// The free-points all-honors rack never turns up outside a rack month.
    func testNoAllHonorsRackOffTheme() {
        let month = MonthlyChallengeContent.challenge(for: date(2026, 11, 5), calendar: calendar)
        for day in 1...month.dayCount {
            let honors = month.round(day: day).items.filter {
                $0.id.hasPrefix(PracticeSkill.rackReading.itemPrefix) && $0.tiles.allSatisfy { tile in
                    if case .suited = tile { return false }
                    return true
                }
            }
            XCTAssertTrue(honors.isEmpty, "day \(day)")
        }
    }

    func testPastMonthsStartAtTheFirstChallenge() {
        XCTAssertEqual(MonthlyChallengeContent.pastMonths(before: date(2026, 10, 20), calendar: calendar).count, 0)
        let past = MonthlyChallengeContent.pastMonths(before: date(2027, 1, 5), calendar: calendar)
        XCTAssertEqual(past.map { calendar.component(.month, from: $0) }, [12, 11, 10])
    }

    func testDaysLeftCountsToTheEndOfTheMonth() {
        let challenge = MonthlyChallengeContent.challenge(for: date(2026, 11, 1), calendar: calendar)
        XCTAssertEqual(challenge.dayCount, 30)
        XCTAssertEqual(challenge.daysLeft(now: date(2026, 11, 1)), 30)
        XCTAssertEqual(challenge.daysLeft(now: date(2026, 11, 30)), 1)
    }

    @MainActor
    private func freshStore(_ name: String) -> (MonthlyChallengeStore, UserDefaults) {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return (MonthlyChallengeStore(defaults: defaults), defaults)
    }

    @MainActor
    func testFirstRunOfADayIsTheOneThatCounts() {
        let (store, defaults) = freshStore("MonthlyChallengeTests")
        let today = round(2026, 11, 3)

        let first = store.record(round: today, answers: [true, false, true])
        let second = store.record(round: today, answers: [true, true, true])

        XCTAssertEqual(first.score, 2)
        XCTAssertEqual(second.score, 2)
        XCTAssertEqual(MonthlyChallengeStore(defaults: defaults).result(for: today)?.score, 2)
        XCTAssertEqual(first.title, "November 3")
    }

    @MainActor
    func testTheMonthScoreKeepsTheBestTwentyDays() {
        let (store, _) = freshStore("MonthlyChallengeScore")
        for day in 1...25 {
            // Five perfect days, then twenty days of one right.
            let answers = day <= 5 ? [true, true, true] : [true, false, false]
            store.record(round: round(2026, 11, day), answers: answers)
        }
        let score = store.monthScore("2026-11")
        XCTAssertEqual(score.daysPlayed, 25)
        XCTAssertEqual(score.points, 5 * 3 + 15 * 1)
        XCTAssertEqual(store.monthScore("2026-12"), .empty)
    }

    @MainActor
    func testARoundResumesAndTheLastAnswerFinishesIt() {
        let (store, defaults) = freshStore("MonthlyChallengeResume")
        let today = round(2026, 11, 3)

        XCTAssertNil(store.recordAnswer(round: today, correct: true, pick: 0))
        XCTAssertNil(store.recordAnswer(round: today, correct: false, pick: 2))
        let reloaded = MonthlyChallengeStore(defaults: defaults)
        XCTAssertEqual(reloaded.progress(for: today)?.answers, [true, false])
        XCTAssertEqual(reloaded.progress(for: today)?.picks, [0, 2])

        let result = reloaded.recordAnswer(round: today, correct: true, pick: 1)
        XCTAssertEqual(result?.total, 3)
        XCTAssertEqual(result?.score, 2)
        XCTAssertEqual(result?.picks, [0, 2, 1])
        XCTAssertNil(reloaded.progress(for: today))
        XCTAssertEqual(MonthlyChallengeStore(defaults: defaults).result(for: today)?.score, 2)
    }

    /// A round left half done at midnight keeps what it earned.
    @MainActor
    func testAnUnfinishedRoundIsClosedWhenItsDayEnds() {
        let (store, _) = freshStore("MonthlyChallengeStale")
        let yesterday = round(2026, 11, 3)
        store.recordAnswer(round: yesterday, correct: true, pick: 0)

        store.closeEarlierRounds(than: round(2026, 11, 4))

        XCTAssertNil(store.progress(for: yesterday))
        XCTAssertEqual(store.result(for: yesterday)?.answers, [true])
        XCTAssertEqual(store.monthScore("2026-11"), MonthScore(points: 1, daysPlayed: 1))
    }

    @MainActor
    func testTheReviewIsOnlyOfferedForTheQuestionsThatWereAnswered() throws {
        let (store, defaults) = freshStore("MonthlyChallengeFingerprints")
        let today = round(2026, 11, 3)
        for _ in today.items { store.recordAnswer(round: today, correct: true, pick: 0) }
        let saved = try XCTUnwrap(MonthlyChallengeStore(defaults: defaults).result(for: today))
        XCTAssertTrue(saved.matches(today))
        // Content that changed under a saved result must not re-label it.
        XCTAssertFalse(saved.matches(round(2026, 11, 4)))
    }

    @MainActor
    func testScoreTokensAreRandomPerMonth() {
        let (store, _) = freshStore("MonthlyChallengeTokens")
        let november = store.scoreToken(for: "2026-11")
        XCTAssertEqual(store.scoreToken(for: "2026-11"), november)
        XCTAssertNotEqual(store.scoreToken(for: "2026-12"), november)
        XCTAssertNotNil(UUID(uuidString: november))
    }

    func testStandingOnlyShowsTheTopHalfOnceEnoughHavePlayed() {
        XCTAssertNil(ChallengeStanding(players: 9, below: 8, points: 30).topPercent)
        XCTAssertNil(ChallengeStanding(players: 200, below: 60, points: 10).topPercent)
        XCTAssertEqual(ChallengeStanding(players: 200, below: 160, points: 40).topPercent, 20)
        XCTAssertEqual(ChallengeStanding(players: 200, below: 199, points: 60).topPercent, 1)
        XCTAssertEqual(ChallengeStanding(players: 200, below: 100, points: 20).topPercent, 50)
    }

    /// A Buddhist or Hebrew system calendar must not change which day a
    /// player is on, or stretch the archive back thousands of months.
    func testTheChallengeIgnoresTheSystemCalendar() {
        XCTAssertEqual(Calendar.gregorianLocal.identifier, .gregorian)
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = .current
        let instant = gregorian.date(from: DateComponents(year: 2026, month: 11, day: 12, hour: 12))!
        XCTAssertEqual(MonthlyChallengeContent.currentRound(now: instant)?.key, "2026-11-12")
        XCTAssertEqual(MonthlyChallengeContent.pastMonths(before: instant).count, 1)
        XCTAssertEqual(MahjMinuteContent.key(for: instant), "2026-11-12")
    }

    func testRoundKeysRoundTripAndNextFollows() {
        let november = MonthlyChallengeContent.challenge(for: date(2026, 11, 5), calendar: calendar)
        XCTAssertEqual(MonthlyChallengeContent.round(key: "2026-11-05", calendar: calendar)?.items.map(\.id),
                       november.round(day: 5).items.map(\.id))
        XCTAssertNil(MonthlyChallengeContent.round(key: "2026-11-31", calendar: calendar))
        XCTAssertNil(MonthlyChallengeContent.round(key: "nonsense", calendar: calendar))
        XCTAssertEqual(MonthlyChallengeContent.next(after: november, calendar: calendar).monthKey, "2026-12")
    }

    func testChallengeLinkParses() {
        XCTAssertEqual(AppDestination(url: URL(string: "mahj://challenge")!), .monthlyChallenge)
        XCTAssertNil(AppDestination(url: URL(string: "mahj://elsewhere")!))
        XCTAssertNil(AppDestination(url: URL(string: "https://challenge")!))
        XCTAssertTrue(AppDestination.monthlyChallenge.isFree)
        XCTAssertFalse(AppDestination.gameNightPrepSession.isFree)
    }
}

/// Writes every question for a run of days as JSON when `CHALLENGE_DUMP`
/// names a path, for content review outside Xcode.
final class MonthlyChallengeDumpTests: XCTestCase {
    func testDumpChallengesForReview() throws {
        guard let path = ProcessInfo.processInfo.environment["CHALLENGE_DUMP"] else { return }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var rounds: [[String: Any]] = []
        for offset in 0..<12 {
            let (year, month) = (2026 + (9 + offset) / 12, (9 + offset) % 12 + 1)
            let date = calendar.date(from: DateComponents(year: year, month: month, day: 15))!
            let challenge = MonthlyChallengeContent.challenge(for: date, calendar: calendar)
            for day in 1...challenge.dayCount {
                let round = challenge.round(day: day)
                rounds.append([
                    "round": round.key,
                    "theme": challenge.theme.title,
                    "questions": round.items.enumerated().map { index, item in
                        [
                            "number": index + 1,
                            "id": item.id,
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
        }
        let data = try JSONSerialization.data(withJSONObject: rounds, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: path))
    }
}
