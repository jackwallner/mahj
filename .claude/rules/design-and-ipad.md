---
paths:
  - "MahjTrainer/Utilities/Theme.swift"
  - "MahjTrainer/Utilities/SoundPlayer.swift"
  - "MahjTrainer/Views/**/*.swift"
---

# Mahj: design system, iPad layout, and illustration

Moved verbatim from AGENTS.md. Loads when a matching file is read; update it here.

**AX5 main-column gap (2026-10-16):** a real build-46 Release render on iPad
Air 11-inch keeps Home in two columns at the largest text size. Room names
and the new challenge title break into fragments, with room descriptions
truncated. The main-column layout is shared with build 45; adaptive training
tiles alone do not solve it. Prefer one main column at accessibility sizes.
See `project-docs/audits/release-experience-2026-10-16.md`. This was a rendered
viewport check, not a complete interactive iPad pass.

**Layout sweep fixes (1.4.1, 2026-10-17):** a seven-device sweep (iPhone
SE, 13 mini, 17, 17 Pro Max, iPad mini, Air 11, Pro 13; L, XXXL, AX3, AX5,
landscape) drove these. Home and the Room drill grid drop to ONE column at
accessibility sizes (this closes the AX5 gap above), the Mahj+ badge stacks
under a title there, and the room/drill icon tile hides there so the name
gets the width. Subtitles wrap (`fixedSize`), never `lineLimit`. Pages that
centre a card (`HowToPlayView`, `FeatureTourView`, the onboarding info and
skill pages) use `ViewThatFits(in: .vertical)`: the designed layout first,
then (onboarding only) a compact one without the icon or subtitle, then a
ScrollView, so an iPhone SE never clips the first screen. The primer's
7-tile row takes the largest of 46/40/36/32pt that fits. Home no longer
hides the toolbar background, which had also removed iOS 26's scroll-edge
blur. The trial page and paywall were left alone (frozen). Harness:
`MahjTrainerScreenshots/LayoutSweepTests.swift` + `scripts/layout-sweep.sh`.
Home's mastery-ring caption scales with `.caption2` but caps at 12pt: a
larger cap squeezed room names into one word per line at XXXL. At AX sizes
the flashcard back scrolls its answer (scroll bar flashed) with Next pinned
below, and the deck takes the full width instead of 520pt. The What's New buttons scroll with the list at AX sizes (pinned, they covered two thirds of an SE at AX5); Done stays in the toolbar. Every change was
pixel-diffed against the pre-fix build on all seven devices; default-size
screens must stay identical.

- `MahjTrainer/Utilities/Theme.swift`: the warm-modern design system: cream
  surfaces, jade primary, coral energy, per-room accents (`Room.accent`), serif
  display type (`Theme.display`), `themedCard()`/`primaryCTA()` styles,
  `Haptics` (gated on `settings.haptics`; grading uses `correctAnswer()` /
  `wrongAnswer()`, which must feel like OPPOSITES in the hand: a crisp rising
  tap vs a dull double thud. Apple's `.success`/`.error` notification patterns
  are both stutters and read as the same buzz mid-drill). `SoundPlayer` plays the synthesized
  wavs in `MahjTrainer/Resources/Sounds` (gated on `settings.sound`;
  regenerate via a make_sounds.py-style script if changed). All colors are
  light/dark adaptive; launch screen color is the `LaunchBackground` asset
  (keep in sync with `Theme.background`).

## iPad layout: centre what underfills

Every drill body is a scroll view, because a graded question plus its coaching
note outgrows a phone. On a 13-inch iPad the same question fills a third of the
screen, and a plain `ScrollView` pins it to the top. `CenteringScrollView`
(`Views/Components/`) is the answer: `minHeight` = viewport so short content
centres, natural size so tall content still scrolls. `QuestionPager` and
`CharlestonDrillView` both use it. Two things it must keep: `maxWidth:
.infinity` alongside the `minHeight` (a plain ScrollView centres narrow content
for you, an explicitly framed one does not, and the question slides left), and
the room eyebrow INSIDE the pager (`QuestionPager.eyebrow`) so it centres with
the question instead of stranding itself at the top. The flashcard deck is
capped at 520pt wide, 1.5x tall: a card stretched to the full readable width is
the same few words spread thinner.

## Illustration: don't

Generated room art was tried and removed (2026-07-13): it looked cheap and
fought the type-and-tile aesthetic. Tiles are drawn from real data by
`TileView`/`TileRackView`; a generated tile face is a WRONG tile, and a wrong
tile teaches the wrong thing. Keep the visual language to type, tiles, SF
Symbols and the room accents.

**Tile rows (2026-09-27):** `TileRackView` balances its rows (8 tiles read 4
and 4, 13 still read 7 and 6). The flashcard front sizes tiles to its widest
row (52pt up to five across, 44 at six, 38 at seven): the deck is a ZStack, so
one wide card stretched EVERY card in the deck past the screen edge and
clipped the choice buttons. Check any new wide front on a phone.
