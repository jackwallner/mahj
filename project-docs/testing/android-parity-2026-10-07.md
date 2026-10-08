# Android parity and Play release verification

## Verified baseline

- iOS 1.3.1, build 36: 167 unit tests and 3 screenshot UI tests passed.
- Android: 36 unit tests and 23 connected device tests passed on API 36.
- Screenshot helper: 8 Python tests passed.
- Minified QA reviewer access unlocked membership and survived a restart without a production RevenueCat connection.
- Signed release bundle: package `com.jackwallner.mahj`, version 1.3.1 (1), target API 36. All four native libraries use at least 16 KB ELF load alignment.
- Play internal track: build 1 active and available to internal testers. Production submission is still pending completion of billing and store setup.

## Coverage

Onboarding and escape routes, free room completion, locked extra sets, membership access, deck flip and swipe grading, undo, Charleston selection and coaching, hand matching, hand completion and resume, glossary nicknames, all four generated skills, queue refill, daily challenge completion, game-night preparation, timed expiry, feedback drafts and selected purchase plans across activity recreation. Seeded racks, passes, defenses, hand scoring and daily challenges match the Swift exporter fixtures.

## Commands

```sh
cd android
./gradlew testDebugUnitTest
ANDROID_SERIAL=emulator-5586 ./gradlew connectedDebugAndroidTest --max-workers=2
./gradlew assembleQa assembleRelease bundleRelease --max-workers=2
```

```sh
python3 -m unittest discover -s scripts/tests -v
```

## Evidence

Runtime logs and captures are in `/tmp/mahj-ios-parity/` and `/tmp/mahj-android-parity/`. The passing Android instrumentation XML is in `/tmp/mahj-android-final-passing-results/`. Temporary evidence is local and is not committed. iOS captures include Home, quick sessions, card matching, Keep or Throw, Charleston, hand play, Reference, onboarding, primer, paywall, Settings and dark mode. The iOS Meet the Tiles capture is the room list; its first deck gesture capture was not completed after simulator startup slowed. Android device tests separately verify those gestures.

## iOS protection

Android uses RevenueCat project `projba4fbe38`, Play app `appeb48abdaf2`, its own `android` offering and a separate Test Store. The original iOS project is `proj28030dc2`. Its Apple products, current offering, entitlement metadata, packages and product assignments were compared against the pre-port snapshot and are identical. No iOS app source, signing credentials, App Store prices or App Store metadata have been changed. Android privacy disclosures use `android-privacy.html`; the existing shared privacy policy is outside this task commit. Android changes do not trigger an iOS release.

## Remaining release checks

Configure and verify Google Play products, trial offers, real license-test purchase and restore, Play pre-launch report, listing and policy declarations, then submit production for review with managed publishing.

## Play installation verification

Build 1 was installed through Google Play on the signed-in remote Play AVD. Its installer is `com.android.vending` and the package has no debuggable flag. First-run pages, skill choice, free exit, tour escape and Home render correctly on the 720 x 1280 display. Actual purchases and restore remain blocked until Google base plans and store products are activated.

## Store setup status

Data Safety is saved with purchase history, app interaction analytics and anonymous app identifiers, encrypted transit, no third-party sharing outside service-provider processing, and an email-based deletion request route. The Android privacy page is published and separate from the iOS page. Education and support contact details are saved. IARC Terms approval is pending. The service account stages listing text and artwork, but its current testing access cannot commit the store listing. Mahj-only production publishing access has been requested. Google Console also rejects valid base-plan IDs in the current editor; do not claim billing or production review completed.
