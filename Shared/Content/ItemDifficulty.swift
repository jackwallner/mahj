import Foundation

/// How far into the game an item reaches. Sessions use it to keep a new
/// player's questions to what a first lesson covers and to let them in on the
/// rest as they show they have it. Never shown to the player.
enum Difficulty: Int, Comparable, CaseIterable, Codable, Sendable {
    /// Tile names, suits, dragons, jokers, the set itself and reading a line
    /// of the card. Nothing that assumes a pung or kong is already known,
    /// except the questions that teach those words.
    case basic
    /// Groups, calling and exposing, scoring, the sections and reading a
    /// rack: what a player meets once they sit down at a table.
    case intermediate
    /// Rule-of-thumb strategy calls, defense, decoy racks and edge rules.
    case challenging

    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// The tier of every drill item in `DrillLibrary`, keyed by item id.
/// One table rather than a field on each content constant, so the whole
/// ladder reads (and is retuned) in one place. `ContentValidityTests` fails
/// any library item missing from it, and any id here the library lacks.
enum ItemDifficulty {

    static func of(_ id: String) -> Difficulty {
        tiers[id] ?? .intermediate
    }

    static let tiers: [String: Difficulty] = {
        var map: [String: Difficulty] = [:]
        for (tier, ids) in table {
            for id in ids { map[id] = tier }
        }
        return map
    }()

    /// Ids listed once each, grouped by room so a reviewer can walk the
    /// rooms in order.
    static let table: [(Difficulty, [String])] = [
        // The Tile Room
        (.basic, [
            "tiles-craks", "tiles-bams", "tiles-dots", "tiles-winds", "tiles-dragons",
            "tiles-soap", "tiles-flowers", "tiles-jokers", "tiles-count", "tiles-card",
            "tiles-groups", "tiles-concealed",
            "quiz-dragon-crak", "quiz-dragon-bam", "quiz-dragon-dot", "quiz-joker-pair",
            "quiz-joker-charleston", "quiz-soap-zero", "quiz-joker-count", "quiz-pung",
            "quiz-flowers-same", "quiz-concealed", "quiz-colors", "quiz-hand-size",
            "plus-tq-copies", "plus-tq-green-dragon", "plus-tq-kong", "plus-tq-wind-count",
            "more-tile-flower-count", "more-tile-dragon-count", "more-tile-one-bam",
            "more-tile-total", "more-tile-soap",
        ]),
        (.intermediate, [
            "quiz-quint", "quiz-sp-jokers", "quiz-joker-exchange", "quiz-dead-joker",
            "plus-tq-expose", "plus-tq-priority", "plus-tq-pair-call", "plus-tq-dead-hand",
            "plus-tq-call-kong", "plus-tq-sextet", "more-tile-swap-joker",
        ]),

        // The Card Room
        (.basic, [
            "cat-year", "cat-2468", "cat-like", "cat-run", "cat-13579", "cat-winds", "cat-369",
            "cat-line-matching-dragon", "cat-line-opposite-dragon", "cat-line-any-number",
            "cat-line-run-slides", "cat-line-news", "cat-line-year-soap",
        ]),
        (.intermediate, [
            "cat-quints", "cat-sp", "cat-line-concealed",
            "hm-2468", "hm-run", "hm-odds", "hm-winds", "hm-369", "hm-like", "hm-year",
            "hm-quints", "hm-sp",
            "plus-hm-odds", "plus-hm-consec", "plus-hm-winds", "plus-hm-year", "plus-hm-quints",
            "plus-hm-sp", "more-rack-evens", "more-rack-consecutive", "more-rack-winds",
            "more-rack-369", "more-rack-like",
        ]),

        // The Charleston Room
        (.basic, ["ch-what", "ch-first-look", "ch-jokers"]),
        (.intermediate, [
            "ch-flowers", "ch-pairs", "ch-blind", "ch-stop", "ch-courtesy",
            "cs-evens", "cs-winds", "cs-run", "cs-pairs", "cs-junk", "cs-flowers", "cs-like",
            "cs-year",
            "plus-ch-first-right", "plus-ch-blind-pass", "plus-ch-courtesy",
            "plus-ch-keep-flowers", "more-pass-odds", "more-pass-honors", "more-pass-flexible",
        ]),
        (.challenging, ["ch-watch", "ch-telegraph", "cs-commit"]),

        // The Table Room
        (.basic, ["kd-count-four", "more-judge-joker-hold"]),
        (.intermediate, [
            "kd-wrong-parity", "kd-joker-swap", "kd-sp-joker", "kd-exposed-pung",
            "kd-wind-pair", "kd-mahj-call",
            "more-table-call-discard", "more-table-dead-hand", "more-table-exposure-read",
            "more-table-never-expose", "table-pay-discard", "table-pay-self-pick",
            "table-pay-jokerless", "table-pay-wall", "table-pay-dead-hand",
            "table-call-too-late", "table-call-then-what", "table-call-priority",
            "table-mahj-in-error",
            "plus-kd-lone-wind", "plus-kd-redeem-own", "plus-kd-call-single",
            "more-judge-lone-wind", "more-judge-third-copy",
        ]),
        (.challenging, [
            "kd-third-flower", "kd-joker-rescue", "kd-follow-count", "kd-flower-vs-wind",
            "kd-dead-joker", "kd-call-cost", "kd-hot-late",
            "more-table-safe-discard", "table-pay-stacked", "table-exposure-locked",
            "plus-kd-fourth-tile", "plus-kd-commit", "plus-kd-safe-discard",
            "plus-kd-dont-call", "plus-kd-count-tiles", "more-judge-flower-discipline",
            "more-judge-late-switch",
        ]),

        // The Master Tables
        (.intermediate, [
            "more-pro-joker-single", "more-pro-joker-discard-late", "more-pro-joker-quint",
            "more-pro-joker-exposure-swap", "more-pro-joker-year",
        ]),
        (.challenging, [
            "pro-ch-two-sections", "pro-ch-keep-pair", "pro-ch-pass-pair", "pro-ch-369-vs-run",
            "pro-ch-second-stop", "pro-ch-defend-late",
            "pro-def-read-like", "pro-def-read-369", "pro-def-count-copies", "pro-def-quints-dead",
            "pro-def-safe-discard", "pro-def-hot-tile", "pro-def-break-hand", "pro-def-joker-swap",
            "pro-def-track-jokers", "pro-def-hidden-count", "pro-def-follow-discard",
            "pro-def-no-exposures",
            "pro-rack-1", "pro-rack-2", "pro-rack-3", "pro-rack-4", "pro-rack-5", "pro-rack-6",
            "pro-rack-7", "pro-rack-8",
            "more-pro-joker-redeem-timing", "more-pro-joker-flowers",
        ]),
    ]
}

/// Where a player's sessions top out. The onboarding answer sets the floor;
/// accuracy raises the ceiling one tier at a time.
enum SessionLevel {

    /// Share of a tier answered right (latest answer) that opens the next one.
    static let promotionAccuracy = 0.8
    /// Share of a tier that must have been answered before it can promote,
    /// so one lucky session of three questions does not count.
    static let promotionCoverage = 0.6

    /// The onboarding answer (`mahj.skillLevel`) as a starting ceiling.
    /// Unset or unknown is a player from before the question existed, who
    /// keeps the full mix they always had.
    static func seed(forSkillLevel skillLevel: String) -> Difficulty {
        switch skillLevel {
        case "new": return .basic
        case "basics": return .intermediate
        default: return .challenging
        }
    }

    /// The ceiling earned from `start` given what the player has answered.
    /// Each tier at the ceiling promotes once enough of it has been answered
    /// and most of those answers stand right; it never steps down.
    static func ceiling(
        from start: Difficulty,
        seen: Set<String>,
        missed: Set<String>,
        includePro: Bool
    ) -> Difficulty {
        let pool = SessionBuilder.poolIDs(includePro: includePro)
        var level = start
        while level < .challenging, promotes(level, pool: pool, seen: seen, missed: missed) {
            level = Difficulty(rawValue: level.rawValue + 1) ?? .challenging
        }
        return level
    }

    static func promotes(
        _ tier: Difficulty,
        pool: [String],
        seen: Set<String>,
        missed: Set<String>
    ) -> Bool {
        let ids = pool.filter { ItemDifficulty.of($0) == tier }
        guard !ids.isEmpty else { return true }
        let answered = ids.filter { seen.contains($0) }
        let needed = max(1, Int((Double(ids.count) * promotionCoverage).rounded(.up)))
        guard answered.count >= needed else { return false }
        let right = answered.filter { !missed.contains($0) }.count
        return Double(right) / Double(answered.count) >= promotionAccuracy
    }
}
