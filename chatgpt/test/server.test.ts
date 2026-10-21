// End-to-end check against a running server: `npm run dev`, then `npm test`.
// MCP_URL points it at a deployed server instead.
import assert from "node:assert/strict";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";

const url = new URL(process.env.MCP_URL ?? "http://localhost:8787/mcp");

async function connect() {
  const client = new Client({ name: "mahj-test", version: "1.0.0" });
  await client.connect(new StreamableHTTPClientTransport(url));
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

test("lists four read-only tools with UI links", async () => {
  const client = await connect();
  const { tools } = await client.listTools();
  await client.close();
  assert.deepEqual(tools.map((t) => t.name).sort(), ["define_mahjong_term", "read_mahjong_rack", "show_mahjong_lesson", "start_mahjong_practice"]);
  for (const tool of tools) {
    assert.deepEqual(tool.annotations, { readOnlyHint: true, destructiveHint: false, openWorldHint: false }, tool.name);
    assert.ok(tool.outputSchema, `${tool.name} outputSchema`);
    assert.ok(tool.description?.startsWith("Use this when"), tool.name);
  }
  const ui = tools.filter((t) => (t._meta as { ui?: { resourceUri?: string } })?.ui?.resourceUri);
  assert.equal(ui.length, 3);
});

test("serves the widget as an MCP App resource", async () => {
  const client = await connect();
  const { contents } = await client.readResource({ uri: "ui://mahj/trainer-v1.html" });
  await client.close();
  assert.equal(contents[0].mimeType, "text/html;profile=mcp-app");
  assert.match(String((contents[0] as { text: string }).text), /<script>/);
});

test("lesson returns cards and a widget deck", async () => {
  const r = await call("show_mahjong_lesson", { topic: "basics" });
  assert.equal(r.structuredContent.cards.length, 6);
  assert.equal(r._meta.widget.view, "learn");
});

test("practice hands the widget answers and the model the questions", async () => {
  const r = await call("start_mahjong_practice", { topic: "charleston", count: 4 });
  assert.equal(r.structuredContent.questions.length, 4);
  assert.equal(r._meta.widget.session.questions[0].kind, "pass");
  assert.match(r.content[0].text ?? "", /Do not list the answers/);
});

test("practice defaults to a mixed set", async () => {
  const r = await call("start_mahjong_practice", {});
  assert.equal(r.structuredContent.questions.length, 6);
});

test("reads an evens rack and flags the odd tiles and the wind", async () => {
  const r = await call("read_mahjong_rack", { tiles: ["2C", "2C", "4C", "4C", "6B", "6B", "8B", "8D", "F", "J", "1C", "9B", "N"] });
  assert.equal(r.structuredContent.read, "2468 (Evens)");
  assert.deepEqual([...r.structuredContent.passes].sort(), ["1C", "9B", "N"]);
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
  assert.equal((await call("define_mahjong_term", { term: "riichi" })).structuredContent.found, false);
});

test("never echoes the NMJL card", async () => {
  const r = await call("read_mahjong_rack", { tiles: ["2C", "2C", "SO", "SO", "2B", "2B", "6B", "6B", "F", "F", "F", "J", "4D"] });
  assert.match(r.content[0].text ?? "", /check the exact lines on their own card/);
});
