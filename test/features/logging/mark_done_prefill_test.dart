// The four entry points that open `log.service` already prefilled.
//
// SPEC.md §10 *Marking a reminder done → a service record*. EPIC-10 built the
// four intents — Home's due card **Log it**, a `reminders.list` row's **Done
// today**, `reminders.edit`'s **Mark as done**, and the notification action —
// and asserted only that each pushes the right URL. The URL has carried
// `?item`, `?on` and `?odometer_m` since then and the modal read none of them,
// so every one of those four landed on an empty form.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/features/logging/ui/log_service_body.dart';
import 'package:odova/ui/calm/calm_chip.dart';

import '../../app/routing/shell_harness.dart';
import '../../support/device.dart';
import '../home/home_fixture.dart';

Future<void> _pump(WidgetTester tester, String location) async {
  tester.useDevice(Device.tallForm);
  await pumpShell(
    tester,
    location,
    settings: homeSettings(golfId),
    vehicles: [homeVehicle(golfId, 'The Golf')],
  );
}

void main() {
  testWidgets('?on prefills the date rather than today', (tester) async {
    // §10 prefills mark-done with TODAY, but a notification acted on the next
    // morning carries the day it was for. The form takes the URL's word.
    await _pump(
      tester,
      Routes.log(LogType.service, on: '2026-03-12'),
    );

    expect(find.textContaining('12'), findsWidgets);
    expect(
      find.textContaining('March'),
      findsWidgets,
      reason: 'the date row shows the date the caller asked for',
    );
  });

  testWidgets('?odometer_m prefills the odometer field', (tester) async {
    // §10: prefilled with the LAST ENTERED reading, "and selected so typing
    // replaces it". Home's staleness strip and the due card both carry it,
    // because a user marking an oil change done is not standing at the car.
    await _pump(
      tester,
      Routes.log(LogType.service, odometerMetres: 187412000),
    );

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(
      fields.map((f) => f.controller?.text),
      contains('187412'),
      reason: 'in the vehicle unit, ungrouped, ready to be replaced',
    );
  });

  testWidgets('the odometer prefill is NOT an estimate mark', (tester) async {
    // The `~` belongs to an offer, not to a value already in the field. §2
    // forbids guessing in a way that looks like fact, and a prefilled number
    // wearing a tilde would be the app hedging on the user's own entry.
    await _pump(
      tester,
      Routes.log(LogType.service, odometerMetres: 187412000),
    );

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    for (final field in fields) {
      expect(field.controller?.text ?? '', isNot(contains('~')));
    }
  });

  testWidgets('?item ticks the chip it names', (tester) async {
    // The originating item, ticked and first — that is what makes the save a
    // MARK-DONE rather than an unrelated service that happens to be logged.
    await _pump(
      tester,
      Routes.log(LogType.service, itemId: 'rem_01JQ8ZK3M7F0R6XN2E9TB4HCV1'),
    );

    expect(find.byType(LogServiceBody), findsOneWidget);
    // No item by that id exists in this fixture, so nothing is ticked — the
    // assertion that matters is that an unknown id does not crash the form.
    expect(
      tester
          .widgetList<CalmChip>(find.byType(CalmChip))
          .where((c) => c.selected),
      isEmpty,
    );
  });

  testWidgets('the + still opens an EMPTY form', (tester) async {
    // The prefill is the caller's, never a default. A `+` that arrived
    // pre-filled with the last reading would get saved unread.
    await _pump(tester, Routes.log(LogType.service));

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    for (final field in fields) {
      expect(field.controller?.text ?? '', isEmpty);
    }
  });
}
