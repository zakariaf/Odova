// SPEC.md §10's `trips.edit` form, as a value object.
//
// The one rule worth reading twice is the distance rule, and it is the reason
// this file exists rather than four booleans on a widget:
//
//   A manual distance is written ONLY when both odometer endpoints are absent,
//   and a bare-distance trip contributes NOTHING to the odometer series.
//
// People log some trips and not others. If a trip could push a number into the
// odometer history, the vehicle's cumulative distance would be the sum of
// whatever the user happened to bracket — a figure that looks authoritative
// and is not. `manualDistanceMetres` returns null the moment either endpoint
// is filled, so the wrong write is unconstructible rather than merely
// discouraged.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/odometer/odometer_entry.dart';
import 'package:odova/core/time/civil_date.dart';

/// The sentinel that means "leave this field alone" in a copy.
///
/// `?? this.x` cannot say the difference between "unchanged" and "cleared",
/// and Still going has to CLEAR the end date.
const Object _keep = Object();

/// What is wrong with the draft, in the order §10's form reads.
enum TripProblem {
  /// The start is after today. §10: "Pick today or a day in the past."
  startInFuture,

  /// The end date is before the start date.
  endBeforeStart,

  /// The end reading is lower than the start reading.
  endBelowStart,

  /// A hand-typed distance of zero or less.
  distanceNotPositive,
}

/// One trip on its way to a row.
@immutable
class TripDraft {
  /// Creates a draft.
  const TripDraft({
    required this.purpose,
    required this.startedOn,
    this.title = '',
    this.endedOn,
    this.stillGoing = false,
    this.startOdometer = '',
    this.endOdometer = '',
    this.manualDistance = '',
    this.notes = '',
    this.groupingSeparator = ',',
  });

  /// §10's Create column: both dates today, nothing else filled.
  ///
  /// [drivenForWork] is the vehicle's own answer to "do you drive this for
  /// work?". Business and Personal, never Commute — a prefill that guessed
  /// commute would put the least deductible purpose on a form whose whole
  /// point is the deductible one.
  factory TripDraft.create({
    required CivilDate today,
    required bool drivenForWork,
  }) {
    final on = today.toString();
    return TripDraft(
      purpose: drivenForWork ? TripPurpose.business : TripPurpose.personal,
      startedOn: on,
      endedOn: on,
    );
  }

  /// Why it was taken.
  final TripPurpose purpose;

  /// What to call it. Empty falls back to the date range in lists.
  final String title;

  /// The day it began.
  final String startedOn;

  /// The day it ended, or null for an open trip.
  final String? endedOn;

  /// Whether the trip is still running.
  final bool stillGoing;

  /// The start reading, as typed.
  final String startOdometer;

  /// The end reading, as typed.
  final String endOdometer;

  /// A distance typed by hand.
  final String manualDistance;

  /// Free text.
  final String notes;

  /// The thousands separator of the locale this form is being typed in.
  ///
  /// Carried, never read from a locale: a value object that reads a locale is
  /// a value object that answers differently in Tehran and Toronto.
  final String groupingSeparator;

  /// Whether the Distance field accepts input.
  ///
  /// §10: "editable only when **both** odometer fields are empty." The
  /// odometer wins whenever it can answer, and a field that stays editable
  /// beside a computed figure is an invitation to disagree with it.
  bool get distanceIsEditable =>
      startOdometer.trim().isEmpty && endOdometer.trim().isEmpty;

  /// Whether anything differs from [original].
  ///
  /// Takes the prefill rather than assuming an empty one: §10 prefills both
  /// dates and the purpose, so "any content at all" — the rule the log forms
  /// use — would call a freshly opened trip form dirty.
  bool isDirty(TripDraft original) =>
      purpose != original.purpose ||
      title != original.title ||
      startedOn != original.startedOn ||
      endedOn != original.endedOn ||
      stillGoing != original.stillGoing ||
      startOdometer != original.startOdometer ||
      endOdometer != original.endOdometer ||
      manualDistance != original.manualDistance ||
      notes != original.notes;

  /// The start reading in metres, or null when it is not a number.
  int? startOdometerMetres({required DistanceUnit unit}) =>
      _entry(startOdometer, unit).metres;

  /// The end reading in metres, or null.
  int? endOdometerMetres({required DistanceUnit unit}) =>
      _entry(endOdometer, unit).metres;

  /// The hand-typed distance in metres, or null.
  ///
  /// **Null whenever either odometer endpoint is filled**, whatever is left in
  /// the field. A user who types a distance, then remembers the readings, then
  /// enters them, must not have the stale figure written underneath the pair —
  /// §3 says the odometer wins and this is where that is enforced, once, for
  /// every caller.
  int? manualDistanceMetres({required DistanceUnit unit}) {
    if (!distanceIsEditable) return null;
    return _entry(manualDistance, unit).metres;
  }

  /// Everything wrong with this draft, in the order the form reads.
  List<TripProblem> problems({required CivilDate today}) {
    final problems = <TripProblem>[];

    final start = CivilDate.tryParse(startedOn);
    if (start != null && start > today) problems.add(TripProblem.startInFuture);

    // Only when the trip has an end at all. Still going has cleared it, and a
    // cleared field cannot be wrong.
    final end = stillGoing ? null : CivilDate.tryParse(endedOn ?? '');
    if (start != null && end != null && end < start) {
      problems.add(TripProblem.endBeforeStart);
    }

    // In METRES, not in the typed string: `100` in miles and `150` in km are
    // in the same unit here, and comparing the strings would compare two
    // scales. The unit is the same for both fields by construction — §10 draws
    // one unit selector for the pair — so either one will do.
    const unit = DistanceUnit.km;
    final from = _entry(startOdometer, unit).metres;
    final to = stillGoing ? null : _entry(endOdometer, unit).metres;
    if (from != null && to != null && to < from) {
      problems.add(TripProblem.endBelowStart);
    }

    // Only when the field is the one that answers. A stale `0` behind an
    // odometer pair is not a validation failure; it is a value nothing reads.
    if (distanceIsEditable && manualDistance.trim().isNotEmpty) {
      final metres = _entry(manualDistance, unit).metres;
      if (metres == null || metres <= 0) {
        problems.add(TripProblem.distanceNotPositive);
      }
    }

    return problems;
  }

  /// A copy with the purpose replaced.
  TripDraft withPurpose(TripPurpose next) => _copy(purpose: next);

  /// A copy with the title replaced.
  TripDraft withTitle(String value) => _copy(title: value);

  /// A copy with the start date replaced.
  TripDraft withStartedOn(String value) => _copy(startedOn: value);

  /// A copy with the end date replaced.
  TripDraft withEndedOn(String value) => _copy(endedOn: value);

  /// A copy with Still going set.
  ///
  /// Ticking CLEARS the end date and the end odometer, per §10's field table.
  /// Hiding them without clearing is what leaves an invisible end date on a
  /// trip the user has just said is still running — and then refuses the save
  /// with an error pointing at a field that is not on screen.
  TripDraft withStillGoing({required bool going}) => _copy(
    stillGoing: going,
    endedOn: going ? null : _keep,
    endOdometer: going ? '' : null,
  );

  /// A copy with the start reading replaced.
  TripDraft withStartOdometer(String value) => _copy(startOdometer: value);

  /// A copy with the end reading replaced.
  TripDraft withEndOdometer(String value) => _copy(endOdometer: value);

  /// A copy with the hand-typed distance replaced.
  TripDraft withManualDistance(String value) => _copy(manualDistance: value);

  /// A copy with the notes replaced.
  TripDraft withNotes(String value) => _copy(notes: value);

  OdometerEntry _entry(String text, DistanceUnit unit) => OdometerEntry(
    unit: unit,
    groupingSeparator: groupingSeparator,
    text: text,
    // The implausible-value warning belongs to `log.odometer`'s field, which
    // offers "Use it anyway". This form has no such affordance, and a draft
    // that reported a problem nobody could clear would be a save nobody could
    // complete.
    warningAccepted: true,
  );

  TripDraft _copy({
    TripPurpose? purpose,
    String? title,
    String? startedOn,
    Object? endedOn = _keep,
    bool? stillGoing,
    String? startOdometer,
    String? endOdometer,
    String? manualDistance,
    String? notes,
  }) => TripDraft(
    purpose: purpose ?? this.purpose,
    title: title ?? this.title,
    startedOn: startedOn ?? this.startedOn,
    endedOn: endedOn == _keep ? this.endedOn : endedOn as String?,
    stillGoing: stillGoing ?? this.stillGoing,
    startOdometer: startOdometer ?? this.startOdometer,
    endOdometer: endOdometer ?? this.endOdometer,
    manualDistance: manualDistance ?? this.manualDistance,
    notes: notes ?? this.notes,
    groupingSeparator: groupingSeparator,
  );
}
