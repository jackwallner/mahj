---
paths:
  - "scripts/capture-screenshots.sh"
  - "scripts/capture-paywall.sh"
  - "scripts/with-ipad-sim.sh"
  - "MahjTrainerScreenshots/*"
---

# Mahj: screenshots

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

## Screenshots: captured, not hand-shot

`scripts/capture-screenshots.sh <udid> <out-dir> [prefix]` drives the real app
through the six App Store screens via the `Screenshots` scheme
(`MahjTrainerScreenshots`) and exports only `ScreenshotTests` attachments.
Purchase-surface tests are intentionally excluded from this command, so the
App Store set never creates paywall images. Run
`scripts/capture-paywall.sh <udid> <out-dir>` separately when reviewing the
paywall or onboarding trial step. iPad shots must be
2064x2752, which only a 13-inch device produces and the agent-sim pool does not
have, so `scripts/with-ipad-sim.sh` creates a throwaway one, boots it headless,
and deletes it on exit:

```bash
./scripts/with-ipad-sim.sh sh -c './scripts/capture-screenshots.sh "$IPAD_UDID" out ipad_'
```

Gotchas baked into the test, do not undo them: the What's New sheet covers Home
on the first launch after a version bump, so the script passes the marketing
version through `TEST_RUNNER_SCREENSHOT_APP_VERSION` and the test marks it seen
(dismissing is not enough, it returns every time Home reappears); returning to
the root taps navigation-bar button 0 only while a back button is there,
because on Home that button is the Settings gear and the extra tap opens
Settings while the elements underneath still answer queries; and the test never
calls `XCTFail`, because a failing UI test spends ten minutes collecting
simulator diagnostics before it tells you anything.
