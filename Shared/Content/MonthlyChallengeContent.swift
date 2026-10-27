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

    /// Months since year zero, for turn-taking that carries across months.
    var monthIndex: Int {
        let parts = monthKey.split(separator: "-").compactMap { Int($0) }
        return parts.count == 2 ? parts[0] * 12 + parts[1] : 0
    }

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
        ChallengeRound(month: self, day: day)
    }
}

/// One day of a month's challenge, played as that day's Mahj Minute: five
/// questions, the same for everyone that day. The month score is built from
/// these.
struct ChallengeRound: Identifiable, Sendable {
    let month: MonthlyChallenge
    let day: Int
    /// Set only when a test pins the questions.
    private let pinnedItems: [QuickItem]?

    init(month: MonthlyChallenge, day: Int, items: [QuickItem]? = nil) {
        self.month = month
        self.day = day
        pinnedItems = items
    }

    /// Built on first use and cached, never just to name the round. The
    /// first build plans the month's racks (0.4s in a Debug build), and
    /// Home names today's round on its first frame, so building it there
    /// held up the launch (release gate, blank launch).
    var items: [QuickItem] { pinnedItems ?? MonthlyChallengeContent.roundItems(for: month, day: day) }

    var key: String { MonthlyChallengeContent.roundKey(monthKey: month.monthKey, day: day) }
    var id: String { key }
    var monthKey: String { month.monthKey }
    /// "November 5"
    var title: String { "\(month.monthName) \(day)" }
}

/// A month-long challenge, free for everyone, built from each day's Mahj
/// Minute: five new questions a day, the same five on every device. Three
/// are the month's (two on its skill, one from another), then two table
/// calls. A player's best `countedDays` rounds make the month score, so a
/// few missed days cost nothing and coming back keeps paying. Generated
/// questions come from the seeded generators; every third day the third
/// question is a hand-written one from the app's own teaching content.
enum MonthlyChallengeContent {
    /// The month's own questions: the theme, another skill, the closer.
    static let themedPerRound = 3
    /// The Mahj Minute's table calls after them.
    static let tableCallsPerRound = 2
    static var questionsPerRound: Int { themedPerRound + tableCallsPerRound }
    /// Rounds that count toward the month score.
    static let countedDays = 20
    static var maxMonthPoints: Int { questionsPerRound * countedDays }

    /// The first month the challenge existed. Earlier months are not offered.
    /// October 2026 opens it so the release (and App Review) has rounds to
    /// play before November's App Store event.
    static let firstMonth = DateComponents(year: 2026, month: 10)

    /// November 2026 opens the rotation on the Charleston.
    private static let rotationAnchor = 2026 * 12 + 10

    /// The id stays "monthly-challenge": it keys saved sessions.
    static let drill = Drill(
        id: "monthly-challenge",
        title: "Mahj Minute",
        subtitle: "Five new questions a day, the same for every player",
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
    private static let itemCache = ChallengeCache<[QuickItem]>()

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
        return itemCache.value(for: key) {
            items(month: month, day: day, roundKey: key, label: "\(month.monthName) Challenge")
        }
    }

    /// Five questions. The month's three, easiest first: one on the theme,
    /// one from another skill (the other two take turns by day), then a
    /// harder one on the theme. Every third day that one is hand-written,
    /// rotating through its pool so a month does not repeat one until the
    /// pool is used up. Then the Minute's two table calls. They go last so a
    /// round saved before they existed still matches its first three.
    private static func items(month: MonthlyChallenge, day: Int, roundKey: String, label: String) -> [QuickItem] {
        let seed = "monthly-\(roundKey)"
        let theme = month.theme
        let other = otherSkill(month: month, day: day)
        let themed = generated(theme, onTheme: true, seed: seed, label: label, month: month, day: day)
        let side = generated(other, onTheme: false, seed: "\(seed)-\(other.rawValue)", label: label, month: month, day: day)
        var closer = themed.count > 1 ? themed[1] : nil
        if day % 3 == 0 {
            let pool = authoredSequence(for: month, label: label)
            if !pool.isEmpty { closer = pool[(day / 3 - 1) % pool.count] }
        }
        return [themed.first, side.first, closer].compactMap { $0 } + tableCalls(month: month, day: day, label: label)
    }

    /// The day's two table calls (keep or throw, call or wait). One shuffle
    /// of the pool per month, dealt two a day, so a month never repeats one
    /// while the pool lasts.
    private static func tableCalls(month: MonthlyChallenge, day: Int, label: String) -> [QuickItem] {
        let pool = tableCallPool
        guard !pool.isEmpty else { return [] }
        let order = ChoiceShuffle.permutation(count: pool.count, seed: "monthly-\(month.monthKey)-table")
        return (0..<tableCallsPerRound).map { slot in
            relabeled(SessionBuilder.prepared(pool[order[((day - 1) * tableCallsPerRound + slot) % pool.count]]), label)
        }
    }

    /// The Table Room's judgment calls, less the ones defense months already
    /// use as closers.
    static var tableCallPool: [QuickItem] {
        let defense = Set(defensePool.map(\.id))
        return SessionBuilder.choiceItems(in: "table-room", includePro: true).filter { !defense.contains($0.id) }
    }

    private static let tableCallIDs = Set(tableCallPool.map(\.id))

    /// The label over an answer in the review: the month's skill, or the
    /// table call it is.
    static func skillTitle(of item: QuickItem) -> String {
        tableCallIDs.contains(item.id) ? "Table Judgment" : skill(of: item).skillTitle
    }

    /// The skill for the day's middle question: the two off-theme skills
    /// take turns by day.
    private static func otherSkill(month: MonthlyChallenge, day: Int) -> MonthlyChallengeTheme {
        let others = MonthlyChallengeTheme.allCases.filter { $0 != month.theme }
        return others[(day - 1) % others.count]
    }

    /// Generated questions for one skill: two for the theme (the second the
    /// harder read where the skill has one), one otherwise.
    private static func generated(
        _ skill: MonthlyChallengeTheme, onTheme: Bool, seed: String, label: String,
        month: MonthlyChallenge, day: Int
    ) -> [QuickItem] {
        let items: [QuickItem]
        switch skill {
        case .rackReading:
            // Planned for the whole month at once, so no rack repeats.
            items = (rackPlan(for: month)[day] ?? []).enumerated().map { index, rack in
                EndlessPractice.rackItem(rack, id: PracticeSkill.rackReading.itemPrefix + "\(seed)-\(index)", sourceLabel: label)
            }
        case .charleston:
            // A Charleston month follows the one-stray pass with the harder
            // two-singles read. Sections are taken in turn by day.
            let turn = day - 1 + month.monthIndex
            let sections = RackGenerator.generatableCategories
            let plain = CharlestonGenerator.pass(section: sections[turn % sections.count], seed: "\(seed)-passes")
                .map { [(pass: $0, twoSingles: false)] } ?? []
            let readSections = CharlestonGenerator.twoSinglesSections
            let read = onTheme
                ? CharlestonGenerator.pass(section: readSections[turn % readSections.count], seed: "\(seed)-two-singles", twoSingles: true)
                    .map { [(pass: $0, twoSingles: true)] } ?? []
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
            // Planned for the whole month at once, so no table repeats.
            items = (defensePlan(for: month)[day] ?? [])
                .map { onTheme ? (DefenseGenerator.withRunBait($0) ?? $0) : $0 }
                .enumerated().map { index, question in
                    EndlessPractice.defenseItem(question, id: PracticeSkill.defense.itemPrefix + "\(seed)-\(index)", sourceLabel: label)
                }
        }
        return items.map(oneOff)
    }

    private static let rackCache = ChallengeCache<[Int: [RackGenerator.GeneratedRack]]>()

    /// Every day's generated racks for a month. Sections come from a shuffled
    /// bag, so the month stays balanced and a day's two racks differ; an
    /// all-honors rack only on a rack month. No rack twice in a month, and
    /// never the same shape (counts per number, suits aside) on neighbouring
    /// days.
    private static func rackPlan(for month: MonthlyChallenge) -> [Int: [RackGenerator.GeneratedRack]] {
        rackCache.value(for: month.monthKey) {
            let onTheme = month.theme == .rackReading
            let sections = RackGenerator.generatableCategories.filter { onTheme || $0 != .windsDragons }
            var bagGenerator = StableSeededGenerator(seed: "monthly-\(month.monthKey)-rack-bag")
            var bag: [HandCategory] = []
            var plan: [Int: [RackGenerator.GeneratedRack]] = [:]
            var used: Set<String> = []
            var yesterday: Set<String> = []
            for day in 1...month.dayCount {
                guard onTheme || otherSkill(month: month, day: day) == .rackReading else {
                    yesterday = []
                    continue
                }
                let seed = "monthly-\(roundKey(monthKey: month.monthKey, day: day))"
                var picked: [RackGenerator.GeneratedRack] = []
                for _ in 0..<(onTheme ? 2 : 1) {
                    let taken = picked.map(\.answer)
                    if !bag.contains(where: { !taken.contains($0) }) { bag += sections.shuffled(using: &bagGenerator) }
                    guard let index = bag.firstIndex(where: { !taken.contains($0) }) else { break }
                    let section = bag.remove(at: index)
                    let shapes = yesterday.union(picked.map(rackShape))
                    let candidates = (0..<12).compactMap { RackGenerator.rack(for: section, seed: "\(seed)-rack-\(section)-\($0)") }
                        .filter { !used.contains(rackKey($0)) }
                    if let rack = candidates.first(where: { !shapes.contains(rackShape($0)) }) ?? candidates.first {
                        picked.append(rack)
                        used.insert(rackKey(rack))
                    }
                }
                yesterday = Set(picked.map(rackShape))
                plan[day] = picked
            }
            return plan
        }
    }

    private static func rackKey(_ rack: RackGenerator.GeneratedRack) -> String {
        rack.tiles.map(\.spokenName).sorted().joined(separator: "|")
    }

    /// The rack with suits taken away: how many of each number or honor.
    private static func rackShape(_ rack: RackGenerator.GeneratedRack) -> String {
        rack.tiles.map { tile -> String in
            if case .suited(let rank, _) = tile { return "\(rank)" }
            return tile.spokenName
        }.sorted().joined(separator: "|")
    }

    private static let defenseCache = ChallengeCache<[Int: [DefenseGenerator.GeneratedDefense]]>()

    /// Every day's defense questions for a month: only tables nobody can read
    /// another way (`DefenseGenerator.isUnarguable`), no table and safe tile
    /// twice in the month, and never the same two exposed numbers twice in a
    /// day or on neighbouring days.
    private static func defensePlan(for month: MonthlyChallenge) -> [Int: [DefenseGenerator.GeneratedDefense]] {
        defenseCache.value(for: month.monthKey) {
            var plan: [Int: [DefenseGenerator.GeneratedDefense]] = [:]
            let closers = authoredDefenseClosers(for: month)
            let authoredDays = Dictionary(grouping: closers, by: \.exposures).mapValues { $0.map(\.day) }
            // A closer's table and marked tile count as used, so a generated
            // table never repeats its safe tile.
            var used = Set(closers.map { $0.exposures + "|" + $0.answer })
            var exposuresLastDay: [String: Int] = [:]
            var usedLessons: Set<String> = []
            var yesterday: Set<String> = []
            for day in 1...month.dayCount {
                let onTheme = month.theme == .defense
                guard onTheme || otherSkill(month: month, day: day) == .defense else {
                    yesterday = []
                    continue
                }
                let seed = "monthly-\(roundKey(monthKey: month.monthKey, day: day))"
                let base = onTheme ? "\(seed)-defense" : "\(seed)-defense-defense"
                let want = onTheme ? 2 : 1
                var picked: [DefenseGenerator.GeneratedDefense] = []
                // A table and safe tile together are never reused in a month.
                // Fresh exposures (and new numbers from yesterday) come
                // first; the unarguable tables number only about 45, so a
                // defense month repeats some, never within a week and never
                // with the same safe tile, and with a safe tile of a new
                // number wherever the month allows.
                for level in [3, 2, 1, 0] {
                    for attempt in 0..<12 where picked.count < want {
                        let batch = DefenseGenerator.batch(count: 48, seed: attempt == 0 ? base : "\(base)-\(attempt)")
                            .filter(DefenseGenerator.isUnarguable)
                        for question in batch where picked.count < want {
                            let table = tableKey(question)
                            guard !used.contains(table),
                                  !picked.contains(where: { tableKey($0) == table || $0.impliedSection == question.impliedSection || numbersKey($0) == numbersKey(question) })
                            else { continue }
                            let lastDay = exposuresLastDay[exposuresKey(question)]
                            let closerDays = authoredDays[exposuresKey(question)] ?? []
                            if level >= 3, lastDay != nil || !closerDays.isEmpty { continue }
                            if level >= 1, closerDays.contains(where: { abs($0 - day) < 7 }) { continue }
                            if level >= 3, yesterday.contains(numbersKey(question)) { continue }
                            if level >= 2, usedLessons.contains(lessonKey(question)) { continue }
                            if level >= 1, let lastDay, day - lastDay < 7 { continue }
                            picked.append(question)
                        }
                    }
                }
                used.formUnion(picked.map(tableKey))
                for question in picked { exposuresLastDay[exposuresKey(question)] = day }
                usedLessons.formUnion(picked.map(lessonKey))
                yesterday = Set(picked.map(numbersKey))
                plan[day] = picked
            }
            return plan
        }
    }

    /// The month's hand-written defense closers that show two exposed pungs:
    /// their day, `exposuresKey` and marked tile, so a generated table never
    /// shows the same two pungs within a week of one or repeats its tile.
    private static func authoredDefenseClosers(for month: MonthlyChallenge) -> [(day: Int, exposures: String, answer: String)] {
        guard month.theme == .defense else { return [] }
        let pool = authoredSequence(for: month, label: "")
        guard !pool.isEmpty else { return [] }
        return stride(from: 3, through: month.dayCount, by: 3).compactMap { day in
            let item = pool[(day / 3 - 1) % pool.count]
            let tiles = item.tiles
            let kinds = tiles.reduce(into: [Tile]()) { kinds, tile in if !kinds.contains(tile) { kinds.append(tile) } }
            guard tiles.count == 6, kinds.count == 2, kinds.allSatisfy({ kind in tiles.filter { $0 == kind }.count == 3 }),
                  item.choices.indices.contains(item.answerIndex)
            else { return nil }
            return (day, kinds.map(\.spokenName).sorted().joined(separator: "|"), item.choices[item.answerIndex])
        }
    }

    private static func tableKey(_ question: DefenseGenerator.GeneratedDefense) -> String {
        exposuresKey(question) + "|" + question.answer.spokenName
    }

    /// The safe tile's number, not the tile: the same exposures with an 8
    /// Bam and then an 8 Dot as the answer teach the same lesson twice.
    private static func lessonKey(_ question: DefenseGenerator.GeneratedDefense) -> String {
        guard case .suited(let rank, _) = question.answer else { return tableKey(question) }
        return exposuresKey(question) + "|\(rank)"
    }

    /// Order-free: the same two pungs called the other way round are the same table.
    private static func exposuresKey(_ question: DefenseGenerator.GeneratedDefense) -> String {
        question.exposures.compactMap(\.first).map(\.spokenName).sorted().joined(separator: "|")
    }

    private static func numbersKey(_ question: DefenseGenerator.GeneratedDefense) -> String {
        question.exposures.compactMap(\.first).compactMap { tile -> Int? in
            if case .suited(let rank, _) = tile { return rank }
            return nil
        }.sorted().map(String.init).joined(separator: "-")
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

    /// Hand-written questions per month on the theme, one for every third day.
    private static let authoredPerMonth = 10

    /// The month's hand-written questions, in the order the days use them.
    /// Every theme's pool holds 40, so the four months a theme gets in a
    /// year never repeat a closer (`MonthlyChallengeTests` checks a year).
    private static func authoredSequence(for month: MonthlyChallenge, label: String) -> [QuickItem] {
        let count = authoredPerMonth
        let round = month.rotation
        let monthKey = month.monthKey
        switch month.theme {
        case .charleston:
            let scenarios = charlestonPool
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
            let pool = defensePool
            return rotation(poolSize: pool.count, seed: "monthly-defense-pool", round: round, count: count)
                .map { relabeled(SessionBuilder.prepared(pool[$0]), label) }
        case .rackReading:
            // Dealt round-robin by section, so neighbouring days read as
            // different hands.
            let pool = rackPool
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

    /// Ids of authored content that leans on the card's year (2026), as the
    /// answer or the decoy. The year changes with every new card, so the
    /// challenge never uses them.
    static let yearBoundIDs: Set<String> = ["cs-year", "pro-rack-3", "pro-rack-8"]

    /// Every three-tile pass the Charleston months draw from.
    static var charlestonPool: [CharlestonScenario] {
        MahjMinuteContent.allCharlestonScenarios.filter { !yearBoundIDs.contains($0.id) } + extraPasses
    }

    /// The four-choice reads and the quicker judgment calls, mixed.
    static var defensePool: [QuickItem] {
        let table = SessionBuilder.choiceItems(in: "table-room", includePro: true)
        return defenseQuestions + extraDefense + defenseItemIDs.compactMap { id in table.first { $0.id == id } }
    }

    /// Every authored rack read except those tied to the year, whose digits
    /// change with the card.
    static var rackPool: [QuickItem] {
        let rackPrompt = "Which section is this rack chasing?"
        let library = (SessionBuilder.choiceItems(in: "card-room", includePro: true)
            + SessionBuilder.choiceItems(in: "pro-tables", includePro: true))
            .filter { $0.prompt == rackPrompt && $0.choices[$0.answerIndex] != HandCategory.year.displayName && !yearBoundIDs.contains($0.id) }
        let extras = extraRacks.map { question in
            QuickItem(
                id: question.id,
                prompt: rackPrompt,
                tiles: question.tiles.racked,
                choices: question.choices.map(\.displayName),
                answerIndex: question.choices.firstIndex(of: question.answer) ?? 0,
                explanation: question.explanation,
                sourceLabel: "Monthly Challenge",
                roomID: "card-room",
                isReviewable: false,
                choiceNotes: RackGenerator.missNotes(tiles: question.tiles, choices: question.choices, answer: question.answer)
            )
        }
        return library + extras
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
            prompt: "Late in the hand, one opponent has exposed a pung of 5 Bams and a pung of 9 Bams. Which discard is safest?",
            tiles: [.b(5), .b(5), .b(5), .b(9), .b(9), .b(9)],
            choices: ["2 Crak", "7 Bam", "3 Dot", "1 Crak"],
            answerIndex: 0,
            explanation: "5s and 9s are both odd, so this could point at 13579 (Odds). The 7 Bam, 3 Dot and 1 Crak are all odd and feed that read, and the 7 Bam is in the same suit as both pungs. The 2 Crak is even and in another suit, so it misses that read.",
            sourceLabel: "Monthly Challenge",
            roomID: "table-room",
            isReviewable: false,
            choiceNotes: [
                nil,
                "The 7 Bam is odd and in the same suit as both pungs, so it fits the odds read.",
                "A 3 is odd, so it fits the 13579 read of their exposures.",
                "A 1 is odd, so it fits the 13579 read of their exposures.",
            ]
        ),
        QuickItem(
            id: "monthly-def-dead-joker",
            prompt: "You can see your hand can no longer win, but you are still drawing and discarding. An opponent with three exposures looks one tile away. What is the safest discard?",
            tiles: [],
            choices: ["A joker", "A tile that fits the pattern of their exposures", "A flower", "A wind nobody has thrown yet"],
            answerIndex: 0,
            explanation: "Nobody can call a discarded joker, so it can never be the tile that hands someone the game, and with your own hand out of reach it costs you nothing. Flowers and unseen winds can still finish someone's hand, and a tile that fits the pattern of their exposures is the riskiest throw.",
            sourceLabel: "Monthly Challenge",
            roomID: "table-room",
            isReviewable: false,
            choiceNotes: [
                nil,
                "A tile that fits the pattern their exposures show is the kind most likely to finish their hand.",
                "Many hands use flowers, so a late flower is a risky throw.",
                "A wind nobody has thrown is still live for anyone collecting winds.",
            ]
        ),
        QuickItem(
            id: "monthly-def-just-passed",
            prompt: "An opponent across the table is close to mah jongg. The player before you just discarded a 6 Dot and nobody called it. You hold a 6 Dot. How safe is it to throw?",
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
                "Any number fits many hands. What matters is that this one just went by and nobody called it, which is a good sign, not proof.",
                "Being the last copy helps, but it is not proof, since even a last copy can be someone's single. The tile that just went by uncalled is the stronger sign.",
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

private final class ChallengeCache<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var byKey: [String: Value] = [:]

    func value(for key: String, build: () -> Value) -> Value {
        if let cached = lock.withLock({ byKey[key] }) { return cached }
        // Built outside the lock: deterministic, so a rare double build is harmless.
        let built = build()
        lock.withLock { byKey[key] = built }
        return built
    }
}
