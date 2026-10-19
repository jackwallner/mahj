import Foundation

/// Hand-written closers that exist only for the monthly challenge, so each
/// theme's pool holds 40: four months of ten with no repeats, a full year of
/// the three-theme rotation (2026-10-18). Original teaching content; nothing
/// here comes from the NMJL card. Year racks and passes are left out of the
/// challenge entirely, because their digits change with every new card.
extension MonthlyChallengeContent {

    // MARK: - Reading Your Rack

    static let extraRacks: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "monthly-rack-like-1s",
            tiles: [.c(1), .c(1), .c(1), .b(1), .b(1), .b(1), .d(1), .d(1), .flower, .flower, .dragon(.green), .dragon(.green), .d(4)],
            choices: [.likeNumbers, .evens2468, .consecutiveRun, .windsDragons],
            answer: .likeNumbers,
            explanation: "Eight 1s, spread over all three suits. When one number turns up in every suit like this, Like Numbers is the read. The 4 Dot is the one number that does not fit."
        ),
        HandMatchQuestion(
            id: "monthly-rack-like-9s",
            tiles: [.c(9), .c(9), .c(9), .b(9), .b(9), .d(9), .d(9), .d(9), .flower, .flower, .joker, .c(4), .wind(.north)],
            choices: [.likeNumbers, .evens2468, .consecutiveRun, .singlesAndPairs],
            answer: .likeNumbers,
            explanation: "Eight 9s across Craks, Bams and Dots. One number filling every suit is the Like Numbers shape. The 4 Crak is the one number that does not fit, and the North is a lone wind."
        ),
        HandMatchQuestion(
            id: "monthly-rack-like-4s",
            tiles: [.c(4), .c(4), .b(4), .b(4), .b(4), .d(4), .d(4), .d(4), .flower, .flower, .dragon(.red), .wind(.west), .c(7)],
            choices: [.likeNumbers, .odds13579, .threeSixNine, .quints],
            answer: .likeNumbers,
            explanation: "Eight 4s in three suits. Like Numbers is built on one number repeated across suits, and this rack is mostly one number. The 7 Crak, the Red Dragon and the West Wind are the strays."
        ),
        HandMatchQuestion(
            id: "monthly-rack-like-8s",
            tiles: [.c(8), .c(8), .c(8), .b(8), .b(8), .b(8), .d(8), .d(8), .joker, .flower, .dragon(.soap), .b(3), .d(5)],
            choices: [.likeNumbers, .odds13579, .consecutiveRun, .windsDragons],
            answer: .likeNumbers,
            explanation: "Eight 8s spread across all three suits, with a joker to help. That is the Like Numbers shape. The 3 Bam and 5 Dot are the numbers that do not fit."
        ),
        HandMatchQuestion(
            id: "monthly-rack-like-2s",
            tiles: [.c(2), .c(2), .c(2), .b(2), .b(2), .d(2), .d(2), .d(2), .flower, .flower, .flower, .wind(.north), .d(9)],
            choices: [.likeNumbers, .threeSixNine, .windsDragons, .singlesAndPairs],
            answer: .likeNumbers,
            explanation: "Eight 2s across the three suits. When a rack is mostly one number in every suit, Like Numbers is the read. The 9 Dot is the one number that does not fit, and the North is a lone wind."
        ),
        HandMatchQuestion(
            id: "monthly-rack-quints-4-5",
            tiles: [.joker, .joker, .joker, .joker, .c(4), .c(4), .c(4), .b(5), .b(5), .b(5), .flower, .flower, .wind(.north)],
            choices: [.quints, .windsDragons, .singlesAndPairs, .odds13579],
            answer: .quints,
            explanation: "Two pungs and four jokers. Two jokers stretch a pung into a quint, and this rack has four of them. Only jokers make quints, and this rack has plenty."
        ),
        HandMatchQuestion(
            id: "monthly-rack-quints-kong",
            tiles: [.joker, .joker, .joker, .d(8), .d(8), .d(8), .d(8), .c(1), .c(1), .c(1), .flower, .flower, .dragon(.red)],
            choices: [.quints, .evens2468, .threeSixNine, .windsDragons],
            answer: .quints,
            explanation: "A kong of 8 Dots needs one joker to become a quint, and the pung of 1 Craks needs two. Jokers are the only way to five of a kind, and this rack has enough to turn either group into a quint. Five of a kind only happens with jokers, so this is a Quints rack."
        ),
        HandMatchQuestion(
            id: "monthly-rack-quints-3-9",
            tiles: [.joker, .joker, .joker, .d(3), .d(3), .d(3), .d(3), .b(9), .b(9), .b(9), .flower, .flower, .wind(.west)],
            choices: [.quints, .evens2468, .consecutiveRun, .singlesAndPairs],
            answer: .quints,
            explanation: "A kong of 3 Dots, a pung of 9 Bams and three jokers. One joker would make the kong a quint, or two the pung. A rack this rich in jokers is how Quints happen."
        ),
        HandMatchQuestion(
            id: "monthly-rack-quints-2-5",
            tiles: [.joker, .joker, .joker, .joker, .b(2), .b(2), .b(2), .c(5), .c(5), .c(5), .wind(.north), .wind(.south), .flower],
            choices: [.quints, .odds13579, .threeSixNine, .windsDragons],
            answer: .quints,
            explanation: "Four jokers beside two pungs. Each pung needs two jokers to reach five of a kind, so four is enough for either one, or both. Joker-heavy racks with big groups point at Quints."
        ),
        HandMatchQuestion(
            id: "monthly-rack-quints-4-9",
            tiles: [.joker, .joker, .joker, .c(9), .c(9), .c(9), .c(9), .d(4), .d(4), .d(4), .flower, .flower, .wind(.east)],
            choices: [.quints, .consecutiveRun, .odds13579, .singlesAndPairs],
            answer: .quints,
            explanation: "A kong of 9 Craks and a pung of 4 Dots with three jokers: one joker would turn the kong into a quint, or two the pung. Quints are five of a kind, and only jokers get you there."
        ),
        HandMatchQuestion(
            id: "monthly-rack-sp-mixed",
            tiles: [.c(1), .c(1), .b(4), .b(4), .d(7), .d(7), .d(2), .d(2), .wind(.north), .wind(.north), .dragon(.red), .dragon(.red), .wind(.east)],
            choices: [.singlesAndPairs, .quints, .threeSixNine, .consecutiveRun],
            answer: .singlesAndPairs,
            explanation: "Six natural pairs, no jokers, and numbers that mix odd and even: 1s, 2s, 4s and 7s never fit one number family together. Singles & Pairs is built from pairs like these, and every pair in it must be natural, since it never takes jokers."
        ),
        HandMatchQuestion(
            id: "monthly-rack-sp-flowers",
            tiles: [.b(3), .b(3), .c(8), .c(8), .d(5), .d(5), .wind(.west), .wind(.west), .dragon(.green), .dragon(.green), .d(1), .d(1), .c(9)],
            choices: [.singlesAndPairs, .evens2468, .likeNumbers, .quints],
            answer: .singlesAndPairs,
            explanation: "Six natural pairs and not one joker. Pairs of 1s, 3s, 5s and 8s mix odd and even, so no number family claims them. This is the Singles & Pairs shape."
        ),
        HandMatchQuestion(
            id: "monthly-rack-sp-honors",
            tiles: [.b(2), .b(2), .d(9), .d(9), .c(5), .c(5), .wind(.east), .wind(.east), .wind(.south), .wind(.south), .dragon(.red), .dragon(.red), .b(1)],
            choices: [.singlesAndPairs, .evens2468, .threeSixNine, .quints],
            answer: .singlesAndPairs,
            explanation: "Six natural pairs, three of numbers and three of honors, with no jokers. The numbers (2, 5, 9) belong to no single family, and the honors are pairs, not pungs. Pairs everywhere points to Singles & Pairs."
        ),
        HandMatchQuestion(
            id: "monthly-rack-sp-gapped",
            tiles: [.c(7), .c(7), .d(3), .d(3), .b(4), .b(4), .d(8), .d(8), .wind(.north), .wind(.north), .dragon(.red), .dragon(.red), .c(1)],
            choices: [.singlesAndPairs, .consecutiveRun, .odds13579, .likeNumbers],
            answer: .singlesAndPairs,
            explanation: "Six natural pairs and not one joker. The numbers skip around and mix odd with even, so no run or number family holds them. Natural pairs like these are how a Singles & Pairs hand starts."
        ),
        HandMatchQuestion(
            id: "monthly-rack-sp-even-odd",
            tiles: [.c(2), .c(2), .b(7), .b(7), .d(4), .d(4), .c(9), .c(9), .wind(.east), .wind(.east), .dragon(.red), .dragon(.red), .dragon(.green)],
            choices: [.singlesAndPairs, .threeSixNine, .evens2468, .quints],
            answer: .singlesAndPairs,
            explanation: "Six natural pairs, no jokers. 2s and 4s are even, 7s and 9s are odd, so no number family wants all four. Every pair in Singles & Pairs must be natural, since it never takes jokers."
        ),
        HandMatchQuestion(
            id: "monthly-rack-evens-steps",
            tiles: [.d(2), .d(2), .d(2), .d(4), .d(4), .b(6), .b(6), .b(6), .c(8), .c(8), .c(4), .flower, .joker],
            choices: [.evens2468, .consecutiveRun, .likeNumbers, .threeSixNine],
            answer: .evens2468,
            explanation: "Every number is even: 2s, 4s, 6s and 8s across all three suits, with pungs of 2 Dots and 6 Bams. All evens is the 2468 pattern, and with no odd numbers between them they cannot step up as a run."
        ),
        HandMatchQuestion(
            id: "monthly-rack-honors-pungs",
            tiles: [.wind(.north), .wind(.north), .wind(.north), .wind(.south), .wind(.south), .wind(.south), .dragon(.red), .dragon(.red), .wind(.east), .wind(.west), .flower, .flower, .joker],
            choices: [.windsDragons, .singlesAndPairs, .quints, .likeNumbers],
            answer: .windsDragons,
            explanation: "Pungs of Norths and Souths, a pair of Reds, an East and a West, and not one numbered tile. Every tile is an honor, a flower or a joker, so Winds & Dragons is the read."
        ),
    ]

    // MARK: - Safe Discards

    static let extraDefense: [QuickItem] = [
        defense(
            "dead-three-out",
            "Late in the hand, three 8 Dots are already in the discard pile and you hold the fourth. An opponent with two exposures looks close. Which discard is safest?",
            tiles: [.d(8)],
            choices: ["The 8 Dot", "A 2 Dot nobody has thrown", "A flower", "A tile that fits their exposures"],
            explanation: "With the other three 8 Dots in the discards, nobody can hold a natural pair of them, so your 8 Dot can only help a player waiting on a single 8 Dot or one ready to call it with two jokers. The other three are live tiles anyone might still want.",
            notes: [
                "Nobody has thrown a 2 Dot yet, so any player could still be collecting them.",
                "Many hands use flowers, so a late flower is a risky throw.",
                "A tile that fits their exposures is the kind most likely to finish their hand.",
            ]
        ),
        defense(
            "pays-double",
            "Why do careful players slow down on their discards late in the hand?",
            choices: ["The player who throws the winning tile pays double", "Late discards must match your exposures", "A late discard ends your own chance to win", "Discards after the halfway point are scored"],
            explanation: "When someone wins on a discard, the player who threw it pays double and the other two pay the normal amount. Late in the hand, when hands are close, one careless throw can cost you twice.",
            notes: [
                "Your discards never have to match anything. Any tile you do not want can go.",
                "Throwing a tile does not stop you winning later, as long as your hand can still be made.",
                "Discards are never scored. Only the winning hand is paid.",
            ]
        ),
        defense(
            "self-drawn",
            "A player draws their own winning tile from the wall. Who pays double?",
            choices: ["All three other players", "Nobody", "Only the last player to discard", "Only the player on their left"],
            explanation: "A self-drawn mah jongg is paid double by all three other players. Nobody threw the tile, so nobody pays alone. Only a win on a discard puts the double on one player.",
            notes: [
                "A self-drawn win pays more, not less: everyone pays double.",
                "The last discard had nothing to do with it. The winner drew the tile themselves.",
                "Seat does not matter. All three other players pay double.",
            ]
        ),
        defense(
            "joker-swap",
            "An opponent has exposed 5 Dot, 5 Dot and a joker. On your turn you hold a 5 Dot you do not need. What is the best play?",
            tiles: [.d(5), .d(5), .joker],
            choices: ["Trade your 5 Dot for their joker", "Discard the 5 Dot", "Keep the 5 Dot hidden all game", "Call their exposure"],
            explanation: "On your turn you may swap a matching tile for a joker in any player's exposure. You gain a joker for any pung or larger group you are building, and the 5 Dot leaves your hand without ever reaching the discard pile.",
            notes: [
                "That gives the 5 Dot away and leaves the joker with them. Trading it in gets you a joker instead.",
                "Holding a tile you do not need wastes a spot in your hand, and the joker is yours for the trade.",
                "You can only call a discard, never another player's exposure.",
            ]
        ),
        defense(
            "concealed-quiet",
            "An opponent has called nothing all hand and is discarding calmly. What should you take from that?",
            choices: ["They may be on a concealed hand, so no tile is proven safe against them", "They are far from mah jongg", "They have no jokers", "They are on Winds & Dragons"],
            explanation: "Some hands must be built concealed, and Singles & Pairs never exposes anything before mah jongg. A player with nothing face up can be as close to winning as anyone, and you have no exposures to read, so their discards are your best clue.",
            notes: [
                "No exposures says nothing about how close they are. A concealed hand can get all the way to its last tile with nothing exposed.",
                "Jokers stay hidden in a concealed hand, so you cannot tell how many they hold.",
                "Nothing on the table points to any section. They could be on any concealed hand.",
            ]
        ),
        defense(
            "only-latest",
            "A 3 Bam was discarded three turns ago and nobody called it. Can a player call that 3 Bam now?",
            tiles: [.b(3)],
            choices: ["No, only the latest discard can be called", "Yes, for mah jongg", "Yes, for any pung", "Yes, if they hold a pair of 3 Bams"],
            explanation: "Only the most recent discard can be called. Once play moves on, an earlier tile stays in the pile for the rest of the hand. That is why old discards tell you a lot about what the table does not want.",
            notes: [
                "Not even for mah jongg. Only the latest discard can be claimed.",
                "Pungs follow the same rule: only the latest discard can be claimed.",
                "Holding a pair does not bring an old discard back. Only the latest one can be called.",
            ]
        ),
        defense(
            "mahjongg-priority",
            "You discard a 7 Crak. One player calls it for a pung and another calls it for mah jongg. Who gets it?",
            tiles: [.c(7)],
            choices: ["The player calling mah jongg", "The player calling the pung", "Whoever spoke first", "The player next in turn"],
            explanation: "A call for mah jongg beats a call for an exposure, wherever the players sit. So a tile one opponent only wants for a pung can still be the tile that hands another the game.",
            notes: [
                "An exposure call loses to a mah jongg call.",
                "Speed does not decide it. A mah jongg call always wins.",
                "Seat order settles ties between calls of the same kind. Mah jongg beats an exposure call.",
            ]
        ),
        defense(
            "turn-order",
            "You discard a 4 Bam and two opponents both call it for a pung at the same moment. Neither is going out. Who gets it?",
            tiles: [.b(4)],
            choices: ["The one whose turn comes next", "The one who called first", "The one with more exposures", "Neither: a tie means nobody takes it"],
            explanation: "When two players call the same discard for an exposure at the same moment, the player next in turn after you takes it. Only a call for mah jongg can jump the line.",
            notes: [
                "Turn order settles a tie between calls made at the same moment.",
                "Exposures already down make no difference to who gets a tile.",
                "A tie is settled by turn order. Someone always gets the tile.",
            ]
        ),
        defense(
            "pair-call",
            "Can an opponent call your discarded 6 Bam just to make a pair in their hand?",
            tiles: [.b(6)],
            choices: ["Only if that pair finishes their mah jongg", "Yes, any time", "Yes, if they expose the pair", "Never, even for mah jongg"],
            explanation: "A discard can be called for a pung or a larger group, but for a pair or a single only when it completes mah jongg. So a tile that fits only someone's pair is dangerous just when it is their last tile.",
            notes: [
                "Pairs cannot be called for during play. Only mah jongg unlocks that.",
                "Pairs are never exposed during play. They go down only with mah jongg.",
                "A pair can be called for when it wins the game.",
            ]
        ),
        defense(
            "no-grow",
            "An opponent exposed a pung of 2 Craks several turns ago. You draw the fourth 2 Crak. Can they add it to make a kong?",
            tiles: [.c(2), .c(2), .c(2)],
            choices: ["No, their exposure is finished", "Yes, if you discard it", "Yes, on their own turn", "Only by trading in a joker"],
            explanation: "Once its owner has discarded, an exposed pung stays a pung. Your 2 Crak cannot turn it into a kong, so that exposure cannot use your tile. The tile can still help another player, so check what else is on the table.",
            notes: [
                "They cannot claim a tile to grow an old exposure.",
                "Even on their own turn, an exposure that is already down cannot take more tiles.",
                "Jokers do not change it. The exposure is finished.",
            ]
        ),
        defense(
            "like-4s",
            "An opponent has exposed a pung of 4 Craks and a pung of 4 Dots. Which discard should worry you most?",
            tiles: [.c(4), .c(4), .c(4), .d(4), .d(4), .d(4)],
            choices: ["4 Bam", "9 Crak", "1 Dot", "7 Bam"],
            explanation: "The same number in two suits is the mark of Like Numbers, and the 4 Bam is that number in the third suit. 4s are even too, so the 4 Bam fits both ways of reading this table. The other three are odd, so they miss both.",
            notes: [
                "A 9 is odd and not a 4, so it misses the Like Numbers and evens reads. The 4 Bam fits both.",
                "A 1 is odd and not a 4, so it misses the Like Numbers and evens reads. The 4 Bam fits both.",
                "A 7 is odd and not a 4, so it misses the Like Numbers and evens reads. The 4 Bam fits both.",
            ]
        ),
        defense(
            "like-1s",
            "An opponent has exposed a pung of 1 Bams and a pung of 1 Dots. Which discard should worry you most?",
            tiles: [.b(1), .b(1), .b(1), .d(1), .d(1), .d(1)],
            choices: ["1 Crak", "6 Bam", "8 Dot", "4 Crak"],
            explanation: "One number in two suits points at Like Numbers, and the 1 Crak is that number in the third suit. 1s are odd too, so it fits the odds read as well. The other three are even and miss both reads.",
            notes: [
                "A 6 is even and not a 1, so it misses the Like Numbers and odds reads. The 1 Crak fits both.",
                "An 8 is even and not a 1, so it misses the Like Numbers and odds reads. The 1 Crak fits both.",
                "A 4 is even and not a 1, so it misses the Like Numbers and odds reads. The 1 Crak fits both.",
            ]
        ),
        defense(
            "wind-pungs",
            "An opponent has exposed a pung of East Winds and a pung of West Winds. Which discard should worry you most?",
            tiles: [.wind(.east), .wind(.east), .wind(.east), .wind(.west), .wind(.west), .wind(.west)],
            choices: ["North Wind", "3 Bam", "6 Crak", "8 Dot"],
            explanation: "Two wind pungs could well be Winds & Dragons, and a North is another wind for that same hand. None of these is free, but the North fits what they are showing most directly.",
            notes: [
                "A number tile is less direct than a third wind on this table.",
                "A number tile is less direct than a third wind on this table.",
                "A number tile is less direct than a third wind on this table.",
            ]
        ),
        defense(
            "dragon-pungs",
            "An opponent has exposed a pung of Red Dragons and a pung of Green Dragons. Which discard should worry you most?",
            tiles: [.dragon(.red), .dragon(.red), .dragon(.red), .dragon(.green), .dragon(.green), .dragon(.green)],
            choices: ["Soap", "2 Bam", "5 Crak", "9 Dot"],
            explanation: "Two dragon pungs could well be Winds & Dragons, and the Soap is the third dragon. None of these is free, but the Soap fits what this player is showing most directly.",
            notes: [
                "A number tile is less direct than the third dragon on this table.",
                "A number tile is less direct than the third dragon on this table.",
                "A number tile is less direct than the third dragon on this table.",
            ]
        ),
        defense(
            "run-adjacent",
            "An opponent has exposed a pung of 3 Bams and a pung of 4 Bams. Which discard should worry you most?",
            tiles: [.b(3), .b(3), .b(3), .b(4), .b(4), .b(4)],
            choices: ["5 Bam", "9 Crak", "9 Dot", "8 Dot"],
            explanation: "Pungs of two numbers in a row can point at a Consecutive Run, and the 5 Bam is the next number up. The 8s and 9s sit far from the 3s and 4s, so they are much less likely to fit.",
            notes: [
                "A 9 sits far from the 3s and 4s, a long shot for a run through both. The 5 Bam is next in line.",
                "A 9 sits far from the 3s and 4s, a long shot for a run through both. The 5 Bam is next in line.",
                "An 8 sits far from the 3s and 4s, a long shot for a run through both. The 5 Bam is next in line.",
            ]
        ),
        defense(
            "bam-evens",
            "An opponent has exposed pungs of 2 Bams, 4 Bams and 6 Bams. Which discard should worry you most?",
            tiles: [.b(2), .b(2), .b(2), .b(4), .b(4), .b(4), .b(6), .b(6), .b(6)],
            choices: ["8 Bam", "7 Crak", "1 Dot", "9 Crak"],
            explanation: "Three even pungs in one suit could point at 2468, and the 8 Bam is the even number they have not shown yet. The other three are odd, so they miss the evens read.",
            notes: [
                "A 7 is odd, so it misses the evens read this table may show.",
                "A 1 is odd, so it misses the evens read this table may show.",
                "A 9 is odd, so it misses the evens read this table may show.",
            ]
        ),
        defense(
            "bam-odds",
            "An opponent has exposed a pung of 1 Bams and a pung of 9 Bams. Which discard should worry you most?",
            tiles: [.b(1), .b(1), .b(1), .b(9), .b(9), .b(9)],
            choices: ["5 Bam", "4 Crak", "6 Dot", "4 Dot"],
            explanation: "1s and 9s are both odd, so this could point at 13579, and the 5 Bam is odd and in the same suit. The other three are even and miss that read.",
            notes: [
                "A 4 is even, so it misses the 13579 read of their exposures.",
                "A 6 is even, so it misses the 13579 read of their exposures.",
                "A 4 is even, so it misses the 13579 read of their exposures.",
            ]
        ),
        defense(
            "dot-evens",
            "An opponent has exposed a pung of 2 Dots and a pung of 4 Dots. Which discard should worry you most?",
            tiles: [.d(2), .d(2), .d(2), .d(4), .d(4), .d(4)],
            choices: ["6 Dot", "9 Crak", "7 Bam", "1 Crak"],
            explanation: "Two even pungs in Dots could point at 2468, and the 6 Dot is even and in the same suit as both pungs. The other three are odd and miss the evens read.",
            notes: [
                "A 9 is odd, so it misses the evens read this table may show.",
                "A 7 is odd, so it misses the evens read this table may show.",
                "A 1 is odd, so it misses the evens read this table may show.",
            ]
        ),
        defense(
            "charleston-memory",
            "In the Charleston, the player on your right passed you three Dots. Late in the hand they have two exposures, both in Craks. Thinking only of them, which discard is likeliest to be safe?",
            choices: ["A Dot", "A Bam", "A Crak", "A flower"],
            explanation: "Tiles a player passes in the Charleston are usually tiles they chose to give away (a blind pass is the exception), and they have since built in Craks. A Dot is the likeliest to be dead weight to them. Not certain, since plans change and some hands use all three suits, but it beats a suit you know nothing about or the one they are showing.",
            notes: [
                "Nothing tells you they do not want Bams. The Dots are the suit they gave away.",
                "Craks are the suit their exposures are built in, so a Crak is the riskiest suit to throw against them.",
                "Many hands use flowers, so a flower is a risky throw against anyone.",
            ]
        ),
        defense(
            "wall-endgame",
            "Six tiles are left in the wall and your hand can no longer win. What matters most now?",
            choices: ["Throwing the tiles least likely to finish anyone else's hand", "Drawing toward your own hand anyway", "Throwing whatever you just drew", "Calling every tile you can"],
            explanation: "With your own hand out of reach, every discard is only a risk. Throw the tiles the table has already let go by, since those are least likely to help anyone, and keep the ones that fit what opponents are showing. If the wall runs out with no winner, nobody pays.",
            notes: [
                "Your hand cannot win, so drawing toward it gains nothing, and the risky tiles still have to go somewhere.",
                "Throwing whatever you draw ignores which tiles are dangerous.",
                "Calling gains you nothing, since your hand cannot win.",
            ]
        ),
        defense(
            "early-safest",
            "Early in the hand, nobody has exposed anything. Which discard is safest?",
            choices: ["A tile matching one already discarded this hand", "A flower", "A tile you just drew", "One tile from a pair you hold"],
            explanation: "A tile the table has already let go by is the one with the best evidence behind it: somebody threw it and nobody called it. Early on little is truly dangerous, but the habit of throwing seen tiles pays off later.",
            notes: [
                "Many hands use flowers, so a flower is less safe than a tile the table has already let go by.",
                "A fresh tile has no history at all. You cannot tell who wants it.",
                "Breaking your own pair costs you a start, and the tile is no safer for it.",
            ]
        ),
        defense(
            "count-kong",
            "An opponent has exposed a kong of four natural 9 Bams. How many 9 Bams can you still draw from the wall?",
            tiles: [.b(9), .b(9), .b(9), .b(9)],
            choices: ["None", "One", "Two", "It depends on the discards"],
            explanation: "There are four of every tile, and all four 9 Bams are in that kong. None can turn up in the wall, so drop any plan that needs 9 Bams.",
            notes: [
                "All four copies are in that kong, so not even one is left.",
                "All four copies are in that kong, so none is left.",
                "The discards do not matter here. All four are already face up.",
            ]
        ),
        defense(
            "hidden-tiles",
            "An opponent has three pungs exposed. Between turns, how many tiles are still hidden in their hand?",
            choices: ["4", "1", "7", "10"],
            explanation: "A player holds 13 tiles between turns, exposed groups included. Three exposed pungs account for 9, so 4 are hidden. That player may be close, so watch what you feed them.",
            notes: [
                "Three pungs are 9 tiles, and a hand holds 13 between turns, so 4 are left.",
                "Three pungs are 9 tiles, and a hand holds 13 between turns, so 4 are left.",
                "Three pungs are 9 tiles, and a hand holds 13 between turns, so 4 are left.",
            ]
        ),
        defense(
            "discard-after-call",
            "Your left opponent calls a tile, exposes a pung, and then discards a 2 Dot. What does that suggest?",
            choices: ["2 Dots probably do not fit their plan", "2 Dots fit their exposure", "They are about to declare mah jongg", "They are out of jokers"],
            explanation: "A player who just reshaped their hand around an exposure chose the 2 Dot as the tile to let go. It is not proof, since players sometimes break a pair to keep options, but it is the best hint you have about what they do not need.",
            notes: [
                "They chose to throw a 2 Dot away, which is not what a player does with a tile they need.",
                "Nothing about one discard says they are about to win.",
                "A discard says nothing about how many jokers they hold.",
            ]
        ),
        defense(
            "jokers-call",
            "Nobody can hold a natural pair of the tile you are about to throw. Why is it still not completely safe?",
            choices: ["A player with a joker or two can call it for a pung", "Discards can be called for pairs at any time", "Exposed pungs can grow into kongs", "Flowers can stand in for it"],
            explanation: "Jokers fill out any group of three or more, so a player holding one copy plus a joker, or two jokers, can call your tile and expose it as a pung. It could also be someone's winning tile as a single. Rare, but never impossible.",
            notes: [
                "A pair can be called for only with mah jongg.",
                "Once its owner has discarded, an exposure never grows.",
                "Flowers are their own tiles. Only jokers stand in for others.",
            ]
        ),
        defense(
            "all-four-out",
            "All four 2 Bams were discarded earlier in the hand, and other tiles have been thrown since. Which of these is true?",
            tiles: [.b(2), .b(2), .b(2), .b(2)],
            choices: ["Nobody can draw a 2 Bam this hand", "Jokers can no longer be used anywhere", "A 2 Bam can still be called from the pile", "The hand has to be thrown in"],
            explanation: "Every 2 Bam is face up in the discards, so none is left in the wall or in anyone's rack. Old discards can never be called back, and the hand goes on as normal.",
            notes: [
                "Jokers still work as usual. Only the 2 Bams themselves are gone.",
                "Only the latest discard can ever be called, and these went by long ago.",
                "Nothing stops the hand. Play goes on as normal.",
            ]
        ),
        defense(
            "own-joker",
            "You have exposed 7 Crak, 7 Crak and a joker. What can an opponent do with that joker?",
            tiles: [.c(7), .c(7), .joker],
            choices: ["Trade a 7 Crak for it on their turn", "Take it any time they like", "Nothing: an exposed joker is locked", "Call it when you discard"],
            explanation: "Any player may swap the matching tile for a joker in an exposure, on their own turn. Whoever gets hold of another 7 Crak can take your joker, which is worth remembering before you expose with one.",
            notes: [
                "Only on their own turn, and only by handing over a 7 Crak.",
                "Exposed jokers can be traded for the real tile they stand in for.",
                "The joker is in your exposure, not the discard pile, so nobody calls it.",
            ]
        ),
        defense(
            "crak-run",
            "The player on your right has discarded three Craks in a row. Which suit are they least likely to be collecting?",
            choices: ["Craks", "Bams", "Dots", "No way to tell"],
            explanation: "Players throw what they do not need. Three Craks in a row says Craks are not their plan right now. It is a lean, not proof, but it is the kind of clue that adds up over a hand.",
            notes: [
                "Nothing says they are short of Bams. The Craks are the suit they keep letting go.",
                "Nothing says they are short of Dots. The Craks are the suit they keep letting go.",
                "Discards are the clue. Three of one suit in a row is a real hint.",
            ]
        ),
        defense(
            "flower-count",
            "Six flowers are already face up in the discards and exposures. How many flowers could still be in play?",
            tiles: [.flower],
            choices: ["Two", "None", "Four", "Six"],
            explanation: "A set has eight flowers. With six face up, only two remain in the wall or in someone's rack, so a hand that needs several more flowers is in trouble. Counting what is face up tells you what is still possible.",
            notes: [
                "A set has eight flowers, so two are still out there.",
                "A set has eight flowers, so six face up leaves two.",
                "A set has eight flowers, so six face up leaves two.",
            ]
        ),
        defense(
            "joker-count",
            "Five jokers are face up around the table, in exposures and discards. How many are not face up?",
            tiles: [.joker],
            choices: ["Three", "None", "Five", "One"],
            explanation: "A set has eight jokers. Five face up leaves three, which could be in any rack or still in the wall. Count jokers before you trust that a tile is dead.",
            notes: [
                "A set has eight jokers, so three are not face up.",
                "A set has eight jokers, so five face up leaves three.",
                "A set has eight jokers, so five face up leaves three.",
            ]
        ),
    ]

    private static func defense(
        _ slug: String,
        _ prompt: String,
        tiles: [Tile] = [],
        choices: [String],
        explanation: String,
        notes: [String]
    ) -> QuickItem {
        QuickItem(
            id: "monthly-def-\(slug)",
            prompt: prompt,
            tiles: tiles,
            choices: choices,
            answerIndex: 0,
            explanation: explanation,
            sourceLabel: "Monthly Challenge",
            roomID: "table-room",
            isReviewable: false,
            choiceNotes: [nil] + notes
        )
    }

    // MARK: - The Charleston

    static let extraPasses: [CharlestonScenario] = [
        CharlestonScenario(
            id: "monthly-ch-evens-right",
            situation: "First Charleston, pass RIGHT. Your evens are lining up. Pick 3.",
            deal: [.b(2), .b(2), .b(4), .b(4), .b(4), .c(6), .c(6), .d(8), .d(8), .flower, .c(3), .b(9), .wind(.north)],
            recommendedPass: [.c(3), .b(9), .wind(.north)],
            reasoning: "Pairs of 2s, 6s and 8s with a pung of 4 Bams: this rack is 2468. The 3 Crak and 9 Bam are odd and the North is a lone wind, so none of them fits the evens plan. Keep the flower, which many hands use.",
            tip: "Count the tiles that fit your lean. The ones left over are your first pass."
        ),
        CharlestonScenario(
            id: "monthly-ch-odds-across",
            situation: "First Charleston, pass ACROSS. Odd numbers are piling up. Pick 3.",
            deal: [.d(1), .d(1), .d(3), .d(3), .d(3), .b(5), .b(5), .c(9), .c(9), .flower, .b(6), .d(8), .wind(.west)],
            recommendedPass: [.b(6), .d(8), .wind(.west)],
            reasoning: "A pung of 3 Dots and pairs of 1s, 5s and 9s make a 13579 rack. The 6 Bam and 8 Dot are even, so an odds hand can never use them, and the West is a lone wind. Those three go.",
            tip: "Pass by family: when the rack is odd, the even tiles leave first."
        ),
        CharlestonScenario(
            id: "monthly-ch-369-left",
            situation: "First Charleston, pass LEFT. You hold 3s, 6s and 9s. Pick 3.",
            deal: [.c(3), .c(3), .c(3), .b(6), .b(6), .d(9), .d(9), .d(6), .flower, .joker, .b(2), .c(7), .wind(.south)],
            recommendedPass: [.b(2), .c(7), .wind(.south)],
            reasoning: "A pung of 3 Craks, pairs of 6 Bams and 9 Dots, and a single 6 Dot: eight tiles of 3s, 6s and 9s. The 2 Bam and 7 Crak are outside that family, and the South is a lone wind.",
            tip: "369 needs its 6s. Without them the same 3s and 9s are just an odds hand."
        ),
        CharlestonScenario(
            id: "monthly-ch-run-across",
            situation: "First Charleston, pass ACROSS. Your numbers sit in the middle. Pick 3.",
            deal: [.b(3), .b(4), .b(5), .d(4), .d(5), .d(6), .d(6), .c(6), .flower, .joker, .b(1), .d(9), .wind(.north)],
            recommendedPass: [.b(1), .d(9), .wind(.north)],
            reasoning: "3-4-5 in Bams and 4-5-6 in Dots with a 6 Dot pair and a 6 Crak: this rack steps through the middle numbers, the start of a Consecutive Run. The 1 Bam and 9 Dot are long shots for a run built on 3 through 6, and the North is a lone wind.",
            tip: "In a run hand, keep the numbers that sit close together and pass the far ones."
        ),
        CharlestonScenario(
            id: "monthly-ch-winds-right",
            situation: "First Charleston, pass RIGHT. Winds keep coming. Pick 3.",
            deal: [.wind(.east), .wind(.east), .wind(.east), .wind(.north), .wind(.north), .wind(.south), .wind(.west), .dragon(.red), .dragon(.red), .flower, .c(2), .b(5), .d(9)],
            recommendedPass: [.c(2), .b(5), .d(9)],
            reasoning: "A pung of Easts, a pair of Norths, the other two winds and a pair of Reds: this rack is heading for Winds & Dragons. The three number tiles are in different suits and no two work together, so they are the passes.",
            tip: "When honors take over a rack, scattered numbers are the easiest tiles to let go."
        ),
        CharlestonScenario(
            id: "monthly-ch-like-3s",
            situation: "Second Charleston, pass LEFT. You hold seven 3s. Pick 3.",
            deal: [.c(3), .c(3), .b(3), .b(3), .b(3), .d(3), .d(3), .flower, .flower, .joker, .c(8), .d(2), .wind(.north)],
            recommendedPass: [.c(8), .d(2), .wind(.north)],
            reasoning: "Seven 3s across all three suits is a strong Like Numbers start. The 8 Crak and 2 Dot fit neither Like Numbers nor a 369 backup, and the North is a lone wind.",
            tip: "Seven of one number is a hand. Pass the tiles that do nothing for that number."
        ),
        CharlestonScenario(
            id: "monthly-ch-evens-across",
            situation: "Second Charleston, pass ACROSS. Your evens are set. Pick 3.",
            deal: [.c(4), .c(4), .c(4), .c(8), .c(8), .d(2), .d(2), .b(6), .b(6), .flower, .d(5), .b(7), .dragon(.green)],
            recommendedPass: [.d(5), .b(7), .dragon(.green)],
            reasoning: "A pung of 4 Craks and pairs of 8s, 2s and 6s: a clean 2468 rack. The 5 Dot and 7 Bam are odd, and the single Green Dragon has no partner. Pass those three and keep every even tile.",
            tip: "Once the rack has picked a family, every pass should make it purer."
        ),
        CharlestonScenario(
            id: "monthly-ch-odds-last",
            situation: "Second Charleston, the LAST pass, going RIGHT. Your odds are strong. Pick 3.",
            deal: [.c(5), .c(5), .c(5), .b(7), .b(7), .d(1), .d(1), .c(9), .b(3), .flower, .d(4), .c(6), .wind(.east)],
            recommendedPass: [.d(4), .c(6), .wind(.east)],
            reasoning: "A pung of 5 Craks and pairs of 7 Bams and 1 Dots, with a 9 and a 3 besides: nine odd tiles. The 4 Dot and 6 Crak are even, and the East is a lone wind. Out they go.",
            tip: "On this last pass you may pass blind, but when you hold clear misfits, pass the misfits."
        ),
        CharlestonScenario(
            id: "monthly-ch-369-courtesy",
            situation: "Courtesy pass, 3 tiles across. Your 369 is well along. Pick 3.",
            deal: [.c(6), .c(6), .c(6), .b(9), .b(9), .b(9), .d(3), .d(3), .flower, .flower, .c(1), .b(8), .wind(.west)],
            recommendedPass: [.c(1), .b(8), .wind(.west)],
            reasoning: "Pungs of 6 Craks and 9 Bams with a pair of 3 Dots: this is a 369 rack. The 1 Crak and 8 Bam are outside the family and the West is a lone wind, so they are the courtesy tiles.",
            tip: "The courtesy pass is optional. You and the player across agree on up to three tiles."
        ),
        CharlestonScenario(
            id: "monthly-ch-run-left",
            situation: "First Charleston, pass LEFT. Your numbers step from 5 to 8. Pick 3.",
            deal: [.c(5), .c(6), .c(7), .b(6), .b(7), .b(8), .d(7), .d(7), .flower, .joker, .d(1), .c(2), .wind(.south)],
            recommendedPass: [.d(1), .c(2), .wind(.south)],
            reasoning: "5-6-7 in Craks, 6-7-8 in Bams and a pair of 7 Dots: the start of a Consecutive Run in the upper numbers. The 1 Dot and 2 Crak are long shots for a run built on 5 through 8, and the South is a lone wind.",
            tip: "Find the stretch your numbers share, then pass what falls outside it."
        ),
        CharlestonScenario(
            id: "monthly-ch-dragons",
            situation: "First Charleston, pass ACROSS. Dragons are stacking up. Pick 3.",
            deal: [.dragon(.red), .dragon(.red), .dragon(.red), .dragon(.green), .dragon(.green), .dragon(.soap), .dragon(.soap), .wind(.north), .wind(.east), .flower, .b(3), .c(8), .d(6)],
            recommendedPass: [.b(3), .c(8), .d(6)],
            reasoning: "A pung of Reds, pairs of Greens and Soaps, and two winds: this rack is built on honors, so Winds & Dragons is the lean. The three numbers are scattered across suits and do not pair up, so they are the cheapest to give.",
            tip: "Dragons and winds are both honors. A rack full of them wants Winds & Dragons."
        ),
        CharlestonScenario(
            id: "monthly-ch-joker-keep",
            situation: "First Charleston, pass RIGHT. Two jokers and a lean toward evens. Pick 3.",
            deal: [.joker, .joker, .c(2), .c(2), .c(4), .d(6), .d(6), .b(8), .flower, .flower, .b(3), .d(9), .wind(.east)],
            recommendedPass: [.b(3), .d(9), .wind(.east)],
            reasoning: "Six even tiles with pairs of 2 Craks and 6 Dots, two jokers for its pungs and two flowers. The 3 Bam and 9 Dot are odd, and the East is a lone wind. Jokers can never be passed, so the three misfits are the pass.",
            tip: "Jokers never leave in the Charleston. Plan your three passes around them."
        ),
        CharlestonScenario(
            id: "monthly-ch-like-9s",
            situation: "Second Charleston, pass ACROSS. Nines in every suit. Pick 3.",
            deal: [.c(9), .c(9), .c(9), .b(9), .b(9), .d(9), .d(9), .flower, .flower, .joker, .c(4), .b(2), .wind(.west)],
            recommendedPass: [.c(4), .b(2), .wind(.west)],
            reasoning: "Seven 9s across three suits: Like Numbers is the plan. The 4 Crak and 2 Bam fit neither Like Numbers nor an odds or 369 backup, and the West is a lone wind.",
            tip: "Keep a backup in mind when you pass: here odds and 369 both still use your 9s."
        ),
        CharlestonScenario(
            id: "monthly-ch-honors-left",
            situation: "Second Charleston, pass LEFT. Honors everywhere. Pick 3.",
            deal: [.wind(.north), .wind(.north), .wind(.north), .wind(.west), .wind(.west), .wind(.south), .dragon(.green), .dragon(.green), .dragon(.soap), .flower, .c(4), .b(6), .d(1)],
            recommendedPass: [.c(4), .b(6), .d(1)],
            reasoning: "A pung of Norths, a pair of Wests, a South, a pair of Greens and a Soap: nine honors and a flower. The three numbers sit in different suits and do not pair up, so they are the easiest passes.",
            tip: "Second Charleston passes should keep making the rack purer, never mixing in a new idea."
        ),
        CharlestonScenario(
            id: "monthly-ch-evens-dots",
            situation: "First Charleston, pass ACROSS. Your Dots are all even. Pick 3.",
            deal: [.d(2), .d(2), .d(4), .d(4), .d(6), .d(8), .d(8), .c(6), .c(6), .flower, .b(1), .c(3), .wind(.north)],
            recommendedPass: [.b(1), .c(3), .wind(.north)],
            reasoning: "Even Dots from 2 to 8 with three pairs, plus a pair of 6 Craks: this is a 2468 rack. The 1 Bam and 3 Crak are odd and the North is a lone wind.",
            tip: "When one suit carries a whole family, keep it and pass the numbers from the other family."
        ),
        CharlestonScenario(
            id: "monthly-ch-369-right",
            situation: "First Charleston, pass RIGHT. Mostly 3s, 6s and 9s. Pick 3.",
            deal: [.b(3), .b(3), .b(3), .d(6), .d(6), .c(9), .c(9), .b(6), .flower, .joker, .d(5), .c(8), .wind(.east)],
            recommendedPass: [.d(5), .c(8), .wind(.east)],
            reasoning: "A pung of 3 Bams, pairs of 6 Dots and 9 Craks and a 6 Bam: eight tiles of 3s, 6s and 9s. The 5 Dot and 8 Crak fall outside that family, and the East is a lone wind.",
            tip: "Read the family first, then the passes pick themselves."
        ),
        CharlestonScenario(
            id: "monthly-ch-run-low",
            situation: "Second Charleston, pass ACROSS. Your numbers sit low. Pick 3.",
            deal: [.c(1), .c(2), .c(3), .b(2), .b(3), .b(4), .d(3), .d(3), .flower, .joker, .c(8), .b(9), .wind(.west)],
            recommendedPass: [.c(8), .b(9), .wind(.west)],
            reasoning: "1-2-3 in Craks, 2-3-4 in Bams and a pair of 3 Dots: the low end of a Consecutive Run. The 8 Crak and 9 Bam are long shots for a run built on 1 through 4, and the West is a lone wind.",
            tip: "Low runs and high runs both work. What matters is that the numbers stay together."
        ),
        CharlestonScenario(
            id: "monthly-ch-odds-flowers",
            situation: "First Charleston, pass LEFT. Three flowers and a pile of odds. Pick 3.",
            deal: [.flower, .flower, .flower, .b(1), .b(1), .b(3), .c(5), .c(5), .d(7), .d(9), .c(4), .b(8), .wind(.south)],
            recommendedPass: [.c(4), .b(8), .wind(.south)],
            reasoning: "Three flowers and seven odd tiles with pairs of 1 Bams and 5 Craks: this is a 13579 rack. The 4 Crak and 8 Bam are even and the South is a lone wind. The flowers stay: many hands use them.",
            tip: "Flowers are hard to replace. Pass them only when nothing else can go."
        ),
        CharlestonScenario(
            id: "monthly-ch-like-5s",
            situation: "First Charleston, pass RIGHT. Fives everywhere, and two jokers. Pick 3.",
            deal: [.c(5), .c(5), .b(5), .b(5), .b(5), .d(5), .d(5), .flower, .joker, .joker, .c(2), .d(8), .wind(.north)],
            recommendedPass: [.c(2), .d(8), .wind(.north)],
            reasoning: "Seven 5s across three suits with two jokers: Like Numbers is the lean, and the jokers could push the 5s toward Quints too. The 2 Crak and 8 Dot are even, so they fit neither Like Numbers nor an odds backup, and the North is a lone wind.",
            tip: "Jokers make a big pile of one number even stronger. Keep feeding the number you hold most of."
        ),
    ]
}
