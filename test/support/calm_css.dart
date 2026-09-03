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

/// One layer of a CSS `box-shadow`: `<dy>px <blur>px <spread>px rgba(...)`.
typedef CssShadowLayer = ({
  double dy,
  double blur,
  double spread,
  double alpha,
});

/// The layers of `--elev-<level>` in [block].
///
/// CSS writes `0 2px 4px rgba(76, 50, 32, 0.05)` and omits the spread when it
/// is zero, so the parser has to treat the third length as optional.
List<CssShadowLayer> elevationLayers(String block, int level) {
  final value = tokenValue(block, '--elev-$level');
  if (value == null || value == 'none') return const [];

  return [
    for (final match in RegExp(
      r'0 (-?[\d.]+)px (-?[\d.]+)px(?: (-?[\d.]+)px)? '
      r'rgba\(\s*\d+,\s*\d+,\s*\d+,\s*([\d.]+)\s*\)',
    ).allMatches(value))
      (
        dy: double.parse(match.group(1)!),
        blur: double.parse(match.group(2)!),
        spread: double.parse(match.group(3) ?? '0'),
        alpha: double.parse(match.group(4)!),
      ),
  ];
}

/// Every `--space-*` and fixed-metric declaration in [block], as name → px.
Map<String, double> pixelMetricsIn(String block) => {
  for (final match in RegExp(
    r'^\s*(--(?:space-\d+|screen-pad|appbar-h|statusbar-h|tabbar-h|homebar-h|'
    r'touch-min|radius-[a-z0-9]+)):\s*(\d+)px;',
    multiLine: true,
  ).allMatches(block))
    match.group(1)!: double.parse(match.group(2)!),
};

/// Every `--dur-*` declaration in [block], as name → milliseconds.
Map<String, int> durationsIn(String block) => {
  for (final match in RegExp(
    r'^\s*(--dur-[a-z]+):\s*(\d+)ms;',
    multiLine: true,
  ).allMatches(block))
    match.group(1)!: int.parse(match.group(2)!),
};

/// Every `--ease-*` declaration in [block], as name → its four control points.
Map<String, List<double>> curvesIn(String block) => {
  for (final match in RegExp(
    r'^\s*(--ease-[a-z]+):\s*cubic-bezier\(([^)]+)\);',
    multiLine: true,
  ).allMatches(block))
    match.group(1)!: [
      for (final part in match.group(2)!.split(',')) double.parse(part.trim()),
    ],
};
