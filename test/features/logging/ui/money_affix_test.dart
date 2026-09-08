// Every money field says which money it is in.
//
// SPEC.md §2 stores money as minor units plus an ISO 4217 code, and §10's
// artboard draws the symbol on `log.fillup`'s Price/L and Total, on
// `log.service`'s Cost and on `log.expense`'s Amount. The app drew one on none
// of them: the litre field had its `L` and every money field shipped as a bare
// number, so a figure typed into Cost said nothing about which of the
// currencies this app holds it was in.
//
// It matters more here than in most apps. A household with two currencies is a
// case this project has already been bitten by, and §2 forbids summing across
// them — a number with no symbol is the input side of that mistake.
//
// The symbol comes from the ACTIVE currency and not a constant:
// `currencySymbolFor` reads the settings' code, so a store in USD draws `$`.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/ui/calm/calm_field.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../support/device.dart';
import '../../home/home_fixture.dart';

/// The affix strings on every field of the screen, in order.
List<String> _affixes(WidgetTester tester) => [
  for (final field in tester.widgetList<CalmField>(find.byType(CalmField)))
    if (field.affix case final Text text) text.data ?? '',
];

Future<void> _pump(WidgetTester tester, LogType type, {String? code}) async {
  tester.useDevice(Device.tallForm);
  await pumpShell(
    tester,
    Routes.log(type),
    settings: homeSettings(golfId, currency: code ?? 'EUR'),
    vehicles: [homeVehicle(golfId, 'The Golf')],
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the fill-up trio marks its two money fields', (tester) async {
    await _pump(tester, LogType.fillUp);
    // Odometer `km`, litres `L`, then Price/L and Total in euro.
    expect(_affixes(tester), containsAll(<String>['€', '€']));
  });

  testWidgets('service Cost and expense Amount carry it too', (tester) async {
    await _pump(tester, LogType.service);
    expect(_affixes(tester), contains('€'));

    await _pump(tester, LogType.expense);
    expect(_affixes(tester), contains('€'));
  });

  testWidgets('and it follows the stored currency, not a constant', (
    tester,
  ) async {
    // The assertion that stops `'€'` being hard-coded. A test that only ever
    // pumps a euro store passes against a literal, and this app ships to six
    // locales across three scripts.
    // All three bodies, because each passes `moneySymbol` at its own call
    // site: a mutation that hard-codes euro on one of them is invisible to a
    // test that only pumps another.
    for (final type in [LogType.fillUp, LogType.service, LogType.expense]) {
      await _pump(tester, type, code: 'USD');
      expect(_affixes(tester), contains(r'$'), reason: type.name);
      expect(_affixes(tester), isNot(contains('€')), reason: type.name);
    }
  });
}
