// The wire spellings are the contract, not the Dart names.
//
// SPEC.md §3 Enums: "These spellings are canonical everywhere: database,
// export, CSV headers, notification payloads." A renamed wire value is a backup
// file that no longer imports, and nothing in the type system notices.
import 'package:odova/core/domain/enums.dart';
import 'package:test/test.dart';

void main() {
  test('every enum has the exact values SPEC.md §3 lists, in order', () {
    // Written out rather than derived, because the point is to compare against
    // the spec by eye. A `.map((e) => e.wire)` over the enum would agree with
    // whatever the enum says and prove nothing.
    expect(DistanceUnit.values.map((e) => e.wire), ['km', 'mi']);
    expect(VolumeUnit.values.map((e) => e.wire), ['l', 'gal_us', 'gal_uk']);
    expect(ConsumptionUnit.values.map((e) => e.wire), [
      'l_100km',
      'km_l',
      'mpg_us',
      'mpg_uk',
      'kwh_100km',
      'mi_kwh',
    ]);
    expect(FuelKind.values.map((e) => e.wire), [
      'petrol',
      'diesel',
      'lpg',
      'cng',
      'electric',
      'hybrid',
      'other',
    ]);
    expect(VehicleType.values.map((e) => e.wire), [
      'car',
      'van',
      'motorcycle',
      'truck',
      'other',
    ]);
    expect(VehicleStatus.values.map((e) => e.wire), [
      'active',
      'archived',
      'sold',
    ]);
    expect(ServicePriority.values.map((e) => e.wire), [
      'safety',
      'normal',
      'low',
    ]);
    expect(ServiceRollover.values.map((e) => e.wire), [
      'from_actual',
      'from_due',
    ]);
    expect(TripPurpose.values.map((e) => e.wire), [
      'business',
      'commute',
      'personal',
      'other',
    ]);
    expect(OdometerSource.values.map((e) => e.wire), [
      'manual',
      'fillup',
      'service',
      'expense',
      'trip_start',
      'trip_end',
      'import',
    ]);
    // Three, not four. SPEC.md §3 listed `unit_mixup` and §14 said it was
    // removed; §14 won and §3 was fixed in the same PR. A km cluster on a
    // miles car needs no correction — storage is metres and the unit is a
    // per-record fact — so admitting the value would offer the user a
    // resolution that does nothing.
    expect(OdometerCorrectionReason.values.map((e) => e.wire), [
      'cluster_replaced',
      'rollover',
      'typo_fix',
    ]);
  });

  test('ExpenseCategory has exactly ten values, no more', () {
    // SPEC.md §3 says "ten values, no more" in the enum block itself. An
    // eleventh is a product decision that changes a CSV header and an export
    // schema, so it goes through the spec.
    expect(ExpenseCategory.values, hasLength(10));
    expect(ExpenseCategory.values.map((e) => e.wire), [
      'insurance',
      'tax_registration',
      'parking',
      'toll',
      'fine',
      'wash',
      'tyre_storage',
      'accessories',
      'finance',
      'other',
    ]);
  });

  test('ServiceKind has 28 values and ends with custom', () {
    expect(ServiceKind.values, hasLength(28));
    expect(ServiceKind.values.last, ServiceKind.custom);
    // The four SPEC.md separates onto their own lines, because they are the
    // ones a car-only reading of the catalogue would drop.
    expect(
      ServiceKind.values.map((e) => e.wire),
      containsAll(<String>[
        'chain_lube',
        'chain_and_sprockets',
        'valve_clearance',
        'fork_oil',
        'reduction_gearbox_oil',
        'battery_12v',
      ]),
    );
  });

  test('no two wire values collide, across every enum', () {
    // Within an enum a collision would be a copy-paste; across enums it is
    // fine (`other` appears in four). This asserts the within-enum rule for
    // all of them at once.
    final enums = <String, List<String>>{
      'DistanceUnit': DistanceUnit.values.map((e) => e.wire).toList(),
      'VolumeUnit': VolumeUnit.values.map((e) => e.wire).toList(),
      'ConsumptionUnit': ConsumptionUnit.values.map((e) => e.wire).toList(),
      'FuelKind': FuelKind.values.map((e) => e.wire).toList(),
      'VehicleType': VehicleType.values.map((e) => e.wire).toList(),
      'VehicleStatus': VehicleStatus.values.map((e) => e.wire).toList(),
      'ServicePriority': ServicePriority.values.map((e) => e.wire).toList(),
      'ServiceRollover': ServiceRollover.values.map((e) => e.wire).toList(),
      'ExpenseCategory': ExpenseCategory.values.map((e) => e.wire).toList(),
      'TripPurpose': TripPurpose.values.map((e) => e.wire).toList(),
      'OdometerSource': OdometerSource.values.map((e) => e.wire).toList(),
      'OdometerCorrectionReason': OdometerCorrectionReason.values
          .map((e) => e.wire)
          .toList(),
      'ServiceKind': ServiceKind.values.map((e) => e.wire).toList(),
    };

    for (final MapEntry(key: name, value: wires) in enums.entries) {
      expect(wires.toSet(), hasLength(wires.length), reason: name);
      for (final wire in wires) {
        expect(
          RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(wire),
          isTrue,
          reason: '$name.$wire is not snake_case',
        );
      }
    }
  });
}
