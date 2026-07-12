# Mahj — Project Guide

Mahj Trainer: American Mah Jongg drill app for new players (flashcards, quizzes,
hand-matching, Charleston practice — no gameplay). XcodeGen project/scheme:
`MahjTrainer`, simulator device `agent-mahj`. Bundle ID `com.jackwallner.mahj`.

**Content is legally constrained:** the NMJL yearly card is copyrighted. Every
example hand is an ORIGINAL teaching hand for the category system — never copy
hands from the actual card. Keep the "not affiliated with NMJL" disclaimer
(Home footer, Settings, App Store description). `ContentValidityTests` enforces
content rules (13-tile deals, 3-tile passes, no passing jokers, max 4 copies of
a tile, no em dashes).

**App Store reviews:** enjoyment gate fires once after the 3rd completed drill
(`DrillCompleteView` → `ProgressStore.shouldShowEnjoymentGate()`). Settings has
Rate + Send Feedback (`jackwallner@gmail.com`).

## Products

`com.jackwallner.mahj.monthly` $1.99 · `.yearly` $9.99 · `.lifetime` $29.99
(StatScout-style cheapo tier, chosen 2026-07-12). Both subscriptions carry a
1-week free trial — keep monthly trials (fleet rule). RevenueCat entitlement
`pro`; public SDK key in `SubscriptionService.swift`, RC secret API key in
`~/.mahj_credentials` (never commit). Soft paywall: Tile Room free, other three
rooms Pro.

## Architecture

- `Shared/Models` — `Tile` (suits/winds/dragons/flower/joker, `.c(n)/.b(n)/.d(n)`
  authoring shorthand), `HandCategory` (the 9 stable NMJL card sections), drill
  types (`Flashcard`, `QuizQuestion`, `HandMatchQuestion`, `CharlestonScenario`,
  `Drill`, `Room`).
- `Shared/Content` — all drill content as Swift constants; `DrillLibrary.rooms`
  defines the 4 rooms. Room ids: `tile-room`, `card-room`, `charleston-room`,
  `table-room`.
- `Shared/Services` — `ProgressStore` (UserDefaults streaks/completions/review
  gate), `SubscriptionService` (RC; simulator early-return preserved — never
  configure the prod `appl_` key on sim).
- `MahjTrainer/Views` — `RootView` branches onboarding vs `HomeView` on the
  `progress.hasOnboarded` defaults key (branch, NOT a fullScreenCover — the
  cover flashed Home behind onboarding on first launch).
- `MahjTrainer/Utilities/Theme.swift` — the warm-modern design system: cream
  surfaces, jade primary, coral energy, per-room accents (`Room.accent`), serif
  display type (`Theme.display`), `themedCard()`/`primaryCTA()` styles,
  `Haptics`. All colors are light/dark adaptive; launch screen color is the
  `LaunchBackground` asset (keep in sync with `Theme.background`).

## Flashcard deck (the signature interaction)

`FlashcardDrillView` is a Sideline-style swipe deck: tap flips the card, and
only a flipped card can be swiped — right = "got it" (leaves the deck), left =
"again" (returns at the back). Pre-flip drags rubber-band. Undo lives in the
toolbar. Gesture gotcha: the deck uses ONE `DragGesture(minimumDistance: 0)`
that treats a <10pt release as the flip tap — a separate `.onTapGesture`
loses arbitration against the drag and silently never fires. Don't "simplify"
it back to `onTapGesture`.

## Design research

`docs/research/mahjong-market.md` (competitor apps, pricing, aesthetic
white-space) and `docs/research/trainer-ux.md` (flashcard/session UX patterns,
swipe-deck checklist) — consult before design or monetization changes.

---
Shared iOS conventions (build, simulator, release/TestFlight, ASC key, signing,
review funnel, pricing scripts, gotchas): always-loaded global CLAUDE.md + the
`ios-dev` skill.
