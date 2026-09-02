// test/theme/calm/status_grayscale_test.dart
//
// Proves the claim the whole skill rests on: in Calm, colour cannot tell two
// states apart, so mark + label must. Every number here is computed from the
// shipped tokens — nothing is hand-copied from a design file.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';

/// WCAG 2.x relative-luminance ratio. `Color.computeLuminance` already applies
/// the sRGB transfer function, so this is the whole formula.
double contrastRatio(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Stand-in for the generated AppLocalizations. English strings only; the
/// six-locale sweep lives in the l10n tests (`calm-typography-and-rtl`).
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

const _Strings strings = _Strings();

/// Zero-saturation matrix (ITU-R BT.709 luma), applied to the real widget tree
/// rather than to the tokens, so the test exercises what the user sees.
const ColorFilter grayscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

void main() {
  final Map<String, CalmColors> themes = <String, CalmColors>{
    'light': calmColorsLight,
    'dark': calmColorsDark,
  };

  group('contrast', () {
    test('status ink clears AA 4.5:1 on its own tint and on the surface', () {
      for (final MapEntry<String, CalmColors> t in themes.entries) {
        for (final DueState s in DueState.values) {
          final CalmStatusStyle st = CalmStatusStyle.resolve(t.value, s);
          expect(contrastRatio(st.ink, st.tint), greaterThanOrEqualTo(4.5),
              reason: '${t.key} ${s.name}: ink on tint');
          expect(contrastRatio(st.ink, t.value.surface), greaterThanOrEqualTo(4.5),
              reason: '${t.key} ${s.name}: ink on surface');
        }
      }
    });

    test('the dot clears the 3:1 non-text floor on the card surface', () {
      for (final MapEntry<String, CalmColors> t in themes.entries) {
        for (final DueState s in DueState.values) {
          final CalmStatusStyle st = CalmStatusStyle.resolve(t.value, s);
          expect(contrastRatio(st.base, t.value.surface), greaterThanOrEqualTo(3.0),
              reason: '${t.key} ${s.name}: base on surface');
        }
      }
    });

    test('the dot on the primary card tint — light `due` misses the floor', () {
      for (final MapEntry<String, CalmColors> t in themes.entries) {
        for (final DueState s in DueState.values) {
          final CalmStatusStyle st = CalmStatusStyle.resolve(t.value, s);
          final double r = contrastRatio(st.base, st.tint);
          if (t.key == 'light' && s == DueState.due) {
            // #B0802C on #F8ECD1 = 2.99999:1 — under WCAG 1.4.11 by three
            // ten-thousandths. Pinned, not rounded away, so any palette edit
            // has to decide about it on purpose.
            expect(r, lessThan(3.0));
            expect(r, greaterThan(2.99));
          } else {
            expect(r, greaterThanOrEqualTo(3.0),
                reason: '${t.key} ${s.name}: base on its own tint');
          }
        }
      }
    });

    test('the anchor line uses ink2 — ink3 is under AA at 13px', () {
      for (final MapEntry<String, CalmColors> t in themes.entries) {
        for (final DueState s in DueState.values) {
          final CalmStatusStyle st = CalmStatusStyle.resolve(t.value, s);
          expect(contrastRatio(t.value.ink2, st.tint), greaterThanOrEqualTo(4.5),
              reason: '${t.key} ${s.name}: ink2 on tint');
          expect(contrastRatio(t.value.ink3, st.tint), lessThan(4.5),
              reason: '${t.key} ${s.name}: ink3 is expected to FAIL — if this '
                  'passes the palette changed and rule 10 can be relaxed');
        }
      }
    });
  });

  group('colour is not a signal', () {
    test('no two state hues are separable in grayscale', () {
      for (final MapEntry<String, CalmColors> t in themes.entries) {
        for (final DueState a in DueState.values) {
          for (final DueState b in DueState.values) {
            if (a == b) continue;
            final double r = contrastRatio(
              CalmStatusStyle.resolve(t.value, a).base,
              CalmStatusStyle.resolve(t.value, b).base,
            );
            // Below the 3:1 non-text floor: colour alone cannot carry state.
            // This is documentation, not a wish — if it ever fails, the palette
            // gained real separation and this test should say so loudly.
            expect(r, lessThan(3.0),
                reason: '${t.key}: ${a.name} vs ${b.name} = '
                    '${r.toStringAsFixed(2)}:1');
          }
        }
      }
    });

    test('every state carries a unique (mark, label) pair', () {
      final Set<String> seen = <String>{};
      for (final DueState s in DueState.values) {
        final CalmStatusStyle st = CalmStatusStyle.resolve(calmColorsLight, s);
        final String key = '${st.mark}|${st.label(strings)}';
        expect(seen.add(key), isTrue, reason: 'duplicate signal pair for ${s.name}');
      }
      expect(seen.length, DueState.values.length);
    });

    test('mark geometry alone is not enough — two pairs stay too close', () {
      // Pinned defect (odova.css §12): ok == overdue, and unknown differs from
      // needsOdometer only by 0.7 opacity. When the design assigns two more
      // silhouettes this test fails — delete it and tighten the test above to
      // assert on the mark alone.
      final Map<CalmStatusMark, List<DueState>> byMark =
          <CalmStatusMark, List<DueState>>{};
      for (final DueState s in DueState.values) {
        byMark
            .putIfAbsent(
                CalmStatusStyle.resolve(calmColorsLight, s).mark, () => <DueState>[])
            .add(s);
      }
      final List<List<DueState>> collisions = byMark.values
          .where((List<DueState> g) => g.length > 1)
          .toList(growable: false);
      expect(collisions, hasLength(1));
      expect(collisions.single, <DueState>[DueState.overdue, DueState.ok]);

      // The softer collision: same diameter, same stroke, distinguished only by
      // opacity, so the grouping above does not catch it. Pin it directly.
      final CalmStatusMark u =
          CalmStatusStyle.resolve(calmColorsLight, DueState.unknown).mark;
      final CalmStatusMark n =
          CalmStatusStyle.resolve(calmColorsLight, DueState.needsOdometer).mark;
      expect(u.diameter, n.diameter);
      expect(u.strokeWidth, n.strokeWidth);
      expect(u.opacity, isNot(n.opacity));
    });

    test('the uncertain states never borrow the ok or overdue palette', () {
      for (final CalmColors c in themes.values) {
        final Set<Color> claimed = <Color>{
          for (final DueState s in <DueState>[DueState.ok, DueState.overdue])
            ...<Color>[
              CalmStatusStyle.resolve(c, s).base,
              CalmStatusStyle.resolve(c, s).ink,
              CalmStatusStyle.resolve(c, s).tint,
            ],
        };
        for (final DueState s in <DueState>[
          DueState.unknown,
          DueState.needsOdometer,
        ]) {
          final CalmStatusStyle st = CalmStatusStyle.resolve(c, s);
          expect(claimed, isNot(contains(st.base)));
          expect(claimed, isNot(contains(st.ink)));
          expect(claimed, isNot(contains(st.tint)));
          expect(st.isUncertain, isTrue);
        }
      }
    });
  });

  testWidgets('in grayscale, every state is still named and still distinct',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCalmTheme(Brightness.light),
        home: ColorFiltered(
          colorFilter: grayscale,
          child: Scaffold(
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final DueState s in DueState.values)
                  Builder(
                    builder: (BuildContext context) {
                      final CalmStatusStyle st = CalmStatusStyle.of(context, s);
                      return Row(
                        children: <Widget>[
                          CalmStatusDot(key: ValueKey<DueState>(s), style: st),
                          Text(st.label(strings)),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    for (final DueState s in DueState.values) {
      final CalmStatusStyle st = CalmStatusStyle.resolve(calmColorsLight, s);
      // Signal 2 survives the filter: the word is still there and still unique.
      expect(find.text(st.label(strings)), findsOneWidget, reason: s.name);
      // Signal 1 survives it too: geometry is not a colour.
      expect(
        tester.getSize(find.byKey(ValueKey<DueState>(s))),
        Size.square(st.mark.diameter),
        reason: s.name,
      );
    }
  });
}
