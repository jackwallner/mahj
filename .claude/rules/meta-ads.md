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
- ATT is asked by `HomeView.askForTrackingIfNeeded`: onboarded, at least one
  finished practice of the player's own after the tour
  (`progress.hasPracticedSinceOnboarding`, build 56; Jack 2026-10-16: asking
  before the player has used the app spooks people), bare Home,
  1.2s settle, re-asked whenever Home is bare again (a sheet closes, a pushed
  screen pops, the offering arrives). Bare means `HomeView.homeIsBare`: Home
  on screen, nothing pushed (a deep-linked challenge counts), no sheet. Never in a
  launch that showed What's New (`WhatsNew.shownThisLaunch`, Jack
  2026-10-18): updaters already have practices, so it waits a launch. It
  also waits for `remoteConfigKnown`, or `att_prompt: off` could not stop a
  cold launch, which asks before the offering loads. Never move it
  to launch or onboarding. `askApple()` stays `nonisolated` (ATT answers off
  the main queue, which traps a main-actor closure under Swift 6). It also
  needs `subscriptions.isOn(.attPrompt)`: offering metadata `att_prompt: off`
  (set on every offering) pauses it without a release.
- StartTrial belongs to `supabase/functions/meta-trial-relay`, never to
  RevenueCat's Meta integration: RevenueCat cannot hold an event 15 minutes.
  If the RC integration ever sends StartTrial, the filter is defeated.
- Relay failures (2026-10-16): a network error, 429 or 5xx from RevenueCat
  or Meta is `Transient`: the row stays `pending`, `attempts` goes up and
  `retry_at` holds it (2, 4, 8 ... capped at 60 min); the 8th gives up as
  `error`. Any other 4xx is `error` at once. Before this, one blip dropped the
  trial's StartTrial for good. Retries resend the same `event_id`, which Meta
  deduplicates. Apply `20261016120000_meta_trial_relay_retries.sql` BEFORE
  deploying the function (it selects the new columns). Test:
  `deno test -A supabase/functions/meta-trial-relay` (all network faked).
- The in-app 50/50 `CTAExperiment` was removed in build 47: it had no
  control arm and needed a release to change. The wording is now `TrialCTA`,
  picked by offering metadata `trial_cta` (see `membership-and-trial.md`).
- `MetaAds.isEnabled` is false on a simulator (the SDK never starts there,
  and the ATT alert would land in every screenshot run); captures opt in
  with `-mahj.previewMetaATT`.
- `MetaAds.extinfo` leaves the two storage slots empty: disk space is an
  Apple required-reason API, and no listed reason covers sending it to an ad
  network.
- Captures: `testTrialPageVariants` pins every non-control trial page
  variant at once with `-mahj.rc.<key>` and checks each one renders.
- Captures: `scripts/capture-meta-cta.sh <udid> <out-dir>` (reinstalls, every
  `TrialCTA` wording on both surfaces, ATT timing, `checks_*` PASS/FAIL attachments).
