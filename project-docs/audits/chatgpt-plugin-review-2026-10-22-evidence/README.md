# ChatGPT plugin review evidence

Evidence for [the October 22 review](../chatgpt-plugin-review-2026-10-22.md).

- `observations.json`: sanitized observed test results, live metadata and adversarial cases.
- `demo-term.png`: existing demo frame at 66.667 seconds, the glossary prompt is still in the composer.
- `demo-riichi.png`: existing demo frame at 75 seconds, the out-of-scope prompt is still in the composer.

The images were extracted from the repository's existing `docs/chatgpt/demo.mp4`. They are review evidence, not newly recorded ChatGPT acceptance tests. The widget probes executed its live script with a minimal DOM stub in Node; they do not establish browser layout or assistive-technology behavior. No authentication secrets or domain-verification token are included.
