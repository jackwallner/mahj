# Pre-submit code review, 1.4.4 (build 84), 2026-11-08

Branch `review/2026-11-08-mahj-deep` from `origin/main` at `47a4fa0`.

## Scope

- Live version: 1.4.2 (build 71). 1.4.3 was rejected on 2026-11-07 under
  5.1.2(i) and never went live, so the diff base is the 1.4.2 tip
  (`289ffc7^`), not the 1.4.3 bump. That covers 1.4.3 (Meta SDK and ATT
  removed, Arabic, trial page and trial sheet fit fixes, Home Training row,
  pitch headline for accounts without a free week, Reset Progress fixes) and
  1.4.4 (PostHog analytics with a Settings opt-out, reminder reconcile against
  iOS permission, `lapseConfirmed` for the game night reminder, the all-access
  weekly gain ledger, the router's no-op publish guard).
- Deep pass over everything a player can reach on `origin/main`: purchase,
  restore, preflight and recovery gates (`SubscriptionService`, `PaywallView`,
  `OnboardingView`, `TrialOfferSheet`), onboarding branch and escape hatches,
  every UserDefaults store and its decode path, local notifications (daily,
  game night, monthly challenge, trial end), deep links and notification
  routes, iPhone Duo panes, localization catalogs, and the drill, challenge,
  hand play and generator code for crashes.
- Code read only. No simulator and no local `xcodebuild`, as instructed.

## Checks that came back clean

- Every format specifier in all 700 `Localizable` and 1,200 `Content` keys
  matches its translation in all six languages (ar, de, es, fr, id, vi):
  same positions and types, no mixed positional and plain specifiers, no stray
  `%`. That is the crash class the Arabic commit fixed in
  `CharlestonGenerator.note`. No key is missing a language.
- No force unwraps, `try!`, `.first!` or `randomElement()!` in app code. Every
  array index in the drill views, generators and challenge views is guarded;
  every generator loop is bounded or always makes progress.
- No placeholder, debug or other-platform UI reachable in Release: `DebugShot`,
  `RevenueCatProbe`, the local Pro override and the `-ChallengeMonth` and
  `-mahj.standing` pins are all inside `#if DEBUG`. No hard-coded prices; every
  price comes from StoreKit. No health claims.
- Paywall, onboarding trial page and trial sheet all carry the membership
  name, the StoreKit price, `PaywallPricing.terms`, Restore, Terms and Privacy.
  Purchase, cancel, redraw, no-product, already-member and restore paths
  dismiss or stay put as `.claude/rules/membership-and-trial.md` describes.
- PostHog persists a Settings opt-out across launches (`persistOptOut`
  defaults to true in posthog-ios 3.93), session replay and text capture are
  off, and the feedback box is never captured.

## Findings

| # | Severity | Where | What happens | Status |
|---|---|---|---|---|
| 1 | P2 | `Shared/Services/SubscriptionService.swift:431` | `setPostHogUserID` is sent to RevenueCat at every configure, whatever `Share Usage Data` says. A player who turns sharing off still gets RevenueCat's server-side `rc_*` trial and renewal events joined to their PostHog person, if the RevenueCat PostHog integration is on. | Not fixed: whether the toggle covers RevenueCat's server events is a product and privacy-label call for Jack. If it should, skip the call (or set the attribute to empty) while sharing is off. |
| 2 | P2 | `MahjTrainer/` (no `PrivacyInfo.xcprivacy`) | The app target has no privacy manifest, so its UserDefaults use (required-reason API, CA92.1) is undeclared. Uploads still pass (every build through 1.4.2 shipped this way), but ASC can send ITMS-91053 warnings. | Not fixed: not broken, and a new bundled resource is a packaging change beyond this review. |
| 3 | P2 | `Shared/Services/AppSettings.swift:276` | `reconcileReminders` reads the permission status before hopping back to the main actor. If a return to the app reads "not determined" just before the player's Allow lands and the in-flight count has already dropped, a reminder they just turned on could switch itself off. The window is a few milliseconds and was not reproduced. | Not fixed: not shown to happen. |
| 4 | P2 | `MahjTrainer/Views/Components/TileView.swift:272`, `MahjTrainer/Views/Drills/FlashcardDrillView.swift:321` | Arabic (new in 1.4.3) runs right to left and nothing pins `layoutDirection`, so tile racks, runs and the swipe deck lay out mirrored. Whether a mirrored run and the swipe direction read correctly to an Arabic player was not checked on screen. | Not fixed: needs an Arabic capture (`gh-sim all --screen "-AppleLanguages (ar)"`) before anyone decides on a change. |
| 5 | P2 | `Shared/Services/PracticeRecordStore.swift:57` (also `MahjMinuteStore`, `MonthlyChallengeStore`, `OrdinaryRunStore`, `HandPlayStore`, `MasteryLedger`) | Each store decodes with `try?`, falls back to empty and overwrites the saved data on the next write. Every shape shipped so far still decodes (fields added since are optional, and the challenge moved to a new key when it changed), so nobody loses data today; a future non-optional field would wipe that store's history. | Not fixed: latent, nothing broken now. |

No P0 or P1 issue was found, so no code changed and no regression test was
added.

## Tests

Unit suite (`MahjTrainerTests`) run on GitHub's Macs with `gh-sim test`,
skipping `TrialEligibilityTests/testFreeWeekUntilTheAccountHasUsedIt`, which
hangs on the iOS 27 runtimes (`.claude/rules/localization.md`). Result in the
commit that adds this line's run id.
