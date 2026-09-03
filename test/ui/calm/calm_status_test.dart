// The status widgets: CalmBadge and CalmStatusDot.
//
// SPEC.md §1's hardest rule — never guess in a way that looks like fact — is
// carried here by redundant encoding. Calm's six state hues sit within 1.51:1
// of one another in grayscale, so colour cannot tell two states apart and the
// mark plus the word must. This file proves that claim rather than asserting
// it, and it pins the two mark collisions the shipped tokens actually have.
//
// The token-level contrast pairs are NOT re-tested here: EPIC-02's
// test/theme/calm/calm_contrast_test.dart already declares ink-on-tint and
// base-on-surface for every ramp, in both themes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_badge.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';

import '../../support/calm_finders.dart';
import '../../support/contrast.dart';
import '../../support/pump_app.dart';

/// Stand-in for the generated `AppLocalizations`. The six-locale sweep is
/// EPIC-04's; this file only needs six distinct words.
class _Strings implements CalmStatusStrings {
  const _Strings();
  @override
  String get statusOverdue => 'Overdue';
  @override
  String get statusDue => 'Due now';
  @override
  String get statusDueSoon => 'Due soon';
  @override
  String get statusOk => 'On track';
  @override
  String get statusUnknown => 'Never recorded';
  @override
  String get statusNeedsOdometer => 'Needs a reading';
}

const _strings = _Strings();

/// Zero-saturation matrix (ITU-R BT.709 luma), applied to the real widget tree
/// rather than to the tokens, so the test exercises what the user sees.
const _grayscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

ShapeDecoration _badgeDecoration(WidgetTester tester) =>
    calmDecorationOf<ShapeDecoration>(tester, find.byType(CalmBadge));

void main() {
  testWidgets('each of the eleven badge kinds reads exactly one (tint, ink) '
      'pair off its ramp', (tester) async {
    const c = calmColorsLight;
    final expected = <CalmBadgeKind, (Color, Color?)>{
      CalmBadgeKind.overdue: (
        CalmStatusStyle.resolve(c, DueState.overdue).tint,
        CalmStatusStyle.resolve(c, DueState.overdue).ink,
      ),
      CalmBadgeKind.due: (
        CalmStatusStyle.resolve(c, DueState.due).tint,
        CalmStatusStyle.resolve(c, DueState.due).ink,
      ),
      CalmBadgeKind.dueSoon: (
        CalmStatusStyle.resolve(c, DueState.dueSoon).tint,
        CalmStatusStyle.resolve(c, DueState.dueSoon).ink,
      ),
      CalmBadgeKind.ok: (
        CalmStatusStyle.resolve(c, DueState.ok).tint,
        CalmStatusStyle.resolve(c, DueState.ok).ink,
      ),
      CalmBadgeKind.unknown: (
        CalmStatusStyle.resolve(c, DueState.unknown).tint,
        CalmStatusStyle.resolve(c, DueState.unknown).ink,
      ),
      CalmBadgeKind.needsOdometer: (
        CalmStatusStyle.resolve(c, DueState.needsOdometer).tint,
        CalmStatusStyle.resolve(c, DueState.needsOdometer).ink,
      ),
      CalmBadgeKind.business: (c.business.tint, c.business.ink),
      CalmBadgeKind.brand: (c.brandSoft, c.brandSoftInk),
      CalmBadgeKind.neutral: (c.surface2, c.ink2),
      CalmBadgeKind.count: (c.brand, c.onBrand),
      // `.badge--dot` is 10px of --color-overdue and carries no text at all.
      CalmBadgeKind.dot: (
        CalmStatusStyle.resolve(c, DueState.overdue).base,
        null,
      ),
    };
    // Guard the guard: a twelfth kind must not pass by omission.
    expect(expected.keys.toSet(), CalmBadgeKind.values.toSet());
    expect(expected, hasLength(11));

    for (final MapEntry(key: kind, value: pair) in expected.entries) {
      await pumpApp(
        tester,
        Center(
          child: kind == CalmBadgeKind.dot
              ? const CalmBadge.dot()
              : CalmBadge(label: '3', kind: kind),
        ),
      );

      expect(_badgeDecoration(tester).color, pair.$1, reason: kind.name);
      if (pair.$2 case final ink?) {
        expect(
          tester.widget<Text>(find.text('3')).style!.color,
          ink,
          reason: kind.name,
        );
      } else {
        expect(find.byType(Text), findsNothing, reason: kind.name);
        expect(tester.getSize(find.byType(CalmBadge)), const Size(10, 10));
      }
    }
  });

  testWidgets('a labelled badge reads a tint, never a base', (tester) async {
    // A badge filled with `base` is a solid block of state colour behind
    // caption-sized text — the pair the palette never audited.
    final bases = {
      for (final state in DueState.values)
        CalmStatusStyle.resolve(calmColorsLight, state).base,
    };

    for (final kind in CalmBadgeKind.values) {
      if (kind == CalmBadgeKind.dot) continue;
      await pumpApp(
        tester,
        Center(
          child: CalmBadge(label: '3', kind: kind),
        ),
      );
      expect(
        bases,
        isNot(contains(_badgeDecoration(tester).color)),
        reason: kind.name,
      );
    }
  });

  testWidgets('a badge is 26 tall, pill-shaped and not interactive', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Center(child: CalmBadge(label: 'Overdue')),
    );

    expect(tester.getSize(find.byType(CalmBadge)).height, 26);
    expect(_badgeDecoration(tester).shape, const StadiumBorder());
    // Never the only signal, and never a control: a badge beside a word is
    // reinforcement, and a badge you can press is a button nobody labelled.
    expect(find.byType(GestureDetector), findsNothing);
  });

  test('every state carries a unique (mark, label) pair', () {
    final seen = <String>{};
    for (final state in DueState.values) {
      final style = CalmStatusStyle.resolve(calmColorsLight, state);
      expect(
        seen.add('${style.mark}|${style.label(_strings)}'),
        isTrue,
        reason: 'duplicate signal pair for ${state.name}',
      );
    }
    expect(seen, hasLength(DueState.values.length));
  });

  test('mark geometry alone is not enough — two pairs stay too close', () {
    // EPIC-03 task 3.5 asks for "six distinct silhouettes". The shipped tokens
    // give FIVE marks for six states: odova.css §12 draws `ok` and `overdue`
    // with the same 12px filled disc, and separates `unknown` from
    // `needsOdometer` by opacity alone. That is a finding against the design,
    // not licence to invent a sixth silhouette here — the reference is the
    // authority. The (mark, label) PAIR above is what is actually unique.
    //
    // When the design assigns two more silhouettes this test fails. Delete it
    // then, and tighten the test above to assert on the mark alone.
    final byMark = <CalmStatusMark, List<DueState>>{};
    for (final state in DueState.values) {
      byMark
          .putIfAbsent(
            CalmStatusStyle.resolve(calmColorsLight, state).mark,
            () => <DueState>[],
          )
          .add(state);
    }

    final collisions = byMark.values.where((g) => g.length > 1).toList();
    expect(collisions, hasLength(1));
    expect(collisions.single, [DueState.overdue, DueState.ok]);

    // The softer collision: same diameter, same stroke, separated only by
    // opacity, so the grouping above cannot see it. Pinned directly.
    final unknown = CalmStatusStyle.resolve(
      calmColorsLight,
      DueState.unknown,
    ).mark;
    final needs = CalmStatusStyle.resolve(
      calmColorsLight,
      DueState.needsOdometer,
    ).mark;
    expect(unknown.diameter, needs.diameter);
    expect(unknown.strokeWidth, needs.strokeWidth);
    expect(unknown.opacity, isNot(needs.opacity));
  });

  test('no two state hues are separable in grayscale', () {
    // Documentation, not a wish. If it ever fails the palette gained real
    // separation, and it should say so loudly rather than quietly stop
    // justifying the mark and the word.
    for (final MapEntry(key: theme, value: colours) in {
      'light': calmColorsLight,
      'dark': calmColorsDark,
    }.entries) {
      for (final a in DueState.values) {
        for (final b in DueState.values) {
          if (a == b) continue;
          final ratio = contrastRatio(
            CalmStatusStyle.resolve(colours, a).base,
            CalmStatusStyle.resolve(colours, b).base,
          );
          expect(
            ratio,
            lessThan(largeTextAndGraphicContrast),
            reason:
                '$theme: ${a.name} vs ${b.name} = '
                '${ratio.toStringAsFixed(2)}:1',
          );
        }
      }
    }
  });

  test('the anchor line uses ink2 — ink3 is under AA on every status tint', () {
    for (final MapEntry(key: theme, value: colours) in {
      'light': calmColorsLight,
      'dark': calmColorsDark,
    }.entries) {
      for (final state in DueState.values) {
        final tint = CalmStatusStyle.resolve(colours, state).tint;
        expect(
          contrastRatio(colours.ink2, tint),
          greaterThanOrEqualTo(bodyTextContrast),
          reason: '$theme ${state.name}: ink2 on tint',
        );
      }
    }
  });

  test('the uncertain states never borrow the ok or overdue palette', () {
    for (final colours in [calmColorsLight, calmColorsDark]) {
      final claimed = <Color>{
        for (final state in [DueState.ok, DueState.overdue]) ...[
          CalmStatusStyle.resolve(colours, state).base,
          CalmStatusStyle.resolve(colours, state).ink,
          CalmStatusStyle.resolve(colours, state).tint,
        ],
      };

      for (final state in [DueState.unknown, DueState.needsOdometer]) {
        final style = CalmStatusStyle.resolve(colours, state);
        expect(claimed, isNot(contains(style.base)));
        expect(claimed, isNot(contains(style.ink)));
        expect(claimed, isNot(contains(style.tint)));
        expect(style.isUncertain, isTrue);
      }
    }
  });

  testWidgets('the dots take their geometry from CalmStatusMark, never a '
      'literal', (tester) async {
    for (final state in DueState.values) {
      final style = CalmStatusStyle.resolve(calmColorsLight, state);
      await pumpApp(
        tester,
        Center(child: CalmStatusDot(style: style)),
      );

      expect(
        tester.getSize(find.byType(CalmStatusDot)),
        Size.square(style.mark.diameter),
        reason: state.name,
      );
    }

    // And the geometry the design actually specifies, so a "tidy-up" that
    // makes every dot 12px filled has to come here and delete this.
    expect(CalmStatusMark.filledLarge.diameter, 12);
    expect(CalmStatusMark.filledLarge.strokeWidth, 0);
    expect(CalmStatusMark.filledSmall.diameter, 8);
    expect(CalmStatusMark.ringHeavy.strokeWidth, 3);
    expect(CalmStatusMark.ringLight.strokeWidth, 2);
    expect(CalmStatusMark.ringLightFaded.opacity, 0.7);
  });

  testWidgets('a status dot adds no stop for a screen reader', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpApp(
      tester,
      Center(
        child: Semantics(
          label: 'Overdue',
          child: CalmStatusDot(
            style: CalmStatusStyle.resolve(calmColorsLight, DueState.overdue),
          ),
        ),
      ),
    );

    // The wording carries the meaning; the dot is reinforcement. A node of its
    // own is one extra stop on every row of a list.
    expect(
      tester.getSemantics(find.byType(CalmStatusDot)),
      matchesSemantics(label: 'Overdue'),
    );

    handle.dispose();
  });

  testWidgets('in grayscale, every state is still named and still distinct', (
    tester,
  ) async {
    await pumpApp(
      tester,
      ColorFiltered(
        colorFilter: _grayscale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final state in DueState.values)
              Builder(
                builder: (context) {
                  final style = CalmStatusStyle.of(context, state);
                  return Row(
                    children: [
                      CalmStatusDot(key: ValueKey(state), style: style),
                      Text(style.label(_strings)),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );

    for (final state in DueState.values) {
      final style = CalmStatusStyle.resolve(calmColorsLight, state);
      // Signal 2 survives the filter: the word is still there and still
      // unique.
      expect(
        find.text(style.label(_strings)),
        findsOneWidget,
        reason: state.name,
      );
      // Signal 1 survives it too: geometry is not a colour.
      expect(
        tester.getSize(find.byKey(ValueKey(state))),
        Size.square(style.mark.diameter),
        reason: state.name,
      );
    }
  });
}
