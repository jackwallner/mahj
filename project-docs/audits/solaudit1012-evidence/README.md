# Audit evidence

Evidence for [solaudit1012.md](../solaudit1012.md). Screenshots and accessibility trees came from the actual simulator app. Text probes compile the app's Shared source. No production feedback was submitted.

- `phone-*`: iPhone 17e, iOS 26.5, normal text or AX5 as named.
- `ipad-*`: iPad Air 11-inch (M4), iPadOS 26.5, portrait.
- `phone27-home.png`, `phone27-challenge.png`: iPhone 18 Pro Max, iOS 27.0, visual launch/Home and challenge deep-link landing smoke checks. Interactive automation was unavailable.
- `android/`: remote Gradle unit log, 30-test XML reports, checksum verification and DST arithmetic proof. No Android emulator was used.
- `final-answer-kill-proof.json`: challenge result banked after answer 12, but no session/streak credit after termination and relaunch.
- `feedback-proof.txt`: three offline reports become one after an offline retry.
- `content-proof-root.txt`: calendar identities, 39 months of challenge generation and the consecutive-run grading counterexample.
- `build41-october.txt`, `current-october.txt`, `old-october.txt`: actual-source challenge outputs from build-41 commit `41457e7`, build 42, and intermediate build-41 commit `2e1a142` respectively.
- `build-summary.txt`, `unit-tests-summary.txt`: excerpts from successful Release build and 214-test iOS run. Complete logs and xcresult remain in `/tmp/mahj-solaudit1012/` for this session.

## Reproduce source probes

From the repository root, on the audited source revision:

```sh
swiftc Shared/Models/*.swift Shared/Content/*.swift \
  Shared/Services/WhatsNew.swift MahjTrainer/Utilities/ChoiceShuffle.swift \
  project-docs/audits/solaudit1012-evidence/probes/main.swift \
  -o /tmp/mahj-content-probe
/tmp/mahj-content-probe
```

The feedback service relies on the app's implicit Combine import. For this standalone macOS probe, add that import to a temporary copy only:

```sh
python3 - <<'PY'
from pathlib import Path
source = Path('Shared/Services/FeedbackService.swift').read_text()
Path('/tmp/mahj-audit-FeedbackService.swift').write_text('import Combine\n' + source)
PY
swiftc -swift-version 5 -parse-as-library \
  /tmp/mahj-audit-FeedbackService.swift \
  project-docs/audits/solaudit1012-evidence/probes/FeedbackProbe.swift \
  -o /tmp/mahj-feedback-probe
/tmp/mahj-feedback-probe
```

The feedback probe uses an isolated UserDefaults suite and an offline URLProtocol. It never contacts the feedback backend.
