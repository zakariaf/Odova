// The locale contract of the root app widget.
//
// SPEC.md §5: six locales ship, three of them right-to-left. `ckb` is the one
// the framework does not know about — it is absent from
// GlobalMaterialLocalizations' supported set and intl's Bidi tables do not
// classify it as RTL — so it gets its own delegates, and this is the test that
// says whether they work.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/app.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

import '../support/capture_context.dart';

void main() {
  testWidgets('supportedLocales is exactly en de fr fa ar ckb', (tester) async {
    await tester.pumpWidget(const OdovaApp());

    final app = tester.widget<WidgetsApp>(find.byType(WidgetsApp));
    expect(
      app.supportedLocales.map((l) => l.toLanguageTag()).toList(),
      ['en', 'de', 'fr', 'fa', 'ar', 'ckb'],
      reason:
          'en first, so a missing key falls back to a language the '
          'maintainer can read',
    );
  });

  for (final (locale, direction) in const [
    ('en', TextDirection.ltr),
    ('de', TextDirection.ltr),
    ('fr', TextDirection.ltr),
    ('fa', TextDirection.rtl),
    ('ar', TextDirection.rtl),
    ('ckb', TextDirection.rtl),
  ]) {
    testWidgets('$locale resolves to $direction', (tester) async {
      late TextDirection resolved;
      await tester.pumpWidget(
        OdovaApp(
          locale: Locale(locale),
          home: captureContext(
            (context) => resolved = Directionality.of(context),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(resolved, direction);
    });
  }

  testWidgets('AppLocalizations.of returns non-null', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      OdovaApp(
        home: captureContext(
          (context) => l10n = AppLocalizations.of(context),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(l10n.appTitle, 'Odova');

    // `nullable-getter: false` in l10n.yaml is what makes a missing or
    // mistyped key a COMPILE error rather than a silently empty widget. The
    // assignment above only type-checks while that holds, and this asserts the
    // generated signature itself so the reason survives a regeneration.
    expect(
      File('lib/l10n/gen/app_localizations.dart').readAsStringSync(),
      contains('static AppLocalizations of(BuildContext context)'),
    );
  });
}
