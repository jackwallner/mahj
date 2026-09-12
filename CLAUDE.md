# Mahj — Project Guide

Mahj Trainer: American Mah Jongg drill app for new players (flashcards, quizzes,
hand-matching, Charleston practice — no gameplay). XcodeGen project/scheme:
`MahjTrainer`, sim lease owner `mahj`. Bundle ID `com.jackwallner.mahj`.

**Product direction:** the swipe deck is a signature mechanic but this is NOT
"a flashcard app" — each room is free to use whatever training interaction fits
its skill (self-test choices, scenario picks, future sims). Propose
room-appropriate mechanics when adding content.

**Content is legally constrained:** the NMJL yearly card is copyrighted. Every
example hand is an ORIGINAL teaching hand for the category system — never copy
hands from the actual card. Keep the "not affiliated with NMJL" disclaimer
(Home footer, Settings, App Store description). `ContentValidityTests` enforces
content rules across ALL drills in `DrillLibrary` (13-tile deals/racks, 3-tile
passes, no passing jokers, max 4 copies of a tile, no em dashes, unique ids,
free/Mahj+ split).

**App Store reviews:** the fleet funnel. `ReviewPromptTracker` (launches,
positive moments, cooldowns, terminal outcome) gates `ReviewPromptSheet`:
enjoying it? → yes routes to the App Store write-review page, no routes to a
feedback mail draft (`jackwallner+m@gmail.com`). Unhappy players never see a
rating ask. Fires after the 3rd finished drill (`DrillCompleteView`, 1.4s after
the celebration lands); Settings' Rate / Send Feedback open the same sheet at
their step. App Store ID `6790052126`.

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

- `Shared/Models` — `Tile` (suits/winds/dragons/flower/joker, `.c(n)/.b(n)/.d(n)`
  authoring shorthand), `HandCategory` (the 9 stable NMJL card sections), drill
  types (`Flashcard` + optional `CardChoice` self-test, `QuizQuestion`,
  `HandMatchQuestion`, `CharlestonScenario`, `Drill`, `Room`).
- `Shared/Content` — all drill content as Swift constants; `DrillLibrary.rooms`
  defines the 5 rooms (ids: `tile-room`, `card-room`, `charleston-room`,
  `table-room`, `pro-tables`). `SessionBuilder.dailyMix` builds the Get Started
  mixed session (missed items first, then unseen; excludes Pro for free users).
  `HowToPlayContent` holds the original six-page beginner primer.
- `Shared/Services` — `ProgressStore` (UserDefaults streaks/completions/review
  gate + item-level `seenItems`/`missedItems`, `resetAll()` keeps onboarding),
  `AppSettings` (theme Light-default/Dark/System, haptics, sound, daily
  reminder via UNUserNotificationCenter), `SubscriptionService` (RC; simulator
  early-return preserved — never configure the prod `appl_` key on sim).

## Rules that hold everywhere
Condensed from the deep notes below; the reasoning and the bugs behind each one live there.
- Generated racks are ORIGINAL structures, never card hands, and `RackGenerator` throws away any rack that reads as more than one section.
- `Room.isLocked(_:isMember:)` is the single source of truth for locking.
- `OnboardingView.trialDisclosure` must always name the same plan the CTA buys (3.1.2). A player backing out of Apple's sheet is `PurchaseOutcome.cancelled`, not an error: never answer it with another paywall.
- `QuickItem.choiceNotes` rides the same permutation as `choices` in `SessionBuilder.prepared`.
- `RootView` branches onboarding vs `HomeView` on `progress.hasOnboarded`, never a fullScreenCover. The primer and the tour always keep an escape hatch straight to Home.
- No generated illustration: tiles are drawn from real data by `TileView`/`TileRackView`.

## Deep notes (load on demand)
These files load automatically when you read a file matching their `paths:`. Agents that do not auto-load rules (AGENTS.md readers) should open the file for the area they are touching. Record new area-specific learnings in the matching file, not here.

| File | Covers | Read when |
|---|---|---|
| `.claude/rules/generated-practice.md` | Generated practice (1.1): the generators, Fix My Mistakes, Timed Challenge, `PracticeRecordStore` | The generators, practice runs, stats |
| `.claude/rules/rituals-and-hand-play.md` | Game-night rhythm (1.2), Play a Hand (1.3), Reference (1.3) | Mahj Minute, game night prep, `HandPlayEngine`, the reference |
| `.claude/rules/mastery-coaching-whats-new.md` | Mastery, coaching the miss, the What's New sheet | Room rings, miss notes, `WhatsNew` |
| `.claude/rules/membership-and-trial.md` | Free-beginner + extra-sets model, monthly on onboarding vs yearly on the paywall | Locking, Plus content, onboarding trial, paywall defaults |
| `.claude/rules/home-and-onboarding-flow.md` | Views: the lobby, onboarding branch, primer and tour | `RootView`, Home, rooms, onboarding |
| `.claude/rules/design-and-ipad.md` | Theme and haptics, iPad layout, no illustration | `Theme`, components, drill layouts |
| `.claude/rules/screenshots.md` | Screenshots: captured, not hand-shot | Capture scripts, the `Screenshots` scheme |

## Flashcard deck (signature interaction)

See `MahjTrainer/Views/Drills/CLAUDE.md` for the swipe-deck gesture/flip
mechanics and gotchas.

## Design research

`docs/research/mahjong-market.md` (competitor apps, pricing, aesthetic
white-space) and `docs/research/trainer-ux.md` (flashcard/session UX patterns,
swipe-deck checklist) — consult before design or monetization changes.

---
Shared iOS conventions (build, simulator, release/TestFlight, ASC key, signing,
review funnel, pricing scripts, gotchas): always-loaded global CLAUDE.md + the
`ios-dev` skill.
