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
- RevenueCat project `proj28030dc2`, Play app `app8da2718cbb` (created
  2026-09-30). Entitlement `pro`, offering `default`, packages
  `$rc_monthly`/`$rc_annual`/`$rc_lifetime`. Play products are listed in
  `android/play-assets/listing-en-US.md` and are NOT created yet.
- Debug uses the project's Test Store key (`REVENUECAT_TEST_KEY`), release the
  `goog_` key (`REVENUECAT_PLAY_KEY`), both in ignored `android/local.properties`.
- Upload keystore: `~/.android/keystores/mahj-upload.p12`, alias `upload`,
  password in `local.properties` and `~/.mahj_credentials`
  (`MAHJ_PLAY_UPLOAD_PASSWORD`). Never commit either.

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
./gradlew testDebugUnitTest            # parity, content, stores
ANDROID_SERIAL=emulator-5586 ./gradlew connectedDebugAndroidTest
./gradlew assembleQa                   # R8 build, debug-signed, no RC key
./gradlew bundleRelease                # signed AAB, needs goog_ key + keystore
```

- Never on the MacBook Air. Unit tests run on jmbp (ssh host `clawd-mac`):
  rsync `android/` (excluding `build/`, `.gradle/`, `local.properties`,
  keystores) to `~/fleet-work/android-ports/mahj/android`, write a
  `local.properties` with only `sdk.dir=/Users/jackwallner/Library/Android/sdk`,
  then `JAVA_HOME=~/.jdk/jdk-21.0.12.1+1/Contents/Home ./gradlew --no-daemon
  testDebugUnitTest`. 39 tests green there on 2026-10-19.
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
