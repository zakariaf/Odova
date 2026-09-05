// `reminders.edit` — the one place a reminder's rules are set.
//
// SPEC.md §9's field table, *Validation*, *Last done*, *Delete* and *States*.
// The RULES are `reminder_draft_test.dart`'s, at their boundaries and without a
// widget; this is what the form does with them — which fields exist, when the
// messages appear, and what Save writes.
//
// The writes go to a real in-memory row, because "the screen called a method"
// and "the item is off" are different claims.
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/data/repositories/service_repository.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../support/device.dart';
import '../../../support/fonts.dart';
import '../../home/home_fixture.dart';

const _oilId = 'rem_01JQ8ZK3M7F0R6XN2E9TB4HCVA';

/// Mounts the editor on [id], with a real database behind it.
Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required AppDatabase db,
  String id = _oilId,
  List<OdometerReading> readings = const [],
  List<ServiceRecord> records = const [],
  Locale? locale = const Locale('en'),
  TextScaler? textScaler,
}) => pumpShell(
  tester,
  Routes.reminderEdit(id),
  locale: locale,
  settings: homeSettings(golfId),
  vehicles: [homeVehicle(golfId, 'The Golf')],
  wrap: textScaler == null
      ? null
      : (app) => Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: app,
          ),
        ),
  overrides: <Override>[
    appDatabaseProvider.overrideWithValue(db),
    clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026, 9, 5, 12))),
    odometerReadingsProvider(
      golfId,
    ).overrideWith((ref) => Stream.value(readings)),
    serviceRecordsProvider(
      golfId,
    ).overrideWith((ref) => Stream.value(records)),
  ],
);

/// The item every edit case starts from: a real 10,000 km / 12-month reminder.
ServiceItem _oil({String label = 'Oil and filter'}) => ServiceItem(
  id: ServiceItemId.tryParse(_oilId)!,
  vehicleId: golfId,
  kind: ServiceKind.custom,
  label: label,
  priority: ServicePriority.normal,
  rollover: ServiceRollover.fromActual,
  intervalDistance: const Distance.fromKm(10000),
  intervalDistanceUnit: DistanceUnit.km,
  intervalMonths: 12,
  isTracked: true,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

Future<AppDatabase> _seeded(ServiceItem item) async {
  final db = homeDatabase();
  await seedItems(db, [item]);
  return db;
}

CalmField _field(WidgetTester tester, String label) => tester
    .widgetList<CalmField>(find.byType(CalmField))
    .firstWhere((f) => f.label == label);

/// Types into the field whose label is [label].
///
/// Through the EDITABLE inside it, not the `CalmField` itself: `enterText`
/// needs an `EditableText`, and a finder that lands on the wrapper reports "no
/// element" rather than saying so.
Future<void> _type(
  WidgetTester tester,
  String label,
  String text,
) async {
  await tester.enterText(
    find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is CalmField && w.label == label,
        description: label,
      ),
      matching: find.byType(EditableText),
    ),
    text,
  );
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('renders every field of §9 table', (tester) async {
    // A TALL surface. `CalmScaffold`'s body is a `ListView`, so a field below
    // the fold is not built and no finder can see it — and this test is about
    // the fields existing, not about where they land. The layout at a real
    // width is asserted by the German-at-200% case below.
    tester.useDevice(Device.tallForm);
    final db = await _seeded(_oil());
    await _pump(tester, db: db);

    final l10n = l10nOf(tester);
    for (final label in [
      l10n.reminderName,
      l10n.reminderEveryDistance,
      l10n.reminderEveryMonths,
      l10n.reminderOnceAtOdometer,
      l10n.reminderOnceOnDate,
      l10n.reminderLastDoneDate,
      l10n.reminderLastDoneOdometer,
      l10n.reminderNotes,
    ]) {
      expect(
        find.byWidgetPredicate((w) => w is CalmField && w.label == label),
        findsWidgets,
        reason: label,
      );
    }
    // The two switches, the two segmented controls and the notice pair.
    expect(find.text(l10n.reminderNotify), findsOneWidget);
    expect(find.text(l10n.reminderRepeats), findsOneWidget);
    expect(find.text(l10n.reminderPriority), findsOneWidget);
    expect(find.text(l10n.reminderRollover), findsOneWidget);
    expect(find.text(l10n.reminderNoticeAhead), findsOneWidget);
  });

  testWidgets('save is never disabled, and pressing it surfaces the error', (
    tester,
  ) async {
    // §9: "Save is never silently disabled." An empty form's Save is LIVE, and
    // pressing it is what produces the sentence.
    final db = await _seeded(_oil());
    await _pump(tester, db: db, id: 'new');

    final bar = tester.widget<CalmAppBar>(find.byType(CalmAppBar));
    expect(bar.onEnd, isNotNull, reason: '§9: never silently disabled');
    expect(
      find.text(
        "Set an interval or a target date — otherwise there's nothing to "
        'remind you about.',
      ),
      findsNothing,
      reason: 'a form that scolds before you have typed is angry at you',
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Set an interval or a target date — otherwise there's nothing to "
        'remind you about.',
      ),
      findsOneWidget,
    );
    // And NOTHING was written: a refused Save leaves the modal open on the
    // message the user has to read.
    expect(await db.select(db.serviceItems).get(), hasLength(1));
  });

  testWidgets(
    'a baseline odometer below the first reading is rejected inline',
    (
      tester,
    ) async {
      tester.useDevice(Device.tallForm);
      final db = await _seeded(_oil());
      await _pump(
        tester,
        db: db,
        readings: [
          OdometerReading(
            id: OdometerReadingId.tryParse(
              'odo_01JQ8ZK3M7F0R6XN2E9TB4HCVA',
            )!,
            vehicleId: golfId,
            occurredOn: '2026-01-01',
            odometer: const Distance.fromKm(100000),
            odometerUnit: DistanceUnit.km,
            source: OdometerSource.manual,
            createdAtUtcMs: 1000,
            updatedAtUtcMs: 1000,
          ),
        ],
      );

      await _type(tester, l10nOf(tester).reminderLastDoneOdometer, '90000');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        _field(tester, l10nOf(tester).reminderLastDoneOdometer).errorText,
        'This is below the earliest reading for this vehicle.',
      );
    },
  );

  testWidgets('a blank notice field shows the automatic window as a '
      'placeholder', (tester) async {
    // §9, for a 10,000 km / 12-month item: `Automatic — 1,000 km / 30 days`,
    // from `clamp(0.10 x interval, 200 km, 1000 km)` and
    // `clamp(0.10 x months x 30.44, 7, 30)`.
    tester.useDevice(Device.tallForm);
    final db = await _seeded(_oil());
    await _pump(tester, db: db);

    // ONE hint under the pair, the way the artboard draws it — not the same
    // sentence twice inside two placeholders.
    // Bidi isolates STRIPPED: `formatWithUnit` wraps the number and its unit
    // in one FSI…PDI run, and leaving them in would make this a test of the
    // isolate as well as of the arithmetic.
    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => stripBidi(t.data ?? ''))
          .where((t) => t.startsWith('Blank means automatic')),
      ['Blank means automatic — 1,000 km / 30 days.'],
    );
  });

  testWidgets('blank distance turns the distance axis off, on the written '
      'item', (tester) async {
    // Asserted on the ROW, not on the widget. "The field is empty" and "the
    // item has no distance axis" are different claims and only the second is
    // what the due engine reads.
    final db = await _seeded(_oil());
    await _pump(tester, db: db);

    await _type(tester, l10nOf(tester).reminderEveryDistance, '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final row = (await db.select(db.serviceItems).get()).single;
    expect(row.intervalDistanceM, isNull);
    expect(row.intervalMonths, 12, reason: 'the time axis is untouched');
  });

  testWidgets('an explicit notice override is stored unclamped', (
    tester,
  ) async {
    // §3: the clamp defines the computed DEFAULT only. 2,000 km is outside it
    // and round-trips, which is why `settings.notifications` may offer one.
    tester.useDevice(Device.tallForm);
    final db = await _seeded(_oil());
    await _pump(tester, db: db);

    await _type(tester, l10nOf(tester).reminderNoticeAhead, '2000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final row = (await db.select(db.serviceItems).get()).single;
    expect(row.noticeDistanceM, 2000000);
  });

  testWidgets('editing an interval resets snooze_count to zero', (
    tester,
  ) async {
    // §9: a snooze is a decision about the OLD schedule. Carrying its count
    // into a new one silently escalates a reminder nobody snoozed.
    final snoozed = ServiceItem(
      id: ServiceItemId.tryParse(_oilId)!,
      vehicleId: golfId,
      kind: ServiceKind.custom,
      label: 'Oil and filter',
      priority: ServicePriority.normal,
      rollover: ServiceRollover.fromActual,
      intervalMonths: 12,
      snoozedUntil: '2026-10-12',
      snoozeCount: 3,
      isTracked: true,
      createdAtUtcMs: 1000,
      updatedAtUtcMs: 1000,
    );
    final db = await _seeded(snoozed);
    await _pump(tester, db: db);

    await _type(tester, l10nOf(tester).reminderEveryMonths, '6');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final row = (await db.select(db.serviceItems).get()).single;
    expect(row.intervalMonths, 6);
    expect(row.snoozeCount, 0);
    expect(row.snoozedUntil, isNull);
  });

  testWidgets('an unreferenced item deletes outright with Undo', (
    tester,
  ) async {
    tester.useDevice(Device.tallForm);
    final db = await _seeded(_oil());
    await _pump(tester, db: db);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    final row = (await db.select(db.serviceItems).get()).single;
    expect(row.deletedAtUtcMs, isNotNull);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('a referenced item cannot be deleted', (tester) async {
    // §9: it "is not deletable"; the destructive control becomes **Turn this
    // reminder off**, with one line saying the records stay. §2 puts eight
    // years of service history above every feature, and orphaning the lines
    // that name this item is exactly that loss.
    tester.useDevice(Device.tallForm);
    final db = await _seeded(_oil());
    await _record(db, lines: 2);

    await _pump(tester, db: db);

    expect(find.text('Turn this reminder off'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
    expect(
      find.text(
        '2 services are recorded against this. Turning it off keeps them.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an untracked item shows its banner and Start tracking', (
    tester,
  ) async {
    final db = await _seeded(_oil());
    await ServiceRepository(db, homeIds()).setItemTracked(
      ServiceItemId.tryParse(_oilId)!,
      isTracked: false,
      updatedAtUtcMs: 2000,
    );

    await _pump(tester, db: db);

    expect(find.text("Not tracked — you won't be reminded"), findsOneWidget);
    await tester.tap(find.text('Start tracking'));
    await tester.pumpAndSettle();

    final row = (await db.select(db.serviceItems).get()).single;
    expect(row.isTracked, isTrue);
  });

  testWidgets('a paused item shows Turn back on', (tester) async {
    final db = await _seeded(_oil());
    await ServiceRepository(db, homeIds()).setItemActive(
      ServiceItemId.tryParse(_oilId)!,
      isActive: false,
      updatedAtUtcMs: 2000,
    );

    await _pump(tester, db: db);

    await tester.tap(find.text('Turn back on'));
    await tester.pumpAndSettle();

    final row = (await db.select(db.serviceItems).get()).single;
    expect(row.isActive, isTrue);
  });

  testWidgets('last done lists the newest records for this item', (
    tester,
  ) async {
    tester.useDevice(Device.tallForm);
    final db = await _seeded(_oil());
    await _pump(
      tester,
      db: db,
      records: [
        _serviceRecord('2026-05-05', 184292, 'A'),
        _serviceRecord('2025-04-04', 172100, 'B'),
      ],
    );

    // Newest FIRST. It is evidence, and evidence read backwards is a list.
    final rows = tester
        .widgetList<CalmListRow>(find.byType(CalmListRow))
        .where((r) => r.title.contains('2026') || r.title.contains('2025'))
        .toList();
    expect(rows.first.title, contains('2026'));
    expect(rows.last.title, contains('2025'));
  });

  testWidgets('labels sit above inputs, in German at 200%', (tester) async {
    // §9: "Labels sit above inputs, never beside them, so German
    // (`Wie weit im Voraus soll ich Bescheid sagen?`) and Sorani wrap freely."
    // The TALL surface at a phone width. The assertion is that the German
    // question wraps rather than truncating, which is about the LABEL and the
    // width; a 667pt viewport would simply not build the field.
    tester.useDevice(Device.tallForm);
    final db = await _seeded(_oil());
    await _pump(
      tester,
      db: db,
      locale: const Locale('de'),
      textScaler: const TextScaler.linear(2),
    );

    // No overflow — the harness turns one into a failure — and the German
    // question is present in full rather than truncated.
    expect(tester.takeException(), isNull);
    expect(
      find.text('Wie weit im Voraus soll ich Bescheid sagen?'),
      findsOneWidget,
    );
  });
}

/// A service record with [lines] lines naming the oil item.
Future<void> _record(AppDatabase db, {required int lines}) async {
  final repository = ServiceRepository(db, homeIds());
  for (var i = 0; i < lines; i++) {
    final saved = await repository.saveRecord(
      ServiceRecord(
        id: ServiceRecordId.tryParse(
          'srv_01JQ8ZK3M7F0R6XN2E9TB4HCV${'AB'[i]}',
        )!,
        vehicleId: golfId,
        occurredOn: '2026-0${i + 1}-01',
        odometerUnit: DistanceUnit.km,
        lines: [
          ServiceLine(
            id: ServiceLineId.tryParse(
              'lin_01JQ8ZK3M7F0R6XN2E9TB4HCV${'AB'[i]}',
            )!,
            serviceRecordId: ServiceRecordId.tryParse(
              'srv_01JQ8ZK3M7F0R6XN2E9TB4HCV${'AB'[i]}',
            )!,
            serviceItemId: ServiceItemId.tryParse(_oilId),
            label: 'Oil and filter',
            amount: Money(0, Currency.tryParse('EUR')!),
          ),
        ],
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );
    expect(saved, isA<Ok<ServiceRecord, PersistFailure>>());
  }
}

ServiceRecord _serviceRecord(String on, int km, String suffix) => ServiceRecord(
  id: ServiceRecordId.tryParse('srv_01JQ8ZK3M7F0R6XN2E9TB4HCV$suffix')!,
  vehicleId: golfId,
  occurredOn: on,
  odometer: Distance.fromKm(km),
  odometerUnit: DistanceUnit.km,
  lines: [
    ServiceLine(
      id: ServiceLineId.tryParse('lin_01JQ8ZK3M7F0R6XN2E9TB4HCV$suffix')!,
      serviceRecordId: ServiceRecordId.tryParse(
        'srv_01JQ8ZK3M7F0R6XN2E9TB4HCV$suffix',
      )!,
      serviceItemId: ServiceItemId.tryParse(_oilId),
      label: 'Oil and filter',
      amount: Money(0, Currency.tryParse('EUR')!),
    ),
  ],
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);
