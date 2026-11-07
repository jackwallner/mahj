---
paths:
  - "Shared/Services/Analytics.swift"
  - "Shared/Services/SubscriptionService.swift"
  - "Shared/Services/PracticeRecordStore.swift"
  - "docs/privacy-policy*"
---

# Mahj: PostHog analytics (added in 1.4.4, 2026-11-07)

Jack wants as much behavior data as possible, to slice later. Project
"Mahj Trainer", id 717934, US Cloud, free plan with no card (1M events a month,
1 year retention; ingestion stops at the cap, nothing is charged). Never add a
card without asking.

`Analytics` is the only file importing the SDK. It never starts on a simulator
or in tests; a DEBUG run with `-phprobe` opts in to prove the pipeline. The
project's internal filter drops `$is_emulator` and `$is_testflight`.

## What is captured

- SDK: lifecycle, rage clicks, crashes and exceptions, GeoIP (the project
  discards the raw IP after the lookup).
- `.analyticsScreen` on every screen. SDK screen capture stays off: it reports
  hosting controller names and overwrites `$screen_name`.
- Events: `answer` (one per graded question, from `PracticeRecordStore.record`),
  `practice_finished` (`ProgressStore.recordSession`), `drill_result`,
  `onboarding_page`, `skill_level_chosen`, `onboarding_trial_page_left`,
  `onboarding_finished`, `paywall_shown`, `purchase_started`,
  `purchase_finished`, `restore_finished`, `trial_offer_checked` (every good
  result, why the sheet did or did not rise), `rating_asked`, `feedback_sent`
  (kind only), `notification_opened`, `setting_changed`,
  `paywall_plan_selected`, `paywall_closed`, `trial_offer_declined`,
  `restore_started`, `deep_link_opened`.
- Stamped on every event: `is_member`, `period_type`, `skill_level`,
  `days_since_install`, and the remote variant keys, so anything can be split by them.
- Identity is RevenueCat's `appUserID` on both sides (`setPostHogUserID`), so
  `rc_*` events from RevenueCat's PostHog integration join the same person.

## Deliberately off

- Session replay: App Review 2.5.14 needs explicit consent and a visible
  indicator for screen recording. Turning it on needs a consent step, and that
  touches the frozen trial flow, so it is Jack's call. Never enable it in the
  binary and gate it on the project's switch: that would record without consent.
- SwiftUI tap capture: measured 2026-11-07, about a dozen taps produced two
  `$autocapture` events, and it walks the accessibility tree on every touch, a
  risk to the swipe deck. A choice worth reading gets a named event instead.
  `$rageclick` is a separate SDK integration and still fires with this off
  (three taps within a second); its `$screen_name` is a hosting controller name.
- UIKit element capture: it reads `UITextView` contents, and the feedback box is
  the one place a player types. The box is also tagged `ph-no-capture`; typed
  text was checked absent from every event, rage clicks included.
- Feature flags and surveys: remote variants come only through RevenueCat.
- Push capture: reminders are local, and it swizzles the notification delegate.

## Disclosure

Any new data type needs the App Privacy label (Product Interaction, Other Usage
Data, User ID, Coarse Location, Crash Data, Other Diagnostic Data: analytics,
linked, not tracking) and the "Usage analytics" section of the policy (three
files under `docs/`) updated in the same release.
