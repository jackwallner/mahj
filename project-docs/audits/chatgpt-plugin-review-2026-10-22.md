# ChatGPT plugin submission review, October 22, 2026

**Recommendation: return for changes before approval.** This is a simulated reviewer assessment using published OpenAI requirements, not an OpenAI employee decision. Reviewed package version `1.0.0`, source commit `025bd69`, and `https://mahj.mahjtrainer.workers.dev/mcp`. One GPT-6 Luna agent at maximum reasoning effort independently researched policy, public pages, content provenance, and the demo.

The plugin has credible standalone educational value: original lessons, interactive quizzes, Charleston exercises and a rack reader. Its four tools are narrowly scoped and have appropriate read-only annotations. The strongest concerns are reliability and submission readiness, not a demonstrated prohibited business model or copied card.

Priority: P1 means resolve before submission; P2 means quality or robustness work. Findings distinguish reproduced defects, source observations, review risks and external checks. These are recommendations, not claims that each item independently triggers rejection.

**Follow-up correction:** The demo finding below was withdrawn after closer frame sampling. This document retains the original 21 review-item numbers for traceability; they are not 21 confirmed bugs. Items about account verification, host acceptance and hosting configuration remain checks rather than established product defects.

## Submission and policy findings

### 1. P1: UI resource does not declare a CSP

**Confirmed in source and live metadata.** `chatgpt/src/worker.ts:49` explicitly omits CSP because the widget makes no network calls. The live resource advertises `ui.prefersBorder` and `ui.domain`, with no `ui.csp`.

OpenAI's [remote MCP review requirements](https://developers.openai.com/plugins/deploy/app-review) require a CSP for returned UI. Declare empty network/resource allowlists for this self-contained widget. No external domains need to be allowed. The [UI documentation](https://developers.openai.com/plugins/build/chatgpt-ui#content-security-policy-csp) describes the resource metadata fields. Confirm the portal accepts the declaration after rescanning.

The documentation does not explicitly settle whether omission is accepted for a component with no off-origin requests. This is a documented requirements mismatch and submission risk, not a demonstrated portal rejection or proof that the host currently permits unrestricted network access.

### 2. P1: Hosting-data retention is not explained

**Confirmed disclosure gap.** `docs/privacy-policy.html:140` explains the plugin's inputs, absence of application storage, Cloudflare hosting and OpenAI's role. It does not specify the retention treatment for the IP addresses and request details it says Cloudflare processes. The general retention paragraph at line 165 covers app data and purchases instead.

OpenAI's [privacy requirements](https://developers.openai.com/plugins/plugin-guidelines#privacy) include retention timelines. State the actual hosting/logging configuration and its retention or applicable provider policy, including what controls users have. Verify the deployed configuration before promising that nothing is logged. No raw-request logging was found in application code; hosting configuration was not inspected.

### 3. Withdrawn: Demo allegedly omitted glossary and riichi results

**The initial finding was wrong.** Widely spaced I-frame samples showed the prompts in the composer and missed completed results between them. Follow-up sampling every second from 60 through 82 seconds shows the glossary result at 70 seconds and the riichi response by 78 seconds. Both claimed missing demonstrations are present. See the [glossary result](chatgpt-plugin-review-2026-10-22-evidence/demo-term-result.jpg) and [riichi result](chatgpt-plugin-review-2026-10-22-evidence/demo-riichi-result.jpg).

No replacement defect is asserted here. The video remains useful evidence, although it does not substitute for this review independently running the manifest cases in current ChatGPT desktop and mobile clients. The manifest includes five positive and three negative cases as requested by the [submission flow](https://developers.openai.com/plugins/deploy/submission#complete-review-information).

### 4. P1 external check: Domain verification cannot currently be demonstrated

**Confirmed endpoint state, conditional blocker.** A Node fetch of `/.well-known/openai-apps-challenge` returns 404. `chatgpt/src/worker.ts:130` serves the token only if the secret is present. This blocks a fresh verification challenge. It does not prove that an existing portal verification is invalid.

Check the portal's current verification state. If a challenge is pending, deploy its exact token at the specified URL and verify it. The [submission instructions](https://developers.openai.com/plugins/deploy/submission#domain-verification-details) define this check. Developer identity, project permissions, residency, current scan findings and publication state were not accessible in this review.

### 5. P2: Listing homepage creates an avoidable cross-promotion question

**Review risk, not a confirmed violation.** `chatgpt/plugin/plugin.json:25` sends users to the native app homepage. That page promotes Mahj+ and links to the App Store. The widget and tool responses themselves contain no purchase link or upsell.

Use a plugin-specific information page to keep the directory listing's purpose clear. OpenAI's [commerce guidelines](https://developers.openai.com/plugins/plugin-guidelines#commerce-and-monetization) restrict digital-product sales and freemium upsells. An app homepage link alone is insufficient evidence to call this a violation.

## Reproduced functional findings

### 6. P1: Invalid tile strings escape the parser's type contract

**Reproduced against live MCP.** Call `read_mahjong_rack` with:

```json
{"tiles":["constructor","__proto__","4C","6B","8B"]}
```

`chatgpt/src/tiles.ts:62` uses `text in WORDS`, which accepts inherited properties. These inputs become a function and an object. The tool returns `isError: true` and exposes output-validation internals, including `Expected string, received function` and property paths.

Use own-property checks or Maps for tile dictionaries, enforce canonical tile strings after parsing, and return the normal readable input-correction response. This is a validation defect; no code execution or successful prototype mutation was demonstrated.

### 7. P1: Nearly half an unreadable rack still receives confident advice

**Reproduced against live MCP and widget script.** Submit seven valid evens followed by six `unknown` entries:

```json
{"tiles":["2C","2C","4C","4C","6B","6B","8B","unknown","unknown","unknown","unknown","unknown","unknown"]}
```

The tool produces a confident 2468 lean. The model gets an `unreadable` array, but `_meta.widget` omits it. The rendered widget says `7 tiles` and presents advice without disclosing that six supplied tiles were dropped. See `chatgpt/src/tools.ts:78` and line 118.

Require correction before actionable passing advice when any supplied tile is unreadable, or prominently mark the result as a partial read and show every rejected entry in the widget.

### 8. P1: Section explanations can contradict the rack

**Reproduced locally.** This rack triggers the early Singles & Pairs branch:

```text
N N E E W W S S RD RD 1C 3C 7C
```

The result labels Winds & Dragons a long shot and explains it as `Only 10 winds or dragons.` Ten of thirteen tiles are honors. `chatgpt/src/rack.ts:151` bypasses ordinary scoring; `verdictFor` then treats non-shortlisted sections as poor, and `longShot` prints a low-support explanation regardless of the count.

Separate alternative-section scoring from the final recommendation. Explain structural limitations when support is high. This finding does not assert that any particular copyrighted card line matches the rack.

### 9. P2: No pass candidate is incorrectly equated with no dead weight

**Reproduced locally and in live output.** If the algorithm returns no candidate, `chatgpt/src/tools.ts:92` and `chatgpt/widget/index.html:297` claim nothing is dead weight. The Singles & Pairs example above receives that reassurance even though the algorithm never evaluates its numbered singletons against a target line. The same assertion appears for eight jokers plus five flowers, where no section is identified.

Say that the section-level reader cannot identify a confident pass. Empty output is not proof that every tile is useful. Offer a next step tied to the player's own card.

### 10. P2: One- or two-tile suggestions lose the three-tile-pass warning in the widget

**Confirmed source/output mismatch.** For `2C 2C 4C 4C 6B 6B 8B 8D F J N 2D 8C`, the reader suggests only North. Model-facing text explains that the player still needs to choose the rest of the three-tile pass. `chatgpt/widget/index.html:295` omits that explanation.

Show the incomplete-pass caveat in the card itself. The model is instructed to keep its reply brief, so the missing guidance should not depend on chat narration.

### 11. P2: Glossary matching can choose the wrong entry or miss a known alias

**Reproduced locally.** `lookUpTerm("joker exchange rules")` returns `Joker`, although `joker exchange` is an alias of `Joker swap`. `lookUpTerm("What is a white dragon?")` returns no match, although `white dragon` is a Soap alias. Natural phrasing such as `How do I swap a joker` also returns the generic Joker entry.

`chatgpt/src/sessions.ts:206` checks exact aliases, then first-match substrings of canonical names only. Prefer normalized exact matches, then the longest boundary-aware match across names and aliases. The model may extract a clean term first, so these are accepted-input failures rather than proof that every conversational prompt fails.

### 12. P2: Tool instructions promise broader rules coverage than the glossary supplies

**Confirmed scope mismatch.** `chatgpt/src/worker.ts:24` routes any American mah jongg term or rule to the glossary. The glossary has 36 entries, and `scoring` returns no match. The miss response at `chatgpt/src/tools.ts:126` asks the model to answer from its own knowledge, despite the tool's promise of a grounded definition.

Describe the supported glossary scope and preserve a clear unknown result. Add reviewed reference coverage if broad rules answers are an intended feature.

### 13. P2: Requested quiz size can silently shrink

**Reproduced locally and live.** `start_mahjong_practice` accepts `count: 12`, but reading and Charleston each contain nine questions. `chatgpt/src/sessions.ts:198` returns nine without explaining the cap. The actual returned array length is correct.

Advertise `up to count` and explain the available pool, or define an intentional repeat policy. Do not imply that twelve distinct questions were delivered.

## UI, resilience and maintenance findings

### 14. P2: Host failures can leave a permanent loading state

**Source observation.** The initial widget says Loading. Missing metadata makes `start()` return indefinitely; MCP initialization errors are swallowed, and follow-up failures have no visible handling. See `chatgpt/widget/index.html:65`, line 198, line 332 and line 347.

Show a useful timeout/error message and a retry path when the host bridge or Practice this action fails. This failure was not induced in a real ChatGPT session.

### 15. P2: Restored widget state is trusted without validation

**Reproduced in a Node VM with a minimal DOM stub.** Restoring a matching lesson key with `i: -1` throws `Cannot read properties of undefined (reading 'title')`. `chatgpt/widget/index.html:182` only clamps the upper bound, and line 336 accepts saved state wholesale.

Validate the index, score and selection types/ranges before restoring state. Reset invalid state. No normal host action producing this corrupt state was demonstrated, so treat this as defensive robustness.

### 16. P2: Partial host bridges can suppress the MCP fallback

**Reproduced in the VM harness.** When `window.openai` exists but its output/metadata are absent, MCP tool-result messages update `mcp.output` and `mcp.meta`, but `host.data()` still chooses the empty OpenAI object. The view remains stale. See `chatgpt/widget/index.html:70` and line 345.

Feature-detect the specific available APIs/data rather than the global object's existence. The official [UI integration guide](https://developers.openai.com/plugins/build/chatgpt-ui) recommends the MCP Apps bridge for new UI and feature detection for host extensions. This is a compatibility risk, not a reproduced current ChatGPT host failure.

### 17. P2: Full DOM replacement loses keyboard focus

**Source observation.** Each interaction calls `paint`, replacing `root.innerHTML`, with no focus restoration. A keyboard user selecting a Charleston tile loses the focused button after every selection. Choice answers and lesson navigation have the same pattern. See `chatgpt/widget/index.html:175` and line 307.

Preserve focus for tile toggles and deliberately focus the next question or feedback region. Verify with keyboard navigation in an actual browser. OpenAI's [UI guidance](https://developers.openai.com/plugins/concepts/ui-guidelines#accessibility) treats accessibility as a core consideration.

### 18. P2: Answer feedback has no announcement mechanism

**Source observation.** Right/wrong feedback, joker warnings and scores are inserted without an `aria-live` region or controlled focus. The widget does provide tile SVG labels and selection state, which are useful foundations.

Add concise status announcements and verify with a screen reader. This review could not perform a real assistive-technology session; the finding is the missing mechanism in source, not a measured WCAG verdict.

### 19. P2: Tile inputs have no per-entry length bound

**Source observation.** `chatgpt/src/worker.ts:32` limits the array to fourteen strings but leaves each string unbounded. Unrecognized values are reflected into error text and structured output.

Trim inputs and impose a reasonable tile-name length bound. Do not echo arbitrarily long strings. No service-level denial of service was attempted.

### 20. P2: Year rollover updates the reader but not the lessons

**Confirmed maintenance risk.** `cardYear()` switches automatically each April in `chatgpt/src/rack.ts:44`. Exported year lesson subtitles, tile examples and some prose remain authored for 2026. After rollover, the reader can use one year while the instructional examples still present another.

Make examples explicitly dated, or update them as a coordinated content release. Keep the privately checked current-card claims distinct from evergreen rules. This is not a current 2026 inconsistency.

### 21. P1 verification gap: Actual ChatGPT acceptance behavior remains unverified

**Unverified, not a claimed defect.** MCP protocol tests do not establish model routing, answer secrecy, mobile layout, iframe sizing, follow-up messages, refresh/reopen persistence, keyboard behavior or negative-case handling in ChatGPT. The collaborative preview reported that no automation host was available; no visual browser or ChatGPT end-to-end pass is claimed.

Run all five positive and three negative manifest cases in ChatGPT desktop and mobile. Add incomplete racks, malformed tiles, ties, one-pass suggestions, absent UI, bridge failure and session restoration. Check Codex's text-only experience as well. Existing tests cover nine authored rack reads and nine Charleston deals, not the general rack space.

## Checks that passed

| Area | Evidence and result |
| --- | --- |
| TypeScript | `cd chatgpt && npm run check`, passed |
| Local worker | Started `npm run dev`, then `npm test`, 14/14 passed |
| Live service | `MCP_URL=https://mahj.mahjtrainer.workers.dev/mcp npm test`, 14/14 passed |
| Production dependencies | `npm audit --omit=dev --json`, zero reported vulnerabilities at review time |
| Package creation | `npm run package -- https://mahj.mahjtrainer.workers.dev/mcp`, ZIP created with manifest, skill, icon and public MCP configuration |
| Tools | Four independent operations, output schemas, explicit `true/false/false` read-only/destructive/open-world annotations |
| MCP resource | Live `ui://mahj/trainer-v2.html` returned `text/html;profile=mcp-app` |
| Transport | Node fetch of GET `/mcp` returned 405, appropriate for the implemented stateless POST transport |
| Content export | Exact read-only comparison to the canonical free-content transformation; 9 categories, 36 glossary entries, 6 primer pages, 9 reference sections, 8 drills and 102 drill items |
| Membership boundaries | No Plus drills or non-free rooms in the plugin content export |
| Commerce surfaces | No purchase links or upsell in inspected widget/tool results |
| Listing | Supported category, 256x256 icon, five positive and three negative cases, prompts, release notes and legal/support URLs present |
| Public URLs | Website, support, privacy, terms and demo returned HTTP 200 in the independent check; support has an email contact |
| IP positioning | American-mahjong scope and NMJL non-affiliation are explicit; original teaching content and section-level coaching are used. No current copyrighted card was obtained or compared, so independent legal clearance is not claimed |

## Acceptance evidence still needed

- Resolve findings 1, 2, 6, 7 and 8, and demonstrate their corrected behavior.
- Complete the independent host acceptance work in finding 21. Finding 3 is withdrawn; do not re-record the demo solely to remedy the alleged omission.
- Confirm identity, ownership, verification token/state, permissions, residency, country availability and automated scan status in the submission portal. An empty manifest country list is not treated here as a proven configuration error.
- Confirm Cloudflare logging, retention, resource limits and monitoring. Source alone cannot establish those settings.
- Privately validate card-dependent teaching claims against the applicable current card without copying its hands into the repository or review materials.

The audit changed documentation only. It did not deploy the worker, alter product behavior, submit a package, purchase services or perform an authenticated portal action.

## Resolution, October 22, 2026

Fixed in the 1.1.0 plugin (worker version `edd048a6`, widget `ui://mahj/trainer-v3.html`), with tests in `chatgpt/test/` (29 pass locally and against the live worker):

| Finding | Resolution |
|---|---|
| 1 | The resource declares an empty CSP in `_meta.ui.csp` and `openai/widgetCSP`. |
| 2 | The privacy policy's `#chatgpt` section states that the worker keeps nothing. Cloudflare's API showed Workers Logs, Logpush and tail workers all off, `wrangler.toml` pins `[observability] enabled = false`, and `src/` has no logging. |
| 4 | Still open. The `OPENAI_DOMAIN_CHALLENGE` secret needs the token from the portal, which opens after identity verification. |
| 5 | The listing's website, homepage, author and support URLs now point at the plugin-only page `https://jackwallner.github.io/mahj/chatgpt/`. |
| 6 | The parser uses `Map` and `Object.hasOwn`, so `constructor` and `__proto__` are unknown words. Entries are capped at 120 characters and echoes at 24. |
| 7 | Any unreadable entry gets a "fix these" reply that shows what was read. Racks under 13 tiles carry a partial warning and pass only tiles that fit nothing. |
| 8 | Section notes are generated from the counts, and a regression test covers the reported rack. |
| 9, 10 | When a rack has no stray tiles, the reply explains what to pass instead, and the widget shows that note beside the pass. |
| 11, 12 | Glossary lookups match whole terms and aliases, never fragments. The tool description says it covers terms, not full rules. |
| 13 | Practice results give the topic's question count, and the model is told when a set is shorter than asked. |
| 14 to 18 | The widget times out to a Try again card, validates restored state, falls back to `window.openai` field by field, restores focus by `data-focus`, and announces verdicts through a live region. |
| 19 | Tile lists accept 1 to 40 entries of at most 120 characters each. |
| 20 | `CARD_YEAR` is fixed to the content's year, and a test fails after April 1 of the next year. |
| 21 | Still open. It needs a pass in ChatGPT on the web, desktop and mobile after Refresh tools. |

The second reviewer's notes are handled in the same release: per-tile pass reasons, anchors, tiles to hope for, joker advice, and pass-aware advice from a new `pass` input. Practice answers are hidden from the model, and a new `check_mahjong_answer` tool checks them. The widget adds tile naming, a missed-question review with Redo, and hit, miss and coach marks on passes. The copy cleanup covers the shared content. Strategy questions stay two-choice by design, because the app's `CardChoice` type is binary. The demo recording predates the v3 widget and should be re-recorded before submission.
