// Copies the FREE part of the app's exported content into the plugin.
// Source of truth stays the Swift content, exported by
// scripts/sync-android-content.sh. Mahj+ drills and the Master Tables are
// left out on purpose: the plugin gives away exactly what the app gives away.
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const source = join(here, "../../android/app/src/main/resources/mahj-content.json");
const target = join(here, "../src/content.json");

const all = JSON.parse(readFileSync(source, "utf8"));

const drills = all.rooms
  .filter((room) => room.isFree)
  .flatMap((room) =>
    room.drills
      .filter((drill) => !drill.isPlus)
      .map((drill) => ({ ...drill, room: room.id, roomName: room.name })),
  );

const content = {
  categories: all.categories,
  glossary: all.glossary,
  primer: all.primer,
  referenceSections: all.referenceSections,
  drills,
};

writeFileSync(target, JSON.stringify(content));
console.log(`content.json: ${drills.length} free drills, ${drills.reduce((n, d) => n + d.items.length, 0)} items`);
