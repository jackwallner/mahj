import Foundation

enum Suit: String, Codable, CaseIterable, Sendable {
    case crak, bam, dot

    var displayName: String {
        switch self {
        case .crak: return String(localized: "Crak")
        case .bam: return String(localized: "Bam")
        case .dot: return String(localized: "Dot")
        }
    }

    var pluralName: String {
        switch self {
        case .crak: return String(localized: "Craks")
        case .bam: return String(localized: "Bams")
        case .dot: return String(localized: "Dots")
        }
    }
}

enum Wind: String, Codable, CaseIterable, Sendable {
    case north, east, west, south

    var letter: String { rawValue.prefix(1).uppercased() }
    var displayName: String {
        switch self {
        case .north: return String(localized: "North")
        case .east: return String(localized: "East")
        case .west: return String(localized: "West")
        case .south: return String(localized: "South")
        }
    }
}

enum Dragon: String, Codable, CaseIterable, Sendable {
    case red, green, soap

    var displayName: String {
        switch self {
        case .red: return String(localized: "Red Dragon")
        case .green: return String(localized: "Green Dragon")
        case .soap: return String(localized: "Soap")
        }
    }

    var pluralName: String {
        switch self {
        case .red: return String(localized: "Red Dragons")
        case .green: return String(localized: "Green Dragons")
        case .soap: return String(localized: "Soaps")
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
        case .suited(let rank, let suit):
            return String(localized: "\(rank) \(suit.displayName)", comment: "A tile's name: its number, then its suit")
        case .wind(.north): return String(localized: "North Wind")
        case .wind(.east): return String(localized: "East Wind")
        case .wind(.west): return String(localized: "West Wind")
        case .wind(.south): return String(localized: "South Wind")
        case .dragon(let dragon): return dragon.displayName
        case .flower: return String(localized: "Flower")
        case .joker: return String(localized: "Joker")
        }
    }

    /// The English name, for orderings that must not change with the
    /// player's language (a shared daily question has to be the same
    /// question everywhere). Never shown.
    var englishName: String {
        switch self {
        case .suited(let rank, let suit): return "\(rank) \(suit.rawValue.capitalized)"
        case .wind(let wind): return "\(wind.rawValue.capitalized) Wind"
        case .dragon(.red): return "Red Dragon"
        case .dragon(.green): return "Green Dragon"
        case .dragon(.soap): return "Soap"
        case .flower: return "Flower"
        case .joker: return "Joker"
        }
    }

    /// The name for two or more of this tile: "7 Bams", "Flowers".
    var pluralName: String {
        switch self {
        case .suited(let rank, let suit):
            return String(localized: "\(rank) \(suit.pluralName)", comment: "Several of one tile: its number, then its suit in the plural")
        case .wind(.north): return String(localized: "North Winds")
        case .wind(.east): return String(localized: "East Winds")
        case .wind(.west): return String(localized: "West Winds")
        case .wind(.south): return String(localized: "South Winds")
        case .dragon(let dragon): return dragon.pluralName
        case .flower: return String(localized: "Flowers")
        case .joker: return String(localized: "Jokers")
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
