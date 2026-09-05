// One reminder, as the form holds it, and the rules that let it be saved.
//
// SPEC.md §9 `reminders.edit`. Pure Dart, no Flutter: the validation is a
// function over the draft, so the four rules can be asserted at their
// boundaries without a widget — and so a screen cannot be the only place that
// knows them.
//
// The draft holds TEXT for every number, because §5 says a field echoes what
// the user typed until it is parsed, and a draft that stored an int would have
// thrown away the difference between "0" and "".
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/l10n/numeric_input.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';

/// Why a draft cannot be saved.
///
/// One member per inline message §9 names, and no `unknown`: a rejection the
/// screen cannot explain is a rejection it must not make.
enum ReminderProblem {
  /// None of the four scheduling fields is set — §9's "otherwise there's
  /// nothing to remind you about".
  noSchedule,

  /// The baseline odometer is below the vehicle's earliest reading.
  baselineBelowFirstReading,

  /// The baseline date is in the future.
  baselineInFuture,

  /// A custom item with no name.
  customNeedsLabel,
}

/// The form's state.
@immutable
class ReminderDraft {
  /// Creates a draft.
  const ReminderDraft({
    required this.unit,
    required this.groupingSeparator,
    this.kind = ServiceKind.custom,
    this.label = '',
    this.intervalDistance = '',
    this.intervalMonths = '',
    this.targetOdometer = '',
    this.targetDate,
    this.baselineDate,
    this.baselineOdometer = '',
    this.noticeDistance = '',
    this.noticeDays = '',
    this.priority = ServicePriority.normal,
    this.rollover = ServiceRollover.fromActual,
    this.notify = true,
    this.repeats = true,
    this.notes = '',
  });

  /// Builds a draft from an existing item.
  factory ReminderDraft.of(
    ServiceItem item, {
    required DistanceUnit unit,
    required String groupingSeparator,
  }) => ReminderDraft(
    unit: unit,
    groupingSeparator: groupingSeparator,
    kind: item.kind,
    label: item.label ?? '',
    // In the ENTERED unit, not in metres. §3 keeps `interval_distance_unit` for
    // display fidelity precisely so a form can show back the number that was
    // typed rather than a conversion of it.
    intervalDistance: _distanceText(item.intervalDistance, unit),
    intervalMonths: item.intervalMonths?.toString() ?? '',
    targetOdometer: _distanceText(item.targetOdometer, unit),
    targetDate: CivilDate.tryParseOrNull(item.targetDate),
    baselineDate: CivilDate.tryParseOrNull(item.baselineDate),
    baselineOdometer: _distanceText(item.baselineOdometer, unit),
    noticeDistance: _distanceText(item.noticeDistance, unit),
    noticeDays: item.noticeDays?.toString() ?? '',
    priority: item.priority,
    rollover: item.rollover,
    notify: item.notify,
    repeats: item.repeats,
    notes: item.notes ?? '',
  );

  /// The unit every distance field is in — the vehicle's, then the app's.
  final DistanceUnit unit;

  /// The locale's grouping separator, for parsing what was typed.
  final String groupingSeparator;

  /// Which catalogue kind, or `custom`.
  final ServiceKind kind;

  /// The name. Required for `custom`, and the table's first row.
  final String label;

  /// `Every … distance`. Blank turns the distance axis off.
  final String intervalDistance;

  /// `Every … months`. Blank turns the time axis off. Months, never days.
  final String intervalMonths;

  /// `Or once, at odometer`.
  final String targetOdometer;

  /// `Or once, on date`. A future date IS allowed here.
  final CivilDate? targetDate;

  /// `Last done — date`. The baseline.
  final CivilDate? baselineDate;

  /// `Last done — odometer`. The other half of the baseline.
  final String baselineOdometer;

  /// `Tell me this far ahead` — distance. Blank means the automatic window.
  final String noticeDistance;

  /// `Tell me this far ahead` — days. Blank means the automatic window.
  final String noticeDays;

  /// Safety, Normal or Low. Breaks ties when the notification cap coalesces.
  final ServicePriority priority;

  /// From the day it was done, or the day it was due.
  final ServiceRollover rollover;

  /// Off still shows on Home and still goes red; it just never posts.
  final bool notify;

  /// Off makes it a one-off that goes `ok` after completion.
  final bool repeats;

  /// Free text.
  final String notes;

  /// A copy with the given changes.
  ///
  /// Every nullable field takes a `clear` flag rather than a null default: a
  /// `copyWith(targetDate: null)` cannot mean "leave it" and "clear it" at
  /// once, and picking one silently is how a date the user removed comes back.
  ReminderDraft copyWith({
    ServiceKind? kind,
    String? label,
    String? intervalDistance,
    String? intervalMonths,
    String? targetOdometer,
    CivilDate? targetDate,
    bool clearTargetDate = false,
    CivilDate? baselineDate,
    bool clearBaselineDate = false,
    String? baselineOdometer,
    String? noticeDistance,
    String? noticeDays,
    ServicePriority? priority,
    ServiceRollover? rollover,
    bool? notify,
    bool? repeats,
    String? notes,
  }) => ReminderDraft(
    unit: unit,
    groupingSeparator: groupingSeparator,
    kind: kind ?? this.kind,
    label: label ?? this.label,
    intervalDistance: intervalDistance ?? this.intervalDistance,
    intervalMonths: intervalMonths ?? this.intervalMonths,
    targetOdometer: targetOdometer ?? this.targetOdometer,
    targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
    baselineDate: clearBaselineDate
        ? null
        : (baselineDate ?? this.baselineDate),
    baselineOdometer: baselineOdometer ?? this.baselineOdometer,
    noticeDistance: noticeDistance ?? this.noticeDistance,
    noticeDays: noticeDays ?? this.noticeDays,
    priority: priority ?? this.priority,
    rollover: rollover ?? this.rollover,
    notify: notify ?? this.notify,
    repeats: repeats ?? this.repeats,
    notes: notes ?? this.notes,
  );

  /// [intervalDistance] as metres, or null when it is blank or unreadable.
  Distance? get intervalDistanceValue => _distance(intervalDistance);

  /// [targetOdometer] as metres.
  Distance? get targetOdometerValue => _distance(targetOdometer);

  /// [baselineOdometer] as metres.
  Distance? get baselineOdometerValue => _distance(baselineOdometer);

  /// [noticeDistance] as metres.
  Distance? get noticeDistanceValue => _distance(noticeDistance);

  /// [intervalMonths] as a whole number of months.
  int? get intervalMonthsValue => _whole(intervalMonths);

  /// [noticeDays] as a whole number of days.
  int? get noticeDaysValue => _whole(noticeDays);

  /// Whether anything at all schedules this item.
  ///
  /// §9's four scheduling fields, and the CHECK on `service_items` says the
  /// same thing in SQL: "an item with no interval and no target can never come
  /// due. It is not a harmless empty row."
  bool get hasSchedule =>
      intervalDistanceValue != null ||
      intervalMonthsValue != null ||
      targetOdometerValue != null ||
      targetDate != null;

  Distance? _distance(String text) {
    if (text.trim().isEmpty) return null;
    final read = normalizeNumericInput(
      text,
      groupingSeparator: groupingSeparator,
    );
    if (read is! NumericInputOk) return null;
    if (read.value <= 0) return null;
    return unit == DistanceUnit.mi
        ? Distance.fromMiles(read.value.round())
        : Distance.fromKm(read.value.round());
  }

  int? _whole(String text) {
    if (text.trim().isEmpty) return null;
    final read = normalizeNumericInput(
      text,
      groupingSeparator: groupingSeparator,
    );
    if (read is! NumericInputOk) return null;
    if (read.value <= 0) return null;
    return read.value.round();
  }

  /// A stored distance as the field shows it: a WHOLE number of [unit].
  ///
  /// Rounded, because [_distance] reads the field back with `.round()` — the
  /// form accepts whole kilometres and whole miles and nothing finer. It used
  /// to print `shown.toString()` for a non-whole value, which for a 10,000 km
  /// interval on a miles vehicle is the literal string
  /// `6213.711922373339`: fifteen decimals in a field the user is expected to
  /// edit, and a number that cannot be typed back.
  static String _distanceText(Distance? value, DistanceUnit unit) {
    if (value == null) return '';
    final shown = unit == DistanceUnit.mi ? value.miles : value.km;
    return shown.round().toString();
  }
}

/// Everything wrong with [draft], in the order §9's form reads.
///
/// A LIST rather than the first problem: §9 puts each message under its own
/// field, and a validator that stopped at the first would make a user fix four
/// things in four round trips.
List<ReminderProblem> validateReminderDraft(
  ReminderDraft draft, {
  required CivilDate today,
  Distance? firstReading,
}) {
  final problems = <ReminderProblem>[];

  if (draft.kind == ServiceKind.custom && draft.label.trim().isEmpty) {
    problems.add(ReminderProblem.customNeedsLabel);
  }
  if (!draft.hasSchedule) problems.add(ReminderProblem.noSchedule);

  final baselineOdometer = draft.baselineOdometerValue;
  if (baselineOdometer != null &&
      firstReading != null &&
      baselineOdometer.metres < firstReading.metres) {
    problems.add(ReminderProblem.baselineBelowFirstReading);
  }

  // The BASELINE only. §9 allows a future target date in as many words — a
  // cambelt at 120,000 km in 2029 is a plan, while "this was last done next
  // March" is a typo.
  final baselineDate = draft.baselineDate;
  if (baselineDate != null && baselineDate.compareTo(today) > 0) {
    problems.add(ReminderProblem.baselineInFuture);
  }

  return List.unmodifiable(problems);
}
