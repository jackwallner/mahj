// End-to-end check against a running server: `npm run dev`, then `npm test`.
// MCP_URL points it at a deployed server instead.
import assert from "node:assert/strict";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";

const url = new URL(process.env.MCP_URL ?? "http://localhost:8787/mcp");

// Claude's endpoint sits beside ChatGPT's on the same origin.
const claudeUrl = new URL("/claude/mcp", url);

async function connect(at: URL = url) {
  const client = new Client({ name: "mahj-test", version: "1.0.0" });
  await client.connect(new StreamableHTTPClientTransport(at));
  return client;
}

// deno-lint-ignore no-explicit-any
type Result = { structuredContent?: any; content: { type: string; text?: string }[]; _meta?: any; isError?: boolean };

async function call(name: string, args: Record<string, unknown>): Promise<Result> {
  const client = await connect();
  try {
    return (await client.callTool({ name, arguments: args })) as Result;
  } finally {
    await client.close();
  }
}

test("lists five read-only tools, three with UI links", async () => {
  const client = await connect();
  const { tools } = await client.listTools();
  await client.close();
  assert.deepEqual(tools.map((t) => t.name).sort(), ["check_mahjong_answer", "define_mahjong_term", "read_mahjong_rack", "show_mahjong_lesson", "start_mahjong_practice"]);
  for (const tool of tools) {
    assert.deepEqual(tool.annotations, { readOnlyHint: true, destructiveHint: false, openWorldHint: false }, tool.name);
    assert.ok(tool.outputSchema, `${tool.name} outputSchema`);
    assert.ok(/^Use this (when|to)/.test(tool.description ?? ""), tool.name);
    assert.doesNotMatch(tool.description ?? "", /sentence/, `${tool.name} tells the model how long to reply`);
  }
  const ui = tools.filter((t) => (t._meta as { ui?: { resourceUri?: string } })?.ui?.resourceUri);
  assert.equal(ui.length, 3);
});

test("serves the widget as an MCP App resource with a closed CSP", async () => {
  const client = await connect();
  const { contents } = await client.readResource({ uri: "ui://mahj/trainer-v3.html" });
  await client.close();
  assert.equal(contents[0].mimeType, "text/html;profile=mcp-app");
  assert.match(String((contents[0] as { text: string }).text), /<script>/);
  // deno-lint-ignore no-explicit-any
  const ui = (contents[0]._meta as any).ui;
  assert.deepEqual(ui.csp, { connectDomains: [], resourceDomains: [], frameDomains: [] });
});

test("lesson returns cards and a widget deck", async () => {
  const r = await call("show_mahjong_lesson", { topic: "basics" });
  assert.equal(r.structuredContent.cards.length, 6);
  assert.equal(r._meta.widget.view, "learn");
});

test("practice hands the widget answers and the model only the questions", async () => {
  const r = await call("start_mahjong_practice", { topic: "charleston", count: 4 });
  assert.equal(r.structuredContent.questions.length, 4);
  assert.equal(r._meta.widget.session.questions[0].kind, "pass");
  assert.doesNotMatch(JSON.stringify(r.structuredContent) + (r.content[0].text ?? ""), /answer"|explanation|recommended/);
  const q = r._meta.widget.session.questions[0];
  const check = await call("check_mahjong_answer", { id: q.id, answer: q.pass.join(" ") });
  assert.equal(check.structuredContent.correct, true);
});

test("a short topic says how many questions it has", async () => {
  const r = await call("start_mahjong_practice", { topic: "reading", count: 12 });
  assert.equal(r.structuredContent.questions.length, 9);
  assert.match(r.content[0].text ?? "", /has 9 questions/);
});

test("practice defaults to a mixed set", async () => {
  const r = await call("start_mahjong_practice", {});
  assert.equal(r.structuredContent.questions.length, 6);
});

test("reads an evens rack and flags the odd tiles and the wind", async () => {
  const r = await call("read_mahjong_rack", { tiles: ["2C", "2C", "4C", "4C", "6B", "6B", "8B", "8D", "F", "J", "1C", "9B", "N"] });
  assert.equal(r.structuredContent.read, "2468 (Evens)");
  assert.deepEqual([...r.structuredContent.passes].sort(), ["1C", "9B", "N"]);
  assert.equal(r.structuredContent.reasons.length, 3);
});

test("reads a whole rack sent as one string, with the pass named", async () => {
  const r = await call("read_mahjong_rack", { tiles: ["2C 2C 4C 4C 6B 6B 8B 8D F J 1C 9B N"], pass: "first-left" });
  assert.equal(r.structuredContent.tiles.length, 13);
  assert.match(r.content[0].text ?? "", /first pass left/);
});

test("refuses to read around tiles it can't read", async () => {
  const r = await call("read_mahjong_rack", { tiles: ["constructor", "__proto__", "4C", "6B", "8B"] });
  assert.ok(!r.isError);
  assert.equal(r.structuredContent.passes.length, 0);
  assert.match(r.content[0].text ?? "", /Could not read/);
});

test("reads tiles written as words", async () => {
  const r = await call("read_mahjong_rack", { tiles: ["north", "north", "north", "east", "east", "west", "south", "south", "red", "green", "soap", "flower", "joker"] });
  assert.equal(r.structuredContent.read, "Winds & Dragons");
});

test("rejects an impossible rack", async () => {
  const r = await call("read_mahjong_rack", { tiles: ["5D", "5D", "5D", "5D", "5D", "1C", "2C", "3C"] });
  assert.match(r.structuredContent.summary, /only four of each tile/);
  assert.ok(r._meta.widget.error);
});

test("defines a term by alias and misses cleanly", async () => {
  assert.equal((await call("define_mahjong_term", { term: "kongs" })).structuredContent.term, "Kong");
  assert.equal((await call("define_mahjong_term", { term: "white dragon" })).structuredContent.term, "Soap");
  assert.equal((await call("define_mahjong_term", { term: "riichi" })).structuredContent.found, false);
  assert.equal((await call("define_mahjong_term", { term: "dead wall" })).structuredContent.found, false);
});

test("never echoes the NMJL card", async () => {
  const r = await call("read_mahjong_rack", { tiles: ["2C", "2C", "SO", "SO", "2B", "2B", "6B", "6B", "F", "F", "F", "J", "4D"] });
  assert.match(r.content[0].text ?? "", /check the exact lines on their own card/);
});

test("Claude's endpoint links its own widget, themed by the host", async () => {
  const client = await connect(claudeUrl);
  const { tools } = await client.listTools();
  for (const tool of tools) {
    assert.ok(tool.title, `${tool.name} title`);
    assert.equal(tool.annotations?.title, tool.title, `${tool.name} annotations.title`);
    assert.doesNotMatch(tool.description ?? "", /\bdon't (write|restate|repeat)\b/, `${tool.name} steers the model's reply`);
    assert.equal(tool.annotations?.readOnlyHint, true, tool.name);
    assert.ok(!Object.keys(tool._meta ?? {}).some((k) => k.startsWith("openai/")), `${tool.name} carries ChatGPT keys`);
  }
  const uris = new Set(tools.map((t) => (t._meta as { ui?: { resourceUri?: string } })?.ui?.resourceUri).filter(Boolean));
  assert.deepEqual([...uris], ["ui://mahj/claude-v1.html"]);
  const { contents } = await client.readResource({ uri: "ui://mahj/claude-v1.html" });
  await client.close();
  const text = String((contents[0] as { text: string }).text);
  assert.match(text, /<html lang="en" data-host="claude">/);
  assert.match(text, /<meta name="color-scheme" content="light dark">/);
  // deno-lint-ignore no-explicit-any
  const meta = contents[0]._meta as any;
  assert.equal(meta.ui.domain, undefined, "Claude derives the sandbox origin itself");
  assert.equal(meta.ui.prefersBorder, false);
  assert.deepEqual(meta.ui.csp, { connectDomains: [], resourceDomains: ["https://assets.claude.ai"] });
  assert.ok(!Object.keys(meta).some((k) => k.startsWith("openai/")));
});

test("ChatGPT's widget stays unthemed", async () => {
  const client = await connect();
  const { contents } = await client.readResource({ uri: "ui://mahj/trainer-v3.html" });
  await client.close();
  assert.doesNotMatch(String((contents[0] as { text: string }).text), /<html[^>]*data-host="claude"/);
});

test("serves the app icon as the favicon", async () => {
  const r = await fetch(new URL("/favicon.ico", url));
  assert.equal(r.status, 200);
  assert.equal(r.headers.get("content-type"), "image/png");
  assert.ok((await r.arrayBuffer()).byteLength > 1000);
});

test("Claude's endpoint describes results without directing the model", async () => {
  const client = await connect(claudeUrl);
  const steer = /\b(don't|do not|ask the|tell the|you should|always|never say)\b/i;
  const texts = [client.getInstructions() ?? ""];
  for (const [name, args] of [
    ["show_mahjong_lesson", { topic: "basics" }],
    ["start_mahjong_practice", { topic: "charleston", count: 3 }],
    ["read_mahjong_rack", { tiles: ["2C", "2C", "4C", "4C", "6B", "6B", "8B", "8D", "F", "J", "1C", "9B", "N"] }],
    ["check_mahjong_answer", { id: "cs-evens", answer: "x" }],
    ["check_mahjong_answer", { id: "more-table-exposure-read", answer: "zzz" }],
  ] as const) {
    const r = (await client.callTool({ name, arguments: args })) as Result;
    texts.push(r.content.map((c) => c.text ?? "").join("\n"));
  }
  const { contents } = await client.readResource({ uri: "ui://mahj/claude-v1.html" });
  await client.close();
  for (const text of texts) assert.doesNotMatch(text, steer);
  assert.match(String((contents[0] as { text: string }).text), /aria-busy="true"/);
  assert.equal(client.getServerVersion()?.title, "Mahj Trainer");
});
