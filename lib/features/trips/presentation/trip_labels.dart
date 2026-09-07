// The strings `trips.list` and `trips.edit` both need, formatted once.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/money_total.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/money_format.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';

/// The dot the meta line and the mixed-currency list are joined with.
const kTripsSeparator = ' · ';

/// A purpose, in the user's language.
///
/// An exhaustive switch with no `default`: a purpose added to SPEC.md §10's
/// enum should stop the build here rather than render as an empty chip.
String tripPurposeLabel(AppLocalizations l10n, TripPurpose purpose) =>
    switch (purpose) {
      TripPurpose.business => l10n.tripsPurposeBusiness,
      TripPurpose.commute => l10n.tripsPurposeCommute,
      TripPurpose.personal => l10n.tripsPurposePersonal,
      TripPurpose.other => l10n.tripsPurposeOther,
    };

/// A trip's date range, at its shortest.
///
/// Two short dates joined by an en dash rather than the reference's `1–2 Aug`
/// elision. Collapsing a same-month range needs to know whether the day
/// precedes the month, which is a per-locale fact `intl` will answer for a
/// whole date and not for half of one — and getting it wrong prints `Aug 1–2`
/// as `1–2 Aug` in the four locales that do not agree with English. The
/// longer form is right in all six.
String tripDateRange(String startedOn, String? endedOn, String formatsTag) {
  final start = formatShortDayMonth(startedOn, formatsTag);
  if (endedOn == null || endedOn == startedOn) return start;
  return '$start – ${formatShortDayMonth(endedOn, formatsTag)}';
}

/// A trip's cost, or null when nothing has been attributed to it.
///
/// Per-currency and joined, never summed: `26.50 € · £80.00` is two facts and
/// there is no rate in this app that could honestly make it one.
String? tripCostLabel(MoneyTotal cost, String formatsTag) {
  if (cost.isEmpty) return null;
  final codes = cost.byCurrency.keys.toList()
    ..sort((a, b) => a.code.compareTo(b.code));
  return [
    for (final currency in codes)
      formatMoney(
        cost.inCurrency(currency),
        formatsTag,
        numerals: CalmNumerals.auto,
      ),
  ].join(kTripsSeparator);
}

/// A distance with its unit, unisolated so a caller can join it into a line.
String tripDistanceLabel(
  AppLocalizations l10n,
  String formatsTag,
  Distance distance,
  DistanceUnit unit,
) => withUnitUnisolated(
  distance.inUnit(unit),
  distanceUnitLabel(l10n, unit),
  formatsTag,
  numerals: CalmNumerals.auto,
  decimalDigits: 0,
);
