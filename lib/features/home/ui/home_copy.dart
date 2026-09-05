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
