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

**Generated practice (1.1, 2026-07-30):** the authored sets are finite, so a
motivated player exhausted Mahj+ in two sittings and then paid for nothing new.
1.1 answers that with three Mahj+ modes on Home under TRAINING, all run by
`PracticeRunView` (Endless / Timed / Review), all built on the existing
`QuickItem` shape:
- **Endless Practice** (`RackGenerator` + `EndlessPractice`) deals racks
  procedurally, forever. `RackGenerator` only generates the five sections whose
  read is UNAMBIGUOUS (evens/odds/369/consecutive/winds-dragons); Like Numbers
  and Quints stay authored because a single-number rack always doubles as evens
  or odds. Every rack is checked with `fits` against all five and thrown away
  if it reads as more than one, and distractors are only sections the rack does
  NOT fit. Generated racks are ORIGINAL structures, never card hands.
- **Fix My Mistakes** replays `PracticeRecordStore.reviewQueue()`, an SM-2-ish
  schedule over per-item history. An item leaves the queue after two correct in
  a row, not one.
- **Timed Challenge**: 90 seconds of mixed generated items, best score kept.

`PracticeRecordStore` records EVERY graded answer app-wide (each drill view
calls it alongside `progress.recordItem`). Generated ids are unique per
question, so they collapse onto one per-skill row and never enter the review
queue or the seen/missed sets, which would otherwise grow without bound.
`StatsView` (free for everyone) reads the per-room rollups.

**Game-night rhythm (1.2, 2026-08-08):** Mahj+ now owns two recurring practice
rituals. `MahjMinuteContent` deterministically builds the same five questions
for every member on a local calendar day: two generated rack reads, one
authored Charleston decision, and two authored table judgments. Results and a
30-day archive stay on device in `MahjMinuteStore`; sharing uses the system
share sheet and needs no account or leaderboard. `GameNightPrepView` stores a
weekly game night in `AppSettings`, schedules a local notification, and opens
directly into `SessionBuilder.gameNightPrep`, which prioritizes due mistakes,
misses, the weakest room, and unseen member content in that order. Both
features are entirely Mahj+ gated. iPad support is free, with adaptive Home
columns, drill grids, readable content widths, and portrait and landscape
orientations.

**What's New sheet:** `WhatsNew` + `WhatsNewSheet`, shown once on the first
launch after an update. A FRESH install never sees it: onboarding calls
`WhatsNew.markCurrentAsBaseline()`. An onboarded player with no stored marker
is an upgrader from a pre-1.1 build and does get it. The sheet raises
`onUpgrade` rather than presenting `PaywallView` itself, because a sheet cannot
present another sheet while dismissing.

**Free-beginner + extra-sets model (2026-07-13):** all four beginner rooms are
FREE and everything that was ever free stays free. Mahj+ ADDS: one extra
practice set per beginner room (`Shared/Content/PlusContent.swift`, drills
flagged `isPlus`, ids `plus-*`, same mechanics as the room's free drills, just
more original questions) plus the whole `pro-tables` room, now shown as **The
Master Tables** (`Shared/Content/ProContent.swift`). Locking is per-drill:
`Room.isLocked(_:isMember:)` is the single source of truth, and `SessionBuilder`
filters the Quick Session pool through it. The onboarding trial page
follows the OT710 zero-shift pattern (`~/OT710.md`, StatScout reference): no
plan cards, soft "Get Started" exit ABOVE the primary, primary CTA in the exact
Continue slot, one tap → yearly trial purchase → Apple confirm; full
`PaywallView` (plan picker) is only the products-failed fallback and the
in-app/Settings paywall. A user backing out of Apple's sheet is a
`PurchaseOutcome.cancelled`, NOT an error: never answer it by shoving up
another paywall.

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
- `MahjTrainer/Views` — `RootView` branches onboarding vs `HomeView` on the
  `progress.hasOnboarded` defaults key (branch, NOT a fullScreenCover — the
  cover flashed Home behind onboarding on first launch). Navigation is a LOBBY:
  `HomeView` shows Get Started (mixed session) + one card per room; `RoomView`
  lists that room's drills, with the locked Mahj+ set and an in-room upsell.
  Home's job is the ROOMS, so everything else earns its space: stats are chips
  beside the title (not a row of their own), room cards carry a progress RING
  rather than a status sentence, that ring counts only drills the player can
  actually open, and the How to Play card disappears once the primer has been
  read (`mahj.hasReadPrimer`), living in Settings after that.
  (Home was flat until 2026-07-13; once every room grew an extra set, a dozen
  drill rows on one screen stopped reading as rooms.) Onboarding stores skill level
  at defaults key `mahj.skillLevel`. After the trial decision, players who
  selected `new` see `HowToPlayView` first, then everyone gets
  `FeatureTourView`, whose finale runs a real Quick Session. Both of those
  screens carry an ESCAPE HATCH straight to Home ("Skip for now" / "Skip the
  tour" / "Skip it, take me to the app"): onboarding is long, and a player who
  wants to just use the app must always be one tap from doing so. The primer
  stays available from Home for new players and from Settings for everyone.
  `HowToPlayView` pages by swipe as well as by buttons, and its Back button
  sits NEXT to Continue, not in the top-left corner a thumb can't reach.
- `MahjTrainer/Utilities/Theme.swift` — the warm-modern design system: cream
  surfaces, jade primary, coral energy, per-room accents (`Room.accent`), serif
  display type (`Theme.display`), `themedCard()`/`primaryCTA()` styles,
  `Haptics` (gated on `settings.haptics`; grading uses `correctAnswer()` /
  `wrongAnswer()`, which must feel like OPPOSITES in the hand: a crisp rising
  tap vs a dull double thud. Apple's `.success`/`.error` notification patterns
  are both stutters and read as the same buzz mid-drill). `SoundPlayer` plays the synthesized
  wavs in `MahjTrainer/Resources/Sounds` (gated on `settings.sound`;
  regenerate via a make_sounds.py-style script if changed). All colors are
  light/dark adaptive; launch screen color is the `LaunchBackground` asset
  (keep in sync with `Theme.background`).

## Flashcard deck (signature interaction)

See `MahjTrainer/Views/Drills/CLAUDE.md` for the swipe-deck gesture/flip
mechanics and gotchas.

## iPad layout: centre what underfills

Every drill body is a scroll view, because a graded question plus its coaching
note outgrows a phone. On a 13-inch iPad the same question fills a third of the
screen, and a plain `ScrollView` pins it to the top. `CenteringScrollView`
(`Views/Components/`) is the answer: `minHeight` = viewport so short content
centres, natural size so tall content still scrolls. `QuestionPager` and
`CharlestonDrillView` both use it. Two things it must keep: `maxWidth:
.infinity` alongside the `minHeight` (a plain ScrollView centres narrow content
for you, an explicitly framed one does not, and the question slides left), and
the room eyebrow INSIDE the pager (`QuestionPager.eyebrow`) so it centres with
the question instead of stranding itself at the top. The flashcard deck is
capped at 520pt wide, 1.5x tall: a card stretched to the full readable width is
the same few words spread thinner.

## Screenshots: captured, not hand-shot

`scripts/capture-screenshots.sh <udid> <out-dir> [prefix]` drives the real app
through the six App Store screens via the `Screenshots` scheme
(`MahjTrainerScreenshots`) and exports only `ScreenshotTests` attachments.
Purchase-surface tests are intentionally excluded from this command, so the
App Store set never creates paywall images. Run
`scripts/capture-paywall.sh <udid> <out-dir>` separately when reviewing the
paywall or onboarding trial step. iPad shots must be
2064x2752, which only a 13-inch device produces and the agent-sim pool does not
have, so `scripts/with-ipad-sim.sh` creates a throwaway one, boots it headless,
and deletes it on exit:

```bash
./scripts/with-ipad-sim.sh sh -c './scripts/capture-screenshots.sh "$IPAD_UDID" out ipad_'
```

Gotchas baked into the test, do not undo them: the What's New sheet covers Home
on the first launch after a version bump, so the script passes the marketing
version through `TEST_RUNNER_SCREENSHOT_APP_VERSION` and the test marks it seen
(dismissing is not enough, it returns every time Home reappears); returning to
the root taps navigation-bar button 0 only while a back button is there,
because on Home that button is the Settings gear and the extra tap opens
Settings while the elements underneath still answer queries; and the test never
calls `XCTFail`, because a failing UI test spends ten minutes collecting
simulator diagnostics before it tells you anything.

## Illustration: don't

Generated room art was tried and removed (2026-07-13): it looked cheap and
fought the type-and-tile aesthetic. Tiles are drawn from real data by
`TileView`/`TileRackView`; a generated tile face is a WRONG tile, and a wrong
tile teaches the wrong thing. Keep the visual language to type, tiles, SF
Symbols and the room accents.

## Design research

`docs/research/mahjong-market.md` (competitor apps, pricing, aesthetic
white-space) and `docs/research/trainer-ux.md` (flashcard/session UX patterns,
swipe-deck checklist) — consult before design or monetization changes.

---
Shared iOS conventions (build, simulator, release/TestFlight, ASC key, signing,
review funnel, pricing scripts, gotchas): always-loaded global CLAUDE.md + the
`ios-dev` skill.

## Subagent delegation
Follow the global CLAUDE.md subagent rules: ask Jack for the model before spawning, spawn at most one at a time unless Jack explicitly approves more, and never allow a subagent to spawn another subagent.
