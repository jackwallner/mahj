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
    let items: [QuickItem]

    var id: String { monthKey }

    func daysLeft(now: Date = MonthlyChallengeContent.today, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: now)
        return max(0, calendar.dateComponents([.day], from: today, to: end).day ?? 0)
    }
}

/// One shared set per calendar month, free for everyone: the same twelve
/// questions on every device, eight on the month's theme and four across the
/// other skills. Generated questions come from the seeded generators, so
/// nothing new has to be authored to keep a month fresh, and the authored
/// ones are picked from the app's own teaching content.
enum MonthlyChallengeContent {
    static let questionCount = 12

    /// The first month the challenge existed. Earlier months are not offered.
    static let firstMonth = DateComponents(year: 2026, month: 10)

    /// November 2026 opens the rotation on the Charleston.
    private static let rotationAnchor = 2026 * 12 + 10

    static let drill = Drill(
        id: "monthly-challenge",
        title: "Monthly Challenge",
        subtitle: "The same twelve questions for every player this month",
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

    /// Today, or in DEBUG the month passed as `-ChallengeMonth 2026-11`, so
    /// store art for a coming month can be captured before it starts.
    static var today: Date {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-ChallengeMonth"), index + 1 < arguments.count {
            let parts = arguments[index + 1].split(separator: "-").compactMap { Int($0) }
            if parts.count == 2,
               let date = Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: 2)) {
                return date
            }
        }
        #endif
        return Date()
    }

    static func challenge(for date: Date = today, calendar: Calendar = .current) -> MonthlyChallenge {
        let parts = calendar.dateComponents([.year, .month], from: date)
        let year = parts.year ?? 2026
        let month = parts.month ?? 1
        let monthKey = key(year: year, month: month)
        let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? date
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? date
        // The app's copy is English, so the month name is too, whatever the
        // calendar's locale (a bare Calendar answers "M11").
        var english = calendar
        english.locale = Locale(identifier: "en_US_POSIX")
        let monthName = english.standaloneMonthSymbols[month - 1]
        let theme = theme(year: year, month: month)
        return MonthlyChallenge(
            monthKey: monthKey,
            title: "\(monthName) \(year)",
            monthName: monthName,
            theme: theme,
            start: start,
            end: end,
            items: items(theme: theme, monthKey: monthKey, label: "\(monthName) Challenge", round: round(year: year, month: month))
        )
    }

    /// The challenge a stored result belongs to, rebuilt from its key.
    static func challenge(monthKey: String, calendar: Calendar = .current) -> MonthlyChallenge? {
        let parts = monthKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2,
              let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: 15))
        else { return nil }
        return challenge(for: date, calendar: calendar)
    }

    /// The month after `challenge`, for the "next up" line and the reminder.
    static func next(after challenge: MonthlyChallenge, calendar: Calendar = .current) -> MonthlyChallenge {
        let date = calendar.date(byAdding: .day, value: 1, to: challenge.end) ?? challenge.end
        return MonthlyChallengeContent.challenge(for: date, calendar: calendar)
    }

    /// Which skill row an item counts toward on the result screen.
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

    /// Every month from the first challenge up to, not including, `date`'s
    /// month, newest first.
    static func pastMonths(before date: Date = today, calendar: Calendar = .current) -> [Date] {
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

    /// Twelve questions, easiest first: five generated on the theme
    /// interleaved with two of each other skill, then three hand-written
    /// questions on the theme to close. Generated questions are picked so no
    /// two in a month share a shape, and the hand-written ones rotate through
    /// their pool so a theme does not repeat one until the pool is used up.
    private static func items(theme: MonthlyChallengeTheme, monthKey: String, label: String, round: Int) -> [QuickItem] {
        let seed = "monthly-\(monthKey)"
        func count(_ skill: MonthlyChallengeTheme) -> Int { skill == theme ? 5 : 2 }

        let racks = distinct(
            RackGenerator.batch(count: count(.rackReading) * 3, seed: "\(seed)-racks")
                // An all-honors rack is free points; a themed month gets one at most.
                .filter { theme == .rackReading || $0.answer != .windsDragons },
            by: { "\($0.answer)" },
            count: count(.rackReading)
        ).enumerated().map { index, rack in
            EndlessPractice.rackItem(rack, id: PracticeSkill.rackReading.itemPrefix + "\(seed)-\(index)", sourceLabel: label)
        }
        // A Charleston month mixes the one-stray pass with the harder two-singles
        // read, easiest first; other months get the plain one.
        let plainPasses = distinct(
            CharlestonGenerator.batch(count: 15, seed: "\(seed)-passes"),
            by: { "\($0.section)" },
            count: theme == .charleston ? 2 : count(.charleston)
        )
        let readPasses = theme == .charleston
            ? distinct(CharlestonGenerator.twoSinglesBatch(count: 12, seed: "\(seed)-two-singles"), by: { "\($0.section)" }, count: 3)
            : []
        let plain = plainPasses.map { (pass: $0, twoSingles: false) }
        let reads = readPasses.map { (pass: $0, twoSingles: true) }
        let passOrder = reads.isEmpty
            ? plain
            : [plain.first, reads.first, plain.dropFirst().first, reads.dropFirst().first, reads.dropFirst(2).first].compactMap { $0 }
        let passes = passOrder.enumerated().map { index, entry in
            EndlessPractice.passItem(
                entry.pass,
                id: PracticeSkill.charlestonPass.itemPrefix + "\(seed)-\(index)",
                sourceLabel: label,
                prompt: entry.twoSingles ? "Two of these tiles are singles. Which one should you pass?" : nil
            )
        }
        // Distinct families first, then distinct pungs; a defense month swaps a
        // run-trap tile into every question whose pungs sit two apart.
        let defenseBatch = DefenseGenerator.batch(count: 20, seed: "\(seed)-defense")
        let byFamily = distinct(defenseBatch, by: { "\($0.impliedSection)" }, count: 3)
        let defensePicked = distinct(
            byFamily + defenseBatch,
            by: { question in
                question.exposures.compactMap(\.first).compactMap { tile -> Int? in
                    if case .suited(let rank, _) = tile { return rank }
                    return nil
                }.sorted().map(String.init).joined(separator: "-")
            },
            count: count(.defense)
        ).map { theme == .defense ? (DefenseGenerator.withRunBait($0) ?? $0) : $0 }
        let defense = defensePicked.enumerated().map { index, question in
            EndlessPractice.defenseItem(question, id: PracticeSkill.defense.itemPrefix + "\(seed)-\(index)", sourceLabel: label)
        }

        // Generated ids are one-off, so they never land in Fix My Mistakes.
        func oneOff(_ item: QuickItem) -> QuickItem {
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
        let byTheme: [MonthlyChallengeTheme: [QuickItem]] = [
            .rackReading: racks.map(oneOff),
            .charleston: passes.map(oneOff),
            .defense: defense.map(oneOff),
        ]
        let others = MonthlyChallengeTheme.allCases.filter { $0 != theme }
        let onTheme = byTheme[theme] ?? []
        let first = byTheme[others[0]] ?? []
        let second = byTheme[others[1]] ?? []

        // T A T B T A T B T, then the authored three.
        var ordered: [QuickItem] = []
        let pattern: [(MonthlyChallengeTheme, Int)] = [
            (theme, 0), (others[0], 0), (theme, 1), (others[1], 0), (theme, 2),
            (others[0], 1), (theme, 3), (others[1], 1), (theme, 4),
        ]
        for (skill, index) in pattern {
            let list = skill == theme ? onTheme : (skill == others[0] ? first : second)
            if list.indices.contains(index) { ordered.append(list[index]) }
        }
        return ordered + authored(theme: theme, monthKey: monthKey, label: label, round: round)
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

    /// The hand-written closers, rotating through each theme's pool.
    private static func authored(theme: MonthlyChallengeTheme, monthKey: String, label: String, round: Int) -> [QuickItem] {
        let count = 3
        switch theme {
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
            // Two four-choice reads, then one quick judgment call.
            let pool = SessionBuilder.choiceItems(in: "table-room", includePro: true)
            let fourChoice = defenseQuestions + defenseItemIDs.compactMap { id in pool.first { $0.id == id && $0.choices.count >= 4 } }
            let judgment = defenseItemIDs.compactMap { id in pool.first { $0.id == id && $0.choices.count < 4 } }
            let reads = rotation(poolSize: fourChoice.count, seed: "monthly-defense-reads", round: round, count: 2).map { fourChoice[$0] }
            let calls = rotation(poolSize: judgment.count, seed: "monthly-defense-calls", round: round, count: 1).map { judgment[$0] }
            return (reads + calls).map { relabeled(SessionBuilder.prepared($0), label) }
        case .rackReading:
            // The generated racks already cover the five sections a generator
            // can deal, so the closers are the sections it cannot: Like
            // Numbers, Year, Quints, Singles & Pairs. Dealt round-robin by
            // section, so any three in a row read as three different hands.
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
            prompt: "Your hand is dead, and an opponent with three exposures looks one tile away. What is the safest discard?",
            tiles: [],
            choices: ["A joker", "A tile that matches their exposures", "A flower", "A wind nobody has thrown yet"],
            answerIndex: 0,
            explanation: "Nobody can call a discarded joker, so it can never be the tile that hands someone the game, and with your own hand dead it costs you nothing. Flowers and unseen winds are wanted by many hands, and a tile matching their exposures is the worst throw of all.",
            sourceLabel: "Monthly Challenge",
            roomID: "table-room",
            isReviewable: false,
            choiceNotes: [
                nil,
                "A tile that matches their exposures is the one most likely to finish their hand.",
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
            explanation: "The player you fear passed on that exact tile a moment ago, so it is one of the safer throws you have. Not certain: they have drawn since and their hand may have changed. But a tile that just went around uncalled beats a fresh one.",
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
