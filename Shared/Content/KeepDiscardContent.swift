import Foundation

/// The Table Room: keep-or-pass judgment calls and table smarts,
/// quick-hit flashcards for real-game decisions.
enum KeepDiscardContent {

    static let judgmentCards: [Flashcard] = [
        Flashcard(
            id: "kd-wrong-parity",
            frontTitle: "You're building 2468 in craks and dots.",
            frontTiles: [.b(3)],
            frontSubtitle: "You draw 3 Bam. Keep or throw?",
            backTitle: "Throw It",
            backBody: "Odd number, wrong suit: it fails your hand on both axes. The only reason to hold a tile like this is defense late in the game. Early on, it's your cleanest discard.",
            choice: CardChoice("Keep it", "Throw it", answerIndex: 1)
        ),
        Flashcard(
            id: "kd-third-flower",
            frontTitle: "You hold FF and your hand needs exactly two flowers.",
            frontTiles: [.flower, .flower, .flower],
            frontSubtitle: "You draw a third F. Keep or throw?",
            backTitle: "Hold It (For Now)",
            backBody: "A spare flower is insurance: if a flower gets jokered on someone's rack you can swap in, and if you change hands the F count often changes. Late game, a flower is also a dangerous throw since so many hands need them.",
            choice: CardChoice("Keep it", "Throw it", answerIndex: 0)
        ),
        Flashcard(
            id: "kd-joker-rescue",
            frontTitle: "Your hand is going nowhere, but you hold a joker.",
            frontTiles: [.joker],
            frontSubtitle: "Bail on the hand or the joker?",
            backTitle: "The Joker Stays",
            backBody: "Rebuild the hand around the joker, never the other way. A joker rescues nearly any section (except Singles & Pairs). Re-scan the card for sections where your joker plus your longest tiles fit.",
            choice: CardChoice("Rebuild around the joker", "Toss the joker", answerIndex: 0)
        ),
        Flashcard(
            id: "kd-joker-swap",
            frontTitle: "An opponent's exposed kong shows a joker.",
            frontTiles: [.b(6), .b(6), .joker, .b(6)],
            frontSubtitle: "You just drew the real 6 Bam. Now what?",
            backTitle: "Swap It!",
            backBody: "On your turn, place your real 6 Bam on their exposure and take the joker. This is the single biggest free upgrade in the game, and new players miss it constantly. Scan every rack, every turn.",
            choice: CardChoice("Swap for the joker", "Keep the 6 Bam", answerIndex: 0)
        ),
        Flashcard(
            id: "kd-sp-joker",
            frontTitle: "You're committed to Singles & Pairs.",
            frontTiles: [.joker],
            frontSubtitle: "You draw a joker. Good news?",
            backTitle: "Actually... No",
            backBody: "Jokers are useless in Singles & Pairs: no groups of 3+ exist there. If you're truly close, play on. If you're 4+ tiles away, this joker is a strong argument to switch sections.",
            choice: CardChoice("Great news", "Not for this hand", answerIndex: 1)
        ),
        Flashcard(
            id: "kd-count-four",
            frontTitle: "How many 5 Craks exist in the whole set?",
            frontTiles: [.c(5), .c(5), .c(5), .c(5)],
            frontSubtitle: "And why should you care?",
            backTitle: "Four. Count Them.",
            backBody: "Only four copies of every tile. If two 5 Craks are in the discards and one is exposed, your 5C pair can never become a pung without a joker. Counting visible copies tells you when a hand is dead.",
            choice: CardChoice("Three", "Four", answerIndex: 1)
        ),
        Flashcard(
            id: "kd-exposed-pung",
            frontTitle: "Your left opponent exposes a pung of 4 Dots.",
            frontTiles: [.d(4), .d(4), .d(4)],
            frontSubtitle: "What did you just learn?",
            backTitle: "Their Section Is Showing",
            backBody: "An exposure narrows their hand to a few card lines: probably an even hand or like-numbers around 4s and dots. Before discarding 4s, dots, or even 2-6-8 dots, pause and check what their exposure could belong to.",
            choice: CardChoice("Their section is showing", "Nothing useful", answerIndex: 0)
        ),
        Flashcard(
            id: "kd-follow-count",
            frontTitle: "Two tiles fit Hand A. Nine tiles fit Hand B.",
            frontSubtitle: "But you LIKE Hand A...",
            backTitle: "Play the Nine",
            backBody: "Always follow the count. The hand with more tiles home needs fewer miracles. Recount after every few draws: the best hand for your rack changes as tiles arrive.",
            choice: CardChoice("Play Hand A", "Play Hand B", answerIndex: 1)
        ),
        Flashcard(
            id: "kd-wind-pair",
            frontTitle: "You hold N N and draw a third North.",
            frontTiles: [.wind(.north), .wind(.north), .wind(.north)],
            frontSubtitle: "Keep the pung?",
            backTitle: "Keep It",
            backBody: "A natural pung of winds is a real asset, but be honest: winds only score in the Winds & Dragons section. Keep it if you can commit there; if your hand lives elsewhere, a wind pung is three dead tiles.",
            choice: CardChoice("Keep it", "Break it up", answerIndex: 0)
        ),
        Flashcard(
            id: "kd-flower-vs-wind",
            frontTitle: "Early game: you must throw a flower or a lone wind.",
            frontTiles: [.flower, .wind(.east)],
            frontSubtitle: "Which is safer?",
            backTitle: "Throw the Wind",
            backBody: "Flowers appear across many sections of the card, so early flowers get called often. A lone wind mostly matters to one section. Early wind throws are usually safe; flower throws help somebody.",
            choice: CardChoice("Throw the flower", "Throw the wind", answerIndex: 1)
        ),
        Flashcard(
            id: "kd-dead-joker",
            frontTitle: "Your hand is dead and you hold three jokers.",
            frontTiles: [.joker, .joker, .joker],
            frontSubtitle: "Just throw a joker?",
            backTitle: "Almost Never",
            backBody: "A discarded joker is dead: nobody can call it, so it's not even dangerous, just wasted. Three jokers is enough to resurrect almost any hand: pungs of anything you hold two of, kongs, quints. Rebuild instead.",
            choice: CardChoice("Throw a joker", "Rebuild instead", answerIndex: 1)
        ),
        Flashcard(
            id: "kd-call-cost",
            frontTitle: "You CAN call that discard for an exposed pung.",
            frontSubtitle: "Should you?",
            backTitle: "Calling Has a Price",
            backBody: "Calling locks you onto hands that fit the exposure, tells the table your section, and kills any concealed hand. Call when it puts you clearly ahead (2+ tiles closer on a committed hand), not just because you can.",
            choice: CardChoice("Always call", "Only if it pays", answerIndex: 1)
        ),
        Flashcard(
            id: "kd-mahj-call",
            frontTitle: "Your hand is concealed (marked C) and someone throws your winning tile.",
            frontSubtitle: "Can you call it?",
            backTitle: "Yes! Mahj Jongg!",
            backBody: "Concealed only bans exposures BEFORE the win. Any hand, concealed or not, may call the final winning tile. Don't sit silently on a win: call it.",
            choice: CardChoice("Yes, call it", "No, stay silent", answerIndex: 0)
        ),
        Flashcard(
            id: "kd-hot-late",
            frontTitle: "It's late, one opponent is clearly close.",
            frontSubtitle: "How do you pick a discard?",
            backTitle: "Throw Dead Tiles",
            backBody: "Prefer tiles with 3 copies already visible, tiles matching NO exposure on their rack, and tiles others already threw safely. Sometimes the right play is breaking your own hand to avoid throwing their winner.",
            choice: CardChoice("Gut feel is fine", "Throw dead tiles", answerIndex: 1)
        ),
    ]
}
