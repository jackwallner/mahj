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
}
