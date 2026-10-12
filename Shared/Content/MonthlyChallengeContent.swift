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
        case .defense: return "Defense"
        case .rackReading: return "Read the Rack"
        }
    }

    var blurb: String {
        switch self {
        case .charleston: return "Pass smart: the tiles you can lose for free, and the three that make the strongest pass."
        case .defense: return "Read the exposures and throw the tile nobody at the table can use."
        case .rackReading: return "Spot the section a rack is chasing before anyone else does."
        }
    }

    /// The skill row on the result screen. Defense months also carry the
    /// authored table judgments, so that row reads as table play.
    var skillTitle: String {
        switch self {
        case .charleston: return "Charleston"
        case .defense: return "Table Play"
        case .rackReading: return "Rack Reading"
        }
    }

    var icon: String {
        switch self {
        case .charleston: return "arrow.triangle.2.circlepath"
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
/// questions on every device, six on the month's theme and six across the
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
            items: items(theme: theme, monthKey: monthKey, label: "\(monthName) Challenge")
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
        if item.id.hasPrefix(PracticeSkill.rackReading.itemPrefix) { return .rackReading }
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

    private static func items(theme: MonthlyChallengeTheme, monthKey: String, label: String) -> [QuickItem] {
        let seed = "monthly-\(monthKey)"
        func counts(_ skill: MonthlyChallengeTheme) -> Int { skill == theme ? 6 : 2 }

        let racks = RackGenerator.batch(count: counts(.rackReading), seed: "\(seed)-racks")
            .enumerated().map { index, rack in
                EndlessPractice.rackItem(
                    rack,
                    id: PracticeSkill.rackReading.itemPrefix + "\(seed)-\(index)",
                    sourceLabel: label
                )
            }
        let passes = CharlestonGenerator.batch(count: counts(.charleston), seed: "\(seed)-passes")
            .enumerated().map { index, pass in
                EndlessPractice.passItem(
                    pass,
                    id: PracticeSkill.charlestonPass.itemPrefix + "\(seed)-\(index)",
                    sourceLabel: label
                )
            }
        let defense = DefenseGenerator.batch(count: counts(.defense), seed: "\(seed)-defense")
            .enumerated().map { index, question in
                EndlessPractice.defenseItem(
                    question,
                    id: PracticeSkill.defense.itemPrefix + "\(seed)-\(index)",
                    sourceLabel: label
                )
            }
        let authored = theme == .charleston
            ? (0..<2).map { index in
                MahjMinuteContent.authoredCharlestonItem(
                    seed: "\(seed)-charleston-\(index)",
                    id: "monthly-charleston-\(monthKey)-\(index)",
                    sourceLabel: label,
                    trackingID: "monthly-charleston",
                    distractorSeed: "\(seed)-\(index)"
                )
            }
            : tableItems(seed: seed).map { relabeled($0, label) }

        // Generated ids are one-off, so they never land in Fix My Mistakes.
        let generated = (racks + passes + defense).map { item in
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
        let all = generated + authored
        return ChoiceShuffle.permutation(count: all.count, seed: "\(seed)-order").map { all[$0] }
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

    private static func tableItems(seed: String) -> [QuickItem] {
        let pool = SessionBuilder.choiceItems(in: "table-room", includePro: true)
        let indices = ChoiceShuffle.permutation(count: pool.count, seed: "\(seed)-table")
        return indices.prefix(2).map { SessionBuilder.prepared(pool[$0]) }
    }
}
