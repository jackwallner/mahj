---
paths:
  - "MahjTrainer/Views/HomeView.swift"
  - "MahjTrainer/Utilities/UnfoldedSplit.swift"
  - "MahjTrainer/Utilities/DebugShot.swift"
---

# Mahj: iPhone Duo (2026-10-22)

- Unfolded (regular width, at least 720 pt), `HomeView` is two panes: Home
  (the lobby, phone layout) on the leading side of the fold, a room on the
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
  (`OrdinaryRunStore.onScreenID`, set by `OrdinaryRunEntryView`).
- iOS 27.1 quirks (2026-10-25): toolbar items stack in a column down each
  pane's trailing edge, so Home hides its navigation bar while split and
  draws the book and gear in its header. The status column's trailing inset
  reaches both panes the whole way down: Home's ScrollView ignores it, and
  every trailing-pane screen applies `trailingPaneEdge()` (ignore the inset,
  start 20 pt lower to clear the clock). It must sit on each screen; on the
  pane's NavigationStack it never reaches them.
- The split also runs on a full-screen iPad (regular, wider than 720 pt):
  Home's two-column iPad layout only remains for regular widths too narrow to
  split. Re-shoot the iPad set before the next iPad screenshot upload.
- Fold edges come from `GeometryProxy.verticalFold()` (iOS 27.1
  `reservedRegions(.division)`), else an even split; math in
  `UnfoldedSplit`, tested in `UnfoldedSplitTests`. Same design as Vitals
  (`jackwallner/vitals`, `.claude/rules/iphone-duo.md`).
- One view tree: folding only moves frames. The trailing pane is mounted the
  first time the Duo unfolds and then kept (hidden when folded), so an open
  drill survives fold and unfold. Never swap layouts with an `if` around the
  panes. Home reads `layoutSizeClass`, not the raw size class: the
  environment override on the pane only reaches its children.
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
  YES -mahj.suppressWhatsNew YES -mahj.demoSeed YES`.
- Full unit suite on the Duo runtime (gh-sim, iOS 27.1, 2026-10-22):
  `TrialEligibilityTests.testFreeWeekUntilTheAccountHasUsedIt` hung until
  GitHub's 60-minute job cap killed the run, and everything before it passed. Until that is fixed,
  pass `--only MahjTrainerTests/UnfoldedSplitTests` (or skip that test) on
  Duo capture runs.
