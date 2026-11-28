# Mahj AI discovery experiment, November 28, 2026

Status: baseline collected and candidate patch tested. The website has not been changed. Publishing the candidate and making follow-up consumer-AI requests need Jack's outward-facing approval.

## Result

Eight unbranded discovery questions and four branded fact checks were tested on four working engines. There are 48 usable answers: 32 discovery answers and 16 branded answers. Perplexity and Copilot were attempted but blocked or empty; their three saved captures are not scored as absences. Other planned requests to those engines were stopped, not completed.

| Engine and surface | Valid discovery answers | Mentions | Recommendations | First/category-leading pick |
| --- | ---: | ---: | ---: | ---: |
| Claude Code with web search | 8 | 0 | 0 | 0 |
| Gemini via agy | 8 | 3 | 3 | 2 |
| ChatGPT consumer browser | 8 | 0 | 0 | 0 |
| Google AI Mode browser | 8 | 1 | 1 | 0 |

The consumer-browser subset is one recommendation in 16 discovery answers. The combined, mixed-surface sample is four recommendations in 32 discovery answers. Neither number measures market share or the probability a typical buyer will see the app.

The four discovery recommendations were:

- Gemini / `after-class`: first app under the category explicitly marked best right after a class. Links to jackwallner.com.
- Gemini / `charleston`: first dedicated passing-drill pick and first app in the summary recommendations. Links to jackwallner.com and the app's App Store listing.
- Gemini / `practice-alone`: suggested in the Charleston practice tip, outside the main ranked app list. Counted as a recommendation, but not a top pick or an assigned list position.
- Google / `free`: recommended after Mahjong 4 Friends and Mahj Parlour. The source panel names the exact existing page title, "Free American Mahjong App With No Subscription." That is title evidence only, not a resolved citation URL.

No citation alone is counted as a recommendation. Source URLs and the name of the different app "Mahjong Trainer: Learn & Win" do not count as Mahj Trainer mentions.

## Branded errors worth addressing

Branded questions are excluded from every discovery score above.

1. **App identity:** Gemini's `what-is` answer describes Mahj Trainer as "listed primarily as Mahjong Trainer: Learn & Win on iOS" and later attributes bot play to it. Its `price` answer merges the developer identities as "Jack Wallner / Cedar Theory." These are separate apps, not two names for this app.
2. **Platforms:** Google's `vs-m4f` answer calls Mahj Trainer "strictly an iOS app." The repo's Android publishing guide and existing Google Play link establish that Android is available too.
3. **Prices:** ChatGPT's `price` answer quotes different, higher plan prices than its own `what-is` and `vs-m4f` answers from the same run. This is an inconsistency flag, not an ASC-verified price determination. No price changes or hardcoded price additions are proposed here.
4. **Correct Android identity:** E3 Apps is the actual Google Play developer name, not evidence of confusion by itself. See `.claude/rules/android.md`, the Play Console app record section. The first interpretation of this run incorrectly treated that name as suspect; this readout does not.

Verification sources checked during the run:

- The public [Mahj Trainer App Store listing](https://apps.apple.com/us/app/id6790052126) and Apple's public lookup response identify Jack Wallner as the seller.
- Apple's public lookup response for [Mahjong Trainer: Learn & Win](https://apps.apple.com/us/app/id6806357092) identifies Cedar Theory LLC as its seller.
- `.claude/rules/android.md` records the E3 Apps Play developer identity; [the existing Play listing](https://play.google.com/store/apps/details?id=com.jackwallner.mahj) is already linked from `docs/index.html`.
- `docs/free-american-mahjong-app.html.md` and `.claude/rules/membership-and-trial.md` establish the free beginner rooms and optional Mahj+ structure. The current landing page explicitly says there are no bot opponents and the official NMJL card is not reproduced.

## One-page change, not a website rewrite

[candidate.patch](candidate.patch) adds exactly one question to the existing landing-page FAQ:

> Is Mahj Trainer the same as Mahjong Trainer: Learn & Win?

The answer names both store publisher identities, distinguishes the separate Cedar Theory app, and restates solo practice versus bot or multiplayer games. It appears in visible HTML, the existing FAQ JSON-LD, and the Markdown twin. Existing author markup, prices, downloads, layout, app code and analytics are unchanged. No extra schema type or AI-specific file is introduced.

The target is the canonical homepage because both engines already use it for branded answers. The hypothesis is narrow: an explicit name-to-seller distinction may reduce entity confusion. The baseline does not establish why any search engine omits the app, and this patch is not claimed to improve rankings or recommendations before a follow-up run.

The existing comparison and free-app pages already answer most buyer questions. This experiment does not duplicate those pages, rewrite honest competitor recommendations, contact authors or purchase an AEO service.

## Evidence and reproducibility

- [questions.tsv](questions.tsv): the exact eight discovery and four branded questions.
- [scorecard.json](scorecard.json): manually inspected grades, capture names, per-file SHA-256 values, saved timestamps and collection-surface details for all 51 saved captures.
- Raw captures stay locally at `~/claude-visibility/mahj-experiment/answers/2026-11-28/`. They are not committed because browser exports include advertising and tracking URLs. The original capture files are unchanged.
- Collection reused the askers in `~/claude-visibility/recommend.py`. Claude Code used the `sonnet` alias with WebSearch and no settings or MCP connectors. Gemini used `gemini-3.8-flash-high` through agy. The two CLI askers appended the existing instruction to search and name apps; the browser askers received only the question. The result is not a controlled consumer-app-versus-API comparison.
- ChatGPT used a logged-out temporary chat with a search hint. Google used AI Mode with `hl=en` and `gl=us`. Physical location was not varied or independently verified. Browser model versions were not recorded.
- A draft-clearing change was temporarily made to the shared browser helper during collection, then restored byte-for-byte. The separate proposal to repair the fleet-wide measurement pipeline was not adopted by this experiment.
- All final grades were checked directly against saved text. The earlier two-answer model-grader smoke test is not used to infer domains from Google source labels or to determine this scorecard.
- This is one capture per working engine/question, with retries for failed browser captures. No repeated-sample confidence interval, install attribution or revenue uplift is claimed.

## Verification

Executed November 28: all eight offline checks passed, including all 51 raw capture hashes. The candidate applied successfully to scratch copies, and `git diff --check` passed. Published website files and the main app working tree were not changed.

Run the offline checks from the repository root:

```sh
python3 -I project-docs/seo/2026-11-28-discovery/verify.py --raw "$HOME/claude-visibility/mahj-experiment/answers/2026-11-28"
```

The checks verify the query split, record uniqueness, all raw-file hashes, exclusion of branded and blocked captures, recommendation counts, candidate patch scope, scratch application, unchanged application metadata and scripts, and agreement between the visible FAQ, JSON-LD and Markdown. Omit `--raw` on machines without the local capture archive; only that hash check is skipped.

No iOS or Android app code changes are included, so no app build or TestFlight upload is required. The candidate applies only to scratch copies during verification. Before publishing from main, recheck the patch against the then-current page and update its normal last-updated date.

## Follow-up, after approval and indexing

1. Publish the single FAQ from main through the existing landing-page mirror workflow. Do not publish from this experiment branch. Verify the canonical HTML and Markdown show the answer and the existing prices, download links and disclaimer still match.
2. Record publication and Google recrawl dates. Wait for recrawl before interpreting changes. If there is no evidence of recrawl after about two weeks, check indexing instead of reporting an AEO loss or win.
3. Rerun the same 12 questions using the same four surfaces, settings and scoring rules. Do not retry blocked engines indefinitely or add new questions to the before/after denominator. Store the new date separately and preserve the baseline.
4. Compare each surface separately. The primary target is correcting Gemini's identity confusion in `what-is` and `price`. Separately report unbranded mentions, recommendations, positions and citations. A change in the four-of-32 aggregate alone is not causal proof.
5. Keep the change if it is accurate and the identity answers improve. If the same mix-up persists, trace the actual sources returned in that follow-up before proposing another change. Check the existing weekly AI-referred App Store tap report as a business signal, but do not equate taps with installs or purchases.

No follow-up requests or timers have been scheduled yet.
