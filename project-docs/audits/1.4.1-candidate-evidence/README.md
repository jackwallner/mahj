# Candidate audit evidence

- `source-manifest.json`: SHA-256 hashes of app, shared, unit-test and UI-test
  source files in the isolated candidate snapshot, with its base commit.
- `candidate-Package.resolved`: dependency versions copied from the original
  checkout, RevenueCat 5.80.3 and Facebook 18.1.1.
- `asc-state.json`: read-only ASC version and latest-build query on October 15,
  2026. No 1.4.1 build was present.
- `reminder-probe.swift`: executes the candidate's actual reminder planner;
  the declarations at its top only supply constants from app-only types.
- `reminder-proof.txt`: finite scheduling window, DST wall-time preservation
  and stale-copy results.
- `unit-summary.json`: all 231 candidate unit tests passed on iOS 26.5, with
  zero failures and no skipped tests, using the preserved dependency pins.
- `onboarding-trial-test-store.png`, `paywall-test-store.png`: recovered from
  the result object store after the broader UI run was interrupted. Both
  purchase tests completed and the images were visually inspected. Prices
  are Test Store values, and trial eligibility is forced for the capture.
- `ui-progress.txt`: runner evidence of those two passing purchase tests and
  the partial drill capture run. The latter did not finish and is not a pass.
- `release-summary.json`: successful arm64 Release simulator compilation,
  using a generic destination after the interrupted UI run.

The reminder probe targets the discarded, uncommitted finite-window
candidate. Its planner API was removed before build 46. It does not compile
against the current `AppSettings.swift`, and its recorded output is
historical evidence, not a current regression check. The complete old
AppSettings source is not retained in this directory; the source manifest
contains its hash. Current checks and the corrected findings are in
[the recheck evidence](../1.4.1-recheck-evidence/README.md).

The full local build logs and result bundles are in `build/audit-1.4.1/` and
are not committed. The initial build attempt used a newly resolved RevenueCat
5.95.0 because generated Xcode project files, including Package.resolved, were
not in the source snapshot. That attempt was interrupted after the simulator
stopped responding. Only subsequent runs using the preserved 5.80.3 lock are
eligible for candidate build/test sign-off.
