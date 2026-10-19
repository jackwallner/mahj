import Foundation

/// The Charleston Room: rules and strategy for the passing phase,
/// plus interactive "pick 3 to pass" scenarios.
enum CharlestonContent {

    static let strategyCards: [Flashcard] = [
        Flashcard(
            id: "ch-what",
            frontTitle: "What is the Charleston?",
            frontSubtitle: "The part that scares everyone",
            backTitle: "The Charleston",
            backBody: "Before play starts, everyone passes tiles: three passes (right, across, left), an optional second round (left, across, right), then an optional courtesy pass across. Each Charleston pass is 3 tiles. It exists so you can trade junk for a real hand."
        ),
        Flashcard(
            id: "ch-first-look",
            frontTitle: "Before Your First Pass",
            frontSubtitle: "What do you do with a fresh deal?",
            backTitle: "Sort, Then Shortlist",
            backBody: "Rack your tiles by suit and number, then shortlist 2-3 card sections your deal leans toward. Don't marry one hand yet: pass the tiles that help NONE of your shortlist."
        ),
        Flashcard(
            id: "ch-jokers",
            frontTitle: "Jokers in the Charleston",
            frontSubtitle: "Rule, not suggestion",
            backTitle: "Never. It's Illegal.",
            backBody: "Jokers may never be passed in the Charleston or courtesy pass. If you're ever handed one, someone broke the rules. (Flowers CAN be passed, but usually shouldn't be early.)"
        ),
        Flashcard(
            id: "ch-flowers",
            frontTitle: "Should You Pass Flowers?",
            frontSubtitle: "They look useless...",
            backTitle: "Hold Them Early",
            backBody: "Flowers appear in sections all over the card, so a flower is rarely dead. Early in the Charleston, keep them. If you're deep into a hand with no F in it, they become passes."
        ),
        Flashcard(
            id: "ch-pairs",
            frontTitle: "Breaking Up Pairs",
            frontSubtitle: "You need 3 tiles to pass, and...",
            backTitle: "Don't Break Pairs",
            backBody: "Pairs are gold: jokers can't make them, so natural pairs anchor hands. Pass lone strays (single winds, isolated numbers) before you ever split a pair, even a pair you're not sure you'll use."
        ),
        Flashcard(
            id: "ch-blind",
            frontTitle: "The Blind Pass",
            frontSubtitle: "a.k.a. stealing",
            backTitle: "Blind Pass",
            backBody: "On the LAST pass of either Charleston, if you don't want to give up 3 tiles, you may pass 1-3 of the tiles being passed TO you without looking at them. Great when your hand is already tight."
        ),
        Flashcard(
            id: "ch-stop",
            frontTitle: "Stopping the Second Charleston",
            frontSubtitle: "You have this power",
            backTitle: "Anyone Can Stop It",
            backBody: "The second Charleston only happens if ALL players agree. If your hand is already strong after round one, say stop: extra passing mostly helps the players with bad hands."
        ),
        Flashcard(
            id: "ch-courtesy",
            frontTitle: "The Courtesy Pass",
            frontSubtitle: "The final exchange",
            backTitle: "Courtesy Pass",
            backBody: "After the Charleston, you and the player across can swap 0-3 tiles: you exchange the SAME number, agreed out loud ('two?'). Ask for fewer if your hand is close."
        ),
        Flashcard(
            id: "ch-watch",
            frontTitle: "Read the Incoming Tiles",
            frontSubtitle: "Free information",
            backTitle: "Passes Tell Stories",
            backBody: "Whatever arrives is what a neighbor DIDN'T need. Three winds from your right? They're not on Winds & Dragons. Also note what never comes back: those tiles are being collected."
        ),
        Flashcard(
            id: "ch-telegraph",
            frontTitle: "Don't Telegraph",
            frontSubtitle: "Passing has a defense side too",
            backTitle: "Split Related Tiles",
            backBody: "When your strays are equally useless to you, mix them across your passes rather than sending three of one family (say, 2C 4C 6C) to one player. It is a small edge: never keep a tile you need just to split a bundle."
        ),
    ]

    static let scenarios: [CharlestonScenario] = [
        CharlestonScenario(
            id: "cs-evens",
            situation: "First Charleston, pass RIGHT. Pick 3 tiles to pass.",
            deal: [.c(2), .c(2), .c(4), .c(4), .b(6), .b(6), .b(8), .d(8), .flower, .joker, .c(1), .b(9), .wind(.north)],
            recommendedPass: [.c(1), .b(9), .wind(.north)],
            reasoning: "This deal leans into 2468: eight even tiles with three pairs, plus a flower and a joker worth keeping. The 1 Crak and 9 Bam are odd, and they and the lone North help none of that. The joker can never be passed, and the flower should stay early.",
            tip: "First pass: dump the tiles that fit NONE of your 2-3 candidate sections."
        ),
        CharlestonScenario(
            id: "cs-winds",
            situation: "First Charleston, pass RIGHT. Pick 3 tiles to pass.",
            deal: [.wind(.north), .wind(.north), .wind(.north), .wind(.east), .wind(.west), .wind(.west), .wind(.south), .dragon(.red), .c(3), .d(6), .b(9), .flower, .joker],
            recommendedPass: [.c(3), .d(6), .b(9)],
            reasoning: "Seven winds and a dragon: this is a Winds & Dragons hand. The three scattered number tiles (3 Crak, 6 Dot, 9 Bam) are strays in three different suits, with nothing to build on for a winds plan. Easy passes.",
            tip: "A pung of winds is a commitment. Once you have one, feed it."
        ),
        CharlestonScenario(
            id: "cs-run",
            situation: "First Charleston, pass ACROSS. Pick 3 tiles to pass.",
            deal: [.c(4), .c(5), .c(6), .b(5), .b(6), .b(7), .d(6), .d(6), .c(1), .d(9), .wind(.north), .flower, .joker],
            recommendedPass: [.c(1), .d(9), .wind(.north)],
            reasoning: "Middle numbers 4 through 7 across Craks and Bams, plus a pair of 6 Dots: a Consecutive Run dream. The 1 and the 9 are long shots for a run built on 4 through 7, and the lone North is dead weight. Keep the 6 Dot pair: pairs anchor hands.",
            tip: "For Consecutive Run hands, middle numbers (4-7) leave the most room to build in either direction."
        ),
        CharlestonScenario(
            id: "cs-pairs",
            situation: "First Charleston, pass LEFT. Pick 3 tiles to pass.",
            deal: [.c(3), .c(3), .b(7), .b(7), .d(9), .d(9), .c(5), .b(1), .wind(.west), .d(4), .c(8), .flower, .joker],
            recommendedPass: [.d(4), .c(8), .wind(.west)],
            reasoning: "Three natural pairs of odd numbers point at 13579. Keep every odd tile: the 5 Crak and 1 Bam still fit odd hands. Pass the evens (4 Dot, 8 Crak) and the lone wind. Keep the pairs, since jokers can never make a pair for you.",
            tip: "Tiles that fit your section stay, even unpaired. Pass tiles from the WRONG number family first."
        ),
        CharlestonScenario(
            id: "cs-junk",
            situation: "First Charleston, pass RIGHT. Five winds and five scattered numbers. Pick 3.",
            deal: [.wind(.west), .wind(.west), .wind(.north), .wind(.east), .wind(.south), .c(2), .b(5), .d(8), .c(9), .d(1), .joker, .joker, .flower],
            recommendedPass: [.d(1), .c(9), .b(5)],
            reasoning: "Five winds plus two jokers is the start of a Winds & Dragons hand, so the five scattered number tiles are the likeliest passes. Send the 1 Dot, 9 Crak and 5 Bam now, and pass the 2 Crak and 8 Dot next. Keep the West pair, and the flower too, since many hands use flowers. Jokers can never be passed.",
            tip: "With a junk deal, let the strongest group set the plan. Strays are interchangeable; pairs and flowers are not."
        ),
        CharlestonScenario(
            id: "cs-flowers",
            situation: "First Charleston, pass ACROSS. Pick 3 tiles to pass.",
            deal: [.flower, .flower, .flower, .b(2), .b(4), .b(6), .b(8), .b(8), .d(2), .c(9), .wind(.north), .joker, .c(5)],
            recommendedPass: [.c(9), .c(5), .wind(.north)],
            reasoning: "Three flowers plus a wall of even bams: this deal wants an evens hand, and many hands use flowers, so keep them. The odd Craks (9 Crak, 5 Crak) and the lone North do not fit an evens plan.",
            tip: "Flowers turn up in hands across the card. Early passes should almost never include one."
        ),
        CharlestonScenario(
            id: "cs-like",
            situation: "Second Charleston, pass LEFT. Pick 3 tiles to pass.",
            deal: [.c(6), .c(6), .b(6), .b(6), .b(6), .d(6), .d(6), .c(4), .b(8), .wind(.north), .flower, .flower, .joker],
            recommendedPass: [.c(4), .b(8), .wind(.north)],
            reasoning: "SEVEN sixes anchor Like Numbers. The 4 Crak and 8 Bam do nothing for the 6s (at best a long-shot backup), and the North is a lone wind, so they are the cheapest tiles to spend. Every other pass breaks up the 6s or gives up a flower.",
            tip: "Count your longest section, not your prettiest. Seven of one number beats four scattered evens."
        ),
        CharlestonScenario(
            id: "cs-commit",
            situation: "First Charleston, pass RIGHT. Two sections look possible. Pick 3.",
            deal: [.c(2), .c(2), .c(4), .c(6), .c(8), .b(3), .b(5), .b(7), .b(9), .flower, .joker, .wind(.north), .wind(.west)],
            recommendedPass: [.wind(.north), .wind(.west), .b(3)],
            reasoning: "Evens in Craks vs odds in Bams: evens edge it, five tiles with a pair against four singles, so lean 2468. The two lone winds help neither plan, so both go now, with the 3 Bam to start letting the odds go. The other odd Bams can follow over later passes.",
            tip: "When two sections compete, commit to the longer one and pass the other side's tiles over the next passes."
        ),
        CharlestonScenario(
            id: "cs-year",
            situation: "First Charleston, pass ACROSS. Pick 3 tiles to pass.",
            deal: [.c(2), .c(2), .b(2), .dragon(.soap), .dragon(.soap), .b(6), .d(6), .flower, .flower, .c(7), .d(3), .wind(.south), .joker],
            recommendedPass: [.c(7), .d(3), .wind(.south)],
            reasoning: "2s, soaps, 6s, flowers: every ingredient of a 2026 year hand. New players pass soaps constantly ('weird blank tile'), but here they're your zeros. The 7C, 3D and lone South are the only tiles with no job.",
            tip: "Before passing a soap, check the year hands. That blank tile is a zero."
        ),
    ]
}
