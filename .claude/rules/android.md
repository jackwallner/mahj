---
paths:
  - "android/**"
  - "scripts/android-export/**"
  - "scripts/sync-android-content.sh"
  - "scripts/android_capture_screenshots.py"
  - "scripts/play_screenshot_compositor.py"
---

# Mahj Trainer Android

Shared Android conventions (SDK, signing, Play release, billing, policy forms)
live in the `android-dev` skill and its `references/fleet-port.md`. This file
holds only what is specific to this app.

## Identity

- Play package and namespace: `com.jackwallner.mahj`. Listing name
  `Mahj Trainer: Mahjong Practice`, category Education, audience 18+.
- Version name follows iOS (`1.3.1`); `versionCode` starts at 1 and bumps on
  every upload.
- RevenueCat Android project `projba4fbe38`, Play app `appeb48abdaf2`
  (created 2026-10-07); Test Store app `appfedf079587`. Entitlement `pro`,
  Android offering `android`, packages
  `$rc_monthly`/`$rc_annual`/`$rc_lifetime`. Play products are listed in
  `android/play-assets/listing-en-US.md`. Google Play product setup is in progress.
- The live iOS RevenueCat project is `proj28030dc2`. Preserve every Apple
  product, the current iOS `default` offering and its
  package mappings, Apple credentials, and App Store pricing. Android has its
  own project and offering, including separate Test Store keys, so its reporting
  and configuration never enter the iOS project. Android work does not trigger an
  iOS release or TestFlight upload.
- Debug uses the project's Test Store key (`REVENUECAT_TEST_KEY`), release the
  `goog_` key (`REVENUECAT_PLAY_KEY`), both in ignored `android/local.properties`.
- Upload keystore: `~/.android/keystores/mahj-upload.p12`, alias `upload`,
  password in `local.properties` and `~/.mahj_credentials`
  (`MAHJ_PLAY_UPLOAD_PASSWORD`). Never commit either.
- Google service-account key: `~/.config/google-play/mahj-service-account.json`,
  approved by Jack for Mahj-scoped billing, product setup and testing uploads.
  Keep the file private and outside git. Preserve the existing service-account
  key and IM Tri Tracker permissions.
- Play Console app record: `4976065425376857577`, E3 Apps developer
  `8314164911785412040` (created 2026-10-07). Creation and export declarations
  were approved by Jack. Recheck the live track and review state before release.

## Review access and repeatable uploads

- Play's Sign in details declaration includes paid features even without an
  account. Reviewers must reach Mahj+ without paying or starting a trial.
  Long press Settings > About > Version, enter the private reviewer code,
  then tap Unlock. Wrong codes never grant membership. This access is separate
  from purchases and persists through restore and app restarts.
- The raw code is `MAHJ_PLAY_REVIEW_CODE` in `~/.mahj_credentials`. Only its
  SHA-256 digest, `PLAY_REVIEW_CODE_SHA256` in ignored `local.properties`, is
  compiled. Release validation requires it. Never put the raw code in git,
  screenshots, logs, public metadata, or chat. Supply it only in Play's private
  reviewer access instructions.
- `scripts/play-upload.sh` uses fastlane supply and reads `applicationId` from
  Gradle. Set `PLAY_SERVICE_ACCOUNT_JSON` to the external credential file.
  The default `validate` mode checks an edit without publishing. `internal`
  uploads to testing; `internal-draft` supports a not-yet-published app;
  `production-draft` stages a release for review through Console. The script
  stages production with draft status. Google rejects changesNotSentForReview
  on this new app, so the upload uses its default commit behavior. Use Chrome
  for the final production review submission.

## Content is exported, not transcribed

- `scripts/sync-android-content.sh` compiles `Shared/Models`, `Shared/Content`,
  `WhatsNew.swift` and `ChoiceShuffle.swift` with `scripts/android-export/main.swift`
  and writes `android/app/src/main/resources/mahj-content.json` (read at
  runtime from the classpath) and `android/app/src/test/resources/mahj-parity.json`.
  Rerun it after ANY change to those Swift files and commit both JSON files.
- The generators, `SessionBuilder`, `HandPlayEngine` and `MahjMinuteContent`
  are hand-ported Kotlin that reproduces Swift's RNG algorithms exactly
  (`model/SeededRandom.kt`: xorshift64*, Lemire bounded draw, Swift's
  Fisher-Yates). `GeneratorParityTest` proves the same seed deals the same
  tiles as iOS, so the shared Mahj Minute is identical across platforms. If a
  Swift generator changes, port the change and resync before the parity test
  will pass.
- Hand copy that is not in the export (screen text, paywall, onboarding) is
  ported by hand; keep it word for word with iOS.

## Deliberate differences from iOS

- Review funnel: Google forbids an enjoyment question before the Play review
  card. A finished drill calls `launchReviewFlow` directly behind the same
  gates (`ReviewPromptTracker`), Settings "Rate" opens the Play listing, and
  "Send Feedback" is its own sheet.
- Settings is a pushed screen, not a sheet. Paywall, What's New and Feedback
  are sheets (`MahjSheet`).
- Reminders use inexact repeating alarms plus a boot receiver;
  `POST_NOTIFICATIONS` is asked only when a reminder is switched on.
- No iPad layout; tablets get the readable-width column.

## Build, test, capture

```bash
cd android
./gradlew testDebugUnitTest            # parity, content, stores
ANDROID_SERIAL=emulator-5586 ./gradlew connectedDebugAndroidTest
./gradlew assembleQa                   # R8 build, debug-signed, no RC key
./gradlew bundleRelease                # signed AAB, needs goog_ key + keystore
```

- Local AVD `mahj-api36` (Pixel 9, API 36 Google Play image), started
  headless on port 5586: `emulator -avd mahj-api36 -port 5586 -no-window
  -no-audio -no-boot-anim -no-metrics -gpu swiftshader_indirect`. Connected
  tests pass on API 36 (5/5 on 2026-09-30); 36.1 has the Espresso
  `InputManager.getInstance` failure noted in the skill.
- Compose test tags are exposed as resource ids (`testTagsAsResourceId` on the
  root and inside `MahjSheet`), so UI Automator and the capture script find
  controls by tag.
- Debug launch extras (`src/debug/.../DebugLaunchOptions.kt`): `resetAll`,
  `onboarded`, `skillLevel`, `seedProgress`, `forcePro`, `appearance`,
  `uiTest`. Release and `qa` compile a no-op.
- Store art: `python3 scripts/android_capture_screenshots.py` (status bar in
  demo mode) then `python3 scripts/play_screenshot_compositor.py`, which reuses
  the App Store compositor's frame and headlines at 1080x1920 and draws the
  1024x500 feature graphic.

## Gotchas

- Do not use elevation `shadow()` on tiles: on the emulator GPU, re-laid-out
  tiles drew grey boxes. `TileView` draws its drop shadow.
- A translucent tint over an elevation shadow shows the shadow through it;
  `ChoiceRow` paints an opaque card colour first.
- Under strong skipping, a function reference to a local fun captured a stale
  parameter (onboarding's skill check). Read changing parameters through
  `rememberUpdatedState` inside handlers.
- The navigation stack lives in `NavigationViewModel`, so activity recreation
  keeps the current drill and its saved Compose state. App-wide sheet flags
  are saveable as well. `ParityFlowTest` checks a graded drill across recreation.
- RevenueCat reports deferred Play payments as `PaymentPendingError`.
  Return `PurchaseOutcome.PENDING` without unlocking or presenting a failure.
- The Swift exporter rounds numeric scoring fixtures to nine decimal places;
  dictionary summation order can change insignificant floating-point bits.

## Verified release state (2026-10-07)

- Internal track serves signed 1 (1.3.1), active for the existing verified
  tester list. The app has its temporary package-based name until review.
- Google credentials are valid in the separate Android RevenueCat project.
- The app-scoped service account can upload bundles and validate receipts.
  Subscription creation and regional-price conversion currently return 403;
  use the signed-in Console for those writes without broadening account access.
- The existing iOS RevenueCat configuration matches its before/after snapshot
  byte for byte across Apple products, entitlement metadata, current offering,
  packages and package-product assignments.
