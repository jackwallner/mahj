# iOS 27 compatibility audit: Mahj Trainer

- Audit date: 2026-08-05
- Runtime: iOS 27.0 (24A5390f)
- Xcode: 26.6 (17F113)
- Scheme: `MahjTrainer`
- Unit target: `MahjTrainerTests`
- Overall: Pass with concurrency warnings

## Checks

- Debug build: Pass.
- Unit tests: Pass.
- Normal rebuild after tests: Pass.
- Install and launch smoke test: Pass.
- Runtime UI snapshot: Pass. Onboarding rendered.

## Findings

- `MahjTrainer/Utilities/Theme.swift:177,184,191` has main-actor isolation warnings for haptic calls or initialization.
- `MahjTrainerTests/ProgressStoreTests.swift`, `ReviewPromptTrackerTests.swift`, and `PracticeRecordStoreTests.swift` contain main-actor isolation warnings.
- No iOS 27-specific compiler error or runtime blocker was observed.

## Recommended follow-up

- Isolate haptic work on the main actor and clean test actor annotations before enabling warnings-as-errors.
