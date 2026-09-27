---
paths:
  - "Shared/Content/PlusContent.swift"
  - "Shared/Content/ProContent.swift"
  - "Shared/Content/DrillLibrary.swift"
  - "Shared/Content/SessionBuilder.swift"
  - "Shared/Models/Drill.swift"
  - "Shared/Services/SubscriptionService.swift"
  - "MahjTrainer/Views/OnboardingView.swift"
  - "MahjTrainer/Views/PaywallView.swift"
  - "MahjTrainer/Views/RoomView.swift"
  - "docs/tasks/03-pricing-increase-1.3.md"
  - "MahjTrainerTests/PaywallFunnelTests.swift"
---

# Mahj: the free-beginner model and the onboarding trial

Moved verbatim from AGENTS.md. Loads when a matching file is read; update it here.

**Free-beginner + extra-sets model (2026-07-13):** all four beginner rooms are
FREE and everything that was ever free stays free. Mahj+ ADDS: one extra
practice set per beginner room (`Shared/Content/PlusContent.swift`, drills
flagged `isPlus`, ids `plus-*`, same mechanics as the room's free drills, just
more original questions) plus the whole `pro-tables` room, now shown as **The
Master Tables** (`Shared/Content/ProContent.swift`). Locking is per-drill:
`Room.isLocked(_:isMember:)` is the single source of truth, and `SessionBuilder`
filters the Quick Session pool through it. The onboarding trial page
follows the OT710 zero-shift pattern (`~/OT710.md`, StatScout reference): no
plan cards, soft "Get Started" exit ABOVE the primary, primary CTA in the exact
Continue slot, one tap → MONTHLY trial purchase → Apple confirm; full
`PaywallView` (plan picker) is only the products-failed fallback and the
in-app/Settings paywall. A user backing out of Apple's sheet is a
`PurchaseOutcome.cancelled`, NOT an error: never answer it by shoving up
another paywall.

Monthly here, yearly on the paywall, deliberately (confirmed 2026-09-04): two
different people reach the two surfaces. Whoever taps through onboarding has
not used the app yet and is reacting to the number on Apple's sheet, so the
smaller recurring figure is what starts the trial; whoever opens the paywall
later has already decided the app is worth something, and it still leads with
yearly. `OnboardingView.trialDisclosure` must always name the SAME plan the CTA
buys, or the screen misstates the charge (3.1.2). The 100%-yearly funnel in
`docs/tasks/03-pricing-increase-1.3.md` predates this and describes the old
onboarding, not the current one.

**3.1.2(c) price line (2026-09-27):** 1.3.0 was rejected on an iPad Air
because the trial outshone the billed amount (1.2.1, same design, had passed:
reviewer variance). Fix is Cribbage Trainer's approved one, ported as-is: a
22pt `trialPrice` ("$9.99/month") above the caption disclosure, in a slot
reserved on every page so the CTA never moves. Nothing else on the page
changed. Cribbage, Skat and Sheepshead all passed with this pattern, and it
did not track with lower trial rates across the card apps (Aug 13 to Sep 26:
Mahj 31% small line, Bridge 9% small line, Cribbage 24% big price).
