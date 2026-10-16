---
paths:
  - "Shared/Services/MetaAds.swift"
  - "Shared/Services/RemoteConfig.swift"
  - "supabase/**"
  - "MahjTrainer/Views/HomeView.swift"
  - "MahjTrainerScreenshots/MetaAndCTARenderTests.swift"
  - "project-docs/marketing/meta-ads.md"
---

# Mahj: Meta ads prep and the trial button wording (2026-10-15)

Full write-up: `project-docs/marketing/meta-ads.md`.

- `MetaAds` is inert until `META_APP_ID` and `META_CLIENT_TOKEN` are set in
  `project.yml`: no SDK start, no ATT prompt. Never start the SDK on a
  simulator. Change the App Store privacy labels in the same submission that
  sets the ids, never before (labels that declare tracking with no ATT prompt
  invite a 5.1.2 rejection).
- Meta's SDK must get `ApplicationDelegate.application(_:didFinishLaunching...)`
  before any other call, so `MetaAds.start` sits in `AppDelegate`, and
  `linkRevenueCat()` runs right after `Purchases.configure`.
- ATT is asked by `HomeView.askForTrackingIfNeeded`: onboarded, bare Home,
  1.2s settle, re-asked on What's New or churn-sheet dismissal. Never move it
  to launch or onboarding. `askApple()` stays `nonisolated` (ATT answers off
  the main queue, which traps a main-actor closure under Swift 6). It also
  needs `subscriptions.isOn(.attPrompt)`: offering metadata `att_prompt: off`
  (set on every offering) pauses it without a release.
- StartTrial belongs to `supabase/functions/meta-trial-relay`, never to
  RevenueCat's Meta integration: RevenueCat cannot hold an event 15 minutes.
  If the RC integration ever sends StartTrial, the filter is defeated.
- The in-app 50/50 `CTAExperiment` was removed in build 47: it had no
  control arm and needed a release to change. The wording is now `TrialCTA`,
  picked by offering metadata `trial_cta` (see `membership-and-trial.md`).
- Captures: `testTrialPageVariants` pins every non-control trial page
  variant at once with `-mahj.rc.<key>` and checks each one renders.
- Captures: `scripts/capture-meta-cta.sh <udid> <out-dir>` (reinstalls, every
  `TrialCTA` wording on both surfaces, ATT timing, `checks_*` PASS/FAIL attachments).
