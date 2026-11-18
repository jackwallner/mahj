// Bundles the site pages' scripts with the real rack reader: site/page.ts into
// docs/chatgpt/page.js (the plugin's web page) and site/practice.ts into
// docs/practice.js (the free practice page). The reader only needs the section
// names, so the rest of content.json stays out of both bundles.
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

const PAGES = [
  ["site/page.ts", "../docs/chatgpt/page.js"],
  ["site/practice.ts", "../docs/practice.js"],
];

for (const [entry, outfile] of PAGES) {
  await build({
    entryPoints: [entry],
    outfile,
    bundle: true,
    minify: true,
    format: "iife",
    target: "es2020",
    charset: "utf8",
    plugins: [sectionsOnly],
    logLevel: "info",
  });
}
