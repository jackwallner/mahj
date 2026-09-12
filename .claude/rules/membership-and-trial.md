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

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

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
