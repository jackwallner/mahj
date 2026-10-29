---
paths:
  - "MahjTrainer/Views/HomeView.swift"
  - "MahjTrainer/Utilities/UnfoldedSplit.swift"
  - "MahjTrainer/Utilities/DebugShot.swift"
---

# Mahj: iPhone Duo (2026-10-22)

- Unfolded (phone idiom, regular width, at least 720 pt), `HomeView` is two
  panes: Home (the lobby, phone layout) on the leading side of the fold, a room on the
  trailing side. A room card replaces the trailing pane's room (and outlines
  itself as the selection); every other Home link (Get Started, Play a Hand,
  the training tiles, stats chips, the reference, the challenge, routed deep
  links) pushes over that room in the trailing pane, so a drill's Done lands
  back in the room. The first room shows until the player picks one. Folded,
  on every other iPhone and in portrait unfolded (669 pt), Home is unchanged.
- Home is the navigator, so a screen Home opened in the pane hides its back
  button (it sat beside the fold); a drill opened from the pane's room keeps
  its own. A room card is outlined only while that room is on screen, and
  Home's Resume card hides for the run open beside it
  (`OrdinaryRunStore.onScreenID`, set by `tracksOrdinaryRun`). While split,
  Home counts as covered (`homeIsBare` is false, so no What's New, churn
  question or ATT prompt) whenever the pane shows anything but a room: a
  screen Home opened there (`panePath`) or a drill opened from its room
  (`onScreenID`). Emptying it calls `homeIsBareAgain()`.
- iOS 27.1 quirks (2026-10-25): toolbar items stack in a column down each
  pane's trailing edge, so Home hides its navigation bar while split and
  draws the book and gear in its header. The status column's trailing inset
  reaches both panes the whole way down: Home's ScrollView ignores it, and
  every trailing-pane screen applies `trailingPaneEdge()` (ignore the inset,
  start 20 pt lower to clear the clock). It must sit on each screen; on the
  pane's NavigationStack it never reaches them.
- A pane is only about 670 pt tall. `QuestionPager` measures the regular
  question against its viewport and, if the last choice would need a scroll,
  switches to compact metrics (`compactQuestion`: smaller prompt, 36 pt tiles,
  tighter rows), decided once per question before grading. The same rule
  fits the iPhone SE. Home's Training row is a grid while split: the pane
  stops short of the fold, so a carousel clipped its last tile in mid-air.
- Phone idiom only (1.4.2): `UnfoldedSplit.make` takes the idiom, and an
  iPad keeps 1.4.1's two-column Home at every width. The first cut split
  any regular container of 720 pt or more, which turned every full-screen
  iPad into the two-pane Home.
- Fold edges come from `GeometryProxy.verticalFold()` (iOS 27.1
  `reservedRegions(.division)`), else an even split; math in
  `UnfoldedSplit`, tested in `UnfoldedSplitTests`. Same design as Vitals
  (`jackwallner/vitals`, `.claude/rules/iphone-duo.md`).
- Home's stack is one view tree: folding only moves its frame, so a screen
  pushed over Home survives fold and unfold. The trailing pane exists while
  split and, after a fold, while a screen Home opened is still in it
  (`panePath`): it then fills the phone with a back button, so a Timed
  Challenge or Game Night Prep keeps its questions, clock and score (view
  state, kept because the pane branch keeps its identity). Back empties
  `panePath` and Home shows; anything Home opens meanwhile goes into the
  pane. A room alone, or a drill opened from it, is never kept hidden (a
  hidden drill once stayed mounted while Home offered Resume for the same
  run): it goes with the fold, and its saved run resumes from Home. Home reads `layoutSizeClass`, not the raw size class:
  the environment override on the pane only reaches its children.
- The container is framed to the full width before `onGeometryChange`: a
  ZStack that shrank to Home's pane width measured "too narrow", undid the
  split, and oscillated.
- Capture: `gh-sim launch --device 'iPhone Duo'` with `--screen "-mahj.shot
  <name>"` per screen (DEBUG `DebugShot` routes; `mahj://shot/<name>` also
  works but `simctl openurl` stops on iOS's "Open in" prompt) and
  `-mahj.demoSeed YES` (a week of real practice, once per install; each
  capture launch also clears the run in progress). Local slot-11 captures
  show the home indicator across the fold, gh-sim's do not. Launch args: `-progress.hasOnboarded YES
  -mahj.hasReadPrimer YES -mahj.skillLevel some -subscription.localProOverride
  YES -mahj.suppressWhatsNew YES -mahj.demoSeed YES`. Phone devices need
  `--wait 60`: gh-sim shoots `--wait` seconds after each relaunch, and at 20
  the slow runner returned the cream launch screen.
- Full unit suite on the Duo runtime (gh-sim, iOS 27.1, 2026-10-22):
  `TrialEligibilityTests.testFreeWeekUntilTheAccountHasUsedIt` hung until
  GitHub's 60-minute job cap killed the run, and everything before it passed. Until that is fixed,
  pass `--only MahjTrainerTests/UnfoldedSplitTests` (or skip that test) on
  Duo capture runs.
