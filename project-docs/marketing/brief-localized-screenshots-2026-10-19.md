# Brief: localized App Store screenshots for Mahj's top markets

Jack (2026-10-19): add localized App Store screenshots for the most popular
regions. Today only en-US has screenshots (iPhone 6.9", iPad 13", iPhone
Duo; 8 each); the other 49 localizations fall back to them. Listing text
(name, subtitle, description, keywords, promo text, What's New) is already
localized in 50 locales.

## Success criterion

For each chosen locale, a complete screenshot set (iPhone 6.9", iPad 13",
iPhone Duo) whose caption text is a natural, native translation of the en-US
captions, rendered with the same compositor and design as en-US, checked by
eye, committed under `fastlane/screenshots/<locale>/`.

## Steps

1. **Pick the locales from data, not guesses.** Rank storefronts by product
   page views and downloads over the last 90 days (App Store Connect
   Analytics or Sales reports with the shared key in
   `~/.baseball_credentials`; RevenueCat customer `store_country` in
   `~/.mahj_credentials` as a cross-check; never print either secret).
   Map storefronts to ASC locales. English storefronts (en-GB, en-CA,
   en-AU) only need a set if their copy should differ from en-US; say
   whether it should. Pick the top non-English locales with real traffic
   (aim for 3 to 6; skip any locale under about 1% of views and say so).
   Write the ranking table into the report.
2. **Read the pipeline before changing it:** `.claude/rules/screenshots.md`,
   `scripts/capture-screenshots.sh`, `scripts/appstore_screenshot_compositor.py`
   and the en-US files in `fastlane/screenshots/en-US/`. Captions are
   overlay text; the app UI itself is English only (do not localize the
   app). Reuse the en-US raw captures unless the compositor needs fresh ones.
3. **Translate the captions** for each locale: short, native and benefit-led,
   the same meaning as en-US, no prices, no "free", no claims the app does
   not back, no em dashes, and keep "Mahj+" and "Mah Jongg" as written.
   American Mah Jongg is a distinct game: never translate it as
   Chinese/Hong Kong mahjong or Riichi. Do not invent features.
4. **Render** each locale's sets at the exact sizes en-US uses (iPhone
   1320x2868 RGB, iPad 2064x2752, Duo 1398x2034). Check every image by eye:
   no clipped or overflowing text (German and French run long), correct
   accents, fonts that carry every glyph (CJK needs a CJK font).
5. **Commit** the images and any compositor change
   (`feat(aso): localized screenshots for <locales>`) and push. Put a short
   report at `project-docs/marketing/localized-screenshots-2026-10-19.md`
   (the locale ranking, the captions per locale with back-translations, and
   what you checked), and add a line to `project-docs/README.md`.

## Limits

- Do NOT upload anything to App Store Connect, submit anything, or touch
  RevenueCat. Another session owns the 1.4.1 submission; it will upload your
  sets with `~/ios/appstore-screenshots/bin/asc-sync-screenshots` and audit
  them.
- Do not edit app code, `project.yml`, `docs/` or `en-US` assets. Commit
  only your own files; leave other uncommitted changes alone.
- No local simulator pool. If you truly need new raw captures, use
  `gh-sim launch` (at most 2 runs, no secrets).
- No paid services or fonts without asking Jack.
