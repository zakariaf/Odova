// Conversion is a read-time act. A converted value must never reach a column.
//
// SPEC.md §3 Canonical units: "Convert on read, never on write." The failure
// this prevents is silent and permanent — a fill-up stored in gallons because
// the form was in gallons reads back as litres for the next user, and eight
// years of consumption figures are wrong by 3.785 with nothing to say so.
//
// `lib/data/` is where a value becomes a column, so that is where the ban
// applies. The getters are perfectly correct one layer up.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import '../support/source_tree.dart';

/// A call to a conversion getter.
///
/// The negative lookbehind is load-bearing: `DistanceUnit.km` and
/// `VolumeUnit.l` are ENUM VALUES, and the data layer reads them all day to
/// store the provenance unit a record was entered in. Without it the gate
/// fires on every table mapper and the only way to make it green is to delete
/// it.
final _conversionGetters = RegExp(
  '(?<!(?:Distance|Volume|Consumption)Unit)'
  r'\.(km|miles|litres|gallonsUs|gallonsUk|kwh|kg|inUnit)\b'
  r'(?!\s*[:=])',
);

void main() {
  test('lib/data calls no conversion getter', () {
    // Matched as a member access — `.km` on its own would fire on a variable
    // named `km`, and `.litres` would fire on a field. A leading dot and a
    // non-word character after is the shape of a getter call.
    final conversions = _conversionGetters;

    final offenders = <String>[];
    for (final file in dartFilesUnder('lib/data')) {
      final source = sourceWithoutLineComments(file);
      for (final match in conversions.allMatches(source)) {
        final line = source.substring(0, match.start).split('\n').length;
        offenders.add('${file.path}:$line ${match.group(0)}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a converted value must never reach a column — SPEC.md §3 '
          'stores metres, millilitres, grams and watt-hours, and converts on '
          'READ',
    );
  });

  test('the matcher recognises the shapes it claims to', () {
    // Guard the guard: this test greps, and a pattern that matches nothing
    // reports a clean tree.
    final conversions = _conversionGetters;

    for (final bad in [
      'odometerM: reading.distance.km,',
      'quantity: fill.volume.litres,',
      'value: energy.kwh,',
      'x: d.inUnit(unit),',
    ]) {
      expect(conversions.hasMatch(bad), isTrue, reason: bad);
    }

    // And does not fire on a canonical read, which is what the data layer
    // legitimately does all day.
    for (final good in [
      'odometerM: reading.distance.metres,',
      'quantityMl: volume.millilitres,',
      'energyWh: energy.wattHours,',
      'grams: mass.grams,',
      // The enum values, which the data layer reads all day to store the
      // provenance unit a record was entered in. Firing on these would make
      // the gate unusable, and deleting it the only way to get green.
      'odometerUnit: DistanceUnit.km.wire,',
      'unit: reading.odometerUnit ?? DistanceUnit.km,',
    ]) {
      expect(conversions.hasMatch(good), isFalse, reason: good);
    }
  });
}
