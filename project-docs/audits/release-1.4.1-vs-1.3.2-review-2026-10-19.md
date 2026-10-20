# Mahj 1.4.1 vs 1.3.2 release review

Baseline: `eaf14d5` (1.3.2, build 37). Candidate fetched at start: `371153b`.
During the audit, `origin/main` advanced to `230468e`; the only change was the
build number in `project.yml` from 61 to 62. App source stayed the same.

## Findings

### Blocker

1. **The November event promises a different daily challenge.**
   `project-docs/marketing/in-app-events/2026-11-challenge/event.json:14-15`
   says there are three new Charleston questions each day. The App Review notes
   also say three questions a day at
   `fastlane/metadata/review_information/notes.txt:23`. In the app, each round
   has five questions: two on the month's theme, one from another skill, then
   two Table Room calls (`Shared/Content/MonthlyChallengeContent.swift:277-294`).
   A player arriving from the event gets a different round than the listing
   promises, and App Review can reject the event as misleading under 2.3.
   Update the event copy and review notes to describe the five-question round
   and its Charleston focus accurately.

### Should fix

1. **The one-tap sheet promises a free week to accounts that may not qualify.**
   `MahjTrainer/Views/Components/TrialOfferSheet.swift:110` says “Try Mahj+ free
   for 7 days,” and line 124 uses shared terms that always say “7 days free.”
   The new sheet is offered to every non-member after a good result, including
   players who may already have used an introductory offer. The purchase path
   does not check eligibility before calling StoreKit at
   `MahjTrainer/Views/Components/TrialOfferSheet.swift:224-235`. Apple limits
   introductory offers to eligible customers in the subscription group and
   documents checking eligibility before presenting the offer
   ([Apple introductory offers](https://developer.apple.com/documentation/storekit/implementing-introductory-offers-in-your-app)).
   An ineligible player can be charged immediately after seeing a free-trial
   claim. Check eligibility for this new sheet and present accurate paid-plan
   terms when no introductory offer is available.

2. **A slow reinstall recovery can finish after a new purchase begins.**
   `Shared/Services/SubscriptionService.swift:117-123` waits at most three
   seconds for an existing StoreKit recovery task, then returns even if the
   task is still running. `MahjTrainer/Views/Components/TrialOfferSheet.swift:228-235`
   continues to `purchase` after that return and only checks `isPro`. A
   reinstalled member whose lifetime or subscription entitlement takes longer
   to sync can reach Apple's purchase sheet as a non-member. Keep the purchase
   disabled until recovery resolves, or fail closed with a retry/Restore path.

3. **Returning players skip the new trial-offer practice threshold.**
   `Shared/Services/ProgressStore.swift:42-46` returns zero when the new
   `sessionsAtOnboarding` key is absent, and its comment confirms that 1.3.2
   installs have no value. `MahjTrainer/Views/Components/TrialOfferSheet.swift:319-323`
   subtracts that zero from the lifetime session count. The 1.3.2 tour's closing
   practice is included in that count, so a player who has not practiced after
   the tour reaches the two-practice threshold on their first actual practice
   after updating. Record a separate offer baseline for already-onboarded
   installs, or exclude the tour session before checking eligibility.

### Nit

1. **The Home stat chips stay in one row at large text sizes.**
   `MahjTrainer/Views/HomeView.swift:417-427` keeps the streak, drills, and
   weekly-gain chips in one `HStack`. On a narrow phone at accessibility text
   sizes, the third chip can run into the edge or compress the other values.
   Let the chips wrap or move the weekly-gain chip to its own row at those
   sizes.

2. **The month grid scales ten day cells without reflowing them.**
   `MahjTrainer/Views/MonthlyChallengeView.swift:304-317` scales each cell with
   Dynamic Type but always lays out ten cells in one row. At the largest text
   size on a small iPhone, the row can exceed the card width and hide days.
   Reduce the column count or cap cell size at accessibility sizes.

3. **The new offer's “Not now” target is 36pt high.**
   `MahjTrainer/Views/Components/TrialOfferSheet.swift:142-146` sets a minimum
   height of 36pt, and the Home game-night dismiss control is 32 by 32pt at
   `MahjTrainer/Views/HomeView.swift:698-705`. Both can be hard to tap for
   players with larger fingers or motor accessibility needs. Give each control
   a 44pt hit area, as [Apple's button guidance recommends](https://developer.apple.com/design/human-interface-guidelines/buttons).

4. **VoiceOver calls exposed tiles a rack in challenge answer review.**
   `MahjTrainer/Views/MonthlyChallengeView.swift:679-685` labels every tile
   group “Rack,” including defense questions where the tiles are another
   player's exposed pungs. VoiceOver users get a misleading description.
   Choose “Exposed tiles” for defense items and “Rack” for rack-reading items.

5. **VoiceOver may miss feedback send results.**
   `MahjTrainer/Views/ReviewPromptSheet.swift:243-259` replaces the form with a
   sent, queued, or failed state but does not move accessibility focus or
   announce the result. A VoiceOver user may remain on the removed Send button
   without hearing whether the message went through. Announce the status or
   move focus to its message.

6. **The Meta relay treats a temporary cancellation as final.**
   `supabase/functions/meta-trial-relay/index.ts:108-115` marks a pending trial
   cancelled on a `CANCELLATION` event, and line 170 returns that state before
   rechecking RevenueCat. There is no `UNCANCELLATION` handler to clear it. A
   player who turns renewal off and back on during the 15-minute hold still has
   an active trial, but Meta never receives `StartTrial`, so conversion
   attribution is understated. Clear the cancellation on `UNCANCELLATION`, or
   recheck the current RevenueCat subscription before dropping the event.

## Checked and found fine

- The onboarding trial CTA, monthly plan, price disclosure, Restore, Terms,
  Privacy, purchase cancellation, and purchase-to-tour path match the frozen
  flow. The benefit wording reflects the approved change for Mahj Minute
  becoming free; RevenueCat variants fall back to the 1.3.2 control.
- Paywall, onboarding, and one-tap trial sheet show a live price, billing period,
  renewal terms, Restore, Terms, and Privacy. The tracking usage description is
  present, and ATT is requested only on a bare Home after a purchase or trial.
- Room drill access still uses `Room.isLocked`. The monthly challenge is free,
  its `mahj://challenge` route is guarded by the remote switch, and saved daily
  rounds resume without resetting answers.
- The native rating prompt has no sentiment gate and is separate from feedback.
  What's New selects the 1.4.1 notes for players updating from 1.3.2 and does
  not show them again after a 1.4.2 build bump.
- Content tests cover rack and pass structure, tile counts, challenge question
  validity, and em-dash-free copy. A source scan found no em dashes in app copy.

## Verification and scope

- `gh-sim test`: passed, 247 passed, 0 failed, 1 skipped, on GitHub Xcode 27.1
  with iPhone 17 / iOS 27.
- The `Screenshots`-scheme ChallengeSwitchTests run on iPhone 17e remained in
  progress after 15 minutes. No UI test result is claimed. The full large-text
  and iPad capture sweep was not rerun; `LayoutSweepTests` was reviewed for
  coverage.
- Live App Store Connect privacy labels and live RevenueCat offering metadata
  were not inspected, as the brief prohibits App Store Connect and RevenueCat
  access.
