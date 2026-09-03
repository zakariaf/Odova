#!/usr/bin/env node
// Assemble design/<slug>/screens.html from the per-group artboard fragments.
//
// The shell — the theme/locale API, the grid, the control bar — lives HERE rather
// than in each design system, so all three behave identically and the screenshot
// tool has one contract to drive. The systems own look; they do not own plumbing.
import { readFile, writeFile, readdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
// The artboard fragments are vendored at design/_fragments/ so this is reproducible.
// They were once only in a scratch directory, which made a rebuild silently destroy any
// artboard added since — exactly how `dialog.snooze` nearly got lost.
const FRAG = process.env.FRAG_DIR || join(ROOT, 'design', '_fragments');

const ORDER = ['g1', 'g2', 'g3'];

// Pull the icon sprite out of system.html. The screens reference icons with
// <use href="#i-...">, and a <use> whose symbol is absent renders NOTHING —
// silently, with no console error. Injecting the sprite here is what stops the
// screenshots coming out with holes where every icon should be.
async function spriteFrom(systemHtml) {
  let i = 0;
  while ((i = systemHtml.indexOf('<svg', i)) !== -1) {
    const end = systemHtml.indexOf('</svg>', i);
    if (end === -1) break;
    const chunk = systemHtml.slice(i, end + 6);
    if (chunk.includes('<symbol')) {
      // Force it hidden regardless of how the system authored it.
      return chunk.replace(/^<svg\b[^>]*>/,
        '<svg width="0" height="0" aria-hidden="true" focusable="false" style="position:absolute">');
    }
    i = end + 6;
  }
  return '';
}

const shell = (slug, name, sprite, body) => `<!doctype html>
<html lang="en" dir="ltr" data-theme="light">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Odova — ${name} — all screens</title>
<link rel="stylesheet" href="odova.css">
<style>
  /* Page chrome only. Nothing here may style the inside of a .device — that is
     the design system's job, and a rule that leaks in would make the mockup a
     lie about what odova.css can do on its own. */
  /* Every shell class is mk- prefixed. .sheet, .bar and .card are all real
     component names inside these design systems - an unprefixed shell class gets
     silently restyled by odova.css, and the first symptom is a contact sheet that
     is one row tall instead of five. */
  body { margin: 0; background: #6b6b6b; }
  .mk-grid, .mk-bar, .mk-cap { position: static; inset: auto; max-height: none; transform: none; }
  html[data-theme="dark"] body { background: #141414; }
  .mk-bar {
    position: sticky; top: 0; z-index: 99; display: flex; gap: 12px;
    align-items: center; flex-wrap: wrap;
    padding: 10px 16px; background: #1c1c1c; color: #fff;
    font: 500 13px/1.4 system-ui, sans-serif;
  }
  .mk-bar strong { font-size: 15px; margin-inline-end: 8px; }
  .mk-bar button {
    font: inherit; padding: 5px 12px; border-radius: 6px; cursor: pointer;
    border: 1px solid #555; background: #2b2b2b; color: #fff;
  }
  .mk-bar button[aria-pressed="true"] { background: #fff; color: #000; border-color: #fff; }
  .mk-bar span { opacity: .6; }
  .mk-grid {
    display: grid; gap: 40px 28px; padding: 32px;
    grid-template-columns: repeat(auto-fill, minmax(390px, max-content));
    justify-content: center;
  }
  .artboard { display: block; }
  .mk-cap {
    margin: 0 0 8px; color: #fff; font: 600 12px/1.3 ui-monospace, Menlo, monospace;
    letter-spacing: .04em;
  }
  .mk-cap b { font-weight: 600; }
  .mk-cap i { font-style: normal; opacity: .55; font-weight: 400; }
  /* Screenshots must be deterministic: no half-finished transition, no caret. */
  html.shooting *, html.shooting *::before, html.shooting *::after {
    transition: none !important; animation: none !important; caret-color: transparent !important;
  }
  html.shooting .mk-bar, html.shooting .mk-cap { display: none !important; }
</style>
</head>
<body>
${sprite}
<div class="mk-bar no-shot">
  <strong>Odova · ${name}</strong>
  <span>theme</span>
  <button id="t-light" aria-pressed="true" onclick="setTheme('light')">Light</button>
  <button id="t-dark" aria-pressed="false" onclick="setTheme('dark')">Dark</button>
  <span>language</span>
  <button id="l-en" aria-pressed="true" onclick="setLocale('en')">English (LTR)</button>
  <button id="l-fa" aria-pressed="false" onclick="setLocale('fa')">فارسی (RTL)</button>
  <span id="count"></span>
</div>
<main class="mk-grid" id="mk-grid">
${body}
</main>
<script>
// ---- the contract the screenshot tool drives -------------------------------
function setTheme(t) {
  document.documentElement.dataset.theme = t;
  document.getElementById('t-light')?.setAttribute('aria-pressed', String(t === 'light'));
  document.getElementById('t-dark')?.setAttribute('aria-pressed', String(t === 'dark'));
}
function setLocale(l) {
  const root = document.documentElement;
  root.lang = l;
  root.dir = l === 'fa' ? 'rtl' : 'ltr';
  for (const el of document.querySelectorAll('[data-en]')) {
    const v = el.getAttribute('data-' + l);
    if (v !== null) el.textContent = v;
  }
  document.getElementById('l-en')?.setAttribute('aria-pressed', String(l === 'en'));
  document.getElementById('l-fa')?.setAttribute('aria-pressed', String(l === 'fa'));
}
window.setTheme = setTheme;
window.setLocale = setLocale;

// Caption each artboard with its id, so the file is browsable by a human.
for (const a of document.querySelectorAll('.artboard')) {
  const cap = document.createElement('p');
  cap.className = 'mk-cap no-shot';
  cap.innerHTML = '<b>' + a.dataset.screen + '</b> &nbsp;<i>' + (a.dataset.title || '') + '</i>';
  a.prepend(cap);
}
document.getElementById('count').textContent =
  document.querySelectorAll('.artboard').length + ' screens';
</script>
</body>
</html>
`;

const systems = (await readdir(join(ROOT, 'design'), { withFileTypes: true }))
  .filter((d) => d.isDirectory() && !d.name.startsWith('_') && d.name !== 'reference')
  .map((d) => d.name);

for (const slug of systems) {
  const parts = [];
  const missing = [];
  for (const g of ORDER) {
    const p = join(FRAG, `${slug}.${g}.html`);
    if (!existsSync(p)) { missing.push(g); continue; }
    parts.push((await readFile(p, 'utf8')).trim());
  }
  if (!parts.length) { console.log(`skip  ${slug} — no fragments`); continue; }
  const name = slug.split('-').map((w) => w[0].toUpperCase() + w.slice(1)).join(' ');
  const sysHtml = await readFile(join(ROOT, 'design', slug, 'system.html'), 'utf8');
  const sprite = await spriteFrom(sysHtml);
  if (!sprite) console.log(`  !! ${slug}: no icon sprite found in system.html`);
  // A fragment may have pasted the sprite in too; drop those copies so ids stay unique.
  const cleaned = parts.map((p) => p.replace(/<svg\b(?![^>]*class="icon)[^>]*>[\s\S]*?<\/svg>/g,
    (m) => (m.includes('<symbol') ? '' : m)));
  const html = shell(slug, name, sprite, cleaned.join('\n\n'));
  const out = join(ROOT, 'design', slug, 'screens.html');
  await writeFile(out, html);
  const n = (html.match(/class="artboard"/g) || []).length;
  console.log(`ok    ${slug}: ${n} artboards${missing.length ? '  MISSING ' + missing.join(',') : ''}`);
}
