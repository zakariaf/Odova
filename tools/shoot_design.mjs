#!/usr/bin/env node
// Photograph every design mockup screen, in both themes and both directions.
//
//   node tools/shoot_design.mjs [slug ...]
//
// Output, per system:
//   design/reference/<slug>/<screen>-<theme>-<dir>.png     one per screen
//   design/reference/<slug>-contact-<theme>-<lang>.png     the whole set on one sheet
//
// The contact sheets match the convention used in earlier episodes and are what
// a PR attaches for visual parity; the per-screen files are what you diff.
//
// Drives the system Chrome through puppeteer-core — no browser download, and no
// network access is needed or made. Set CHROME= to override the binary.
import { mkdir, readdir, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import puppeteer from 'puppeteer-core';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const CHROME = process.env.CHROME
  || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const SCALE = Number(process.env.SCALE || 2);
const COMBOS = [
  { theme: 'light', locale: 'en', dir: 'ltr' },
  { theme: 'dark', locale: 'en', dir: 'ltr' },
  { theme: 'light', locale: 'fa', dir: 'rtl' },
  { theme: 'dark', locale: 'fa', dir: 'rtl' },
];

const wanted = process.argv.slice(2);
const systems = (await readdir(join(ROOT, 'design'), { withFileTypes: true }))
  .filter((d) => d.isDirectory() && !d.name.startsWith('_') && d.name !== 'reference')
  .map((d) => d.name)
  .filter((s) => !wanted.length || wanted.includes(s));

if (!systems.length) { console.error('no design systems found'); process.exit(1); }
if (!existsSync(CHROME)) { console.error(`Chrome not found at ${CHROME}`); process.exit(1); }

const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: 'new',
  args: ['--no-sandbox', '--force-color-profile=srgb', '--font-render-hinting=none',
    '--disable-lcd-text', '--hide-scrollbars'],
});

let total = 0;
const report = [];

for (const slug of systems) {
  const src = join(ROOT, 'design', slug, 'screens.html');
  if (!existsSync(src)) { console.log(`skip  ${slug} — no screens.html`); continue; }
  const outDir = join(ROOT, 'design', 'reference', slug);
  await mkdir(outDir, { recursive: true });

  const page = await browser.newPage();
  page.on('pageerror', (e) => console.log(`  !! ${slug} page error: ${e.message}`));
  await page.setViewport({ width: 1600, height: 1200, deviceScaleFactor: SCALE });
  await page.goto(pathToFileURL(src).href, { waitUntil: 'load' });
  await page.evaluate(() => document.fonts.ready);
  await page.evaluate(() => document.documentElement.classList.add('shooting'));

  const screens = await page.$$eval('.artboard', (els) =>
    els.map((e) => e.dataset.screen));
  console.log(`\n${slug}: ${screens.length} screens × ${COMBOS.length} combos`);

  for (const c of COMBOS) {
    await page.evaluate((t, l) => { window.setTheme(t); window.setLocale(l); },
      c.theme, c.locale);
    await page.evaluate(() => document.fonts.ready);
    await new Promise((r) => setTimeout(r, 120));

    // ---- per screen
    for (const name of screens) {
      const el = await page.$(`.artboard[data-screen="${name}"] .device`);
      if (!el) { console.log(`  !! ${name}: no .device`); continue; }
      await el.screenshot({ path: join(outDir, `${name}-${c.theme}-${c.dir}.png`) });
      total++;
    }

    // ---- contact sheet: the whole set, one image.
    //
    // fullPage, not an element screenshot. Puppeteer clips an element capture to
    // the viewport, and the viewport that fits a 6-wide grid is not knowable until
    // after the grid has been laid out at that width — measuring first gave a
    // sheet one row tall. Sizing the viewport and letting fullPage do the rest is
    // the version that cannot get this wrong.
    const COLS = 6, W = COLS * 390 + (COLS - 1) * 28 + 64;
    await page.evaluate((cols) => {
      const s = document.getElementById('mk-grid');
      s.style.gridTemplateColumns = `repeat(${cols}, 390px)`;
      s.style.justifyContent = 'start';
    }, COLS);
    // Size the viewport to the laid-out document and take a PLAIN screenshot.
    // `fullPage` expanded only on the first capture of a run and silently gave a
    // one-row sheet for every one after it, which is the kind of bug that ships
    // because the file exists and nobody opens it.
    await page.setViewport({ width: W, height: 1200, deviceScaleFactor: 1 });
    await new Promise((r) => setTimeout(r, 150));
    const h = await page.evaluate(() => Math.ceil(
      Math.max(document.documentElement.scrollHeight, document.body.scrollHeight)));
    await page.setViewport({ width: W, height: Math.min(h, 30000), deviceScaleFactor: 1 });
    await new Promise((r) => setTimeout(r, 150));
    await page.screenshot({
      path: join(ROOT, 'design', 'reference', `${slug}-contact-${c.theme}-${c.locale}.png`),
    });
    total++;
    await page.setViewport({ width: 1600, height: 1200, deviceScaleFactor: SCALE });
    await page.evaluate(() => {
      const s = document.getElementById('mk-grid');
      s.style.gridTemplateColumns = '';
      s.style.justifyContent = '';
    });
    console.log(`  ✓ ${c.theme}/${c.dir}  ${screens.length} screens + contact sheet`);
  }
  report.push({ slug, screens: screens.length });
  await page.close();
}

await browser.close();
console.log(`\n${total} images written to design/reference/`);
for (const r of report) console.log(`  ${r.slug}: ${r.screens} screens × 4 = ${r.screens * 4} + 4 sheets`);
