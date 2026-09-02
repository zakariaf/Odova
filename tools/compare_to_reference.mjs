#!/usr/bin/env node
// Compare a screenshot of the BUILT app against the design reference.
//
//   node tools/compare_to_reference.mjs <app.png> <screen> [--theme light|dark]
//                                        [--dir ltr|rtl] [--system calm]
//
// Writes design/reference/_parity/<screen>-<theme>-<dir>.png — reference, app,
// and a difference heatmap side by side — and prints a report.
//
// WHAT THIS CAN AND CANNOT PROVE, stated plainly, because a gate that overclaims
// gets switched off the first week:
//
//   The reference is Chrome rendering HTML+CSS. The app is Flutter rendering
//   Skia. Glyph rasterisation, subpixel positioning, shadow blur and gradient
//   dithering all differ. The two will NEVER be pixel-identical, and a raw pixel
//   diff is therefore useless as a pass/fail gate — it is included only as a
//   heatmap for a human to look at.
//
//   What IS decidable, and what this tool actually gates on:
//     colour  — every large surface the app paints must be a Calm token, within a
//               small delta. The delta is not slack for taste: the committed
//               references are palette-quantised (tools/optimise_png.mjs, 58 MB
//               -> 19 MB), so exact token hexes do not survive in them, and
//               Calm's card gradients legitimately produce intermediate values.
//               The comparison is therefore APP-versus-TOKENS, never
//               app-versus-reference-pixels.
//     bands   — the vertical position and height of each horizontal region of
//               the screen. Catches a card in the wrong place, wrong height, or
//               missing, and is not fooled by text rendering differently.
import { mkdir, readdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const args = process.argv.slice(2);
const flag = (n, d) => { const i = args.indexOf(`--${n}`); return i === -1 ? d : args[i + 1]; };
const positional = args.filter((a, i) => !a.startsWith('--') && !args[i - 1]?.startsWith('--'));

const [appPath, screen] = positional;
const theme = flag('theme', 'light');
const dir = flag('dir', 'ltr');
const system = flag('system', 'calm');
const BAND_TOL = Number(flag('band-tolerance', 4));   // px, at reference scale

if (!appPath || !screen) {
  console.error('usage: compare_to_reference.mjs <app.png> <screen> [--theme] [--dir] [--system]');
  process.exit(2);
}

const refPath = join(ROOT, 'design', 'reference', system, `${screen}-${theme}-${dir}.png`);
if (!existsSync(refPath)) {
  console.error(`no reference for ${screen}-${theme}-${dir}. Available:`);
  const all = await readdir(join(ROOT, 'design', 'reference', system));
  console.error('  ' + [...new Set(all.map((f) => f.replace(/-(light|dark)-(ltr|rtl)\.png$/, '')))].join(', '));
  process.exit(2);
}
if (!existsSync(appPath)) { console.error(`no such file: ${appPath}`); process.exit(2); }

// ---- load both at the reference's size, so a 1x device shot still compares
const ref = sharp(refPath);
const refMeta = await ref.metadata();
const W = refMeta.width, H = refMeta.height;
const refRaw = await ref.clone().ensureAlpha().raw().toBuffer();
const appRaw = await sharp(appPath).resize(W, H, { fit: 'fill' }).ensureAlpha().raw().toBuffer();

// ---- the Calm token set, split by theme.
// Split, because "is this colour a token?" cannot catch a dark build shot against
// a light reference: the dark palette is made of tokens too. The requested
// theme's own background is what settles it.
const { readFile } = await import('node:fs/promises');
const cssText = await readFile(join(ROOT, 'design', system, 'odova.css'), 'utf8');

function tokensOf(selector) {
  const i = cssText.indexOf(selector);
  if (i === -1) return new Map();
  const body = cssText.slice(i, cssText.indexOf('}', i));
  const m = new Map();
  for (const [, name, val] of body.matchAll(/(--[\w-]+)\s*:\s*([^;]+);/g)) {
    for (const [, h] of val.matchAll(/#([0-9A-Fa-f]{6})\b/g)) {
      const k = h.toUpperCase();
      if (!m.has(k)) m.set(k, name);
    }
  }
  return m;
}
const lightTokens = tokensOf(':root,\n.theme-light {');
const darkTokens = tokensOf(':root[data-theme="dark"],\n.theme-dark {');
// Scale, radius and motion tokens are declared once, in the light block; a colour
// that appears in both blocks is theme-neutral and never decides the theme.
const themeTokens = theme === 'dark' ? darkTokens : lightTokens;
const otherTokens = theme === 'dark' ? lightTokens : darkTokens;
const tokens = new Map([...lightTokens, ...darkTokens]);

const hex = (r, g, b) => [r, g, b].map((v) => v.toString(16).padStart(2, '0')).join('').toUpperCase();

// ---- colour census: what does each image actually paint, and is it a token?
function census(raw) {
  const counts = new Map();
  for (let i = 0; i < raw.length; i += 4) {
    const k = hex(raw[i], raw[i + 1], raw[i + 2]);
    counts.set(k, (counts.get(k) || 0) + 1);
  }
  return [...counts.entries()].sort((a, b) => b[1] - a[1]);
}

// ---- band profile: mean luminance per row, then the rows where it steps
function bands(raw) {
  const rows = new Float64Array(H);
  for (let y = 0; y < H; y++) {
    let s = 0;
    for (let x = 0; x < W; x++) {
      const i = (y * W + x) * 4;
      s += 0.2126 * raw[i] + 0.7152 * raw[i + 1] + 0.0722 * raw[i + 2];
    }
    rows[y] = s / W;
  }
  const edges = [];
  for (let y = 1; y < H; y++) if (Math.abs(rows[y] - rows[y - 1]) > 2.0) edges.push(y);
  // collapse runs
  const out = [];
  for (const e of edges) if (!out.length || e - out[out.length - 1] > 3) out.push(e);
  return out;
}

// ---- difference heatmap (for human eyes only)
const diff = Buffer.alloc(W * H * 4);
let differing = 0;
for (let i = 0; i < refRaw.length; i += 4) {
  const d = Math.abs(refRaw[i] - appRaw[i]) + Math.abs(refRaw[i + 1] - appRaw[i + 1]) +
            Math.abs(refRaw[i + 2] - appRaw[i + 2]);
  const hot = d > 30;
  if (hot) differing++;
  diff[i] = hot ? 255 : 20; diff[i + 1] = hot ? 40 : 20; diff[i + 2] = hot ? 90 : 20; diff[i + 3] = 255;
}

const outDir = join(ROOT, 'design', 'reference', '_parity');
await mkdir(outDir, { recursive: true });
const outPath = join(outDir, `${screen}-${theme}-${dir}.png`);
const GAP = 16;
await sharp({ create: { width: W * 3 + GAP * 4, height: H + GAP * 2, channels: 4,
                        background: { r: 26, g: 26, b: 26, alpha: 1 } } })
  .composite([
    { input: refPath, top: GAP, left: GAP },
    { input: await sharp(appPath).resize(W, H, { fit: 'fill' }).png().toBuffer(), top: GAP, left: GAP * 2 + W },
    { input: await sharp(diff, { raw: { width: W, height: H, channels: 4 } }).png().toBuffer(),
      top: GAP, left: GAP * 3 + W * 2 },
  ])
  .png({ palette: true })
  .toFile(outPath);

// ---------------------------------------------------------------- the report
const refCensus = census(refRaw), appCensus = census(appRaw);
const total = W * H;
// Nearest token by summed channel distance. TOKEN_TOL absorbs palette
// quantisation and gradient banding; it is far tighter than the gap between any
// two Calm tokens, so a genuinely wrong colour still fails.
const TOKEN_TOL = Number(flag('token-tolerance', 24));
const nearestToken2 = (h, map) => [...map.keys()]
  .map((t) => ({ t, d: [0, 2, 4].reduce((a, o) =>
    a + Math.abs(parseInt(h.slice(o, o + 2), 16) - parseInt(t.slice(o, o + 2), 16)), 0) }))
  .sort((a, b) => a.d - b.d)[0];

const nearestToken = (h) => [...tokens.keys()]
  .map((t) => ({ t, d: [0, 2, 4].reduce((a, o) =>
    a + Math.abs(parseInt(h.slice(o, o + 2), 16) - parseInt(t.slice(o, o + 2), 16)), 0) }))
  .sort((a, b) => a.d - b.d)[0];

const appOffToken = appCensus
  .filter(([h, n]) => n / total > 0.005)
  .map(([h, n]) => ({ h, n, near: nearestToken(h) }))
  .filter((c) => !c.near || c.near.d > TOKEN_TOL)
  .slice(0, 8);

console.log(`\n${screen} · ${theme} · ${dir}`);
console.log(`reference  ${basename(refPath)}  ${W}x${H}`);
console.log(`sheet      design/reference/_parity/${basename(outPath)}`);
console.log(`\npixels differing >30: ${(100 * differing / total).toFixed(1)}%  ` +
            `(informational — Chrome and Skia never agree pixel for pixel)`);

console.log('\ncolour — every surface the app paints should be a Calm token');
if (!appOffToken.length) {
  console.log(`  ok    every surface over 0.5% is within Δ${TOKEN_TOL} of a Calm token`);
} else {
  for (const { h, n, near } of appOffToken) {
    console.log(`  FAIL  #${h} covers ${(100 * n / total).toFixed(1)}% and is not a Calm token` +
                (near ? ` — nearest is ${tokens.get(near.t)} #${near.t} (Δ${near.d})` : ''));
  }
}

// ---- is this actually the theme we asked for?
// The single largest surface is the screen's ground. If it belongs to the OTHER
// theme's palette and not to this one, the build under test is in the wrong
// theme and every other check below would pass while saying nothing.
const [domHex, domN] = appCensus[0];
const inThis = themeTokens.has(domHex) || (nearestToken2(domHex, themeTokens)?.d ?? 999) <= TOKEN_TOL;
const inOther = otherTokens.has(domHex) || (nearestToken2(domHex, otherTokens)?.d ?? 999) <= TOKEN_TOL;
let wrongTheme = false;
console.log(`\ntheme — the ground should be a ${theme} token`);
if (inThis) {
  console.log(`  ok    #${domHex} (${(100 * domN / total).toFixed(0)}% of the screen) is a ${theme} surface`);
} else if (inOther) {
  wrongTheme = true;
  console.log(`  FAIL  #${domHex} covers ${(100 * domN / total).toFixed(0)}% and belongs to the ` +
              `${theme === 'dark' ? 'light' : 'dark'} palette — this build is in the wrong theme`);
} else {
  wrongTheme = true;
  console.log(`  FAIL  #${domHex} covers ${(100 * domN / total).toFixed(0)}% and is in neither palette`);
}

const rb = bands(refRaw), ab = bands(appRaw);
const matched = rb.filter((y) => ab.some((z) => Math.abs(z - y) <= BAND_TOL * (H / 1688)));
console.log(`\nlayout — horizontal bands within ${BAND_TOL}px`);
console.log(`  ${matched.length}/${rb.length} reference band edges have an app edge nearby`);
const missRatio = rb.length ? 1 - matched.length / rb.length : 0;
if (missRatio > 0.25) {
  console.log(`  FAIL  ${(100 * missRatio).toFixed(0)}% of the reference's band edges are absent — ` +
              `something is a different height or in a different place`);
} else {
  console.log('  ok    the vertical rhythm matches the reference');
}

const failed = appOffToken.length > 0 || missRatio > 0.25 || wrongTheme;
console.log(`\n${failed ? 'FAIL' : 'ok  '}  open the sheet and look at it either way — ` +
            `these checks cannot see everything.\n`);
process.exit(failed ? 1 : 0);
