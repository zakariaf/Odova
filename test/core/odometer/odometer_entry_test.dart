// A typed odometer, read.
//
// The rule worth the most care is the one an implementation gets wrong by
// being careful: above three million kilometres the app WARNS, and a warning
// that stops Save is a block wearing a warning's clothes.
@TestOn('vm')
library;

import 'package:odova/core/odometer/odometer_entry.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

OdometerEntry _entry(String text, {DistanceUnit unit = DistanceUnit.km}) =>
    OdometerEntry(unit: unit, groupingSeparator: ',', text: text);

void main() {
  test('a plain reading parses in the unit the field is showing', () {
    expect(_entry('187412').metres, const Distance.fromKm(187412).metres);
    expect(
      _entry('187412', unit: DistanceUnit.mi).metres,
      const Distance.fromMiles(187412).metres,
    );
    expect(_entry('187,412').metres, const Distance.fromKm(187412).metres);
    expect(_entry('0').problem, isNull, reason: 'new cars exist');
  });

  test('anything that is not a whole reading is refused', () {
    expect(_entry('').problem, OdometerProblem.empty);
    expect(_entry('   ').problem, OdometerProblem.empty);
    expect(_entry('twelve').problem, OdometerProblem.notANumber);
    expect(_entry('1000.5').problem, OdometerProblem.notANumber);
    expect(_entry('-5').problem, OdometerProblem.notANumber);
    for (final text in ['', 'twelve', '1000.5']) {
      expect(_entry(text).usable, isFalse, reason: text);
    }
  });

  test('an implausible reading warns and is still usable', () {
    // SPEC.md §8: "a warning with a 'Use it anyway' affordance, never a
    // block". Both halves in one test, because they are one sentence.
    final doubted = _entry('3000001');
    expect(doubted.problem, OdometerProblem.implausible);
    expect(doubted.usable, isTrue);

    final accepted = doubted.copyWith(warningAccepted: true);
    expect(accepted.problem, isNull);
    expect(accepted.usable, isTrue);
  });

  test('a new number is a new question', () {
    // Accepting 3,000,001 must not silently accept the 300,000,001 typed after
    // it — the second is a different mistake and deserves its own ask.
    final accepted = _entry('3000001').copyWith(warningAccepted: true);
    expect(accepted.problem, isNull);
    expect(
      accepted.copyWith(text: '300000001').problem,
      OdometerProblem.implausible,
    );
  });

  test('an accepted warning survives a copy that changes nothing', () {
    // `VehicleEditNotifier.edit` re-units the entry on every keystroke in
    // every other field on the form. A `copyWith` that dropped the acceptance
    // unless it was restated brought the warning back the moment the user
    // typed one letter of the make.
    final accepted = _entry('3000001').copyWith(warningAccepted: true);
    expect(accepted.copyWith(unit: DistanceUnit.km).problem, isNull);
    expect(accepted.copyWith(text: '3000001').problem, isNull);
    expect(accepted.copyWith().problem, isNull);
  });

  test('a new unit is a new question, like a new number', () {
    // 3,000,001 MILES is not the number 3,000,001 km was — it is nearly five
    // million kilometres, and the app has not been told to accept that one.
    final accepted = _entry('3000001').copyWith(warningAccepted: true);
    expect(
      accepted.copyWith(unit: DistanceUnit.mi).problem,
      OdometerProblem.implausible,
    );
  });

  test('three million exactly is not implausible', () {
    // The boundary is ABOVE three million. A reading of exactly the limit is a
    // number the app has no reason to doubt.
    expect(_entry('3000000').problem, isNull);
    expect(_entry('3000001').problem, OdometerProblem.implausible);
  });
}
