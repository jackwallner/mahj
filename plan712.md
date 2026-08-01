# Mahj Trainer — pre-App-Store plan (2026-07-12)

Detailed, resumable plan for everything remaining before we publish. Written by
the orchestrator (Opus) after a full grounding pass over the codebase and the
fleet ASC/fastlane tooling.

---

## 0. Status so far (this session)

- DONE: Support/feedback email changed to `jackwallner+m@gmail.com` in-app
  (`MahjTrainer/Views/SettingsView.swift`) and across `docs/` (support, terms,
  privacy-policy) + the project guide. (Appfile `apple_id` intentionally left as
  the developer login, not a support address.)
- DONE: American Mah Jongg accuracy audit -> `docs/audits/mahjong-accuracy-2026-07-12.md`.
  Fixed the recurring "mahj jongg" misspelling (should be "Mah Jongg") in
  `TileBasicsContent.swift` (4) and `KeepDiscardContent.swift` (1). Content is
  otherwise accurate. TWO nuanced rules FLAGGED for your call (see 6.A).
- STAGED: resumable task briefs `docs/tasks/01-accuracy-audit.md` (done) and
  `docs/tasks/02-quick-session-rebuild.md` (ready to execute).
- All edits are currently UNCOMMITTED on `main`.

## 1. Decisions locked (from you)

1. Localization = ASC metadata only (all ~50 locales), like the other apps.
   NOT in-app string localization for v1 (drill content stays English).
2. Dopamine = haptics + sound + confetti with streak escalation. Full-screen
   effects allowed.
3. Quick Session = choice-only. Drop plain flashcards; use quiz + hand-match +
   CardChoice cards. Charleston stays a room drill (too interaction-heavy).
4. Multiple-choice answer position must be varied (not always top).

## 2. Orchestration model

- Work runs as a STRICT SEQUENCE (one agent at a time), Sonnet
  (`claude-sonnet-5-thinking-high`) preferred. NOTE: the Claude/fleet models
  ("luna/terra/sol") are not available inside Cursor; "sonnet" here = Cursor's
  Sonnet. If background Sonnet subagents stall (the fleet was hitting rate-limit
  cooldowns today), the orchestrator does the task directly in-session instead of
  waiting.
- Resumability: every task has a brief in `docs/tasks/NN-*.md` with a progress
  checklist and a "resume protocol"; agents commit incrementally with
  conventional-commit messages and do NOT push / do NOT bump build numbers.
  Respawn = read the brief + `git log` + continue from the first unchecked box.
- Order is dependency-driven: content correctness (done) -> app code -> then
  screenshots + metadata (which depend on final UI/content) -> final sim pass ->
  ship.

## 3. Task 2 — Quick Session rebuild + answer variety + harder dopamine

Full spec: `docs/tasks/02-quick-session-rebuild.md`. Summary:

- Root cause of the current glitch/skip: `MixedSessionView` packs three
  heterogeneous item types (plain-flashcard flip + self-grade, CardChoice cards,
  quiz, hand-match) plus a per-switch `SessionBeat` interstitial. The mixed
  grading paths + beat/transition interplay is what feels like it "skips the
  right answer." Fix = rebuild as ONE uniform choice flow.
- New `QuickSessionView` + builder producing a normalized single-select
  `QuickItem` (prompt, tiles, choices, answerIndex, explanation, sourceLabel)
  from: quiz questions, hand-match (choices = category names), and CardChoice
  flashcards. Exclude plain flashcards and Charleston. Keep the missed>unseen>
  review tiering and the free/Pro filter from `SessionBuilder`.
- Uniform flow: pick -> grade immediately -> correct answer highlights and HOLDS
  -> explicit Next -> `DrillCompleteView`. No auto-advance, no per-item beat.
- Move shared `QuestionPager` + `ChoiceList` out of `MixedSessionView` into
  `MahjTrainer/Views/Components/QuestionUI.swift` so `QuizDrillView` /
  `HandMatchDrillView` keep compiling; then delete `MixedSessionView`.
- Answer-position variety EVERYWHERE (quick session, QuizDrillView,
  HandMatchDrillView, CardChoice cards): deterministic per-item choice shuffle
  seeded by item id (stable across re-render/undo/back), remap the correct index,
  guarantee not-always-index-0. Do NOT edit authored `answerIndex` in content
  (keeps `ContentValidityTests` canonical).
- Dopamine: escalate the correct-answer landing (bigger pop/glow/shine +
  confetti + success haptic/sound, all already gated on settings). Add an
  in-session consecutive-correct streak with milestones (3/5/10 -> more
  confetti, stronger haptic, brief "N in a row!" banner). Miss = gentle existing
  feedback, resets streak. Reuse `Haptics`, `SoundPlayer`, `ConfettiBurst`,
  `.shine`/`.winGlow`; no new sound-asset binaries.
- Wire `HomeView.getStartedCard` to the new view; grep-replace all
  `MixedSessionView`/`MixedItem`/`dailyMix` refs.
- Verify: `xcodegen generate` -> build -> `-only-testing:MahjTrainerTests`. No
  heavy UI automation here.

## 4. Task 3 — Learn to Play back-nav + end recommendation; tour finale

Files: `MahjTrainer/Views/HowToPlayView.swift`, `FeatureTourView.swift`,
`OnboardingView.swift`, and `Shared/Content/HowToPlayContent.swift`.

- HowToPlayView currently only goes forward ("Continue"/"Take your seat"). Add
  BACK navigation: a back chevron/button that decrements `index` with the
  reverse transition, disabled on page 0. (Also fine to allow a back swipe, but a
  visible control is the requirement.)
- End-of-primer recommendation: the final page (`htp-ready`) should recommend a
  room to go practice, mapped to onboarding skill level (`mahj.skillLevel`):
  new -> Tile Room, basics -> Card Room, played -> Table Room. Add a clear CTA.
  When run standalone (from Home/Settings) it dismisses; in onboarding it should
  finish onboarding and land the player in a good next step (Home with the
  recommended room obvious, or auto-open Quick Session). Implementer picks the
  cleanest wiring (e.g. a one-shot `@AppStorage` hint HomeView consumes) but the
  recommendation must be a real, tappable next action, not just text.
- Feature tour: the misleading bit is the FIRST tour page's "Get Started" hero,
  which renders a play button that looks launchable but is not (it is mid-tour).
  Reorder `tourPages` so the Get Started / Quick Session beat is LAST, and make
  that finale's primary CTA a genuinely actionable "Start my first session" that
  finishes the tour and opens a real Quick Session (for new players who then get
  How-to-Play, sequence so the last actionable session-start is not shadowed by a
  following screen — e.g. run How-to-Play before the Get Started finale, or let
  the finale hand off into the primer's end recommendation). Remove any
  fake-clickable session affordance from earlier pages.
- Verify: build + unit tests; quick sanity that onboarding still flips
  `hasOnboarded` and both skill paths reach Home.

## 5. Task 4 — ASC metadata + 50-locale localization + push

Reuse the baseball (StatScout) template — it is the canonical fastlane app.

- Copy into `mahj/scripts/`: `asc-supported-locales.json` (the ~50-locale list),
  `asc-add-missing-localizations.py`, and confirm `asc-upload-metadata.py`
  (already present) + add `pull-appstore-metadata.sh`/`upload-appstore-metadata.sh`
  patterns. ALWAYS run a metadata pull/snapshot before editing so any ASC web-UI
  edits are not clobbered.
- Finalize en-US metadata FIRST (`fastlane/metadata/en-US/`):
  - Keep the NMJL non-affiliation disclaimer (already in description).
  - ADD the auto-renewing-subscription disclosure Apple requires near the
    description end: product names + prices ($1.99/mo, $9.99/yr, $29.99 lifetime),
    1-week free trial on subs, "payment charged to your Apple ID; auto-renews
    unless canceled 24h before period end; manage in Account Settings," plus
    Terms (EULA) + Privacy links. In-app onboarding already links Apple's standard
    EULA + the privacy page; mirror that here.
  - Verify subtitle (<=30 chars), keywords (<=100 chars, comma-sep), promo text.
- Translate the full en-US set into every locale in `asc-supported-locales.json`,
  create `fastlane/metadata/<locale>/` for each, KEEP the disclaimer + sub terms
  in each localized description. Then push with the fastlane upload / ASC script
  (metadata only, no binary, no submit-for-review).
- Deliverable: all locale dirs populated + a successful ASC metadata upload.

## 6. Task 5 — App Store screenshots (frame + real captures)

- Device family is iPhone-only (`TARGETED_DEVICE_FAMILY: "1"`). Target the
  REQUIRED 6.9" set: exactly 1320 x 2868 portrait. (6.5" optional; skip unless
  trivial. Do NOT guess sizes: 1320x2868 is the 6.9" spec.)
- Ensure `agent-mahj` is a 6.9" device (iPhone 16 Pro Max class) so raw captures
  are 1320x2868; otherwise create/boot one. Headless only; never open
  Simulator.app.
- Build a custom, on-brand device FRAME (warm cream/jade, serif display type to
  match `Theme`) with a short headline per shot, real screenshot composited
  inside, output at exactly 1320x2868. Make it more distinctive than the fleet
  default (target audience: new American Mah Jongg players, mostly not
  20-something gamers — warm, confident, uncluttered, legible).
- Shot list (6-8), headlines derived from onboarding value props:
  1. Quick Session correct-answer moment ("Practice between games").
  2. Rack-reading hand-match ("Read the rack, name the section").
  3. Keep-or-throw judgment card ("Make the call, learn the why").
  4. Charleston pick scenario ("Beat Charleston nerves").
  5. Home with streak/rooms ("Five minutes a day. It sticks.").
  6. Tile Room basics ("Meet every tile").
- Capture flow: `agent-sim boot mahj` -> install/launch -> use `axe` to drive to
  each screen -> `agent-sim screenshot mahj` -> composite into frame -> place in
  `fastlane/screenshots/en-US/`. (Screenshots can stay en-US only for all
  locales unless you want localized text overlays.)

## 7. Task 6 — Final verification (single pass)

One Sonnet/Opus sim pass at the very end (per your "don't get in the weeds"):
`xcodegen generate` -> build -> full `MahjTrainerTests` -> boot `agent-mahj` ->
walk onboarding (both skill paths), a Quick Session (correct + wrong + streak),
each room drill once, Settings (verify email = jackwallner+m@gmail.com),
paywall/trial copy. Fix anything broken, then ship.

## 8. App Store readiness gaps (must clear before submit)

- A. RESOLVE the two flagged rules in the accuracy audit:
  - F1 joker-exchange "must draw first / dead hand" claim (TileBasics
    `quiz-joker-exchange`, ProContent `pro-def-joker-swap`).
  - F2 blind-pass timing (`ch-blind`).
  Confirm against your NMJL source; I will apply the one-line copy edits.
- B. Subscription legal in metadata (see Task 4) — REQUIRED for auto-renewing
  subs or review rejects.
- C. Privacy: confirm `https://jackwallner.github.io/mahj/privacy-policy` is
  LIVE (repo Pages, main/`docs`), and terms/support pages resolve. Fill the ASC
  App Privacy questionnaire: RevenueCat collects Purchases + Identifiers (linked
  to user, for app functionality; not used for tracking).
- D. Age rating questionnaire: 4+. "Simulated gambling" = NO (trainer, no
  wagering/chips/betting). Say so explicitly.
- E. Review notes for Apple: state plainly that all hands are ORIGINAL teaching
  hands illustrating stable category families, NOT copied from the copyrighted
  NMJL card; app is unaffiliated with NMJL (disclaimer in-app + description).
  Include how to test Pro (StoreKit/sandbox) and trial terms.
- F. Verify OT710 trial page shows price + trial terms near the CTA (it does:
  `yearlyDisclosure`), and the products-failed PaywallView fallback works.
- G. App icon final + launch screen (`LaunchBackground` asset) verified in light
  + dark; `UILaunchScreen` present in Info.plist (fleet gotcha).
- H. Confirm StoreKit products exist in ASC (monthly $1.99 / yearly $9.99 /
  lifetime $29.99) with 1-week free trial on both subscriptions (fleet rule:
  keep monthly trial).

## 9. Ship sequence (after Tasks 2-8)

1. Commit all work (conventional commits), then push `main` (also publishes the
   docs/ Pages site with the new email).
2. `./scripts/testflight.sh` (bumps build, archives, uploads) — per fleet rule,
   on every push that changes app code.
3. Metadata: pull/snapshot -> upload localized metadata + screenshots (no submit).
4. Fill ASC App Privacy + age rating + review notes.
5. Submit for review — CONFIRM WITH JACK before hitting submit.

## 10. Open questions for you

1. F1/F2 flagged rules: keep as written, or soften once you check your NMJL
   source? (I will not change rules copy without your OK.)
2. Screenshot headline voice: use the derived headlines in Task 5, or do you
   want a specific angle/tagline?
3. Custom EULA, or Apple's standard EULA (currently linked in onboarding)?
4. OK to auto-upload a TestFlight build after the code tasks land (fleet
   default), and to push localized metadata to ASC now — holding only the final
   "Submit for Review" for your explicit go?
