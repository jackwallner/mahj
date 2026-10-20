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

**The trial flow is frozen at 1.3.2 (2026-10-16).** Jack's ruling after the
1.4 audit: the onboarding trial page and the paywall convert well, so their
copy, layout and order stay exactly as shipped in 1.3.2. "Try Mahj+ free",
"Start 7-day free trial" / "Start 7-Day Free Trial", "7 days free, then
$X. Auto-renews until canceled." for every account, and nothing between the
purchase and the tour. 1.4.0 (build 45, pulled before release) had added
Apple-eligibility gating ("Subscribe" / "Get Mahj+" for ineligible or
unknown accounts) and a trial-end reminder screen after purchase; build 47
removed both and verified the trial page pixel-identical to 1.3.2 at default
text size (paywall identical bar the Home behind the sheet). Accessibility
sizes may lay out differently, since they scroll. iPad keeps 1.3.2's full
width too: build 52 removed a 760pt readable-width cap from the onboarding
pages and footer that had narrowed the trial CTA on large iPads. A reinstalled member is
still synced from StoreKit before the purchase runs, and `startedTrial`
comes from the entitlement, not the product.

**Remote knobs (`Shared/Services/RemoteConfig.swift`, 1.4.1).** Vitals'
pattern: every variant ships in the binary and the current offering's
metadata picks one; a missing or unknown value is the control, which is
exactly 1.3.2. Every variant aims at paid value (LTV), never at the free
path, and every one keeps the 3.1.2 disclosures.

| Key | Control | Variants |
|---|---|---|
| `trial_cta` | `seven_day` ("Start 7-day free trial") | `my`, `your` |
| `trial_title` | `try_free` ("Try Mahj+ free") | `game_night` ("Get ready for game night") |
| `trial_benefits` | `reassure_first` (free rooms first, then coached practice hands) | `paid_first` (leads with coached practice hands, no free-rooms line) |
| `onboarding_plan` | `monthly` | `yearly` (price line, disclosure and purchase all follow) |
| `offer_pitch` | `benefits` (the trial sheet's three benefit lines) | `timeline` (how the free week runs, real dates), `split` (in-app 50/50, see below) |

Test one key at a time as a RevenueCat Experiment (second offering, same
packages, only that key differs) and promote the winner by making its
offering the default. Every picked value rides to RevenueCat as a customer
attribute under its key.

Off switches (`RemoteSwitch`), on unless the value is exactly `off`:
`att_prompt` (Apple's tracking prompt for Meta), `rating_prompt`
(Apple's rating prompt) and `monthly_challenge` (the challenge card and
its link, from 1.4.1 build 54). Set a switch the SAME on every offering, default
and any experiment arm, or the experiment flips it as a side effect.

DEBUG builds pin any key with the launch argument `-mahj.rc.<key> <value>`
(`MetaAndCTARenderTests` uses it). Any change to the trial flow beyond
these variants needs Jack's explicit go-ahead first.

Running since 2026-10-16: experiment `expfa8555d5ee` ("Trial button: 7-day vs
my (1.4.1+)") in project `proj28030dc2`, control `default` (no metadata) vs
`cta_my` (`trial_cta: my`, same three packages and products). New customers
only, 100%, pinned audience App Store app `app171fd011b0` with app version
>= 1.4.1, so 1.3.2 and Android never enrol. It went live with TestFlight
build 47, so a few test installs are in the counts. Primary metric initial
conversion; read trials started per viewer. Created through `rc api POST
/projects/<id>/experiments` and `.../actions/start` (targeting is immutable
once started; RevenueCat stores it as `pinned_audience`).

Decision rule (Jack, 2026-10-16): no 95% bar. The control is proven and a
winner flips back remotely, so after about 3 weeks live take the arm
RevenueCat shows at 75% chance to win or better on initial conversion; if
neither gets there by about 5 weeks, stop and keep 7-day. Promote "my" by
setting `cta_my` as the default offering.


**Plain-words pitch (1.4.1, 2026-10-19):** with the Mahj Minute free for everyone, the Mahj+ pitch leads with practice hands. Jack first asked for "unlimited hands", then cut the mode name: a new player does not know what "Play a Hand" is. Every surface now says "coached practice hands, as many as you want" (trial page benefits, paywall's first benefit, pitch card, Home's Get Mahj+ row, room upsell). `TrialOfferPacerTests` fails any benefit line that names "Play a Hand". Only wording changed on the trial page; its layout, CTA and plan are untouched.

**One-tap trial sheet (1.4.1, 2026-10-19):** results pitch through `TrialOfferSheet` (Vitals pattern), never a card that opens the full paywall: one plan (the onboarding page's, `onboarding_plan`), and its CTA goes straight to Apple's sheet. It carries every 3.1.2 element (price as the largest price text, `PaywallPricing.terms`, Terms, Privacy, Restore). It falls back to `PaywallView` only when products fail to load. A tap on a Mahj+ card or the free-hand-spent upsell opens it at once. It also rises on its own 1.2s after a good result (drill at least half or a deck, Minute at least half, the free hand spent), paced by `TrialOfferPacer` (Jack 2026-10-19: sessions for day 0 and day 1, days for the tail): not before the 2nd practice after onboarding; on install day and the next calendar day, once per app session and at most 3 a day (Jack: a cap, but more than the tail allows; a return after 30 minutes away is a new session, counted by `noteForeground`/`noteBackground` from the scene phase); after that, at most once in 3 days, then 7, then every 14. Install day is `ConversionDiagnostics.installDate`, so an upgrader is day-paced from the start. The rating prompt stands down for 120s after an automatic ask. `trial_offer: off` stops the automatic asks without a release. RevenueCat sources: `mahj_offer_drill|minute|hand`, with `_auto` for automatic asks, so tapped and automatic asks can be compared. Intro-offer eligibility (Luna review, 2026-10-19): Apple gives one free week per subscription group, so the sheet asks StoreKit (`SubscriptionService.isTrialEligible`, unknown reads as eligible). An account that already had it never gets an automatic ask; a tapped card shows "Everything in Mahj+, starting today", the benefits list, `PaywallPricing.terms(..., trial: false)` ("billed today") and "Join Mahj+". The tap re-checks eligibility after offerings load and redraws instead of buying if it changed. It also refuses to sell while a reinstall's StoreKit sync (`isRecoveringMembership`) is still running. The frozen onboarding page and paywall are unchanged. Upgraders from 1.3.2 get `sessionsAtOnboarding` stamped once to `min(totalSessions, 1)` (the tour's practice), so their two practices are their own.

**Trial sheet pitch test (1.4.1, 2026-10-19):** `offer_pitch` picks the sheet's body: `benefits` (control) or `timeline` (Today / By <date>: cancel and pay nothing / <date>: your plan begins; "cancel by" is the day before the trial ends because Apple renews unless canceled 24 hours ahead; no reminder is promised because the app sends none). It runs IN THE APP, not as a RevenueCat Experiment: Experiments enrol only new customers, one experiment each, so it would steal the trial button test's traffic and miss the existing free players who make up most of the sheet's audience. `split` deals each player one arm for good (`trialOffer.pitchArm`), and every sheet view records the arm shown as the `offer_pitch` customer attribute. Read it with `python3 scripts/offer-pitch-readout.py` (sheet viewers, trials started on the sheet via `converted_surface` `offer_*`, chance to win). Volume is small (a few hundred viewers a month), so only a bold difference like this one can read out; do not spend it on word swaps. Live since 2026-10-19: `offer_pitch: split` on both `default` and `cta_my` (older builds ignore it). Deploy the winner by setting `offer_pitch` to it on every offering; set it the same on every offering, or the trial button experiment flips it.

