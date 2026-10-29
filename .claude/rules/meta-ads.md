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

**Removed in 1.4.3 (2026-10-29, Jack: Meta ads are not viable for this
app).** The Meta SDK, `MetaAds`, the ATT prompt and its `att_prompt`
switch, `NSUserTrackingUsageDescription`, the Facebook Info.plist keys and
Meta's SKAdNetwork ids are gone; RevenueCat keeps Apple Ads attribution
(AdServices, no prompt). App Privacy labels (2026-10-29, before the 1.4.3
submission): Advertising Data, Device ID, Coarse Location, Crash Data and
Other Data removed (Meta-only); Purchase History (App Functionality,
Analytics) and Product Interaction (Analytics) stay linked, not tracking.
Product Interaction is still marked tracking: App Store Connect answers
409 to clearing the last tracking entry while a live binary contains
`NSUserTrackingUsageDescription` (1.4.2's build 71 does), and the 1.4.3
review notes say so. Clear it the day 1.4.3 is released (App Privacy >
Product Interaction > Edit > No, we do not use ... for tracking >
Publish). The `meta-trial-relay` RevenueCat webhook can be switched off.
Everything below is history.

Full write-up: `project-docs/marketing/meta-ads.md`.

- `MetaAds` is inert until `META_APP_ID` and `META_CLIENT_TOKEN` are set in
  `project.yml`: no SDK start, no ATT prompt. Never start the SDK on a
  simulator. Change the App Store privacy labels in the same submission that
  sets the ids, never before (labels that declare tracking with no ATT prompt
  invite a 5.1.2 rejection).
- Meta's SDK must get `ApplicationDelegate.application(_:didFinishLaunching...)`
  before any other call, so `MetaAds.start` sits in `AppDelegate`, and
  `linkRevenueCat()` runs right after `Purchases.configure`.
- ATT is asked only after a trial start or a purchase (Jack 2026-10-19),
  so only paying players are prompted and the relay can count a consented
  trial within its 15 minutes. In the first three days of 1.4.1 none of 16
  trials qualified (9 no_consent, 3 cancelled, 4 waiting) under the old
  after-first-practice ask. `SubscriptionService.purchase` calls
  `MetaAds.notePurchase()` on every completed purchase (onboarding page,
  paywall, result trial sheet), which stores `meta.askAfterPurchase`;
  `HomeView.askForTrackingIfNeeded` asks on the next bare Home and
  `requestTracking` clears the flag and calls `collectDeviceIdentifiers()`
  so RevenueCat has the answer fast. A player who never starts a trial or
  buys never sees the prompt. Guards kept: onboarded, bare Home
  (`HomeView.homeIsBare`: Home on screen, nothing pushed, no sheet), 1.2s
  settle, re-asked whenever Home is bare again, never in a launch that
  showed What's New (`WhatsNew.shownThisLaunch`), waits for
  `remoteConfigKnown` and needs `subscriptions.isOn(.attPrompt)` (offering
  metadata `att_prompt: off` pauses it without a release). Never at launch
  or in onboarding. `askApple()` stays `nonisolated` (ATT answers off the
  main queue, which traps a main-actor closure under Swift 6).
- StartTrial belongs to `supabase/functions/meta-trial-relay`, never to
  RevenueCat's Meta integration: RevenueCat cannot hold an event 15 minutes.
  If the RC integration ever sends StartTrial, the filter is defeated.
- The relay can also serve the four card trainers (`APPS` in `index.ts`,
  `?app=<key>`, `app` column), but it is switched off for them (Jack
  2026-10-21: no Meta outside Mahj yet): no webhooks, no secrets. Steps to
  turn one on are in `project-docs/marketing/meta-ads.md`.
- A webhook CANCELLATION is not final (2026-10-19, Luna review): at the
  15-minute mark `decide` always rechecks RevenueCat, so a player who turns
  renewal off and back on inside the hold is sent, and one still off is
  `cancelled`. `cancelled_at` stays on the row as a record. Jack kept the
  hold at 15 minutes (a longer one would also catch same-day cancellers but
  delays Meta's signal). Deployed as version 7.
- Relay failures (2026-10-16): a network error, 429 or 5xx from RevenueCat
  or Meta is `Transient`: the row stays `pending`, `attempts` goes up and
  `retry_at` holds it (2, 4, 8 ... capped at 60 min); the 8th gives up as
  `error`. Any other 4xx is `error` at once. Before this, one blip dropped the
  trial's StartTrial for good. Retries resend the same `event_id`, which Meta
  deduplicates. Apply `20261016120000_meta_trial_relay_retries.sql` BEFORE
  deploying the function (it selects the new columns). It was not, and every
  sweep returned 500 from 2026-10-20 to 2026-10-27 (35 trials stuck
  `pending`, nothing sent) until it was applied. Health check: rows with
  `checked_at` null and `trial_started_at` over an hour old, or
  `net._http_response` showing 500s, mean the sweep is broken. Test:
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
- Verifying the SDK on a real phone (2026-10-19): the dataset's
  `last_fired_time` and the Meta Ads MCP `ads_get_dataset_stats` do NOT show
  app SDK events (`/activities`). The only event they ever showed was the
  relay's CAPI curl test on 2026-10-16 18:36 UTC, and stats came back empty
  even for that. Neither stored token can read app events (the system user
  gets code 3000 on `app_event_types`). Proof that the SDK ran is on the
  RevenueCat customer instead: `linkRevenueCat` only runs after `MetaAds.start`,
  so a 1.4.x customer carrying `$fbAnonId` and `meta_extinfo` (plus
  `$attConsentStatus`) had the SDK live. Simulator customers (Test Store key)
  never carry them, by design. Whether Meta received the launches is only
  visible in Events Manager: the dataset's Overview page
  (`events_manager2/list/dataset/1445876447511793/overview`) lists the SDK
  events. Reading it in Jack's Chrome is fine; never click or change
  anything there. A `read_insights` token is not an option: the Meta app's
  use cases only offer `ads_read`. First confirmed 2026-10-19: App installs
  5, ActivateApp and fb_mobile_deactivate_app from the Facebook SDK, Start
  trial 1 (the relay's Conversions API test).
