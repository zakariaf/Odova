// The fill-up write path: one row, one derived reading, one recompute.
//
// SPEC.md §10's Definition of done for this epic — "every save is one
// transaction ending in a due-state recompute" — and §3's rule that every
// record carrying an odometer emits a reading. The reading is NOT written
// here: `odometer_fan_out.dart` is the only writer of a non-manual reading and
// the repository fans it out, so what this asserts is that one save produces
// both rows and that Undo removes both.
@TestOn('vm')
library;

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/id_provider.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/logging/application/fillup_save.dart';
import 'package:odova/features/logging/domain/fillup_draft.dart';
import 'package:odova/features/logging/domain/price_trio.dart';

import '../../../data/support/test_ids.dart';
import '../../../support/provider_harness.dart';

final Currency _eur = Currency.tryParse('EUR')!;
final VehicleId _vehicleId = VehicleId.tryParse(
  'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
)!;

Vehicle _vehicle() => Vehicle(
  id: _vehicleId,
  name: 'The Golf',
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

FillUpDraft _draft() => const FillUpDraft(
  occurredOn: '2026-09-02',
  trio: PriceTrio(quantity: '42.61', total: '76.66'),
  station: 'Shell A61',
);

void main() {
  late DatabaseHarness harness;

  setUp(() async {
    harness = containerWithDatabase(
      overrides: [
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 9, 2, 10)),
        ),
        ulidFactoryProvider.overrideWithValue(testIds()),
      ],
    );
    await harness.container.read(vehicleRepositoryProvider).save(_vehicle());
  });

  Future<int> liveCount(String table) async {
    final row = await harness.db
        .customSelect(
          'SELECT COUNT(*) AS n FROM $table WHERE deleted_at_utc_ms IS NULL',
        )
        .getSingle();
    return row.read<int>('n');
  }

  test('one save writes the fill-up and its derived reading', () async {
    // §3: "EVERY record carrying an odometer emits a reading." The form does
    // not write it — the repository fans it out — so this asserts that the
    // save path goes through the repository and not around it.
    final written = await harness.container
        .read(fillUpSaveProvider.notifier)
        .save(
          vehicle: _vehicle(),
          draft: _draft(),
          odometer: const Distance.fromKm(187412),
          currency: _eur,
        );

    expect(written, isA<FillUpSaved>());
    expect(await liveCount('fill_ups'), 1);
    expect(await liveCount('odometer_readings'), 1);
  });

  test('the DISPLAYED quantity is what gets stored', () async {
    // §10: "The rounded, displayed value is what gets stored. 76.66 € ÷ 1.799
    // shows 42.61 L and stores 42 610 mL, not 42 613.7 — a hidden extra
    // decimal makes the app's own price-per-litre disagree with the receipt,
    // and then nothing on screen is trusted."
    final written =
        await harness.container
                .read(fillUpSaveProvider.notifier)
                .save(
                  vehicle: _vehicle(),
                  draft: _draft(),
                  odometer: const Distance.fromKm(187412),
                  currency: _eur,
                )
            as FillUpSaved;

    expect(written.fillUp.quantity, isA<LiquidVolume>());
    expect(written.fillUp.quantity!.amount, 42610);
  });

  test('only quantity and total are written, never a price per unit', () async {
    // §10: "Only quantity and total are persisted; price per unit is
    // re-derived for display." Asserted against the SCHEMA, because a price
    // column is the kind of thing that gets added by a later migration and
    // then quietly disagrees with the two values it was derived from.
    final columns = await harness.db
        .customSelect('PRAGMA table_info(fill_ups)')
        .get();
    final names = columns.map((r) => r.read<String>('name')).toSet();

    expect(names, contains('quantity_ml'));
    expect(names, contains('total_cost_minor'));
    expect(
      names.where((n) => n.contains('price')),
      isEmpty,
      reason: 'a price-per-unit column would be a third place to disagree',
    );
  });

  test('Undo removes the fill-up and its reading together', () async {
    // §10 makes the snackbar the only confirmation logging gets, and the trade
    // only holds if Undo works. A reading left behind would leave the due
    // engine computing distance from a fill-up the user has undone.
    final save = harness.container.read(fillUpSaveProvider.notifier);
    final written =
        await save.save(
              vehicle: _vehicle(),
              draft: _draft(),
              odometer: const Distance.fromKm(187412),
              currency: _eur,
            )
            as FillUpSaved;

    final undone = await save.undo(written.fillUp);

    expect(undone, isA<Ok<void, PersistFailure>>());
    expect(await liveCount('fill_ups'), 0);
    expect(await liveCount('odometer_readings'), 0);
  });

  test('a save that goes backwards is refused, not written', () async {
    final save = harness.container.read(fillUpSaveProvider.notifier);
    await save.save(
      vehicle: _vehicle(),
      draft: _draft(),
      odometer: const Distance.fromKm(187412),
      currency: _eur,
    );

    final second = await save.save(
      vehicle: _vehicle(),
      draft: const FillUpDraft(
        occurredOn: '2026-09-03',
        trio: PriceTrio(quantity: '40', total: '70'),
      ),
      odometer: const Distance.fromKm(100),
      currency: _eur,
    );

    expect(second, isA<FillUpSaveFailed>());
    expect(await liveCount('fill_ups'), 1, reason: 'the first one only');
  });
}
