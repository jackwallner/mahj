// Builds the OpenAI plugin ZIP: plugin/ plus an mcp.json pointing at the
// deployed server. Usage: npm run package -- https://mahj.<sub>.workers.dev/mcp
import { execFileSync } from "node:child_process";
import { cpSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const url = process.argv[2] ?? process.env.MCP_URL;
if (!url?.startsWith("https://") || !url.endsWith("/mcp")) {
  console.error("Pass the deployed HTTPS endpoint ending in /mcp.");
  process.exit(1);
}

const { version } = JSON.parse(readFileSync(join(root, "plugin/plugin.json"), "utf8"));
const stage = join(root, "dist/mahj");
const zip = join(root, `dist/mahj-plugin-${version}.zip`);
rmSync(join(root, "dist"), { recursive: true, force: true });
mkdirSync(stage, { recursive: true });
cpSync(join(root, "plugin"), stage, { recursive: true });

const mcp = {
  $schema: "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json",
  mcpServers: {
    mahj: { type: "streamable-http", url, extensions: { "com.openai": { auth: { type: "none" } } } },
  },
};
writeFileSync(join(stage, "mcp.json"), JSON.stringify(mcp, null, 2) + "\n");

execFileSync("zip", ["-rqX", zip, ".", "-x", ".*", "*/.*"], { cwd: stage });
console.log(zip);
