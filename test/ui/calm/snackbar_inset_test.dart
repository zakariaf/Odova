// The confirmation is not hidden behind the tab bar.
//
// SPEC.md §9 puts a persistent tab bar at the bottom of every shell screen, and
// §10's save ends in a snackbar with an Undo in it. The snackbar was laid out
// against the raw viewport, so on a shell screen it came up UNDER the bar —
// message clipped, Undo unreachable. A person saved a fill-up, saw a sliver of
// text below the tabs, and could not undo it.
//
// The `log.*` modal is the awkward case and the reason `overTabBar` exists as
// an override rather than a lookup. The modal is a root-navigator route with no
// tab bar under it, so the context says "no bar" truthfully — and then the
// modal POPS on save and the snackbar appears over the shell, where there is
// one. What the context can see is not where the snackbar will be drawn.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

import '../../support/pump_app.dart';

/// The inset the host would use, read from a context under [hasTabBar].
Future<({double inset, double tabbarH, double safeBottom})> _read(
  WidgetTester tester, {
  required bool hasTabBar,
  bool? overTabBar,
  double safeBottom = 0,
}) async {
  late double inset;
  late double tabbarH;
  await pumpApp(
    tester,
    Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(padding: EdgeInsets.only(bottom: safeBottom)),
        child: CalmChromeScope(
          hasTabBar: hasTabBar,
          child: Builder(
            builder: (inner) {
              inset = calmSnackbarBottomInset(inner, overTabBar: overTabBar);
              tabbarH = CalmSpace.of(inner).tabbarH;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  return (inset: inset, tabbarH: tabbarH, safeBottom: safeBottom);
}

void main() {
  testWidgets('on a shell screen it clears the whole bar', (tester) async {
    final r = await _read(tester, hasTabBar: true, safeBottom: 34);
    expect(
      r.inset,
      greaterThanOrEqualTo(r.tabbarH + 34),
      reason: 'the snackbar overlaps the tab bar and Undo cannot be tapped',
    );
  });

  testWidgets('with no bar it sits just above the safe area', (tester) async {
    // The other direction, and the one a blanket `+ tabbarH` would break: a
    // full-screen route has no bar, and a snackbar floating 56pt up on it is
    // as wrong as one hidden behind a bar that is there.
    final r = await _read(tester, hasTabBar: false, safeBottom: 34);
    expect(r.inset, lessThan(r.tabbarH));
    expect(r.inset, greaterThanOrEqualTo(34));
  });

  testWidgets('a caller can override what the context can see', (tester) async {
    // The `log.*` modal's case. It has no bar under it and knows the snackbar
    // will land on the shell that does.
    final under = await _read(tester, hasTabBar: false, overTabBar: true);
    final plain = await _read(tester, hasTabBar: false);
    expect(under.inset - plain.inset, under.tabbarH);
  });
}
