import Foundation

/// Content added in 1.1. Kept in its own file rather than appended inline so
/// it stays obvious which questions shipped when, and so the 1.0 sets can be
/// read as they were authored.
///
/// Every rack and deal here is an ORIGINAL teaching hand built from the stable
/// category structures. Nothing is copied from the NMJL card, and nothing
/// claims to be a card hand.
enum MoreContent {

    // MARK: - The Tile Room (Mahj+ extras)

    static let tileExtras: [QuizQuestion] = [
        QuizQuestion(
            id: "more-tile-flower-count",
            prompt: "How many flower tiles are in an American mah jongg set?",
            choices: ["Four", "Six", "Eight", "Twelve"],
            answerIndex: 2,
            explanation: "Eight flowers, and unlike suited tiles they are all interchangeable with each other."
        ),
        // These two replaced a joker count and a joker-in-a-pair question that
        // repeated the free Tile Check word for word.
        QuizQuestion(
            id: "more-tile-dragon-count",
            prompt: "How many dragon tiles are in an American set?",
            tiles: [.dragon(.red), .dragon(.green), .dragon(.soap)],
            choices: ["Three", "Eight", "Twelve", "Sixteen"],
            answerIndex: 2,
            explanation: "Twelve: four Red, four Green and four Soap. Sixteen is the winds. With only four of each dragon, a dragon kong takes every copy or a joker."
        ),
        QuizQuestion(
            id: "more-tile-one-bam",
            prompt: "Many sets draw the 1 Bam as something other than a single stick. What is it usually?",
            tiles: [.b(1)],
            choices: ["A bird", "A flower", "A dragon", "A joker"],
            answerIndex: 0,
            explanation: "A bird, often a peacock or sparrow. It is still just the 1 Bam: a bam tile, and one of the four copies."
        ),
        QuizQuestion(
            id: "more-tile-swap-joker",
            prompt: "When may you swap a real tile for a joker in an exposure?",
            choices: [
                "Never",
                "When the exposure is yours only",
                "On your turn, for any exposed joker whose tile you hold",
                "Only during the Charleston"
            ],
            answerIndex: 2,
            explanation: "On your turn you may redeem any exposed joker, including an opponent's, by giving the real tile it stands for."
        ),
        QuizQuestion(
            id: "more-tile-total",
            prompt: "How many tiles does a player hold after the deal, before the first discard?",
            choices: ["12", "13", "14", "16"],
            answerIndex: 1,
            explanation: "Thirteen tiles, except East who starts with fourteen and discards first."
        ),
        QuizQuestion(
            id: "more-tile-soap",
            prompt: "In Year hands, what does the soap usually represent?",
            choices: ["A joker", "A zero", "A flower", "Any dragon"],
            answerIndex: 1,
            explanation: "The white dragon, or soap, stands in for the zero in a year. It is still a dragon everywhere else on the card."
        ),
    ]

    // MARK: - The Card Room (Mahj+ extras)

    static let rackReading: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "more-rack-evens",
            tiles: [.c(2), .c(2), .c(2),
                    .b(4), .b(4), .b(4),
                    .d(6), .d(6), .d(6),
                    .b(8), .b(8),
                    .flower, .flower],
            choices: [.evens2468, .odds13579, .threeSixNine, .consecutiveRun],
            answer: .evens2468,
            explanation: "Every number on this rack is even and there is not an odd tile in sight. Pass anything odd and commit to 2468."
        ),
        HandMatchQuestion(
            id: "more-rack-consecutive",
            tiles: [.c(3), .c(3), .c(3),
                    .c(4), .c(4), .c(4),
                    .c(5), .c(5), .c(5),
                    .b(6), .b(6),
                    .flower, .flower],
            choices: [.consecutiveRun, .evens2468, .odds13579, .threeSixNine],
            answer: .consecutiveRun,
            explanation: "Three, four, five, six: the numbers step up in order. A run always mixes odd and even, so it can never be an evens or odds hand."
        ),
        HandMatchQuestion(
            id: "more-rack-winds",
            tiles: [.wind(.north), .wind(.north), .wind(.north),
                    .wind(.east), .wind(.east), .wind(.east),
                    .dragon(.red), .dragon(.red), .dragon(.red),
                    .dragon(.green), .dragon(.green),
                    .flower, .flower],
            choices: [.windsDragons, .likeNumbers, .singlesAndPairs, .threeSixNine],
            answer: .windsDragons,
            explanation: "Not one numbered tile on the rack. When honors pile up like this, Winds and Dragons is the only section that fits."
        ),
        HandMatchQuestion(
            id: "more-rack-369",
            tiles: [.c(3), .c(3), .c(3),
                    .b(6), .b(6), .b(6),
                    .d(9), .d(9), .d(9),
                    .d(6), .d(6),
                    .flower, .flower],
            choices: [.threeSixNine, .evens2468, .odds13579, .consecutiveRun],
            answer: .threeSixNine,
            explanation: "Only 3s, 6s and 9s. The 6 rules out a pure odds hand and the 3 and 9 rule out a pure evens hand, so 369 is the read."
        ),
        HandMatchQuestion(
            id: "more-rack-like",
            tiles: [.c(7), .c(7), .c(7),
                    .b(7), .b(7), .b(7),
                    .d(7), .d(7), .d(7),
                    .dragon(.red), .dragon(.red),
                    .flower, .flower],
            choices: [.likeNumbers, .consecutiveRun, .threeSixNine, .quints],
            answer: .likeNumbers,
            explanation: "The same number in all three suits is the signature of Any Like Numbers. One number arriving from every direction is the cue to look here."
        ),
    ]

    // MARK: - The Charleston Room (Mahj+ extras)

    static let passes: [CharlestonScenario] = [
        CharlestonScenario(
            id: "more-pass-odds",
            situation: "Your deal leans heavily odd. First pass, three tiles to the right.",
            deal: [.c(1), .c(1), .c(3), .c(5),
                   .b(1), .b(3), .b(5), .b(9),
                   .d(7), .d(9),
                   .c(2), .b(4), .wind(.north)],
            recommendedPass: [.c(2), .b(4), .wind(.north)],
            reasoning: "Ten odd tiles is a direction, not a coincidence. The two evens and the lone wind are doing nothing for an odds hand, so they go first.",
            tip: "Pass what does not fit the story your rack is already telling."
        ),
        CharlestonScenario(
            id: "more-pass-honors",
            situation: "Honors are stacking up and the numbers are scattered. First pass, three tiles.",
            deal: [.wind(.east), .wind(.east), .wind(.east),
                   .dragon(.red), .dragon(.red), .dragon(.green),
                   .flower, .flower,
                   .c(4), .b(7), .d(2), .d(8), .c(9)],
            recommendedPass: [.c(4), .b(7), .c(9)],
            reasoning: "A pung of east, a pair of red and a green is a real Winds and Dragons start. The five loose numbers are the passable ones, so send the three that pair with nothing.",
            tip: "Keep the flowers. Almost every section uses them, and they cost you nothing to hold."
        ),
        CharlestonScenario(
            id: "more-pass-flexible",
            situation: "Nothing has taken shape yet. First pass, and you want to stay flexible.",
            deal: [.c(2), .c(4), .c(6),
                   .b(2), .b(4), .b(6), .b(8),
                   .d(4), .d(6),
                   .d(1), .d(3), .c(9), .flower],
            recommendedPass: [.d(1), .d(3), .c(9)],
            reasoning: "Nine even tiles against three odd ones. You are not committed yet, but the evens are clearly the majority, so pass the odd strays and see what comes back.",
            tip: "Early passes are about narrowing, not deciding. Keep the majority and let the Charleston tell you the rest."
        ),
    ]

    // MARK: - The Table Room

    /// Free. The Table Room shipped with a single drill, which made it the
    /// thinnest door on Home; a free quiz alongside the judgment cards gives
    /// it the same shape as every other room.
    static let tableQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "more-table-call-discard",
            prompt: "Another player discards a tile you need. When may you call it?",
            choices: [
                "Any time you want it",
                "Only to complete an exposure you can show, or to declare mah jongg",
                "Only on your own turn",
                "Only during the first round"
            ],
            answerIndex: 1,
            explanation: "You call a discard to complete a pung, kong or quint that you then expose, or to finish your hand. You cannot call for a pair or a single unless it is your winning tile."
        ),
        QuizQuestion(
            id: "more-table-dead-hand",
            prompt: "What most often makes a hand dead?",
            choices: [
                "Holding too many flowers",
                "An exposure that cannot belong to any hand on the card",
                "Passing a joker by mistake",
                "Discarding out of turn"
            ],
            answerIndex: 1,
            explanation: "If your exposures do not match any hand on the card, the hand is dead. Check the card before you expose, not after."
        ),
        QuizQuestion(
            id: "more-table-safe-discard",
            prompt: "Late in the hand, which discard is usually safest?",
            choices: [
                "A tile nobody has exposed",
                "A tile already discarded twice with no takers",
                "A tile that matches an opponent's exposure",
                "A flower"
            ],
            answerIndex: 1,
            explanation: "A tile that has gone around without being called is unlikely to suddenly become useful. Repeating a dead discard is the classic safe throw."
        ),
        QuizQuestion(
            id: "more-table-exposure-read",
            prompt: "An opponent exposes a pung of 4 Bams and a pung of 6 Dots. What are they most likely chasing?",
            choices: ["An odds hand", "An evens hand", "Winds and Dragons", "Singles and Pairs"],
            answerIndex: 1,
            explanation: "Two even pungs points at 2468. Stop feeding them even tiles and watch which numbers they still need."
        ),
        QuizQuestion(
            id: "more-table-never-expose",
            prompt: "Which kind of hand can never be exposed?",
            choices: [
                "Any Like Numbers",
                "Consecutive Run",
                "Singles and Pairs",
                "Winds and Dragons"
            ],
            answerIndex: 2,
            explanation: "Singles and Pairs contains no pungs or kongs, so there is nothing to call and nothing to expose. It is played entirely from your own rack."
        ),
        // Scoring and payment. Values come from the card; these are the
        // standing payment rules every table uses on top of them.
        QuizQuestion(
            id: "table-pay-discard",
            prompt: "You win on another player's discard. Who pays what?",
            choices: [
                "The discarder pays double, the other two pay the hand's value",
                "Only the discarder pays",
                "All three pay the same",
                "All three pay double"
            ],
            answerIndex: 0,
            explanation: "Throwing the winning tile costs double. The other two players pay the value printed beside the hand on the card."
        ),
        QuizQuestion(
            id: "table-pay-self-pick",
            prompt: "You win on a tile you drew from the wall yourself. Who pays?",
            choices: ["Nobody", "Only East", "All three players pay double", "All three pay the hand's value"],
            answerIndex: 2,
            explanation: "Nobody fed you the winning tile, so everyone pays double."
        ),
        QuizQuestion(
            id: "table-pay-jokerless",
            prompt: "You win with no jokers anywhere in your hand. What changes?",
            choices: ["Nothing", "The hand pays double", "You deal the next hand", "Only the discarder pays"],
            answerIndex: 1,
            explanation: "A jokerless win pays double. Singles and Pairs hands are the exception: they can never hold a joker, so they earn no bonus for going without."
        ),
        QuizQuestion(
            id: "table-pay-stacked",
            prompt: "You draw your own winning tile, and the hand has no jokers. What does each player pay?",
            choices: ["The hand's value", "Double the value", "Four times the value", "Nothing extra, bonuses do not combine"],
            answerIndex: 2,
            explanation: "Both bonuses apply. Drawing it yourself doubles the payment, and jokerless doubles it again, so each player pays four times the hand's value."
        ),
        QuizQuestion(
            id: "table-pay-wall",
            prompt: "The wall runs out and nobody has won. Who pays?",
            choices: ["The last player to discard", "East", "Nobody", "Everyone pays East"],
            answerIndex: 2,
            explanation: "A wall game costs nothing. The tiles are reshuffled and the next hand is dealt."
        ),
        QuizQuestion(
            id: "table-pay-dead-hand",
            prompt: "Your hand went dead earlier, and another player wins. Do you pay?",
            choices: ["No, a dead hand is out of the game", "Yes, like any other player", "Only if you are East", "You pay double"],
            answerIndex: 1,
            explanation: "A dead hand cannot win, but you are still at the table, so you pay the winner like everyone else. Throw the winning tile and you pay double, as anyone would."
        ),
        // Table procedure: the moments that start arguments.
        QuizQuestion(
            id: "table-call-too-late",
            prompt: "When is it too late to call a discard?",
            choices: [
                "Once the next player has drawn from the wall and racked the tile",
                "As soon as the tile touches the table",
                "Only after the next discard lands",
                "Never, discards stay callable all game"
            ],
            answerIndex: 0,
            explanation: "You may call until the next player has drawn a tile and put it on their rack. After that, the discard is gone. Speak up quickly."
        ),
        QuizQuestion(
            id: "table-call-then-what",
            prompt: "You call a discard for a pung. What comes next?",
            choices: [
                "Draw from the wall, then discard",
                "Expose the pung, then discard",
                "Expose the pung and draw a replacement tile",
                "Wait for your normal turn"
            ],
            answerIndex: 1,
            explanation: "Calling takes the place of your draw. Put the pung face up on your rack, discard, and play continues to your right."
        ),
        QuizQuestion(
            id: "table-call-priority",
            prompt: "Two players call the same discard for a pung. Who gets it?",
            choices: ["Whoever spoke first", "The player whose turn comes next", "The player with fewer exposures", "Neither, it is dead"],
            answerIndex: 1,
            explanation: "When two players want a tile for an exposure, it goes to the one next in turn after the discarder. A call for mah jongg still beats any exposure."
        ),
        QuizQuestion(
            id: "table-exposure-locked",
            prompt: "You have an exposed pung of 5 Bams and draw the fourth. Can you add it to make a kong?",
            choices: ["Yes, on your turn", "No, an exposure can never grow", "Only if it wins the hand", "Only before your next discard"],
            answerIndex: 1,
            explanation: "Once you have discarded after exposing it, a group is locked. The fourth 5 Bam stays on your rack or goes to the discards. The one change still allowed is someone swapping a real tile for a joker in it."
        ),
        QuizQuestion(
            id: "table-mahj-in-error",
            prompt: "You call mah jongg, lay your hand down, and it turns out one tile is wrong. What happens?",
            choices: [
                "Pick the tiles back up and keep playing",
                "Your hand is dead, and the other three play on",
                "The whole hand is replayed",
                "You skip your next turn"
            ],
            answerIndex: 1,
            explanation: "Once a wrong hand is laid down, it is dead. The other three keep playing, and you still pay whoever wins. Check the card before you lay down."
        ),
    ]

    /// Mahj+ extras for the Table Room.
    static let judgment: [Flashcard] = [
        Flashcard(
            id: "more-judge-lone-wind",
            frontTitle: "One lone North, mid-game",
            frontTiles: [.wind(.north)],
            frontSubtitle: "Your hand is going 2468. Keep or throw?",
            backTitle: "Throw it",
            backBody: "A single honor that belongs to no section you are chasing is pure dead weight. The earlier it goes, the safer it is.",
            choice: CardChoice("Throw", "Keep", answerIndex: 0)
        ),
        Flashcard(
            id: "more-judge-third-copy",
            frontTitle: "You hold two 5 Craks",
            frontTiles: [.c(5), .c(5)],
            frontSubtitle: "Two more are already exposed elsewhere. Keep waiting?",
            backTitle: "Let it go",
            backBody: "All four are accounted for. Your pair can never become a pung, so any hand that needs one is finished. Count before you commit.",
            choice: CardChoice("Let it go", "Keep waiting", answerIndex: 0)
        ),
        Flashcard(
            id: "more-judge-joker-hold",
            frontTitle: "Two jokers, no direction yet",
            frontTiles: [.joker, .joker],
            frontSubtitle: "Pass a joker to speed things up?",
            backTitle: "Never pass a joker",
            backBody: "Jokers can never be passed, in the Charleston or the courtesy pass. Even if they could, they are the most valuable tiles on your rack.",
            choice: CardChoice("Keep them", "Pass one", answerIndex: 0)
        ),
        Flashcard(
            id: "more-judge-flower-discipline",
            frontTitle: "Three flowers, hand is Singles and Pairs",
            frontTiles: [.flower, .flower, .flower],
            backTitle: "Check the hand first",
            backBody: "Flowers are useful in most sections, but a Singles and Pairs hand may only want a pair of them. Holding a third out of habit costs you a tile you need.",
            choice: CardChoice("Check the card", "Always keep all", answerIndex: 0)
        ),
        Flashcard(
            id: "more-judge-late-switch",
            frontTitle: "Seven tiles from mah jongg, late in the wall",
            frontSubtitle: "A better section appears. Switch?",
            backTitle: "Usually not",
            backBody: "Switching late means starting over with fewer tiles left in the wall. Only jump when the new hand is genuinely closer than the one you are on.",
            choice: CardChoice("Stay", "Switch", answerIndex: 0)
        ),
    ]

    // MARK: - The Master Tables

    static let jokerRules: [QuizQuestion] = [
        QuizQuestion(
            id: "more-pro-joker-single",
            prompt: "Your hand needs one more single tile to win. Can a joker finish it?",
            choices: ["Yes", "No", "Only if exposed", "Only on your own draw"],
            answerIndex: 1,
            explanation: "Jokers never fill a single or a pair. A hand that needs a single needs the real tile, which is why those hands score higher."
        ),
        QuizQuestion(
            id: "more-pro-joker-redeem-timing",
            prompt: "When can you NOT redeem an exposed joker?",
            choices: [
                "After you have already discarded that turn",
                "When the joker is in your own exposure",
                "During the first round",
                "When you hold two of the tile"
            ],
            answerIndex: 0,
            explanation: "Redemption happens on your turn, before you discard. Once you have thrown, the window is closed until your next turn."
        ),
        QuizQuestion(
            id: "more-pro-joker-discard-late",
            prompt: "Late in the hand, what happens to a joker you discard?",
            choices: [
                "It is against the rules to discard one",
                "Nobody can call it, so it is safe but gone for good",
                "It can be called for mah jongg by a player who needs a group",
                "It ends the game immediately"
            ],
            answerIndex: 1,
            explanation: "A discarded joker is dead: nobody can call it, for an exposure or for mah jongg. That makes it a safe throw, but you are giving away the most flexible tile in the set, and it tells the table you had one to spare."
        ),
        QuizQuestion(
            id: "more-pro-joker-quint",
            prompt: "How many jokers does a quint typically require?",
            choices: ["None", "At least one", "At least two", "Exactly four"],
            answerIndex: 1,
            explanation: "Only four of any tile exist, so a group of five always needs at least one joker. Most players will not commit to Quints without two."
        ),
        QuizQuestion(
            id: "more-pro-joker-exposure-swap",
            prompt: "An opponent exposes a pung of 3 Dots using a joker. You hold a 3 Dot. What can you do?",
            choices: [
                "Nothing until they discard",
                "Swap your 3 Dot for their joker on your turn",
                "Declare their hand dead",
                "Call the tile for yourself"
            ],
            answerIndex: 1,
            explanation: "Any exposed joker is redeemable by any player holding the tile it stands for, on their own turn. Taking an opponent's joker is one of the strongest plays in the game."
        ),
        QuizQuestion(
            id: "more-pro-joker-flowers",
            prompt: "Your hand needs four flowers and you hold three. Can a joker be the fourth?",
            tiles: [.flower, .flower, .flower, .joker],
            choices: ["Yes, flowers in a group of three or more take jokers", "No, flowers never take jokers", "Only in a pair of flowers", "Only if the flowers are exposed"],
            answerIndex: 0,
            explanation: "A group of three or more flowers is a group like any other, so jokers can fill it. A pair of flowers is still a pair: those two have to be real."
        ),
        QuizQuestion(
            id: "more-pro-joker-year",
            prompt: "Can a joker stand in for one of the digits in a year like 2026?",
            tiles: [.c(2), .dragon(.soap), .joker, .c(6)],
            choices: ["Yes, any digit", "Only for the zero", "No, each digit is a single tile", "Only in a concealed hand"],
            answerIndex: 2,
            explanation: "Each digit of the year is a single tile, and jokers never fill a single. The year has to be spelled with real tiles."
        ),
    ]
}
