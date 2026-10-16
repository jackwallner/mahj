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
