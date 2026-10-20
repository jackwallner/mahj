# Brief: end-to-end review of Mahj 1.4.1 against 1.3.2

You are reviewing every user-facing and behavioural difference between the
shipped Mahj Trainer 1.3.2 and the release about to be submitted.

- Baseline: commit `eaf14d5` (1.3.2 build 37, live on the App Store).
- Candidate: `origin/main` at the time you start (`git fetch` first). The
  release is being renamed from 1.4.2 back to 1.4.1 (1.4.1 was cancelled in
  review and never approved, so the number is free); treat "1.4.1" and
  "1.4.2" in comments and notes as the same release.
- Scope: `git diff eaf14d5 origin/main` minus `android/`, `docs/`,
  marketing images and screenshot art. That is about 400 files; read the app
  code (`MahjTrainer/`, `Shared/`), tests, `project.yml`, `supabase/`, and
  the rules in `.claude/rules/` that the diff touches.

## What to check

1. **Correctness:** crashes, state bugs, wrong locking (`Room.isLocked` is
   the single source of truth), purchase and restore paths, RevenueCat
   remote config (`Shared/Services/RemoteConfig.swift`), the new one-tap
   trial sheet and its pacing (`TrialOfferSheet`, `TrialOfferPacer`), the
   Mahj Minute as the monthly challenge's free daily round, the ATT prompt
   (only after a trial or purchase), the rating prompt, What's New, Play a
   Hand's free hand.
2. **The frozen trial flow:** the onboarding trial page, paywall and
   purchase-to-tour must be exactly 1.3.2 apart from the approved remote
   copy variants (see `.claude/rules/membership-and-trial.md`). Flag any
   drift.
3. **App Review risk:** 3.1.2 (every paywall-like surface shows name, price,
   period, auto-renew terms, Restore, Terms, Privacy), 5.1.2 (ATT and
   privacy labels), 4.3/2.3, 1.4.1 framing, in-app event deep links.
4. **Content rules:** original hands only (never NMJL card hands),
   card-dependent claims, no em dashes in any user-facing copy.
5. **UX regressions:** anything a 1.3.2 player would find worse,
   confusing or broken on update; large text, iPad, iPhone SE, iPhone Duo.

## How to work

- Read-only on app code: do NOT edit, commit, push, build for TestFlight,
  or touch App Store Connect or RevenueCat. Another session is releasing
  from this checkout.
- You may run tests: prefer `gh-sim test` (GitHub Macs, includes uncommitted
  changes, at most 2 runs; never pass secrets). Do not use the local
  simulator pool.
- Verify each finding against the code before reporting it; drop anything
  you cannot point to a file and line for.

## Output

Write `project-docs/audits/release-1.4.1-vs-1.3.2-review-2026-10-19.md`:
findings ranked by severity (blocker, should fix, nit), each with file:line,
what goes wrong for a player, and a suggested fix; then a short list of
what you checked and found fine. No em dashes. Commit only that file with
`docs: end-to-end review of 1.4.1 against 1.3.2` and push.
