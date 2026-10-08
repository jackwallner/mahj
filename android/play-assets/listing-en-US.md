# Mahj Trainer: Google Play listing (en-US)

Source of truth for the Play Console store listing. Adapted from
`fastlane/metadata/en-US/` with Google Play billing and cancellation wording.
No prices in copy: Play shows them.

## App name (30/30)

Mahj Trainer: Mahjong Practice

## Short description (79/80)

Five-minute American Mah Jongg drills: tiles, Charleston, racks and table play.

## Full description (3330/4000)

Practice American Mah Jongg in five-minute drills: tiles, Charleston strategy, rack reading, and keep-or-throw judgment, built for new players.

Learned mah jongg on Thursday? Keep it. Mahj Trainer has no opponents and no pressure: just quick, interactive reps that build the skills you need before sitting down at a real table. Think of it like practicing your serve without playing a match.

WHY IT WORKS
Most new players learn at a weekly game, then have no way to practice until the next one. Lessons fade. Mahj Trainer gives you quick reps you can run anywhere, even standing in line.

FOUR FREE PRACTICE ROOMS

THE TILE ROOM
Meet every tile family: craks, bams, dots, winds, dragons, flowers, and jokers. Then quiz yourself on the rules everyone gets wrong: which dragon goes with which suit, what jokers can and cannot do, what a soap really means.

THE CARD ROOM
Learn the card's sections (2468, Consecutive Run, 13579, Winds and Dragons, 369, Singles and Pairs, and more) and how to spot them. Then practice reading racks: see 13 tiles and name the section they're chasing.

THE CHARLESTON ROOM
The part that scares every new player, minus the panic. Learn the rules and strategy of the pass, then work through real deals: pick 3 tiles to pass and compare your choice with the coach's, with the reasoning explained.

THE TABLE ROOM
Keep-or-throw judgment calls: when to hold a flower, when to swap for an exposed joker, what an opponent's exposure tells you, and which discards are safe.

MAHJ+ (optional upgrade)
Everything above stays free, forever. Mahj+ adds practice that never runs out:

PLAY A HAND deals thirteen tiles off a real wall, then grades every discard and shows the arithmetic behind it. No opponents and no bots, so nothing can feel rigged. Everyone gets one free hand a day.

ENDLESS PRACTICE deals a freshly generated rack every time, so section reading never repeats and never runs dry.

FIX MY MISTAKES remembers what you got wrong and brings it back on a spaced schedule, so weak spots actually close.

TIMED CHALLENGE gives you ninety seconds of mixed reads and a personal best to chase.

EXTRA PRACTICE SETS in every one of the four rooms, with fresh questions, racks and deals in the same drills you already use.

THE MASTER TABLES, where advanced Charleston strategy, a defense school, and expert rack-reading drills wait for players moving past the basics.

New drills are added all year.

BUILT FOR NEW PLAYERS
Flashcards with the "why" on the back. Streaks to keep you practicing between games. Original practice hands that teach the category system, so your skills transfer to any year's card.

Mahj Trainer is an independent training app. It is not affiliated with or endorsed by the National Mah Jongg League. For official hands and values, get the current NMJL card.

SUBSCRIPTIONS
Mahj+ is available as an auto-renewing subscription (Monthly or Yearly, both with a 7-day free trial) or as a one-time Lifetime purchase. Prices are shown in the app before you buy and vary by region. Payment is charged to your Google Play account. Subscriptions renew automatically until canceled. Manage or cancel anytime in Google Play under Payments & subscriptions. Terms of Use: https://jackwallner.github.io/mahj/terms.html. Privacy Policy: https://jackwallner.github.io/mahj/android-privacy.html.

## Graphics

- App icon: `icon-512.png` (512 x 512)
- Feature graphic: `feature-graphic.png` (1024 x 500)
- Phone screenshots: `screenshots/01..08` (1080 x 1920), rebuilt by
  `scripts/android_capture_screenshots.py` then `scripts/play_screenshot_compositor.py`

## Store settings

- Category: Education (a training app with no gameplay against anyone, as on iOS).
- Contact email: jackwallner+m@gmail.com. Website: https://jackwallner.github.io/mahj/
- Privacy policy: https://jackwallner.github.io/mahj/android-privacy.html

## Products (create in Play Console, then map in RevenueCat project `projba4fbe38`, Play app `appeb48abdaf2`)

| Play product | Type | Base plan / offer | RevenueCat package |
|---|---|---|---|
| `com.jackwallner.mahj.monthly` | Subscription | base plan `monthly` (P1M), offer `free-trial` (P1W free, new customers) | `$rc_monthly` |
| `com.jackwallner.mahj.yearly` | Subscription | base plan `yearly` (P1Y), offer `free-trial` (P1W free, new customers) | `$rc_annual` |
| `com.jackwallner.mahj.lifetime` | One-time product | none | `$rc_lifetime` |

All three attach to entitlement `pro`, Android offering `android`. Preserve the
iOS `default` offering and every Apple product mapping. Price from the iOS
US tier, then review Play's converted local prices against `~/ios/pricing`.

## Policy answers (from the code)

- Ads: no.
- App access: everything reachable without an account; no login.
- Target audience: 18+ (adult hobby players; not designed for children).
- Content rating (IARC): educational, no violence, no user interaction, no
  gambling (no real-money play, no simulated gambling: it teaches tile
  recognition and hand shapes, no scoring for stakes), no location.
- Data Safety: data is collected by the RevenueCat SDK, including Financial
  info > Purchase history, App activity > App interactions (app-open and
  purchase-screen counts, timestamps and paywall impressions), and Device or
  other IDs (RevenueCat's anonymous app user ID, not a hardware or advertising
  identifier). Practice answers, progress and settings stay on device.
  Purchase history is used for app functionality and analytics. Interactions
  are used for purchase-funnel analytics. The anonymous app ID is used for purchase/restore functionality
  and associating those analytics events. Processing is not ephemeral. There is no
  collection opt-out in this build, so do not label SDK collection optional.
  Data is encrypted in transit. RevenueCat acts as a service provider; confirm
  no additional integrations share the data before answering the sharing
  question. Users can request server-side deletion by email; clearing local
  practice progress does not delete RevenueCat's purchase record. Recheck the
  live SDK/project configuration before entering these draft answers.
- Notifications: optional daily and game-night reminders, requested only when
  the player turns one on.
- Health apps declaration: not a health app.
