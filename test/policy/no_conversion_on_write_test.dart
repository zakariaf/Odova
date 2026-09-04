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
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib/data')) {
      final source = sourceWithoutLineComments(file);
      for (final match in _conversionGetters.allMatches(source)) {
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
    for (final bad in [
      'odometerM: reading.distance.km,',
      'quantity: fill.volume.litres,',
      'value: energy.kwh,',
      'x: d.inUnit(unit),',
    ]) {
      expect(_conversionGetters.hasMatch(bad), isTrue, reason: bad);
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
      expect(_conversionGetters.hasMatch(good), isFalse, reason: good);
    }
  });
  test('only the mapper unwraps a value object into a column', () {
    // The read direction had an invariant and the write direction had nothing.
    // `moneyOrNull` refuses to build half a price — an amount without its
    // currency is not a smaller amount, it is an unknown one — and then forty
    // sites across five repositories unwrapped `.amountMinor` and
    // `.currency.code` straight into companions, where writing one without the
    // other compiles and produces a row nothing above the mapper can read.
    //
    // So the unwrap lives in one file, next to the function that does the
    // reverse, and this says so. `lib/data/db/mappers/` is exempt because it
    // IS the layer that knows both shapes; everything else asks it.
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib/data')) {
      if (file.path.startsWith('lib/data/db/mappers/')) continue;
      final source = sourceWithoutLineComments(file);
      for (final match in RegExp(
        r'\.(amountMinor|metres|millilitres|grams|wattHours)\b'
        r'|\.currency\.code\b',
      ).allMatches(source)) {
        final line = source.substring(0, match.start).split('\n').length;
        offenders.add('${file.path}:$line ${match.group(0)}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'unwrap through lib/data/db/mappers/ — amountMinorColumn, '
          'currencyColumn, metresColumn and the three quantity writers — so '
          'a pair is always written as a pair',
    );
  });
}
