import Foundation

enum DrillLibrary {

    static let rooms: [Room] = [
        Room(
            id: "tile-room",
            name: "The Tile Room",
            tagline: "Meet the tiles and talk the talk",
            icon: "square.grid.3x3.fill",
            isFree: true,
            drills: [
                Drill(
                    id: "meet-tiles",
                    title: "Meet the Tiles",
                    subtitle: "Flashcards: every tile family and what it does",
                    kind: .flashcards(TileBasicsContent.meetTheTiles)
                ),
                Drill(
                    id: "tile-quiz",
                    title: "Tile Check",
                    subtitle: "Quick quiz: dragons, jokers, and the rules everyone gets wrong",
                    kind: .quiz(TileBasicsContent.tileQuiz)
                ),
            ]
        ),
        Room(
            id: "card-room",
            name: "The Card Room",
            tagline: "Learn to read the card and your rack",
            icon: "menucard.fill",
            isFree: true,
            drills: [
                Drill(
                    id: "category-cards",
                    title: "Know the Sections",
                    subtitle: "Flashcards: every card section and how to spot it",
                    kind: .flashcards(CategoryContent.categoryCards)
                ),
                Drill(
                    id: "hand-match",
                    title: "Read the Rack",
                    subtitle: "See 13 tiles, name the section they're chasing",
                    kind: .handMatch(CategoryContent.handMatch)
                ),
            ]
        ),
        Room(
            id: "charleston-room",
            name: "The Charleston Room",
            tagline: "Practice the pass without the pressure",
            icon: "arrow.triangle.2.circlepath",
            isFree: true,
            drills: [
                Drill(
                    id: "charleston-rules",
                    title: "Charleston Playbook",
                    subtitle: "Flashcards: the rules and the strategy",
                    kind: .flashcards(CharlestonContent.strategyCards)
                ),
                Drill(
                    id: "charleston-pass",
                    title: "Pick Your Pass",
                    subtitle: "Real deals: choose 3 tiles to pass, then compare with the coach",
                    kind: .charleston(CharlestonContent.scenarios)
                ),
            ]
        ),
        Room(
            id: "table-room",
            name: "The Table Room",
            tagline: "Keep-or-throw judgment for real games",
            icon: "hand.point.up.left.fill",
            isFree: true,
            drills: [
                Drill(
                    id: "judgment-cards",
                    title: "Keep or Throw",
                    subtitle: "Make the call, then flip to see the coach's answer",
                    kind: .flashcards(KeepDiscardContent.judgmentCards)
                ),
            ]
        ),
        Room(
            id: "pro-tables",
            name: "The Pro Tables",
            tagline: "Advanced play for when the basics feel easy",
            icon: "crown.fill",
            isFree: false,
            drills: [
                Drill(
                    id: "pro-charleston",
                    title: "Advanced Charleston",
                    subtitle: "Torn deals, pair math, and defending with your pass",
                    kind: .charleston(ProContent.advancedCharleston)
                ),
                Drill(
                    id: "pro-defense",
                    title: "Defense School",
                    subtitle: "Read exposures, count tiles, and stop feeding winners",
                    kind: .quiz(ProContent.defenseQuiz)
                ),
                Drill(
                    id: "pro-rack-reading",
                    title: "Expert Rack Reading",
                    subtitle: "Ambiguous racks where two sections look right",
                    kind: .handMatch(ProContent.expertRackReading)
                ),
            ]
        ),
    ]

    static func room(id: String) -> Room? {
        rooms.first { $0.id == id }
    }
}
