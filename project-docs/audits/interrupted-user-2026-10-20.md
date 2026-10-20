# Mahj Trainer: interrupted-user audit (2026-10-20)

Persona: tired, busy player interrupted mid-task (home button, app kill) who returns later.
Method: iPhone 17 simulator (iOS 27) on GitHub Mac via gh-sim, XCUITest `MahjTrainerScreenshots/InterruptedPlayerTests` (commit "test: interrupted-player UI flows"). Run: `mahj@shift-audit-mahj-interrupted-1-1792491391-imac0bba-1020-031804-219`. Results: 2 passed, 1 failed (test-summary.json). Screenshots in `shots/`, filenames are the xcresult exports (map in test attachments manifest).

## Status: BLOCKED on the 60 fps requirement
- gh-sim's native recording (`tests-phone.mp4`) came back 0 bytes; the unfinalized `.sb-*` file has no moov atom and is undecodable.
- The only decodable video is XCTest's own screen recording (`video/xctest-screenrecording.mp4`): 30 frames over 342 s, 0.08 fps measured, 12 distinct frames (`.frames.json`). Not 60 fps and not usable for motion review. No frames were interpolated.
- `testGetStartedInterrupted` hung on a UI snapshot query for about 6 minutes (spindump attached: app main thread idle in the run loop, so the app was not hung; likely the test's query against a huge element tree or a busy Get Started screen, unresolved). Whole run took 1520 s. Get Started interruption is therefore source-only.
- Next action: rerun with a lighter Get Started test (use accessibility identifiers, no allElementsBoundByIndex filter) and a gh-sim version whose recording finalizes, then run `fleet-record60 verify` on the `tests-` video.

## Findings

### F1 (Low-Med, runtime observed) Killing the app mid-onboarding restarts at page 1
Repro: fresh install, Continue twice (page 3 "Walk in confident"), terminate, relaunch. Evidence: `shots/2C6CDAF4...png` (page 3 after Home-button background: state kept) vs `shots/006A60A0...png` (after kill: back to "Make it stick between games", page 1). Impact: the user repeats three info screens and the skill-level page may be re-asked; for an interrupted newcomer this is the highest-drop point before the trial page. Cause: `OnboardingView.page` is `@State` (OnboardingView.swift:20), not persisted. Fix: `@SceneStorage("onboarding.page")` for page and stage (skill level is already `@AppStorage`). Do not change the frozen trial page itself; this only restores position.

### F2 (Info, runtime observed, works) Mahj Minute resumes correctly
Home button and return keep the answered screen with feedback (`7AA41F0C`, `5A21A759`). Kill and relaunch: Home card says "1 of 5 answered today" (`7143713A`), challenge page button becomes "Resume Today's Mahj Minute" (`5E3E5BC8`). Minor: resume lands on question 2, so the explanation for question 1 (the coaching note the user was reading) is gone with no way back. Fix: optional, show the last answered question's note as a banner on resume. Low priority.

### F3 (Medium, source-only, unverified at runtime) Get Started session and drills do not resume
QuickSessionView (index, score, answers, items) and FlashcardDrillView (queue) are `@State` only; the only resume paths are Mahj Minute (MonthlyChallengeStore) and Hand Play (HandPlayStore.inProgress, Home badge "Resume"). After a kill the Get Started card rebuilds a fresh mix; answered items are already in seen/missed via `recordItem` (QuickSessionView.swift:265) so work is not wholly lost, but: (a) `recordSession`/streak credit only happens in DrillCompleteView:48, so answering 4 of 5 then being killed earns no session or streak day; (b) the 5-item session is replaced by a different mix, no "pick up where you left off". Fix: credit the session/streak on first answered item (as Mahj Minute already does on its last answer, QuickSessionView.swift:261) or persist a small resume snapshot like MonthlyChallengeProgress.

### F4 (Low, source-only) Sheets and Paywall state
PaywallView and trial sheet state not exercised (no purchases allowed). Not audited at runtime.

## Not covered
Flashcard swipe mid-gesture interruption, Charleston/Practice runs, keyboard (Send Feedback), Settings, motion/frame cadence (blocked above).
