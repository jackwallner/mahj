# laudit89 UX audit

Audit date: 2026-08-09

Apps audited: Mahj, Bridge, Skat, Sheepshead, and Cribbage

## Outcome

This is a user-perspective audit of the end-to-end experience across the five trainer apps. It covers new-player onboarding, free use, Mahj+ or membership conversion, member practice, content navigation, compact-phone layout, iPad layout where available, accessibility-tree behavior, localization, pricing, and failure states.

No product code was changed. The only intended working-tree change is this document.

Severity used below:

- P1, high: blocks a meaningful user path, creates a serious accessibility failure, or risks a purchase decision.
- P2, medium: causes repeat confusion, hides important content, or creates a substantial layout or localization problem.
- P3, low: limited-device polish issue or a lower-impact usability risk.

## Executive triage

| ID | Severity | Apps | Finding |
| --- | --- | --- | --- |
| FLEET-004 | P1 | All, confirmed in Mahj and Bridge | Modal and full-screen surfaces do not isolate the presenting content from the accessibility tree. Underlying controls remain discoverable and enabled while a paywall, Settings sheet, or first-session cover is visible. |
| FLEET-007 | P1 | All | Card and tile selections are implemented as tap gestures on visual views without clear button traits, actions, or selected-state announcements. Cribbage confirms the card picker remains static text in the accessibility tree even while touch selection works. |
| FLEET-005 | P1 | All, confirmed in Bridge, Sheepshead, and Cribbage | Stacked flashcard previews are exposed as multiple active accessible cards. VoiceOver users can be read future questions as though they are current. |
| FLEET-002 | P2 | Skat, Sheepshead, Cribbage confirmed | Returning to Home through the onboarding escape hatch leaves the Home scroll content shifted upward by roughly 70 points. The title and stats clip, and the Settings gear overlaps the Get Started play control. |
| SKAT-001 | P2 | Skat | German users see English labels and entire English member screens for Skat Minute and Game Night Prep. |
| SKAT-002 | P1 | Skat | When product prices are unavailable, all plan cards remain on `Preis wird geladen ...` indefinitely while the purchase CTA remains enabled. |
| PAY-001 | P2 | Mahj and Skat confirmed | The lowest monthly plan is partly covered by the sticky paywall footer on compact screens. Supporting plan details are not fully available before purchase. |
| FLEET-003 | P2 | All | The Home training carousel hides paid practice modes offscreen without a visual scroll cue, page indicator, or accessible “more” affordance. |
| FLEET-006 | P2 | All | Offscreen onboarding pages remain in the accessibility tree, including trial controls and legal links that do not belong to the visible page. |
| FLEET-001 | P2 | Mahj confirmed, shared layout risk | On the 402-point Mahj Home, the stats chip and Settings gear occupy overlapping horizontal space. |
| FLEET-008 | P2 | All | Timed Challenge begins counting down as soon as the screen appears, with no ready state. Reading instructions and orienting to the first question consumes the advertised 90 seconds. |
| MAH-002 | P2 | Mahj | Public pricing and legal surfaces still use the previous prices and the retired “Pro” name while the app and current store metadata use Mahj+ and the new prices. |
| MAH-001 | P3 | Mahj | The primer Previous button is clipped at the left edge on an iPhone 17 Pro running iOS 27. |

The highest-leverage work is the accessibility isolation and card/tile semantics shared by all five apps, followed by the compact Home transition and paywall states. The Skat localization and product-loading issues should be handled as app-specific release blockers for the relevant audience.

## Test and runtime coverage

### Devices and states

- Mahj: fresh iPhone 17 Pro at 402 points, iOS 27; fresh iPad Air 11-inch M3 in portrait; member state exercised with simulator-safe local state.
- Bridge: fresh iPhone 17 Pro Max at 440 points, iOS 26.5; free and paywall paths exercised.
- Skat: fresh iPhone 17 Pro at 402 points, iOS 26.3; German onboarding, primer, Home, room, paywall, and member-feature labels exercised.
- Sheepshead: fresh iPhone 17 Pro at 402 points, iOS 26.5; onboarding, Home, Bury room, flashcards, and paywall exercised.
- Cribbage: fresh iPhone 17 Pro at 402 points, iOS 26.3; onboarding, Home, Discard room, flashcards, card selection, and paywall exercised.

All simulator work used the headless shared device pool. The production RevenueCat key was not used on a simulator.

### Automated checks

- Mahj: 68 tests passed.
- Bridge: the initial run had a launch or test-environment flake around the daily-content test. A full rerun completed with 51 tests passed and no failures.
- Skat: the initial full run had one failure in `SkatMinuteContentTests.testChallengeIsStableAndSharedForACalendarDay`. The test passed when rerun in isolation. It is treated as test-environment noise, not a user-facing finding.
- Sheepshead: 65 tests passed.
- Cribbage: 76 tests passed.

The content validity, answer, and domain test suites did not expose a confirmed wrong-answer, malformed-hand, empty-session, or locking defect during this audit. That does not replace a full content review, but the findings below are primarily interaction, accessibility, layout, localization, and monetization issues.

### Persona and angle coverage

| Persona or angle | Coverage |
| --- | --- |
| Brand-new beginner | Fresh-install onboarding was walked in every app, including skill selection, trial choice, primer, and the first Home landing. Mahj also reached the real first Quick Session. |
| Beginner in a hurry | The trial and primer escape hatches were used. This exposed the post-onboarding Home offset in Skat, Sheepshead, and Cribbage. |
| Free learner | Free rooms, free drills, room progress, locked extra sets, and the in-room upsell were sampled in all five apps. |
| Mahj+ or membership candidate | Paywalls were opened from locked content in all five apps. Prices, benefits, legal links, restore, CTA state, and compact scrolling were inspected. |
| Active member | Mahj member state exercised Endless Practice, Fix My Mistakes, and Timed Challenge. The other apps were source-checked and sampled through the available member surfaces. |
| Returning player | Home after completed work, Home after an onboarding transition, restart behavior, Settings, and progress surfaces were inspected. |
| Accessibility user | Accessibility-tree inspection covered onboarding, Home, modal surfaces, flashcard decks, and card or tile selection. This was not a full hands-on VoiceOver session, so the accessibility findings should be confirmed with VoiceOver before implementation is closed. |
| Compact-phone user | 402-point iPhone layouts were exercised for Mahj, Skat, Sheepshead, and Cribbage. Bridge was exercised at 440 points, so its 402-point compact layout still needs direct validation. |
| iPad user | Mahj was exercised on an 11-inch iPad Air in portrait. The tested layout was clean. A 13-inch App Store screenshot capture was not run. |
| German-language player | Skat onboarding, free drills, Home, paywall, Skat Minute, and Game Night Prep labels were inspected. |
| Trust-sensitive purchaser | Public and in-app prices, product naming, trial language, cancellation language, restore, Terms, Privacy, and unavailable-product behavior were inspected. |
| Notification and game-night user | Mahj Settings notification permission and time selection were sampled. Recurring feature copy was source-checked in the other apps; notification delivery was not scheduled and waited on end-to-end in every app. |

## Findings

### FLEET-004, modal surfaces do not isolate underlying controls

Severity: P1

Apps: all five by source parity; runtime confirmed in Mahj and Bridge

User impact: VoiceOver navigation can move from the visible modal or full-screen flow into the Home, Feature Tour, or other presenting controls. A user may hear or activate controls that are visually covered and cannot understand which surface currently owns the interaction.

Observed behavior:

- In Mahj, while the Feature Tour's real Quick Session was visible, the accessibility tree still contained `YOUR TURN`, `Start my first session`, and `Skip it, take me to the app` from the covered tour. They remained available alongside `Close` and `Quick Session`.
- In Mahj, while Settings was presented, Home controls remained in the accessibility tree.
- In Bridge, while the paywall sheet was visible, Home room and training controls remained discoverable in the accessibility tree.
- The visual presentation looked modal to a sighted user, so this creates a mismatch between visual and accessibility state.

Reproduction:

1. Complete onboarding far enough to reach Home.
2. Open a paywall or Settings sheet, or start the Feature Tour's first real session.
3. Inspect the accessibility tree, or navigate with VoiceOver focus.
4. Continue past the visible sheet's controls and note the underlying Home or tour controls.

Evidence and source:

- `MahjTrainer/Views/HomeView.swift:70-71` and equivalent `HomeView.swift` files present sheets without accessibility isolation on the presenting content.
- `MahjTrainer/Views/FeatureTourView.swift:91-103` and equivalent Feature Tour files present the real session with `fullScreenCover`; the underlying tour remains exposed.
- The same Home and Feature Tour structure exists in Bridge, Skat, Sheepshead, and Cribbage.

Expected behavior: while a sheet or full-screen cover owns the interaction, the presenting content should be hidden from accessibility navigation and should not expose actionable controls.

### FLEET-007, card and tile selection is not represented as an accessible control

Severity: P1

Apps: all five by shared component pattern; direct runtime confirmation in Cribbage

User impact: a user who cannot use direct touch may hear repeated card labels but not receive a clear “selectable card” control, action, or selected-state announcement. This can make the central answer interaction unusable with VoiceOver.

Observed behavior in Cribbage:

- In `Pick Your Discard`, `3 of Diamonds`, `K of Diamonds`, `4 of Hearts`, and `5 of Spades` appeared as repeated `AXStaticText` elements rather than buttons or selectable controls.
- The same card face was exposed multiple times because the outer accessibility label and the child rank, suit, and face text were all present.
- Tapping a card changed the visible count from `Selected 0 of 2` to `Selected 1 of 2`, proving that touch selection works, but the accessibility representation did not change to a clear selected control.
- `Discard These 2` correctly remained disabled until enough cards were selected.

The same source pattern exists in all apps:

- Mahj: `MahjTrainer/Views/Components/TileView.swift:11-22` labels the outer tile, while `TileRackView` around lines 156-191 uses `onTapGesture` for selection.
- Bridge: `Bridge/Views/Components/BridgeCardView.swift:12-29` labels the card, while `BridgeHandView` around lines 32-65 uses `onTapGesture`.
- Skat, Sheepshead, and Cribbage: each `Views/Components/PlayingCardView.swift:11-22` supplies an outer label, while `CardHandView` around lines 62-97 uses `onTapGesture`.

Reproduction:

1. Enter any drill that asks the user to choose cards or tiles.
2. Inspect each card or tile in the accessibility tree.
3. Check for a button or adjustable-control trait, an activation action, and a selected or unselected state.
4. In Cribbage, compare the tree before and after tapping a card.

Expected behavior: each selectable card or tile should be one accessible control with one spoken label, an activation action, and a reliable selected-state announcement. The child face elements should not be separately announced.

### FLEET-005, future flashcards are accessible as if they are current

Severity: P1

Apps: all five by source parity; directly observed in Bridge, Sheepshead, and Cribbage

User impact: the visual deck intentionally shows a few cards stacked behind the current card. For VoiceOver, however, the future cards are not merely visual decoration. They are exposed as separate accessible content, so a player can hear the answer to a later card or believe that multiple questions are available at once.

Observed behavior:

- Bridge exposed `High-card points`, `Which card is highest?`, and `Four suits` simultaneously in the accessibility tree. Only the top card had the `KNEW IT` and `AGAIN` actions.
- Sheepshead exposed `Hold the called suit`, `Protect trump control`, and `Bury two cards`, each with `Tap to reveal`, while only the top card could be interacted with.
- Cribbage exposed multiple future card groups and repeated `Tap to reveal` labels while only the visible top card was active.

Source cause indicator:

- Each `FlashcardDrillView.swift` uses `queue.prefix(3)` around lines 116-141.
- `.allowsHitTesting(slot == 0)` prevents touch interaction with lower cards, but it does not hide those cards from the accessibility tree.
- The deck code adds button traits to the card views but does not make `slot != 0` accessibility-hidden.

Expected behavior: only the current card should be navigable and announced. The lower cards may remain visual decoration, but they should not be exposed as questions or actions until they become current.

### FLEET-002, onboarding escape hatch returns to a shifted Home

Severity: P2

Apps: Skat, Sheepshead, and Cribbage confirmed; not reproduced on the Bridge 440-point device; Mahj takes a different post-onboarding route in this scenario

User impact: the first screen after onboarding is a malformed-looking Home. New players can miss the app title and progress stats, and the Settings gear overlaps the primary Get Started play control. This is especially damaging because the user used the promised “skip” escape hatch and expects a clean landing page.

Observed behavior:

- Skat immediately after skipping the primer: `Skat Trainer` had an accessibility frame beginning at y -34, stats began at y -30, while Settings remained at y 66. The Home subtitle was under the status area. The screenshot showed the gear over or beside the Get Started play control.
- Sheepshead immediately after skipping the primer: `Sheepshead Trainer` began at y -73, stats at y -69, subtitle at y 8, and the Get Started card began at y 40. The Settings gear and play control overlapped.
- Cribbage showed the same shape: `Cribbage Trainer` began at y -74, stats at y -70, subtitle at y 8, and the Get Started card began at y 40.
- Restarting each app returned Home to its normal position, so this is a transition-state bug rather than a permanently invalid layout.

Reproduction:

1. Install one of the affected apps fresh.
2. Complete the onboarding skill choice.
3. Tap the onboarding trial page's soft exit, then skip the primer.
4. Inspect Home before restarting the app.

Source and likely mechanism:

- Each `OnboardingView.swift` calls the finish path directly from the primer escape hatch.
- Each `HomeView.swift` wraps the page in a vertical `ScrollView` and does not explicitly establish a fresh scroll position for this transition.
- The exact retained scroll state is not proven, but the repeatable reset-on-relaunch behavior points to a stale scroll offset or transition geometry state.

Expected behavior: the first Home frame after onboarding should begin at the same top position as a cold launch, with the title, stats, Settings, and Get Started control all visible and non-overlapping.

### FLEET-001, compact Home header collides with the Settings control

Severity: P2

Apps: Mahj confirmed on a 402-point device; shared layout risk exists in all five

User impact: the status chips and Settings gear compete for the same horizontal space. A user may interpret the gear as part of the progress chip or tap the wrong control. This is distinct from the more severe onboarding transition offset in FLEET-002.

Observed behavior in Mahj after one completed Quick Session:

- Settings frame: `{{348.33,66},{31.33,36}}`.
- `1 day streak, 1 drills done` chip frame: `{{284,52.33},{102,30}}`.
- The chip extends through x 386 while the gear occupies x 348 through x 379, so the two controls overlap. The screenshot showed the green completion/checkmark area under the gear.

The 440-point Bridge device did not visibly reproduce the collision, but its Home header uses the same structure and the narrower 402-point layout has less room. Skat, Sheepshead, and Cribbage show the related shifted-header collision immediately after onboarding as described above.

Source:

- The common `HomeView.swift` header around lines 213-259 places the title and stat chips in the main content while the Settings control is supplied by the toolbar.
- The toolbar uses a hidden navigation background, so there is no reserved compact-width layout area that prevents the main content from entering the toolbar region.

Expected behavior: the header should reserve a non-overlapping region for the toolbar, or move the stats below the title on compact widths.

### FLEET-003, Home training carousel hides paid modes without a cue

Severity: P2

Apps: all five

User impact: the Home screen presents Training as if it were a short row of cards, but the horizontal list contains more cards than fit on the screen. A new free user can reasonably assume the visible cards are the whole offering. Mahj+ modes such as Timed Challenge and Fix My Mistakes are especially easy to miss.

Observed behavior:

- On Mahj at 402 points, the first two cards were fully visible and the third was clipped. Timed Challenge and Fix My Mistakes were offscreen at x 434 and x 572 in the accessibility frames.
- On Bridge at 440 points, the first three cards were visible and Timed Challenge began offscreen at x 434.
- Skat, Sheepshead, and Cribbage exposed the same offscreen training cards in the accessibility tree.
- The visual scroll indicators are disabled. There is no chevron, page dot, “swipe for more” text, or visible partial card that reliably signals the full list on every device.

Source:

- The common `HomeView.swift` training section around lines 357-385 uses `ScrollView(.horizontal, showsIndicators: false)`.

Expected behavior: the page should communicate that more training exists and should make the next card discoverable without relying on an unprompted horizontal swipe.

### FLEET-006, offscreen onboarding pages remain in accessibility navigation

Severity: P2

Apps: all five, directly observed in Bridge, Skat, Sheepshead, and Cribbage, with the same Mahj source structure

User impact: a user navigating onboarding with VoiceOver encounters controls from future pages before they are visible. This makes the onboarding order difficult to understand and can create apparent disabled controls or duplicate legal links.

Observed behavior:

- On the first onboarding page, the accessibility tree contained trial-page controls such as `Get Started`, Terms, Privacy, Restore, and a loading price label.
- The controls were generally offscreen or disabled, but their labels remained in the navigation surface.
- The visual page itself was clean, so this is an accessibility-state mismatch rather than a normal visual carousel affordance.

Source:

- Each `OnboardingView.swift` builds a `TabView` containing all onboarding pages around lines 48-70.
- The implementation does not hide non-current pages from accessibility navigation.

Expected behavior: only the current onboarding page and its intentional page-level context should be exposed. Future pages should become accessible when selected.

### FLEET-008, Timed Challenge starts before the player is ready

Severity: P2

Apps: all five by source parity; timing behavior observed in Mahj

User impact: the advertised 90-second challenge starts consuming time while the player is reading the instructions, understanding the scoring, or waiting for the first question to settle. A player who enters the mode for the first time is penalized for orientation rather than answer quality.

Observed behavior in Mahj:

- The Timed Challenge screen initially showed 90 seconds.
- After a short period spent inspecting the screen and preparing the first answer, it showed 76 seconds.
- There was no “Ready”, “Start”, or brief rules screen separating orientation from scored time.

Source:

- `PracticeRunView.swift` initializes `secondsRemaining = 90` around line 44.
- The view starts `runClock()` in a `.task` around line 152, so the countdown begins as soon as the view is presented.
- The same practice-run structure is present in all five apps.

This is a usability risk, not a confirmed decrement or persistence bug. The requested 90 seconds may be technically correct once the screen appears, but the user does not receive a meaningful ready state.

Expected behavior: provide a short ready state or explicitly state that the clock starts on entry, then make the first scored interaction available immediately.

### PAY-001, compact paywall footer covers the lowest plan

Severity: P2

Apps: Mahj and Skat confirmed; not reproduced in Bridge, Sheepshead, or Cribbage on the tested devices

User impact: the lowest plan is visible enough to appear selectable, but its lower details can be hidden behind the sticky purchase footer. Users cannot compare all plan terms in the same way before deciding.

Observed behavior in Mahj at 402 points:

- The monthly plan was the lowest card in the scroll view.
- Its card frame extended into the area occupied by the sticky footer. The monthly heading and price were visible, but lower card details were obscured.
- The footer contained the auto-renew terms and primary CTA, which reduced the available viewport further.

Observed behavior in Skat at 402 points:

- The monthly plan occupied approximately y 614 through 712.
- The sticky footer began around y 668 and extended to the CTA near y 745, covering the lower portion of the monthly card.
- Long German strings made the collision easier to see.

The Bridge, Sheepshead, and Cribbage paywalls showed all three plan cards without this specific visual occlusion at the tested sizes, but they use the same scroll-plus-sticky-footer pattern.

Source:

- The paywall content uses a vertical `ScrollView` with a `.safeAreaInset(edge: .bottom)` sticky footer around lines 158-195 in Mahj and Bridge, with equivalent code in the other apps.

Expected behavior: the scroll content should include enough bottom inset for the entire last plan card to scroll above the footer, and the current plan selection should remain fully readable.

### SKAT-002, unavailable product prices leave an enabled purchase path with no amount

Severity: P1

App: Skat

User impact: a player reaches the purchase screen and cannot see what any plan costs. The primary purchase CTA remains enabled, creating uncertainty about whether an amount will be shown later or whether the user is about to confirm an unreviewed charge.

Observed behavior:

- On the Skat paywall, after waiting more than five seconds, yearly, lifetime, and monthly cards all still displayed `Preis wird geladen ...`.
- The paywall remained otherwise interactive, including the primary purchase CTA.
- There was no visible retry, product-unavailable explanation, disabled purchase state, or fallback pricing.

Source:

- `SkatTrainer/Views/PaywallView.swift:123-150` intentionally renders the loading placeholder when product data is absent instead of supplying a bounded error state.

The simulator does not prove that production StoreKit or RevenueCat will fail in the same way. It does prove that product unavailability is a user-facing state with no safe resolution. This should be tested with a controlled product outage or network failure before release.

Expected behavior: do not offer an apparently ready purchase without a price. Show a bounded loading state, retry, a clear unavailable state, or a product-failed fallback that preserves the required legal and restore controls.

### SKAT-001, German experience contains large English sections

Severity: P2

App: Skat

User impact: onboarding, the core free drills, and the paywall are mostly German, so a German-speaking player reasonably expects the recurring member features to be German too. The mixed language reduces comprehension and makes Mahj+ feel unfinished.

Observed examples on Home and in member surfaces:

- Home showed `Game Night Prep` alongside German room labels.
- Badges appeared as `Daily` and `Weekly` beside German copy.
- The Skat Minute screen used `Today's Skat-Minute`, `View Today's Challenge`, `Start Today's Challenge`, `YOUR WEEK`, and English status text.
- Game Night Prep used `Start My Five-Minute Prep`, `Open Settings`, `Not now`, `WEEKLY REMINDER`, `Prep is scheduled`, and English notification copy.

Source examples:

- `SkatTrainer/Views/GameNightPrepView.swift` around lines 27, 38, 43-59, and 74-97.
- `SkatTrainer/Views/SkatMinuteView.swift` around lines 35, 48, 54, 67-71, 93-104, 139, 177, and 217.

Expected behavior: all user-visible strings in the German app should use one consistent locale, including recurring practice, notification copy, badges, empty states, and settings handoffs.

### MAH-002, public price and membership naming drift

Severity: P2

App: Mahj

User impact: a player can see different prices and product names depending on whether they are in the app, reading the website, opening the Terms page, or viewing an Apple purchase confirmation. That creates purchase hesitation and legal copy inconsistency.

Current in-app and store-facing source:

- Mahj+ uses the current prices of $4.99 monthly, $19.99 yearly, and $49.99 lifetime in the StoreKit configuration and current app fallback surfaces.
- Fastlane metadata has the current prices.
- The in-app membership label is `Mahj+`.

Stale or inconsistent surfaces:

- `docs/index.html:616` still advertises $1.99/month, $9.99/year, and $29.99 once.
- `docs/terms.html:19` still says `Mahj Trainer Pro`.
- `MahjTrainer/MahjTrainer.storekit` still uses display names such as `Mahj Trainer Pro Lifetime`, `Mahj Trainer Pro Monthly`, and `Mahj Trainer Pro Yearly`, with `Pro` reference names.

The pricing increase task identifies the new prices as intentional, so the old website prices are stale rather than an unresolved pricing choice. The StoreKit display names may also surface in purchase confirmation or testing tools, so the retired player-facing word should be reviewed there.

Expected behavior: the app, website, Terms, privacy and purchase surfaces should use the same current prices and Mahj+ name, while retaining any required entitlement identifier internally.

### MAH-001, primer Previous button is clipped on one compact iOS configuration

Severity: P3

App: Mahj

User impact: on the second primer page, the Back affordance is partly outside the screen. A new player can still continue, but going back is visually broken and the clipped label can make the navigation row look malformed.

Observed behavior:

- Device: iPhone 17 Pro at 402 points, iOS 27.
- On primer page 2, the Previous button accessibility frame began at x -2 with width 56.
- The visual screenshot showed the left edge of the button clipped. Continue remained visible.
- The same primer row was not clipped on the tested iPad or on the Bridge 440-point device.

Source:

- `MahjTrainer/Views/HowToPlayView.swift` uses a fixed 56-point Previous button in the footer HStack.

Expected behavior: the Back control should remain fully inside the safe horizontal area on all supported compact devices and OS versions.

## Per-app user journey notes

### Mahj

What worked well:

- The fresh onboarding sequence clearly explains the product as training and separates the skill choice from the trial decision.
- The new-player escape hatches are easy to find. Skipping the primer still reaches Home, and the feature-tour finale runs a real Quick Session rather than a static demonstration.
- The free beginner rooms are understandable, and the room-specific drill cards make the product read as a training lobby rather than a generic flashcard list.
- Mahj+ Endless Practice, Fix My Mistakes, and Timed Challenge were reachable in member state. The generated practice and review flows did not show a sampled functional failure.
- The 11-inch iPad portrait Home layout was strong in the tested state. Title, stats, Get Started, How to Play, training cards, room grid, and Settings remained readable without overlap or clipping.
- Settings, haptics and sound choices, and the notification permission path were understandable in the sampled flow.

Issues to carry forward:

- FLEET-001, FLEET-003, FLEET-004, FLEET-005, FLEET-006, FLEET-007, and FLEET-008.
- MAH-001 and MAH-002.
- The 13-inch App Store screenshot configuration was not exercised in this audit. The 11-inch runtime spot check does not prove the 13-inch capture path.

### Bridge

What worked well:

- The fresh onboarding and Bridge+ trial page were coherent in English.
- The Card Room clearly separated the free `Meet the Game` flashcards from `Card Check` and the locked extra set.
- The paywall loaded readable prices and required legal, restore, and auto-renew language on the tested device.
- The first full test run had environment noise, but a complete rerun passed all 51 tests.

Issues to carry forward:

- FLEET-003 and FLEET-004 were directly reproduced.
- FLEET-005 was directly reproduced in the card flashcard deck.
- FLEET-006 and FLEET-007 are present by source parity and should be checked with VoiceOver.
- The compact header collision was not visible at 440 points, but the shared layout should be checked at 402 points.

### Skat

What worked well:

- German onboarding, skill labels, primer, free room names, and the sampled discard flow were internally understandable.
- The room locked-set explanation communicated that the extra content required Skat+.

Issues to carry forward:

- FLEET-002 was directly reproduced after the primer skip.
- FLEET-003, FLEET-004, FLEET-006, FLEET-007, and FLEET-008 are present by shared structure, with FLEET-003 visible in the training list.
- PAY-001 was directly reproduced.
- SKAT-001 is a broad localization defect across two core recurring features.
- SKAT-002 is a purchase-safety and conversion defect whenever products are unavailable.
- The daily-content test had one failure in the full run, then passed in isolation. This should still be monitored for real flakiness, but it is not counted as a confirmed user bug here.

### Sheepshead

What worked well:

- The onboarding voice and skill choices were easy to understand in English.
- The Bury room made the progression from `Bury Playbook` to `Choose Your Bury` clear.
- The locked extra and Mahj+ upsell were visible without hiding the free drills.
- The paywall loaded all three prices and legal controls in the tested state.

Issues to carry forward:

- FLEET-002 was directly reproduced after skipping the primer.
- FLEET-003 is present in the Home training carousel.
- FLEET-005 was directly reproduced in the Bury flashcard deck.
- FLEET-004, FLEET-006, FLEET-007, and FLEET-008 are present by shared structure and should receive the same fleet fix.

### Cribbage

What worked well:

- The onboarding, Discard Room, and `Pick Your Discard` prompt were visually clear.
- Touch selection worked, the selected count updated, and the discard action remained disabled until two cards were selected.
- The paywall loaded readable prices, Restore, Terms of Use, Privacy Policy, and the auto-renew copy in the tested state.

Issues to carry forward:

- FLEET-002 was directly reproduced after skipping the primer.
- FLEET-003 is present in the Home training carousel.
- FLEET-005 was directly reproduced in the discard flashcard deck.
- FLEET-007 was directly reproduced in the card picker. Touch works, but the accessibility representation is not a selectable control.
- FLEET-004, FLEET-006, and FLEET-008 are present by shared structure and should receive the same fleet fix.

## Cross-app recurrence matrix

| Finding | Mahj | Bridge | Skat | Sheepshead | Cribbage |
| --- | --- | --- | --- | --- | --- |
| FLEET-001 compact header collision | Confirmed at 402 points | Shared source, not seen at 440 points | Related transition collision | Related transition collision | Related transition collision |
| FLEET-002 post-onboarding Home offset | Not observed on this route | Not observed at 440 points | Confirmed | Confirmed | Confirmed |
| FLEET-003 hidden training carousel | Confirmed | Confirmed | Confirmed | Confirmed | Confirmed |
| FLEET-004 modal accessibility isolation | Confirmed in Feature Tour and Settings | Confirmed in paywall | Shared source | Shared source | Shared source |
| FLEET-005 stacked deck exposure | Shared source | Confirmed | Shared source | Confirmed | Confirmed |
| FLEET-006 offscreen onboarding AX content | Shared source | Confirmed | Confirmed | Confirmed | Confirmed |
| FLEET-007 card or tile semantics | Shared source | Shared source | Shared source | Shared source | Confirmed in card picker |
| FLEET-008 timer starts immediately | Confirmed | Shared source | Shared source | Shared source | Shared source |
| PAY-001 plan occlusion | Confirmed | Not seen | Confirmed | Not seen | Not seen |
| Unavailable product price state | Existing fallback path observed as available prices | Available prices | Confirmed loading failure mode | Available prices | Available prices |
| Locale drift | None observed in sampled English flow | None observed | Confirmed German and English mix | None observed | None observed |
| Public price or membership drift | Confirmed | None observed | None observed | None observed | None observed |
| Primer navigation clipping | Confirmed on one Mahj device and OS | Not seen | Not seen | Not seen | Not seen |

The source recurrence means a single fix can improve several apps, but runtime validation is still needed per app because the same component can be affected differently by local copy length, device width, or product availability.

## Recommended handoff order

1. Treat FLEET-004, FLEET-005, and FLEET-007 as one accessibility pass. Verify with actual VoiceOver, not only the accessibility tree: isolate presented surfaces, expose only the current flashcard, make card and tile picks actionable, and announce selection state once.
2. Add compact-device UI coverage for the onboarding escape hatch and Home at 402 points. FLEET-002 should be fixed before optimizing general Home spacing because it damages the first post-onboarding screen.
3. Make the full Training offering discoverable. The paid modes should not depend on an invisible horizontal swipe.
4. Repair paywall geometry so every plan can scroll fully above the sticky footer. Add a controlled product-unavailable path, especially for Skat, and keep the amount visible before purchase.
5. Finish Skat localization for Skat Minute, Game Night Prep, badges, notification copy, settings handoffs, and empty states.
6. Reconcile Mahj website, Terms, StoreKit display names, App Store metadata, and in-app prices under the Mahj+ naming and current price decision.
7. Add regression coverage for accessibility tree isolation, 402-point Home geometry, onboarding page visibility, flashcard stack visibility, card selection traits, paywall last-card visibility, and Timed Challenge's ready state.

## Evidence index

Runtime screenshots captured during the audit included:

- `/tmp/laudit89/mahj-home-after-tour.png`
- `/tmp/laudit89/mahj-primer-2.png`
- `/tmp/laudit89/mahj-paywall.png`
- `/tmp/laudit89/mahj-ipad-next.png`
- `/tmp/laudit89/bridge-home.png`
- `/tmp/laudit89/bridge-paywall.png`
- `/tmp/laudit89/bridge-card-drill.png`
- `/tmp/laudit89/skat-home.png`
- `/tmp/laudit89/skat-paywall.png`
- `/tmp/laudit89/sheepshead-home.png`
- `/tmp/laudit89/cribbage-home.png`
- `/tmp/laudit89/cribbage-fresh.png`

These are temporary local artifacts and are not part of the handoff commit. The source paths and accessibility frames in each finding are the durable evidence for another agent to reproduce the issues.

## Verification note

Success criterion: `laudit89.md` contains reproducible, severity-ranked, persona-oriented UX findings for Mahj, Bridge, Skat, Sheepshead, and Cribbage, including cross-app recurrence and evidence, with no product code changes.

The audit was written after the five app builds and runtime passes. No fix was applied. The document is the only task-owned file to commit.
