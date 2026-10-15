# Recheck evidence

App code: `5bb9bee`, 1.4.1 (46). Simulator: leased iPhone 18 Pro, iOS 27.0.
Production code was unchanged. Real purchases and feedback submissions were
not made.

- `layout-capture.swift`: temporary XCTest helper hosting the actual
  `TrialReminderOfferView` at normal Large and AX5. It was copied into
  `MahjTrainerTests/AuditEvidenceTests.swift` for the run, then removed.
  XcodeGen was regenerated after adding and removing it.
- `layout-summary.json`: both capture methods completed. These are evidence
  captures, not assertions that the screen fits.
- `trial-reminder-large.png`, `trial-reminder-ax5.png`: the normal layout
  and the reproduced clipping. The view contains no scrolling container.
- `relay-probe.mjs`, `relay-proof.txt`: runs the actual relay source with
  mocked Supabase and fetch dependencies. Network failure and HTTP 429 each
  write `error`, and a second sweep makes no retry. No external request is
  made. The proof records the relay source hash.
- `readout-proof.json`: mocked execution of the actual CTA readout's
  customer-date filter. An existing customer is excluded. The script's hash
  is retained; the script lives in `~/ios/growth/` and is not duplicated here.
- `core-summary.json`, `core-captures-manifest.json`: completed existing UI
  capture case and hashes of its 12 PNGs. Eight representative frames were
  inspected. The raw captures remain in `build/audit-recheck/core-captures/`.
- `challenge-proof.json`: free-user deep-link and one-answer persistence
  check across a process restart, verified from the accessibility tree.
- `unit-summary.json`: fresh full suite after removing the temporary capture
  helper, 226 tests passed, zero failures or skips, on iOS 27.0.

Run the offline relay probe from the repo root:

```sh
node project-docs/audits/1.4.1-recheck-evidence/relay-probe.mjs
```

The iOS captures use the real app target and the helper above:

```sh
xcodebuild test -project MahjTrainer.xcodeproj -scheme MahjTrainer \
  -destination "id=$AUDIT_UDID" -quiet -jobs 2 -parallel-testing-enabled NO \
  -only-testing:MahjTrainerTests/AuditEvidenceTests
xcodebuild test -project MahjTrainer.xcodeproj -scheme Screenshots \
  -destination "id=$AUDIT_UDID" -quiet -jobs 2 -parallel-testing-enabled NO \
  -only-testing:MahjTrainerScreenshots/ScreenshotTests/testCaptureAppStoreSet
```

Set `AUDIT_UDID` from an active `agent-sim` lease, and release that lease when
finished. The helper must be installed and XcodeGen regenerated for the first
command. Preserve the resolved package versions. Full logs and result
bundles are in `build/audit-recheck/`.
