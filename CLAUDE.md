# Mahj Trainer — Project Guide

American Mah Jongg training app: flashcard/quiz drills for new players (no actual gameplay). XcodeGen project/scheme: `MahjTrainer`, simulator device `agent-mahj`.

## Tech Stack
- Swift 6 / SwiftUI (strict concurrency)
- XcodeGen (`project.yml`). Target: iOS 17+
- RevenueCat entitlement `pro` (public key in `SubscriptionService.swift`; secret API key in `~/.mahj_credentials`, never commit)

## Targets / bundle IDs
- `MahjTrainer` — `com.jackwallner.mahj` (product name "Mahj Trainer", module `MahjTrainer`)

## Architecture
- `Shared/Models` — `Tile` (suits/winds/dragons/flower/joker with `.c(n)/.b(n)/.d(n)` authoring shorthand), `HandCategory` (the 9 stable NMJL card sections), drill types (`Flashcard`, `QuizQuestion`, `HandMatchQuestion`, `CharlestonScenario`, `Drill`, `Room`).
- `Shared/Content` — all drill content as Swift constants; `DrillLibrary.rooms` defines the 4 rooms (Tile Room free; Card/Charleston/Table rooms Pro). Content rules are enforced by `ContentValidityTests` (13-tile deals, 3-tile passes, no passing jokers, max 4 copies of a tile, no em dashes).
- `Shared/Services` — `ProgressStore` (UserDefaults streaks/completions, review-funnel gate after 3rd session), `SubscriptionService` (RC, simulator early-return preserved).
- `MahjTrainer/Views` — `HomeView` (rooms) → `RoomView` → 4 drill view types; `TileView`/`TileRackView` render tiles natively (no images).

## App-specific notes
- **Content is legally constrained**: the NMJL yearly card is copyrighted. All example hands are ORIGINAL teaching hands for the category system. Never copy hands from the actual card; keep the "not affiliated with NMJL" disclaimer (Home footer, Settings, App Store description).
- Products: `com.jackwallner.mahj.monthly` ($4.99) / `.yearly` ($29.99), both with 1-week free trial. Keep monthly trials (fleet rule).
- Review funnel: enjoyment gate fires once after the 3rd completed drill (`DrillCompleteView`).

---
Shared iOS conventions (build, simulator, release/TestFlight, ASC key, signing, review funnel, gotchas):
always-loaded global CLAUDE.md + the `ios-dev` skill.
