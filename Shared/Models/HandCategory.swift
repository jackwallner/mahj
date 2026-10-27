import Foundation

/// The stable category families that appear on the NMJL card year after year.
/// All example hands in this app are original teaching hands, not card hands.
enum HandCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case year
    case evens2468
    case likeNumbers
    case quints
    case consecutiveRun
    case odds13579
    case windsDragons
    case threeSixNine
    case singlesAndPairs

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .year: return String(localized: "Year Hands")
        case .evens2468: return String(localized: "2468 (Evens)")
        case .likeNumbers: return String(localized: "Any Like Numbers")
        case .quints: return String(localized: "Quints")
        case .consecutiveRun: return String(localized: "Consecutive Run")
        case .odds13579: return String(localized: "13579 (Odds)")
        case .windsDragons: return String(localized: "Winds & Dragons")
        case .threeSixNine: return String(localized: "369")
        case .singlesAndPairs: return String(localized: "Singles & Pairs")
        }
    }

    var shortName: String {
        switch self {
        case .year: return String(localized: "Year")
        case .evens2468: return String(localized: "2468")
        case .likeNumbers: return String(localized: "Like Numbers")
        case .quints: return String(localized: "Quints")
        case .consecutiveRun: return String(localized: "Consec. Run")
        case .odds13579: return String(localized: "13579")
        case .windsDragons: return String(localized: "Winds-Dragons")
        case .threeSixNine: return String(localized: "369")
        case .singlesAndPairs: return String(localized: "Singles & Pairs")
        }
    }

    var howToSpot: String {
        switch self {
        case .year:
            return String(localized: "Built around the current year's digits, with soaps standing in for zeros. Spot it when you're holding 2s and soaps.")
        case .evens2468:
            return String(localized: "Only even numbers (2, 4, 6, 8). Every odd tile in your hand is dead weight for this section.")
        case .likeNumbers:
            return String(localized: "The same number collected across different suits. Spot it when one number keeps showing up in two or three suits at once.")
        case .quints:
            return String(localized: "Needs five of a kind, and only four of each tile exist, so quints are impossible without jokers. Only chase these when you're joker-rich.")
        case .consecutiveRun:
            return String(localized: "Numbers that step up in order, like 4-5-6-7. Unless a line's note names its numbers, a run can start on any number, so a deal with numbers in a row can fit more than one line.")
        case .odds13579:
            return String(localized: "Only odd numbers (1, 3, 5, 7, 9). The mirror image of 2468, with one more number to build from.")
        case .windsDragons:
            return String(localized: "Built mostly from N, E, W, S and the dragons, sometimes with a few numbers. Spot it when winds keep piling up on your rack.")
        case .threeSixNine:
            return String(localized: "Only 3s, 6s and 9s. It is a small, focused family, so if you hold several of those three numbers, look here.")
        case .singlesAndPairs:
            return String(localized: "No pungs or kongs, just single tiles and pairs. No jokers are allowed.")
        }
    }

    /// The one thing this section demands, in a sentence. Used to explain a
    /// wrong pick: a player who chose 369 needs to hear what 369 actually
    /// wants, not just that they were wrong.
    var requires: String {
        switch self {
        case .year:
            return String(localized: "a year hand is built from the year's digits, with soaps for zeros, so it wants 2s and soaps rather than a spread of numbers")
        case .evens2468:
            return String(localized: "an evens hand uses only 2s, 4s, 6s and 8s for its numbers, so look for it when those four numbers fill the rack")
        case .likeNumbers:
            return String(localized: "like numbers means the same number across different suits, so a rack spread across several numbers is not it")
        case .quints:
            return String(localized: "quints need five of a kind, which is impossible without jokers, so this is a joker question before it is a number question")
        case .consecutiveRun:
            return String(localized: "a run needs numbers stepping up in order with no gaps, which always mixes odd and even")
        case .odds13579:
            return String(localized: "an odds hand uses only 1s, 3s, 5s, 7s and 9s for its numbers, so look for it when odd numbers fill the rack")
        case .windsDragons:
            return String(localized: "this section is built mostly from winds and dragons, so a rack full of number tiles is not it")
        case .threeSixNine:
            return String(localized: "369 uses only 3s, 6s and 9s for its numbers, and it needs the 6 to tell it apart from a pure evens or pure odds hand")
        case .singlesAndPairs:
            return String(localized: "singles and pairs means no pungs or kongs at all, and no jokers anywhere")
        }
    }

    /// Per-choice coaching for a section question: nothing for the right
    /// answer, and for every wrong one, what that section would have needed.
    static func missNotes(for choices: [HandCategory], answer: HandCategory) -> [String?] {
        choices.map { choice in
            choice == answer ? nil : String(localized: "\(choice.displayName): \(choice.requires).", comment: "A section name, then what that section needs")
        }
    }
}
