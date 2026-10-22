---
paths:
  - "chatgpt/**"
---

# ChatGPT plugin (`chatgpt/`)

A free, non-monetized OpenAI plugin (ChatGPT and Codex directory) that teaches American mah jongg with the app's free content. Remote MCP server on Cloudflare Workers, stateless streamable HTTP, plus one MCP Apps widget.

- Live: `https://mahj.mahjtrainer.workers.dev/mcp` (workers.dev subdomain `mahjtrainer` on the 2jtest0979 Cloudflare account, free tier; rename it with DELETE then PUT on `/accounts/{id}/workers/subdomain`, since PUT alone refuses an existing one). The plugin's MCP origin is locked once submitted: changing host means a new plugin.
- Content: `npm run content` copies only the free subset from `android/app/src/main/resources/mahj-content.json` (free rooms' non-Plus drills, primer, glossary, reference). Never ship Plus drills here. Fix content errors in `Shared/Content/*.swift`, then `scripts/sync-android-content.sh` and `npm run content` (revert `mahj-parity.json` if only float noise changed). Plugin-only copy lives in `PRIMER_COPY` and `PASS_ALSO` in `src/sessions.ts`.
- Tools: `show_mahjong_lesson`, `start_mahjong_practice`, `read_mahjong_rack` (widget) and `define_mahjong_term` (text). All read-only with output schemas. `_meta.widget` carries the widget payload and is hidden from the model.
- `src/rack.ts` reads a dealt rack like a coach: support counts per section (runs need a same-suit 3-chain inside a 5-wide stretch; Year needs a soap and uses `cardYear()`, which flips each April), a shortlist, and up to 3 passes (never jokers or flowers; lone winds, then numbers, then dragons; pairs kept). `test/rack.test.ts` holds it to the app's 9 hand-match reads and 9 Charleston passes. Sections only; never add card hands.
- Widget: `widget/index.html`, one file, system fonts, no own border (`prefersBorder: true`), jade only on primary buttons, no network calls (so no CSP). `ui.domain` defaults to the server's own origin. Bump `WIDGET_URI` on breaking changes (hosts cache it).
- No upsell and no app link anywhere in tool output or the widget (the app sells Mahj+; OpenAI bans freemium cross-promotion). The footer is only the NMJL disclaimer. Don't call it free in listing copy; that goes in `commerce_description`.
- GET `/mcp` returns 405: a stateless server has no stream to hold open, and an open GET hangs clients.
- Commands: `npm run dev`, `npm test` (or `MCP_URL=https://.../mcp npm test` against live), `npm run check`, `npm run deploy`, `npm run package -- <https url>/mcp` builds `dist/mahj-plugin-<version>.zip`. Each upload needs a new `version` in `plugin/plugin.json`. `node --experimental-strip-types scripts/dump-review.mjs` prints everything the plugin can say, for coach and compliance reviews.
- Domain verification: `npx wrangler secret put OPENAI_DOMAIN_CHALLENGE` (never a `[vars]` entry, which overrides the secret) and redeploy; served at `/.well-known/openai-apps-challenge`.
- Testing in ChatGPT: developer mode, Add custom MCP server with the live `/mcp` URL (ZIP upload there cannot reach localhost). After every deploy press Refresh tools on the plugin's settings page; ChatGPT snapshots tool and resource metadata, and a stale snapshot shows "Resource not found". Its first `server/discover` probe gets a 400 and falls back to `initialize`; that is expected.
- Reply length is steered by the tool descriptions and `INSTRUCTIONS` in `src/worker.ts`; text inside tool output is mostly ignored for that. Widgets render after the model finishes streaming.
- Review demo: `docs/chatgpt/demo.mp4` (served at `https://jackwallner.github.io/mahj/chatgpt/demo.mp4`, set as `review.demo_recording_url`). Re-record when a tool's UI changes.
- Yearly: the shared content's year examples say 2026; update them with the app when the new card lands each April.
