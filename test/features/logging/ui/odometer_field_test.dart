// The odometer field as the user meets it, on all three forms that carry it.
//
// SPEC.md §10. The RULES are `odometer_rules_test.dart`'s; what is asserted
// here is what the widget draws over them — the helper line, the estimate chip
// that is never a default, the live delta, and the unit chip that changes this
// entry and leaves the vehicle alone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/logging/ui/odometer_field.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_field.dart';

import '../../../support/pump_app.dart';

ReadingPoint _reading(String on, int km) => (
  id: 'odo_$on',
  occurredOn: on,
  createdAtUtcMs: 1000,
  odometer: Distance.fromKm(km),
);

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(OdometerField)));

CalmField _field(WidgetTester tester) =>
    tester.widget<CalmField>(find.byType(CalmField));

/// Mounts the field with a history behind it.
Future<TextEditingController> _pump(
  WidgetTester tester, {
  List<ReadingPoint> existing = const [],
  Distance? estimate,
  int estimateStaleDays = 0,
  DistanceUnit unit = DistanceUnit.km,
  String occurredOn = '2026-09-02',
  String text = '',
  void Function(DistanceUnit)? onUnitChanged,
  Locale? locale = const Locale('en'),
}) async {
  final controller = TextEditingController(text: text);
  addTearDown(controller.dispose);

  await pumpApp(
    tester,
    StatefulBuilder(
      builder: (context, setState) => OdometerField(
        controller: controller,
        unit: unit,
        existing: existing,
        corrections: const [],
        occurredOn: occurredOn,
        formatsTag: 'en',
        estimate: estimate,
        estimateStaleDays: estimateStaleDays,
        onChanged: (_) => setState(() {}),
        onUnitChanged: onUnitChanged ?? (_) {},
      ),
    ),
    locale: locale,
  );
  return controller;
}

void main() {
  testWidgets('is never prefilled from an estimate', (tester) async {
    // §10: "An estimate that arrives as a default gets saved unread; one that
    // takes a tap was chosen." This is the whole design of the field.
    final controller = await _pump(
      tester,
      existing: [_reading('2026-03-12', 186980)],
      estimate: const Distance.fromKm(187700),
    );

    expect(controller.text, isEmpty);
    expect(
      find.byKey(kOdometerEstimateChipKey),
      findsOneWidget,
      reason: 'the projection is OFFERED, never filled in',
    );
  });

  testWidgets('the helper line names the last ENTERED reading and its date', (
    tester,
  ) async {
    await _pump(tester, existing: [_reading('2026-03-12', 186980)]);

    // The helper line is the field's `hint`, not a sibling Text.
    final hint = _field(tester).hint;
    expect(hint, contains('186,980'));
    expect(hint, contains('March'));
  });

  testWidgets('tapping the estimate chip fills the field', (tester) async {
    final controller = await _pump(
      tester,
      existing: [_reading('2026-03-12', 186980)],
      estimate: const Distance.fromKm(187700),
    );

    await tester.tap(find.byKey(kOdometerEstimateChipKey));
    await tester.pumpAndSettle();

    // The ENTERED value, in the field's own unit and with no `~` — once it is
    // in the field it is a number the user has accepted, not an estimate.
    expect(controller.text, '187700');
  });

  testWidgets('no estimate chip when the last reading is over 60 days old', (
    tester,
  ) async {
    // §10: "A 174-day-old estimate offered as a default would launder itself
    // into a fact." The helper line names the age instead.
    await _pump(
      tester,
      existing: [_reading('2026-03-12', 186980)],
      estimate: const Distance.fromKm(187700),
      estimateStaleDays: 174,
    );

    expect(find.byKey(kOdometerEstimateChipKey), findsNothing);
    expect(_field(tester).hint, contains('174'));
  });

  testWidgets('the live delta appears once a value is entered', (tester) async {
    // §10 calls it "the cheapest possible check on a dropped digit".
    await _pump(
      tester,
      existing: [_reading('2026-03-12', 186980)],
      text: '187412',
    );

    expect(find.textContaining('432'), findsWidgets);
  });

  testWidgets('no prior reading renders no helper line, chip or delta', (
    tester,
  ) async {
    // §10's "No prior reading (imported vehicle)": the field is simply
    // required. This is the anchor the whole app hangs from.
    await _pump(tester, text: '187412');

    expect(find.byKey(kOdometerEstimateChipKey), findsNothing);
    expect(_field(tester).hint, isNull);
  });

  testWidgets('a below-last value is not drawn as an inline error', (
    tester,
  ) async {
    // §10: the three-way sheet owns this, never a bare error under the field.
    // A message here would be the app asking the user to guess which of the
    // three answers it meant.
    await _pump(
      tester,
      existing: [_reading('2026-03-12', 186980)],
      text: '186000',
    );

    expect(_field(tester).errorText, isNull);
  });

  testWidgets('a soft warning is shown and does not block', (tester) async {
    // 3,020 km the DAY after the last reading — §10's "over 2,000 km a day"
    // warning. Amber, and it saves anyway: a delivery driver really does do
    // 2,400 km in a day, and the app is not entitled to refuse it.
    await _pump(
      tester,
      existing: [_reading('2026-03-12', 186980)],
      occurredOn: '2026-03-13',
      text: '190000',
    );

    // Shown as the field's message, and the value is still usable — §10's
    // amber line saves anyway.
    expect(_field(tester).errorText, isNotNull);
  });

  testWidgets('a backdated reading says it becomes the earliest', (
    tester,
  ) async {
    await _pump(
      tester,
      existing: [_reading('2026-03-12', 186980)],
      occurredOn: '2019-05-01',
      text: '96000',
    );

    expect(
      find.text(_l10n(tester).logOdometerOlderThanAnything),
      findsOneWidget,
    );
  });

  testWidgets('the unit chip changes this entry only', (tester) async {
    // §10: "A garage that fits a kilometre cluster to a miles car is logged
    // without re-rendering eight years of history." The callback carries the
    // new unit; nothing here touches the vehicle.
    DistanceUnit? asked;
    await _pump(tester, onUnitChanged: (u) => asked = u);

    await tester.tap(find.byKey(kOdometerUnitChipKey));
    await tester.pumpAndSettle();

    expect(asked, DistanceUnit.mi);
  });
}
