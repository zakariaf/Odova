/// Reads `design/calm/odova.css`, which is the only source of Calm's values.
///
/// The `calm-tokens` skill repeatedly cites a `tokens.json`; there is no such
/// file in this repo. The CSS is the design, and every Tier-1 constant has to
/// trace to a line in it — otherwise the palette is a second, drifting record
/// of what the app looks like.
library;

import 'dart:io';

/// The path to the design system's stylesheet.
const calmCssPath = 'design/calm/odova.css';

String _css() => File(calmCssPath).readAsStringSync();

/// The body of the `:root, .theme-light` block.
String lightTokenBlock() => RegExp(
  r'^:root,\n\.theme-light \{(.*?)^\}',
  multiLine: true,
  dotAll: true,
).firstMatch(_css())!.group(1)!;

/// The body of the `:root[data-theme="dark"], .theme-dark` block.
String darkTokenBlock() => RegExp(
  r'^:root\[data-theme="dark"\],\n\.theme-dark \{(.*?)^\}',
  multiLine: true,
  dotAll: true,
).firstMatch(_css())!.group(1)!;

/// Every `--color-*` / `--chart-*` declaration in [block], as name → hex.
///
/// Upper-cased, because the CSS and the Dart literals disagree on case and a
/// trace that is case-sensitive is a trace that fails on `#f8f2e9`.
Map<String, String> colourRolesIn(String block) => {
  for (final match in RegExp(
    r'^\s*(--(?:color|chart)-[a-z0-9-]+):\s*(#[0-9A-Fa-f]{6});',
    multiLine: true,
  ).allMatches(block))
    match.group(1)!: match.group(2)!.toUpperCase(),
};

/// The distinct colours declared across both themes.
Set<String> allCalmHexes() => {
  ...colourRolesIn(lightTokenBlock()).values,
  ...colourRolesIn(darkTokenBlock()).values,
};

/// The `rgba(r, g, b, …)` bases used by `--elev-*`, `--scrim` and the sheen.
///
/// They are not roles — they are the opaque colour each alpha value is applied
/// to — so they carry no `--token` name of their own and have to be recovered
/// from the shadow lists.
Set<String> allCalmRgbaBases() => {
  for (final block in [lightTokenBlock(), darkTokenBlock()])
    for (final match in RegExp(
      r'rgba\((\d+),\s*(\d+),\s*(\d+),',
    ).allMatches(block))
      '#'
              '${int.parse(match.group(1)!).toRadixString(16).padLeft(2, '0')}'
              '${int.parse(match.group(2)!).toRadixString(16).padLeft(2, '0')}'
              '${int.parse(match.group(3)!).toRadixString(16).padLeft(2, '0')}'
          .toUpperCase(),
};

/// The value of a single custom property in [block], verbatim.
String? tokenValue(String block, String name) => RegExp(
  '^\\s*${RegExp.escape(name)}:\\s*(.+?);',
  multiLine: true,
).firstMatch(block)?.group(1);
