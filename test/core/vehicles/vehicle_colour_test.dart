// SPEC.md §8's colour swatches, as a stored vocabulary.
//
// `Vehicle.colour` is a nullable string in the schema and in the backup file,
// so the enum's job is to be the ONLY thing that writes one — a free-form
// column with nine sanctioned values is a column that ends up with ten.
import 'package:odova/core/vehicles/vehicle_colour.dart';
import 'package:test/test.dart';

void main() {
  test('nine values, in the order the row draws them', () {
    // EPIC-09 F-9.18: eight paints from the artboard plus `other`, which is not
    // a paint. Brown is deliberately absent — the eight are hand-tuned against
    // each other and a ninth hex is design work, not engineering.
    expect(VehicleColour.values.map((c) => c.wire), [
      'white',
      'silver',
      'grey',
      'black',
      'red',
      'blue',
      'green',
      'yellow',
      'other',
    ]);
  });

  test('the wire value is the enum name, so the two cannot drift', () {
    for (final colour in VehicleColour.values) {
      expect(colour.wire, colour.name, reason: '$colour');
    }
  });

  test('an unknown stored value reads as null, never as a guess', () {
    // A backup written by a future version, or by a hand. SPEC.md §2: the app
    // never guesses in a way that looks like fact, and silently mapping
    // `brown` to `red` would repaint somebody's car.
    expect(VehicleColour.tryParse('white'), VehicleColour.white);
    expect(VehicleColour.tryParse('brown'), isNull);
    expect(VehicleColour.tryParse(''), isNull);
    expect(VehicleColour.tryParse(null), isNull);
    // Case matters: the wire is lower-case and a writer that emits `White` has
    // a bug worth seeing.
    expect(VehicleColour.tryParse('White'), isNull);
  });
}
