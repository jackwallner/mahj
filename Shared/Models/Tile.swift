import Foundation

enum Suit: String, Codable, CaseIterable, Sendable {
    case crak, bam, dot

    var displayName: String {
        switch self {
        case .crak: return "Crak"
        case .bam: return "Bam"
        case .dot: return "Dot"
        }
    }
}

enum Wind: String, Codable, CaseIterable, Sendable {
    case north, east, west, south

    var letter: String { rawValue.prefix(1).uppercased() }
    var displayName: String { rawValue.capitalized }
}

enum Dragon: String, Codable, CaseIterable, Sendable {
    case red, green, soap

    var displayName: String {
        switch self {
        case .red: return "Red Dragon"
        case .green: return "Green Dragon"
        case .soap: return "Soap"
        }
    }

    /// The suit this dragon belongs with on the card.
    var matchingSuit: Suit {
        switch self {
        case .red: return .crak
        case .green: return .bam
        case .soap: return .dot
        }
    }
}

enum Tile: Hashable, Codable, Sendable {
    case suited(rank: Int, suit: Suit)
    case wind(Wind)
    case dragon(Dragon)
    case flower
    case joker

    // Shorthand for content authoring.
    static func c(_ rank: Int) -> Tile { .suited(rank: rank, suit: .crak) }
    static func b(_ rank: Int) -> Tile { .suited(rank: rank, suit: .bam) }
    static func d(_ rank: Int) -> Tile { .suited(rank: rank, suit: .dot) }

    var shortLabel: String {
        switch self {
        case .suited(let rank, let suit): return "\(rank)\(suit.rawValue.prefix(1).uppercased())"
        case .wind(let wind): return wind.letter
        case .dragon(.red): return "RD"
        case .dragon(.green): return "GD"
        case .dragon(.soap): return "SO"
        case .flower: return "F"
        case .joker: return "J"
        }
    }

    var spokenName: String {
        switch self {
        case .suited(let rank, let suit): return "\(rank) \(suit.displayName)"
        case .wind(let wind): return "\(wind.displayName) Wind"
        case .dragon(let dragon): return dragon.displayName
        case .flower: return "Flower"
        case .joker: return "Joker"
        }
    }

    /// Sort key so hands display grouped the way players rack them.
    var sortKey: Int {
        switch self {
        case .suited(let rank, let suit):
            let suitOrder = [Suit.crak: 0, .bam: 1, .dot: 2][suit] ?? 0
            return suitOrder * 10 + rank
        case .dragon(let dragon):
            return 30 + ([Dragon.red: 0, .green: 1, .soap: 2][dragon] ?? 0)
        case .wind(let wind):
            return 40 + ([Wind.north: 0, .east: 1, .west: 2, .south: 3][wind] ?? 0)
        case .flower: return 50
        case .joker: return 60
        }
    }
}

extension Array where Element == Tile {
    var racked: [Tile] { sorted { $0.sortKey < $1.sortKey } }
}
