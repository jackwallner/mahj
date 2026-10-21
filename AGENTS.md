# Mahj Project Guide

Mahj Trainer: American Mah Jongg drill app for new players (flashcards, quizzes,
hand-matching, Charleston practice, no gameplay). XcodeGen project/scheme:
`MahjTrainer`, sim lease owner `mahj`. Bundle ID `com.jackwallner.mahj`.

**Product direction:** the swipe deck is a signature mechanic but this is NOT
"a flashcard app." Each room is free to use whatever training interaction fits
its skill (self-test choices, scenario picks, future sims). Propose
room-appropriate mechanics when adding content.

**Content is legally constrained:** the NMJL yearly card is copyrighted. Every
example hand is an ORIGINAL teaching hand for the category system. Never copy
hands from the actual card. Keep the "not affiliated with NMJL" disclaimer
(Home footer, Settings, App Store description). `ContentValidityTests` enforces
content rules across ALL drills in `DrillLibrary` (13-tile deals/racks, 3-tile
passes, no passing jokers, max 4 copies of a tile, no em dashes, unique ids,
free/Mahj+ split).

**App Store reviews and feedback (1.4):** the fleet's no-gate policy (ios-dev
skill, "App Store ratings and feedback"). A finished drill, Mahj Minute or a
challenge scoring half or better calls Apple's `requestReview()` directly,
3s later, via `.requestsReview(after:)` (`Views/Components/ReviewRequest.swift`),
gated only by `ReviewPromptTracker`: second launch on, 30-day cooldown, and
opening the write-review page ends the asks. NO "Enjoying it?" question: that
gate got IM Tri Tracker rejected under 5.6.1 (2026-10-01). Settings has two
separate rows: Rate opens the write-review page, Send Feedback opens
`ReviewPromptSheet(.feedback)`, which posts to `FeedbackService` (Supabase
insert-only table, offline queue). Feedback never stops rating asks. The same
sheet hosts the one churn question. No per-question report link: Jack cut it
before 1.4.1 shipped because a flag under every answer casts doubt on the
right one; question problems come in through Send Feedback. App Store ID `6790052126`. Details in
`.claude/rules/feedback-and-retention.md`.

## Products & the Mahj+ model

`com.jackwallner.mahj.monthly` · `.yearly` · `.lifetime`. Prices are NOT
restated here: `PaywallPricing` reads them live from StoreKit via RevenueCat,
and App Store Connect is the only source of truth. Copies of the numbers in
this file, the `.storekit` fixture, and `docs/index.html` have all drifted a
tier apart before; check ASC before quoting a price anywhere. Both
subscriptions carry a 1-week free trial; keep monthly trials (fleet rule).
RevenueCat entitlement `pro`; public SDK key in `SubscriptionService.swift`,
RC secret API key in `~/.mahj_credentials` (never commit).

Membership is branded **Mahj+** in-app (`Membership.name`; the RevenueCat
entitlement id stays `pro`). "Pro" as a player-facing word is retired: it reads
as a skill tier, and the free rooms are explicitly the beginner ones.

**Paywall compliance (App Review 3.1.2):** `PaywallView` must always show, on
the purchase screen itself: membership name, per-plan price, billing period, an
explicit auto-renew + cancellation sentence (`PaywallPricing.terms`), Restore,
Terms of Use, and Privacy Policy. Don't trim any of them for layout.

## Architecture

- `Shared/Models`: `Tile` (suits/winds/dragons/flower/joker, `.c(n)/.b(n)/.d(n)`
  authoring shorthand), `HandCategory` (the 9 stable NMJL card sections), drill
  types (`Flashcard` + optional `CardChoice` self-test, `QuizQuestion`,
  `HandMatchQuestion`, `CharlestonScenario`, `Drill`, `Room`).
- `Shared/Content`: all drill content as Swift constants; `DrillLibrary.rooms`
  defines the 5 rooms (ids: `tile-room`, `card-room`, `charleston-room`,
  `table-room`, `pro-tables`). `SessionBuilder.quickSession` builds the Get Started
  mixed session (missed items first, then unseen; excludes Pro for free users).
  `HowToPlayContent` holds the original six-page beginner primer.
- `Shared/Services`: `ProgressStore` (UserDefaults streaks/completions/review
  gate + item-level `seenItems`/`missedItems`, `resetAll()` keeps onboarding),
  `AppSettings` (theme Light-default/Dark/System, haptics, sound, daily
  reminder via UNUserNotificationCenter), `SubscriptionService` (RC; simulator
  early-return preserved. Never configure the prod `appl_` key on sim).

## Rules that hold everywhere
Condensed from the deep notes below; the reasoning and the bugs behind each one live there.
- Generated racks are ORIGINAL structures, never card hands, and `RackGenerator` throws away any rack that reads as more than one section.
- `Room.isLocked(_:isMember:)` is the single source of truth for locking.
- The trial flow (onboarding trial page, paywall, purchase to tour) is frozen at 1.3.2: it converts. The one approved change is trial-page benefit rows 2 and 4 (Jack, 2026-10-19, since the Mahj Minute went free). Remote variants come only through RevenueCat offering metadata (`RemoteConfig`). Any other change needs Jack's go-ahead.
- `OnboardingView.trialDisclosure` must always name the same plan the CTA buys (3.1.2). A player backing out of Apple's sheet is `PurchaseOutcome.cancelled`, not an error: never answer it with another paywall.
- `QuickItem.choiceNotes` rides the same permutation as `choices` in `SessionBuilder.prepared`.
- `RootView` branches onboarding vs `HomeView` on `progress.hasOnboarded`, never a fullScreenCover. The primer and the tour always keep an escape hatch straight to Home.
- No generated illustration: tiles are drawn from real data by `TileView`/`TileRackView`.
- Content teaches how to read hands, never what the current card contains. Players check every claim against their card, so a card-dependent statement ("usually", "exactly", "most likely building") must hold on the current card, checked privately and never copied in. Exposures cannot grow: once its owner discards, an exposed pung never becomes a kong.

## Deep notes (load on demand)
These files load automatically when you read a file matching their `paths:`. Agents that do not auto-load rules (Codex, Cursor) should open the file for the area they are touching. Record new area-specific learnings in the matching file, not here.

| File | Covers | Read when |
|---|---|---|
| `.claude/rules/generated-practice.md` | Generated practice (1.1): the generators, Fix My Mistakes, Timed Challenge, `PracticeRecordStore` | The generators, practice runs, stats |
| `.claude/rules/rituals-and-hand-play.md` | Game-night rhythm (1.2), Play a Hand (1.3), Reference (1.3) | Mahj Minute, game night prep, `HandPlayEngine`, the reference |
| `.claude/rules/mastery-coaching-whats-new.md` | Mastery, coaching the miss, the What's New sheet | Room rings, miss notes, `WhatsNew` |
| `.claude/rules/membership-and-trial.md` | Free-beginner + extra-sets model, monthly on onboarding vs yearly on the paywall | Locking, Plus content, onboarding trial, paywall defaults |
| `.claude/rules/home-and-onboarding-flow.md` | Views: the lobby, onboarding branch, primer and tour | `RootView`, Home, rooms, onboarding |
| `.claude/rules/design-and-ipad.md` | Theme and haptics, iPad layout, no illustration | `Theme`, components, drill layouts |
| `.claude/rules/screenshots.md` | Screenshots: captured, not hand-shot | Capture scripts, the `Screenshots` scheme |
| `.claude/rules/feedback-and-retention.md` | Feedback sink, churn question, weekly gain ledger, personalised reminders (1.4) | `FeedbackService`, `ReviewPromptSheet`, `MasteryLedger`, churn prompts, reminder copy |
| `.claude/rules/monthly-challenge.md` | The free monthly challenge, its rotation and the monthly event + nomination | `MonthlyChallengeContent`, `mahj://challenge`, in-app events |
| `.claude/rules/meta-ads.md` | Meta SDK + ATT (inert until a Meta app exists), the 15-minute StartTrial relay | `MetaAds`, `TrialCTA`, `supabase/`, ATT timing |
| `.claude/rules/android.md` | The Android port: exported content, RNG parity, Play identity, deliberate differences | Anything under `android/` or the content export |

## Flashcard deck (signature interaction)

See `MahjTrainer/Views/Drills/AGENTS.md` for the swipe-deck gesture/flip
mechanics and gotchas.

## Design research

`docs/research/mahjong-market.md` (competitor apps, pricing, aesthetic
white-space) and `docs/research/trainer-ux.md` (flashcard/session UX patterns,
swipe-deck checklist). Consult before design or monetization changes.

---
Shared iOS conventions (build, simulator, release/TestFlight, ASC key, signing,
review funnel, pricing scripts, gotchas): the global agent rules + the
`ios-dev` skill.
