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
- Capture: `gh-sim all --device 'iPhone Duo'` with DEBUG `mahj://shot/<name>`
  routes (`DebugShot`) and `-mahj.demoSeed YES` (a week of real practice,
  once per install). Launch args: `-progress.hasOnboarded YES
  -mahj.hasReadPrimer YES -mahj.skillLevel some -subscription.localProOverride
  YES -mahj.suppressWhatsNew YES -mahj.demoSeed YES`.
