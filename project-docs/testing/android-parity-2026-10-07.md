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

Runtime logs and captures are in `/tmp/mahj-ios-parity/` and `/tmp/mahj-android-parity/`. The passing Android instrumentation XML is in `/tmp/mahj-android-final-passing-results/`. Temporary evidence is local and is not committed. iOS captures include Home, quick sessions, card matching, Keep or Throw, Charleston, hand play, Reference, onboarding, primer, paywall, Settings and dark mode. A follow-up headless iOS run captured the first Meet the Tiles front, revealed answer and undo state. Runtime snapshots verify that a pre-reveal swipe does not advance, swipe right changes progress from 0 to 1, undo restores Craks and 0, and swipe left advances to Bams without increasing progress. Tapping the locked Extra Reps set opens the paywall. These match the assertions in Android `ParityFlowTest.deckRequiresFlipThenSupportsSwipeAndUndo`. Evidence is in `/tmp/mahj-ios-parity/deck-runtime-evidence.json`; the simulator lease was released afterward.

## iOS protection

Android uses RevenueCat project `projba4fbe38`, Play app `appeb48abdaf2`, its own `android` offering and a separate Test Store. The original iOS project is `proj28030dc2`. Its Apple products, current offering, entitlement metadata, packages and product assignments were compared against the pre-port snapshot and are identical. No iOS app source, signing credentials, App Store prices or App Store metadata have been changed. Android privacy disclosures use `android-privacy.html`; the existing shared privacy policy is outside this task commit. Android changes do not trigger an iOS release.

## Remaining release checks

Finish the annual and lifetime store-flow checks, obtain the Play pre-launch report and content rating, then submit production for review. Managed publishing was attempted, but Google Console displayed "You can't turn on managed publishing right now" for this unpublished app. Recheck availability before submission.

## Play installation verification

Build 1 was installed through Google Play on the signed-in remote Play AVD. Its installer is `com.android.vending` and the package has no debuggable flag. First-run pages, skill choice, free exit, tour escape and Home render correctly on the 720 x 1280 display. The monthly no-charge Google license-test purchase and restore have now passed in this Play-installed release.

## Store setup status

Data Safety is saved with purchase history, app interaction analytics and anonymous app identifiers, encrypted transit, no third-party sharing outside service-provider processing, and an email-based deletion request route. The Android privacy page is published and separate from the iOS page. Education and support contact details are saved. IARC Terms approval is pending. The complete English store listing, icon, feature graphic and eight phone screenshots were saved through the signed-in Console. Publishing overview confirms the listing is ready to send for review. The service account can stage these assets but cannot commit them with its current testing access. The requested permission expansion is optional now that Console billing edits work. The pre-launch report currently has no generated report and suggests a closed-testing upload. Sequential keyboard input resolved the plan-ID and price-editor issues. Production review remains incomplete.

## Google billing verification

All three Play products are active. Monthly uses base plan `monthly` (P1M), yearly uses `yearly` (P1Y), and lifetime uses backwards-compatible Buy option `lifetime`. Each subscription has active offer `trial-7d`: one P7D free phase in 174 regions, restricted to people who never had any subscription in this app. The Google API verifies these durations, eligibility rules and active states.

Current Apple prices were read through GET requests, excluding preserved subscription cohorts. Google prices match those Apple prices exactly in all 127 shared markets using the same currency, for each of the three products. Other markets use the currencies and conversions supported by Google. The before/after Apple RevenueCat configuration still matches exactly across all five snapshot sections.

Android RevenueCat products are monthly `prod3c3a1dfc62`, yearly `prod1c0204b5c3`, and lifetime `prod123d5bd30c`. They are attached to the corresponding packages in offering `android` and entitlement `pro`, within the separate Android project. The original iOS project has received no writes.

The existing signed-in Play account is already in the selected license tester list; no account-wide license settings were changed. The Google purchase sheet explicitly displayed the test card and no-charge notice. Closing the monthly purchase sheet returned to the paywall without an error. Completing the test subscription unlocked Mahj+ in release build 1. RevenueCat reports the real receipt as Play Store, sandbox, trialing, `gives_access=true`, monthly product `prod3c3a1dfc62`, with entitlement `pro`. The in-app Restore Purchases action reported "Mahj+ restored!". Google accelerated the seven-day trial to three minutes for this test account.

Price and trial verification artifacts are in `/tmp/mahj-google-*-verified-prices.json` and `/tmp/mahj-google-*-trial.json`. Private receipt and runtime diagnostics stay outside git. IARC terms approval remains pending.
