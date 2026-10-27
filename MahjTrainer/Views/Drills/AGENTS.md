# Flashcard deck (signature interaction)

`FlashcardDrillView` is a Sideline-style swipe deck: tap flips the card, and
only a flipped card can be swiped. Swipe right for "got it" (leaves the deck);
swipe left for "again" (returns at the back). Pre-flip drags rubber-band. Undo lives in the
toolbar. Cards with a `CardChoice` show two answer buttons on the front
(choose, graded flip, held result, explicit Next). Their answer determines the
grade and whether the card returns; swipe direction never overrides it. Gesture
gotcha: the deck uses ONE
`DragGesture(minimumDistance: 0)` that treats a <10pt release as the flip
tap. A separate `.onTapGesture` loses arbitration against the drag and
silently never fires. Don't "simplify" it back to `onTapGesture`.

**One throw at a time (1.4.2):** every grade of the top card (Next, a swipe,
the VoiceOver actions) goes through `DeckFlingGate.begin()`; a second Next
during the 0.34s throw used to commit twice and grade the next card unseen.
The quiz, hand match and Charleston drills guard Next the same way with
`DrillNext.allowed(answered:finished:)`: two taps before the button hides
skipped a question, or finished the drill with the last one unanswered.
Reduce Motion fades the card where it is instead of throwing it, cuts the
deck's springs and skips the first-flip swipe hint. At accessibility sizes
the front scrolls its question (`ViewThatFits`: the designed stack first)
with the choice buttons pinned below, as the back does.

**Flip gotcha (fixed 2026-07-12):** the whole card must rotate as ONE unit.
`FlipRotation` is `Animatable` and swaps faces exactly at 90° while the card is
edge-on. Never rotate the text faces inside a static card background; that's
what made text detach from the card. Both faces use the same `MahjCardFace`
mahjong-card chrome (ivory surface, double frame, eyebrow, watermark).
