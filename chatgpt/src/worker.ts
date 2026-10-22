// Mahj for ChatGPT: a remote MCP server (streamable HTTP, stateless) that
// teaches American mah jongg with the app's free content. Runs on Cloudflare
// Workers; one fresh McpServer per request.
import { registerAppResource, registerAppTool, RESOURCE_MIME_TYPE } from "@modelcontextprotocol/ext-apps/server";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import { CfWorkerJsonSchemaValidator } from "@modelcontextprotocol/sdk/validation/cfworker";
import { z } from "zod";

import widgetHtml from "../widget/index.html";
import { lookUpTerm } from "./sessions.ts";
import { lessonResult, practiceResult, rackResult, termResult } from "./tools.ts";
import { LEARN_TOPICS, PRACTICE_TOPICS } from "./sessions.ts";

type Env = { OPENAI_DOMAIN_CHALLENGE?: string; WIDGET_DOMAIN?: string };

// Treat the URI as a cache key: bump the version on any breaking widget change.
const WIDGET_URI = "ui://mahj/trainer-v2.html";

const INSTRUCTIONS = [
  "Mahj Trainer teaches American mah jongg, the game played with the yearly NMJL card.",
  "Never quote or reconstruct hands from the NMJL card: it is copyrighted and changes every year.",
  "Talk in card sections (2468, 13579, 369, Consecutive Run, Like Numbers, Winds & Dragons, Singles & Pairs, Quints, Year) and tell players to check exact lines on their own card.",
  "When someone asks what an American mah jongg term or rule means, call define_mahjong_term and build the answer on its definition.",
  "When a tool shows the interactive card, the player reads it there: keep your reply to a sentence or two and do not restate its cards, tiles or answers.",
  "Not for Chinese, Hong Kong or Japanese riichi mahjong, or mahjong solitaire.",
].join(" ");

const READ_ONLY = { readOnlyHint: true, destructiveHint: false, openWorldHint: false } as const;

const tileList = z
  .array(z.string())
  .min(1)
  .max(14)
  .describe('The player\'s tiles, one per entry. Codes: 1C-9C craks, 1B-9B bams, 1D-9D dots, N E W S winds, RD GD SO (soap) dragons, F flower, J joker. One tile per entry; words like "5 dot", "five crak", "soap" or "north" also work.');

function buildServer(env: Env, origin: string): McpServer {
  const server = new McpServer(
    { name: "mahj", version: "1.0.0" },
    { instructions: INSTRUCTIONS, jsonSchemaValidator: new CfWorkerJsonSchemaValidator() },
  );

  registerAppResource(server, "Mahj Trainer", WIDGET_URI, {}, async () => ({
    contents: [{
      uri: WIDGET_URI,
      mimeType: RESOURCE_MIME_TYPE,
      text: widgetHtml,
      _meta: {
        // The widget makes no network calls, so it declares no CSP. Its domain
        // defaults to this server's own origin, which is unique to the plugin.
        ui: { prefersBorder: true, domain: env.WIDGET_DOMAIN || origin },
        "openai/widgetDescription": "An interactive American mah jongg card: a short lesson, a practice quiz, or a read of the player's rack.",
      },
    }],
  }));

  registerAppTool(server, "show_mahjong_lesson", {
    title: "Show a mah jongg lesson",
    description:
      "Use this when someone wants to learn or review American mah jongg (NMJL-card style): how the game works, the tiles, the sections of the card, the Charleston, or keep-or-throw judgment. Shows a short illustrated card deck that is the answer: after it appears, reply in at most two sentences and do not write your own guide. Do not use to list or reproduce the hands on the NMJL card, or for other mahjong variants.",
    inputSchema: {
      topic: z.enum(LEARN_TOPICS).default("basics").describe("basics = how the game works; tiles; sections = the card's hand families; charleston = the tile pass; strategy = keep-or-throw calls"),
    },
    outputSchema: {
      title: z.string(),
      cards: z.array(z.object({ title: z.string(), subtitle: z.string().optional(), answer: z.string().optional(), body: z.string(), tip: z.string().optional() })),
    },
    annotations: READ_ONLY,
    _meta: { ui: { resourceUri: WIDGET_URI }, "openai/toolInvocation/invoking": "Laying out the tiles", "openai/toolInvocation/invoked": "Lesson ready" },
  }, async ({ topic }) => lessonResult(topic));

  registerAppTool(server, "start_mahjong_practice", {
    title: "Practice American mah jongg",
    description:
      "Use this when someone wants to practice or be quizzed on American mah jongg: naming tiles, reading which card section a rack is chasing, choosing a Charleston pass, keep-or-throw calls, or table rules. Shows an interactive quiz that checks each answer and explains it: after it appears, reply in one sentence and never reveal or list the questions or answers.",
    inputSchema: {
      topic: z.enum(PRACTICE_TOPICS).default("mixed").describe("tiles; reading = which section a rack is chasing; charleston = pick 3 tiles to pass; strategy = keep or throw; table = calling, exposures and scoring rules; mixed"),
      count: z.number().int().min(3).max(12).default(6).describe("How many questions"),
    },
    outputSchema: {
      title: z.string(),
      questions: z.array(z.object({ prompt: z.string(), tiles: z.array(z.string()), choices: z.array(z.string()).optional(), answer: z.string(), explanation: z.string() })),
    },
    annotations: READ_ONLY,
    _meta: { ui: { resourceUri: WIDGET_URI }, "openai/toolInvocation/invoking": "Dealing practice questions", "openai/toolInvocation/invoked": "Practice ready" },
  }, async ({ topic, count }) => practiceResult(topic, count));

  registerAppTool(server, "read_mahjong_rack", {
    title: "Read a mah jongg rack",
    description:
      "Use this when an American mah jongg player shares the tiles on their rack and asks which section of the card they lean toward or what to pass in the Charleston. Reads the tiles against the stable card sections, shortlists the strongest, and picks up to three tiles to pass that fit none of them. Shows the read in an interactive rack card: after it appears, sum it up in two or three sentences. Needs at least five tiles; the full 13-tile rack works best. It never names specific card hands. Do not use for other mahjong variants.",
    inputSchema: { tiles: tileList },
    outputSchema: {
      tiles: z.array(z.string()),
      read: z.string().nullable(),
      shortlist: z.array(z.string()),
      summary: z.string(),
      passes: z.array(z.string()),
      spare: z.array(z.string()),
      sections: z.array(z.object({ name: z.string(), verdict: z.string(), note: z.string() })),
      unreadable: z.array(z.string()),
    },
    annotations: READ_ONLY,
    _meta: { ui: { resourceUri: WIDGET_URI }, "openai/toolInvocation/invoking": "Reading your rack", "openai/toolInvocation/invoked": "Rack read" },
  }, async ({ tiles }) => rackResult(tiles));

  server.registerTool("define_mahjong_term", {
    title: "Define a mah jongg term",
    description:
      "Use this whenever someone asks what an American mah jongg term or rule means, such as pung, kong, quint, soap, exposure, joker swap, hot tile, dead hand, the blind pass or the courtesy pass. Returns the Mahj glossary's plain-language definition, written to NMJL rules, so answer from it rather than from memory. Do not use for other mahjong variants.",
    inputSchema: { term: z.string().min(1).max(60).describe("The term to define") },
    outputSchema: { term: z.string(), definition: z.string(), found: z.boolean() },
    annotations: READ_ONLY,
  }, async ({ term }) => termResult(term, lookUpTerm(term)));

  return server;
}

const CORS: Record<string, string> = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-allow-headers": "content-type, mcp-session-id, mcp-protocol-version, accept, authorization",
  "access-control-expose-headers": "Mcp-Session-Id",
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const { pathname } = new URL(request.url);
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
    if (pathname === "/.well-known/openai-apps-challenge" && env.OPENAI_DOMAIN_CHALLENGE) {
      return new Response(env.OPENAI_DOMAIN_CHALLENGE, { headers: { "content-type": "text/plain" } });
    }
    if (pathname === "/") return new Response("Mahj for ChatGPT. MCP endpoint: /mcp\n", { headers: { "content-type": "text/plain" } });
    if (pathname !== "/mcp") return new Response("Not found", { status: 404 });
    // Stateless: no server-initiated stream to hold open, so refuse GET (and DELETE) per the spec.
    if (request.method !== "POST") return new Response("Method not allowed", { status: 405, headers: { ...CORS, allow: "POST, OPTIONS" } });

    const transport = new WebStandardStreamableHTTPServerTransport({ sessionIdGenerator: undefined, enableJsonResponse: true });
    await buildServer(env, new URL(request.url).origin).connect(transport);
    const response = await transport.handleRequest(request);
    const headers = new Headers(response.headers);
    for (const [key, value] of Object.entries(CORS)) headers.set(key, value);
    return new Response(response.body, { status: response.status, headers });
  },
};
