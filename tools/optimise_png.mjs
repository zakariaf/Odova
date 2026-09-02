#!/usr/bin/env node
// Palette-quantise the design reference PNGs.
//
// These are flat UI screenshots — a handful of hues, no photographic gradients —
// so an 8-bit palette is visually identical and roughly a third of the size.
// 336 files live in this repo forever and every clone pays for them.
import { readdir, stat, rename } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const DIR = join(ROOT, 'design', 'reference');

async function* walk(d) {
  for (const e of await readdir(d, { withFileTypes: true })) {
    const p = join(d, e.name);
    if (e.isDirectory()) yield* walk(p);
    else if (e.name.endsWith('.png')) yield p;
  }
}

let before = 0, after = 0, n = 0, grew = 0;
for await (const p of walk(DIR)) {
  const b = (await stat(p)).size;
  const tmp = p + '.opt';
  await sharp(p).png({ palette: true, quality: 90, effort: 9, colours: 256 }).toFile(tmp);
  const a = (await stat(tmp)).size;
  if (a < b) { await rename(tmp, p); after += a; grew += 0; }
  else { const { unlink } = await import('node:fs/promises'); await unlink(tmp); after += b; grew++; }
  before += b; n++;
  if (n % 60 === 0) process.stdout.write(`  ${n}…\n`);
}
const pct = Math.round((1 - after / before) * 100);
console.log(`${n} files: ${(before / 1e6).toFixed(1)} MB → ${(after / 1e6).toFixed(1)} MB (−${pct}%)`);
if (grew) console.log(`${grew} left unchanged (quantising made them larger)`);
