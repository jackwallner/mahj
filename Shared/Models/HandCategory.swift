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
        case .year: return "Year Hands"
        case .evens2468: return "2468 (Evens)"
        case .likeNumbers: return "Any Like Numbers"
        case .quints: return "Quints"
        case .consecutiveRun: return "Consecutive Run"
        case .odds13579: return "13579 (Odds)"
        case .windsDragons: return "Winds & Dragons"
        case .threeSixNine: return "369"
        case .singlesAndPairs: return "Singles & Pairs"
        }
    }

    var shortName: String {
        switch self {
        case .year: return "Year"
        case .evens2468: return "2468"
        case .likeNumbers: return "Like Numbers"
        case .quints: return "Quints"
        case .consecutiveRun: return "Consec. Run"
        case .odds13579: return "13579"
        case .windsDragons: return "Winds-Dragons"
        case .threeSixNine: return "369"
        case .singlesAndPairs: return "Singles & Pairs"
        }
    }

    var howToSpot: String {
        switch self {
        case .year:
            return "Built around the current year's digits, with soaps standing in for zeros. Spot it when you're holding 2s and soaps plus flowers."
        case .evens2468:
            return "Only even numbers: 2, 4, 6, 8. Every odd tile in your hand is dead weight for this section."
        case .likeNumbers:
            return "The same number collected across all three suits. Spot it when one number keeps showing up in craks, bams, AND dots."
        case .quints:
            return "Needs five of a kind, and only four of each tile exist, so quints are impossible without jokers. Only chase these when you're joker-rich."
        case .consecutiveRun:
            return "Numbers that step up in order, like 4-5-6-7. The most flexible section on the card because any starting number can work."
        case .odds13579:
            return "Only odd numbers: 1, 3, 5, 7, 9. The mirror image of 2468, usually with more hand choices."
        case .windsDragons:
            return "Built from N, E, W, S and the dragons. Spot it when winds keep piling up on your rack."
        case .threeSixNine:
            return "Only 3s, 6s, and 9s. A small, focused family: if you hold several of those three numbers, look here."
        case .singlesAndPairs:
            return "No pungs or kongs, just single tiles and pairs. NO JOKERS ALLOWED, which is why these hands pay the most."
        }
    }

    /// The one thing this section demands, in a sentence. Used to explain a
    /// wrong pick: a player who chose 369 needs to hear what 369 actually
    /// wants, not just that they were wrong.
    var requires: String {
        switch self {
        case .year:
            return "a year hand is built from the year's digits, with soaps for zeros, so it wants 2s and soaps rather than a spread of numbers"
        case .evens2468:
            return "an evens hand can contain 2s, 4s, 6s and 8s and nothing else, so a single odd tile rules it out"
        case .likeNumbers:
            return "like numbers means the SAME number in all three suits, so a rack spread across several numbers is not it"
        case .quints:
            return "quints need five of a kind, which is impossible without jokers, so this is a joker question before it is a number question"
        case .consecutiveRun:
            return "a run needs numbers stepping up in order with no gaps, which always mixes odd and even"
        case .odds13579:
            return "an odds hand can contain 1s, 3s, 5s, 7s and 9s and nothing else, so a single even tile rules it out"
        case .windsDragons:
            return "this section is honors only, so any numbered tile on the rack rules it out"
        case .threeSixNine:
            return "369 wants only 3s, 6s and 9s, and it needs the 6 to tell it apart from a pure evens or pure odds hand"
        case .singlesAndPairs:
            return "singles and pairs means no pungs or kongs at all, and no jokers anywhere"
        }
    }

    /// Per-choice coaching for a section question: nothing for the right
    /// answer, and for every wrong one, what that section would have needed.
    static func missNotes(for choices: [HandCategory], answer: HandCategory) -> [String?] {
        choices.map { choice in
            choice == answer ? nil : "\(choice.displayName): \(choice.requires)."
        }
    }
}
