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
- Moving into the iOS project (2026-10-27): Play app `app8da2718cbb` in `proj28030dc2` has the Play products on entitlement `pro` and a non-current `android` offering. The next release swaps `REVENUECAT_PLAY_KEY` to that app's `goog_` key, and the code syncs existing Play purchases once (`SYNCED_TO_SHARED_PROJECT`) so old-project trials keep access. Upload the service-account JSON to that app first. Until then the release ships the old key below. Live Play vc7 was built from `chore/android-staging-20261002`; that branch is merged into main (2026-10-27), `versionCode` is 7 and the release step bumps it. Trial copy follows Play's offer (`offersFreeTrial`) and also drops the free week for anyone with a past subscription (`TrialPolicy`).
- RevenueCat project `projba4fbe38` "Mahj Trainer Android" (separate from
  iOS `proj28030dc2`), Play app `appeb48abdaf2`, whose `goog_` key the release
  ships. The older Play app `app8da2718cbb` in the iOS project is unused.
  Entitlement `pro`, current offering `android`, packages
  `$rc_monthly`/`$rc_annual`/`$rc_lifetime`. Live in Play production since
  2026-10-10 with the three Mahj+ products active; the listing copy is in
  `android/play-assets/listing-en-US.md`.
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
- The fixture also records the rack `missNotes` for every section and the
  Endless filters' verdicts (`passFilter`, `defenseFilter`: 120 seeded deals
  per seed through `CharlestonGenerator.isUnarguable` and
  `DefenseGenerator.isUnarguable`), so a reworded note or a changed filter
  rule fails `GeneratorParityTest` until it is ported.
- Brought up to iOS 1.4.2 on 2026-10-19 (e2288ed, 77077ca, 3cf7e92).
  Challenge-only generator code (`CharlestonGenerator.pass(section:seed:)`,
  two-singles racks, `DefenseGenerator.withRunBait`, `RackGenerator.rack(for:seed:)`,
  `MonthlyChallengeContent`/`Extras` and its `defensePlan` closers) is not
  ported: the monthly challenge is iOS only.
- Hand copy that is not in the export (screen text, paywall, onboarding) is
  ported by hand; keep it word for word with iOS.

## Deliberate differences from iOS

- Review prompt: same rules as iOS. A finished drill calls `launchReviewFlow`
  directly (no question first) from the second launch, at most every 30 days
  (`ReviewPromptTracker` in `Funnel.kt`); only "Rate" (opens the Play listing)
  ends the asks, and "Send Feedback" never does.
- Settings is a pushed screen, not a sheet. Paywall, What's New and Feedback
  are sheets (`MahjSheet`).
- Reminders use inexact ONE-SHOT alarms, re-laid at the chosen local time on
  every delivery, boot, clock change and time-zone change
  (`AppSettings.rescheduleAll`); fixed 24h/7d repeats drifted an hour at DST.
  `POST_NOTIFICATIONS` is asked only when a reminder is switched on, and a
  denial raises the "Notifications are off" alert from `RootScreen`, wherever
  it was asked.
- `SubscriptionService.membershipResolved`: `isPro` is false on every launch
  until a customer record is read. Never act on a lapse (turning off the game
  night reminder) before it is true.
- No iPad layout; tablets get the readable-width column.
- Home has none of iOS's gated extras yet (challenge card, game night card,
  tracking prompt). `ProgressStore.hasPracticedSinceOnboarding` and the
  `sessionsAtOnboarding` stamp in onboarding's `finish()` are ported, so any
  Home extra added later must gate on it, never on `totalSessions > 0`.
- What's New uses iOS's fallback: `WhatsNewTracker.currentRelease` is the
  newest entry at or below `versionName`, shown once to anyone whose last
  seen version is older than that entry.

## Build, test, capture

```bash
cd android
fm-gradle testDebugUnitTest            # parity, content, stores
fm-gradle connectedDebugAndroidTest    # every device attached on jmbp
fm-gradle assembleQa                   # R8 build, debug-signed, no RC key
./gradlew bundleRelease                # signed AAB, needs goog_ key + keystore
```

- Only the signed `bundleRelease` runs on the MacBook Air (the keystore never
  leaves it). `fm-gradle` runs everything else on jmbp (ssh host `clawd-mac`)
  and copies outputs, reports and test results back. 39 unit tests green on
  jmbp on 2026-10-19.
- AVD `mahj-api36` (on jmbp, never the Air; Pixel 9, API 36 Google Play image), started
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
- Listing experiment B (2026-10-21): `scripts/android_capture_screenshots_b.py`
  (seed progress + debug `forcePro`, plays three Mahj Minutes so the week row
  is not empty) then `scripts/play_screenshot_compositor_b.py`, which writes
  `android/play-assets/experiment-b/screenshots/` and `compare.png` (A over B
  at thumbnail size). The live set stays in `play-assets/screenshots/`. A
  freshly booted emulator can drop the first demo-mode broadcast and boot
  with a short `wm size` override; the B script resets both.
- Store listing text: `android/play-assets/metadata/android/<play-locale>/`
  (fastlane supply layout, 50 locales, en-US is the live copy).
  `scripts/validate-play-listing.py` checks limits and house rules; every
  non-English description says the app itself is in English.

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
- Google trials target people who never subscribed in this app. Derive past
  subscription history from CustomerInfo expiration-date keys, including
  expired subscriptions. `TrialPolicy` drives paywall and onboarding copy;
  returning subscribers buy the base plan with its offering context.
- The Swift exporter rounds numeric scoring fixtures to nine decimal places;
  dictionary summation order can change insignificant floating-point bits.
- In Play Console plan IDs and local-price popups, clear the input, use
  `pressSequentially`, then press Tab. Verify prices through the Play API after
  the final save confirmation. `fill` changes the visible value but can leave
  the underlying form value stale in these custom fields.

## Verified release state (2026-10-08)

- Internal track serves signed 4 (1.3.1), active for the existing verified
  tester list. The app has its temporary package-based name until review.
- Google credentials are valid in the separate Android RevenueCat project.
- The complete store listing and eight screenshots are saved, pending review.
  App setup is complete. IARC terms were approved and the Everyone rating saved.
- Monthly (`monthly`, P1M), yearly (`yearly`, P1Y) and lifetime Buy option
  `lifetime` are active. Both subscriptions have active `trial-7d` offers with
  one P7D free phase, eligible for people who never subscribed in this app.
  All three prices match current Apple prices in 127 shared markets using the
  same currency. Preserve the existing Apple subscription cohorts.
- Play license-test monthly purchase, cancellation of its purchase sheet and
  restore passed in signed build 1. The receipt is sandbox, grants `pro`, and
  the release app displays Mahj+ unlocked. Annual and lifetime store-flow
  verification, pre-launch reporting and production submission remain pending.
- Build 2 fixes returning-subscriber trial disclosure. Forty unit tests and 25
  device tests pass. Its signed bundle is active internally and installed
  through Play. Returning-subscriber copy and yearly base-plan purchase/restore
  are verified in release. Lifetime pending payment is being checked.
- The app-scoped service account can upload bundles and validate receipts.
  Subscription creation and regional-price conversion currently return 403.
  Use the signed-in Console for billing and final submission; expanded service
  account permissions are optional.
- The existing iOS RevenueCat configuration matches its before/after snapshot
  byte for byte across Apple products, entitlement metadata, current offering,
  packages and package-product assignments.

- Build 3 handles pending Restore with the payment-pending explanation. All 42
  unit tests and 25 device tests pass. It is active internally; install and
  delayed Lifetime completion/restore verification are pending.

- Build 4 derives subscription management from active subscription IDs and
  hides it for Lifetime-only membership. All 44 unit tests and 26 device tests
  pass. Standard Lifetime purchase and restore passed in the Play build; the
  delayed test order was refunded and did not verify approval completion.

- Production 1.3.1 (4) and the US Alpha release are submitted for review.
  Google quick checks completed; Publishing overview confirms changes are now
  in review. Managed publishing is enabled, so approval does not publish.
  Production targets 177 countries/regions plus Rest of World. The Pro Play
  installation, Lifetime management correction and Restore were verified.
  The pre-launch device-lab report has not been generated; do not claim it passed.

## Parity audit (2026-10-08)

Every iOS view and shared service was read against its Kotlin counterpart,
and every user-facing string literal was diffed between the two trees. Copy,
flows, gates, keys and the RNG ports match; the only Android-only strings are
the deliberate Google Play wording. Three gaps were fixed in build 5:

- `PracticeRunScreen` drops answered items when a generated run tops up and
  resets `index`, so its "Question N" footer went back to 1 mid-run. The
  footer now counts `attempted + 1`, which is what iOS shows.
- The "Notifications are off" alert only lived in Settings; iOS also raises it
  from Game Night Prep. It now lives in `RootScreen` and fires wherever the
  toggle was flipped.
- The reviewer-code dialog was stock Material; it now uses the app palette.

Build 6 answers Play's release-dashboard recommendations on build 4: resource
shrinking is on, and a Gradle constraint lifts `androidx.fragment` from the
1.1.0 that `review-ktx` pulls in. The two remaining recommendations are left
on purpose: the portrait lock matches the iPhone app (Android 16 ignores it
on tablets anyway), and the deprecated edge-to-edge calls come from library
internals, not app code.

All three fixes were verified on the Pro Play AVD in the Play-installed signed
build 5. The reviewer code unlocked membership there, so the app data on that
AVD was cleared afterwards (`pm clear`); the Play install and its account are
preserved, and the next billing check starts from a fresh onboarding.

Build 7 fixes what a 360 x 640dp phone showed (the Play AVD is one; the
capture script's device is taller, so nothing earlier caught it):

- Every onboarding page, the tour card and the primer card overflowed the
  space the zero-shift footer leaves them, so body copy was cut off under the
  page dots. Each now sits in a `CenteringScroll` and draws a compact variant
  (smaller icon, title and tiles) when its `BoxWithConstraints` height is
  short. The thresholds are 440dp (onboarding), 460dp (tour) and 500dp (primer).
- `TileRack` shrinks tiles to the width it is given. Seven 44dp tiles need
  344dp and a 360dp phone has 328dp inside the screen padding, so the seventh
  tile of every 13-tile rack question, and the sixth primer tile, were clipped.
  iOS has the same arithmetic on an iPhone SE width; it is not fixed there.

Verified in the R8 QA build on a temporary config-only Pro AVD
(`mahj_agent_test`, API 36.1 Play image, port 5560), removed afterwards.

Signed build 7 (1.3.1) is active on the internal track and was installed
through Play on `small_phone`, where the onboarding pages fit. The service
account cannot touch the production track (`The caller does not have
permission` on both a promote and a draft upload), so promotion is a Console
step. On 2026-10-08 build 7 was promoted from internal to a production draft in
Chrome, with en-US release notes, and saved to Publishing overview. The only
preview warning was the non-blocking native-debug-symbols note. Sending it
for review ("Submit 1 change for review") was left for Jack.

On 2026-10-10 Google approved the submission and all 17 changes were published
from Publishing overview (managed publishing stays on). Production 1.3.1
(build 7, superseding build 4) is live in 177 countries/regions plus Rest of
World, with the US Alpha track, store listing and app content declarations.
