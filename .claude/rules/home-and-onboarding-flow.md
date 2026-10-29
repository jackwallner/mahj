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
the exact 1.3.2 layout below accessibility sizes (an earlier fit change had
moved it at L and XXXL on the SE, which the freeze forbids) and only scrolls
at AX sizes. The onboarding info and skill pages pick their designed 1.3.2
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
Every drill here opens with Mahj+." Training is a two-across grid of compact
tiles (icon square plus one title, like the room cards) on every width,
an odd last tile spanning the row, and one column at AX sizes (2026-10-29).
The scrolling carousel it replaced cut its last tile mid-word ("Game N") as
the scroll cue and sat 4 pt off the cards' edge; Jack called it out. The tour's own
"A five-minute mix" line is frozen with the trial flow and stays. Home
reads `DayClock`, so a resume on a new day redraws Get Started and the
challenge card for today.
