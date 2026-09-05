// Every sentence Home says about one card, chosen from what the engine
// concluded.
//
// A MAPPER, never a string builder. SPEC.md §2 forbids assembling a sentence
// from parts, because a sentence built in Dart is a sentence no translator can
// reorder — so this file picks an ICU message and hands it arguments, and every
// word a user reads lives in the six ARB files.
//
// The rule that costs the most to get right is the last row of §9's estimate
// table: at `confidence = default` there is NO date and NO figure. The card
// asks for a reading instead. A screen that guesses and looks certain is what
// §1's third fact about the user exists to prevent.
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/l10n/relative_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';

/// What the primary button on a card does.
///
/// An enum rather than a route string, because the destination is EPIC-11's and
/// the copy is this file's — and the two should not have to change together.
enum HomeAction {
  /// Record that the job was done. §9's default for anything actionable.
  logIt,

  /// Ask for a reading first. §9 gives this to `needs_odometer`, and to
  /// `due_soon` on the distance axis when the rate is not trusted — in both
  /// cases the app cannot say when without one.
  updateOdometer,
}

/// Which button [assessment] earns.
HomeAction homeActionKey(DueAssessment assessment) =>
    assessment.state == DueState.needsOdometer || _mustAskForReading(assessment)
    ? HomeAction.updateOdometer
    : HomeAction.logIt;

/// Whether the card may print a figure or a date at all.
///
/// §9: at `confidence = default` on the distance axis, "No date and no figure."
/// The rate behind a projection at that confidence is the app's own guess about
/// a car it has one reading for, and dressing it up as `in about 5,000 km`
/// makes an invention look like a measurement.
bool _mustAskForReading(DueAssessment assessment) =>
    assessment.state == DueState.dueSoon &&
    assessment.driver == DueDriver.distance &&
    assessment.confidence == RateConfidence.defaulted;

/// The status line one card shows, already shaped and isolated.
String homeStatusLine(
  AppLocalizations l10n,
  String formatsTag,
  DueAssessment assessment,
  DistanceUnit unit,
) {
  String distance(int metres) => formatWithUnit(
    Distance(metres.abs()).inUnit(unit),
    distanceUnitLabel(l10n, unit),
    formatsTag,
    numerals: CalmNumerals.auto,
    decimalDigits: 0,
  );

  return switch (assessment.state) {
    // §9: overdue "uses its own positive string, never 'in −21 days'", and
    // distance leads when both axes are past — a kilometre figure is checkable
    // against the dash and a date is not.
    DueState.overdue => switch (assessment.driver) {
      DueDriver.both => l10n.homeOverdueByBoth(
        distance(assessment.remainingMetres ?? 0),
        _duration(l10n, formatsTag, assessment.remainingDays ?? 0),
      ),
      DueDriver.distance => l10n.homeOverdueByDistance(
        distance(assessment.remainingMetres ?? 0),
      ),
      _ => l10n.homeOverdueByTime(
        _duration(l10n, formatsTag, assessment.remainingDays ?? 0),
      ),
    },
    DueState.due => l10n.homeDueNow,
    DueState.needsOdometer => l10n.homeNeedsOdometer,
    DueState.dueSoon =>
      _mustAskForReading(assessment)
          ? l10n.homeDueSoonNoConfidence
          : assessment.driver == DueDriver.distance
          ? l10n.homeDueSoonDistance(distance(assessment.remainingMetres ?? 0))
          : _relative(l10n, formatsTag, assessment.remainingDays ?? 0),
    // Neither reaches a card: §9 keeps `ok` off Home entirely and collapses
    // `unknown` into its own card, which carries no status line.
    DueState.ok || DueState.unknown => '',
  };
}

/// The card's THIRD line: what the status is measured against.
///
/// SPEC.md §9's card table, and the card's only checkable fact — "Overdue by
/// 900 km" is a claim, "Was due at 186,512 km" is a number the user can hold
/// against their own dash.
///
/// Null when the app cannot stand behind anything. §9's `default` confidence
/// row gives the card "no date and no figure", and an anchor line would smuggle
/// one back in under a different heading.
String? homeAnchorLine(
  AppLocalizations l10n,
  String formatsTag,
  DueAssessment assessment,
  DistanceUnit unit,
) {
  final metres = assessment.dueAtOdometerMetres;
  final odometer = metres == null
      ? null
      : formatWithUnit(
          Distance(metres).inUnit(unit),
          distanceUnitLabel(l10n, unit),
          formatsTag,
          numerals: CalmNumerals.auto,
          decimalDigits: 0,
        );
  final on = assessment.dueOn;
  final date = on == null ? null : formatLongDate(on.toString(), formatsTag);

  return switch (assessment.state) {
    DueState.overdue => switch ((odometer, date)) {
      (final o?, final d?) => l10n.homeWasDueAtOn(o, d),
      (final o?, null) => l10n.homeWasDueAt(o),
      (null, final d?) => l10n.homeWasDueOn(d),
      _ => null,
    },
    DueState.due => switch ((odometer, date)) {
      (final o?, final d?) => l10n.homeDueAtOn(o, d),
      (final o?, null) => l10n.homeDueAt(o),
      (null, final d?) => d,
      _ => null,
    },
    // §9: "Last entered 12 July". It states what the app HAS rather than what
    // it wants — an accusation it cannot support is the thing this state exists
    // to avoid making.
    DueState.needsOdometer => date == null ? null : l10n.homeLastEntered(date),
    DueState.dueSoon => _softDate(l10n, formatsTag, assessment, date),
    // Neither reaches a card with an anchor: §9 keeps `ok` off Home and
    // collapses `unknown` into a card that carries no lines of its own.
    DueState.ok || DueState.unknown => null,
  };
}

/// The `due_soon` anchor: a plain date from the calendar, a hedged one from the
/// odometer, or nothing.
///
/// The time axis produces a date by calendar arithmetic and §9 renders it
/// "exact and plain". The distance axis produces one by projecting a rate, and
/// only at `measured` — a rate drawn from the user's own readings — may it be
/// shown at all, hedged with the one word §9 allows.
///
/// `assumed` gets nothing here, though §9 gives it a MONTH-precision phrase
/// ("around mid-October"). Nothing in the app formats a month-precision date
/// yet, and inventing a day for it would be the exact substitution this
/// function exists to refuse. Recorded in epics/progress/EPIC-10.md.
String? _softDate(
  AppLocalizations l10n,
  String formatsTag,
  DueAssessment assessment,
  String? date,
) {
  if (assessment.driver != DueDriver.distance) return date;
  if (assessment.confidence != RateConfidence.measured) return null;
  final projected = assessment.projectedDueDate;
  if (projected == null) return null;
  return l10n.homeAroundDate(formatLongDate(projected.toString(), formatsTag));
}

/// `Today`, `Tomorrow`, `in 5 days`, `in about 3 weeks`, `in about 5 months`.
///
/// Through `bucketRelativeDays`, which is the same function the past side uses.
/// One vocabulary in both directions: a user who reads "4 months ago" on one
/// screen should not read "in 122 days" on the next.
String _relative(AppLocalizations l10n, String formatsTag, int days) {
  final (:bucket, :count) = bucketRelativeDays(days);
  final n = formatForDisplay(count, formatsTag, numerals: CalmNumerals.auto);
  return switch (bucket) {
    RelativeDateBucket.today => l10n.dateToday,
    RelativeDateBucket.tomorrow => l10n.dateTomorrow,
    RelativeDateBucket.inDays => l10n.dateInDays(count, n),
    RelativeDateBucket.inAboutWeeks => l10n.dateInAboutWeeks(count, n),
    RelativeDateBucket.inAboutMonths => l10n.dateInAboutMonths(count, n),
    // The past buckets cannot be reached from a forward-looking count, and
    // returning today's word for one is better than a thrown exception on a
    // card the user is looking at.
    _ => l10n.dateToday,
  };
}

/// How far past due, as a phrase — `3 weeks`, never `−21 days`.
///
/// The same buckets read forwards: the OVERSHOOT is a positive quantity, and
/// §9's sentence supplies the word "overdue" around it.
String _duration(AppLocalizations l10n, String formatsTag, int days) {
  final overshoot = days.abs();
  final (:bucket, :count) = bucketRelativeDays(overshoot);
  final n = formatForDisplay(count, formatsTag, numerals: CalmNumerals.auto);
  return switch (bucket) {
    RelativeDateBucket.inAboutWeeks => l10n.homeDurationWeeks(count, n),
    RelativeDateBucket.inAboutMonths => l10n.homeDurationMonths(count, n),
    _ => l10n.homeDurationDays(count, n),
  };
}
