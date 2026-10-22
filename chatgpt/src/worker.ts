// Mahj for ChatGPT: a remote MCP server (streamable HTTP, stateless) that
// teaches American mah jongg with the app's free content. Runs on Cloudflare
// Workers; one fresh McpServer per request.
import { registerAppResource, registerAppTool, RESOURCE_MIME_TYPE } from "@modelcontextprotocol/ext-apps/server";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import { CfWorkerJsonSchemaValidator } from "@modelcontextprotocol/sdk/validation/cfworker";
import { z } from "zod";

import widgetHtml from "../widget/index.html";
import { CHARLESTON_PASSES } from "./rack.ts";
import { LEARN_TOPICS, lookUpTerm, PRACTICE_TOPICS } from "./sessions.ts";
import { checkResult, lessonResult, practiceResult, rackResult, termResult } from "./tools.ts";

type Env = { OPENAI_DOMAIN_CHALLENGE?: string; WIDGET_DOMAIN?: string };

// Treat the URI as a cache key: bump the version on any breaking widget change.
const WIDGET_URI = "ui://mahj/trainer-v3.html";

const INSTRUCTIONS = [
  "Mahj Trainer teaches American mah jongg, the game played with the yearly NMJL card.",
  "Never quote or reconstruct hands from the NMJL card: it is copyrighted and changes every year.",
  "Talk in card sections (2468, 13579, 369, Consecutive Run, Like Numbers, Winds & Dragons, Singles & Pairs, Quints, Year) and tell players to check exact lines on their own card.",
  "When someone asks what an American mah jongg term means, call define_mahjong_term and build the answer on its definition when it has one.",
  "When a tool shows the interactive card, the player reads it there, so don't restate its cards, tiles or answers in chat.",
  "Not for Chinese, Hong Kong or Japanese riichi mahjong, or mahjong solitaire.",
].join(" ");

const READ_ONLY = { readOnlyHint: true, destructiveHint: false, openWorldHint: false } as const;

const tileList = z
  .array(z.string().max(120))
  .min(1)
  .max(40)
  .describe('The player\'s tiles, ideally one per entry. Codes: 1C-9C craks, 1B-9B bams, 1D-9D dots, N E W S winds, RD GD SO (soap) dragons, F flower, J joker. Words like "5 dot", "five crak", "soap", "north wind" or "3 jokers" also work, as does the whole rack in one entry.');

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
        // The widget is one self-contained file that makes no network calls
        // and loads nothing, so its CSP allows no outside domains. Its domain
        // defaults to this server's own origin, which is unique to the plugin.
        ui: { prefersBorder: true, domain: env.WIDGET_DOMAIN || origin, csp: { connectDomains: [], resourceDomains: [], frameDomains: [] } },
        "openai/widgetDescription": "An interactive American mah jongg card: a short lesson, a practice quiz, or a read of the player's rack.",
        "openai/widgetCSP": { connect_domains: [], resource_domains: [] },
      },
    }],
  }));

  registerAppTool(server, "show_mahjong_lesson", {
    title: "Show a mah jongg lesson",
    description:
      "Use this when someone wants to learn or review American mah jongg (NMJL-card style): how the game works, the tiles, the sections of the card, the Charleston, or keep-or-throw judgment. Shows a short card deck with tile pictures, and cards that ask a question let the player answer first. The deck is the lesson, so don't write a second guide in chat. Do not use to list or reproduce the hands on the NMJL card, or for other mahjong variants.",
    inputSchema: {
      topic: z.enum(LEARN_TOPICS).default("basics").describe("basics = how the game works; tiles; sections = the card's hand families; charleston = the tile pass; strategy = keep-or-throw calls"),
    },
    outputSchema: {
      title: z.string(),
      cards: z.array(z.object({ title: z.string(), context: z.string().optional(), subtitle: z.string().optional(), answer: z.string().optional(), body: z.string(), tip: z.string().optional() })),
    },
    annotations: READ_ONLY,
    _meta: { ui: { resourceUri: WIDGET_URI }, "openai/toolInvocation/invoking": "Laying out the tiles", "openai/toolInvocation/invoked": "Lesson ready" },
  }, async ({ topic }) => lessonResult(topic));

  registerAppTool(server, "start_mahjong_practice", {
    title: "Practice American mah jongg",
    description:
      "Use this when someone wants to practice or be quizzed on American mah jongg: naming tiles, reading which card section a rack is chasing, choosing a Charleston pass, keep-or-throw calls, or table rules. Shows an interactive quiz that checks each answer and explains it. The result holds the questions but not the answers.",
    inputSchema: {
      topic: z.enum(PRACTICE_TOPICS).default("mixed").describe("tiles; reading = which section a rack is chasing; charleston = pick 3 tiles to pass; strategy = keep or throw; table = calling, exposures and scoring rules; mixed"),
      count: z.number().int().min(3).max(12).default(6).describe("Up to this many questions. A topic with fewer questions returns all it has."),
    },
    outputSchema: {
      title: z.string(),
      available: z.number().int(),
      questions: z.array(z.object({ id: z.string(), prompt: z.string(), tiles: z.array(z.string()), choices: z.array(z.string()).optional(), pick: z.number().int().optional() })),
    },
    annotations: READ_ONLY,
    _meta: { ui: { resourceUri: WIDGET_URI }, "openai/toolInvocation/invoking": "Dealing practice questions", "openai/toolInvocation/invoked": "Practice ready" },
  }, async ({ topic, count }) => practiceResult(topic, count));

  registerAppTool(server, "read_mahjong_rack", {
    title: "Read a mah jongg rack",
    description:
      "Use this when an American mah jongg player shares the tiles on their rack and asks which section of the card they lean toward or what to pass in the Charleston. Reads the tiles against the stable card sections, shortlists the strongest, and picks a three-tile pass with a reason for each tile. Shows the read in an interactive rack card. Needs at least five tiles; the full 13-tile rack works best. If any entry can't be read it asks for a correction instead of guessing. It never names specific card hands. Do not use for other mahjong variants.",
    inputSchema: {
      tiles: tileList,
      pass: z.enum(CHARLESTON_PASSES).optional().describe("Which Charleston pass the player is about to make, if they said. first-left and second-right allow a blind pass; courtesy is 0 to 3 tiles across."),
    },
    outputSchema: {
      tiles: z.array(z.string()),
      read: z.string().nullable(),
      shortlist: z.array(z.string()),
      summary: z.string(),
      passes: z.array(z.string()),
      reasons: z.array(z.string()),
      spare: z.array(z.string()),
      sections: z.array(z.object({ name: z.string(), verdict: z.string(), note: z.string() })),
      unreadable: z.array(z.string()),
    },
    annotations: READ_ONLY,
    _meta: { ui: { resourceUri: WIDGET_URI }, "openai/toolInvocation/invoking": "Reading your rack", "openai/toolInvocation/invoked": "Rack read" },
  }, async ({ tiles, pass }) => rackResult(tiles, pass));

  server.registerTool("check_mahjong_answer", {
    title: "Check a mah jongg practice answer",
    description:
      "Use this to check the player's typed answer to a question from start_mahjong_practice when the interactive quiz is not visible. Pass the question's id and the player's answer: the choice text, or the three tiles they would pass. Returns whether it is right, the right answer and the explanation.",
    inputSchema: {
      id: z.string().min(1).max(40).describe("The question's id from start_mahjong_practice"),
      answer: z.string().min(1).max(120).describe("The player's answer: the choice text, or three tiles like 1C 9B N"),
    },
    outputSchema: { id: z.string(), found: z.boolean(), correct: z.boolean(), answer: z.string(), explanation: z.string() },
    annotations: READ_ONLY,
  }, async ({ id, answer }) => checkResult(id, answer));

  server.registerTool("define_mahjong_term", {
    title: "Define a mah jongg term",
    description:
      "Use this when someone asks what an American mah jongg term means, such as pung, kong, quint, soap, exposure, joker swap, hot tile, dead hand, the blind pass or the courtesy pass. Returns the plain-language definition from the Mahj glossary of 36 terms, written to NMJL rules, or says the term is not in it. It covers terms, not full rules such as scoring. Do not use for other mahjong variants.",
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
