import Foundation

/// The skill a month's challenge leans on. Themes rotate so every month is
/// new content, which is what an App Store in-app event has to promote.
enum MonthlyChallengeTheme: String, CaseIterable, Codable, Sendable {
    case charleston
    case defense
    case rackReading

    var title: String {
        switch self {
        case .charleston: return "The Charleston"
        case .defense: return "Safe Discards"
        case .rackReading: return "Reading Your Rack"
        }
    }

    var blurb: String {
        switch self {
        case .charleston: return "Pass smart: the tiles that do nothing for your hand, and the three that make the strongest pass."
        case .defense: return "Read the tiles other players have out, and throw the one nobody can use."
        case .rackReading: return "Look at a rack and spot which section of the card it is heading for."
        }
    }

    /// The skill's name on chips, the result screen and the answer review.
    var skillTitle: String {
        switch self {
        case .charleston: return "Charleston"
        case .defense: return "Safe Discards"
        case .rackReading: return "Reading Your Rack"
        }
    }

    var icon: String {
        switch self {
        case .charleston: return "arrow.left.arrow.right"
        case .defense: return "shield.lefthalf.filled"
        case .rackReading: return "square.grid.3x3.fill"
        }
    }
}

struct MonthlyChallenge: Identifiable, Sendable {
    let monthKey: String
    /// "November 2026"
    let title: String
    /// "November"
    let monthName: String
    let theme: MonthlyChallengeTheme
    let start: Date
    let end: Date
    /// How many months have shared this theme before, for the authored rotation.
    let rotation: Int
    let calendar: Calendar

    var id: String { monthKey }

    /// Days in the month, so rounds 1...dayCount.
    var dayCount: Int { calendar.dateComponents([.day], from: start, to: end).day ?? 30 }

    /// Days still to play, today included: 30 on November 1, 1 on the 30th.
    func daysLeft(now: Date = MonthlyChallengeContent.today) -> Int {
        let today = calendar.startOfDay(for: now)
        return max(0, calendar.dateComponents([.day], from: today, to: end).day ?? 0)
    }

    /// Which round `date` is, or nil outside this month.
    func day(of date: Date) -> Int? {
        guard date >= start, date < end else { return nil }
        return calendar.component(.day, from: date)
    }

    func round(day: Int) -> ChallengeRound {
        ChallengeRound(
            month: self,
            day: day,
            items: MonthlyChallengeContent.roundItems(for: self, day: day)
        )
    }
}

/// One day of a month's challenge: three questions, the same for everyone
/// that day. The month score is built from these.
struct ChallengeRound: Identifiable, Sendable {
    let month: MonthlyChallenge
    let day: Int
    let items: [QuickItem]

    var key: String { MonthlyChallengeContent.roundKey(monthKey: month.monthKey, day: day) }
    var id: String { key }
    var monthKey: String { month.monthKey }
    /// "November 5"
    var title: String { "\(month.monthName) \(day)" }
}

/// A month-long challenge, free for everyone: three new questions every day,
/// the same three on every device, two on the month's skill and one from
/// another. A player's best `countedDays` rounds make the month score, so a
/// few missed days cost nothing and coming back keeps paying. Generated
/// questions come from the seeded generators; every third day the last
/// question is a hand-written one from the app's own teaching content.
enum MonthlyChallengeContent {
    static let questionsPerRound = 3
    /// Rounds that count toward the month score.
    static let countedDays = 20
    static var maxMonthPoints: Int { questionsPerRound * countedDays }

    /// The first month the challenge existed. Earlier months are not offered.
    /// October 2026 opens it so the release (and App Review) has rounds to
    /// play before November's App Store event.
    static let firstMonth = DateComponents(year: 2026, month: 10)

    /// November 2026 opens the rotation on the Charleston.
    private static let rotationAnchor = 2026 * 12 + 10

    static let drill = Drill(
        id: "monthly-challenge",
        title: "Monthly Challenge",
        subtitle: "Three new questions a day, the same for every player",
        kind: .quiz([])
    )

    /// How many earlier months have shared this month's theme since the
    /// rotation began (negative before it), for the authored rotation.
    static func round(year: Int, month: Int) -> Int {
        let offset = (year * 12 + (month - 1)) - rotationAnchor
        let cases = MonthlyChallengeTheme.allCases.count
        return offset >= 0 ? offset / cases : -((-offset + cases - 1) / cases)
    }

    static func theme(year: Int, month: Int) -> MonthlyChallengeTheme {
        let offset = (year * 12 + (month - 1)) - rotationAnchor
        let cases = MonthlyChallengeTheme.allCases
        return cases[((offset % cases.count) + cases.count) % cases.count]
    }

    /// Now, or in DEBUG the day passed as `-ChallengeMonth 2026-11` (the 2nd)
    /// or `-ChallengeMonth 2026-11-30`, so store art and late-month states can
    /// be captured on any date.
    static var today: Date {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-ChallengeMonth"), index + 1 < arguments.count {
            let parts = arguments[index + 1].split(separator: "-").compactMap { Int($0) }
            if parts.count >= 2,
               let date = Calendar.gregorianLocal.date(from: DateComponents(
                year: parts[0], month: parts[1], day: parts.count > 2 ? parts[2] : 2, hour: 12)) {
                return date
            }
        }
        #endif
        return Date()
    }

    /// True once the first month has begun in the player's own time zone.
    static func isOpen(on date: Date = today, calendar: Calendar = .gregorianLocal) -> Bool {
        guard let first = calendar.date(from: firstMonth) else { return false }
        return date >= first
    }

    /// The month the challenge opens with, for the "starts on" screen.
    static func firstChallenge(calendar: Calendar = .gregorianLocal) -> MonthlyChallenge {
        challenge(for: calendar.date(from: firstMonth) ?? today, calendar: calendar)
    }

    /// Today's round, or nil before the challenge opens.
    static func currentRound(now: Date = today, calendar: Calendar = .gregorianLocal) -> ChallengeRound? {
        guard isOpen(on: now, calendar: calendar) else { return nil }
        let month = challenge(for: now, calendar: calendar)
        return month.day(of: now).map { month.round(day: $0) }
    }

    static func challenge(for date: Date = today, calendar: Calendar = .gregorianLocal) -> MonthlyChallenge {
        let parts = calendar.dateComponents([.year, .month], from: date)
        let year = parts.year ?? 2026
        let month = parts.month ?? 1
        let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? date
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? date
        // The app's copy is English, so the month name is too, whatever the
        // calendar's locale (a bare Calendar answers "M11").
        var english = calendar
        english.locale = Locale(identifier: "en_US_POSIX")
        let monthName = english.standaloneMonthSymbols[month - 1]
        return MonthlyChallenge(
            monthKey: key(year: year, month: month),
            title: "\(monthName) \(year)",
            monthName: monthName,
            theme: theme(year: year, month: month),
            start: start,
            end: end,
            rotation: round(year: year, month: month),
            calendar: calendar
        )
    }

    /// A day's questions never change, and Home and the challenge screen
    /// ask for them on every render; generating them each time re-ran the
    /// rack generators dozens of times a second.
    private static let itemCache = ChallengeItemCache()

    /// The challenge a stored month key belongs to.
    static func challenge(monthKey: String, calendar: Calendar = .gregorianLocal) -> MonthlyChallenge? {
        let parts = monthKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count >= 2,
              let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: 15))
        else { return nil }
        return challenge(for: date, calendar: calendar)
    }

    /// The round a stored round key belongs to ("2026-11-05").
    static func round(key: String, calendar: Calendar = .gregorianLocal) -> ChallengeRound? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, let month = challenge(monthKey: key, calendar: calendar),
              (1...month.dayCount).contains(parts[2]) else { return nil }
        return month.round(day: parts[2])
    }

    /// The month after `challenge`, for the "next up" line and the reminder.
    static func next(after challenge: MonthlyChallenge, calendar: Calendar = .gregorianLocal) -> MonthlyChallenge {
        let date = calendar.date(byAdding: .day, value: 1, to: challenge.end) ?? challenge.end
        return MonthlyChallengeContent.challenge(for: date, calendar: calendar)
    }

    /// Which skill row an item counts toward.
    static func skill(of item: QuickItem) -> MonthlyChallengeTheme {
        if item.id.hasPrefix(PracticeSkill.rackReading.itemPrefix) || item.roomID == "card-room" { return .rackReading }
        if item.id.hasPrefix(PracticeSkill.charlestonPass.itemPrefix) || item.roomID == "charleston-room" {
            return .charleston
        }
        return .defense
    }

    static func key(year: Int, month: Int) -> String {
        String(format: "%04d-%02d", year, month)
    }

    static func roundKey(monthKey: String, day: Int) -> String {
        monthKey + String(format: "-%02d", day)
    }

    /// Every month from the first challenge up to, not including, `date`'s
    /// month, newest first.
    static func pastMonths(before date: Date = today, calendar: Calendar = .gregorianLocal) -> [Date] {
        guard let first = calendar.date(from: firstMonth),
              let current = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else { return [] }
        var months: [Date] = []
        var cursor = calendar.date(byAdding: .month, value: -1, to: current)
        while let month = cursor, month >= first {
            months.append(month)
            cursor = calendar.date(byAdding: .month, value: -1, to: month)
        }
        return months
    }

    static func roundItems(for month: MonthlyChallenge, day: Int) -> [QuickItem] {
        let key = roundKey(monthKey: month.monthKey, day: day)
        return itemCache.items(for: key) {
            items(month: month, day: day, roundKey: key, label: "\(month.monthName) Challenge")
        }
    }

    /// Three questions, easiest first: one on the theme, one from another
    /// skill (the other two take turns by day), then a harder one on the
    /// theme. Every third day that last one is hand-written, rotating through
    /// its pool so a month does not repeat one until the pool is used up.
    private static func items(month: MonthlyChallenge, day: Int, roundKey: String, label: String) -> [QuickItem] {
        let seed = "monthly-\(roundKey)"
        let theme = month.theme
        let others = MonthlyChallengeTheme.allCases.filter { $0 != theme }
        let other = others[(day - 1) % others.count]
        let themed = generated(theme, onTheme: true, seed: seed, label: label)
        let side = generated(other, onTheme: false, seed: "\(seed)-\(other.rawValue)", label: label)
        var closer = themed.count > 1 ? themed[1] : nil
        if day % 3 == 0 {
            let pool = authoredSequence(for: month, label: label)
            if !pool.isEmpty { closer = pool[(day / 3 - 1) % pool.count] }
        }
        return [themed.first, side.first, closer].compactMap { $0 }
    }

    /// Generated questions for one skill: two for the theme (the second the
    /// harder read where the skill has one), one otherwise.
    private static func generated(_ skill: MonthlyChallengeTheme, onTheme: Bool, seed: String, label: String) -> [QuickItem] {
        let count = onTheme ? 2 : 1
        let items: [QuickItem]
        switch skill {
        case .rackReading:
            // Distinct sections, and an all-honors rack only on a rack month.
            items = distinct(
                RackGenerator.batch(count: count * 4, seed: "\(seed)-racks")
                    .filter { onTheme || $0.answer != .windsDragons },
                by: { "\($0.answer)" },
                count: count
            ).enumerated().map { index, rack in
                EndlessPractice.rackItem(rack, id: PracticeSkill.rackReading.itemPrefix + "\(seed)-\(index)", sourceLabel: label)
            }
        case .charleston:
            // A Charleston month follows the one-stray pass with the harder
            // two-singles read.
            let plain = CharlestonGenerator.batch(count: 4, seed: "\(seed)-passes").prefix(1).map { (pass: $0, twoSingles: false) }
            let read = onTheme
                ? CharlestonGenerator.twoSinglesBatch(count: 4, seed: "\(seed)-two-singles").prefix(1).map { (pass: $0, twoSingles: true) }
                : []
            items = (plain + read).enumerated().map { index, entry in
                EndlessPractice.passItem(
                    entry.pass,
                    id: PracticeSkill.charlestonPass.itemPrefix + "\(seed)-\(index)",
                    sourceLabel: label,
                    prompt: entry.twoSingles ? "Two of these tiles are singles. Which one should you pass?" : nil
                )
            }
        case .defense:
            // Distinct families; a defense month swaps in the run-trap tile.
            items = distinct(DefenseGenerator.batch(count: 8, seed: "\(seed)-defense"), by: { "\($0.impliedSection)" }, count: count)
                .map { onTheme ? (DefenseGenerator.withRunBait($0) ?? $0) : $0 }
                .enumerated().map { index, question in
                    EndlessPractice.defenseItem(question, id: PracticeSkill.defense.itemPrefix + "\(seed)-\(index)", sourceLabel: label)
                }
        }
        return items.map(oneOff)
    }

    /// Generated ids are one-off, so they never land in Fix My Mistakes.
    private static func oneOff(_ item: QuickItem) -> QuickItem {
        SessionBuilder.prepared(QuickItem(
            id: item.id,
            prompt: item.prompt,
            tiles: item.tiles,
            choices: item.choices,
            answerIndex: item.answerIndex,
            explanation: item.explanation,
            sourceLabel: item.sourceLabel,
            roomID: item.roomID,
            trackingID: PracticeSkill.skill(forItemID: item.id)?.rawValue,
            isReviewable: false,
            choiceNotes: item.choiceNotes
        ))
    }

    /// Picks `count` items with distinct keys where the batch allows, then
    /// tops up with repeats rather than coming back short.
    private static func distinct<T>(_ items: [T], by key: (T) -> String, count: Int) -> [T] {
        var seen: Set<String> = []
        var picked: [T] = []
        var rest: [T] = []
        for item in items {
            if picked.count < count, seen.insert(key(item)).inserted { picked.append(item) } else { rest.append(item) }
        }
        return picked + rest.prefix(max(0, count - picked.count))
    }

    /// Hand-written questions per month on the theme, one for every third day.
    private static let authoredPerMonth = 10

    /// The month's hand-written questions, in the order the days use them.
    private static func authoredSequence(for month: MonthlyChallenge, label: String) -> [QuickItem] {
        let count = authoredPerMonth
        let round = month.rotation
        let monthKey = month.monthKey
        switch month.theme {
        case .charleston:
            let scenarios = MahjMinuteContent.allCharlestonScenarios
            return rotation(poolSize: scenarios.count, seed: "monthly-charleston-pool", round: round, count: count).map { index in
                MahjMinuteContent.authoredCharlestonItem(
                    scenario: scenarios[index],
                    id: "monthly-charleston-\(monthKey)-\(index)",
                    sourceLabel: label,
                    trackingID: "monthly-charleston",
                    distractorSeed: "monthly-\(monthKey)-\(index)"
                )
            }
        case .defense:
            // The four-choice reads and the quicker judgment calls, mixed.
            let table = SessionBuilder.choiceItems(in: "table-room", includePro: true)
            let pool = defenseQuestions + defenseItemIDs.compactMap { id in table.first { $0.id == id } }
            return rotation(poolSize: pool.count, seed: "monthly-defense-pool", round: round, count: count)
                .map { relabeled(SessionBuilder.prepared(pool[$0]), label) }
        case .rackReading:
            // The generated racks already cover the five sections a generator
            // can deal, so these are the sections it cannot: Like Numbers,
            // Year, Quints, Singles & Pairs. Dealt round-robin by section, so
            // neighbouring days read as different hands.
            let generatable = Set(RackGenerator.generatableCategories.map(\.displayName))
            let pool = SessionBuilder.choiceItems(in: "card-room", includePro: true)
                .filter { $0.prompt == "Which section is this rack chasing?" && !generatable.contains($0.choices[$0.answerIndex]) }
            let groups = Dictionary(grouping: pool, by: { $0.choices[$0.answerIndex] })
            let sections = groups.keys.sorted()
            let depth = groups.values.map(\.count).max() ?? 0
            let sequence = (0..<depth).flatMap { level in sections.compactMap { section in
                groups[section].flatMap { $0.indices.contains(level) ? $0[level] : nil }
            } }
            guard !sequence.isEmpty else { return [] }
            let start = ((round * count) % sequence.count + sequence.count) % sequence.count
            return (0..<min(count, sequence.count))
                .map { sequence[(start + $0) % sequence.count] }
                .map { relabeled(SessionBuilder.prepared($0), label) }
        }
    }

    /// Two-choice table judgments that are about defense. The four-choice
    /// ones in this list join `defenseQuestions` as reads.
    static let defenseItemIDs = [
        "more-table-safe-discard", "more-table-exposure-read",
        "plus-kd-safe-discard", "kd-exposed-pung", "plus-kd-fourth-tile",
        "more-judge-third-copy", "plus-kd-lone-wind",
    ]

    /// Four-choice defense reads written for the challenge. Original table
    /// situations; nothing here comes from the NMJL card.
    static let defenseQuestions: [QuickItem] = [
        QuickItem(
            id: "monthly-def-run-trap",
            prompt: "Late in the hand, one opponent has exposed a pung of 5 Bams and a pung of 7 Dots. Which discard is safest?",
            tiles: [.b(5), .b(5), .b(5), .d(7), .d(7), .d(7)],
            choices: ["2 Crak", "6 Bam", "9 Crak", "North Wind"],
            answerIndex: 0,
            explanation: "5s and 7s read as 13579 (Odds), and with a 6 between them they could sit in a run too. The 9 Crak feeds the odds read, the 6 Bam feeds the run, and winds turn up in odds hands on real cards. The 2 Crak is even and too far from 5 and 7 for a run through both.",
            sourceLabel: "Monthly Challenge",
            roomID: "table-room",
            isReviewable: false,
            choiceNotes: [
                nil,
                "The 6 sits between their 5s and 7s, so it feeds a run through both pungs.",
                "A 9 is odd, so it fits the 13579 read of their exposures.",
                "Winds and dragons appear in odds hands too, so a wind is not proven safe against this table.",
            ]
        ),
        QuickItem(
            id: "monthly-def-dead-joker",
            prompt: "Your hand can no longer win, but nobody has called it dead, so you are still drawing and discarding. An opponent with three exposures looks one tile away. What is the safest discard?",
            tiles: [],
            choices: ["A joker", "A tile that fits the pattern of their exposures", "A flower", "A wind nobody has thrown yet"],
            answerIndex: 0,
            explanation: "Nobody can call a discarded joker, so it can never be the tile that hands someone the game, and with your own hand out of reach it costs you nothing. Flowers and unseen winds are wanted by many hands, and a tile that fits the pattern of their exposures is the riskiest throw.",
            sourceLabel: "Monthly Challenge",
            roomID: "table-room",
            isReviewable: false,
            choiceNotes: [
                nil,
                "A tile that fits the pattern their exposures show is the kind most likely to finish their hand.",
                "Many hands use flowers, so a late flower is one of the riskiest throws.",
                "A wind nobody has thrown is still live for anyone collecting winds.",
            ]
        ),
        QuickItem(
            id: "monthly-def-just-passed",
            prompt: "An opponent is close to mah jongg. The player before you just discarded a 6 Dot and nobody called it. You hold a 6 Dot. How safe is it to throw?",
            tiles: [.d(6)],
            choices: [
                "Safer than most: it just went by uncalled",
                "Never safe: a 6 fits too many hands",
                "Safe only if it is the last copy",
                "Safe only if you are East",
            ],
            answerIndex: 0,
            explanation: "The player you fear could have called that exact tile a moment ago for mah jongg and did not, and the only tile drawn since is the one you just took. That makes your 6 Dot one of the safest throws you have. Not certain, since a player can miss a tile or pass on it, but it beats a fresh tile.",
            sourceLabel: "Monthly Challenge",
            roomID: "table-room",
            isReviewable: false,
            choiceNotes: [
                nil,
                "Any number fits many hands. What matters is that this one just went by and nobody wanted it.",
                "Copies left do not decide it: one copy can still be someone's winning tile.",
                "Seat has nothing to do with which tiles are safe.",
            ]
        ),
    ]

    /// Round `round` of a fixed shuffle of the pool: consecutive slices, so
    /// nothing repeats until every item has been used once.
    private static func rotation(poolSize: Int, seed: String, round: Int, count: Int) -> [Int] {
        guard poolSize > 0 else { return [] }
        let order = ChoiceShuffle.permutation(count: poolSize, seed: seed)
        let start = ((round * count) % poolSize + poolSize) % poolSize
        return (0..<min(count, poolSize)).map { order[(start + $0) % poolSize] }
    }

    /// Authored items keep their id and grading; only the eyebrow changes, so
    /// every question in the run says which month's challenge it is.
    private static func relabeled(_ item: QuickItem, _ label: String) -> QuickItem {
        QuickItem(
            id: item.id,
            prompt: item.prompt,
            tiles: item.tiles,
            choices: item.choices,
            answerIndex: item.answerIndex,
            explanation: item.explanation,
            sourceLabel: label,
            roomID: item.roomID,
            trackingID: item.trackingID,
            isReviewable: item.isReviewable,
            choiceNotes: item.choiceNotes
        )
    }
}

private final class ChallengeItemCache: @unchecked Sendable {
    private let lock = NSLock()
    private var byMonth: [String: [QuickItem]] = [:]

    func items(for monthKey: String, build: () -> [QuickItem]) -> [QuickItem] {
        if let cached = lock.withLock({ byMonth[monthKey] }) { return cached }
        // Built outside the lock: deterministic, so a rare double build is harmless.
        let built = build()
        lock.withLock { byMonth[monthKey] = built }
        return built
    }
}
