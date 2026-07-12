import Foundation

/// The Tile Room: meet the tiles, learn the vocabulary. All free.
enum TileBasicsContent {

    static let meetTheTiles: [Flashcard] = [
        Flashcard(
            id: "tiles-craks",
            frontTitle: "Craks",
            frontTiles: [.c(1), .c(5), .c(9)],
            backTitle: "Craks (Characters)",
            backBody: "36 tiles: numbers 1 through 9, four of each. On real tiles the number sits above a red Chinese character. Craks partner with the Red Dragon on the card."
        ),
        Flashcard(
            id: "tiles-bams",
            frontTitle: "Bams",
            frontTiles: [.b(1), .b(5), .b(9)],
            backTitle: "Bams (Bamboo)",
            backBody: "36 tiles: numbers 1 through 9, four of each, drawn as green bamboo sticks. Bams partner with the Green Dragon. Heads up: the 1 Bam is usually a bird!"
        ),
        Flashcard(
            id: "tiles-dots",
            frontTitle: "Dots",
            frontTiles: [.d(1), .d(5), .d(9)],
            backTitle: "Dots (Circles)",
            backBody: "36 tiles: numbers 1 through 9, four of each, drawn as circles. Dots partner with the Soap (White Dragon)."
        ),
        Flashcard(
            id: "tiles-winds",
            frontTitle: "Winds",
            frontTiles: [.wind(.north), .wind(.east), .wind(.west), .wind(.south)],
            backTitle: "The Winds",
            backBody: "16 tiles: North, East, West, South, four of each. They mostly live in the Winds & Dragons section of the card, so lone winds are usually early passes."
        ),
        Flashcard(
            id: "tiles-dragons",
            frontTitle: "Dragons",
            frontTiles: [.dragon(.red), .dragon(.green), .dragon(.soap)],
            backTitle: "The Dragons",
            backBody: "12 tiles: 4 Red, 4 Green, 4 Soap. Each dragon belongs to a suit: Red goes with Craks, Green with Bams, Soap with Dots. When a card hand shows a dragon, it must match the suit you're using."
        ),
        Flashcard(
            id: "tiles-soap",
            frontTitle: "The Soap",
            frontTiles: [.dragon(.soap)],
            frontSubtitle: "It has a second job",
            backTitle: "Soap = White Dragon = Zero",
            backBody: "The Soap is the White Dragon (it looks like a bar of soap). Besides being Dots' dragon, it stands in for ZERO in year hands, like the 0 in 2026."
        ),
        Flashcard(
            id: "tiles-flowers",
            frontTitle: "Flowers",
            frontTiles: [.flower, .flower],
            backTitle: "Flowers",
            backBody: "8 flower tiles, and in American mahj they are ALL interchangeable. Any flower works wherever the card shows an F. Flowers appear all over the card, so hold them early."
        ),
        Flashcard(
            id: "tiles-jokers",
            frontTitle: "Jokers",
            frontTiles: [.joker, .joker],
            frontSubtitle: "The most powerful tile",
            backTitle: "Jokers",
            backBody: "8 jokers. A joker stands in for any tile in a group of 3 or more (pung, kong, quint). It can NEVER be used in a pair or as a single tile, never in Singles & Pairs hands, and can never be passed in the Charleston."
        ),
        Flashcard(
            id: "tiles-count",
            frontTitle: "The Whole Set",
            frontSubtitle: "How many tiles?",
            backTitle: "152 Tiles",
            backBody: "108 number tiles (three suits, 1-9, four each) + 16 winds + 12 dragons + 8 flowers + 8 jokers = 152. American sets are bigger than Chinese sets because of the flowers and jokers."
        ),
        Flashcard(
            id: "tiles-card",
            frontTitle: "The Card",
            frontSubtitle: "Why everyone squints at it",
            backTitle: "The NMJL Card",
            backBody: "The card lists every legal winning hand this year, grouped in sections (2468, Consecutive Run, 13579...). A new card comes out every spring. Colors on the card mean DIFFERENT suits, not specific ones: any suit can be red, green, or blue."
        ),
        Flashcard(
            id: "tiles-groups",
            frontTitle: "Pung, Kong, Quint",
            frontSubtitle: "The building blocks",
            backTitle: "Groups",
            backBody: "Pair = 2 identical tiles. Pung = 3. Kong = 4. Quint = 5 (only possible with jokers, since only four of each tile exist). Card hands are built from these blocks plus singles."
        ),
        Flashcard(
            id: "tiles-concealed",
            frontTitle: "C vs X on the Card",
            frontSubtitle: "Those little letters by the value",
            backTitle: "Concealed vs Exposed",
            backBody: "X = you may call discards and expose groups on your rack. C = concealed: no exposures allowed before mahj jongg (you may still call the final winning tile). Concealed hands are harder, so they pay more."
        ),
    ]

    static let tileQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "quiz-dragon-crak",
            prompt: "Which dragon goes with a crak hand?",
            tiles: [.c(3), .c(3), .c(3)],
            choices: ["Red Dragon", "Green Dragon", "Soap", "Any dragon"],
            answerIndex: 0,
            explanation: "Red goes with Craks. Remember C-R: Craks are Red. Green belongs to Bams, Soap to Dots."
        ),
        QuizQuestion(
            id: "quiz-dragon-bam",
            prompt: "Your hand is all bams. Which dragon do you need?",
            tiles: [.b(4), .b(4), .b(8), .b(8)],
            choices: ["Red Dragon", "Green Dragon", "Soap", "Any dragon"],
            answerIndex: 1,
            explanation: "Green goes with Bams: bamboo is green. Easy one to picture."
        ),
        QuizQuestion(
            id: "quiz-dragon-dot",
            prompt: "Which dragon matches a dot hand?",
            tiles: [.d(2), .d(2), .d(6), .d(6)],
            choices: ["Red Dragon", "Green Dragon", "Soap", "Any dragon"],
            answerIndex: 2,
            explanation: "Soap (the White Dragon) goes with Dots. White soap, white circles."
        ),
        QuizQuestion(
            id: "quiz-joker-pair",
            prompt: "Can a joker complete a pair?",
            choices: ["Yes, jokers work anywhere", "No, never", "Only in year hands", "Only if exposed"],
            answerIndex: 1,
            explanation: "Never. Jokers only work in groups of 3 or more (pung, kong, quint). Pairs and singles must be the real tiles."
        ),
        QuizQuestion(
            id: "quiz-joker-charleston",
            prompt: "Can you pass a joker in the Charleston?",
            choices: ["Yes", "Only on the blind pass", "No, it's against the rules", "Only in the courtesy pass"],
            answerIndex: 2,
            explanation: "Jokers may never be passed in the Charleston or the courtesy pass. It's not just bad strategy, it's illegal."
        ),
        QuizQuestion(
            id: "quiz-soap-zero",
            prompt: "In a year hand like 2026, what stands in for the 0?",
            choices: ["A flower", "The Soap", "A joker", "The White... wait, any dragon"],
            answerIndex: 1,
            explanation: "The Soap (White Dragon) doubles as zero. 2026 = 2, Soap, 2, 6."
        ),
        QuizQuestion(
            id: "quiz-joker-count",
            prompt: "How many jokers are in an American mahj set?",
            choices: ["4", "6", "8", "12"],
            answerIndex: 2,
            explanation: "Eight jokers. That's also why counting them matters: if you've seen 6 on racks and discards, only 2 are left in play."
        ),
        QuizQuestion(
            id: "quiz-pung",
            prompt: "What is a pung?",
            tiles: [.d(7), .d(7), .d(7)],
            choices: ["2 identical tiles", "3 identical tiles", "4 identical tiles", "A run like 5-6-7"],
            answerIndex: 1,
            explanation: "Three identical tiles. And no, unlike other mahjong styles, American mahj has no runs you can 'chow': the card decides every shape."
        ),
        QuizQuestion(
            id: "quiz-quint",
            prompt: "Only four of each tile exist. How is a quint (5 of a kind) possible?",
            choices: ["It isn't", "Borrow from the wall", "Jokers", "Use two suits"],
            answerIndex: 2,
            explanation: "Jokers. Every quint needs at least one. That's why Quints hands pay so well."
        ),
        QuizQuestion(
            id: "quiz-flowers-same",
            prompt: "Are all 8 flowers interchangeable?",
            tiles: [.flower, .flower],
            choices: ["Yes, any flower is any F", "No, they're numbered", "Only in pairs", "Only 4 of them"],
            answerIndex: 0,
            explanation: "In American mahj every flower is identical for play. If the card says FF, any two flowers work."
        ),
        QuizQuestion(
            id: "quiz-sp-jokers",
            prompt: "Jokers in a Singles & Pairs hand?",
            choices: ["Allowed anywhere", "Only in the pairs", "Never allowed", "One per hand"],
            answerIndex: 2,
            explanation: "Never. Singles & Pairs hands have no groups of 3+, and jokers only work in groups of 3+. That's why S&P pays the most."
        ),
        QuizQuestion(
            id: "quiz-concealed",
            prompt: "A hand marked C on the card means...",
            choices: ["Craks only", "Concealed: no exposures", "Courtesy hand", "Charleston required"],
            answerIndex: 1,
            explanation: "Concealed. You can't call discards to expose groups; the hand stays on your rack until you call the winning tile for mahj jongg."
        ),
        QuizQuestion(
            id: "quiz-colors",
            prompt: "A card hand shows numbers in green, red, and blue. What do the colors mean?",
            choices: ["Bams, craks, dots exactly", "Three different suits, any order", "Dragons required", "Nothing, just decoration"],
            answerIndex: 1,
            explanation: "Colors mean DIFFERENT suits, not specific ones. Green-red-blue just tells you the hand uses three suits; you pick which is which."
        ),
        QuizQuestion(
            id: "quiz-hand-size",
            prompt: "How many tiles do you hold during play (before your turn)?",
            choices: ["12", "13", "14", "16"],
            answerIndex: 1,
            explanation: "Thirteen. You draw a 14th, then discard (or keep it and discard something else). Mahj jongg = 14 tiles matching a card hand exactly."
        ),
        QuizQuestion(
            id: "quiz-joker-exchange",
            prompt: "An opponent's exposed kong contains a joker. You hold the real matching tile. Can you swap?",
            choices: ["No, exposures are locked", "Yes, on your turn", "Only if they agree", "Only for your own exposures"],
            answerIndex: 1,
            explanation: "Yes, but only after you draw or call your 14th tile. Then you can exchange the real tile for any exposed joker, yours or an opponent's. Free joker. Always scan the racks."
        ),
        QuizQuestion(
            id: "quiz-dead-joker",
            prompt: "Someone discards a joker. Can you call it?",
            choices: ["Yes, like any discard", "Only for mahj jongg", "No, discarded jokers are dead", "Only with a pung"],
            answerIndex: 2,
            explanation: "A discarded joker is dead: nobody can call it for anything. Which is why you basically never throw one."
        ),
    ]
}
