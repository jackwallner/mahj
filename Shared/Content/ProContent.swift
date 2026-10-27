import Foundation

/// The Table Room's advanced tier: Charleston judgment calls, defensive play,
/// and expert rack reading for players who already know the sections.
///
/// LEGAL: Every hand below is an ORIGINAL teaching hand built to illustrate a
/// category family. None of them is copied from any real NMJL card (the card is
/// copyrighted, and the reading skills transfer regardless). Winds, dragons, and
/// soaps are used only to teach how sections read at the table.
enum ProContent {

    // MARK: - Advanced Charleston

    static let advancedCharleston: [CharlestonScenario] = [
        CharlestonScenario(
            id: "pro-ch-two-sections",
            situation: "First Charleston, pass RIGHT. Your craks scream odds, your bams start a run. Pick 3.",
            deal: [.c(1), .c(1), .c(3), .c(7), .c(9), .c(9), .b(5), .b(6), .b(7), .d(2), .d(4), .flower, .joker],
            recommendedPass: [.b(6), .d(2), .d(4)],
            reasoning: "Count both roads. The odds side has eight odd tiles with two pairs (1 and 9 Crak). The run side is only the 5-6-7 in Bams, three tiles, and your Craks (1, 3, 7, 9) have gaps, so they add little to it. Commit to 13579. Keep 5 Bam and 7 Bam since they are odd, and pass the evens an odds hand can't use: 6 Bam, 2 Dot and 4 Dot.",
            tip: "When two sections compete, follow the count. The longer, paired side wins; the shorter side becomes your passes."
        ),
        CharlestonScenario(
            id: "pro-ch-keep-pair",
            situation: "First Charleston, pass RIGHT. You lean toward 2468, and you also hold a pair of Red Dragons. Pick 3.",
            deal: [.c(2), .c(4), .c(6), .b(2), .b(4), .b(6), .dragon(.red), .dragon(.red), .d(3), .d(5), .d(7), .flower, .joker],
            recommendedPass: [.d(3), .d(5), .d(7)],
            reasoning: "The three odd Dots (3, 5, 7) fit none of your even plan, so they are clean passes. Your 2468 lean is only six tiles so far, so the Reds stay as a backup. Do NOT break the Red pair when you have cleaner tiles to give. Jokers can never build a pair, so a natural pair is hard to rebuild once it is gone.",
            tip: "Hold natural pairs by default, and break one only when every other pass costs more."
        ),
        CharlestonScenario(
            id: "pro-ch-pass-pair",
            situation: "First Charleston, pass RIGHT. Eight even tiles plus a lonely pair of Norths. Pick 3.",
            deal: [.c(2), .c(4), .c(6), .c(8), .b(2), .b(4), .b(6), .b(8), .wind(.north), .wind(.north), .d(5), .flower, .joker],
            recommendedPass: [.wind(.north), .wind(.north), .d(5)],
            reasoning: "Usually you protect pairs, but a pair of Norths does not fit the evens you are collecting, and you already hold eight even tiles and a joker, so here the pair is the cheapest thing to give. Pass both Norths and the odd 5 Dot rather than give up an even tile or a flower.",
            tip: "Hold pairs by default, but a pair that fits none of your target section is fair to pass early, before opponents lock in."
        ),
        CharlestonScenario(
            id: "pro-ch-369-vs-run",
            situation: "First Charleston, pass ACROSS. Your hand reads as both 369 and Consecutive Run. Pick 3.",
            deal: [.c(3), .c(6), .c(9), .c(9), .b(3), .b(6), .b(9), .d(6), .d(6), .d(9), .b(4), .b(5), .wind(.north)],
            recommendedPass: [.b(4), .b(5), .wind(.north)],
            reasoning: "369 and a run overlap here. 369 uses ten of your twelve numbers, every 3, 6 and 9. A run on the 3-4-5-6 core uses eight, and it cannot reach your four 9s without 7s and 8s you do not hold. 369 is ahead, so commit to it, keep the 6 Dot and 9 Crak pairs, and pass the 4 Bam and 5 Bam, which 369 has no use for, with the lone North.",
            tip: "When 369 and Run overlap, count how many of your tiles each one can use. Commit to whichever uses more."
        ),
        CharlestonScenario(
            id: "pro-ch-second-stop",
            situation: "Second Charleston, pass LEFT. Nobody stopped the second Charleston, so it goes ahead. You hold seven 6s across three suits. Pick 3.",
            deal: [.c(6), .c(6), .b(6), .b(6), .b(6), .d(6), .d(6), .c(9), .d(3), .flower, .flower, .wind(.north), .joker],
            recommendedPass: [.c(9), .d(3), .wind(.north)],
            reasoning: "Seven 6s across three suits is a strong Like Numbers start, so this pass is a chance to clear out the tiles that do not serve it. The lone 9 Crak and 3 Dot do nothing for the 6s (at best a long-shot backup), and every other choice breaks up your 6s or gives up a flower, so they are the cheapest to give, with the North. Keep both flowers, since many hands use them. Remember that the second Charleston is optional: any one player can stop it.",
            tip: "Any player can stop the second Charleston, so know before it starts whether you still want three more passes."
        ),
        CharlestonScenario(
            id: "pro-ch-defend-late",
            situation: "Second Charleston, the last pass, going RIGHT. On an earlier left pass your right-hand neighbor handed you three winds, so they are probably not on Winds and Dragons. Pick 3.",
            deal: [.c(4), .c(5), .c(6), .b(5), .b(6), .b(7), .d(6), .d(6), .b(2), .d(9), .wind(.east), .flower, .joker],
            recommendedPass: [.b(2), .d(9), .wind(.east)],
            reasoning: "Your tiles cluster on 4s through 7s, the makings of a Consecutive Run with a 6 Dot pair, so the 2 Bam, 9 Dot and East are the strays. Your LAST pass is also defense: your right-hand neighbor passed you three winds, so they are probably not collecting winds, which makes the East a fairly safe tile to send them.",
            tip: "Your final pass is a defensive tool. Feed a neighbor the kind of tile they have hinted they do not want."
        ),
    ]

    // MARK: - Defensive play quiz

    static let defenseQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "pro-def-read-like",
            prompt: "An opponent exposes a kong of 6 Bams AND a kong of 6 Craks. Which discard is most dangerous?",
            tiles: [.b(6), .b(6), .b(6), .b(6), .c(6), .c(6), .c(6), .c(6)],
            choices: ["6 Dot", "North", "1 Crak"],
            answerIndex: 0,
            explanation: "The same number in two suits is the Like Numbers tell, and kongs of it make the read even stronger. Whatever their exact hand, it is made of 6s: the 6 Dot is the tile to hold. Exposures cannot grow once play moves on, so read them as they sit."
        ),
        QuizQuestion(
            id: "pro-def-read-369",
            prompt: "An opponent exposes a pung of 3 Dots and a pung of 9 Dots. Which of these sections fits?",
            tiles: [.d(3), .d(3), .d(3), .d(9), .d(9), .d(9)],
            choices: ["Consecutive Run", "369", "Quints"],
            answerIndex: 1,
            explanation: "A run through both 3 and 9 would have to cover seven numbers, so Consecutive Run is a long shot. Threes and nines together are a 369 tell (an odds hand can use them too). Treat 3s, 6s, and 9s as hot tiles against this player."
        ),
        QuizQuestion(
            id: "pro-def-count-copies",
            prompt: "You hold one North and want a pung. Two Norths already sit in the discards. How many more Norths can still reach you?",
            tiles: [.wind(.north), .wind(.north)],
            choices: ["Two", "One at most", "Three", "None, it is truly impossible"],
            answerIndex: 1,
            explanation: "Only four of any tile exist. You hold one and two are in the discards, so at most one is left, and it could be buried in the wall or stuck in a hand. Even if it comes, that is a pair: the pung needs a joker. Start lining up a backup."
        ),
        QuizQuestion(
            id: "pro-def-quints-dead",
            prompt: "You are chasing a quint (five of a kind) of 5 Dots. You hold one 5 Dot and one joker, and the other three 5 Dots are in the discards. Keep pushing?",
            tiles: [.d(5), .d(5), .d(5)],
            choices: ["Yes, jokers will cover it", "No, it is effectively dead", "Only if you draw two more jokers first"],
            answerIndex: 1,
            explanation: "Only four 5 Dots exist, and the three in the discards are gone for good, so your quint needs four jokers beside your 5 Dot. You hold one, so three more of the set's eight jokers would have to reach you, and even two more leaves you a tile short. Count the naturals and your jokers before you chase any quint, and fold this one."
        ),
        QuizQuestion(
            id: "pro-def-safe-discard",
            prompt: "One opponent has exposed a pung of North and a pung of Red, and has discarded since. You hold the fourth North. Which discard is safest against them?",
            tiles: [.wind(.north), .wind(.north), .wind(.north), .dragon(.red), .dragon(.red), .dragon(.red)],
            choices: ["North wind", "A 5 Bam", "Soap", "A flower"],
            answerIndex: 0,
            explanation: "Their North pung locked when they discarded, so it can never become a kong, and with three Norths on their rack and one in yours, nobody else holds a natural North to build with. A middle number or a soap can still fit a winds and dragons hand, and flowers fit many hands."
        ),
        QuizQuestion(
            id: "pro-def-hot-tile",
            prompt: "An opponent has exposed a pung of 6 Bams and a pung of 8 Bams and is waiting for a tile. Which discard is most dangerous?",
            tiles: [.b(6), .b(6), .b(6), .b(8), .b(8), .b(8)],
            choices: ["7 Bam", "2 Crak", "North", "Soap"],
            answerIndex: 0,
            explanation: "Two pungs in one suit, two numbers apart, read as a run with the middle missing: the 7 Bam is the bridge that would complete it. Hold it and throw something unrelated."
        ),
        QuizQuestion(
            id: "pro-def-break-hand",
            prompt: "Your hand is hopeless, and an opponent is one tile away from mah jongg on an obvious hand. What is the right play?",
            tiles: [],
            choices: ["Draw and hope your own hand comes together", "Switch to defense: discard only tiles they cannot use, even if it breaks your hand", "Discard fast to end the game sooner"],
            answerIndex: 1,
            explanation: "If you cannot win, your job is to not deal the winning tile. Break your own hand and throw tiles their exposures prove are safe. A blocked win is a good outcome when yours is hopeless."
        ),
        QuizQuestion(
            id: "pro-def-joker-swap",
            prompt: "An opponent has an exposed pung of 3 Craks made with two real tiles and one joker. You hold a real 3 Crak. On your turn you may:",
            tiles: [.c(3), .c(3), .joker],
            choices: ["Call the joker off the discard pile", "Swap your real 3 Crak for the joker and take the joker into your hand", "Nothing, exposed jokers are frozen"],
            answerIndex: 1,
            explanation: "This is the joker exchange. On your turn, before you discard, you may redeem an exposed joker by giving the matching natural tile, and the joker comes into your hand. A free joker is a huge tempo swing, so watch for these."
        ),
        QuizQuestion(
            id: "pro-def-track-jokers",
            prompt: "Why bother tracking the jokers sitting in opponents' exposures?",
            tiles: [],
            choices: ["Any player can redeem them with the matching tile, so plan to grab them", "They score bonus points at the end", "They stop you from using your own jokers"],
            answerIndex: 0,
            explanation: "Exposed jokers are up for grabs. A single spare natural tile can pull one into your hand on your turn. Knowing which jokers are live tells you when a swap is waiting for you."
        ),
        QuizQuestion(
            id: "pro-def-hidden-count",
            prompt: "Between turns, an opponent has three pungs face up. How many of their tiles are still hidden?",
            tiles: [],
            choices: ["One", "Four", "Seven", "Ten"],
            answerIndex: 1,
            explanation: "Everyone holds thirteen between turns. Nine are showing in the three pungs, so only four are hidden, and those four plus one more tile make the hand. The fewer tiles hidden, the easier they are to read and the closer they usually are."
        ),
        QuizQuestion(
            id: "pro-def-follow-discard",
            prompt: "The player on your left just threw a 4 Bam and nobody called it. You hold a 4 Bam. How risky is throwing it now?",
            tiles: [.b(4)],
            choices: ["About as safe as a throw gets", "Very dangerous, it is live", "Illegal, the same tile cannot follow", "Only safe if you are East"],
            answerIndex: 0,
            explanation: "Every other player just had the chance to take that exact tile and passed. Following a fresh discard is a classic safe throw. It is not a guarantee: one draw can change a hand, so it is safest right away."
        ),
        QuizQuestion(
            id: "pro-def-no-exposures",
            prompt: "Late in the hand, one opponent has exposed nothing and is discarding calmly. What does that tell you?",
            tiles: [],
            choices: ["They are far from winning", "Nothing is proven safe against them, they may be close on a concealed hand", "They cannot win without calling a discard", "Their hand is dead"],
            answerIndex: 1,
            explanation: "No exposures means no information, not no danger. A concealed hand can be one tile away with nothing showing. Lean on tiles the table has already let pass."
        ),
    ]

    // MARK: - Expert rack reading

    static let expertRackReading: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "pro-rack-1",
            tiles: [.c(4), .c(5), .c(6), .b(6), .b(7), .b(8), .d(5), .d(6), .d(7), .d(7), .b(9), .flower, .joker],
            choices: [.consecutiveRun, .threeSixNine, .evens2468],
            answer: .consecutiveRun,
            explanation: "369 is the decoy: there is a 6 in every suit and a 9 Bam. But the 4 and 5 Crak, the 7 and 8 Bam, and the 5 and 7 Dots are dead weight for 369, while they make 4-5-6, 6-7-8-9 and 5-6-7 runs, one in each suit. Stepping numbers like these make this Consecutive Run."
        ),
        HandMatchQuestion(
            id: "pro-rack-2",
            tiles: [.c(3), .c(3), .c(6), .c(6), .d(9), .d(9), .b(3), .b(6), .b(9), .c(9), .b(5), .flower, .joker],
            choices: [.threeSixNine, .consecutiveRun, .likeNumbers],
            answer: .threeSixNine,
            explanation: "Consecutive Run is the decoy, tempted by the 3, 5 and 6 Bams. But ten of your eleven numbers are 3s, 6s and 9s, including three pairs, and the 5 Bam is the only number 369 cannot use. This is 369."
        ),
        HandMatchQuestion(
            id: "pro-rack-3",
            tiles: [.c(2), .c(2), .c(4), .c(8), .b(6), .b(6), .b(8), .b(4), .d(2), .d(4), .d(8), .flower, .joker],
            choices: [.evens2468, .year, .likeNumbers],
            answer: .evens2468,
            explanation: "Year is the decoy because of the 2s, 6s, and flowers. But a year hand needs soaps as its zeros, and there are none. With 4s and 8s in the mix, tiles a year hand never uses, this is a straight 2468."
        ),
        HandMatchQuestion(
            id: "pro-rack-4",
            tiles: [.c(2), .c(2), .b(2), .b(2), .dragon(.soap), .dragon(.soap), .d(6), .d(6), .b(6), .flower, .flower, .flower, .joker],
            choices: [.year, .evens2468, .windsDragons],
            answer: .year,
            explanation: "2468 is the decoy since 2s and 6s are even. But the soaps are the giveaway: they stand in for the zeros in 2, 0, 2, 6. With no 4s or 8s and three flowers, this is a Year hand."
        ),
        HandMatchQuestion(
            id: "pro-rack-5",
            tiles: [.c(1), .c(1), .c(3), .c(3), .b(5), .b(5), .b(5), .d(7), .d(9), .d(9), .b(1), .flower, .joker],
            choices: [.odds13579, .singlesAndPairs, .consecutiveRun],
            answer: .odds13579,
            explanation: "Singles and Pairs is the decoy, since you have several pairs. But a Singles and Pairs hand has no pungs and no jokers, and this rack has a pung of 5 Bams and a joker, so it does not fit. Read it as 13579."
        ),
        HandMatchQuestion(
            id: "pro-rack-6",
            tiles: [.c(1), .c(1), .b(2), .b(2), .d(3), .d(3), .c(5), .c(5), .b(6), .b(6), .d(8), .d(8), .wind(.north)],
            choices: [.singlesAndPairs, .odds13579, .evens2468],
            answer: .singlesAndPairs,
            explanation: "13579 is the decoy off the 1s, 3s, and 5s, but the 2, 6, and 8 pairs kill any odd-only hand. Six natural pairs across mixed numbers with zero jokers is the textbook Singles and Pairs shape."
        ),
        HandMatchQuestion(
            id: "pro-rack-7",
            tiles: [.c(7), .c(7), .b(7), .b(7), .b(7), .d(7), .d(7), .d(7), .c(2), .b(9), .d(9), .flower, .joker],
            choices: [.likeNumbers, .quints, .consecutiveRun],
            answer: .likeNumbers,
            explanation: "Quints is the decoy, dreaming of five 7s in a suit. But your 7s sit in pungs and pairs, which need two or three jokers each to reach five, and you hold just one. Eight 7s spread across all three suits reads as Any Like Numbers instead."
        ),
        HandMatchQuestion(
            id: "pro-rack-8",
            tiles: [.dragon(.soap), .dragon(.soap), .dragon(.red), .dragon(.red), .dragon(.green), .dragon(.green), .wind(.north), .wind(.north), .wind(.east), .c(2), .d(2), .flower, .joker],
            choices: [.windsDragons, .year, .singlesAndPairs],
            answer: .windsDragons,
            explanation: "Year is the decoy: the soaps and 2s hint at 2, 0, 2, 6. But there is not a single 6, and three dragon pairs plus three winds are already on the rack. That is Winds and Dragons."
        ),
    ]
}
