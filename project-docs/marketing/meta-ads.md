# Meta (Facebook and Instagram) ads: prep

Status 2026-10-16: **turned on.** Meta app `987930193620309` (Live, E3 Fitness LLC,
iOS bundle + store ID, ad account `1842133493904848` authorized, App Page Mahj
Trainer, automatic in-app event logging off). Dataset `1445876447511793`; its
CAPI token is in `~/.mahj_credentials` and set as the relay's `META_DATASET_ID` /
`META_CAPI_TOKEN` secrets. SDK on from build 49 (1.4.1, TestFlight). Left:
RevenueCat Meta integration (Jack, step 6), app icon on the Meta app (Jack),
privacy labels (step 7) before the App Store submission. One stray test
StartTrial was recorded as a live event on 2026-10-16 (wrong test code).

Status 2026-10-15: code ready, relay live, **no Meta app, no ad account, no
spend**. Approved as prep only ([decisions](../../../ios/growth/2026-10-15-growth-decisions.md),
research in `~/ios/growth/2026-10-14-x-likes-ads-research.md`). A real test is
$350 to $1,000 and is Jack's call.

## What is built

| Piece | Where | State |
|---|---|---|
| Meta SDK 18.1.1 (`FacebookCore`), purchase auto-logging off, `activateApp()` on every foreground | `Shared/Services/MetaAds.swift`, `project.yml` | Inert until `META_APP_ID` + `META_CLIENT_TOKEN` are set |
| RevenueCat link: `$fbAnonId`, `collectDeviceIdentifiers()` (again after ATT), `meta_extinfo` | `MetaAds.linkRevenueCat()`, called from `SubscriptionService.configureIfNeeded` | Inert with the SDK |
| ATT prompt, on Home after onboarding, never over a sheet, never at launch | `HomeView.askForTrackingIfNeeded`, `NSUserTrackingUsageDescription` | Shown only when Meta is on |
| SKAdNetwork ids for Meta | `Info.plist` `SKAdNetworkItems` | Shipping |
| 15-minute StartTrial relay | `supabase/functions/meta-trial-relay`, `supabase/migrations/20261015170000_meta_trial_relay.sql` | **Live**, recording trials, sends nothing (`would_send`) |
| RevenueCat webhook to the relay | RC project `28030dc2`, webhook `whintgrfb640672ce`, App Store app, production, `initial_purchase`/`cancellation`/`expiration` | **Live** |
| Privacy policy section | `docs/privacy-policy.html`, `docs/privacy-policy/index.html` | Published with this change |

The simulator never starts the SDK. `-mahj.previewMetaATT` (DEBUG) shows the
real ATT prompt without a Meta app, for captures:
`scripts/capture-meta-cta.sh <udid> <out-dir>`.

## Who sends what

- **Meta SDK:** installs, app opens, SKAN/AEM. Nothing about purchases.
- **RevenueCat Meta Ads integration:** Subscribe (trial converted, initial
  purchase, renewal) and `fb_mobile_purchase` (lifetime). **Not StartTrial.**
- **Relay:** StartTrial, only for a trial still on 15 minutes after it began
  (@cvazquez310's tip: Meta otherwise learns to find trial-and-cancel users).

### The relay

RevenueCat webhook (`Authorization` = `META_RELAY_RC_WEBHOOK_AUTH`) stores each
`INITIAL_PURCHASE` with `period_type TRIAL` in `public.meta_trial_relay`
(Supabase project `ucoveqbyfuxqvpysmixu`, "Sports", next to `app_feedback`)
and stamps `cancelled_at` on a `CANCELLATION`/`EXPIRATION`. pg_cron job
`meta-trial-relay` runs `meta_trial_relay_tick()` every minute; it calls the
function's `?sweep` only when a trial is 15 minutes old. The sweep then:

1. drops a trial the webhook already saw cancelled (`cancelled`);
2. rechecks RevenueCat v2 (subscription `trialing`/`active` and renewal
   `will_renew`/`will_change_product`), else `cancelled`;
3. needs `$attConsentStatus = authorized` (Apple: no user-level events to Meta
   without consent). `denied`/`restricted` is `no_consent`; not answered yet
   waits up to 24 hours (the prompt comes after onboarding, usually after the
   trial started) then `no_consent`;
4. builds a CAPI app event shaped like RevenueCat's (`anon_id`, `madid`, IP,
   hashed `external_id`, `extinfo` from the app's `meta_extinfo`,
   `event_id = rc_trial_<original transaction>`) and POSTs it to
   `graph.facebook.com/<META_GRAPH_VERSION>/<META_DATASET_ID>/events`
   (`sent`), or records it as `would_send` while Meta is not configured.
   Sandbox/TestFlight rows are only ever sent with `META_TEST_EVENT_CODE`.

Function secrets (project-wide, all `META_` prefixed so they cannot collide
with Sports' functions): `META_RELAY_RC_WEBHOOK_AUTH`, `META_RELAY_CRON_SECRET`
(also vault `meta_relay_cron_secret`, with `meta_relay_url`),
`META_RELAY_RC_SECRET_KEY`, `META_RELAY_RC_PROJECT_ID`; later
`META_DATASET_ID`, `META_CAPI_TOKEN`, optional `META_TEST_EVENT_CODE`,
`META_GRAPH_VERSION` (default `v24.0`), `META_SEND_WITHOUT_ATT` (leave unset).
Local copies of the generated secrets: `~/.mahj_credentials`.

Watch it (counts per status; `would_send` vs `cancelled` is the real
15-minute cancel rate, useful even before Meta exists):

```sql
select status, count(*) from public.meta_trial_relay group by 1 order by 2 desc;
```

Deploy: `SUPABASE_ACCESS_TOKEN=<jackle token> supabase functions deploy
meta-trial-relay --project-ref ucoveqbyfuxqvpysmixu --no-verify-jwt --use-api`.

## Turning it on (when Jack decides to test)

Jack, in the browser (needs his Facebook login and Meta's terms):

1. developers.facebook.com: Create app, use case "Other", type "Business".
   Name "Mahj Trainer". Add platform iOS: bundle `com.jackwallner.mahj`,
   iPhone Store ID `6790052126`. Copy the **App ID** (Settings > Basic) and
   **Client Token** (Settings > Advanced).
2. Events Manager: Connect data > App > pick the app. That creates the
   **dataset**. Dataset Settings > Conversions API > Generate access token.
   Copy the **Dataset ID** and **CAPI token**.
3. Events Manager > the app > Aggregated Event Measurement / SKAdNetwork:
   rank `StartTrial` first. Let only Meta write SKAN conversion values.

Claude, with those four values:

4. `project.yml`: fill `META_APP_ID`, `META_CLIENT_TOKEN`; bump the version.
5. `supabase secrets set META_DATASET_ID=... META_CAPI_TOKEN=...`, then one
   TestFlight trial with `META_TEST_EVENT_CODE` set to Events Manager's Test
   Events code, confirm it lands, unset the code.
6. RevenueCat > Mahj Trainer > Integrations > Meta Ads (Jack, dashboard only):
   app "Mahj Trainer (App Store)", Conversions API with the Dataset ID and
   CAPI token, **"Send events when ATT consent is not authorized" off**.
   Events: **Trial Started: clear the name so it is not sent**; if the field
   cannot be empty, rename it `rc_trial_started_unfiltered` (a custom event
   Meta does not optimize on). Trial Converted, Initial Purchase, Renewal stay
   `Subscribe`; Non-Renewing Purchase stays `fb_mobile_purchase`.
7. App Store Connect privacy labels, in the same submission (list below).
8. Ad account and campaign: only after Jack approves a budget. One campaign,
   1-2 ad sets, optimize on StartTrial, "them vs us" creatives first.

## App Store Connect privacy-label clicks (step 7)

App Store Connect > Mahj Trainer > App Privacy > Edit. Keep everything already
declared; add or change:

- **"Do you or your third-party partners use data for tracking?"** Yes.
- **Identifiers > Device ID** (new): purposes Third-Party Advertising,
  Developer's Advertising or Marketing, Analytics. Linked to the user: Yes
  (matches Meta SDK's manifest). Used for tracking: Yes.
- **Purchases > Purchase History**: add purpose Developer's Advertising or
  Marketing; Used for tracking: Yes.
- **Usage Data > Product Interaction** (installs, opens): Analytics,
  Developer's Advertising or Marketing; tracking Yes.
- **Usage Data > Advertising Data** (new): Developer's Advertising or
  Marketing, Analytics; tracking Yes.
- **Location > Coarse Location** (new; Meta derives it from the IP):
  Developer's Advertising or Marketing; tracking Yes.
- **Diagnostics > Crash Data** and **Other Data**: Meta SDK's manifest
  declares them (App Functionality, Analytics), not linked, no tracking. Add
  them if not already declared.

Do not change the labels before the build that sets the Meta ids is
submitted: until then the app does not track, and labels saying it does would
invite a 5.1.2 rejection for declaring tracking without an ATT prompt.
