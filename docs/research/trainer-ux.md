# Trainer/Drill App UX Research — for Mahj Trainer

Research on how top flashcard/drill/trainer apps design their core loop, sessions,
progression, and completion screens, to inform Mahj Trainer's swipeable card deck
(Tinder-style fling + tap-to-flip) for American Mah Jongg drills.

## Card interaction patterns

**AnkiMobile**
- Core loop: show front → tap/swipe to reveal back → rate recall on a 4-button scale (Again / Hard / Good / Easy — colored red/orange/green/blue). The rating, not a binary right/wrong, drives the next-interval scheduling (SM-2 / FSRS algorithms).
- Swipe is a *secondary* input layered onto tap: users can configure swipe-up/down/left/right to fire the same actions as the four buttons, but taps on dedicated buttons remain the primary, discoverable path. Anki deliberately restricts where a horizontal vs. vertical swipe can *start* (edges only, in recent versions) specifically to avoid conflicting with scrolling/selecting text on content-heavy cards.
- Takeaway: when a card can contain long text, swipe-to-answer and scroll/select-to-read gestures compete; Anki's fix (edge-triggered swipes) is a pattern worth reusing if any Mahj Trainer card ever has long text on the back.

**Brainscape**
- Same shape as Anki but self-graded on a 1–5 "confidence" scale instead of 4 recall buckets. Confidence-Based Repetition (CBR) resurfaces low-confidence cards almost immediately (even within the same short session) and defers high-confidence cards for a long time — this is what makes the review feel personalized rather than mechanical.
- Key UX idea: the grading scale itself is the core interaction, not an afterthought. Users report the app "gets out of the way" because there's no separate correct/incorrect judgment step, just a felt-sense confidence tap.

**Quizlet**
- Two named flashcard modes: "Flip" (tap card to flip, arrow/swipe to advance) and "Flow"/swipe mode, which is closest to what Mahj Trainer wants: swipe **up** to reveal the answer, swipe again to advance; in the swipe-sort variant, swipe **right** = "know it", swipe **left** = "still learning" (mirrors Tinder's like/pass grammar almost exactly, which is why it feels instantly familiar).
- "Learn" mode (their spaced-repetition mode) escalates question *type* as confidence increases: flashcard recall → multiple choice → written answer, with harder formats appearing more often for mastered material. This is a useful precedent for Mahj Trainer's later drill types (quiz, hand-match) building on top of flashcard mastery.
- Notable: Quizlet overlays a single persistent mode-switcher header across all study modes, so users never feel "trapped" in one drill type — worth considering as a lightweight way to jump between flashcard/quiz/Charleston without leaving the session.

## Session design

**Anki/Brainscape** — session length is user-controlled (default daily new-card + review queue, commonly 10-20 min, but power users grind much longer); this makes the loop powerful for existing habits but genuinely tedious for newcomers because there's no designed "stopping point" — the deck just keeps queuing reviews until you quit, which can feel like an unbounded chore. This is the single biggest thing Duolingo fixed and is a cautionary tale for Mahj Trainer: an SRS-style endless queue is wrong for a casual/onboarding audience.

**Duolingo**
- Atomic unit is a *lesson*, deliberately scoped to fit under 5 minutes (many closer to 2-3 minutes) with essentially zero setup friction — tap and you're in a card within a second.
- Difficulty and content are chunked into a visual "path"/map metaphor (a winding trail of nodes) so progress is spatial and legible at a glance, not just a number. Completed nodes glow/fill in; the next node is visually "next," which does a lot of the motivational work map-free apps have to do with copy instead.
- Celebration moments are frequent and small: XP awarded per lesson, occasional "Treasure Chest" bonus reward screens (measured 15% lift in lesson completion), level-ups, and streak-day confirmation animations. The key pattern is *small, frequent* dopamine hits distributed throughout rather than one big reward at the very end.
- Loss-aversion is doing more work than reward-seeking: the streak system (with forgiving "streak freeze"/repair mechanics so one missed day doesn't erase months of history) is repeatedly cited as the top retention lever, reportedly correlating with a ~60% lift in engagement and long-term users being ~3.6x more likely to stay engaged past a 7-day streak.
- Monetization moments are deliberately placed at natural breaks, not mid-task: paywall/upsell interstitials appear *after* a lesson completes (never before or mid-lesson), and the upsell copy is contextual to what triggered it (e.g., ran out of hearts, wanted to skip an ad, hit a streak-freeze moment). Reported cadence is aggressive by volume (up to ~7 upsell touches in a single first-time session) but never during the actual learning interaction itself — the sanctity of the lesson flow is protected even while the surrounding chrome is heavily monetized.

Sources:
- [AnkiMobile Flashcards - App Store](https://apps.apple.com/us/app/ankimobile-flashcards/id373493387)
- [Study Tools - AnkiMobile Manual](https://docs.ankimobile.net/study-tools.html)
- [How Does Brainscape's Spaced Repetition Algorithm Work? (CBR)](https://brainscape.zendesk.com/hc/en-us/articles/13103043051149-How-Does-Brainscape-s-Spaced-Repetition-Algorithm-Work)
- [What Is Confidence-Based Repetition - Brainscape Academy](https://www.brainscape.com/academy/confidence-based-repetition-definition/)
- [Introducing our new Flashcards mode - Quizlet](https://quizlet.com/blog/introducing-our-new-flip-flashcards-mode)
- [Quizlet Study Modes](https://quizlet.com/gb/features/study-modes)
- [UX and Gamification in Duolingo - UX Planet](https://uxplanet.org/ux-and-gamification-in-duolingo-40d55ee09359)
- [Duolingo — Streak System Detailed Breakdown & Design](https://medium.com/@salamprem49/duolingo-streak-system-detailed-breakdown-design-flow-886f591c953f)
- [Duolingo's Gamification Secrets - Orizon](https://www.orizon.co/blog/duolingos-gamification-secrets)
- [How Duolingo pushes users from freemium to premium](https://adplist.substack.com/p/how-duolingo-pushes-users-from-freemium)
- [Duolingo's Pushy Paywall Play: Smart or Risky? - Motley Fool](https://www.fool.com/investing/2025/08/08/duolingos-pushy-paywall-play-smart-or-risky/)

## Progression & streaks

**Chess.com (puzzle trainer)**
- Uses a single continuously-updating Elo-style "Puzzle Rating" instead of fixed levels: every puzzle is itself rated, and solving/missing it moves your rating toward or away from the puzzle's rating (Glicko-like — beating a much-harder puzzle gains a lot, beating an easy one gains almost nothing). This keeps difficulty self-calibrating per user without any manual level-select.
- Offers three parallel modes on top of the same content: untimed rated puzzles (the "trainer" proper), **Puzzle Rush** (3 or 5-minute timed sprint, score = puzzles solved before 3 mistakes/time runs out — a pure arcade/high-score mode), and **custom practice** (pick your own theme/rating band, unrated, zero-pressure "just drill this weakness" mode). Three different framings of the *same* underlying question bank is a strong pattern: one mode for calibrated growth, one for a dopamine sprint, one for deliberate practice.
- Post-puzzle feedback panel breaks performance down by *tactical theme* (fork, pin, skewer, etc.) as a percentage-correct bar per theme, so users see not just "you're improving" but "you're weak specifically at X" — directly analogous to Mahj Trainer breaking feedback down by hand category or NMJL section.
- Design research citation: Chess.com's own stated rationale for defaulting to "Standard" (easier) puzzle difficulty is that a *higher success rate* is better for learning/retention than being constantly stumped — success rate itself is treated as a tunable UX parameter, not just a byproduct.

**Music/rhythm/typing trainers (ABRSM Music Theory Trainer, Complete Rhythm Trainer, Mavis Beacon-style typing)**
- Nearly universal structure: content is pre-sequenced into **levels → chapters → drills** (e.g., Complete Rhythm Trainer: 4 levels / 30 chapters / 252 drills across 5 drill *types*), so the app — not the user — decides the next unit, removing choice-paralysis. This maps closely to Mahj Trainer's existing Room → Drill structure and validates keeping rooms linearly gated rather than an open menu.
- Multiple named modes per skill area (e.g., "Easy Mode" progressive chapters vs. "Arcade Mode" for a small curated set of drills played for score) mirror the chess.com pattern: one mode for structured mastery, one for replay-for-fun.
- These apps lean on visible level/chapter completion (checkmarks, stars, percent-complete per chapter) as the primary progress affordance — simpler than streaks, appropriate for a skill that's practiced in bursts rather than daily (relevant to Mah Jongg, which people often prep for occasionally, e.g. before game night, not necessarily daily).

**Duolingo streak mechanics (deeper dive)**
- The streak-freeze/repair mechanic is the load-bearing piece: without forgiveness, a single missed day (illness, travel) permanently zeroes a habit users have invested months in, which reads as punishing rather than motivating. Duolingo explicitly treats forgiveness as necessary infrastructure, not a nice-to-have, for the streak mechanic to be net-positive rather than anxiety-inducing.
- Milestone escalation: ordinary streak days get a minor tick-up animation; landmark days (7, 30, 100, 365) get a full-screen bespoke celebration. Reserve the biggest celebration animations for meaningful thresholds, not every single day — constant maximum celebration cheapens the signal.
- XP/rewards are granted *before* the user has even left the lesson-complete screen, tightly coupling the reward to the behavior that earned it (matches operant-conditioning best practice: minimize latency between action and reward).

## Completion screens & prompts

Common shape across Duolingo, Chess.com Puzzle Rush, and streak/habit apps for a "session just ended" screen:
1. **Immediate, unambiguous result** at the top (score, cards reviewed, accuracy %, streak count) — no scrolling needed to see "how did I do."
2. **One live/animated element** (streak flame ticking up, XP counter counting up, a treasure chest opening) — motion communicates "this just happened to you" rather than a static summary.
3. **Comparison/context**, not just a raw number: chess.com shows rating delta and per-theme accuracy; Duolingo shows leaderboard movement and quest progress — the number alone is less motivating than "you're improving relative to X."
4. **Encouraging, specific copy** over generic praise (cited to lift completion ~25% vs. generic messaging) — e.g., naming the category just drilled rather than "Great job!"
5. **A single clear next action** (Continue / Practice again / Next drill) as the dominant button; secondary actions (share, view full stats) are visually subordinate.
6. **Monetization/review prompts live on this screen or the one after it, never inside the drill itself.** Apple's own guidance (and Duolingo's practice) is to ask for App Store reviews only after a clear moment of accomplishment, never on first launch, and to space repeated asks by weeks — Apple caps an app at 3 native rating prompts per 365 days regardless of how often you request one. This validates Mahj Trainer's existing "enjoyment gate after 3rd completed drill" placement in `DrillCompleteView` as structurally correct (post-accomplishment, not first-launch).
- Paywall upsells, when present, should reuse the same post-completion beat and be *contextual* to what the user just did (Duolingo swaps paywall copy per entry point) rather than a single generic "Go Pro" screen shown identically everywhere.

## Swipe-deck mechanics checklist

Distilled from Tinder-style implementation write-ups (react-tinder-card, SwiftUI clones, `gajus/swing`) and Anki/Quizlet's handling of swipe-vs-tap conflicts:

- **Drag tracks the finger 1:1** during the gesture (card center follows touch point exactly) so it reads as physically grabbed, not remote-controlled.
- **Rotation is coupled to horizontal translation**, not a separate animation — a common formula is `angle = translation.x / K` (e.g., K≈180pt maps a full-width drag to roughly a 1-radian/~57° tilt). This single coupling is what makes the gesture feel physical for free.
- **Two independent thresholds** decide commit-vs-snap-back: a *position* threshold (dragged past X% of screen width) OR a *velocity* threshold (flicked fast even if short distance) — using both, not just position, is what makes a quick flick feel responsive even when the user doesn't drag far.
- **Snap-back must reset rotation, not just position** — resetting only the center and leaving residual rotation is a common bug that makes failed swipes look broken/glitchy.
- **Directional intent overlay** (a "peek" label like LIKE/NOPE, or in Mahj Trainer's case something like "GOT IT" / "REVIEW AGAIN") fades in proportional to drag distance, confirming to the user mid-gesture what letting go will do — critical for any swipe whose two directions mean different things (unlike Tinder, this app's swipe likely maps to a grading action, so the intent overlay is not optional polish, it's how the user knows which way is which).
- **Peek of the next card**: show at least the top edge/scaled-down silhouette of the next 1-2 cards behind the current one; scale/opacity step per depth communicates "there's more" and prevents the deck from feeling like a single disconnected card each time. Standard is 2-3 cards visible in the stack with each successive card slightly smaller/behind.
- **Undo is expected and important**: a persistent (or shake-to-undo / dedicated button) way to bring back the last swiped card matters a lot for a *grading* swipe deck specifically — unlike Tinder where a wrong swipe is low-stakes, a mis-swiped "I knew that" vs "I didn't know that" directly corrupts the user's own progress data, so undo is not just a convenience here, it protects the integrity of the drill.
- **Haptics**: use system-semantic haptics only, and sparingly — a light selection tick on a threshold crossing (about to commit), a slightly stronger impact on release/commit, nothing on drag itself. Apple HIG guidance: haptics should be "felt, not noticed"; decorative/constant haptics are the first thing power users disable, so reserve them for the two or three moments (correct/incorrect commit, milestone) where a physical confirmation genuinely helps.
- **Gesture-conflict avoidance (tap-to-flip + swipe-to-advance on the same card)**: the two safest patterns from real apps are (a) tap flips in place, swipe is a *separate* gesture that only registers on a horizontal drag past a small dead-zone (so a tap never gets misread as a micro-swipe), or (b) swipe is only enabled once the card is already flipped to its answer side (Quizlet's swipe-up-to-reveal-then-swipe-to-advance is one variant of this). Anki's fix for content-heavy cards — restricting swipe *start point* to screen edges so mid-card interactions stay reserved for scroll/tap — is the fallback if a Mahj Trainer card ever needs scrollable content on the back.
- **Common mistakes to avoid**: swiping left-to-right for card actions when the OS already uses that gesture for a system-level action (e.g., iOS back-navigation edge-swipe) creates muscle-memory conflicts; making the commit threshold too small causes accidental swipes during an intended tap; not decoupling rotation reset from position reset on snap-back; omitting the next-card peek so the deck looks empty/final after each swipe; skipping undo on a deck where swipe direction carries scoring meaning.

## Concrete recommendations for Mahj Trainer's drill loop

1. **Session shape**: cap a flashcard drill session at a small, fixed card count (10-15 cards) framed as one "round," not an open-ended queue — closer to Duolingo's bounded lesson than Anki's unbounded review queue, since Mahj Trainer's audience is casual beginners, not SRS power users. Offer "Practice again" rather than auto-continuing into more cards.
2. **Card interaction**: tap anywhere on the card = flip to reveal back (matches Quizlet Flip / Anki default). Once flipped, swipe right = "Got it" / swipe left = "Review again" (Quizlet's swipe-sort grammar, immediately legible via Tinder muscle memory). Do not allow swipe-to-grade *before* the flip — the user must see the answer before grading themselves, otherwise the swipe is meaningless and error-prone. Show a small "GOT IT" / "REVIEW AGAIN" label that fades in with drag distance so direction-meaning is never ambiguous.
3. **Give a real undo**: last-swiped card should be recoverable via a visible undo button or shake gesture for at least the current session — a mis-swipe on a grading deck corrupts the user's own mastery data, unlike a low-stakes Tinder mis-swipe.
4. **Peek + physics**: show the next 1-2 cards' top edges behind the current card, scaled down; couple rotation to horizontal drag (angle ≈ translation.x / 180); use both a position and a velocity threshold to commit a swipe; snap back with rotation reset if under threshold.
5. **Haptics**: light selection tick as the drag crosses the commit threshold, one impact haptic on release/commit. Nothing else. Respect Reduce Motion / haptics-off settings.
6. **Progress feedback should be per-category, not just aggregate**: reuse Chess.com's "percent correct per tactical theme" idea and Mahj Trainer's existing `HandCategory` structure — show mastery per NMJL section (e.g., "Consecutive Run: 8/10", "Winds & Dragons: 4/6") on the room/progress screen, not just a single overall streak number. This also gives natural re-engagement copy ("You're weakest on 13579 — drill it?").
7. **Streak, with forgiveness built in from day one**: since this is a casual, occasional-use app (prep-before-game-night, not daily habit), consider a lighter-weight "sessions this week" or "cards mastered" counter alongside/instead of a punishing daily streak, or ship the streak with a freeze/grace mechanic from the start rather than retrofitting it — an unforgiving streak in a non-daily-use app will just make users feel bad and churn rather than motivate them.
8. **Completion screen** after each drill (already have `DrillCompleteView`): keep the existing shape (result at top, one animated element, encouraging copy naming the category just drilled, one dominant "Continue"/"Next" button) and continue placing the review-funnel enjoyment gate here post-3rd-drill — this matches both Apple's own guidance (ask after accomplishment, not on launch) and Duolingo's placement (post-lesson, never mid-lesson). If/when a Pro upsell is added to a completion screen, make its copy contextual to the room/drill just completed rather than a single generic paywall.
9. **Multiple modes over one queue**: consider chess.com/rhythm-trainer's pattern of 2-3 framings on the same content — a structured "Learn" path through a room's drills (gated, sequential, mirrors current Room→Drill design) plus an optional unlocked "quick practice" / timed sprint mode once a room is completed, for users who want a fast confidence-check rather than fresh instruction.
10. **Escalate format with mastery, not just content**: borrow Quizlet Learn's idea of increasing question difficulty format (flashcard → multiple choice → active recall) as a category is mastered — Mahj Trainer already has flashcards, quizzes, and hand-match as separate drill types; sequencing them by demonstrated mastery within a category (rather than only by room) would reuse existing content types as a built-in difficulty ramp.

Sources (additional, beyond those cited above):
- [How do Puzzles work on Chess.com?](https://support.chess.com/en/articles/8608686-how-do-puzzles-work-on-chess-com)
- [Announcing New Puzzles Rating System - Chess.com](https://www.chess.com/news/view/announcing-new-puzzles-rating-system)
- [How do Puzzle ratings work? - Chess.com Help Center](https://support.chess.com/en/articles/8602396-how-do-puzzle-ratings-work)
- [Complete Rhythm Trainer - App Store](https://apps.apple.com/us/app/complete-rhythm-trainer/id1550799056)
- [react-tinder-card - npm](https://www.npmjs.com/package/react-tinder-card)
- [Building a Tinder-esque Card Interface - Phill Farrugia](https://medium.com/@phillfarrugia/building-a-tinder-esque-card-interface-5afa63c6d3db)
- [Creating Tinder-Like Swipeable Cards in SwiftUI](https://medium.com/@jaredcassoutt/creating-tinder-like-swipeable-cards-in-swiftui-193fab1427b8)
- [GitHub - gajus/swing](https://github.com/gajus/swing)
- [Playing haptics - Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- [Haptic Feedback UI Guidelines for iOS - VP0 Journal](https://vp0.com/blogs/haptic-feedback-ui-design-guidelines-ios)
- [Duolingo Streaks: How the Mechanic Drives 2x Daily Retention](https://duolingo.deconstructoroffun.com/mechanics/streaks)
- [Designing A Streak System: The UX And Psychology Of Streaks - Smashing Magazine](https://www.smashingmagazine.com/2026/02/designing-streak-system-ux-psychology/)
- [Requesting App Store reviews - Apple Developer Documentation](https://developer.apple.com/documentation/storekit/requesting-app-store-reviews)
- [What's the Right Time to Ask Users to Rate My App?](https://weareaffective.com/learning-centre/whats-the-right-time-to-ask-users-to-rate-my-app)
- [Prompting for app reviews and ratings on iOS and Android - Appbot](https://appbot.co/blog/prompting-for-app-reviews-ratings-ios-android-ultimate-guide/)

