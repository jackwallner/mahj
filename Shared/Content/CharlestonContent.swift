import Foundation

/// The Charleston Room: rules and strategy for the passing phase,
/// plus interactive "pick 3 to pass" scenarios.
enum CharlestonContent {

    static let strategyCards: [Flashcard] = [
        Flashcard(
            id: "ch-what",
            frontTitle: "What is the Charleston?",
            frontSubtitle: "How the passing before play works",
            backTitle: "The Charleston",
            backBody: "Before play starts, everyone passes tiles. That is three passes (right, across, left), an optional second round (left, across, right), then an optional courtesy pass across. Each Charleston pass is 3 tiles. The point is to trade tiles you don't need for ones you might."
        ),
        Flashcard(
            id: "ch-first-look",
            frontTitle: "Before Your First Pass",
            frontSubtitle: "What do you do with a fresh deal?",
            backTitle: "Sort, Then Shortlist",
            backBody: "Rack your tiles by suit and number, then shortlist 2-3 card sections your deal leans toward. Don't commit to one hand yet. Pass the tiles that help none of your shortlist."
        ),
        Flashcard(
            id: "ch-jokers",
            frontTitle: "Jokers in the Charleston",
            frontSubtitle: "Can you pass one?",
            backTitle: "Not Allowed",
            backBody: "Jokers may never be passed in the Charleston or courtesy pass. If you're ever handed one, someone broke the rules. Flowers can be passed, but early on it is better to keep them."
        ),
        Flashcard(
            id: "ch-flowers",
            frontTitle: "Should You Pass Flowers?",
            frontSubtitle: "They look useless...",
            backTitle: "Hold Them Early",
            backBody: "Many card hands use flowers, so a flower is rarely a dead tile early on. Keep them in the early passes. Once you are committed to a hand with no F in it, they become passes."
        ),
        Flashcard(
            id: "ch-pairs",
            frontTitle: "Breaking Up Pairs",
            frontSubtitle: "You must pass three tiles. Which ones?",
            backTitle: "Don't Break Pairs",
            backBody: "Jokers can't fill a pair, so natural pairs anchor a hand. Pass lone strays (single winds, isolated numbers) before you split a pair, unless the pair fits none of the sections you are considering."
        ),
        Flashcard(
            id: "ch-blind",
            frontTitle: "The Blind Pass",
            frontSubtitle: "a.k.a. stealing",
            backTitle: "Blind Pass",
            backBody: "On the last pass of each Charleston (the first Left and the second Right), you may pass on 1 to 3 of the tiles just handed to you without looking at them. You still pass three tiles, but each blind one lets you keep one of your own. Use it when you don't want to give up tiles you need."
        ),
        Flashcard(
            id: "ch-stop",
            frontTitle: "Stopping the Second Charleston",
            frontSubtitle: "Who decides whether it happens?",
            backTitle: "Anyone Can Stop It",
            backBody: "The second Charleston only happens if all players agree, so any one player can stop it. If your hand is already strong after round one, say stop. Another round means more tiles leaving your rack, which a strong hand may not need."
        ),
        Flashcard(
            id: "ch-courtesy",
            frontTitle: "The Courtesy Pass",
            frontSubtitle: "The final exchange",
            backTitle: "Courtesy Pass",
            backBody: "After the Charleston, you and the player across can swap 0 to 3 tiles. You each pass the same number, agreed out loud ('two?'). Ask for fewer if your hand is close."
        ),
        Flashcard(
            id: "ch-watch",
            frontTitle: "Read the Incoming Tiles",
            frontSubtitle: "Free information",
            backTitle: "Passes Are Hints",
            backBody: "Tiles that arrive are often ones the passer didn't need, unless they were passed blind. Three winds from your right? That player probably isn't on Winds & Dragons. Treat it as a hint, not proof, since blind passes tell you nothing."
        ),
        Flashcard(
            id: "ch-telegraph",
            frontTitle: "Don't Telegraph",
            frontSubtitle: "Passing has a defense side too",
            backTitle: "Split Related Tiles",
            backBody: "When your strays are equally useless to you, mix them across your passes rather than sending three of one family (say, 2C 4C 6C) to one player. The edge is small, so never keep a tile you need just to split a bundle."
        ),
    ]

    static let scenarios: [CharlestonScenario] = [
        CharlestonScenario(
            id: "cs-evens",
            situation: "First Charleston, pass right. Pick 3 tiles to pass.",
            deal: [.c(2), .c(2), .c(4), .c(4), .b(6), .b(6), .b(8), .d(8), .flower, .joker, .c(1), .b(9), .wind(.north)],
            recommendedPass: [.c(1), .b(9), .wind(.north)],
            reasoning: "This deal leans toward 2468, with eight even tiles including three pairs, plus a flower and a joker worth keeping. The 1 Crak and 9 Bam are odd, so they and the lone North do nothing for that plan. The joker can never be passed, and the flower should stay early.",
            tip: "On the first pass, dump the tiles that fit none of your 2-3 candidate sections."
        ),
        CharlestonScenario(
            id: "cs-winds",
            situation: "First Charleston, pass right. Pick 3 tiles to pass.",
            deal: [.wind(.north), .wind(.north), .wind(.north), .wind(.east), .wind(.west), .wind(.west), .wind(.south), .dragon(.red), .c(3), .d(6), .b(9), .flower, .joker],
            recommendedPass: [.c(3), .d(6), .b(9)],
            reasoning: "Seven winds and a dragon make this a Winds & Dragons deal. The three scattered number tiles (3 Crak, 6 Dot, 9 Bam) are strays in three different suits, with nothing to build on for a winds plan. Easy passes.",
            tip: "A pung of winds is a commitment. Once you have one, build around it."
        ),
        CharlestonScenario(
            id: "cs-run",
            situation: "First Charleston, pass across. Pick 3 tiles to pass.",
            deal: [.c(4), .c(5), .c(6), .b(5), .b(6), .b(7), .d(6), .d(6), .c(1), .d(9), .wind(.north), .flower, .joker],
            recommendedPass: [.c(1), .d(9), .wind(.north)],
            reasoning: "Middle numbers 4 through 7 across Craks and Bams, plus a pair of 6 Dots, make a strong Consecutive Run start. The 1 and the 9 are long shots for a run built on 4 through 7, and the lone North is dead weight. Keep the 6 Dot pair, since pairs anchor hands.",
            tip: "For Consecutive Run hands, middle numbers (4-7) leave the most room to build in either direction."
        ),
        CharlestonScenario(
            id: "cs-pairs",
            situation: "First Charleston, pass left. Pick 3 tiles to pass.",
            deal: [.c(3), .c(3), .b(7), .b(7), .d(9), .d(9), .c(5), .b(1), .wind(.west), .d(4), .c(8), .flower, .joker],
            recommendedPass: [.d(4), .c(8), .wind(.west)],
            reasoning: "Three natural pairs of odd numbers point at 13579. Keep every odd tile, since the 5 Crak and 1 Bam still fit odd hands. Pass the evens (4 Dot, 8 Crak) and the lone wind. Keep the pairs too, because jokers can never make a pair for you.",
            tip: "Tiles that fit your section stay, even unpaired. Pass tiles from the wrong number family first."
        ),
        CharlestonScenario(
            id: "cs-junk",
            situation: "First Charleston, pass right. Five winds, a dragon pair and a few strays. Pick 3.",
            deal: [.wind(.west), .wind(.west), .wind(.north), .wind(.east), .wind(.south), .dragon(.red), .dragon(.red), .b(5), .c(9), .d(1), .joker, .joker, .flower],
            recommendedPass: [.d(1), .c(9), .b(5)],
            reasoning: "Five winds, a Red Dragon pair and two jokers are the start of a Winds & Dragons hand, so the three number tiles are the passes: the 1 Dot, 9 Crak and 5 Bam. Keep the West and Red pairs, the lone winds a Winds & Dragons hand can use, and the flower too, since many hands use flowers. Jokers can never be passed.",
            tip: "With a junk deal, let the strongest group set the plan, and pass the strays that fit none of it."
        ),
        CharlestonScenario(
            id: "cs-flowers",
            situation: "First Charleston, pass across. Pick 3 tiles to pass.",
            deal: [.flower, .flower, .flower, .b(2), .b(4), .b(6), .b(8), .b(8), .d(2), .c(9), .wind(.north), .joker, .c(5)],
            recommendedPass: [.c(9), .c(5), .wind(.north)],
            reasoning: "Three flowers plus five even bams make this an evens deal, and many hands use flowers, so keep them. The odd Craks (9 Crak, 5 Crak) and the lone North do not fit an evens plan.",
            tip: "Flowers turn up in many hands, so early passes seldom include one. Count yours. Extras beyond what your sections can use can go."
        ),
        CharlestonScenario(
            id: "cs-like",
            situation: "Second Charleston, pass left. Pick 3 tiles to pass.",
            deal: [.c(6), .c(6), .b(6), .b(6), .b(6), .d(6), .d(6), .c(4), .b(8), .wind(.north), .flower, .flower, .joker],
            recommendedPass: [.c(4), .b(8), .wind(.north)],
            reasoning: "Seven sixes anchor Like Numbers. The 4 Crak and 8 Bam do nothing for the 6s (at best a long-shot backup), and the North is a lone wind, so they are the cheapest tiles to spend. Every other pass breaks up the 6s or gives up a flower.",
            tip: "Go with the section where you hold the most tiles, not the one you like best. Seven of one number beats four scattered evens."
        ),
        CharlestonScenario(
            id: "cs-commit",
            situation: "First Charleston, pass right. Two sections look possible. Pick 3.",
            deal: [.c(2), .c(2), .c(4), .c(6), .c(8), .b(3), .b(5), .b(7), .b(9), .flower, .joker, .wind(.north), .wind(.west)],
            recommendedPass: [.wind(.north), .wind(.west), .b(3)],
            reasoning: "Evens in Craks edge out odds in Bams, with five tiles including a pair against four singles, so lean 2468. The two lone winds help neither plan, so both go now, with the 3 Bam to start letting the odds go. The other odd Bams can follow over later passes.",
            tip: "When two sections compete, commit to the longer one and pass the other side's tiles over the next passes."
        ),
        CharlestonScenario(
            id: "cs-year",
            situation: "First Charleston, pass across. Pick 3 tiles to pass.",
            deal: [.c(2), .c(2), .b(2), .dragon(.soap), .dragon(.soap), .b(6), .d(6), .flower, .flower, .c(7), .d(3), .wind(.south), .joker],
            recommendedPass: [.c(7), .d(3), .wind(.south)],
            reasoning: "The 2s, soaps for the zeros, and 6s are the makings of a year hand. A soap can look like a blank tile worth passing, but here they're your zeros. The 7 Crak, 3 Dot and lone South are the only tiles with no job.",
            tip: "Before passing a soap, check the year hands. That blank tile is a zero."
        ),
    ]
}
