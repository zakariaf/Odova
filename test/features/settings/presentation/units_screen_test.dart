// SPEC.md §13's `settings.units` — the screen that makes the Persian build
// real.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/notifications/schedule_rebuilder.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/settings_repository.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';
import 'package:odova/features/settings/presentation/units_labels.dart';
import 'package:odova/features/settings/presentation/units_screen.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/ui/calm/calm_sheet.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../data/support/test_ids.dart';
import '../../../support/device.dart';
import '../../home/home_fixture.dart';

class _CountingRebuilder implements ScheduleRebuilder {
  int calls = 0;

  @override
  Future<void> rebuildAll() async => calls++;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(UnitsScreen)));

late AppDatabase _db;
late _CountingRebuilder _rebuilder;

Future<void> _pump(
  WidgetTester tester, {
  Locale? locale = const Locale('en'),
}) async {
  tester.useDevice(Device.tallForm);
  _db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(_db.close);
  // A real row for each thing the shell reads at launch. `liveStreams: true`
  // means the app reads the DATABASE rather than the harness's fixed values,
  // and a database with no vehicle sends the router somewhere else entirely —
  // the first version of this test asserted against a degraded-mode screen.
  await SettingsRepository(
    _db,
  ).save(homeSettings(golfId, language: locale?.languageCode ?? 'system'));
  await VehicleRepository(_db, testIds()).save(homeVehicle(golfId, 'The Golf'));
  _rebuilder = _CountingRebuilder();

  await pumpShell(
    tester,
    Routes.settingsUnits,
    locale: locale,
    liveStreams: true,
    settings: homeSettings(golfId),
    vehicles: [homeVehicle(golfId, 'The Golf')],
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(_db),
      scheduleRebuilderProvider.overrideWithValue(_rebuilder),
      // The DEVICE locale too, not just the app's. `pumpShell`'s `locale:`
      // goes straight to `OdovaApp` and bypasses `localeControllerProvider`,
      // so the screen renders Persian while the resolved tags still say
      // `en-US` — and the numerals row, which depends on the resolved tags,
      // silently offered the English options under a Persian screen. A phone
      // set to Persian is the user §13's preview example describes anyway.
      if (locale != null) deviceLocalesProvider.overrideWithValue([locale]),
    ],
  );
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String row, String option) async {
  await tester.tap(find.text(row));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<ConsumptionUnit?> _storedConsumption() async {
  final read = await SettingsRepository(_db).read();
  return read is Ok<AppSettings, PersistFailure>
      ? read.value.consumptionUnit
      : null;
}

void main() {
  testWidgets('the preview sits above both groups, in two lines', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.text(l10n.unitsPreviewLabel), findsOneWidget);
    expect(find.textContaining('187,412'), findsOneWidget);
    expect(find.textContaining('6.4'), findsOneWidget);
    expect(find.text(l10n.unitsGroupMeasurement), findsOneWidget);
    expect(find.text(l10n.unitsGroupDatesNumbers), findsOneWidget);
  });

  testWidgets('changing distance updates the preview', (tester) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    await _choose(tester, l10n.unitsRowDistance, l10n.unitsDistanceMi);
    // 187,412 km is 116,452 miles. The preview is the only place a user can
    // check that before their whole history changes unit.
    expect(find.textContaining('116,452'), findsOneWidget);
    expect(find.textContaining('187,412'), findsNothing);
  });

  testWidgets('the calendar offers exactly two', (tester) async {
    // §5 ships one alternative, not a catalogue. `hijri` is not a storable
    // value in v1 and a third row would be one nobody has checked a date
    // against.
    await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.unitsRowCalendar));
    await tester.pumpAndSettle();

    expect(find.byType(CalmSheet), findsOneWidget);
    // `findsWidgets`, because the row's VALUE says Gregorian too — which is
    // the point of the row.
    expect(find.text(l10n.unitsCalendarGregorian), findsWidgets);
    expect(find.text(l10n.unitsCalendarPersian), findsOneWidget);
    expect(CalmCalendar.values, hasLength(2));
  });

  testWidgets('numerals offers no Local row in English', (tester) async {
    // A German or English user offered a "Local" row that renders the same
    // digits as the row above it is being asked a question with one answer.
    await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.unitsRowNumerals));
    await tester.pumpAndSettle();

    expect(find.text(l10n.unitsNumeralsAuto), findsWidgets);
    expect(find.textContaining('Local'), findsNothing);
  });

  testWidgets('numerals offers a Local row in Persian, with a sample', (
    tester,
  ) async {
    // And the sample answers the question the row asks: `محلی (۰–۹)` shows
    // what choosing it does without applying it first.
    await _pump(tester, locale: const Locale('fa'));
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.unitsRowNumerals));
    await tester.pumpAndSettle();

    expect(find.textContaining('محلی'), findsOneWidget);
    expect(find.textContaining('۰–۹'), findsOneWidget);
  });

  testWidgets('choosing miles and US gallons suggests mpg', (tester) async {
    // §13 fills the row in rather than asking: leaving `L/100 km` selected
    // under miles and gallons produces a figure that is not wrong so much as
    // meaningless.
    await _pump(tester);
    final l10n = _l10n(tester);

    await _choose(tester, l10n.unitsRowDistance, l10n.unitsDistanceMi);
    await _choose(tester, l10n.unitsRowVolume, l10n.unitsVolumeGalUs);

    expect(await _storedConsumption(), ConsumptionUnit.mpgUs);
  });

  testWidgets('an explicit choice survives, whatever route gets there', (
    tester,
  ) async {
    // A rideshare driver in the US who prefers `km/L` picked it on purpose.
    // And the ROUTE matters: switching volume first leaves a pairing that
    // implies nothing, which the previous rule read as "not chosen" and used
    // to overwrite the choice on the very next tap.
    await _pump(tester);
    final l10n = _l10n(tester);

    await _choose(
      tester,
      l10n.unitsRowConsumption,
      l10n.unitConsumptionKmPerLitre,
    );
    await _choose(tester, l10n.unitsRowVolume, l10n.unitsVolumeGalUs);
    await _choose(tester, l10n.unitsRowDistance, l10n.unitsDistanceMi);

    expect(await _storedConsumption(), ConsumptionUnit.kmPerL);
  });

  testWidgets(
    'currency opens a sheet, and the footer says what it does not do',
    (
      tester,
    ) async {
      await _pump(tester);
      final l10n = _l10n(tester);

      // The footer is on the SCREEN too, before the tap: somebody hesitating
      // over this row needs to know their history is not converted while they
      // are still deciding.
      expect(find.text(l10n.unitsFooter), findsOneWidget);

      await tester.tap(find.text(l10n.unitsRowCurrency));
      await tester.pumpAndSettle();

      expect(find.byType(CalmSheet), findsOneWidget);
      // Still on `settings.units`: a sheet, not a push. §7 allows no branch in
      // this app three levels deep.
      expect(find.byType(UnitsScreen), findsOneWidget);
    },
  );

  testWidgets('changing a unit reschedules notifications', (tester) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    await _choose(tester, l10n.unitsRowDistance, l10n.unitsDistanceMi);

    expect(_rebuilder.calls, greaterThanOrEqualTo(1));
  });

  testWidgets('it mirrors without overflowing', (tester) async {
    await _pump(tester, locale: const Locale('fa'));

    expect(
      Directionality.of(tester.element(find.byType(UnitsScreen))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a suggested unit says it was suggested', (tester) async {
    // `unitsConsumptionSuggested` was translated into all six ARB files and
    // rendered by nothing, while the row changed under the user's hand. Its
    // own ARB description names the failure: "a value that changed without
    // being touched reads as a bug".
    await _pump(tester);
    final l10n = _l10n(tester);

    await _choose(tester, l10n.unitsRowDistance, l10n.unitsDistanceMi);
    await _choose(tester, l10n.unitsRowVolume, l10n.unitsVolumeGalUs);

    expect(
      find.text(
        l10n.unitsConsumptionSuggested(
          l10n.unitsDistanceMi,
          l10n.unitsVolumeGalUs,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('each consumption unit has its own name', (tester) async {
    // Four of the six rendered `mpg`, so a user who picked `km/L` read
    // `6.4 mpg` here and `6.4 km/L` on Home for one stored value — off by the
    // 2.35 between them — and US versus imperial gallons, a 17% difference,
    // was unpickable.
    await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.unitsRowConsumption));
    await tester.pumpAndSettle();

    final labels = {
      for (final unit in ConsumptionUnit.values)
        consumptionOptionLabel(l10n, unit, '100'),
    };
    expect(labels, hasLength(ConsumptionUnit.values.length));
  });

  testWidgets('the first day of week offers Saturday', (tester) async {
    // `calendar.dart` seeds Saturday for twelve regions and §5's table gives
    // it for `fa`, `ar` and `ckb`. With Monday and Sunday alone, an Iranian
    // user opened a row reading `شنبه`, found neither option ticked, and
    // could not set it back whatever they tapped.
    await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.unitsRowFirstDay));
    await tester.pumpAndSettle();

    expect(find.text(weekdayName('en-GB', DateTime.saturday)), findsOneWidget);
    expect(find.text(weekdayName('en-GB', DateTime.sunday)), findsOneWidget);
    expect(find.text(weekdayName('en-GB', DateTime.monday)), findsWidgets);
  });
}
