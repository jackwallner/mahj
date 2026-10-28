---
paths:
  - "scripts/capture-screenshots.sh"
  - "scripts/capture-paywall.sh"
  - "scripts/with-ipad-sim.sh"
  - "MahjTrainerScreenshots/*"
---

# Mahj: screenshots

Moved verbatim from AGENTS.md. Loads when a matching file is read; update it here.

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

## Release gate journeys

`ReleaseJourneysUITests` runs per persona in `qa-gate run` (newcomer, AX3,
Reduce Motion, iPhone Duo). `testCoreLoopPracticeFinishesAndResumes` is the
core loop: one answer in Tile Check, back to Home, Resume reopens the same
question with the answer held; then a whole Get Started session to its
result, and Home shows "Today's session is done", one more drill counted and
a streak, again after `QA.relaunch`. It must not pass launch arguments for
anything it asserts: arguments win over saved values on every relaunch. The
helpers that call `QA.checkpoint` take `journey: String = #function`, so
findings carry the test's name (ledger matches before 1.4.2's batch 7 said
`home(_:in:)`). `back(in:)` taps the `BackButton` identifier first: the iPhone Duo draws a
pushed screen's back button in a side bar, and the navigation bar's first
button there is Home's (gate run 6 left the drill open beside Home, so no
Resume card). DEBUG builds log `launch-timing` lines (process start to the
App's init, the first appear and the commit after it) for blank-launch
findings.
