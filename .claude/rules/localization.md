---
paths:
  - "MahjTrainer/Resources/*.xcstrings"
  - "MahjTrainer/Views/**"
  - "Shared/**"
  - "project.yml"
---

# Mahj: localization (2026-10-27)

The app ships in English plus German, Spanish, French, Indonesian and
Vietnamese (de, es, fr, id, vi), chosen from the regions with new customers.
Non-English rich markets trialed at about 6% against 15 to 19% in
US/UK/CA/AU at the same price, with the App Store pages already translated,
so the gap was inside the app. Every user-facing string is translated; brand
names stay as they are (Mahj Trainer, Mahj+, Mahj Minute, NMJL), and so do
the American Mah Jongg table words players meet on the card and at the
table (pung, kong, quint, Charleston, Crak/Bam/Dot, Soap).

## Three catalogs, all in `MahjTrainer/Resources`

- `Localizable.xcstrings`: UI copy, notifications, alerts, the paywall and
  onboarding, and every sentence the generators build. Keys are the English
  text; plurals are plural variations on one key ("%lld drills done").
- `Content.xcstrings`: the authored drill content in `Shared/Content`.
  Keyed by the English sentence and looked up at runtime, never extracted.
- `InfoPlist.xcstrings`: `NSUserTrackingUsageDescription`.

All entries are `extractionState: manual`, so Xcode never rewrites or drops
them. XcodeGen derives the project's `knownRegions` from the languages in
the catalogs (it has no `knownRegions` option), so `xcodegen generate` after a
catalog change; `CFBundleLocalizations` in `Info.plist` lists the same
languages.

## How authored content is translated

`Shared/Content` stays plain English Swift. The models' initializers
(`Flashcard`, `CardChoice`, `QuizQuestion`, `HandMatchQuestion`,
`CharlestonScenario`, `QuickItem`, `Drill`, `Room`, `HowToPlayPage`,
`GlossaryTerm`, `SectionReference`) pass each string through
`ContentText.localized` (`Shared/Models/Localization.swift`), which reads
the Content table and falls back to the English. So the unit tests, the
Android export and the parity fixture still see byte-identical English: run
`scripts/sync-android-content.sh` after a copy change and the JSON must not
move except for the edit you made. A string that concatenates two pieces
(`howToSpot + " " + ...`) localizes each piece itself.

Orderings and identities that must match across languages (the shared
Mahj Minute distractors, challenge dedupe keys, the Singles & Pairs pung
note) use `Tile.englishName`, never `spokenName`.

## Adding or changing copy

1. In a view, a literal in `Text`, `Button`, `Label`, `Toggle`, `Link`,
   `.navigationTitle`, `.alert`, `.accessibilityLabel/Hint` localizes
   itself. Anything held in a `String` (view parameters, enums, ternaries
   mixing a variable and a literal, notifications, alerts' messages) must be
   `String(localized:)`. Logs, analytics, RevenueCat ids and attributes,
   feedback tags (the churn chips send their English) stay plain.
2. Whole sentences only. Never build copy from fragments or `"s"` endings:
   branch and give each variant its own key, or use one plural key. Lists use
   `PhraseList.and` / `PhraseList.chained`, which keep the English output
   exactly as it was.
3. No `.capitalized`/`.lowercased()` on translated text. Dates through
   `setLocalizedDateFormatFromTemplate` or `Date.FormatStyle` (the challenge
   uses `MonthlyChallenge.format`, Gregorian in the player's language);
   percents through `.formatted(.percent)`; prices only from StoreKit.
4. Add the key to the catalog with all five translations, natural and about
   as short as the English, no em or en dashes, the same format specifiers
   (reorder with `%1$@`). New Content strings go in `Content.xcstrings` under
   the exact English text.
5. Check nothing is missing: a key with no translation shows English in that
   language. The harness used to build these catalogs (key harvest from the
   compiler's `.stringsdata`, translation files, validator) lives outside the
   repo; the catalogs themselves are the source of truth.

## Checking a language

`gh-sim all --screen "-AppleLanguages (de) -AppleLocale de_DE ..."`, one
`--screen` per screen: `-mahj.onboardingPage 0` and `-mahj.onboardingPage 4`
(the trial page, DEBUG only) on a fresh install, and `-progress.hasOnboarded
YES -mahj.suppressWhatsNew YES -mahj.hasReadPrimer YES -mahj.skillLevel some`
plus `-mahj.shot paywall` for the paywall. Pass `--skip
MahjTrainerTests/TrialEligibilityTests/testFreeWeekUntilTheAccountHasUsedIt`:
it hangs on the iOS 27.0 iPhone 17 runtime too (2026-10-27), and keep a run
to about ten screens or GitHub's job cap cuts the screenshots short. Look for
truncation, clipped buttons, leftover English, and a soft exit that repeats
the trial button's verb (Spanish and Indonesian did). The simulator's
storefront is US, so a non-US locale shows US prices; that is expected.
