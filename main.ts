// main.ts -- the entrypoint for this bring-the-humans-03 entry.
//
// Its only job is to hand the video's address to the grader: it copies
// VIDEO.json from the repository into the output directory. It reads the
// repository from MAKEFUN_BOT_DIR (default /bot) and writes to
// MAKEFUN_OUTPUT_DIR (default /output). It touches nothing else: no
// network, no wall clock, no files outside the repository, so two runs
// write the same bytes.
//
// Before copying, it checks the file is a JSON object carrying a url
// string, and fails loudly if it is not: a broken VIDEO.json copied
// silently would only be caught later, when the entry is already graded.
import { copyFileSync, mkdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

const botDir = process.env.MAKEFUN_BOT_DIR ?? "/bot";
const outDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

const source = join(botDir, "VIDEO.json");
const parsed: unknown = JSON.parse(readFileSync(source, "utf8"));
if (
  typeof parsed !== "object" ||
  parsed === null ||
  typeof (parsed as { url?: unknown }).url !== "string"
) {
  throw new Error("VIDEO.json must be a JSON object with a string url");
}

mkdirSync(outDir, { recursive: true });
copyFileSync(source, join(outDir, "VIDEO.json"));
