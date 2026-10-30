---
paths:
  - "MahjTrainer/RootView.swift"
  - "MahjTrainer/Views/HomeView.swift"
  - "MahjTrainer/Views/RoomView.swift"
  - "MahjTrainer/Views/OnboardingView.swift"
  - "MahjTrainer/Views/HowToPlayView.swift"
  - "MahjTrainer/Views/FeatureTourView.swift"
  - "Shared/Services/ProgressStore.swift"
---

# Mahj: Home, rooms, and the onboarding flow

Moved verbatim from AGENTS.md. Loads when a matching file is read; update it here.

**Large text in onboarding (fixed builds 47 and 51):** at accessibility
sizes the onboarding pages, the `HowToPlayView` primer (47) and the
`FeatureTourView` tour (51) put the page in a ScrollView, keyed by page so
each one opens at the top, with the buttons pinned below. Before that, the
primer and the tour pushed Continue / Show me and both escape hatches off
the screen, a dead end even for a player who had just started a trial.
Default text sizes keep the 1.3.2 layout exactly. Evidence for the original
gap: `project-docs/audits/release-experience-2026-10-16.md`.

**Fit fixes (1.4.1 build 54):** every fix is conditional on fit or text
size, never on device, so the designed layout still runs wherever it fits.
The primer's page swipe is off inside its ScrollView fallbacks
(`movingCard(swipes:)`): a drag gesture on the scroll content swallowed the
scroll, so an SE could not reach the "Play a turn" tip. The trial page keeps
the exact 1.3.2 layout below accessibility sizes wherever its benefit rows
fit at full height (an earlier fit change had moved it at L and XXXL on the
SE, which the freeze forbids) and always scrolls at AX sizes. Below AX it
picks through `ContentFit` (2026-10-30, Jack's go-ahead via the overnight
bug hunt): the designed page, then the page without the icon, then a
ScrollView. On an SE at default size the 1.4.1 rows and every translation
had been cut off mid-sentence (3 of 5 rows in English, all 5 in fr and vi);
a row is now never cut. Default size on larger phones is pixel-identical.
Guard: `MahjTrainerScreenshots/TrialPageFitTests` (six languages, both
benefit arms) on `gh-sim test --scheme Screenshots --device "iPhone SE (3rd
generation)"`. The onboarding info and skill pages pick their designed 1.3.2
layout through `ContentFit`, which measures the content alone plus one gap:
a plain `ViewThatFits` also demanded room for the spacers, and on a 13 mini
(where 1.3.2 fit only by squeezing them out) it swapped in the compact page
at default text size. The onboarding info page without an icon packs its text with
zero spacers, and the info/skill ScrollView fallbacks flash their scroll bar
per page so a player can see there is more.

- `MahjTrainer/Views`: `RootView` branches onboarding vs `HomeView` on the
  `progress.hasOnboarded` defaults key (branch, NOT a fullScreenCover — the
  cover flashed Home behind onboarding on first launch). Navigation is a LOBBY:
  `HomeView` shows Get Started (mixed session) + one card per room; `RoomView`
  lists that room's drills, with the locked Mahj+ set and an in-room upsell.
  Home's job is the ROOMS, so everything else earns its space: stats are chips
  beside the title (not a row of their own), room cards carry a progress RING
  rather than a status sentence, that ring counts only drills the player can
  actually open, and the How to Play card disappears once the primer has been
  read (`mahj.hasReadPrimer`), living in Settings after that.
  (Home was flat until 2026-07-13; once every room grew an extra set, a dozen
  drill rows on one screen stopped reading as rooms.) Onboarding stores skill level
  at defaults key `mahj.skillLevel`. After the trial decision, players who
  selected `new` see `HowToPlayView` first, then everyone gets
  `FeatureTourView`, whose finale runs a real Quick Session. Both of those
  screens carry an ESCAPE HATCH straight to Home ("Skip for now" / "Skip the
  tour" / "Skip it, take me to the app"): onboarding is long, and a player who
  wants to just use the app must always be one tap from doing so. The primer
  stays available from Home for new players and from Settings for everyone.
  `HowToPlayView` pages by swipe as well as by buttons, and its Back button
  sits NEXT to Continue, not in the top-left corner a thumb can't reach.

**1.4.2 copy cuts (Jack's bar: no taglines, helper text or secondary
labels; fix the layout instead).** Home lost "Your seat at the table.", the
Get Started subtitle and the "SWIPE FOR MORE" label over Training; the
challenge screen lost its rules footnote; a locked room lost "Look around.
Every drill here opens with Mahj+." The Training carousel signals that it
scrolls by always ending about 40% into a tile (`TrainingCarousel`, sized
with `containerRelativeFrame`, tested in `HomeLayoutTests`): at a fixed
128 pt a 440 pt phone showed exactly three whole tiles. Inside a tile
(2026-10-29, Jack: the info was misformatted): a tinted icon square and the
lock on top, then the single-line title (wrapping on its own, at most two
lines) and its badge, all hung from the top edge. The old tile pinned a
forced two-line title to the bottom with a blank badge line, so titles sat
on different lines across the row. The tour's own
"A five-minute mix" line is frozen with the trial flow and stays. Home
reads `DayClock`, so a resume on a new day redraws Get Started and the
challenge card for today.
