// One transaction, then a recompute, then a reschedule — in that order.
//
// SPEC.md §10 *Save*: "One transaction: the record, its `OdometerReading` if it
// carries one, then a recompute of due states and a notification reschedule."
// The ORDER is the contract: a reschedule that ran before the recompute would
// schedule notifications against due states the write had already invalidated.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/features/logging/application/log_save_service.dart';

const String _b = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
final VehicleId _vehicleId = VehicleId.tryParse('veh_$_b')!;

/// Records what happened and in which order.
class _Recorder implements LogSaveSteps {
  final steps = <String>[];
  PersistFailure? failWith;

  @override
  Future<Result<void, PersistFailure>> persist() async {
    steps.add('persist');
    final failure = failWith;
    return failure == null ? const Ok(null) : Err(failure);
  }

  @override
  Future<void> recompute() async => steps.add('recompute');

  @override
  Future<void> reschedule() async => steps.add('reschedule');
}

FillUp _fillUp() => FillUp(
  id: FillUpId.tryParse('fil_$_b')!,
  vehicleId: _vehicleId,
  occurredOn: '2026-09-02',
  odometer: const Distance.fromKm(187412),
  odometerUnit: DistanceUnit.km,
  fuelKind: FuelKind.diesel,
  quantity: const LiquidVolume(Volume(42610)),
  quantityUnit: VolumeUnit.l,
  totalCost: Money(7666, Currency.tryParse('EUR')!),
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

void main() {
  test('persist, then recompute, then reschedule', () async {
    // The order is the contract. A reschedule before the recompute would build
    // notifications from due states the write had already invalidated, and the
    // user would be reminded about work they had just logged.
    final recorder = _Recorder();

    final result = await saveLogEntry(recorder);

    expect(result, isA<Ok<void, PersistFailure>>());
    expect(recorder.steps, ['persist', 'recompute', 'reschedule']);
  });

  test('a write failure stops before the recompute', () async {
    // §10: the modal "stays open with everything intact". Recomputing after a
    // failed write would recompute from rows that were never written, and
    // rescheduling would then fire notifications for them.
    final recorder = _Recorder()..failWith = const WriteFailed('disk full');

    final result = await saveLogEntry(recorder);

    expect(result, isA<Err<void, PersistFailure>>());
    expect(recorder.steps, ['persist']);
  });

  test('the failure reaches the caller unchanged', () async {
    // The modal shows one sentence and keeps every field. It cannot do that
    // from a swallowed exception.
    final recorder = _Recorder()..failWith = const WriteFailed('disk full');

    final result = await saveLogEntry(recorder);

    expect((result as Err<void, PersistFailure>).failure, isA<WriteFailed>());
  });

  test('a fill-up carries exactly one quantity form', () async {
    // The `fill_ups` CHECK is
    // `(quantity_ml IS NOT NULL) + (quantity_g IS NOT NULL) + (energy_wh IS
    // NOT NULL) = 1`, so a draft that produced none or two would be refused by
    // SQL. Asserted here because the form is what builds it.
    final fill = _fillUp();

    expect(fill.quantity, isA<LiquidVolume>());
    expect(quantityFormsSet(fill.quantity), 1);
  });
}
