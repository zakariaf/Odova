// `vehicle.edit`'s draft: what is dirty, what is refused, and what is only
// remarked upon.
//
// SPEC.md §8 distinguishes three strengths and the screen depends on all three.
// The name is REQUIRED. The year is an ERROR — "Enter a year between 1900 and
// 2027." A VIN of the wrong length and a duplicate name are NOTES: the form
// says something and saves anyway, because a 1978 tractor really does have a
// short number and two vans really can share a name.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/vehicles/vehicle_colour.dart';
import 'package:odova/features/vehicles/vehicle_edit_draft.dart';
import 'package:test/test.dart';

Vehicle _golf({
  String name = 'The Golf',
  String? plate = 'M-AB 1234',
  String? colour = 'grey',
}) => Vehicle(
  id: VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA')!,
  name: name,
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  plate: plate,
  colour: colour,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

void main() {
  group('dirty', () {
    test('an untouched draft is clean, and one keystroke is not', () {
      final draft = VehicleEditDraft.of(_golf());
      expect(draft.isDirty, isFalse);
      expect(draft.copyWith(name: 'The Polo').isDirty, isTrue);
    });

    test('a field added to Vehicle is dirty-tracked the day it is added', () {
      // The comparison is `Vehicle == Vehicle`, not a hand-written list of
      // fields — so a twenty-first field cannot be silently untracked, which is
      // how a form comes to lose a change without warning anybody.
      final draft = VehicleEditDraft.of(_golf());
      for (final changed in [
        draft.copyWith(make: 'VW'),
        draft.copyWith(year: 2016),
        draft.copyWith(colour: VehicleColour.red),
        draft.copyWith(notes: 'winter tyres in the shed'),
        draft.copyWith(isBusiness: true),
        draft.copyWith(notificationsMuted: true),
        draft.copyWith(distanceUnit: DistanceUnit.mi),
        draft.copyWith(noticeDays: 30),
      ]) {
        expect(changed.isDirty, isTrue, reason: 'not tracked');
      }
    });

    test('clearing a field is a change, which null alone cannot say', () {
      // The whole reason the draft exists rather than a `Vehicle.copyWith`:
      // passing null means "leave it alone", so without an explicit clear the
      // user could set a plate and never remove one.
      final draft = VehicleEditDraft.of(_golf());
      // Through a variable, because `copyWith(plate: null)` written literally
      // is `avoid_redundant_argument_values` — the analyzer is right that it
      // matches the default, and that IS the claim: null is the default
      // because null means "leave it alone".
      const String? nothing = null;
      expect(draft.copyWith(plate: nothing).isDirty, isFalse);
      final cleared = draft.copyWith(clear: {VehicleField.plate});
      expect(cleared.isDirty, isTrue);
      expect(cleared.toVehicle(1000).plate, isNull);
    });

    test('Automatic on each of the six overrides writes null', () {
      // SPEC.md §8: "each with an **Automatic** option that writes null." Null
      // is not "a value that happens to match the global" — it is an
      // instruction to keep following it, and materialising the current global
      // instead would pin the vehicle to today's answer forever.
      final set = VehicleEditDraft.of(_golf()).copyWith(
        distanceUnit: DistanceUnit.mi,
        noticeDays: 30,
        noticeDistance: const Distance(500000),
      );
      final automatic = set.copyWith(
        clear: {
          VehicleField.currency,
          VehicleField.distanceUnit,
          VehicleField.volumeUnit,
          VehicleField.consumptionUnit,
          VehicleField.noticeDistance,
          VehicleField.noticeDays,
        },
      );
      final row = automatic.toVehicle(2000);
      expect(row.currency, isNull);
      expect(row.distanceUnit, isNull);
      expect(row.volumeUnit, isNull);
      expect(row.consumptionUnit, isNull);
      expect(row.noticeDistance, isNull);
      expect(row.noticeDays, isNull);
    });
  });

  group('what is refused and what is only remarked upon', () {
    test('the name is the only required field', () {
      final draft = VehicleEditDraft.of(_golf());
      expect(draft.canSave, isTrue);
      expect(draft.copyWith(name: '').canSave, isFalse);
      expect(draft.copyWith(name: '   ').canSave, isFalse);
      // Everything else empty still saves. SPEC.md §8: "Everything else in
      // `Vehicle` is nullable and asked later."
      expect(
        VehicleEditDraft.of(_golf(plate: null, colour: null)).canSave,
        isTrue,
      );
    });

    test('the year range is 1900 to next year, and next year moves', () {
      // "Enter a year between 1900 and 2027." The upper bound is a fact about
      // the calendar — next year's models are on sale this year — so it is an
      // argument rather than a constant, and the message reads 2027 in 2026 and
      // 2028 in 2027 without anybody editing a string.
      final draft = VehicleEditDraft.of(_golf());
      expect(draft.copyWith(year: 2016).yearOutOfRange(2026), isFalse);
      expect(draft.copyWith(year: 1900).yearOutOfRange(2026), isFalse);
      expect(draft.copyWith(year: 2027).yearOutOfRange(2026), isFalse);
      expect(draft.copyWith(year: 1899).yearOutOfRange(2026), isTrue);
      expect(draft.copyWith(year: 2028).yearOutOfRange(2026), isTrue);
      // Next year, 2028 is fine.
      expect(draft.copyWith(year: 2028).yearOutOfRange(2027), isFalse);
      // No year at all is not an error — it is a field nobody filled in.
      expect(draft.yearOutOfRange(2026), isFalse);
    });

    test('a short VIN is a note, and the draft still saves', () {
      // Some pre-1981 and non-road vehicles have shorter numbers, and refusing
      // theirs would mean refusing the vehicle.
      final draft = VehicleEditDraft.of(_golf());
      expect(draft.vinLengthUnusual, isFalse, reason: 'no VIN, no note');
      expect(
        draft.copyWith(vin: 'WVWZZZ1KZAW12345').vinLengthUnusual,
        isTrue,
        reason: '16 characters',
      );
      expect(
        draft.copyWith(vin: 'WVWZZZ1KZAW123456').vinLengthUnusual,
        isFalse,
      );
      // A note, never a refusal.
      expect(draft.copyWith(vin: 'ABC').canSave, isTrue);
    });
  });

  group('what reaches the row', () {
    test('blank text becomes null rather than an empty string', () {
      // An empty string and a null are the same absence to a user and two
      // different values to every `groupBy`, every export and every "is it
      // set?" test in the app.
      final row = VehicleEditDraft.of(
        _golf(),
      ).copyWith(make: '  ', notes: '').toVehicle(2000);
      expect(row.make, isNull);
      expect(row.notes, isNull);
    });

    test('the name is trimmed, because a trailing space is invisible', () {
      final row = VehicleEditDraft.of(
        _golf(),
      ).copyWith(name: '  The Golf  ').toVehicle(2000);
      expect(row.name, 'The Golf');
    });

    test('an unrecognised stored colour reads as no selection', () {
      // A backup written by a future version. SPEC.md §2: never guess in a way
      // that looks like fact — snapping `brown` to the nearest swatch would
      // repaint somebody's car, and saving would then persist the repaint.
      final draft = VehicleEditDraft.of(_golf(colour: 'brown'));
      expect(draft.colour, isNull);
      expect(draft.isDirty, isTrue, reason: 'the row no longer round-trips');
    });

    test('the identity, the status and the sale survive an edit', () {
      // The form edits FACTS. Nothing on it can change which vehicle this is,
      // whether it is sold, or what it sold for — those move through Mark as
      // sold, and an edit that quietly reset them would lose a sale price.
      final sold = Vehicle(
        id: VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA')!,
        name: 'The Golf',
        vehicleType: VehicleType.car,
        fuelKindDefault: FuelKind.diesel,
        status: VehicleStatus.sold,
        soldOn: '2024-03-12',
        sortOrder: 3,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      );
      final row = VehicleEditDraft.of(
        sold,
      ).copyWith(name: 'Old Golf').toVehicle(2000);
      expect(row.id, sold.id);
      expect(row.status, VehicleStatus.sold);
      expect(row.soldOn, '2024-03-12');
      expect(row.sortOrder, 3);
      expect(row.createdAtUtcMs, 1000);
      expect(row.updatedAtUtcMs, 2000);
    });
  });
}
