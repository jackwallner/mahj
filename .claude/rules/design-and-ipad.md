---
paths:
  - "MahjTrainer/Utilities/Theme.swift"
  - "MahjTrainer/Utilities/SoundPlayer.swift"
  - "MahjTrainer/Views/**/*.swift"
---

# Mahj: design system, iPad layout, and illustration

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

- `MahjTrainer/Utilities/Theme.swift` — the warm-modern design system: cream
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
