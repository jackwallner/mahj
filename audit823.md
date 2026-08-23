# Mahj Trainer audit823

Date: 2026-08-23

Scope: Mahj Trainer only, repository /Users/jackwallner/mahj. This is a fresh max-reasoning rerun. The audit covers acquisition, App Store Connect metadata and release state, downloads, trial starts, purchase flow, RevenueCat, ratings, onboarding, user experience, paywall experiments, website and legal consistency, reliability and regression signals, and Cursor, Claude, and Codex documentation hygiene.

Only this file is intended to change. No app code, metadata, website file, script, credentials, App Store Connect record, RevenueCat configuration, commit, or push was changed.

## Reading the evidence

- E means directly observed in current local source/config, a current public listing lookup, or the App Store Connect context available on 2026-08-23.
- H means a dated repository note or previous audit. It is useful context, not current production truth.
- I means an inference or hypothesis that needs measurement.
- NA means the value was not available in the local repository or current context.
- Local StoreKit prices and scripts are not evidence of the live App Store price.
- This audit does not treat RevenueCat privacy or App Privacy wording as a finding about data collection or tracking, per request. RevenueCat purchase and entitlement behavior is still included where it affects conversion, support, or reliability.

## Executive assessment

Mahj Trainer has a coherent free product foundation: four free practice rooms, a clear Mahj+ expansion model, a small but excellent public rating sample, localized StoreKit pricing, a custom purchase screen with Restore, Terms, Privacy, and dynamic localized prices, and a deliberately gated review funnel.

The highest-risk problem is commercial source-of-truth failure. The app guide, local StoreKit fixture, website schema, ASC setup scripts, price scripts, historical research, and onboarding behavior disagree about prices, plan names, and which subscription the first trial CTA buys. A player can see one price on a website or local test capture and another in the live purchase sheet. An agent can also make the wrong catalog change because the repository contains several plausible but contradictory instructions.

The second highest-risk problem is release-state ambiguity. App Store Connect showed version 1.2.1, build 23, Waiting for Review. The public listing lookup still showed version 1.2.0. The repository state file says draft 1.2.0 and live 1.1. Those are three different release snapshots. No current download count, current trial-start count, or current RevenueCat cohort metrics were available, so growth and revenue conclusions must not be made from local evidence alone.

The third highest-risk problem is observability. The only current RevenueCat instrumentation found is custom paywall impression tracking. There are no RevenueCat custom attributes, purchase funnel events, crash or hang diagnostics, MetricKit integration, OSLog or Logger instrumentation, or generic analytics events. Current code cannot answer which acquisition source, paywall source, room, plan, or onboarding path produces a trial, purchase, activation, retention, or failure.

The current test gate is not green. The build phase reached compilation with warnings, but the xcodebuild test run was interrupted after test workers failed to materialize. That is not proof of a product crash, but it is not a passing current test result. A dated flow audit reports a previous 24-test baseline and older visual risks that need revalidation on the current build.

Recommended order:

1. Establish one catalog and release source of truth, then reconcile ASC, RevenueCat, StoreKit, website, scripts, metadata, and agent docs.
2. Treat 1.2.1 as a pending release until ASC and public listing evidence agree. Verify build 23, IAP attachment, offer duration, price schedule, and screenshots before submission.
3. Add a minimal, privacy-safe purchase and activation funnel using RevenueCat attributes plus durable local counters or a first-party event sink.
4. Fix product-loading and restore dead ends in onboarding and the paywall.
5. Re-run unit, UI, device, accessibility, purchase, and regression checks before spending on acquisition.
6. Refresh metadata and screenshots only after the commercial copy is stable.

## 1. Current identity and release state

| Item | Evidence | Assessment |
|---|---|---|
| App | Mahj Trainer: Mahjong Practice | E, current App Store Connect context and public lookup |
| App Store ID | 6790052126 | E, matches local review and ASC links |
| Bundle ID | com.jackwallner.mahj | E, project.yml and local subscription configuration |
| Local marketing version | 1.2.1 | E, project.yml:31 |
| Local build | 23 | E, project.yml:32 |
| Deployment target | iOS 17.0 | E, project.yml:7-8 and 13-14 |
| Devices | iPhone and iPad | E, project.yml:35 |
| Current ASC status | 1.2.1, Waiting for Review | E, App Store Connect app list context on 2026-08-23 |
| Public store version | 1.2.0 | E, read-only iTunes lookup on 2026-08-23 |
| Public rating | 5.0, 6 ratings, current-version rating also 5.0 from 6 ratings | E, public lookup on 2026-08-23 |
| Current downloads | NA | No current count in local repository or captured context |
| Current trial starts | NA | No current count in local repository or captured context |
| Current revenue or net proceeds | NA | Do not infer from public listing or local StoreKit |
| RevenueCat project | Mahj / Mahj Trainer, project ID 28030dc2 | E, project list context on 2026-08-23 |
| Public seller URL | https://jackwallner.github.io/mahj/ | E, public lookup |
| Local metadata marketing URL | https://jackwallner.github.io/mahj/ | E, fastlane/metadata |
| Website canonical URL | https://jackwallner.com/ios/mahj/ | E, docs/index.html:10 |

### Release conclusion

Do not describe 1.2.1 as live. Use the following release labels in future notes:

- Public production: 1.2.0, based on the public listing lookup.
- Pending ASC release: 1.2.1 build 23, Waiting for Review, based on the ASC context.
- Repository automation snapshot: stale until scripts/.asc-state.json is refreshed.

The stale state file is scripts/.asc-state.json:

- appId 6790052126
- draftVersion 1.2.0
- liveVersion 1.1
- updatedAt 2026-08-11

This file is not safe to use as current release evidence. A release watchdog should compare at least four values: repository marketing version, ASC version and status, public version, and uploaded build number.

## 2. Acquisition and App Store metadata

### 2.1 Listing identity and positioning

Current en-US metadata:

- Name: Mahj Trainer: Mahjong Practice, exactly 30 characters.
- Subtitle: Learn American Mah Jongg Cards, exactly 30 characters.
- Keywords: 99 characters according to the local metadata check.
- Primary category: Education.
- The description leads with four free rooms, then explains drills, Mahj+ features, the one-week trial, lifetime access, Apple billing, cancellation, Terms, and Privacy.
- The description does not hardcode a price. That is the correct resilience pattern for regional pricing.
- The public listing description and release notes match the local en-US release notes for Mahj Minute, Game Night Prep, iPad, and Mahj+.

The current keyword string includes majong, joker, mahjongg, tile, nmjl, charleston, flashcard, tutor, beginner, lesson, drill, rule, hand, and strategy.

Potential ASO improvements:

- Keep high-intent American Mah Jongg and practice language prominent. The title and subtitle already do much of this work.
- The keyword majong is a misspelling test. It may capture misspelled intent, but it consumes scarce keyword space and should be kept only if the current rank or acquisition data justifies it.
- joker is potentially ambiguous with unrelated games. Keep it only if search-term and conversion evidence support it.
- rule, hand, and strategy are broad. Test more specific combinations such as mahjong training, mahjong lessons, card practice, hand practice, American mahjong practice, learn mahjong, and Charleston mahjong through keyword rotation or product page optimization.
- Do not optimize solely for a keyword rank. Pair rank with product-page conversion, install rate, trial start rate, paid conversion, and net proceeds.

### 2.2 Historical keyword evidence

H, archive/ads89.md:138-166, Astro data retrieved 2026-08-09:

| Keyword | Historical rank | Popularity | Difficulty |
|---|---:|---:|---:|
| mahjong training | 5 | 5 | 44 |
| mahjong lessons | 8 | 5 | 56 |
| mahjong card practice | 10 | 5 | 68 |
| mahjong hand practice | 10 | 5 | 63 |
| American mahjong practice | 11 | 8 | 53 |
| American mah jongg | 12 | 5 | 48 |
| mahjong practice | 13 | 32 | 58 |
| learn mahjong | 14 | 24 | 53 |
| mahjong trainer | 19 | 5 | 11 |
| nmjl | 10 | 5 | 33 |
| Charleston mahjong | 33 | 5 | 59 |
| mahjong strategy | 74 | 5 | 66 |
| mahjong for beginners | 85 | 5 | 53 |
| mahjong app | 177 | 5 | 72 |
| American mahjong | Not top 100 | 8 | 52 |

Historical suggestions included mahjong for seniors and real mah jongg. They are hypotheses, not recommendations to ship unchanged. The 50+ audience hypothesis is plausible from the product and the research file, but it must be validated against trial starts and paid conversion rather than assumed from demographics.

### 2.3 Locale completeness and consistency

The repository contains 50 locale directories under fastlane/metadata, plus review_information. The supported locale list is scripts/asc-supported-locales.json.

Observed in the local metadata tree:

- All 50 locale directories contain name, subtitle, keywords, promotional_text, description, release_notes, support_url, marketing_url, and privacy_url files.
- Four locales duplicate the en-US name, subtitle, keywords, promotional text, and release notes exactly. This may be intentional for English-speaking storefronts, but it should be explicitly documented.
- One locale duplicates the en-US description exactly.
- support_url and privacy_url are the same canonical URL across all locales. That is operationally reasonable if the pages are English and globally served, but verify every URL returns successfully and that the intended language behavior is understood.
- marketing_url is blank in 39 locale files:
  ar-SA, bn-BD, ca, da, de-DE, en-AU, en-CA, en-GB, es-ES, es-MX, fr-CA, fr-FR, gu-IN, he, hi, id, it, ja, kn-IN, ko, ml-IN, mr-IN, ms, nl-NL, no, or-IN, pa-IN, pt-BR, pt-PT, ro, sv, ta-IN, te-IN, th, tr, ur-PK, vi, zh-Hans, zh-Hant.
- The metadata upload script only sets a URL when the local value is non-empty. scripts/asc-upload-metadata.py:52-58 and 86-88 therefore cannot clear stale ASC marketing URLs or make the local blank state explicit.
- The public listing lookup reported only EN in languageCodesISO2A. That does not prove the other 49 ASC localizations are absent, but it does mean the live storefront localization state must be checked in ASC rather than inferred from the repository tree.

Priority action:

1. Decide whether all 50 storefronts should have the marketing URL or whether blank means intentional.
2. Normalize the local files or encode an explicit per-locale policy.
3. Pull or inspect ASC localization state before mutation.
4. Extend scripts/asc-readiness.py to report missing fields, exact duplicates, blank URLs, HTTP status, and live localization counts.
5. Do not upload metadata while the commercial price and version sources disagree.

### 2.4 Metadata upload and readiness gaps

scripts/asc-readiness.py is a useful read-only starting point. It reports app/version/build, version localizations, screenshots, age rating, IAPs, subscription states, and price schedules.

It does not currently prove:

- introductory offer or free-trial duration for each subscription product;
- that the current offering maps the intended products to the intended entitlement;
- that every product is attached to the pending version or in the correct review state;
- that the metadata URLs respond successfully;
- that every locale has the intended marketing URL policy;
- that screenshots are unique and dimension-correct without a separate check;
- that product IDs and price literals agree across source, StoreKit fixture, website, scripts, and docs;
- that the public listing version agrees with the pending version;
- that release metrics have not regressed against the previous version.

This makes the script a readiness report, not a complete release gate.

### 2.5 Screenshots and product-page conversion

Local asset facts:

- fastlane contains six iPhone screenshots at 1320 x 2868 and six iPad screenshots at 2064 x 2752.
- docs contains six 1320 x 2868 marketing screenshot assets.
- A quick comparison found no exact duplicate screenshot groups within the captured set.
- The docs assets and fastlane assets are not byte-identical, so there are at least two screenshot variants. The repository does not make the source-of-truth relationship explicit.
- docs/appstore-screenshot-05.png shows the Home screen with the bottom disclaimer very close to, and visually at risk of clipping against, the lower frame edge. Treat this as an asset presentation defect until the screenshot is recaptured with safe bottom padding.
- The screenshot UI tests use continueAfterFailure = true. MahjTrainerScreenshots/ScreenshotTests.swift:13-24 and PaywallRenderTests.swift:16-24 record missing elements as attachments instead of failing the test. A capture can therefore look successful while omitting a key CTA or label.
- The screenshot suite captures the product set, while paywall captures are separate. That separation is sensible, but it needs a hard assertion contract for required elements.

Recommended product-page tests:

- Control: current quick-session lead, “Practice between games”.
- Variant A: five-minute daily habit, “Five minutes a day. It sticks.”
- Variant B: learner confidence, “Walk into game night ready.”
- Keep the app icon, title, audience, and offer stable while changing one screenshot headline or first frame.
- Measure impressions, product-page views, installs, trial starts, paid conversions, and proceeds by product page.
- Run a screenshot lint that fails on wrong dimensions, duplicate hashes, clipped text near safe areas, missing expected OCR strings, and stale version labels.

### 2.6 Historical Apple Ads state

H, archive/ads89.md:1-5 and 85-136:

- Apple Ads campaigns were staged but paused as of 2026-08-09.
- The historical target was US iPhone Search Results, with a 50+ women hypothesis and an all-eligible control.
- Five campaigns were staged with a historical total daily budget of $20, with an intended initial live test of at most $14/day.
- No current spend or active campaign state was captured for this audit. Do not state that these campaigns are active.
- The historical plan required a pricing cohort before enabling spend. That gate is still logical, but the price source must first be resolved.

When paid acquisition is resumed, use a control:

- Core 50+ audience.
- All-eligible audience.
- Search Match or discovery only after the core cohort has a readable baseline.
- Negative terms for solitaire, connect, tile match, multiplayer, and unrelated game intent.
- Stop based on net revenue per install and trial quality, not taps or raw installs.

## 3. Onboarding, activation, and trial path

### 3.1 Current source flow

The current first-run path is:

1. RootView decides between onboarding and Home using ProgressStore.hasOnboarded.
2. OnboardingView presents three value pages.
3. The player selects one of three skill levels on page 3. The selection is stored in AppStorage as mahj.skillLevel.
4. The trial page appears on page 4.
5. Entering the trial page emits the RevenueCat custom paywall impression mahj_onboarding_trial once per session.
6. The page displays Mahj+ benefits and a dynamic price disclosure.
7. The primary button says Start 7-day free trial.
8. OnboardingView.primaryAction() calls ensureOfferings(), then explicitly selects subscriptions.package(for: .monthly) at OnboardingView.swift:336-352.
9. A successful purchase starts the tour. A cancellation leaves the player on the trial page. An error presents Purchase Issue.
10. A missing monthly package presents the full PaywallView fallback.
11. After the trial decision, new players see How to Play and FeatureTour, which ends with a real Quick Session before Home is marked complete.

The source comment at OnboardingView.swift:3-8 says the trial CTA is a one-tap path with no plan cards. This is intentional, but it makes the selected plan and price a critical hidden decision.

### 3.2 Direct inconsistencies

- CLAUDE.md:30-32 says the onboarding flow is a one-tap yearly trial purchase.
- OnboardingView.swift:343 selects the monthly package.
- OnboardingView.swift:239-244 derives the disclosure from the monthly plan, so the disclosure and purchase currently match monthly, while the agent guide does not.
- The current StoreKit fixture and website schema use prices that do not match CLAUDE.md or historical acquisition notes.
- The trial page says “Try Mahj+ free” and the in-app brand is Mahj+, while several scripts and legal pages call the product Pro.

This is not a cosmetic documentation issue. It changes the price, billing cadence, trial cohort, and revenue interpretation.

### 3.3 Activation strengths

- The first-run copy explains the target problem clearly: practice between games.
- The skill question can route a future personalized experience.
- The “same Continue slot” interaction reduces button movement across pages.
- The app preserves free beginner rooms, which lowers the download-to-value barrier after onboarding.
- The post-trial tour includes a real session rather than only marketing slides.
- The content validity tests enforce the free/Mahj+ split, original content constraints, and no em dash text.

### 3.4 Activation risks

P1, trial decision before demonstrated product value:

- A new user reads three information pages, answers a skill question, and sees a trial CTA before completing a free interactive drill.
- The actual Quick Session is later in the tour. This may be appropriate for a paid conversion strategy, but it creates a high-risk testable hypothesis for a learner audience.
- Test immediate trial versus free Quick Session first. Do not remove the free rooms. Compare first-session completion, trial start rate, day 1 retention, and paid conversion.

P1, hidden monthly plan:

- The onboarding path has no plan cards. A user cannot choose yearly or lifetime before the Apple sheet.
- If monthly is the intended low-friction trial, update CLAUDE.md and all operational docs to say monthly. If yearly is intended, change the source and disclosure together. Do not infer the choice from the local fixture.

P1, offering failure dead end:

- ensureOfferings() has no explicit error state. loadOfferings() stores try? await Purchases.shared.offerings(), so the underlying reason is discarded.
- A missing offering sends the user to a fallback PaywallView whose prices can remain Loading price.
- The fallback CTA can remain tappable and eventually show a generic purchase error. There is no clear retry state, support path, or offline explanation.
- The onboarding Restore button at OnboardingView.swift:295 ignores restore errors with try?. A user can tap Restore, receive no confirmation, and remain unsure whether anything happened.

P1, impression loss:

- trackPaywallImpression() silently returns if RevenueCat is not configured.
- Onboarding and paywall impression calls are not queued for a later configured state.
- This is especially relevant for cold starts, simulator/local mode, product-load races, and any future configuration failure.

P2, long first-run path:

- Three marketing pages plus skill selection plus trial plus primer plus feature tour may be too much before a repeatable habit forms.
- Measure elapsed time from install to first answer, first completed drill, first trial CTA, and Home arrival. Segment by skill selection.

### 3.5 Trial funnel that should be measured

Implement a stable, low-cardinality state machine:

install or first_open -> onboarding_page_view -> skill_selected -> trial_page_view -> offerings_ready or offerings_failed -> trial_cta_tap -> Apple_sheet_presented -> trial_started, purchase_cancelled, purchase_failed, or purchase_restored -> entitlement_active -> first_free_drill_started -> first_drill_completed -> second_session -> review_gate_shown -> write_review_opened or feedback_started.

Required cohort dimensions:

- app version and build;
- locale and storefront country;
- device family, iPhone or iPad;
- skill level;
- onboarding experiment variant;
- paywall source;
- selected plan and product identifier;
- acquisition source where available, such as Apple Ads campaign or product page;
- product-load status;
- trial eligibility state;
- first drill type;
- free versus Mahj+ entitlement at the time of the event.

Do not put names, emails, full practice content, or unbounded free-form text into RevenueCat attributes.

## 4. Purchase catalog and RevenueCat

### 4.1 Current code behavior

Shared/Services/SubscriptionService.swift:

- DEBUG uses a RevenueCat test key at line 6.
- Release uses the production appl_ key at line 8.
- Simulator builds guard against non-test keys at lines 63-67, avoiding production RevenueCat data from simulator runs.
- The entitlement is pro at lines 168-171.
- Offerings are loaded at lines 98-101.
- package(for:) maps yearly to annual, monthly to monthly, and lifetime to lifetime at lines 103-109.
- purchase(_:) returns cancelled for RevenueCat user cancellation at lines 132-143.
- confirmEntitlement() polls customer info up to three times at lines 146-159.
- restore() applies restored customer info at lines 162-166.
- A local Pro override is stored in UserDefaults for development.
- The only custom RevenueCat instrumentation is trackPaywallImpression() at lines 77-88.

The purchase implementation has good cancellation semantics and a short entitlement confirmation loop. The missing state reporting around offerings and purchase outcomes is the larger operational problem.

### 4.2 Catalog consistency matrix

The following sources disagree:

| Source | Monthly | Yearly | Lifetime | Naming |
|---|---:|---:|---:|---|
| CLAUDE.md:30-32 and H archive/ads89.md | $1.99 | $9.99 | $29.99 | In-app Mahj+, entitlement pro |
| MahjTrainer/MahjTrainer.storekit | $9.99 | $39.99 | $89.99 | Pro product and Pro group |
| docs/index.html:39-53 JSON-LD | $9.99 | $39.99 | $89.99 | Visible copy Mahj+, schema product names |
| scripts/asc-setup-release.py | $4.99 | $19.99 | Not defined | Pro |
| scripts/asc-set-prices.py | $4.99 | $19.99 | $49.99 | Price mutation script |
| docs/research/mahjong-market.md historical table | $4.99 monthly | $29.99 yearly | Not defined | Research snapshot |
| Public App Store listing | Not captured | Verify in ASC and RevenueCat | Not captured | Public description says prices shown in app |

Additional catalog conflict:

- scripts/asc-setup-release.py uses subscription group name Pro and product names Mahj Trainer Pro Monthly and Mahj Trainer Pro Yearly.
- scripts/rc-add-lifetime.py uses display name Pro Lifetime and the same pro entitlement.
- The in-app membership label is Mahj+.
- CLAUDE.md explicitly says Pro is retired as a player-facing word.

Priority P0. Do not choose a price from this audit. Establish the intended commercial truth from the live ASC subscription and IAP records plus the live RevenueCat offering. Then update the local StoreKit fixture, website schema, scripts, metadata or docs, and agent guide in one reviewed change. Preserve product IDs and entitlement unless a deliberate migration is planned.

### 4.3 RevenueCat data that is present

The Mahj project is identified in the available RevenueCat context as project 28030dc2. Local source proves the app configures RevenueCat in release and uses the pro entitlement.

Custom paywall impression IDs currently present:

- mahj_onboarding_trial, OnboardingView.swift:79.
- mahj_onboarding_fallback, OnboardingView.swift:82.
- mahj_home_sheet, HomeView.swift:70.
- mahj_settings_sheet, SettingsView.swift:41.
- mahj_room_sheet, RoomView.swift:41.
- mahj_paywall_sheet, PaywallView.swift:263 and the default source.

The Home training tiles do not pass a source-specific paywall ID. Different locked features therefore collapse into the default paywall source when tapped.

### 4.4 RevenueCat data that is missing

Search of current source found no:

- setAttributes or setAttribute calls;
- RevenueCat login, logout, or identify path;
- plan-selected event;
- purchase-start event;
- purchase-success, cancellation, failure, or refund event;
- product-load failure reason;
- restore-start, restore-success, or restore-failure event;
- skill-level event;
- first-drill or activation event;
- session, streak, weak-room, due-count, or feature-use attribute;
- MetricKit, OSLog, Logger, Sentry, Crashlytics, Firebase, Bugsnag, or equivalent crash system.

RevenueCat custom attributes can help with cohort slicing, but they are not a replacement for an event schema. Use only low-cardinality, privacy-safe values.

Recommended attribute set, subject to verifying the current purchases-ios 5.72 API:

At SubscriptionService.start(), after configure and initial customer info:

- app_version
- build
- locale
- storefront_country if available and not sensitive for the chosen use
- device_family
- onboarding_state

At OnboardingView:

- skill_level when selected
- onboarding_variant
- trial_surface_seen when the trial page appears

At PaywallView:

- paywall_source
- paywall_variant
- selected_plan
- purchase_product_id immediately before purchase
- last_purchase_result after completion
- last_restore_result after restore

At drill and habit surfaces:

- activation_state, with values such as not_started, first_drill_started, first_drill_completed, second_session
- free_drills_completed as a bounded integer or bucket
- total_sessions as a bounded integer or bucket
- streak_days as a bounded integer or bucket
- weakest_room as one of the fixed room IDs
- due_count bucket
- mahj_minute_completed as a boolean-like state
- game_night_prep_used as a boolean-like state

Never send:

- name, email, contact information;
- full hand or practice content;
- arbitrary drill text;
- full item IDs if they create high cardinality;
- raw timestamps for every interaction when a bucket is enough.

### 4.5 RevenueCat and purchase validation

Before any price or paywall decision, capture a read-only catalog snapshot containing:

- project and app ID;
- offering identifier;
- package identifiers;
- product identifiers;
- entitlement mapping;
- product period;
- localized price for a representative set of territories;
- introductory offer duration and eligibility;
- current product state;
- latest customer and transaction error categories without user identity.

The repository has rc-add-lifetime.py and ASC setup and price scripts that mutate external systems. They were not run. They should not be used until the source-of-truth decision is documented.

## 5. Paywall UX and A/B opportunities

### 5.1 Current paywall behavior

PaywallView.swift:

- PaywallPlan order is yearly, lifetime, monthly at lines 4-15.
- The yearly plan is selected by default at line 266.
- Yearly and monthly CTAs say Start 7-Day Free Trial.
- Lifetime says Unlock Mahj+ Forever.
- Product prices are dynamic from RevenueCat StoreProduct, not hardcoded in the rendered paywall.
- The yearly card calculates a per-month equivalent, monthly anchor, and savings percentage from the loaded products at lines 196-236.
- The footer includes price/trial/renewal copy, Restore, Terms of Use, and Privacy Policy at lines 240-331.
- Terms links to Apple's standard EULA.
- Privacy links to jackwallner.github.io/mahj/privacy-policy.
- Purchase calls ensureOfferings(), then purchases the selected package at lines 337-368.
- A successful transaction confirms entitlement. A delayed entitlement tells the user to restore rather than charging again.
- A cancelled Apple sheet returns without an error alert.

Strengths:

- dynamic localized prices reduce stale UI price risk inside the app;
- the annual savings calculation is data-driven;
- restore and legal links are on the purchase screen;
- cancellation is treated as a normal user outcome;
- the lifetime plan is clearly differentiated as one-time.

Risks:

- the paywall is a custom SwiftUI paywall, not a RevenueCat native Paywall or remotely configured offering screen. The Apple purchase sheet is native, but the plan cards, copy, ordering, and experiments are local code.
- there is no visible retry action when offerings fail;
- the exact product selected and paywall source are not recorded;
- the purchase screen does not explicitly say “cancel at least 24 hours before the current period ends” in the visible plan detail. The Terms and App Store description contain the fuller cancellation rule. Verify the final point-of-purchase wording against the current App Review requirement.
- product loading placeholders may leave a low-confidence CTA if the product is not ready;
- the source-specific impression IDs are not enough to reconstruct plan selection or purchase conversion.

### 5.2 Recommended tests

| Test | Control | Variant | Primary metric | Guardrails |
|---|---|---|---|---|
| Plan default | Yearly selected, yearly card first | Monthly selected or annual copy first | Trial start and paid conversion | Net proceeds, refund, cancellation |
| Onboarding plan | Hidden monthly one-tap CTA | Explicit yearly or three-plan choice | Trial starts per install | First-session completion and revenue per install |
| Trial timing | Trial before interactive drill | Free Quick Session before trial | Activation and trial start | Day 1 and day 7 retention |
| Benefit order | Current content list | Daily habit, confidence, and advanced content order | Paywall conversion | Refund and support contacts |
| Lifetime framing | Lifetime last | Lifetime “own forever” value card earlier | Lifetime mix and net proceeds | Subscription trial starts |
| Lock context | Generic Membership label | Room/drill-specific reason and benefit | Paywall open to trial start | Dismissal rate |
| Loading failure | Generic error or fallback | Explicit unavailable state with Retry and Support | Recovered purchase attempt | Error recurrence |
| CTA wording | Start 7-day free trial | Try Mahj+ free for 7 days | CTA tap and purchase completion | Trial cancellation |
| Review timing | Third completed drill | Second session or first completed Mahj Minute | Review gate open and rating count | Session abandonment |

For all experiments:

- persist variant assignment;
- send the variant with each relevant event;
- do not change price, copy, product order, and onboarding timing in the same experiment;
- wait for enough trial starts and paid outcomes to avoid reacting to noise;
- segment by locale, skill level, iPhone/iPad, and acquisition source.

### 5.3 Native paywall “nooks and crannies”

Because the app uses a custom PaywallView rather than RevenueCat's native Paywall UI, the native surfaces available for controlled optimization are:

- the Apple purchase confirmation sheet after plan selection;
- the localized product price and introductory offer rendered by StoreKit or RevenueCat;
- Restore Purchases;
- Terms and Privacy links;
- the App Store product page;
- subscription management after purchase.

The local, controllable surfaces are:

- onboarding trial page;
- Home upgrade card;
- room-level locked rows;
- locked training tiles;
- settings upgrade row;
- plan order and default selection;
- plan card benefit copy;
- loading, retry, and error states;
- post-purchase entitlement confirmation.

Do not test Apple sheet copy as if it were app-controlled. Test the decision context before the sheet and the recovery state after it.

## 6. User experience and product usage

### 6.1 Feature and entitlement map

Shared/Content/DrillLibrary.swift defines five rooms:

- Tile Room
- Card Room
- Charleston Room
- Table Room
- Master Tables

The free/Mahj+ split is per drill:

- the four non-master rooms each contain two free drills and one Mahj+ set;
- Master Tables contains four paid drills;
- the app therefore has seven locked drills total;
- HomeView.swift:590 describes seven more drills across every room, plus other Mahj+ modes;
- RoomView.swift:150-155 shows the locked count and contextual upgrade copy;
- all beginner rooms remain free, which is a strong trust and conversion position.

Mahj+ gated training features include:

- Mahj Minute;
- Game Night Prep;
- Endless Practice;
- Timed Challenge;
- Fix My Mistakes;
- extra sets and Master Tables.

HomeView.swift:390-492 renders the training tiles. Locked training tiles show the same Membership label and open a generic paywall. This is a missed context signal. Pass source values such as mahj_home_mahj_minute, mahj_home_game_night, mahj_home_endless, mahj_home_timed, and mahj_home_mistakes, or send a fixed feature attribute alongside one shared paywall ID.

RoomView.swift:75-155 knows the room and drill that caused the lock, but the paywall source only says mahj_room_sheet. Add fixed room_id, drill_id category, and lock_reason values if RevenueCat attributes or an event sink is used. Do not send arbitrary practice content.

### 6.2 Local usage model

ProgressStore and PracticeRecordStore are local:

- ProgressStore stores launches, sessions, completions, streaks, seen items, and missed items in UserDefaults.
- PracticeRecordStore stores per-skill records and a review queue using an SM-2-like schedule.
- generated practice items collapse into bounded skill rows, which is good for local storage but means detailed drill behavior is not available remotely.
- Mahj Minute is daily and includes an archive and share result path.
- Game Night Prep uses weak rooms, due mistakes, unseen material, and a local weekly reminder.
- AppSettings uses local daily and weekly notifications.
- There is no account or server-side usage model in the repository.

This makes the product feel private and simple, but it prevents answering basic growth questions:

- Which first drill produces the first trial?
- Which free room produces the second session?
- Does Mahj Minute retain better than ordinary drills?
- Do weak-room reminders return users?
- Which locked feature gets the highest paywall-to-trial conversion?
- Does iPad usage have different conversion or retention?

Add the minimum instrumentation needed to answer these questions without collecting practice content.

### 6.3 UX strengths

- Free rooms are complete enough to communicate value without an immediate purchase.
- The training surface creates recurring reasons to return.
- Review mistakes and weak-room personalization give the app a habit loop.
- The app uses a clear Mahj+ brand in most player-facing UI.
- The purchase flow handles user cancellation explicitly.
- Product prices are localized dynamically.
- The product supports iPad as well as iPhone.
- ContentValidityTests protects original content, free access boundaries, and required disclaimers.

### 6.4 UX risks and opportunities

P1, contextual conversion:

- Home has several locked training tiles and an upgrade card.
- Room detail has locked rows and contextual copy.
- The generic default paywall source loses the feature and room context.
- Test a specific “what you get here” block with the selected benefit at the top of the paywall.

P1, demographic accessibility:

- The research note identifies a likely older learner audience.
- The current UI needs a current device pass for Dynamic Type, VoiceOver, Reduce Motion, high contrast, iPad split or landscape layouts, touch target sizes, and zoomed display.
- The old flow audit explicitly did not fully verify accessibility, dark mode, rotation, iPad, VoiceOver, Reduce Motion, or low-memory behavior.
- Add these as release checks, not optional polish.

P1, motion and transition reliability:

H, archive/flow-catalog-2026-07-12.md:101-175 reports:

- F1, black compositing frames around the flashcard 3D flip and swipe.
- F2, clipped or ghosted onboarding and navigation transitions.
- F3, a transient black or missing-content state around Settings toggle redraw.
- F4, purchase cancellation and product failure branches not safely exercisable on the simulator.
- F5, mixed-session behavior not fully completed.
- F6, inconsistent grading vocabulary and capitalization.

The source has since changed and comments indicate attempted fixes, so these are not current confirmed defects. They are high-value regression targets because they affect first-run confidence, drill comprehension, and screenshots. Revalidate on a physical device and with Reduce Motion enabled.

P2, empty-state resilience:

- PracticeRunView has a route that can deliver a zero-item completion state when a review queue is empty or becomes stale.
- Verify the UI gives a useful “nothing due” message with a route to a free drill rather than showing a completed 0/0 session.

P2, feedback grammar:

- Flashcard verdict stamps use KNEW IT, AGAIN, and NEXT.
- Other drills use Knew it and Again.
- Standardize the action vocabulary and accessibility hints while preserving the distinction between self-grading and a next-question action.

P2, settings trust:

- Settings includes upgrade, restore, Manage Subscription, Rate, and Send Feedback.
- Settings does not show direct Terms or Privacy rows.
- Add legal and support links in Settings so a subscriber does not need to reopen a paywall to find them.

P2, notification value:

- Daily and weekly reminders are local only.
- Instrument permission granted, permission denied, scheduled, opened, and disabled states if the product needs to evaluate reminder effectiveness.
- Do not assume a scheduled local reminder was delivered or opened.

## 7. Ratings and review funnel

### 7.1 Current funnel

Shared/Services/ReviewPromptTracker.swift:

- App Store ID is 6790052126.
- The write-review URL is the App Store action=write-review URL.
- Negative feedback routes to jackwallner+m@gmail.com.
- The gate requires at least three positive moments and two launches.
- Hard cooldown is 120 days.
- Soft defer cooldown is 30 days.
- Outcomes are terminal for openedWriteReview and submittedFeedback.
- DrillCompleteView and MahjMinuteResultView record a positive moment and wait approximately 1.4 seconds after completion before showing the review sheet.
- Settings has direct Rate and Send Feedback actions.

The pre-prompt is a good policy choice:

- satisfied users can go to the App Store;
- unsatisfied users can send feedback;
- the app does not ask unhappy users for a rating.

### 7.2 Funnel problems

P1, Maybe later semantics:

- ReviewPromptTracker.swift:49-52 documents that Maybe later fires requestReview().
- SettingsView.swift:55 also calls requestReview() for enjoyedMaybeLater.
- The visible button says Maybe later, but the action can immediately show Apple's native review prompt.
- Apple may silently suppress the native prompt, making behavior unpredictable.
- Either make Maybe later truly defer, or rename the action to a clear native-rating action. Test one consistent behavior.

P1, measurement gap:

- The tracker records local state but does not emit remote events.
- Opening the App Store URL is not proof that a rating was submitted.
- Native requestReview is not observable as a submitted rating.
- There is no funnel metric for gate shown, yes, no, maybe later, write-review URL opened, feedback started, or mail client opened.
- Public rating is 5.0 from six ratings, which is encouraging but too small to infer causal lift.

P2, timing:

- The third completed drill may be too early for a learner who has not seen the recurring value.
- Compare the third drill with second-session completion and Mahj Minute completion, while preserving the negative-feedback branch.

### 7.3 Recommended review experiments

- Keep the current satisfaction gate as the control.
- Test the gate after the first meaningful “I got it” moment versus after the third completed drill.
- Test direct write-review URL versus native requestReview only for satisfied users.
- Keep the no-feedback route for users who select no.
- Measure rating count growth, app-store conversion where available, support mail volume, day 7 retention, and session completion.
- Do not use the 5.0 rating alone as a success criterion.

## 8. Website, Terms, Privacy, and consistency

### 8.1 Website evidence

docs/index.html:

- canonical is https://jackwallner.com/ios/mahj/ at line 10;
- App Store badge uses app ID 6790052126;
- download links use the correct public App Store ID;
- JSON-LD lists free, monthly $9.99, yearly $39.99, and lifetime $89.99 at lines 30-53;
- JSON-LD softwareVersion is 1.2.0 at line 60;
- JSON-LD aggregateRating is 5 with ratingCount 1 at lines 65-68;
- visible copy uses Mahj+, four free rooms, a one-week trial, and prices shown in-app;
- seller and metadata URLs point to jackwallner.github.io/mahj.

Concrete consistency issues:

1. Website schema prices match the local StoreKit fixture but not CLAUDE.md, historical acquisition notes, or ASC scripts.
2. Website schema softwareVersion 1.2.0 matches the public listing but not the pending 1.2.1 build.
3. Website schema ratingCount 1 is stale against the public six-rating snapshot.
4. Website canonical host differs from the App Store marketing URL. Verify whether jackwallner.com/ios/mahj/ redirects to or intentionally mirrors GitHub Pages. Pick one canonical marketing domain.
5. The visible website mostly uses Mahj+, while docs/terms.html uses Mahj Trainer Pro in subscription language.
6. The website has no explicit trial-eligibility troubleshooting or “paid but still locked” support path.

Do not update schema until the price and release truth are selected. A machine-generated schema file or checked snapshot would prevent this class of drift.

### 8.2 Terms

docs/terms.html:62 says last updated August 17, 2026.

docs/terms.html:81-95 says Mahj Trainer Pro includes monthly and yearly auto-renewing subscriptions and a one-time lifetime purchase, prices and trial shown before purchase, Apple billing, cancellation, renewal, management, and refund handling.

The terms are operationally useful, but the product name conflicts with player-facing Mahj+. Decide whether “Mahj Trainer Pro” is the legal product name and “Mahj+” is the UI brand, then state that relationship once and use it consistently.

Terms coverage that should be verified:

- introductory offer eligibility;
- whether a trial is offered only to eligible Apple IDs;
- exact restore behavior;
- support route when entitlement does not unlock;
- price and period always shown in the Apple purchase context;
- links work from the app, website, and all required ASC localizations.

### 8.3 Privacy

docs/privacy-policy.html:62 is dated August 17, 2026.

It describes local progress and preferences, Apple purchase processing, RevenueCat purchase verification and restoration, and the absence of an account, ads, analytics SDK, tracking pixel, and similar systems.

Per request, this audit does not flag any RevenueCat data disclosure or tracking wording as an inconsistency. The operational improvement is to keep the purchase and restore behavior, legal links, and support language synchronized when the catalog or product branding changes.

### 8.4 Support

docs/support.html contains contact, restore, cancellation, and card disclaimer guidance.

Add practical answers for:

- trial eligibility and why a trial may not appear;
- product prices vary by storefront;
- offerings unavailable or App Store unreachable;
- purchase succeeded but Mahj+ is still locked;
- Restore Purchases result and expected delay;
- how to contact support with app version, build, device, and storefront, without requesting practice content.

### 8.5 Legal link placement

PaywallView has Terms and Privacy links. Settings does not have direct legal links. Add them to Settings in a future implementation so they are available outside an upsell context.

## 9. Crash, regression, and watchdog signals

### 9.1 Current local observability

No current source match was found for:

- MetricKit, MXMetricManager, MXCrashDiagnostic, or MXHangDiagnostic;
- OSLog or Logger;
- Sentry, Crashlytics, Firebase, Bugsnag, or another crash SDK;
- generic analytics event calls;
- RevenueCat custom attributes;
- structured purchase or product-load error events.

The repository therefore cannot notify anyone when a live user crashes, hangs, fails to load products, or hits a purchase regression. This is a capability gap, not evidence that crashes are occurring.

### 9.2 Current test evidence

A headless simulator lease was used for Mahj with the shared agent-sim pool. The run targeted the leased device ID, not a named simulator. The production RevenueCat key was not used by the simulator path.

Command run:

xcodebuild test -project MahjTrainer.xcodeproj -scheme MahjTrainer -destination "id=<leased Mahj simulator>" -derivedDataPath /tmp/mahj-audit823-derived -quiet

Result:

- compilation reached the test-run phase with warnings;
- test workers did not materialize and the runner reported a worker coordination delay;
- the invocation was interrupted after the wait;
- final result was BUILD INTERRUPTED;
- this is not a passing test result and not proof of a product crash.

Warnings observed:

- MahjTrainer/Utilities/Theme.swift:171-195 has Swift 6 concurrency warnings around synchronous, nonisolated Haptics calls into main-actor UIKit feedback generators.
- MahjTrainerTests/PracticeRecordStoreTests.swift has main-actor isolation warnings around test properties and PracticeRecordStore initialization.
- MahjTrainerTests/ReviewPromptTrackerTests.swift:9 and 13 has main-actor isolation warnings around static setup and teardown.
- MahjTrainerTests/ProgressStoreTests.swift has similar main-actor isolation warnings.

The test-runner diagnostic mentioned waiting for workers to materialize, a processing delay, and an attempt to allow restarting crashed test operations. Treat this as test infrastructure or test-worker instability until reproduced with logs. It is an urgent release gate because the current result cannot establish a green baseline.

Historical comparison:

- H, archive/flow-catalog-2026-07-12.md reports a prior 24-test baseline and source-level UI findings.
- H, ios27MahjTrainer.md dated 2026-08-05 reports an earlier debug build and test pass with concurrency warnings.
- Neither historical result proves the current 1.2.1 build is green.

### 9.3 Watchdog design to implement later

No notification deployment is requested in this audit. A future MacBook or CI watchdog should be read-only by default and configurable through environment variables or a local config file.

Release-state checks:

- compare local project version/build with ASC pending version/build;
- compare public store version with ASC status;
- flag a pending version that is older or newer than expected;
- flag a release where the public version changes without a matching release note;
- report IAP product state, subscription group, trial duration, and price schedule;
- report missing or stale ASC localizations;
- report missing screenshots, wrong dimensions, duplicate hashes, and stale version labels;
- report legal URL failures and canonical URL changes.

Catalog consistency checks:

- scan source, StoreKit fixture, scripts, website schema, metadata, terms, and CLAUDE.md for product IDs, entitlement ID, plan names, and price literals;
- fail when a product ID is missing from one required source;
- fail when monthly/yearly/lifetime names disagree without an allowlist;
- fail when the onboarding selected plan differs from the documented selected plan;
- fail when a price-bearing fixture differs from the approved catalog manifest;
- report historical files separately so an agent does not treat archive values as live values.

Runtime and production checks:

- consume ASC App Analytics, Crashes, and retention data after each release;
- compare crash-free users, crash-free sessions, hangs, launch failures, and retention for 24 hours and seven days against the previous release;
- consume RevenueCat offering load failures, transaction failures, trial starts, renewals, cancellations, refunds, and entitlement mismatches;
- monitor ratings count and new one-star review volume;
- monitor support mail volume for “paid but locked”, “trial”, “restore”, and “crash” subjects;
- keep a release watch window for at least 24 hours after a new production build, with a seven-day review.

On-device diagnostic options for a future implementation:

- MetricKit for crash, hang, launch, and performance diagnostics;
- OSLog or Logger with a small privacy-safe event vocabulary;
- a durable local ring buffer that can be attached to support exports;
- a production crash service only if the privacy and App Store disclosures are intentionally updated.

Do not build a watchdog that silently scrapes private user data or sends full practice content. Use aggregates and redacted error categories.

## 10. Agent documentation hygiene

### 10.1 Current structure

The repository has:

- CLAUDE.md as the main app guide;
- AGENTS.md as a symlink to CLAUDE.md;
- no repository-scoped .cursor rules;
- no repository-scoped .claude, .codex, or .agents instruction directory found at the inspected depth;
- archive/ for dated historical audits and plans;
- docs/ for website, legal, research, and submission notes;
- scripts/ for ASC, RevenueCat, screenshot, and release automation.

The AGENTS.md symlink is good for Claude and Codex continuity. Cursor has no dedicated repository rule directory in this checkout, so the team should decide whether the symlink is sufficient for the intended Cursor setup or whether one canonical checked-in instruction source should be referenced explicitly.

### 10.2 Current contradictions agents can act on incorrectly

Highest impact:

- CLAUDE.md:30-32 says $1.99 monthly, $9.99 yearly, $29.99 lifetime.
- MahjTrainer.storekit says $9.99 monthly, $39.99 yearly, $89.99 lifetime.
- docs/index.html schema says $9.99, $39.99, $89.99.
- scripts/asc-setup-release.py says $4.99 and $19.99.
- scripts/asc-set-prices.py says $4.99, $19.99, and $49.99.
- archive/ads89.md says the original price is $1.99, $9.99, $29.99 and proposes a future two-times test.
- docs/research/mahjong-market.md contains another historical price table.
- CLAUDE.md describes a yearly onboarding purchase, while OnboardingView.swift buys monthly.
- CLAUDE.md says player-facing Pro is retired, while terms and mutation scripts use Pro.

An agent following the first plausible file can make a wrong ASC mutation or change the onboarding trial without noticing the conflict.

### 10.3 Stale or historical documents

Mark, move, or clearly label these in a future documentation pass:

- ios27MahjTrainer.md, dated 2026-08-05, top-level and easy to mistake for current release truth;
- docs/asc-submission-checklist.md, which contains dated legal and submission checks and a historical upload state;
- docs/tasks/03-pricing-increase-1.3.md, a task note that can be confused with current pricing;
- scripts/.asc-state.json, stale version snapshot;
- scripts/.astro-app.json, stale sync snapshot;
- archive/flow-catalog-2026-07-12.md, historical interaction audit;
- archive/ads89.md, historical acquisition and revenue baseline;
- docs/research/mahjong-market.md, dated market research with historical price observations.

The archive/README.md correctly says dated audits and plans are historical. The problem is that several dated files remain at the repository root or active docs paths without a strong “historical, do not use as source of truth” banner.

### 10.4 Recommended source-of-truth contract

Add a future, concise catalog and release manifest with:

- app ID and bundle ID;
- public and pending version;
- build;
- product IDs;
- entitlement ID;
- approved plan display names;
- approved trial duration;
- approved price source, explicitly “ASC live catalog”;
- approved player-facing brand and legal product relationship;
- marketing URL, support URL, privacy URL, Terms URL;
- current status and last verified timestamp;
- owners for ASC, RevenueCat, code, website, and agent docs.

Then update CLAUDE.md and AGENTS.md guidance to say:

- never infer live price from StoreKit fixtures;
- never run mutating ASC or RevenueCat scripts without a current manifest check;
- archive dated plans once superseded;
- label historical revenue and ranking data with date and source;
- keep onboarding plan selection and trial disclosure in the same test or manifest;
- run the read-only readiness and consistency scanner before any upload.

No agent-documentation files were changed as part of this audit.

## 11. Recommended implementation backlog

### P0, before release or paid acquisition

1. Resolve catalog truth.
   - Verify live ASC products and prices.
   - Verify RevenueCat offering and pro entitlement.
   - Decide Mahj+ versus Pro legal naming.
   - Decide monthly versus yearly onboarding purchase.
   - Publish a catalog manifest.
   - Reconcile StoreKit, website schema, scripts, docs, and metadata.
   - Validation: one automated consistency report with zero unapproved differences.

2. Resolve release truth.
   - Confirm 1.2.1 build 23 in ASC.
   - Confirm IAPs and introductory offers are attached and reviewable.
   - Confirm public version remains 1.2.0 until the new release is live.
   - Refresh scripts/.asc-state.json only from a read-only ASC query.
   - Validation: local, ASC, and public version table agrees on expected pending/live state.

3. Restore a green test gate.
   - Reproduce the worker materialization failure with full test logs.
   - Run unit tests and UI tests separately.
   - Resolve or consciously baseline Swift 6 actor warnings.
   - Validation: current unit and required UI tests finish successfully on a leased simulator, followed by physical-device purchase and transition checks.

### P1, before scaling acquisition

4. Instrument activation and monetization.
   - Add source, variant, plan, product, offering, purchase outcome, restore outcome, skill, first drill, second session, and feature use.
   - Use low-cardinality RevenueCat attributes and a durable event path.
   - Validation: a test customer or sandbox run produces a complete funnel trace without PII.

5. Harden product loading and restore.
   - Add offerings loading, unavailable, retry, and support states.
   - Preserve the intended CTA after retry.
   - Show explicit restore success, no purchase, and failure states in onboarding.
   - Validation: simulate offline, delayed products, missing package, cancelled purchase, failed purchase, successful purchase, delayed entitlement, and restore.

6. Revalidate historical motion issues.
   - Flashcard flip and swipe.
   - Onboarding and navigation transitions.
   - Settings redraw.
   - Mixed session transitions.
   - Validation: physical iPhone and iPad, dark mode, Reduce Motion, Dynamic Type, VoiceOver, rotation, and low-memory pass.

7. Fix screenshot quality gates.
   - Choose a single source of truth for docs and fastlane screenshots.
   - Add hard assertions for required controls.
   - Re-capture screenshot 05 with safe disclaimer padding.
   - Validation: dimensions, hashes, OCR or accessibility labels, and visual review all pass.

8. Repair website and legal consistency.
   - Align canonical domain and marketing URL.
   - Refresh schema price, rating count, and softwareVersion from approved sources.
   - Decide Pro and Mahj+ naming relationship.
   - Add trial and entitlement troubleshooting to support.
   - Add Settings legal links.
   - Validation: all links return success, schema matches the approved manifest, and the pending/public version is labeled correctly.

### P2, optimize after a stable baseline

9. Test onboarding timing and plan presentation.
10. Test plan order and lifetime framing.
11. Test contextual paywall source and lock copy.
12. Test review timing and native versus direct store route.
13. Test screenshot product-page variants.
14. Test Apple Ads core versus all-eligible audiences only after trial and paid cohorts are measurable.
15. Add release watchdog automation and a 24-hour/7-day release review template.

## 12. Validation checklist for the implementing agent

### Catalog and ASC

- [ ] Read live ASC product identifiers, prices, periods, subscription group, lifetime IAP state, and introductory offers.
- [ ] Read live RevenueCat offering, packages, product identifiers, and entitlement mapping.
- [ ] Confirm product IDs are exactly com.jackwallner.mahj.monthly, com.jackwallner.mahj.yearly, and com.jackwallner.mahj.lifetime, unless a deliberate migration is approved.
- [ ] Confirm the intended trial is seven days and the intended trial plan is documented.
- [ ] Confirm 1.2.1 build 23 and Waiting for Review state.
- [ ] Keep public 1.2.0 separate from pending 1.2.1 in release notes and website labels.
- [ ] Remove or clearly mark stale price scripts and historical price notes.

### Trial and purchase

- [ ] Test new user onboarding with a product-ready response.
- [ ] Test product loading delay.
- [ ] Test product failure and retry.
- [ ] Test monthly, yearly, and lifetime plan selection.
- [ ] Test Apple purchase cancellation.
- [ ] Test purchase failure.
- [ ] Test successful entitlement with delayed RevenueCat refresh.
- [ ] Test restore success, no previous purchase, and restore error.
- [ ] Test a user who is already entitled.
- [ ] Verify price, period, trial, auto-renew, cancellation, Restore, Terms, and Privacy at the point of purchase.

### UX and accessibility

- [ ] Complete one free drill before and after any onboarding experiment.
- [ ] Verify free rooms remain free in every path.
- [ ] Verify all seven locked drills and all Mahj+ training tiles open contextual paywalls.
- [ ] Verify no 0/0 empty session state is presented without an explanation.
- [ ] Verify Dynamic Type, VoiceOver, Reduce Motion, dark mode, iPad, rotation, and touch targets.
- [ ] Recheck flashcard motion, onboarding transitions, and Settings redraw on a physical device.

### Ratings

- [ ] Verify the three-positive-moment and two-launch gate.
- [ ] Decide whether Maybe later defers or opens a native prompt, then align label and behavior.
- [ ] Verify unhappy users still route to feedback.
- [ ] Track gate shown, store URL opened, feedback started, and native prompt requested.
- [ ] Do not treat URL open as rating submission.

### Metadata and website

- [ ] Verify all intended ASC locale localizations are actually present.
- [ ] Decide the marketing URL policy for the 39 blank locale files.
- [ ] Check every support, privacy, terms, and marketing URL.
- [ ] Refresh website schema price, rating count, version, and canonical URL from the manifest.
- [ ] Recheck screenshot dimensions and source-of-truth ownership.
- [ ] Keep prices out of descriptions and promotional copy unless the copy is intentionally storefront-specific.

### Watchdog

- [ ] Add read-only release-state comparison.
- [ ] Add catalog and text consistency scan.
- [ ] Add screenshot lint.
- [ ] Add URL and metadata completeness checks.
- [ ] Add a post-release ASC and RevenueCat metric snapshot.
- [ ] Add crash and hang diagnostics before claiming live-user crash notification capability.
- [ ] Configure alerts only after thresholds and recipients are explicitly chosen.

## 13. Concrete source index

Core configuration:

- project.yml:7-8, 13-37, 66-102
- MahjTrainer/Info.plist
- MahjTrainer/MahjTrainer.storekit
- fastlane/metadata/en-US/description.txt
- scripts/asc-supported-locales.json
- scripts/.asc-state.json
- scripts/.astro-app.json

Onboarding and purchase:

- MahjTrainer/Views/OnboardingView.swift:3-8, 77-83, 196-310, 324-376
- MahjTrainer/Views/PaywallView.swift:4-15, 78-92, 196-263, 288-368
- Shared/Services/SubscriptionService.swift:4-10, 32-100, 103-171
- MahjTrainer/Views/HomeView.swift:70, 390-492, 576-615
- MahjTrainer/Views/RoomView.swift:41, 75-155
- MahjTrainer/Views/SettingsView.swift

Usage and content:

- Shared/Content/DrillLibrary.swift
- Shared/Content/ProContent.swift
- Shared/Services/ProgressStore.swift
- Shared/Services/PracticeRecordStore.swift
- MahjTrainer/Views/PracticeRunView.swift
- MahjTrainer/Views/MahjMinuteView.swift
- MahjTrainer/Views/GameNightPrepView.swift
- MahjTrainer/Views/DrillCompleteView.swift
- MahjTrainer/Views/MahjMinuteResultView.swift

Ratings:

- Shared/Services/ReviewPromptTracker.swift:11-125
- MahjTrainer/Views/SettingsView.swift:10, 55, 181
- MahjTrainerTests/ReviewPromptTrackerTests.swift:25-76

Metadata and release automation:

- scripts/asc-readiness.py
- scripts/asc-upload-metadata.py:42-88, 162-194
- scripts/asc-upload-screenshots.py
- scripts/asc-setup-release.py
- scripts/asc-set-prices.py
- scripts/rc-add-lifetime.py
- fastlane/Fastfile
- fastlane/Appfile

Website and historical evidence:

- docs/index.html:10-68, 500-660
- docs/privacy-policy.html:62-87
- docs/terms.html:62-95
- docs/support.html
- docs/asc-submission-checklist.md
- docs/research/mahjong-market.md
- archive/flow-catalog-2026-07-12.md
- archive/ads89.md
- ios27MahjTrainer.md
- archive/README.md

Test and screenshot quality:

- MahjTrainerScreenshots/ScreenshotTests.swift:13-24, 43-71, 153
- MahjTrainerScreenshots/PaywallRenderTests.swift:16-24, 37-95, 131
- MahjTrainerTests/ProgressStoreTests.swift
- MahjTrainerTests/PracticeRecordStoreTests.swift
- MahjTrainerTests/ReviewPromptTrackerTests.swift

## Final decision

Mahj Trainer is suitable for continued product and acquisition work, but not for confident scaling or a catalog-affecting release until the price, plan, trial, naming, and release state are reconciled. The immediate implementation handoff should start with the catalog manifest and read-only release check, then purchase failure handling and funnel instrumentation, then current physical-device and accessibility regression testing.

## Activity and success context, 2026-08-23

Classification: **active monetizing**. Confidence: **high**. Trend: **no ASC comparison displayed**.

ASC release state: `iOS 1.2.1 Waiting for Review`. ASC evidence: [Analytics Overview](https://appstoreconnect.apple.com/apps/6790052126/analytics/overview?dateSpec=d90), selected range `dateSpec=d90`.
RevenueCat evidence: [Project Overview](https://app.revenuecat.com/projects/28030dc2/overview), production mode, selected range `Last 28 days, 2026-07-27 through 2026-08-23`.

### Observed activity

| Source | Metric | Value | Window or comparison |
| --- | --- | ---: | --- |
| ASC | first-time downloads | 270 | 90-day Analytics Overview |
| ASC | redownloads | 11 | 90-day Analytics Overview |
| ASC | conversion rate | 1.32% | comparison not displayed |
| ASC | proceeds | $292 | 90-day Analytics Overview |
| ASC | in-app purchases | 111 | 90-day Analytics Overview |
| RevenueCat | new customers | 220 | last 28 days |
| RevenueCat | active customers | 247 | last 28 days |
| RevenueCat | active trials | 18 | current total |
| RevenueCat | active subscriptions | 35 | current total |
| RevenueCat | MRR | $75 | current total |
| RevenueCat | revenue | $348 | last 28 days |

A missing value above means the source did not expose that metric in this read-only snapshot. It is not a zero.

### Interpretation and implementation focus

Mahj is a core monetizing app in this snapshot: 270 ASC first-time downloads, $292 of ASC proceeds, 220 RevenueCat new customers, 18 active trials, 35 active subscriptions, $75 MRR, and $348 RevenueCat revenue. The main opportunity is not generic acquisition copy. It is to protect the current paid path, remove conversion ambiguity in the trial cohort, and use the catalog, paywall, and release evidence in the audit to improve trial starts without disrupting a working revenue engine.

The deterministic classifier recommends: Protect the current paid path, then use release and cohort baselines to decide whether acquisition or conversion is the next constraint.

- Join ASC first-time download, first launch, first value, paywall shown, offer loaded, trial started, trial canceled, trial converted, entitlement active, restore, and purchase failure events with the app version and build.
- Keep ASC's 90-day acquisition and proceeds window separate from RevenueCat's 28-day customer and revenue window. Do not calculate a conversion rate by dividing values from different windows.
- Use a mature trial cohort and a minimum sample before choosing a native paywall or onboarding A/B winner. Record the offering identifier, package, placement, experiment variant, and build.
- Put the app's classification and the next baseline date in the release handoff so Cursor, Claude, and Codex do not optimize from an old qualitative audit.

### Boundary on success or death

This snapshot supports the label **active monetizing**, not a lifetime verdict. The app has current paid activity, but ASC does not expose a positive comparison for the selected window. A later decision should include a clean 28-day RevenueCat trend, ASC acquisition and conversion trend, ratings and review count, crash and hang evidence, and a release-specific cohort.
This dated section supersedes earlier statements in this file that per-app ASC or RevenueCat activity was unavailable as of 2026-08-23. Earlier statements remain historical evidence boundaries for their original audit pass.
