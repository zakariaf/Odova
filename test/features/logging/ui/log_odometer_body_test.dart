// The fastest entry in the app: two fields, the keypad up.
//
// SPEC.md §10 `log.odometer`: "Two fields. No notes, no category, no More
// section — this screen exists to be finished before the user changes their
// mind; one more optional field would be a net loss."
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/logging/ui/log_odometer_body.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_disclosure.dart';
import 'package:odova/ui/calm/calm_number_pad.dart';
import 'package:odova/ui/calm/calm_row_group.dart';

import '../../../support/device.dart';
import '../../../support/pump_app.dart';

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(LogOdometerBody)));

Future<void> _pump(
  WidgetTester tester, {
  String value = '',
  Distance? lastReading,
  String? lastReadingOn,
  Locale? locale = const Locale('en'),
}) async {
  // A phone-shaped viewport: `CalmNumberPad` is five rows of 68pt plus its
  // display, which does not fit the 800x600 the harness defaults to.
  tester.useDevice(Device.tallForm);
  await pumpApp(
    tester,
    _Host(
      initial: value,
      lastReading: lastReading,
      lastReadingOn: lastReadingOn,
    ),
    locale: locale,
  );
}

class _Host extends StatefulWidget {
  const _Host({required this.initial, this.lastReading, this.lastReadingOn});
  final String initial;
  final Distance? lastReading;
  final String? lastReadingOn;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String _value = widget.initial;

  @override
  Widget build(BuildContext context) => LogOdometerBody(
    value: _value,
    unit: DistanceUnit.km,
    formatsTag: 'en',
    occurredOn: '2026-09-02',
    onPickDate: () {},
    lastReading: widget.lastReading,
    lastReadingOn: widget.lastReadingOn,
    onValueChanged: (v) => setState(() => _value = v),
    onSave: () {},
  );
}

void main() {
  testWidgets('renders two fields and nothing else', (tester) async {
    // §10 names the whole screen: an odometer and a date. No More section
    // exists to be opened.
    await _pump(tester);

    expect(find.byType(CalmNumberPad), findsOneWidget);
    expect(find.byType(CalmDisclosure), findsNothing);
  });

  testWidgets('a digit key appends to the value', (tester) async {
    // The pad is stateless and reports ASCII whatever glyph it drew — the
    // caller owns the buffer.
    await _pump(tester);

    // Pumped BETWEEN taps: the key's callback closes over the buffer from the
    // build that drew it, so two taps without a rebuild in between both append
    // to the same empty string.
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();

    final pad = tester.widget<CalmNumberPad>(find.byType(CalmNumberPad));
    expect(pad.value, '18');
  });

  testWidgets('Clear empties the value rather than deleting one digit', (
    tester,
  ) async {
    await _pump(tester, value: '187412');

    await tester.tap(find.text(_l10n(tester).logOdometerPadClear));
    await tester.pumpAndSettle();

    expect(
      tester.widget<CalmNumberPad>(find.byType(CalmNumberPad)).value,
      isEmpty,
    );
  });

  testWidgets('the value is grouped for reading, not for editing', (
    tester,
  ) async {
    // The pad renders a string and does no arithmetic, so the grouping is the
    // caller's job — and a six-digit odometer is unreadable without it.
    await _pump(tester, value: '187412');

    expect(
      tester.widget<CalmNumberPad>(find.byType(CalmNumberPad)).value,
      '187,412',
    );
  });

  testWidgets('the delta rides in the pad hint', (tester) async {
    // §10 puts `+432 km since 12 Mar` above the keypad, where the number being
    // typed is — it is the cheapest possible check on a dropped digit.
    await _pump(
      tester,
      value: '187412',
      lastReading: const Distance.fromKm(186980),
      lastReadingOn: '2026-03-12',
    );

    final pad = tester.widget<CalmNumberPad>(find.byType(CalmNumberPad));
    expect(pad.hint, contains('432'));
  });

  testWidgets('the first reading of a vehicle has no hint at all', (
    tester,
  ) async {
    // §10: "First reading of a vehicle's life — no helper line, no delta, just
    // the field. This is the anchor the whole app hangs from."
    await _pump(tester, value: '187412');

    expect(
      tester.widget<CalmNumberPad>(find.byType(CalmNumberPad)).hint,
      isEmpty,
    );
  });

  testWidgets('the decimal key is Clear, because there is no decimal', (
    tester,
  ) async {
    // §10's Field kit: "Odometer — number pad, no decimal." A dash reads whole
    // units and a separator there is a mis-parse on its way to a column. The
    // artboard puts Clear in that key rather than leaving a dead one, so the
    // assertion is that the key is not a SEPARATOR — not that it is empty.
    await _pump(tester);

    final pad = tester.widget<CalmNumberPad>(find.byType(CalmNumberPad));
    expect(pad.decimalLabel, isNot(anyOf('.', ',', '٫')));
    expect(pad.decimalLabel, _l10n(tester).logOdometerPadClear);
  });

  testWidgets('the date is a KEY on the pad, not a row above it', (
    tester,
  ) async {
    // §10 gives this screen two fields and nothing else: "one more optional
    // field would be a net loss." The date sits beside Save, at its shortest,
    // where it can be changed without leaving the keypad.
    await _pump(tester);

    final pad = tester.widget<CalmNumberPad>(find.byType(CalmNumberPad));
    expect(pad.secondaryLabel, contains('Sep'));
    expect(find.byType(CalmRowGroup), findsNothing);
  });
}
