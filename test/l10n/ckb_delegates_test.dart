// The three vendored `ckb` delegates.
//
// Flutter ships no Sorani, and SPEC.md §5 ships it anyway. Vendoring the
// Material half alone converts a crash into something worse: Flutter's default
// WidgetsLocalizations claims EVERY locale and hardcodes TextDirection.ltr, so
// the app reads backwards and logs nothing.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/l10n/ckb_localizations.dart';
import 'package:odova/l10n/supported_locales.dart';

import '../support/pump_app.dart';

const _ckb = Locale('ckb');

void main() {
  test('the SDK still lacks ckb', () {
    // This test exists so the vendored code is a DELIBERATE deletion the day
    // Flutter covers the locale, rather than dead code nobody dares remove.
    // It fails — correctly — when the SDK catches up, and the failure message
    // says what to do about it.
    expect(
      GlobalMaterialLocalizations.delegate.isSupported(_ckb),
      isFalse,
      reason:
          'Flutter now ships ckb: delete lib/l10n/ckb_localizations.dart '
          'and the three CkbFallbackDelegate entries in supported_locales.dart',
    );
    expect(GlobalCupertinoLocalizations.delegate.isSupported(_ckb), isFalse);
    // And so does the Widgets one, which is worth stating because the received
    // wisdom is that it claims everything. It does not — but its absence is
    // the SILENT failure rather than the loud one: with no WidgetsLocalizations
    // claiming ckb, Flutter falls back to DefaultWidgetsLocalizations, which
    // hardcodes TextDirection.ltr. Vendoring only the Material half converts a
    // crash into an app that reads backwards and logs nothing.
    expect(GlobalWidgetsLocalizations.delegate.isSupported(_ckb), isFalse);
  });

  test('each vendored delegate claims ckb and nothing else', () {
    // A delegate that claimed `ar` would shadow a locale the SDK does ship,
    // and Arabic would silently render Persian chrome.
    for (final delegate in [
      const CkbFallbackDelegate<WidgetsLocalizations>(
        GlobalWidgetsLocalizations.delegate,
      ),
      const CkbFallbackDelegate<MaterialLocalizations>(
        GlobalMaterialLocalizations.delegate,
      ),
      const CkbFallbackDelegate<CupertinoLocalizations>(
        GlobalCupertinoLocalizations.delegate,
      ),
    ]) {
      expect(delegate.isSupported(_ckb), isTrue);
      for (final other in ['en', 'de', 'fr', 'fa', 'ar', 'ku', 'kmr']) {
        expect(
          delegate.isSupported(Locale(other)),
          isFalse,
          reason: '$delegate claims $other',
        );
      }
    }
  });

  test('the vendored delegates sit ahead of the Global ones, per type', () {
    // `Localizations._loadAll` takes the FIRST delegate of a type that claims
    // the locale. Ordering is the whole mechanism, and a vendored delegate
    // appended after the Global* spread is a delegate that never runs.
    for (final type in [
      WidgetsLocalizations,
      MaterialLocalizations,
      CupertinoLocalizations,
    ]) {
      final first = odovaLocalizationsDelegates.firstWhere(
        (d) => d.type == type,
      );
      expect(
        first,
        isA<CkbFallbackDelegate<Object>>(),
        reason: 'the first $type delegate is not the vendored one',
      );
    }
  });

  test('each vendored delegate reports its own type, not Object', () {
    // The failure this catches has no symptom at the call site. In a list
    // typed `<LocalizationsDelegate<Object>>`, inference resolves T to Object
    // from the context, so all three report `Object` for `type` — and
    // Localizations, which keys the loaded value on exactly that, loads only
    // the first and ckb falls back to English with a warning nobody reads.
    final types = odovaLocalizationsDelegates
        .whereType<CkbFallbackDelegate<Object>>()
        .map((d) => d.type)
        .toList();

    expect(types, hasLength(3));
    expect(types.toSet(), hasLength(3), reason: 'two delegates share a type');
    expect(types, isNot(contains(Object)));
  });

  testWidgets('a MaterialLocalizations string resolves under ckb', (
    tester,
  ) async {
    late MaterialLocalizations material;
    await pumpApp(
      tester,
      Builder(
        builder: (context) {
          material = MaterialLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
      locale: _ckb,
    );

    // The borrowed Persian string, not English chrome and not a throw. Named
    // as a compromise here rather than discovered in a screenshot later.
    final persian = await GlobalMaterialLocalizations.delegate.load(
      const Locale('fa'),
    );
    expect(material.okButtonLabel, persian.okButtonLabel);
  });

  testWidgets('a Tooltip under ckb does not assert', (tester) async {
    // The loud failure, pinned. Tooltip reaches for
    // MaterialLocalizations.of(context) and asserts if nothing supplied it.
    await pumpApp(
      tester,
      const Center(
        child: Tooltip(message: 'وردەکاری', child: Icon(Icons.info_outline)),
      ),
      locale: _ckb,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Tooltip), findsOneWidget);
  });

  testWidgets('ckb lays out right-to-left, which is the silent one', (
    tester,
  ) async {
    late TextDirection direction;
    await pumpApp(
      tester,
      Builder(
        builder: (context) {
          direction = Directionality.of(context);
          return const SizedBox.shrink();
        },
      ),
      locale: _ckb,
    );

    // Vendoring only the Material half converts a crash into an app that reads
    // backwards and logs nothing at all.
    expect(direction, TextDirection.rtl);
  });
}
