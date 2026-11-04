// Bundles site/page.ts and the real rack reader into docs/chatgpt/page.js, the
// script of the plugin's web page. The reader only needs the section names, so
// the rest of content.json stays out of the bundle.
import { readFile } from "node:fs/promises";

import { build } from "esbuild";

const sectionsOnly = {
  name: "sections-only",
  setup(b) {
    b.onLoad({ filter: /content\.json$/ }, async (args) => {
      const { categories } = JSON.parse(await readFile(args.path, "utf8"));
      return { contents: JSON.stringify({ categories }), loader: "json" };
    });
  },
};

await build({
  entryPoints: ["site/page.ts"],
  outfile: "../docs/chatgpt/page.js",
  bundle: true,
  minify: true,
  format: "iife",
  target: "es2020",
  charset: "utf8",
  plugins: [sectionsOnly],
  logLevel: "info",
});
