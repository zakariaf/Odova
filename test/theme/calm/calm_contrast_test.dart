// The contrast audit, as executable code.
//
// `calm-tokens`' audit is a table of measured ratios. Shipped as a unit test
// rather than a spreadsheet, a palette change that drops a pair under
// threshold breaks the build — because the next person to touch
// `--color-ink-3` will not re-run a markdown file by hand.
//
// Thresholds: 4.5:1 for text under 18.66px, which is every Calm role except
// display, hero, titleLg and title; 3:1 for large text and non-text graphics
// (status dots, progress fills, focus rings, chart marks).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_theme.dart';

import '../../support/calm_ramps.dart';
import '../../support/contrast.dart';
import '../../support/source_tree.dart';

/// One declared pair: a foreground, a background and the floor it must clear.
typedef ContrastPair = ({
  String name,
  Color Function(CalmColors) foreground,
  Color Function(CalmColors) background,
  double minRatio,
});

ContrastPair _text(
  String name,
  Color Function(CalmColors) fg,
  Color Function(CalmColors) bg,
) => (name: name, foreground: fg, background: bg, minRatio: bodyTextContrast);

ContrastPair _graphic(
  String name,
  Color Function(CalmColors) fg,
  Color Function(CalmColors) bg,
) => (
  name: name,
  foreground: fg,
  background: bg,
  minRatio: largeTextAndGraphicContrast,
);

/// The paper surfaces any ink may be placed on.
final _surfaces = <String, Color Function(CalmColors)>{
  'bg': (c) => c.bg,
  'surface': (c) => c.surface,
  'surface2': (c) => c.surface2,
  'surface3': (c) => c.surface3,
};

/// The ink slots that carry text, and are therefore held to 4.5:1.
///
/// `ink4` is deliberately NOT here. Its use as *text* in Calm is disabled
/// text, which SC 1.4.3 exempts — `.btn:disabled`, `.stepper__btn.is-disabled`,
/// `.input:disabled`. Declaring it as a text pair would assert something the
/// design never claimed.
///
/// Its NON-exempt use is the row disclosure chevron, which arrived with
/// EPIC-03 task 3.3 exactly as this file predicted it would. A chevron is a
/// non-text graphic, so it is declared below at the 3:1 floor and it fails
/// there — see [knownContrastExceptions]. The chart axis label, the other
/// predicted use, reaches the slot through `chartAxisInk` and is already
/// declared as text.
final _inks = <String, Color Function(CalmColors)>{
  'ink': (c) => c.ink,
  'ink2': (c) => c.ink2,
  'ink3': (c) => c.ink3,
};

/// Every pair the design is accountable for.
List<ContrastPair> declaredPairs() => [
  // The ink ramp on paper — where Calm is tight.
  for (final MapEntry(key: ink, value: fg) in _inks.entries)
    for (final MapEntry(key: paper, value: bg) in _surfaces.entries)
      _text('$ink on $paper', fg, bg),
  _text(
    'inkInverse on surfaceInverse',
    (c) => c.inkInverse,
    (c) => c.surfaceInverse,
  ),

  // Brand.
  _text('onBrand on brand', (c) => c.onBrand, (c) => c.brand),
  _text('onBrand on brandStrong', (c) => c.onBrand, (c) => c.brandStrong),
  _text('brandSoftInk on brandSoft', (c) => c.brandSoftInk, (c) => c.brandSoft),
  _text('brand on surface', (c) => c.brand, (c) => c.surface),

  // Destructive.
  _text('danger on surface', (c) => c.danger, (c) => c.surface),
  _text('danger on dangerTint', (c) => c.danger, (c) => c.dangerTint),

  // The status families: ink on tint is the text pair, base is the graphic.
  for (final MapEntry(key: name, value: ramp) in rampAccessors.entries) ...[
    _text('$name.ink on $name.tint', (c) => ramp(c).ink, (c) => ramp(c).tint),
    _graphic('$name.base on surface', (c) => ramp(c).base, (c) => c.surface),
    _graphic(
      '$name.base on $name.tint',
      (c) => ramp(c).base,
      (c) => ramp(c).tint,
    ),
  ],

  // Non-text graphics.
  // The row disclosure chevron is `ink4` on whichever ground the row has:
  // `surface` in a plain group, `surface2` in a tinted one, `surface3` while
  // the row is pressed.
  _graphic('ink4 on surface', (c) => c.ink4, (c) => c.surface),
  _graphic('ink4 on surface2', (c) => c.ink4, (c) => c.surface2),
  _graphic('ink4 on surface3', (c) => c.ink4, (c) => c.surface3),
  _graphic('focus on surface', (c) => c.focus, (c) => c.surface),
  _graphic('focus on surface3', (c) => c.focus, (c) => c.surface3),
  for (var i = 1; i <= 5; i++)
    _graphic(
      'chart$i on chartPlot',
      (c) => [
        c.chart1,
        c.chart2,
        c.chart3,
        c.chart4,
        c.chart5,
      ][i - 1],
      (c) => c.chartPlot,
    ),

  // Chart axis labels are 13px text, not a graphic.
  _text('chartAxisInk on chartPlot', (c) => c.chartAxisInk, (c) => c.chartPlot),
];

/// Pairs that are known to fail, deliberately, with the decision behind them.
///
/// Each entry asserts the pair **still fails**, so the day the design is fixed
/// this test goes red and forces the exception's removal. An exception that
/// silently goes stale is how a fixed bug gets recorded as permanent.
/// **The decision, 2026-09-03, and who made it.** Taken by the engineer
/// building EPIC-02, deliberately and not quietly, and recorded in three
/// places: here, in `design/calm/ACCESSIBILITY-FINDING.md` under `## Decision`,
/// and in `SPEC.md` §18.
///
/// The remedy is a **design** judgement, not an engineering one — the finding
/// document says so in its own words, and `CLAUDE.md` §9 assigns the closure to
/// EPIC-17. Darkening tertiary text from `#8B7B6C` to `#6B5F53` clears all four
/// light surfaces and measurably reduces the softness that is part of why Calm
/// reads as calm, and nobody building the token layer is in a position to make
/// that trade on the designer's behalf.
///
/// What that costs, stated plainly so the trade is visible rather than
/// implied: fixing it TODAY is two hex values in `design/calm/odova.css` plus
/// one re-shoot of the 112 Calm reference PNGs, about four minutes, and no app
/// code changes because no screen exists. Fixing it after EPIC-15 is the same
/// re-shoot PLUS re-running the parity check on all 28 built screens.
const knownContrastExceptions =
    <({String pair, String theme, double measured, String decision})>[
      // Finding 1 — the single biggest a11y defect in the palette.
      // `--color-ink-3` is `color:` in 47 CSS rules, 25 of them at 13px or
      // 14px: `.row__sub`, `.section__hint`, `.duecard__anchor`.
      (
        pair: 'ink3 on bg',
        theme: 'light',
        measured: 3.67,
        decision: 'deferred to EPIC-17; #6B5F53 clears all four light surfaces',
      ),
      (
        pair: 'ink3 on surface',
        theme: 'light',
        measured: 3.99,
        decision: 'same finding',
      ),
      (
        pair: 'ink3 on surface2',
        theme: 'light',
        measured: 3.42,
        decision: 'same finding',
      ),
      (
        pair: 'ink3 on surface3',
        theme: 'light',
        measured: 3.02,
        decision: 'same finding; the worst of the four',
      ),
      // Dark is not clean either, and the finding document does not say so —
      // it reports ink3 as light-theme-only. Found by this test.
      (
        pair: 'ink3 on surface2',
        theme: 'dark',
        measured: 4.39,
        decision: 'same finding, DARK theme — not in ACCESSIBILITY-FINDING.md',
      ),
      (
        pair: 'ink3 on surface3',
        theme: 'dark',
        measured: 3.84,
        decision: 'same finding, DARK theme — not in ACCESSIBILITY-FINDING.md',
      ),
      // `--chart-axis-ink` IS `--color-ink-3` in light, and a chart axis label
      // is real 13px text rather than a graphic. One value, two findings.
      (
        pair: 'chartAxisInk on chartPlot',
        theme: 'light',
        measured: 3.99,
        decision: 'chartAxisInk is ink3; fixing ink3 fixes this',
      ),
      // The disclosure chevron, 2026-09-03, EPIC-03 task 3.3. `--color-ink-4`
      // is #AC9C8B; against `--color-surface` it is 2.60:1, below SC 1.4.11's
      // 3:1 floor for a graphical object. It is the same design decision as
      // ink3 and the focus ring — deferred to EPIC-17, which must take all
      // three or the chevron stays invisible. Dark on `surface` clears at
      // 3.17:1 and is deliberately NOT excepted, so darkening light to match
      // dark would close five of these six entries at once.
      (
        pair: 'ink4 on surface',
        theme: 'light',
        measured: 2.60,
        decision: 'deferred to EPIC-17 with ink3 and the focus ring',
      ),
      (
        pair: 'ink4 on surface2',
        theme: 'light',
        measured: 2.23,
        decision: 'same finding; a tinted group',
      ),
      (
        pair: 'ink4 on surface3',
        theme: 'light',
        measured: 1.97,
        decision: 'same finding; a pressed row, the worst pair in the palette',
      ),
      (
        pair: 'ink4 on surface2',
        theme: 'dark',
        measured: 2.85,
        decision: 'same finding, DARK theme; a tinted group',
      ),
      (
        pair: 'ink4 on surface3',
        theme: 'dark',
        measured: 2.49,
        decision: 'same finding, DARK theme; a pressed row',
      ),
      // Finding 4 — a focus ring on the warmest surface. SC 1.4.11 holds a
      // focus indicator to 3:1, and a control inside a `surface3` container
      // gets a ring the user cannot see.
      (
        pair: 'focus on surface3',
        theme: 'light',
        measured: 2.82,
        decision:
            'deferred to EPIC-17 with ink3; EPIC-17 must take both, or '
            'the focus ring stays invisible on one surface',
      ),
    ];

/// The ratio, at the precision WCAG is verified in.
///
/// Two decimal places, which is how the criterion is reported by every checker
/// and how the audit states it. This is not a tolerance: it exists for one
/// pair, `due.base` on `due.tint`, which measures **2.999997257573712** — the
/// design landing exactly on 3.0 with the float error of an sRGB gamma curve
/// underneath it. Treating three millionths as a defect would make the gate
/// report a failure no auditor would.
double _measured(Color foreground, Color background) =>
    double.parse(contrastRatio(foreground, background).toStringAsFixed(2));

void main() {
  final themes = {'light': calmColorsLight, 'dark': calmColorsDark};

  // Built once. The list is ~50 records from four nested comprehensions, and
  // it was being rebuilt per theme and again per exception lookup.
  final pairs = declaredPairs();
  final byName = {for (final pair in pairs) pair.name: pair};

  test('every declared pair meets its threshold in both themes', () {
    final excepted = {
      for (final e in knownContrastExceptions) '${e.theme} ${e.pair}',
    };
    final failures = <String>[];

    for (final MapEntry(key: theme, value: colours) in themes.entries) {
      for (final pair in pairs) {
        if (excepted.contains('$theme ${pair.name}')) continue;
        final ratio = _measured(
          pair.foreground(colours),
          pair.background(colours),
        );
        if (ratio < pair.minRatio) {
          failures.add(
            '$theme ${pair.name}: ${ratio.toStringAsFixed(2)}:1 '
            '(needs ${pair.minRatio})',
          );
        }
      }
    }

    expect(failures, isEmpty);
  });

  test('the known exceptions still fail', () {
    // If one passes, the design was fixed and the exception has to go.
    for (final exception in knownContrastExceptions) {
      final colours = themes[exception.theme]!;
      final pair = byName[exception.pair]!;
      final ratio = _measured(
        pair.foreground(colours),
        pair.background(colours),
      );

      expect(
        ratio,
        exception.measured,
        reason:
            '${exception.theme} ${exception.pair} measures '
            '${ratio.toStringAsFixed(2)}:1, not the '
            '${exception.measured}:1 this exception was written against',
      );
      expect(
        ratio,
        lessThan(pair.minRatio),
        reason:
            '${exception.theme} ${exception.pair} now clears its '
            'threshold at ${ratio.toStringAsFixed(2)}:1 — delete the '
            'exception.',
      );
    }
  });

  test('no pair is missing from the declaration', () {
    // Adding an ink slot or a status family without declaring its pairs would
    // pass by omission, which is the quietest way to ship a contrast failure.
    final declared = byName.keys.toSet();

    for (final ink in _inks.keys) {
      for (final paper in _surfaces.keys) {
        expect(declared, contains('$ink on $paper'));
      }
    }
    expect(
      _inks.keys,
      isNot(contains('ink4')),
      reason:
          'ink4 is exempt as a disabled colour; if it has gained a text '
          'use, declare its pairs and expect them to fail',
    );
    for (final ramp in rampAccessors.keys) {
      expect(declared, contains('$ramp.ink on $ramp.tint'));
      expect(declared, contains('$ramp.base on surface'));
    }
  });

  test('ink4 is reachable only from its declared call sites', () {
    // #AC9C8B is 2.60:1 on surface — below even the 3:1 non-text floor. The
    // slot is not banned outright any more, because the design does place it
    // on the chevron; it is ALLOWLISTED, so the file that adds the next use
    // has to come here and say what the use is and which SC exempts it.
    // Comment lines stripped — EPIC-03's CalmField will want to write
    // "/// Never [CalmColors.ink4] here" above its placeholder colour, and
    // that sentence is the point.
    final callSites = dartFilesUnder('lib')
        .where((f) => !f.path.startsWith('lib/theme/calm/'))
        .where(
          (f) => f
              .readAsLinesSync()
              .where((line) => !line.trimLeft().startsWith('//'))
              .join('\n')
              .contains('.ink4'),
        )
        .map((f) => f.path)
        .toSet();

    expect(
      callSites,
      {
        // The disclosure chevron — a non-text graphic, declared above and
        // failing at 2.60:1. Deferred to EPIC-17 with ink3.
        'lib/ui/calm/calm_list_row.dart',
        // Disabled button text, which SC 1.4.3 exempts outright.
        'lib/ui/calm/calm_button.dart',
        // TWO uses, and only one is exempt. Disabled field text is SC 1.4.3
        // exempt like the button's; the PLACEHOLDER is not, and it fails at
        // the same 2.60 / 2.23 the chevron does — see the ink4 pairs above.
        'lib/ui/calm/calm_field.dart',
      },
      reason:
          'a new ink4 use — or a removed one. Every call site is declared '
          'here with the SC that exempts it or the exception that records '
          'its failure; see knownContrastExceptions.',
    );
  });
}
