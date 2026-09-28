import Foundation

/// The Card Room: understand the card's sections and learn to read a rack.
/// Every example hand here is an ORIGINAL teaching hand, not a hand from the
/// NMJL card (the card itself is copyrighted, and skills transfer anyway).
enum CategoryContent {

    static let categoryCards: [Flashcard] = [
        Flashcard(
            id: "cat-year",
            frontTitle: "Year Hands",
            frontTiles: [.c(2), .dragon(.soap), .c(2), .b(6)],
            frontSubtitle: "2 - 0 - 2 - 6",
            backTitle: "Year Hands",
            backBody: HandCategory.year.howToSpot + " Usually near the top of the card, and a friendly section for new players."
        ),
        Flashcard(
            id: "cat-2468",
            frontTitle: "2468 (Evens)",
            frontTiles: [.c(2), .c(4), .b(6), .b(8)],
            frontSubtitle: "Even numbers only",
            backTitle: "2468",
            backBody: HandCategory.evens2468.howToSpot + " If your deal is heavy on 2s, 4s, 6s and 8s, start here and pass every odd tile."
        ),
        Flashcard(
            id: "cat-like",
            frontTitle: "Any Like Numbers",
            frontTiles: [.c(5), .b(5), .d(5)],
            frontSubtitle: "Same number, different suits",
            backTitle: "Any Like Numbers",
            backBody: HandCategory.likeNumbers.howToSpot + " Great fallback when one number keeps arriving from every direction."
        ),
        Flashcard(
            id: "cat-quints",
            frontTitle: "Quints",
            frontTiles: [.d(7), .d(7), .d(7), .d(7), .joker],
            frontSubtitle: "Five of a kind",
            backTitle: "Quints",
            backBody: HandCategory.quints.howToSpot + " Rule of thumb: don't commit to Quints with fewer than two jokers."
        ),
        Flashcard(
            id: "cat-run",
            frontTitle: "Consecutive Run",
            frontTiles: [.b(4), .b(5), .b(6), .b(7)],
            frontSubtitle: "Numbers in a row",
            backTitle: "Consecutive Run",
            backBody: HandCategory.consecutiveRun.howToSpot + " When in doubt early, lean consecutive: more of your random deal will fit."
        ),
        Flashcard(
            id: "cat-13579",
            frontTitle: "13579 (Odds)",
            frontTiles: [.c(1), .c(3), .d(5), .d(7), .d(9)],
            frontSubtitle: "Odd numbers only",
            backTitle: "13579",
            backBody: HandCategory.odds13579.howToSpot + " Odds section is usually the biggest on the card, so an odd-heavy deal has options."
        ),
        Flashcard(
            id: "cat-winds",
            frontTitle: "Winds & Dragons",
            frontTiles: [.wind(.north), .wind(.east), .wind(.west), .wind(.south)],
            frontSubtitle: "N E W S + dragons",
            backTitle: "Winds & Dragons",
            backBody: HandCategory.windsDragons.howToSpot + " Winds only show up here and there in other sections, so count yours: one or two = pass them, four or five = consider committing."
        ),
        Flashcard(
            id: "cat-369",
            frontTitle: "369",
            frontTiles: [.c(3), .b(6), .d(9)],
            frontSubtitle: "Threes, sixes, nines",
            backTitle: "369",
            backBody: HandCategory.threeSixNine.howToSpot + " Bonus: 3s and 9s also fit 13579, and 6s fit 2468, so a 369 start keeps other doors open."
        ),
        Flashcard(
            id: "cat-sp",
            frontTitle: "Singles & Pairs",
            frontTiles: [.c(1), .c(1), .b(3), .b(3)],
            frontSubtitle: "The no-joker zone",
            backTitle: "Singles & Pairs",
            backBody: HandCategory.singlesAndPairs.howToSpot + " New players should admire it from a distance: every tile but the winning one must be drawn or come through the Charleston."
        ),
        // Reading a single line of the card. The notation here is generic
        // teaching shorthand (a group of 4s, a D), never a line from the card.
        Flashcard(
            id: "cat-line-matching-dragon",
            frontTitle: "A line shows 4444 and a D, both in the same color.",
            frontTiles: [.c(4), .c(4), .c(4), .c(4), .dragon(.red)],
            frontSubtitle: "Your tiles: do they fill that part of the line?",
            backTitle: "Yes: Same Color, Same Suit",
            backBody: "A dragon printed in the same color as a number group is that suit's own dragon. 4 Craks go with the Red Dragon, so this fits. Green would belong with bams, and Soap with dots.",
            choice: CardChoice("Fits", "Doesn't fit", answerIndex: 0)
        ),
        Flashcard(
            id: "cat-line-opposite-dragon",
            frontTitle: "A line shows 4444 in one color and a D in a different color.",
            frontTiles: [.b(4), .b(4), .b(4), .b(4), .dragon(.green)],
            frontSubtitle: "Your tiles: do they fill that part of the line?",
            backTitle: "No: Different Color, Different Suit",
            backBody: "A dragon in a different color from the numbers has to come from a different suit. Green is the bams' own dragon, so it matches these 4 Bams instead of contrasting with them. A Red Dragon or a Soap would fit.",
            choice: CardChoice("Fits", "Doesn't fit", answerIndex: 1)
        ),
        Flashcard(
            id: "cat-line-any-number",
            frontTitle: "A Like Numbers line is printed with 1s.",
            frontTiles: [.c(7), .c(7), .c(7), .c(7), .b(7), .b(7), .b(7), .b(7)],
            frontSubtitle: "Can you play it with 7s instead?",
            backTitle: "Yes, Any Number Works",
            backBody: "In Any Like Numbers the 1s are a placeholder. Any number works as long as every group on the line uses the same one, so 7s in the colors the line shows are just as good as 1s.",
            choice: CardChoice("Yes", "No, only 1s", answerIndex: 0)
        ),
        Flashcard(
            id: "cat-line-run-slides",
            frontTitle: "A Consecutive Run line is printed with 1s, 2s and 3s.",
            frontTiles: [.d(5), .d(5), .d(6), .d(6), .d(6), .d(7), .d(7)],
            frontSubtitle: "Can you play it with 5s, 6s and 7s?",
            backTitle: "Yes, Unless the Line Says Otherwise",
            backBody: "Run lines show the lowest numbers, and most can start anywhere as long as the numbers stay in order with no gaps. Read the note beside the line: a run that names its numbers cannot slide.",
            choice: CardChoice("Yes, unless noted", "No, only 1-2-3", answerIndex: 0)
        ),
        Flashcard(
            id: "cat-line-concealed",
            frontTitle: "Your target line is marked C, and you already exposed a pung.",
            frontTiles: [.b(4), .b(4), .b(4)],
            frontSubtitle: "Can you still win with that line?",
            backTitle: "No, Pick Another Line",
            backBody: "C means concealed: nothing may be exposed before mah jongg. Once a group is face up on your rack, every C line is closed to you, and only X lines can still win.",
            choice: CardChoice("Yes", "No", answerIndex: 1)
        ),
        Flashcard(
            id: "cat-line-news",
            frontTitle: "A line includes NEWS.",
            frontTiles: [.wind(.north), .wind(.east), .joker, .wind(.south)],
            frontSubtitle: "Can the joker stand in for the West?",
            backTitle: "No, Every Letter Is Real",
            backBody: "NEWS means one North, one East, one West and one South: four single tiles. Jokers never fill a single, so every wind has to be the real tile.",
            choice: CardChoice("Yes", "No", answerIndex: 1)
        ),
        Flashcard(
            id: "cat-line-year-soap",
            frontTitle: "Your year hand's 2s and 6 are Craks.",
            frontTiles: [.c(2), .dragon(.soap), .c(2), .c(6)],
            frontSubtitle: "Can the Soap be your 0?",
            backTitle: "Yes, a Zero Has No Suit",
            backBody: "Used as a zero, the Soap goes with any suit. It only has to line up with Dots when it is playing its other role, as the dots' dragon.",
            choice: CardChoice("Yes", "No, only with Dots", answerIndex: 0)
        ),
    ]

    static let handMatch: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "hm-2468",
            tiles: [.c(2), .c(2), .c(4), .c(4), .c(4), .b(6), .b(6), .b(8), .d(8), .d(8), .flower, .flower, .joker],
            choices: [.evens2468, .odds13579, .consecutiveRun, .likeNumbers],
            answer: .evens2468,
            explanation: "Every number tile is even: 2s, 4s, 6s, 8s across suits, plus flowers and a joker that fit anywhere. This rack is screaming 2468."
        ),
        HandMatchQuestion(
            id: "hm-run",
            tiles: [.c(3), .c(4), .c(5), .b(4), .b(5), .b(6), .d(5), .d(6), .d(7), .d(7), .wind(.north), .flower, .joker],
            choices: [.consecutiveRun, .evens2468, .threeSixNine, .year],
            answer: .consecutiveRun,
            explanation: "3-4-5, 4-5-6, 5-6-7: stepping numbers in all three suits. Mixed odds and evens rule out 2468 and 13579; Consecutive Run eats this deal up."
        ),
        HandMatchQuestion(
            id: "hm-odds",
            tiles: [.b(1), .b(1), .b(3), .b(3), .b(5), .b(5), .c(7), .c(9), .c(9), .flower, .d(2), .joker, .wind(.north)],
            choices: [.odds13579, .singlesAndPairs, .evens2468, .quints],
            answer: .odds13579,
            explanation: "1s, 3s, 5s, 7s, 9s: all odd except one stray 2 Dot. Three pairs of odd bams is a strong 13579 spine. The 2D and lone wind are your first passes."
        ),
        HandMatchQuestion(
            id: "hm-winds",
            tiles: [.wind(.north), .wind(.north), .wind(.north), .wind(.east), .wind(.east), .wind(.west), .wind(.south), .wind(.south), .dragon(.red), .dragon(.green), .c(4), .flower, .joker],
            choices: [.windsDragons, .year, .likeNumbers, .odds13579],
            answer: .windsDragons,
            explanation: "Eight winds including a pung of Norths, plus two dragons. Only one number tile in the whole rack. This is a Winds & Dragons hand waiting to happen."
        ),
        HandMatchQuestion(
            id: "hm-369",
            tiles: [.c(3), .c(3), .c(6), .c(6), .c(6), .b(9), .b(9), .d(3), .d(6), .d(9), .d(9), .flower, .b(2)],
            choices: [.threeSixNine, .consecutiveRun, .evens2468, .likeNumbers],
            answer: .threeSixNine,
            explanation: "Every number is a 3, 6, or 9 except the stray 2 Bam. A pung of 6 Craks plus pairs of 9s puts you well on the way in the 369 section."
        ),
        HandMatchQuestion(
            id: "hm-like",
            tiles: [.c(5), .c(5), .b(5), .b(5), .b(5), .d(5), .d(5), .d(5), .c(2), .b(8), .flower, .joker, .wind(.north)],
            choices: [.likeNumbers, .odds13579, .quints, .consecutiveRun],
            answer: .likeNumbers,
            explanation: "EIGHT fives across all three suits. When one number floods your rack like this, Any Like Numbers is the shortest road home."
        ),
        HandMatchQuestion(
            id: "hm-year",
            tiles: [.c(2), .c(2), .dragon(.soap), .dragon(.soap), .b(2), .b(2), .b(6), .b(6), .flower, .flower, .flower, .joker, .d(4)],
            choices: [.year, .evens2468, .windsDragons, .singlesAndPairs],
            answer: .year,
            explanation: "2s, Soaps (zeros), 6s, and a fistful of flowers: those are exactly the ingredients of a 2026 year hand. 2468 is the decoy, but the soaps give it away."
        ),
        HandMatchQuestion(
            id: "hm-quints",
            tiles: [.joker, .joker, .joker, .b(7), .b(7), .b(7), .d(7), .d(7), .d(7), .flower, .flower, .wind(.north), .c(5)],
            choices: [.quints, .likeNumbers, .odds13579, .consecutiveRun],
            answer: .quints,
            explanation: "Two pungs of 7s and three jokers. Two jokers finish one pung into a quint, and the third leaves the other pung one real 7 short of a second. Without jokers you would read this as Like Numbers; with them, Quints is live and pays far more. Jokers decide."
        ),
        HandMatchQuestion(
            id: "hm-sp",
            tiles: [.c(1), .c(1), .c(3), .c(3), .b(5), .b(5), .b(7), .b(7), .d(9), .d(9), .wind(.north), .wind(.north), .wind(.east)],
            choices: [.singlesAndPairs, .odds13579, .windsDragons, .evens2468],
            answer: .singlesAndPairs,
            explanation: "Six natural pairs and zero jokers. That's a rare, precious start: Singles & Pairs is the one section where this rack is nearly home. (13579 is a fine backup.)"
        ),
    ]
}
