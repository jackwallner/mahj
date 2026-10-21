// Meta StartTrial relay for Mahj Trainer and the four card trainers.
//
// Meta optimizes for whatever event it is told about. Told about every trial
// start, it learns to find people who start a trial and cancel it a minute
// later. So StartTrial reaches Meta only for trials that are still on 15
// minutes after they began. RevenueCat's own Meta integration cannot delay or
// filter, so it sends Subscribe events only and this relay owns StartTrial.
//
// Two entry points, one function:
//   POST ?app=<key> (Authorization: RC_WEBHOOK_AUTH)   RevenueCat webhook, one
//        per app's RevenueCat project (no ?app is Mahj). Records trial starts,
//        marks trials cancelled or expired. Never sends anything.
//   POST ?sweep (x-cron-secret: CRON_SECRET)  pg_cron, every minute while a
//        trial is due. Rechecks each due trial against RevenueCat's API and
//        sends the survivors to Meta's Conversions API.
//
// Off by default per app: with no dataset id and CAPI token for that app, a
// trial that would have been sent is marked `would_send` instead. See
// project-docs/marketing/meta-ads.md.

import { createClient } from "jsr:@supabase/supabase-js@2.49.4";

const env = (name: string) => (Deno.env.get(name) ?? "").trim();

const RC_WEBHOOK_AUTH = env("META_RELAY_RC_WEBHOOK_AUTH");
const CRON_SECRET = env("META_RELAY_CRON_SECRET");
const META_GRAPH_VERSION = env("META_GRAPH_VERSION") || "v24.0";
// Apple: sending a user-level event to Meta without ATT consent is tracking
// the user never agreed to. Off unless Jack decides otherwise.
const SEND_WITHOUT_ATT = env("META_SEND_WITHOUT_ATT") === "true";

const HOLD_MINUTES = 15;
// ATT is asked on Home after onboarding, usually after the trial started, and
// RevenueCat only learns the answer when the app next syncs attributes.
const CONSENT_WAIT_HOURS = 24;
// A trial whose subscription RevenueCat cannot find after this is an error.
const LOOKUP_WAIT_HOURS = 2;
// A network error, 429 or 5xx from RevenueCat or Meta leaves the trial
// pending and retries with backoff (2, 4, 8 ... capped at 60 minutes). After
// this many it is an error. Any other 4xx is an error at once.
const MAX_ATTEMPTS = 8;
const MAX_BACKOFF_MINUTES = 60;

type App = {
  bundleID: string;
  rcProject: string;
  rcKey: string;
  datasetID: string;
  capiToken: string;
  testEventCode: string;
};

// Each app has its own RevenueCat project, Meta app and dataset. Mahj keeps
// its original secret names; a card app's are META_<KEY>_RC_SECRET_KEY,
// META_<KEY>_DATASET_ID, META_<KEY>_CAPI_TOKEN and META_<KEY>_TEST_EVENT_CODE.
const card = (key: string, rcProject: string): App => {
  const name = (suffix: string) => env(`META_${key.toUpperCase()}_${suffix}`);
  return {
    bundleID: `com.jackwallner.${key}`,
    rcProject,
    rcKey: name("RC_SECRET_KEY"),
    datasetID: name("DATASET_ID"),
    capiToken: name("CAPI_TOKEN"),
    testEventCode: name("TEST_EVENT_CODE"),
  };
};
const APPS: Record<string, App> = {
  mahj: {
    bundleID: "com.jackwallner.mahj",
    rcProject: env("META_RELAY_RC_PROJECT_ID") || "28030dc2",
    rcKey: env("META_RELAY_RC_SECRET_KEY"),
    datasetID: env("META_DATASET_ID"),
    capiToken: env("META_CAPI_TOKEN"),
    testEventCode: env("META_TEST_EVENT_CODE"),
  },
  bridge: card("bridge", "proj71e29dd0"),
  skat: card("skat", "proje0bf13d7"),
  cribbage: card("cribbage", "proj371df86d"),
  sheepshead: card("sheepshead", "proj3fd00657"),
};

const db = createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), {
  auth: { persistSession: false },
});

type Row = {
  id: string;
  app: string;
  app_user_id: string;
  original_transaction_id: string | null;
  transaction_id: string | null;
  product_id: string | null;
  store: string | null;
  environment: string | null;
  trial_started_at: string;
  cancelled_at: string | null;
  attempts: number;
};

/** A failure worth retrying: the request never landed, or the server said later. */
class Transient extends Error {}

type Verdict = {
  status: "pending" | "sent" | "would_send" | "cancelled" | "no_consent" | "error";
  detail: string;
  meta_response?: unknown;
};

Deno.serve(async (req) => {
  if (req.method !== "POST") return text(405, "POST only");
  const url = new URL(req.url);
  if (url.searchParams.has("sweep")) {
    if (!CRON_SECRET || !same(req.headers.get("x-cron-secret"), CRON_SECRET)) return text(401, "no");
    return json(200, await sweep());
  }
  if (!RC_WEBHOOK_AUTH || !same(req.headers.get("authorization"), RC_WEBHOOK_AUTH)) return text(401, "no");
  const body = await req.json().catch(() => null);
  const event = body?.event;
  if (!event?.id || !event?.type) return text(400, "no event");
  const app = url.searchParams.get("app") ?? "mahj";
  if (!APPS[app]) return text(400, "unknown app");
  return json(200, { handled: await record(app, event) });
});

/** Webhook side: remember trial starts and cancellations. Idempotent. */
async function record(app: string, event: Record<string, any>): Promise<string> {
  const isTrial = String(event.period_type ?? "").toUpperCase() === "TRIAL";
  if (!isTrial) return "ignored";

  if (event.type === "INITIAL_PURCHASE") {
    const { error } = await db.from("meta_trial_relay").upsert({
      id: event.id,
      app,
      app_user_id: event.app_user_id,
      original_transaction_id: event.original_transaction_id ?? event.transaction_id ?? null,
      transaction_id: event.transaction_id ?? null,
      product_id: event.product_id ?? null,
      store: event.store ?? null,
      environment: event.environment ?? null,
      trial_started_at: new Date(Number(event.purchased_at_ms ?? event.event_timestamp_ms)).toISOString(),
    }, { onConflict: "id", ignoreDuplicates: true });
    if (error) throw error;
    return "trial_recorded";
  }

  if (event.type === "CANCELLATION" || event.type === "EXPIRATION") {
    const at = new Date(Number(event.event_timestamp_ms ?? Date.now())).toISOString();
    let query = db.from("meta_trial_relay").update({ cancelled_at: at })
      .eq("app", app).eq("status", "pending").is("cancelled_at", null);
    query = event.original_transaction_id
      ? query.eq("original_transaction_id", event.original_transaction_id)
      : query.eq("app_user_id", event.app_user_id).eq("product_id", event.product_id);
    const { error } = await query;
    if (error) throw error;
    return "trial_cancelled";
  }
  return "ignored";
}

/** Cron side: decide every trial whose 15 minutes are up. */
async function sweep() {
  const now = new Date().toISOString();
  const due = new Date(Date.now() - HOLD_MINUTES * 60_000).toISOString();
  const { data, error } = await db.from("meta_trial_relay")
    .select("id, app, app_user_id, original_transaction_id, transaction_id, product_id, store, environment, trial_started_at, cancelled_at, attempts")
    .eq("status", "pending").lte("trial_started_at", due)
    .or(`retry_at.is.null,retry_at.lte."${now}"`)
    .order("trial_started_at").limit(50);
  if (error) throw error;

  const results: Record<string, string> = {};
  for (const row of (data ?? []) as Row[]) {
    let verdict: Verdict;
    let retryAt: string | null = null;
    let transient = false;
    const attempts = (row.attempts ?? 0) + 1;
    try {
      verdict = await decide(row);
    } catch (e) {
      const detail = String(e).slice(0, 500);
      transient = e instanceof Transient;
      if (!transient) {
        verdict = { status: "error", detail };
      } else if (attempts >= MAX_ATTEMPTS) {
        verdict = { status: "error", detail: `gave up after ${attempts} attempts: ${detail}` };
      } else {
        verdict = { status: "pending", detail: `retry ${attempts}/${MAX_ATTEMPTS}: ${detail}` };
        const minutes = Math.min(2 ** attempts, MAX_BACKOFF_MINUTES);
        retryAt = new Date(Date.now() + minutes * 60_000).toISOString();
      }
    }
    const update: Record<string, unknown> = {
      status: verdict.status,
      detail: verdict.detail,
      checked_at: new Date().toISOString(),
      retry_at: retryAt,
    };
    if (transient) update.attempts = attempts;
    if (verdict.meta_response !== undefined) update.meta_response = verdict.meta_response;
    if (verdict.status === "sent") update.sent_at = new Date().toISOString();
    await db.from("meta_trial_relay").update(update).eq("id", row.id);
    results[row.id] = verdict.status;
  }
  return { checked: Object.keys(results).length, results };
}

async function decide(row: Row): Promise<Verdict> {
  const app = APPS[row.app];
  if (!app) return { status: "error", detail: `unknown app ${row.app}` };
  // A webhook cancel is not final: renewal can be turned back on inside the
  // hold (RevenueCat sends UNCANCELLATION), so RevenueCat's current state
  // decides below. The cancel only settles the row when that cannot be read.
  if (!app.rcKey) {
    return row.cancelled_at
      ? { status: "cancelled", detail: `webhook cancel at ${row.cancelled_at}` }
      : { status: "pending", detail: `${row.app}: RevenueCat secret key missing` };
  }

  const ageHours = (Date.now() - Date.parse(row.trial_started_at)) / 3_600_000;
  const subscription = await findSubscription(app, row);
  if (!subscription) {
    return ageHours > LOOKUP_WAIT_HOURS
      ? { status: "error", detail: "subscription not found in RevenueCat" }
      : { status: "pending", detail: "subscription not visible yet" };
  }
  // Switching plan inside the trial keeps it on; turning renewal off does not.
  const stillOn = ["trialing", "active"].includes(subscription.status) &&
    ["will_renew", "will_change_product"].includes(subscription.auto_renewal_status);
  if (!stillOn) {
    return {
      status: "cancelled",
      detail: `recheck: status=${subscription.status} renewal=${subscription.auto_renewal_status}`,
    };
  }

  const attributes = await customerAttributes(app, row.app_user_id);
  const consent = attributes["$attConsentStatus"] ?? "";
  const authorized = consent === "authorized";
  if (!authorized && !SEND_WITHOUT_ATT) {
    if (consent === "denied" || consent === "restricted") {
      return { status: "no_consent", detail: `ATT ${consent}` };
    }
    return ageHours > CONSENT_WAIT_HOURS
      ? { status: "no_consent", detail: `ATT never answered (${consent || "missing"})` }
      : { status: "pending", detail: `waiting on ATT (${consent || "missing"})` };
  }

  const event = await metaEvent(app, row, attributes, authorized);
  const live = row.store === "APP_STORE" && row.environment === "PRODUCTION";
  if (!app.datasetID || !app.capiToken) {
    return { status: "would_send", detail: "Meta not configured", meta_response: { event } };
  }
  if (!live && !app.testEventCode) {
    return { status: "would_send", detail: `${row.store}/${row.environment}, no test code`, meta_response: { event } };
  }

  const payload: Record<string, unknown> = { data: [event], access_token: app.capiToken };
  if (!live) payload.test_event_code = app.testEventCode;
  // A retry resends the same event_id, which Meta deduplicates, so a 5xx
  // that Meta did in fact record cannot count twice.
  const response = await call("Meta", `https://graph.facebook.com/${META_GRAPH_VERSION}/${app.datasetID}/events`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(payload),
  });
  const answer = await response.json().catch(() => ({}));
  return response.ok && (answer?.events_received ?? 0) > 0
    ? { status: "sent", detail: `events_received=${answer.events_received}`, meta_response: answer }
    : { status: "error", detail: `Meta HTTP ${response.status}`, meta_response: answer };
}

/** fetch that throws Transient on a network error, 429 or 5xx. */
async function call(name: string, url: string, init: RequestInit) {
  let response: Response;
  try {
    response = await fetch(url, init);
  } catch (e) {
    throw new Transient(`${name} network: ${String(e).slice(0, 200)}`);
  }
  if (response.status === 429 || response.status >= 500) {
    const body = (await response.text().catch(() => "")).slice(0, 200);
    throw new Transient(`${name} HTTP ${response.status} ${body}`.trim());
  }
  return response;
}

async function rc(app: App, path: string) {
  const response = await call("RevenueCat", `https://api.revenuecat.com/v2/projects/${app.rcProject}${path}`, {
    headers: { authorization: `Bearer ${app.rcKey}` },
  });
  if (!response.ok) throw new Error(`RevenueCat ${path} HTTP ${response.status}`);
  return await response.json();
}

async function findSubscription(app: App, row: Row) {
  const customer = encodeURIComponent(row.app_user_id);
  const { items = [] } = await rc(app, `/customers/${customer}/subscriptions?limit=50`);
  // v2 names the subscription by its latest store transaction, which 15
  // minutes in is still the trial's own. Failing that, the one that started
  // with the trial.
  const ids = [row.transaction_id, row.original_transaction_id].filter(Boolean);
  const started = Date.parse(row.trial_started_at);
  return items.find((s: any) => ids.includes(s.store_subscription_identifier)) ??
    items.find((s: any) => Math.abs(Number(s.starts_at) - started) < 10 * 60_000);
}

async function customerAttributes(app: App, appUserID: string): Promise<Record<string, string>> {
  const { items = [] } = await rc(app, `/customers/${encodeURIComponent(appUserID)}/attributes?limit=100`);
  return Object.fromEntries(items.map((a: any) => [a.name, String(a.value ?? "")]));
}

/** One Conversions API app event, shaped like RevenueCat's own. */
async function metaEvent(app: App, row: Row, a: Record<string, string>, authorized: boolean) {
  const idfa = a["$idfa"] ?? "";
  const validIDFA = authorized && idfa && !/^[0-]+$/.test(idfa);
  const userData: Record<string, unknown> = { external_id: [await sha256(row.app_user_id)] };
  if (a["$fbAnonId"]) userData.anon_id = a["$fbAnonId"];
  if (validIDFA) userData.madid = idfa;
  if (a["$ip"]) userData.client_ip_address = a["$ip"];

  const appData: Record<string, unknown> = {
    advertiser_tracking_enabled: authorized ? 1 : 0,
    application_tracking_enabled: 1,
    extinfo: extinfo(app, a["meta_extinfo"]),
  };
  if (a["$idfv"]) appData.vendor_id = a["$idfv"];

  return {
    event_name: "StartTrial",
    event_time: Math.floor(Date.parse(row.trial_started_at) / 1000),
    event_id: `rc_trial_${row.original_transaction_id ?? row.id}`,
    action_source: "app",
    user_data: userData,
    app_data: appData,
    custom_data: {
      currency: "USD",
      value: 0,
      content_type: "product",
      content_ids: row.product_id ? [row.product_id] : [],
    },
  };
}

/** The 16-slot array the app wrote (MetaAds.extinfo), or a bare iOS one. */
function extinfo(app: App, raw: string | undefined): string[] {
  try {
    const parsed = JSON.parse(raw ?? "");
    if (Array.isArray(parsed) && parsed.length === 16) return parsed.map(String);
  } catch { /* fall through */ }
  return ["i2", app.bundleID, "", "", "", "", "", "", "", "0", "0", "0", "0", "0", "0", ""];
}

async function sha256(value: string) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function same(given: string | null, expected: string) {
  if (!given || given.length !== expected.length) return false;
  let diff = 0;
  for (let i = 0; i < given.length; i++) diff |= given.charCodeAt(i) ^ expected.charCodeAt(i);
  return diff === 0;
}

const text = (status: number, body: string) => new Response(body, { status });
const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
