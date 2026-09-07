// SPEC.md §10 `trips.edit` — the field table's four validations and the
// distance rule that keeps the odometer the source of truth.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/trips/trip_draft.dart';
import 'package:test/test.dart';

final CivilDate _today = CivilDate.tryParse('2026-09-07')!;

TripDraft _draft({
  String startedOn = '2026-09-01',
  String? endedOn = '2026-09-03',
  bool stillGoing = false,
  String startOdometer = '',
  String endOdometer = '',
  String manualDistance = '',
}) => TripDraft(
  purpose: TripPurpose.business,
  startedOn: startedOn,
  endedOn: endedOn,
  stillGoing: stillGoing,
  startOdometer: startOdometer,
  endOdometer: endOdometer,
  manualDistance: manualDistance,
);

void main() {
  test('purpose prefills from whether the vehicle is driven for work', () {
    expect(
      TripDraft.create(
        today: _today,
        drivenForWork: true,
        groupingSeparator: ',',
      ).purpose,
      TripPurpose.business,
    );
    expect(
      TripDraft.create(
        today: _today,
        drivenForWork: false,
        groupingSeparator: ',',
      ).purpose,
      TripPurpose.personal,
    );
    // Both dates today, nothing else filled — §10's Create column.
    final draft = TripDraft.create(
      today: _today,
      drivenForWork: false,
      groupingSeparator: ',',
    );
    expect(draft.startedOn, '2026-09-07');
    expect(draft.endedOn, '2026-09-07');
    expect(draft.stillGoing, isFalse);
  });

  test('a future start is refused; today is not', () {
    expect(
      _draft(startedOn: '2026-09-08').problems(today: _today),
      contains(TripProblem.startInFuture),
    );
    expect(
      _draft(
        startedOn: '2026-09-07',
        endedOn: '2026-09-07',
      ).problems(today: _today),
      isEmpty,
    );
  });

  test('an end before the start is refused', () {
    expect(
      _draft(
        startedOn: '2026-09-03',
        endedOn: '2026-09-01',
      ).problems(today: _today),
      contains(TripProblem.endBeforeStart),
    );
  });

  test('Still going clears the end date and the end odometer', () {
    final ended = _draft(endOdometer: '187412');
    final open = ended.withStillGoing(going: true);

    expect(open.endedOn, isNull);
    expect(open.endOdometer, '');
    // And the fields it cleared cannot then fail validation.
    expect(open.problems(today: _today), isEmpty);
  });

  test('an end reading below the start is refused', () {
    expect(
      _draft(
        startOdometer: '187412',
        endOdometer: '187000',
      ).problems(today: _today),
      contains(TripProblem.endBelowStart),
    );
    expect(
      _draft(
        startOdometer: '187000',
        endOdometer: '187412',
      ).problems(today: _today),
      isEmpty,
    );
  });

  group('the distance rule', () {
    test('distance is editable only when BOTH odometer fields are empty', () {
      expect(_draft().distanceIsEditable, isTrue);
      expect(_draft(startOdometer: '187000').distanceIsEditable, isFalse);
      expect(_draft(endOdometer: '187412').distanceIsEditable, isFalse);
    });

    test('a manual distance of zero is refused', () {
      expect(
        _draft(manualDistance: '0').problems(today: _today),
        contains(TripProblem.distanceNotPositive),
      );
      expect(_draft(manualDistance: '145').problems(today: _today), isEmpty);
    });

    test('a manual distance is ignored once an odometer pair exists', () {
      // §3: the manual figure is written ONLY when both endpoints are absent.
      // A stale `0` left in the field must not refuse a save whose distance
      // now comes from the odometer.
      final draft = _draft(
        startOdometer: '187000',
        endOdometer: '187145',
        manualDistance: '0',
      );

      expect(draft.problems(today: _today), isEmpty);
      expect(draft.manualDistanceMetres(unit: DistanceUnit.km), isNull);
    });

    test('a bare distance emits no odometer readings', () {
      final bare = _draft(manualDistance: '145');
      expect(bare.manualDistanceMetres(unit: DistanceUnit.km), 145_000);
      expect(bare.startOdometerMetres(unit: DistanceUnit.km), isNull);
      expect(bare.endOdometerMetres(unit: DistanceUnit.km), isNull);
    });

    test('an odometer pair converts through the entry unit', () {
      final miles = _draft(startOdometer: '100', endOdometer: '200');
      expect(miles.startOdometerMetres(unit: DistanceUnit.mi), 160_934);
      expect(miles.endOdometerMetres(unit: DistanceUnit.mi), 321_868);
    });
  });

  test('a draft with nothing in it is not dirty', () {
    final fresh = TripDraft.create(
      today: _today,
      drivenForWork: false,
      groupingSeparator: ',',
    );
    expect(fresh.isDirty(fresh), isFalse);
    expect(fresh.withTitle('Munich run').isDirty(fresh), isTrue);
  });

  test('a German 12.345 is twelve thousand kilometres, not twelve', () {
    // The default `','` stood while every other form in the app passed
    // `groupingSeparatorFor(tag)`, so a German user typing `12.345` had the
    // dot read as a DECIMAL POINT — 12,345 km stored as 12,345 metres, and
    // fanned out as two `odometer_readings` rows. Silent corruption of the
    // one series this app treats as the source of truth.
    const german = TripDraft(
      purpose: TripPurpose.business,
      startedOn: '2026-09-01',
      manualDistance: '12.345',
      groupingSeparator: '.',
    );

    expect(
      german.manualDistanceMetres(unit: DistanceUnit.km),
      12_345_000,
    );
  });
}
