// A phone whose date is wrong stops answering rather than answering wrongly.
//
// SPEC.md §3 *Invariants and validation*: "`today` is validated on every resume
// against `[build_date, build_date + 10 years]`. Outside that range the app
// enters clock-suspect mode … every due state renders `unknown`, no
// notification is scheduled … Without this, a phone that reset to 1970 writes
// records whose dates are indistinguishable from real ones afterwards."
//
// §14 gave a second trigger — "before the newest `created_at`, or more than 24
// hours ahead of it" — and a second consequence, that confidence drops to
// `assumed`. The two cannot both hold, §3 owns the domain contract, and §14's
// trigger fires for anyone who opens the app on a Wednesday having last used it
// on a Monday. That clause is corrected in the same commit as this file.
//
// The window is generous on purpose. It is not trying to detect a clock a few
// hours out; it is trying to catch a device that has lost its date entirely,
// which is the only case where the app can be CERTAIN and the only case where
// refusing to answer is better than answering.
import 'package:meta/meta.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/value_equality.dart';

/// How many years past the build date a clock is still believed.
///
/// Ten. A device still running this build in 2036 is more likely to have a
/// broken clock than to be a decade-old install, and either way the app cannot
/// tell the difference — which is why the consequence is to say `unknown`
/// rather than to guess.
const kClockTrustYears = 10;

/// Whether the device clock can be believed.
@immutable
class ClockSuspicion with ValueEquality {
  /// Creates a verdict.
  const ClockSuspicion({required this.isSuspect, required this.observedToday});

  /// Whether `today` fell outside the trusted window.
  ///
  /// When true, SPEC.md §3 requires every due state to render `unknown`, no
  /// notification to be scheduled, and every logging form to default its date
  /// to the newest `occurred_on` in the database with Save blocked.
  final bool isSuspect;

  /// The date the device reported, whether or not it is believed.
  ///
  /// Carried so the banner can quote it — §3's copy is "Your phone's date looks
  /// wrong — {date}", and a banner that cannot name the date gives the user
  /// nothing to check against.
  final CivilDate observedToday;

  @override
  List<Object?> get props => [isSuspect, observedToday];

  @override
  String toString() =>
      'ClockSuspicion(${isSuspect ? 'suspect' : 'trusted'}, $observedToday)';
}

/// Validates [today] against `[buildDate, buildDate + 10 years]`.
///
/// Both ends are INCLUSIVE: somebody installs the app the day it ships, and a
/// decade later to the day is still inside a window whose whole purpose is to
/// be generous.
ClockSuspicion assessClock({
  required CivilDate today,
  required CivilDate buildDate,
}) {
  final latest = buildDate.addMonths(kClockTrustYears * 12);
  return ClockSuspicion(
    isSuspect: today < buildDate || today > latest,
    observedToday: today,
  );
}
