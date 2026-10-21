// Dry run of the sweep with every network call faked: no Supabase, RevenueCat
// or Meta traffic. Run: deno test -A supabase/functions/meta-trial-relay
import { assert, assertEquals } from "jsr:@std/assert@1.0.13";

Deno.env.set("SUPABASE_URL", "http://db.test");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "service");
Deno.env.set("META_RELAY_CRON_SECRET", "cron");
Deno.env.set("META_RELAY_RC_WEBHOOK_AUTH", "hook");
Deno.env.set("META_RELAY_RC_SECRET_KEY", "rc");
Deno.env.set("META_DATASET_ID", "123");
Deno.env.set("META_CAPI_TOKEN", "token");
Deno.env.set("META_BRIDGE_RC_SECRET_KEY", "rc-bridge");
Deno.env.set("META_BRIDGE_DATASET_ID", "456");
Deno.env.set("META_BRIDGE_CAPI_TOKEN", "token-bridge");
Deno.env.set("META_SKAT_RC_SECRET_KEY", "rc-skat");

type Reply = Response | Error;
let row: Record<string, unknown>;
let rcReply: () => Reply;
let renewal = "will_renew";
let metaReply: () => Reply;
let selectQuery = "";
let patches: Record<string, unknown>[] = [];
let metaCalls = 0;
let rcCalls: { path: string; auth: string }[] = [];
let metaBodies: { path: string; body: Record<string, any> }[] = [];

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
const hand = (reply: Reply) => reply instanceof Error ? Promise.reject(reply) : Promise.resolve(reply);

globalThis.fetch = (input: string | URL | Request, init?: RequestInit) => {
  const url = new URL(input instanceof Request ? input.url : String(input));
  const method = init?.method ?? (input instanceof Request ? input.method : "GET");
  if (url.host === "db.test") {
    if (method === "GET") {
      selectQuery = decodeURIComponent(url.search);
      return Promise.resolve(json(200, [row]));
    }
    patches.push(JSON.parse(String(init?.body)));
    return Promise.resolve(new Response(null, { status: 204 }));
  }
  if (url.host === "api.revenuecat.com") {
    rcCalls.push({ path: url.pathname, auth: new Headers(init?.headers).get("authorization") ?? "" });
    const reply = rcReply();
    if (reply instanceof Response && reply.ok && url.pathname.endsWith("/subscriptions")) {
      return Promise.resolve(json(200, {
        items: [{ store_subscription_identifier: "txn1", status: "trialing", auto_renewal_status: renewal }],
      }));
    }
    if (reply instanceof Response && reply.ok) {
      return Promise.resolve(json(200, { items: [{ name: "$attConsentStatus", value: "authorized" }] }));
    }
    return hand(reply);
  }
  if (url.host === "graph.facebook.com") {
    metaCalls++;
    metaBodies.push({ path: url.pathname, body: JSON.parse(String(init?.body)) });
    return hand(metaReply());
  }
  throw new Error(`unexpected fetch ${url}`);
};

let handler: (req: Request) => Promise<Response>;
// deno-lint-ignore no-explicit-any
(Deno as any).serve = (h: typeof handler) => { handler = h; return {}; };
await import("./index.ts");

async function sweep(attempts = 0, cancelledAt: string | null = null, app = "mahj") {
  row = {
    id: "evt1", app, app_user_id: "user1", original_transaction_id: "txn1", transaction_id: "txn1",
    product_id: "com.jackwallner.mahj.yearly", store: "APP_STORE", environment: "PRODUCTION",
    trial_started_at: new Date(Date.now() - 20 * 60_000).toISOString(), cancelled_at: cancelledAt, attempts,
  };
  patches = [];
  metaCalls = 0;
  rcCalls = [];
  metaBodies = [];
  const res = await handler(new Request("http://fn.test/?sweep", { method: "POST", headers: { "x-cron-secret": "cron" } }));
  assertEquals(res.status, 200);
  assertEquals(patches.length, 1);
  return patches[0];
}

const ok = () => json(200, {});
const sent = () => json(200, { events_received: 1 });

Deno.test("sweep only picks rows whose backoff is over", async () => {
  rcReply = ok;
  metaReply = sent;
  await sweep();
  assert(selectQuery.includes("status=eq.pending"));
  assert(selectQuery.includes("or=(retry_at.is.null,retry_at.lte."));
});

Deno.test("RevenueCat 503 stays pending with an attempt and a retry time", async () => {
  rcReply = () => json(503, { message: "unavailable" });
  metaReply = sent;
  const p = await sweep();
  assertEquals(p.status, "pending");
  assertEquals(p.attempts, 1);
  assert(String(p.detail).startsWith("retry 1/8: Error: RevenueCat HTTP 503"));
  const wait = Date.parse(String(p.retry_at)) - Date.now();
  assert(wait > 60_000 && wait <= 120_000, `retry in ${wait}ms`);
  assertEquals(metaCalls, 0);
});

Deno.test("RevenueCat 429 and network errors stay pending", async () => {
  metaReply = sent;
  rcReply = () => json(429, {});
  assertEquals((await sweep(2)).status, "pending");
  rcReply = () => new TypeError("connection reset");
  const p = await sweep(2);
  assertEquals(p.status, "pending");
  assertEquals(p.attempts, 3);
});

Deno.test("RevenueCat 400 is an error at once", async () => {
  rcReply = () => json(400, { message: "bad" });
  metaReply = sent;
  const p = await sweep();
  assertEquals(p.status, "error");
  assertEquals(p.retry_at, null);
  assertEquals(p.attempts, undefined);
});

Deno.test("Meta 503 stays pending, Meta 400 is an error", async () => {
  rcReply = ok;
  metaReply = () => json(503, {});
  const pending = await sweep();
  assertEquals(pending.status, "pending");
  assertEquals(pending.sent_at, undefined);
  assertEquals(metaCalls, 1);

  metaReply = () => json(400, { error: { message: "bad token" } });
  const error = await sweep();
  assertEquals(error.status, "error");
  assertEquals(error.detail, "Meta HTTP 400");
});

Deno.test("the eighth transient failure gives up", async () => {
  rcReply = () => json(502, {});
  const p = await sweep(7);
  assertEquals(p.status, "error");
  assertEquals(p.attempts, 8);
  assert(String(p.detail).startsWith("gave up after 8 attempts"));
  assertEquals(p.retry_at, null);
});

Deno.test("a retry that succeeds sends once and clears the backoff", async () => {
  rcReply = ok;
  metaReply = sent;
  const p = await sweep(3);
  assertEquals(p.status, "sent");
  assertEquals(p.retry_at, null);
  assertEquals(metaCalls, 1);
});

Deno.test("backoff doubles and caps at an hour", async () => {
  rcReply = () => json(500, {});
  const third = await sweep(2);
  const wait = Date.parse(String(third.retry_at)) - Date.now();
  assert(wait > 7 * 60_000 && wait <= 8 * 60_000, `retry in ${wait}ms`);
  const seventh = await sweep(6);
  const capped = Date.parse(String(seventh.retry_at)) - Date.now();
  assert(capped > 59 * 60_000 && capped <= 60 * 60_000, `retry in ${capped}ms`);
});

Deno.test("renewal turned back on inside the hold still sends", async () => {
  rcReply = ok;
  metaReply = sent;
  renewal = "will_renew";
  const p = await sweep(0, new Date(Date.now() - 10 * 60_000).toISOString());
  assertEquals(p.status, "sent");
  assertEquals(metaCalls, 1);
});

Deno.test("renewal still off is cancelled, with nothing sent", async () => {
  rcReply = ok;
  metaReply = sent;
  renewal = "will_not_renew";
  const p = await sweep(0, new Date(Date.now() - 10 * 60_000).toISOString());
  renewal = "will_renew";
  assertEquals(p.status, "cancelled");
  assertEquals(metaCalls, 0);
});

Deno.test("a card app's trial uses its own RevenueCat project and dataset", async () => {
  rcReply = ok;
  metaReply = sent;
  const p = await sweep(0, null, "bridge");
  assertEquals(p.status, "sent");
  assert(rcCalls.every((c) => c.path.startsWith("/v2/projects/proj71e29dd0/") && c.auth === "Bearer rc-bridge"));
  assertEquals(metaBodies[0].path.split("/").at(-2), "456");
  assertEquals(metaBodies[0].body.access_token, "token-bridge");
  assertEquals(metaBodies[0].body.data[0].app_data.extinfo[1], "com.jackwallner.bridge");
});

Deno.test("a card app without a dataset yet records would_send", async () => {
  rcReply = ok;
  metaReply = sent;
  const p = await sweep(0, null, "skat");
  assertEquals(p.status, "would_send");
  assert(rcCalls.every((c) => c.path.startsWith("/v2/projects/proje0bf13d7/")));
  assertEquals(metaCalls, 0);
});

Deno.test("the webhook tags each trial with its app and refuses unknown apps", async () => {
  const event = { id: "evt9", type: "INITIAL_PURCHASE", period_type: "TRIAL", app_user_id: "u9",
    transaction_id: "t9", purchased_at_ms: Date.now() };
  const post = (query: string) => handler(new Request(`http://fn.test/${query}`, {
    method: "POST", headers: { authorization: "hook" }, body: JSON.stringify({ event }),
  }));
  patches = [];
  assertEquals((await post("?app=cribbage")).status, 200);
  assertEquals(patches[0].app, "cribbage");
  patches = [];
  assertEquals((await post("")).status, 200);
  assertEquals(patches[0].app, "mahj");
  assertEquals((await post("?app=poker")).status, 400);
});
