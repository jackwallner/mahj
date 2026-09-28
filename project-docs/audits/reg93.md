# REG93: 1.2.1 App Store release to 1.3.0 TestFlight audit

Audit date: 2026-09-04, Pacific Time

## Comparison and confidence

| Artifact | Ground truth |
|---|---|
| Current App Store release | Version 1.2.1, live build 23, `READY_FOR_SALE` |
| Latest valid TestFlight build | Version 1.3.0, build 28, uploaded 2026-09-04 01:03 PDT, `VALID` |
| TestFlight distribution | Internal group only (`Jack`). External beta submission is still `READY_FOR_BETA_SUBMISSION` |
| Source baseline | Commit `fe6898a`, the build 23 release source |
| Test source | Commit `5b98676`, the build 28 source |
| Source delta | 40 files, 6,096 additions, 92 deletions |
| ASC products checked | Monthly $9.99, yearly $39.99, lifetime $89.99 in the USA. Both subscriptions have a 1-week trial. Subscription group is `Mahj+` |

The audit used read-only App Store Connect API queries, the source diff, static review of all changed runtime/content paths, the prior live runtime audit in [laudit89.md](/Users/jackwallner/mahj/archive/laudit89.md), and a local build.

The 1.3.0 source build succeeded with bundle `com.jackwallner.mahj`, version 1.3.0, build 28, and minimum iOS 17.0. Unit-test bundles also compiled, but no unit-test cases ran because CoreSimulator timed out while preparing `agent-sim-2` after 60 seconds. The result was infrastructure failure, not a passing test run. The current build could not be visually smoke-tested because install/launch calls on the leased iOS 26.5 and iOS 27 pool devices did not return. Runtime claims below are marked as source findings or carry-forward findings from the live audit.

## Triage

| ID | Severity | Status | Finding |
|---|---|---|---|
| REG93-001 | P1 | New in 1.3 | Mastery and Stats do not migrate completion-only history, so existing progress can reset or contradict room state |
| REG93-002 | P1 | New 1.3 surface | The core Play a Hand discard interaction has no accessible action or selected state |
| REG93-003 | P2 | New in 1.3 | Generated Charleston racks can contain multiple ungrouped junk tiles while coaching claims only one |
| REG93-004 | P2 | New in 1.3 | Tile-counting questions display a tile when the prompt says the player holds none |
| REG93-005 | P2 | New in 1.3 | Play a Hand setup and verdict do not use the app's iPad centering container |
| REG93-006 | P2 | Worsened by 1.3 | Adding Play a Hand pushes existing compact Home training modes farther offscreen with no discovery cue |
| REG93-007 | P2 | New in 1.3 | A free player's daily hand is consumed on start with no resume or abandon protection |
| REG93-008 | P1 | Carry-forward, live observed | Sheets and full-screen surfaces do not isolate the underlying accessibility tree |
| REG93-009 | P1 | Carry-forward, source confirmed | Stacked flashcard previews remain exposed as active accessibility elements |
| REG93-010 | P2 | Carry-forward, live observed | The compact Home header still allows the title, stats chips, and toolbar to collide |
| REG93-011 | P2 | Carry-forward, live observed | Timed Challenge spends its 90 seconds before the player is ready and drops early-exit scores |
| REG93-012 | P2 | Carry-forward, worsened by 1.3 content | Paywall has a dead loading-price state, weak plan selection semantics, and a compact-footer occlusion risk |
| REG93-013 | P2 | Carry-forward, source confirmed | Onboarding's monthly purchase conflicts with the canonical yearly-trial brief and historical funnel assumption |
| REG93-014 | P2 | Release readiness | ASC, in-app branding, legal pages, StoreKit fixture, review notes, and release scripts disagree |
| REG93-015 | P2 | Carry-forward, source confirmed | Onboarding's offscreen pages remain in the accessibility tree |

## Findings

### REG93-001: Mastery and Stats can reset or contradict prior progress

Severity: P1

Status: New in 1.3.

Impact: The live Home ring counted completed drills from `ProgressStore.completions`. The test build replaces it with per-question mastery from `PracticeRecordStore`, where an item is known only after two consecutive correct answers. There is no migration from completion totals. A player who has older completion data without matching practice records can see a room change to `Not started`, while the room's drill rows still show their old completion checkmarks. Stats can simultaneously say `No practice yet`.

Evidence:

- The release implementation counted `progress.completions(for:)` in the Home room ring. This is the code at baseline commit `fe6898a`, lines 522 to 527 of `MahjTrainer/Views/HomeView.swift`.
- The test build reads mastery from [HomeView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/HomeView.swift:572), [Mastery.swift](/Users/jackwallner/mahj/Shared/Services/Mastery.swift:95), and [PracticeRecordStore.swift](/Users/jackwallner/mahj/Shared/Services/PracticeRecordStore.swift:52).
- The old completion data remains in [ProgressStore.swift](/Users/jackwallner/mahj/Shared/Services/ProgressStore.swift:41), while [RoomView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/RoomView.swift:93) still renders its checkmarks from that store.
- An empty practice-record dictionary drives [StatsView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/StatsView.swift:14) to `No practice yet`.

Recommendation: preserve a completion-only transition state or migrate old engagement without inventing mastery. Home, Room, and Stats should tell one consistent story after an upgrade.

### REG93-002: Play a Hand discard selection is not accessible

Severity: P1

Status: New 1.3 surface, using an existing shared component.

Impact: The new mode depends on tapping a tile for every one of its twelve throws. The rack exposes a label and identifier, but the throw action is only an `onTapGesture`. There is no Button action, custom accessibility action, selected state, or equivalent control semantics. VoiceOver users can hear tile names but cannot reliably activate a throw, and Switch Control users cannot complete the mode.

Evidence:

- [HandPlayView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Drills/HandPlayView.swift:216) wires the core play screen to `TileRackView` and [HandPlayView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Drills/HandPlayView.swift:230) supplies the throw callback.
- [TileView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Components/TileView.swift:162) renders the rack, but [TileView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Components/TileView.swift:196) attaches only `onTapGesture`.
- The same tile-control pattern was recorded as a live accessibility issue in [laudit89.md](/Users/jackwallner/mahj/archive/laudit89.md:110), and 1.3 makes it a blocking interaction rather than a secondary drill detail.

Recommendation: expose each throw as an accessible control with an action and state, including the highlighted drawn tile and the post-throw disabled state.

### REG93-003: Generated Charleston questions can have several junk tiles

Severity: P2

Status: New in 1.3.

Impact: A generated question promises one defensible tile to pass. The generator can build an 11-tile core from `[4, 3, 3, 1]` or `[3, 3, 4, 1]`, then adds two outsiders. That produces at least two tiles outside the made groups, and sometimes a third singleton in the core. Only `strays[0]` is offered as the answer. The explanation says every other tile is already part of a group, which is false when the player inspects the rack.

Evidence:

- [CharlestonGenerator.swift](/Users/jackwallner/mahj/Shared/Content/CharlestonGenerator.swift:34) allows partitions with a singleton.
- [CharlestonGenerator.swift](/Users/jackwallner/mahj/Shared/Content/CharlestonGenerator.swift:90) adds two strays, but [CharlestonGenerator.swift](/Users/jackwallner/mahj/Shared/Content/CharlestonGenerator.swift:96) selects only the first.
- The false coaching sentence is in [CharlestonGenerator.swift](/Users/jackwallner/mahj/Shared/Content/CharlestonGenerator.swift:190).
- [GeneratedPracticeTests.swift](/Users/jackwallner/mahj/MahjTrainerTests/GeneratedPracticeTests.swift:41) verifies the answer and distractors, but does not verify that every non-answer rack tile belongs to a made group or that the explanation is true.

Recommendation: generate exactly one non-grouped tile, or change the question and coaching to account for every junk tile. Add a whole-rack invariant to the generator tests.

### REG93-004: Tile-counting prompt contradicts the displayed rack

Severity: P2

Status: New in 1.3.

Impact: When `held == 0`, the prompt says `none on your rack`, but the generated item still carries one copy of the tile. [QuestionUI.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Components/QuestionUI.swift:73) renders every nonempty `item.tiles` array, so the player sees a tile directly below a statement that says they hold none. The visual can be mistaken for a held tile and makes a simple counting question look internally inconsistent.

Evidence:

- [EndlessPractice.swift](/Users/jackwallner/mahj/Shared/Content/EndlessPractice.swift:151) writes the `none on your rack` text.
- [EndlessPractice.swift](/Users/jackwallner/mahj/Shared/Content/EndlessPractice.swift:157) forces at least one displayed tile with `max(held, 1)`.
- The generated-practice tests cover answer arithmetic and item shape, not prompt-to-visual consistency.

Recommendation: omit the tile when the held count is zero, or label it explicitly as the tile being counted rather than a tile in the player's rack.

### REG93-005: Play a Hand does not center all iPad states

Severity: P2

Status: New in 1.3.

Impact: The new play state uses `CenteringScrollView`, but the setup and verdict states use plain `ScrollView`. On the 13-inch iPad, a short verdict or a shortened setup can pin content to the top and leave a large empty lower region. This breaks the app's stated iPad layout contract and makes the mode feel unfinished compared with the other drills.

Evidence:

- Setup uses plain `ScrollView` in [HandPlayView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Drills/HandPlayView.swift:72).
- The play state correctly uses [CenteringScrollView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Components/CenteringScrollView.swift:3) at [HandPlayView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Drills/HandPlayView.swift:216).
- The verdict returns to plain `ScrollView` in [HandPlayView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Drills/HandPlayView.swift:394).
- The project layout rule requires drill bodies to use the centering container. Current runtime confirmation was blocked by CoreSimulator.

Recommendation: use the same centering container for setup and verdict, preserving normal scrolling when their content exceeds the viewport.

### REG93-006: New Home tile worsens hidden compact training modes

Severity: P2

Status: Worsened by 1.3.

Impact: On compact devices, the TRAINING section is a horizontal scrolling row with indicators disabled and no `More` label or page cue. Build 28 inserts Play a Hand before Endless Practice, Mahj Minute, Game Night Prep, Timed Challenge, and conditional Fix My Mistakes. The prior live audit already observed that Timed Challenge and Review were offscreen at roughly 402 points wide. The new first tile pushes those modes farther away, so members can miss paid features and free users get no signal that more training exists.

Evidence:

- The compact row is in [HomeView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/HomeView.swift:375), with indicators disabled at [HomeView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/HomeView.swift:391).
- Build 28 puts Play a Hand first and Timed Challenge fifth in [HomeView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/HomeView.swift:402).
- The live observation and impact are documented in [laudit89.md](/Users/jackwallner/mahj/archive/laudit89.md:215).

Recommendation: add an explicit discovery affordance or make the compact training modes fit a predictable grid or paged control.

### REG93-007: Abandoning a started free hand consumes the daily allowance

Severity: P2

Status: New in 1.3.

Impact: The one free hand is recorded as spent as soon as the player taps `Play it out`. The hand is held only in view state. If a player backs out, backgrounds the app, or the app is terminated before the verdict, there is no resume path and the Home tile says `Back tomorrow`. An accidental navigation tap can therefore consume the only free use without delivering a result.

Evidence:

- [HandPlayView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Drills/HandPlayView.swift:208) calls `recordStart` before entering the playing phase.
- [HandPlayStore.swift](/Users/jackwallner/mahj/Shared/Services/HandPlayStore.swift:39) writes the free-day marker at that point.
- [HandPlayView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Drills/HandPlayView.swift:32) stores the rack and wall only as transient view state. No persisted in-progress hand or abandon confirmation exists.

Recommendation: persist an in-progress hand with resume, or delay consuming the free allowance until a completed hand and provide an explicit abandon confirmation.

## Carry-forward issues still present in 1.3

### REG93-008: Modal surfaces do not isolate the underlying accessibility tree

Severity: P1

Status: Carry-forward, live observed in the current release family.

Impact: When Settings, Paywall, What's New, or the feature-tour full-screen session is presented, controls behind the surface remain discoverable to assistive technology. This lets focus land on controls that are not visible and can activate the wrong surface.

Evidence:

- Home still presents multiple sheets without an explicit accessibility-modal boundary in [HomeView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/HomeView.swift:83).
- Feature Tour still presents its full-screen session from [FeatureTourView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/FeatureTourView.swift:91).
- The underlying-control behavior was directly observed for Mahj Feature Tour and Settings in [laudit89.md](/Users/jackwallner/mahj/archive/laudit89.md:80).

Recommendation: make each modal surface a true accessibility modal and hide the presenting content while it is active.

### REG93-009: Stacked flashcard previews remain exposed as active cards

Severity: P1

Status: Carry-forward, source confirmed and previously audited.

Impact: The top flashcard is the only hit-testable card, but the next two cards remain in the accessibility tree with their labels and button traits. VoiceOver can focus a card that cannot be opened or advanced, which makes the signature swipe deck appear broken.

Evidence:

- [FlashcardDrillView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Drills/FlashcardDrillView.swift:120) renders three cards, while [FlashcardDrillView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Drills/FlashcardDrillView.swift:140) limits hit testing to slot zero.
- Accessibility traits are still added to every rendered card at [FlashcardDrillView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Drills/FlashcardDrillView.swift:142).
- This was documented as a live drill issue in [laudit89.md](/Users/jackwallner/mahj/archive/laudit89.md:140).

Recommendation: hide non-top cards from accessibility and expose only the active card's actions.

### REG93-010: Compact Home header still has a collision risk

Severity: P2

Status: Carry-forward, live observed.

Impact: The title and two stats chips remain in an unconstrained horizontal stack. On a 402-point iPhone width, the live audit observed the stats area colliding with the navigation-bar Settings control. The new Reference toolbar item does not fix the underlying width pressure.

Evidence:

- The current header remains an `HStack` with both stats chips in [HomeView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/HomeView.swift:226).
- The live collision is documented in [laudit89.md](/Users/jackwallner/mahj/archive/laudit89.md:192).

Recommendation: give the title and stats an adaptive compact layout, and retest at the smallest supported iPhone width and Dynamic Type sizes.

### REG93-011: Timed Challenge starts before ready and loses early exits

Severity: P2

Status: Carry-forward, live observed.

Impact: The 90-second clock starts from the view's `.task`, while the player is still orienting to the first question. The timed mode has no explicit Finish control. If the player uses the navigation back action before the timer expires, `finish()` is not called, so the score is not saved as a best score.

Evidence:

- The timer is initialized to 90 seconds and starts from [PracticeRunView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Drills/PracticeRunView.swift:44) and [PracticeRunView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Drills/PracticeRunView.swift:154).
- The toolbar deliberately omits Finish for timed mode at [PracticeRunView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Drills/PracticeRunView.swift:145).
- `finish()` is the only path that records the best score at [PracticeRunView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/Drills/PracticeRunView.swift:322).
- The live audit observed the timer dropping from 90 to 76 while the first question was being read in [laudit89.md](/Users/jackwallner/mahj/archive/laudit89.md:257).

Recommendation: add a ready state or pause-on-first-interaction, and make an early exit either confirm abandonment or save an intentional finish.

### REG93-012: Paywall has a dead loading state and weak compact semantics

Severity: P2

Status: Carry-forward, with the layout risk worsened by the larger 1.3 benefit list.

Impact: If offerings have not loaded, all prices show `Loading price…`, but the primary CTA remains enabled. Tapping it runs another offerings request and then produces a generic products-unavailable error if the package is still missing. The plan cards also communicate selection only through border and fill changes, while yearly and monthly share the same CTA label and have no selected accessibility value. On compact phones, the sticky terms and CTA footer still competes with the taller benefit list and can obscure the lowest plan details.

Evidence:

- The loading placeholder is defined in [PaywallView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/PaywallView.swift:168), while the purchase button is only disabled for `purchasing` at [PaywallView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/PaywallView.swift:292).
- Plan selection is visual only in [PaywallView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/PaywallView.swift:103), and the two subscription plans share the CTA title at [PaywallView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/PaywallView.swift:7).
- The current content has seven benefits at [PaywallView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/PaywallView.swift:53), and the sticky footer is defined at [PaywallView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/PaywallView.swift:276).
- The compact footer occlusion was directly observed against the live paywall in [laudit89.md](/Users/jackwallner/mahj/archive/laudit89.md:281).

Recommendation: disable or replace the CTA until a selected package and price are ready, expose selected state to accessibility, and verify the full plan cards above the sticky footer at compact widths.

### REG93-013: Onboarding's monthly trial conflicts with the yearly-trial brief

Severity: P2

Status: Carry-forward decision mismatch, not changed by 1.3.

Impact: The canonical project brief describes the onboarding tap as a yearly trial purchase, and the historical pricing analysis cites a 100% yearly onboarding funnel. Both release build 23 and test build 28 instead purchase the monthly package and disclose the monthly price. ASC currently has both products, so this is a real plan-selection difference, not a naming detail. It may be intentional, but the release artifact, brief, and historical funnel no longer describe the same customer path.

Evidence:

- The brief says yearly trial at [CLAUDE.md](/Users/jackwallner/mahj/CLAUDE.md:146).
- The historical funnel assumption is recorded in [docs/tasks/03-pricing-increase-1.3.md](/Users/jackwallner/mahj/docs/tasks/03-pricing-increase-1.3.md:180).
- The test build discloses and purchases monthly in [OnboardingView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/OnboardingView.swift:231) and [OnboardingView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/OnboardingView.swift:337).
- The same monthly behavior is present in the release baseline, so this is not a newly introduced binary regression.

Recommendation: resolve the intended onboarding plan before evaluating 1.3 conversion or submitting the build, then align the brief, funnel instrumentation, and CTA behavior.

### REG93-014: Release surfaces disagree with ASC and Mahj+ branding

Severity: P2

Status: Release readiness finding, not a new runtime regression.

Impact: ASC uses the `Mahj+` group and current USA prices of $9.99 monthly, $39.99 yearly, and $89.99 lifetime. Several local release and review surfaces still describe `Pro`, old product scope, or historical prices. This can mislead App Review, make local StoreKit testing show the retired brand, and let future release scripts reset ASC toward obsolete values. The local ASC state also says live 1.2.0 even though ASC reports 1.2.1.

Evidence:

- The marketing page has current prices but stale JSON-LD version `1.2.0` in [docs/index.html](/Users/jackwallner/mahj/docs/index.html:60).
- Terms and privacy still call the product `Mahj Trainer Pro` in [docs/terms.html](/Users/jackwallner/mahj/docs/terms.html:79) and [docs/privacy-policy/index.html](/Users/jackwallner/mahj/docs/privacy-policy/index.html:69).
- The StoreKit fixture still uses `Pro` names and group labels in [MahjTrainer.storekit](/Users/jackwallner/mahj/MahjTrainer/MahjTrainer.storekit:12).
- Review notes still describe only the old Pro room and old $1.99, $9.99, and $29.99 prices in [notes.txt](/Users/jackwallner/mahj/fastlane/metadata/review_information/notes.txt:11).
- Release scripts still contain old group, price, and review-note targets in [asc-setup-release.py](/Users/jackwallner/mahj/scripts/asc-setup-release.py:16) and [asc-set-prices.py](/Users/jackwallner/mahj/scripts/asc-set-prices.py:31).
- The local state file is stale in [.asc-state.json](/Users/jackwallner/mahj/scripts/.asc-state.json:2), reporting draft 1.2.1 and live 1.2.0.

Recommendation: treat ASC as the source of truth, then synchronize the local fixture, legal naming, review notes, scripts, and version metadata before the next submission. This audit did not modify any of those files.

### REG93-015: Offscreen onboarding pages remain accessible

Severity: P2

Status: Carry-forward, source confirmed.

Impact: The onboarding `TabView` contains all five pages at once, but there is no page-specific accessibility hiding. VoiceOver can encounter skill and trial controls while the page is visually elsewhere, creating a misleading focus order and premature access to purchase controls.

Evidence:

- All pages are constructed in one `TabView` in [OnboardingView.swift](/Users/jackwallner/mahj/MahjTrainer/Views/OnboardingView.swift:48).
- The same issue was recorded during the live accessibility review in [laudit89.md](/Users/jackwallner/mahj/archive/laudit89.md:236).

Recommendation: expose only the active page and its controls to accessibility, and verify the page transition order with VoiceOver.

## Validation notes

- No app or test source was changed for this audit. The only intended working-tree addition is this report.
- `xcodebuild build` succeeded for the 1.3.0 source.
- `xcodebuild test -only-testing:MahjTrainerTests` compiled the test target but executed zero cases because CoreSimulator could not boot `agent-sim-2` within 60 seconds.
- No crash, hang, or visual result from the current 1.3.0 runtime is classified as an app regression because the simulator launch wrapper did not return.
- The unit tests include coverage for generator arithmetic, hand-play scoring, mastery rules, reference content, and paywall funnel records, but their assertions were not executed in this audit.
