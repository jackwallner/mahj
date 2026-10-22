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
            backBody: "It's an odd number in a suit you're not using, so it misses your hand twice. The only reason to hold a tile like this is defense late in the game. Early on, it's your cleanest discard.",
            choice: CardChoice("Keep it", "Throw it", answerIndex: 1)
        ),
        Flashcard(
            id: "kd-third-flower",
            frontTitle: "You hold FF and your hand needs exactly two flowers.",
            frontTiles: [.flower, .flower, .flower],
            frontSubtitle: "You draw a third F. Keep or throw?",
            backTitle: "Hold It (For Now)",
            backBody: "While your hand could still change, a spare flower is insurance. You can swap it for a joker in someone's flower exposure, and switching lines can change how many flowers you need. Once you are locked into a line with exactly two, it becomes a fine discard.",
            choice: CardChoice("Keep it", "Throw it", answerIndex: 0)
        ),
        Flashcard(
            id: "kd-joker-rescue",
            frontTitle: "Your hand is going nowhere, but you hold a joker.",
            frontTiles: [.joker],
            frontSubtitle: "Bail on the hand or the joker?",
            backTitle: "The Joker Stays",
            backBody: "Rebuild the hand around the joker. A joker can rescue any section except Singles & Pairs. Re-scan the card for sections where your joker plus your longest tiles fit. Only late in the hand, with no way left to win, is a joker the safest discard you own, because nobody can call it.",
            choice: CardChoice("Rebuild around the joker", "Toss the joker", answerIndex: 0)
        ),
        Flashcard(
            id: "kd-joker-swap",
            frontTitle: "An opponent's exposed kong shows a joker.",
            frontTiles: [.b(6), .b(6), .joker, .b(6)],
            frontSubtitle: "You just drew the real 6 Bam. Now what?",
            backTitle: "Swap It",
            backBody: "On your turn, place your real 6 Bam on their exposure and take the joker. You trade one tile for a more flexible one, so check the exposures on the table for jokers every turn.",
            choice: CardChoice("Swap for the joker", "Keep the 6 Bam", answerIndex: 0)
        ),
        Flashcard(
            id: "kd-sp-joker",
            frontTitle: "You're committed to Singles & Pairs.",
            frontTiles: [.joker],
            frontSubtitle: "You draw a joker. Good news?",
            backTitle: "Not for This Hand",
            backBody: "Jokers can't be used in Singles & Pairs, which has no groups of 3 or more. If you're truly close, play on. If you're 4 or more tiles away, this joker is a good reason to switch sections.",
            choice: CardChoice("Great news", "Not for this hand", answerIndex: 1)
        ),
        Flashcard(
            id: "kd-count-four",
            frontTitle: "How many 5 Craks exist in the whole set?",
            frontTiles: [.c(5), .c(5), .c(5), .c(5)],
            frontSubtitle: "And why should you care?",
            backTitle: "Four, So Keep Count",
            backBody: "Only four copies of every tile. If one 5 Crak is in the discards and one is exposed, your pair of 5 Craks can never become a pung without a joker. Counting visible copies tells you when a hand can no longer be made.",
            choice: CardChoice("Three", "Four", answerIndex: 1)
        ),
        Flashcard(
            id: "kd-exposed-pung",
            frontTitle: "Your left opponent exposes a pung of 4 Dots.",
            frontTiles: [.d(4), .d(4), .d(4)],
            frontSubtitle: "What did you just learn?",
            backTitle: "It Narrows Their Hand",
            backBody: "An exposure narrows their hand to the card lines that use it. An evens hand, a run through 4, or a like-numbers hand of 4s could all fit. Before discarding another 4, or an even number such as 2, 6 or 8, pause and think about what their exposure could belong to.",
            choice: CardChoice("It narrows their hand", "Nothing useful", answerIndex: 0)
        ),
        Flashcard(
            id: "kd-follow-count",
            frontTitle: "Two tiles fit Hand A. Nine tiles fit Hand B.",
            frontSubtitle: "But you like Hand A...",
            backTitle: "Play the Nine",
            backBody: "Follow the count. The hand with more tiles home needs fewer lucky draws, unless the other is far more flexible or pays far more. Recount every few draws, because the best hand for your rack changes as tiles arrive.",
            choice: CardChoice("Play Hand A", "Play Hand B", answerIndex: 1)
        ),
        Flashcard(
            id: "kd-wind-pair",
            frontTitle: "Early in the hand, you hold N N and draw a third North.",
            frontTiles: [.wind(.north), .wind(.north), .wind(.north)],
            frontSubtitle: "Keep the pung?",
            backTitle: "Keep It If a Line Uses It",
            backBody: "A natural pung of winds is a real asset, but only in a hand that calls for one. Check your card for lines that use it. Keep it if you can commit to one of them. If your hand lives elsewhere, a wind pung is three dead tiles.",
            choice: CardChoice("Keep it", "Break it up", answerIndex: 0)
        ),
        Flashcard(
            id: "kd-flower-vs-wind",
            frontTitle: "Early in the game, you must throw a flower or a lone wind.",
            frontTiles: [.flower, .wind(.east)],
            frontSubtitle: "Which is safer?",
            backTitle: "Throw the Wind",
            backBody: "All eight flowers are interchangeable, so any flower you throw fits anyone collecting flowers. An East fits only a player collecting Easts, and only three others exist. Neither is truly safe, but early on the lone wind is usually the lighter throw.",
            choice: CardChoice("Throw the flower", "Throw the wind", answerIndex: 1)
        ),
        Flashcard(
            id: "kd-dead-joker",
            frontTitle: "Your hand looks hopeless and you hold three jokers.",
            frontTiles: [.joker, .joker, .joker],
            frontSubtitle: "Just throw a joker?",
            backTitle: "Almost Never",
            backBody: "A discarded joker cannot be called, so it is safe, but it is gone for good. Three jokers can rescue a slow hand. They can fill pungs of anything you hold two of, kongs, even quints. Look for a new line before you give one up.",
            choice: CardChoice("Throw a joker", "Rebuild instead", answerIndex: 1)
        ),
        Flashcard(
            id: "kd-call-cost",
            frontTitle: "You can call that discard for an exposed pung.",
            frontSubtitle: "Should you?",
            backTitle: "Calling Has a Price",
            backBody: "Calling locks you onto hands that fit the exposure, tells the table your section, and kills any concealed hand. Call when it moves a hand you are already committed to clearly closer to done, not just because you can.",
            choice: CardChoice("Always call", "Only if it pays", answerIndex: 1)
        ),
        Flashcard(
            id: "kd-mahj-call",
            frontTitle: "Your hand is concealed (marked C) and someone throws your winning tile.",
            frontSubtitle: "Can you call it?",
            backTitle: "Yes, Call Mah Jongg",
            backBody: "Concealed only bans exposures before the win. Any hand, concealed or not, may call the final winning tile. If the tile wins your hand, call it.",
            choice: CardChoice("Yes, call it", "No, stay silent", answerIndex: 0)
        ),
        Flashcard(
            id: "kd-hot-late",
            frontTitle: "It's late, one opponent is clearly close.",
            frontSubtitle: "How do you pick a discard?",
            backTitle: "Throw Dead Tiles",
            backBody: "Prefer tiles matching no exposure on their rack, tiles others already threw without anyone calling them, and tiles with 3 copies already visible. Those are safer, not safe. Jokers can still finish a group, and a lone tile can be their winner. Sometimes the right play is breaking your own hand to avoid throwing it.",
            choice: CardChoice("Gut feel is fine", "Throw dead tiles", answerIndex: 1)
        ),
    ]
}
