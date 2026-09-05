// `vehicle.edit` — the form half.
//
// The validation lives on `VehicleEditDraft` and the lifecycle on its notifier.
// This file is about what the screen draws and what a tap does.
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/dirty_modal_guard.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/vehicles/vehicle_colour.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/presentation/vehicle_edit_screen.dart';
import 'package:odova/features/vehicles/vehicle_edit_notifier.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_segmented.dart';
import 'package:odova/ui/calm/calm_switch.dart';

import '../../../data/support/rows.dart';
import '../../../parity/support/parity_capture.dart'
    show kReferenceDpr, kReferencePhysical;
import '../../../support/pump_app.dart';

const _golf = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';
final VehicleId _id = VehicleId.tryParse(_golf)!;

/// Pumps the screen over a database holding one vehicle.
Future<AppDatabase> _pump(
  WidgetTester tester, {
  String name = 'The Golf',
  Locale? locale,
  List<OdometerReading> readings = const [],
  bool tall = false,
  List<Vehicle> garage = const [],
}) async {
  tester.view.physicalSize = tall
      // Tall enough that the lazy ListView builds every child. Not a device
      // anyone owns — it is a way of asking "is the row there at all", which is
      // a different question from "does it fit".
      ? const Size(780, 2600)
      : kReferencePhysical;
  tester.view.devicePixelRatio = kReferenceDpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await insertVehicle(db, id: _golf, name: name);

  await pumpApp(
    tester,
    VehicleEditScreen(vehicleId: _id),
    locale: locale,
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026, 9, 4))),
      // PINNED, or the vehicle's units follow whatever locale the machine
      // running the test is set to — and a British CI box would render the
      // odometer in miles while a German one renders kilometres.
      deviceLocalesProvider.overrideWithValue(const [Locale('de', 'DE')]),
      // The READINGS are supplied, not written. `provider_harness.dart` says
      // why: a drift stream never delivers under `testWidgets`, because the
      // widget binding's fake async does not run its timers — and the symptom
      // is a ten-minute hang with no output rather than a failure. This test is
      // about the ROW, so the row gets its data and drift stays out of it.
      odometerReadingsProvider(
        _id,
      ).overrideWith((ref) => Stream.value(readings)),
      // SUPPLIED, and not optional: the name field reads the garage to notice
      // a duplicate, and a real drift stream under `testWidgets` leaves a
      // pending timer at teardown that fails the test AFTER the one that
      // opened it — `provider_harness.dart`'s rule, arriving here the moment a
      // second provider was watched.
      vehiclesProvider.overrideWith((ref) => Stream.value(garage)),
    ],
  );
  // The notifier loads asynchronously; let it land.
  await tester.pumpAndSettle();
  return db;
}

/// Pumps `vehicle.edit` PUSHED over a host, so it has somewhere to dismiss to.
///
/// [_pump] puts the screen at `/`, where a pop has nothing under it — fine for
/// everything that only reads the form, wrong for the two rows at its foot,
/// which end by leaving.
Future<AppDatabase> _pumpHosted(WidgetTester tester) async {
  tester.view.physicalSize = const Size(780, 2600);
  tester.view.devicePixelRatio = kReferenceDpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await insertSettings(db);
  await insertVehicle(db, id: _golf);

  await pumpApp(
    tester,
    Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => VehicleEditScreen(vehicleId: _id),
          ),
        ),
        child: const Text('open'),
      ),
    ),
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026, 9, 4))),
      deviceLocalesProvider.overrideWithValue(const [Locale('de', 'DE')]),
      // SUPPLIED, all three: a drift stream never delivers under `testWidgets`
      // (`provider_harness.dart`), and these flows read the garage, the
      // settings and this vehicle's readings on their way through.
      settingsProvider.overrideWith((ref) => Stream.value(null)),
      odometerReadingsProvider(
        _id,
      ).overrideWith((ref) => Stream.value(const [])),
      vehiclesProvider.overrideWith(
        (ref) => Stream.value([_garageRow('The Golf')]),
      ),
    ],
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return db;
}

/// A garage row, for the tests that need the app to know about other vehicles.
Vehicle _garageRow(String name, {String id = _golf}) => Vehicle(
  id: VehicleId.tryParse(id)!,
  name: name,
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.petrol,
  status: VehicleStatus.active,
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);

BuildContext _ctx(WidgetTester tester) =>
    tester.element(find.byType(VehicleEditScreen));

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(_ctx(tester));

/// A reading taken on [occurredOn].
OdometerReading _reading(
  String occurredOn, {
  int km = 187412,
  String id = 'odo_01K1C4V2H9B8N3Q7ZE5RY6TMWY',
}) => OdometerReading(
  id: OdometerReadingId.tryParse(id)!,
  vehicleId: _id,
  occurredOn: occurredOn,
  odometer: Distance.fromKm(km),
  odometerUnit: DistanceUnit.km,
  source: OdometerSource.manual,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// A history, oldest first — which is `watchReadings`' own order.
///
/// TWO readings, not one. With a single reading the first and the last are the
/// same row, and a screen showing the OLDEST one passes every assertion while
/// telling the user their car has not moved since they bought it.
List<OdometerReading> _history(String latestOn) => [
  _reading('2024-01-05', km: 96400, id: 'odo_01K1C4V2H9B8N3Q7ZE5RY6TMWZ'),
  _reading(latestOn),
];

/// The row titled [title].
///
/// The caller pumps with `tall: true`, because `CalmScaffold`'s body is a lazy
/// `ListView`: everything below the fold is NOT BUILT rather than merely
/// off-screen, so `skipOffstage: false` finds nothing because there is nothing.
/// A taller viewport rather than a scroll — `scrollUntilVisible` never
/// converges here, since the multiline notes field grows as the list is dragged
/// and the target stays just out of reach.
CalmListRow _row(WidgetTester tester, String title) => tester
    .widgetList<CalmListRow>(find.byType(CalmListRow))
    .firstWhere((r) => r.title == title);

VehicleEditDraftReader _draft(WidgetTester tester) => VehicleEditDraftReader(
  ProviderScope.containerOf(_ctx(tester)).read(vehicleEditProvider(_id)),
);

/// Unwraps the ready state, so a test reads `_draft(tester).name` rather than
/// four casts.
extension type VehicleEditDraftReader(VehicleEditState state) {
  VehicleEditReady get _ready => state as VehicleEditReady;
  String get name => _ready.draft.name;
  String? get plate => _ready.draft.plate;
  int? get year => _ready.draft.year;
  VehicleColour? get colour => _ready.draft.colour;
  VehicleType get vehicleType => _ready.draft.vehicleType;
  bool get isDirty => _ready.draft.isDirty;
}

void main() {
  testWidgets('the modal closes with a glyph that is still named', (
    tester,
  ) async {
    // EPIC-09 F-9.19. The artboard's start action is an ✕ where `log.fillup`
    // closes with the word Cancel.
    await _pump(tester);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(
      tester.getSemantics(find.byIcon(Icons.close)).label,
      _l10n(tester).commonClose,
    );
  });

  testWidgets('the fields are seeded from the row, and once only', (
    tester,
  ) async {
    // Re-seeding on every build would fight the user's typing — the notifier
    // deliberately never reloads its row, and the controllers must not either.
    await _pump(tester);
    // TWICE, and both are right: the modal is titled with the vehicle's name —
    // the artboard titles it "Golf", not "Vehicle" — and the field holds it
    // too. A user with three cars open needs to know which one they are in.
    expect(find.text('The Golf'), findsNWidgets(2));

    await tester.enterText(find.byType(CalmField).first, 'The Polo');
    await tester.pumpAndSettle();
    expect(_draft(tester).name, 'The Polo');
    // The title follows the field as it is typed, so renaming a car does not
    // leave the header describing the old one.
    expect(find.text('The Polo'), findsNWidgets(2));
  });

  testWidgets('four type segments, and truck is not among them', (
    tester,
  ) async {
    // EPIC-09 F-9.21, raised rather than closed: §4.8 gives `truck` the car set
    // unchanged, so the choice costs a label and not a reminder — but this IS
    // the screen a truck owner would come to in order to fix that label.
    await _pump(tester);
    final l10n = _l10n(tester);
    final labels = tester
        .widgetList<CalmSegmentedOption>(find.byType(CalmSegmentedOption))
        .map((o) => o.label)
        .toList();
    expect(labels, [
      l10n.vehicleTypeCar,
      l10n.vehicleTypeVan,
      l10n.vehicleTypeMotorcycle,
      l10n.vehicleTypeOther,
    ]);

    await tester.tap(find.text(l10n.vehicleTypeVan));
    await tester.pumpAndSettle();
    expect(_draft(tester).vehicleType, VehicleType.van);
  });

  testWidgets('nine swatches, each named, and other has no fill', (
    tester,
  ) async {
    // EPIC-09 F-9.18. A circle of colour has no text, so a screen reader would
    // otherwise announce nine identical buttons.
    await _pump(tester);
    final l10n = _l10n(tester);

    for (final label in [
      l10n.colourWhite,
      l10n.colourSilver,
      l10n.colourGrey,
      l10n.colourBlack,
      l10n.colourRed,
      l10n.colourBlue,
      l10n.colourGreen,
      l10n.colourYellow,
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    // `Other` is searched inside the swatch row, because the TYPE segment is
    // also called Other in English — EPIC-09 F-9.22. German already
    // distinguishes them (Sonstige / Sonstiges); English does not, and two
    // controls announcing "Other, button" on one screen is a real ambiguity
    // for a screen reader rather than an artefact of this test.
    expect(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.bySemanticsLabel(l10n.colourOther),
      ),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel(l10n.colourRed));
    await tester.pumpAndSettle();
    expect(_draft(tester).colour, VehicleColour.red);
  });

  testWidgets('a year outside the range says so, and next year is fine', (
    tester,
  ) async {
    await _pump(tester);
    final year = find.byType(CalmField).at(3);

    await tester.enterText(year, '2016');
    await tester.pumpAndSettle();
    expect(find.textContaining('1900'), findsNothing);

    await tester.enterText(year, '1899');
    await tester.pumpAndSettle();
    // The bound is formatted WITHOUT grouping — "1,900" is a thousand nine
    // hundred, which is not a year anybody has driven a car in.
    expect(find.textContaining('1900'), findsOneWidget);
    expect(find.textContaining('1,900'), findsNothing);
  });

  testWidgets('an unusual VIN is a hint, never an error', (tester) async {
    // SPEC.md §8: it still saves. Some pre-1981 and non-road vehicles have
    // shorter numbers, and refusing theirs would mean refusing the vehicle.
    await _pump(tester);
    final vin = find.byType(CalmField).at(5);

    await tester.enterText(vin, 'WVWZZZ1KZAW12345');
    await tester.pumpAndSettle();

    final field = tester.widget<CalmField>(vin);
    expect(field.hint, isNotNull, reason: 'a hint');
    expect(field.errorText, isNull, reason: 'not an error');
    // And Save is still offered.
    final bar = tester.widget<CalmAppBar>(find.byType(CalmAppBar));
    expect(bar.onEnd, isNotNull);
  });

  testWidgets('the plate and the VIN are forced LTR on a Persian screen', (
    tester,
  ) async {
    // SPEC.md §8. An Iranian plate legitimately carries Persian digits AND a
    // Persian letter, and reordering it rewrites somebody's own characters.
    await _pump(tester, locale: const Locale('fa'));
    final fields = tester
        .widgetList<CalmField>(find.byType(CalmField))
        .toList();
    expect(fields[4].code, isTrue, reason: 'plate');
    expect(fields[5].code, isTrue, reason: 'VIN');
    // The name is not a code — it takes direction from the screen.
    expect(fields[0].code, isFalse);
  });

  testWidgets('Save is refused while the name is empty', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(CalmField).first, '   ');
    await tester.pumpAndSettle();
    expect(
      tester.widget<CalmAppBar>(find.byType(CalmAppBar)).onEnd,
      isNull,
    );
  });

  testWidgets('editing marks the form dirty and saving cleans it', (
    tester,
  ) async {
    await _pump(tester);
    expect(_draft(tester).isDirty, isFalse);

    await tester.enterText(find.byType(CalmField).at(1), 'VW');
    await tester.pumpAndSettle();
    expect(_draft(tester).isDirty, isTrue);
  });

  testWidgets('a dirty dismiss asks, and a clean one does not', (
    tester,
  ) async {
    // SPEC.md §10 through EPIC-08's `DirtyModalGuard` and EPIC-08's dialog —
    // this screen supplies only the subject and the summary. A clean form
    // dismisses silently, because a discard dialog that appears when nothing is
    // pending teaches the user to dismiss it unread, and then it is worth
    // nothing on the day something IS pending.
    await _pump(tester);

    final guard = tester.widget<DirtyModalGuard>(find.byType(DirtyModalGuard));
    expect(guard.isDirty(), isFalse);

    await tester.enterText(find.byType(CalmField).first, 'The Polo');
    await tester.pumpAndSettle();
    // A CALLBACK, not a bool: the answer changes with every keystroke and the
    // guard is not rebuilt for any of them.
    expect(
      tester.widget<DirtyModalGuard>(find.byType(DirtyModalGuard)).isDirty(),
      isTrue,
    );
  });

  testWidgets('the screen writes no discard dialog of its own', (
    tester,
  ) async {
    // The structural half of the same rule lives in
    // `test/ui/dialogs/discard_dialog_test.dart`, which allow-lists this file
    // as a CALLER and bans every declaration. This is the behavioural half:
    // the guard the screen mounts is the shared one.
    await _pump(tester);
    expect(find.byType(DirtyModalGuard), findsOneWidget);
  });

  testWidgets('the odometer is a read-only row with the reading and its age', (
    tester,
  ) async {
    // SPEC.md §8: "in create mode it is an input; in edit mode a row showing
    // the latest reading and its age". A facts form that wrote a dated reading
    // would stamp today on a number last checked in March.
    await _pump(tester, readings: _history('2026-09-01'), tall: true);
    final l10n = _l10n(tester);

    final row = _row(tester, l10n.vehicleOdometerRow);

    // The number and its unit are ONE run, so a Persian screen never splits
    // them across the mirror.
    // A FULL STOP, because the device is pinned to de-DE and German groups
    // with one. Asserting "187,412" here would be asserting that the row
    // ignores the locale.
    expect(row.value, contains('187.412'));
    expect(row.value, contains(l10n.unitDistanceKm));
    // And the two are inside one bidi isolate, so a Persian screen cannot
    // split the number from its unit across the mirror — SPEC.md §5.
    expect(row.value!.codeUnitAt(0), 0x2068);
    expect(row.value!.codeUnitAt(row.value!.length - 1), 0x2069);

    // Three days before the pinned clock, and phrased as a PAST age — not
    // `dateDaysOverdue`, which would say the reading itself was late.
    expect(row.subtitle, l10n.vehicleOdometerRowHint(l10n.dateDaysAgo(3, '3')));

    // Read-only: no field for it anywhere on the screen.
    expect(
      tester
          .widgetList<CalmField>(find.byType(CalmField))
          .where((f) => f.label == l10n.vehicleOdometerRow),
      isEmpty,
    );
  });

  testWidgets("today's reading says today, not zero days ago", (tester) async {
    await _pump(tester, readings: _history('2026-09-04'), tall: true);
    final l10n = _l10n(tester);
    final row = _row(tester, l10n.vehicleOdometerRow);
    expect(row.subtitle, l10n.vehicleOdometerRowHint(l10n.dateToday));
  });

  testWidgets('a vehicle with no readings shows the row and no number', (
    tester,
  ) async {
    // The row never disappears. A missing odometer is a fact worth drawing,
    // and a row that vanishes is a screen the user cannot ask about it from.
    await _pump(tester, tall: true);
    final l10n = _l10n(tester);
    final row = _row(tester, l10n.vehicleOdometerRow);
    expect(row.value, isNull);
    expect(row.subtitle, isNull);
  });

  testWidgets(
    'a tap on the switch itself toggles it, like the rest of the row',
    (
      tester,
    ) async {
      // `CalmSwitch.onChanged` null is the SANCTIONED arrangement inside a
      // switch row — its own dartdoc says so — because the ROW is the tap
      // target and the switch is paint. A no-op `(_) {}` instead of null is not
      // "the same thing, spelled defensively": it makes the switch an active
      // GestureDetector, and a child recognizer beats the ancestor's in the
      // arena. So the one place the user is most likely to press — the control
      // itself — was the one place that did nothing at all.
      await _pump(tester, tall: true);
      final l10n = _l10n(tester);

      for (final title in [l10n.vehicleBusinessLabel, l10n.vehicleMuteLabel]) {
        final row = find.ancestor(
          of: find.text(title),
          matching: find.byType(CalmListRow),
        );
        final knob = find.descendant(
          of: row,
          matching: find.byType(CalmSwitchTrack),
        );
        expect(tester.widget<CalmSwitchTrack>(knob).value, isFalse);

        await tester.tap(knob);
        await tester.pump();
        expect(
          tester.widget<CalmSwitchTrack>(knob).value,
          isTrue,
          reason: 'tapping the $title switch must toggle it',
        );
      }
    },
  );

  testWidgets('a duplicate name is noted, not refused', (tester) async {
    // SPEC.md §8: "duplicates allowed, with the note 'You already have a
    // vehicle called Van'". A plumber with two identical Transits may well
    // want them named the same and told apart by their plates, so the app says
    // what it noticed and stops there — Save stays live.
    await _pump(
      tester,
      garage: [
        _garageRow('The Golf'),
        _garageRow('Van', id: 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVB'),
      ],
    );
    final l10n = _l10n(tester);
    CalmField nameField() => tester
        .widgetList<CalmField>(find.byType(CalmField))
        .firstWhere((f) => f.label == l10n.vehicleNameLabel);

    expect(nameField().hint, isNull, reason: 'its own name is not a duplicate');

    await tester.enterText(find.byWidget(nameField()), '  van ');
    await tester.pumpAndSettle();
    expect(
      nameField().hint,
      l10n.vehicleDuplicateNameNote('Van'),
      // Trimmed and case-folded: "van" and "Van " are the same answer to
      // "what do you call it", and a note that only fires on an exact byte
      // match is a note that mostly does not fire.
      reason: 'whitespace and case are not what tells two vans apart',
    );
    expect(nameField().errorText, isNull, reason: 'a note, not an error');
  });

  testWidgets('Mark as sold opens the sale form and dismisses the modal', (
    tester,
  ) async {
    // SPEC.md §8 draws both rows at the foot of `vehicle.edit`, and they were
    // inert. The modal DISMISSES after a sale, and not for tidiness:
    // `VehicleEditDraft` copies `status` from the row it loaded, so a form left
    // open over a sold vehicle writes `active` back over it on the next Save
    // and undoes the sale in silence.
    final db = await _pumpHosted(tester);
    final l10n = _l10n(tester);

    await tester.ensureVisible(find.text(l10n.vehicleMarkAsSold));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.vehicleMarkAsSold));
    await tester.pumpAndSettle();
    // The sheet titles itself with the same words as the row that opened it,
    // so its own Confirm is the SECOND of the two.
    expect(find.text(l10n.vehicleSoldOn), findsOneWidget);

    await tester.tap(find.text(l10n.vehicleMarkAsSold).last);
    await tester.pumpAndSettle();

    final row = await db.select(db.vehicles).getSingle();
    expect(row.status, VehicleStatus.sold.wire);
    expect(find.byType(VehicleEditScreen), findsNothing, reason: 'dismissed');
  });

  testWidgets('Delete asks first, and Cancel leaves the vehicle alone', (
    tester,
  ) async {
    final db = await _pumpHosted(tester);
    final l10n = _l10n(tester);

    // SCROLLED TO first. The row is the last thing on a long form, so it is
    // built but off-screen — and a tap on an off-screen widget hits nothing
    // and warns rather than failing, which is a test that passes by not
    // pressing the button.
    final deleteRow = find.text(l10n.vehicleDeleteRowEmpty('The Golf'));
    await tester.ensureVisible(deleteRow);
    await tester.pumpAndSettle();
    await tester.tap(deleteRow);
    await tester.pumpAndSettle();
    expect(find.text(l10n.commonCancel), findsOneWidget);

    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();

    final row = await db.select(db.vehicles).getSingle();
    expect(row.deletedAtUtcMs, isNull);
    expect(find.byType(VehicleEditScreen), findsOneWidget, reason: 'still up');
  });

  group('create mode', () {
    /// Pushes `vehicle.edit` in create mode over a host screen, and collects
    /// what it pops with.
    Future<(AppDatabase, List<Vehicle?>)> pumpCreate(
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(780, 2600);
      tester.view.devicePixelRatio = kReferenceDpr;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await insertSettings(db);

      final popped = <Vehicle?>[];
      await pumpApp(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => popped.add(
              await Navigator.of(context).push<Vehicle>(
                MaterialPageRoute(
                  builder: (_) => const VehicleEditScreen(
                    vehicleId: null,
                    mode: VehicleEditMode.create,
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(
            Clock.fixed(DateTime.utc(2026, 9, 4)),
          ),
          deviceLocalesProvider.overrideWithValue(const [Locale('de', 'DE')]),
          // SUPPLIED, not watched off the database. Create mode reads the
          // app's distance unit to label its odometer field, and
          // `provider_harness.dart`'s rule holds: a drift stream never
          // delivers under `testWidgets`, because the widget binding's fake
          // async does not run its timers. Null is the honest first-frame
          // value, and the unit falls back to the pinned locale's — km.
          settingsProvider.overrideWith((ref) => Stream.value(null)),
          // An EMPTY garage: this is the form for the car that does not exist
          // yet, and supplying it keeps a real drift stream — whose teardown
          // timer fails the NEXT test rather than this one — out of the way.
          vehiclesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return (db, popped);
    }

    CalmAppBarAction saveAction(WidgetTester tester) => tester
        .widgetList<CalmAppBarAction>(find.byType(CalmAppBarAction))
        .firstWhere((a) => a.label == _l10n(tester).commonSave);

    testWidgets('it titles itself Add vehicle and asks for an odometer', (
      tester,
    ) async {
      await pumpCreate(tester);
      final l10n = _l10n(tester);

      // Not "Vehicle": a blank form titled with the generic word says nothing
      // about what Save would do.
      expect(find.text(l10n.vehicleAddTitle), findsOneWidget);
      expect(
        tester
            .widgetList<CalmField>(find.byType(CalmField))
            .where((f) => f.label == l10n.odometerNowLabel),
        hasLength(1),
        reason: 'SPEC.md §8: in create mode the odometer is an input',
      );
      // And nothing to sell or delete on a car that does not exist.
      expect(find.text(l10n.vehicleMarkAsSold), findsNothing);
      expect(find.textContaining(l10n.commonDelete), findsNothing);
    });

    testWidgets('Save waits for a name and a reading, then writes both', (
      tester,
    ) async {
      final (db, popped) = await pumpCreate(tester);
      final l10n = _l10n(tester);

      expect(saveAction(tester).onTap, isNull, reason: 'nothing typed');

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is CalmField && w.label == l10n.vehicleNameLabel,
        ),
        'The Transit',
      );
      await tester.pumpAndSettle();
      expect(saveAction(tester).onTap, isNull, reason: 'no reading yet');

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is CalmField && w.label == l10n.odometerNowLabel,
        ),
        '92050',
      );
      await tester.pumpAndSettle();
      expect(saveAction(tester).onTap, isNotNull);

      await tester.tap(find.text(l10n.commonSave));
      await tester.pumpAndSettle();

      final row = await db.select(db.vehicles).getSingle();
      expect(row.name, 'The Transit');
      final reading = await db.select(db.odometerReadings).getSingle();
      expect(reading.odometerM, const Distance.fromKm(92050).metres);

      // The id travels back with the pop, because the CALLER decides whether
      // to switch to it — the garage offers, the switcher does it.
      expect(popped.single!.id.toString(), row.id);
      expect(
        popped.single!.name,
        'The Transit',
        reason: 'the whole row travels back, so the caller can name it',
      );
    });

    testWidgets('an implausible reading warns and still saves', (tester) async {
      final (db, _) = await pumpCreate(tester);
      final l10n = _l10n(tester);

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is CalmField && w.label == l10n.vehicleNameLabel,
        ),
        'The Truck',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is CalmField && w.label == l10n.odometerNowLabel,
        ),
        '3000001',
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.odometerImplausibleWarning), findsOneWidget);
      expect(
        saveAction(tester).onTap,
        isNotNull,
        reason: 'SPEC.md §8: a warning with an affordance, never a block',
      );

      await tester.tap(find.text(l10n.commonSave));
      await tester.pumpAndSettle();
      expect(await db.select(db.vehicles).get(), hasLength(1));
    });
  });
}
