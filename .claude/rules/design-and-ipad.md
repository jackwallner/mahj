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
  (the light `Theme.background` cream in both modes, because `AppSettings.appearance`
  defaults to Light and the first frame is cream even in system dark mode).

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

**Graded question motion (2026-10-19 frame capture):** grading makes the
question taller, so `CenteringScrollView` re-centres it. Animate that from
ONE place: `QuestionPager` carries `.animation(gradeSpring, value: answered)`
on the whole pager. A per-row `.animation` left the prompt and tiles jumping
while the rows glided across the coaching note. The note fades in after the
rows settle. `questionSlide` removes the old question at once (`.identity`)
and eases the new one in from 40pt: any fade-out, even 0.1s, drew both tile
racks on top of each other for several frames. With Reduce Motion on (1.4.2)
the pager and choice rows take no spring and the scroll to the note jumps;
the note still fades in, and grading keeps its colours, icons and border.

**Rack motion (2026-10-19 frame capture, Play a Hand):** `TileRackView`
keys each tile by what it is plus which copy, never by position, and lays
every row out in one `BalancedRowsLayout`. Keyed by position, a throw or a
draw slid each slot's outline to its new place while the face inside
swapped to a different tile, and a tile changing rows faded out of one
`HStack` and into the next. The gold selection outline is always present
(opacity only): removed, it stayed fading at the old spot while its tile
slid away. A thrown tile leaves at once. Play a Hand passes
`tileInsertion: TileRackView.dropIn` so a drawn tile arrives after the gap
opens; the default stays a plain fade, because a delayed insertion on a new
Charleston deal showed only the tiles both deals share for 0.2s. Text and
cards around a moving rack (`HandPlayView.settleIn`, the Charleston coach
card) leave at once and fade in after the tiles settle, so no tile slides
across them.

**Racks fit their width (2026-11-22, 1-star review "text and tiles are
constantly cut off" on an iPhone 15 Pro):** `BalancedRowsLayout` used to
ignore the offered width. With Display Zoom a 15 Pro is 320pt wide, a
question offers its rack 268pt, and seven 44pt tiles drew 344pt: the scroll
view sheared tiles off both edges, and a flashcard front stretched the deck
and clipped its choices. A row that does not fit now closes its gaps (to
2pt), then wraps into more balanced rows at full tile size; the ideal size
(what `ViewThatFits` reads) is still the design. On a 393pt phone the
Hand Match rack's gaps close from 6 to 5.5pt. Guard: `TileRackFitTests`.

**Narrow screens are checked, not assumed (2026-11-22):** the pool's
narrowest phone is 393pt, and a simulator has no Display Zoom, so nothing
ever ran at 320pt. DEBUG `-mahj.windowSize 320x693` shrinks the app's window
(`DebugShot.resizeWindowIfRequested`); `scripts/narrow-shots.sh <udid> <out>`
shoots every room and drill at 320 and 375pt, and `SWEEP_WINDOW=320x693
scripts/layout-sweep.sh ...` walks the answered states. Run both before a
release that touches layout. The first pass found, besides the racks:
flashcard questions truncated to "You're building 2468 in craks an..." (the
stack between the card's spacers squeezed the title; titles now never
truncate, the question shrinks to 21pt with tiles at most 40pt, then
scrolls), long answers running past the card bottom (the back now scrolls
when it must), and the primer's "Recommended:..." chip.

**Release gate accessibility pass (1.4.2, 2026-10-27):** every `withAnimation`,
`.animation` and inserted `.transition` reads `accessibilityReduceMotion` and
drops to `nil`/`.identity` (`PressableCardStyle` dims instead of scaling).
Accent text goes through `Theme.readable(_:)` (darker in light, lighter in
dark) and secondary ink is `inkSecondary`/`inkTertiary`, all at 7:1 or more
on the card. Small text links grow to 44pt with `hitPadding(_:)` inside the
label plus `.padding(-insets)` on the control, so nothing moves. The launch
screen color is the light cream in both modes. At AX3 the coaching note
never scrolled into view (gate runs 4 and 5 left it behind Next): the
`ScrollViewReader` sat inside the scroll view's content, where `scrollTo`
did nothing, and grading's `onChange` fired before the note had a frame.
The reader now wraps `CenteringScrollView`, the scroll runs one main-queue
turn after the content's `onGeometryChange` reports it grown (a scroll asked
for inside the layout pass is dropped), and on iOS 18 a graded pager's
scroll view keeps its bottom on growth (`CenteringScrollView(keepsBottom:)`,
`defaultScrollAnchor(.bottom, for: .sizeChanges)`, off until graded so the
compact switch never scrolls an unanswered prompt away). The scroll uses
the `.top` anchor: clamped by the scroll range it lands where `.bottom` did
whenever the note fits, and a note taller than the screen (AX3) starts at
its first line instead of under the navigation bar. Checked by
`OrdinaryRunTests.testCoachingNoteScrollsAboveNextAtAX3`. Home's Reference button carries its label on the image: a
`NavigationLink` in the toolbar read the symbol name ("book") and dropped
a label set on the link. `OnboardingView` draws
`Theme.background` under its stage change, or the trial-to-tour transition
flashed the bare white window. Apple's contrast audit flags
text that draws at 7 to 15:1 (it samples off-element pixels); those are
accepted in `qa/ledger.jsonl` with the ratio measured off the gate
screenshot, so measure before darkening a token further.

**Experience audit fixes (2026-11-22, council of three, audit in
`project-docs/audits/experience-2026-11-20/`):**
- Grade marks use `Theme.gradeCorrect` / `gradeWrong`, not the tile pigments:
  bamGreen and crakRed fell under 3:1 on the tinted rows in dark mode.
- Play a Hand places the prompt and rack from their measured height plus a
  fixed note reserve (`noteReserve`), not by centring the whole stack, so a
  verdict of any length grows downward and the rack never moves. Next's
  room is held by a hidden copy; the real button still comes and goes, so
  its label never flips while it fades.
- `StablePageTop` (primer and tour) gives every page the top edge the
  tallest page would have. Where the tallest page does not fit, pages share
  the top of the screen; centring them is what made titles jump.
- `ConfettiBurst` from an answer row waits 0.35s for the row to settle, and
  hosts pass `scope` (the question) so Next inside the wait cancels it: the
  answer row reports its frame before it is answered, so a late burst fired
  from the next question's right answer.
- A missed rack question whose prompt and rack fill over 55% of the screen
  repeats the rack at 32pt above the explanation, because the scroll to the
  note takes the real rack away. Captions need 32pt: FLOWER cut to "FLO..."
  at 26. The copy is one combined accessibility element, never hidden: hidden,
  its drawn captions failed the gate's Apple audit ("Potentially inaccessible
  text").
- The iPad plan sheet (item 22, Jack's go-ahead) opens at `.page` size and
  shows all three plans in both orientations. `.form.fitted` collapsed it to
  the footer: a ScrollView has no ideal height. The footer is capped to the
  plans' 680pt, and the hard top edge is regular width only, because on
  iPhone it drew a divider under Close at rest and the frozen paywall must
  stay pixel-identical there. Lifetime stays third on iPhone (item 8, Jack).

**XCUITest and the accessibility tree (iOS 27, 2026-11-23):**
- XCUITest still lists SwiftUI views marked `accessibilityHidden(true)`. To take
  an element out of the tree (the deck's back cards, the KNEW IT / AGAIN stamps),
  remove the view or strip its label and traits; hiding alone does not.
- XCUITest `tap()` and coordinate presses do not flip a flashcard (its
  `DragGesture` has `minimumDistance: 0`); real HID taps do. A harness quirk,
  not an app bug: drive flips with a swipe or a real tap.

**Tiles follow the text size (1.4.7, 2026-11-24):** a Mahj teacher said
phone tiles are too small for kids and older players. Jack chose the iPhone
text-size setting over an in-app size setting. `TileView.scale(for:)` is the
one place: 1x up to Large (smaller text never shrinks a tile), 1.1 at XL,
1.2 at XXL, 1.3 at XXXL, 1.4 at every accessibility size, and no tile wider
than `TileView.maximumWidth` (72pt). Call sites keep passing their designed
width; `TileRackView`'s highlight outline scales with it. 1.4x is the cap
because a 13-tile rack in a 320pt Display Zoom question (268pt) still fits
four a row. `BalancedRowsLayout` now spreads tiles evenly across its rows
(13 four a row read 4, 3, 3, 3, never 4, 4, 4 and a lone tile; 5 a row read
5, 4, 4). The Monthly Challenge answers' own AX bump (30 to 36pt) is gone:
the shared scale covers it. The onboarding info pages' 54pt rack is the one that
does not grow (`.dynamicTypeSize(...large)`): grown, it broke 2 and 2 at
XXXL on a 320pt phone and pushed the copy under the page dots.
`CenteringScrollView` flashes its scroll bar on appear, since a big-text
question with its rack can run past the footer.

Fixed alongside (all checked on a 320x693 window): the onboarding pages
clip at their own bottom (`.clipped()` on the paged TabView) and every
scrolling fallback ends 10pt above the page dots, so copy never draws across
them; the info pages' scroll fallback drops the icon so the first screen
shows copy at XXXL. The onboarding footer and Play a Hand's status line and
held Next room cap at AX1: at AX5 the pinned price, terms and trial button
outgrew the screen and drew over the trial page, and Play a Hand showed one
rack row. Play a Hand's status scrolls with the rack at AX sizes, the target
and fit count sharing a line where they fit; the whole 13-tile rack is on
screen at AX5. Guard: `TileRackFitTests`.
