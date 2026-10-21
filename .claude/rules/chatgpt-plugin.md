---
paths:
  - "chatgpt/**"
---

# ChatGPT plugin (`chatgpt/`)

A free, non-monetized OpenAI plugin (ChatGPT and Codex directory) that teaches American mah jongg with the app's free content. Remote MCP server on Cloudflare Workers, stateless streamable HTTP, plus one MCP Apps widget.

- Live: `https://mahj.2jtest0979.workers.dev/mcp` (Cloudflare account 2jtest0979, free tier). The plugin's MCP origin is locked once submitted: changing host means a new plugin.
- Content: `npm run content` copies only the free subset from `android/app/src/main/resources/mahj-content.json` (free rooms' non-Plus drills, primer, glossary, reference). Never ship Plus drills here.
- Tools: `show_mahjong_lesson`, `start_mahjong_practice`, `read_mahjong_rack` (widget) and `define_mahjong_term` (text). All read-only with output schemas. `_meta.widget` carries the widget payload and is hidden from the model.
- `src/rack.ts` ports `RackGenerator` but reads leans from support counts (5-wide runs, Year needs soap or a 2). It talks in sections only; never add card hands.
- Widget: `widget/index.html`, one file, ChatGPT-neutral surfaces, jade only on primary buttons. Bump `WIDGET_URI` on breaking changes (hosts cache it).
- No upsell: the only app mention is the footer link to the landing page. OpenAI rejects digital-goods selling or checkout links.
- GET `/mcp` returns 405: a stateless server has no stream to hold open, and an open GET hangs clients.
- Commands: `npm run dev`, `npm test` (or `MCP_URL=https://.../mcp npm test` against live), `npm run check`, `npm run deploy`, `npm run package -- <https url>/mcp` builds `dist/mahj-plugin-<version>.zip`. Each upload needs a new `version` in `plugin/plugin.json`.
- Domain verification: set `OPENAI_DOMAIN_CHALLENGE` with `npx wrangler secret put` (or the `[vars]` entry) and redeploy; served at `/.well-known/openai-apps-challenge`.
