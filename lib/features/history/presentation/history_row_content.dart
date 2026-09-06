// An entry's two lines, per §11's type table.
//
//   Fill-up   `52.10 L · 189,204 km`     / station, then grade
//   Partial   `20.00 L · partial`        / station
//   Service   labels joined by `·`       / vendor · odometer
//   Expense   category, or `label`       / vendor, or the coverage window
//   Trip      title, else the range      / `412 km · business`
//   Odometer  `189,204 km`               / `Reading`
//
// This is presentation, so it takes a locale and formats; the DECISIONS about
// what a row means — which badge, which figure — are `lib/core/history/`'s and
// are not re-made here.
import 'package:odova/core/history/history_entry.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';

/// What one row says.
typedef HistoryRowContent = ({String primary, String secondary});

/// [entry]'s two lines in [formatsTag].
HistoryRowContent historyRowContent(
  HistoryEntry entry,
  AppLocalizations l10n, {
  required String formatsTag,
  required DistanceUnit unit,
}) {
  final date = formatLongDate(entry.occurredOn, formatsTag);
  final odometer = entry.odometerM == null
      ? null
      : formatWithUnit(
          Distance(entry.odometerM!).inUnit(unit),
          distanceUnitLabel(l10n, unit),
          formatsTag,
          numerals: CalmNumerals.auto,
          decimalDigits: 0,
        );

  return switch (entry.kind) {
    HistoryEntryKind.fillUp => (
      // A part fill says so IN PLACE of the odometer, per §11's second row:
      // `20.00 L · partial`. It is the fact that explains the missing
      // consumption figure, so it takes the more visible slot.
      primary: [
        ?_quantityText(entry, l10n, formatsTag),
        if (!entry.isFullTank) l10n.logFillUpPartFill else ?odometer,
      ].join(' · '),
      secondary: [date, ?entry.label, ?entry.secondaryLabel].join(' · '),
    ),
    HistoryEntryKind.service => (
      primary: entry.label ?? l10n.logTitleService,
      secondary: [date, ?entry.secondaryLabel, ?odometer].join(' · '),
    ),
    HistoryEntryKind.expense => (
      primary: entry.label ?? l10n.logTitleExpense,
      secondary: [date, ?entry.secondaryLabel].join(' · '),
    ),
    HistoryEntryKind.trip => (
      // §11 falls back to the DATE RANGE when a trip has no title, because a
      // trip with no name is still a trip that happened somewhere.
      primary: entry.label ?? date,
      secondary: [?odometer, ?entry.secondaryLabel].join(' · '),
    ),
    HistoryEntryKind.odometer => (
      primary: odometer ?? '',
      // §11 names what the row IS, because its primary line is only a number
      // and every other row's is a thing.
      secondary: [date, l10n.historyOdometerReading].join(' · '),
    ),
    HistoryEntryKind.correction => (
      primary: odometer ?? '',
      secondary: date,
    ),
  };
}

/// `52.10 L`, `4.5 kg`, `52.4 kWh` — or null where the row has no quantity.
String? _quantityText(
  HistoryEntry entry,
  AppLocalizations l10n,
  String formatsTag,
) {
  final amount = entry.quantity;
  if (amount == null) return null;
  // From the COLUMN the row was written into, not from the vehicle's current
  // fuel kind — a vehicle whose default changed would otherwise re-read its
  // own history in the wrong unit.
  final (value, label) = switch (entry.quantityForm) {
    'ml' => (amount / 1000, l10n.unitVolumeLitre),
    'g' => (amount / 1000, l10n.unitMassKg),
    'wh' => (amount / 1000, l10n.unitEnergyKwh),
    _ => (null, ''),
  };
  if (value == null) return null;
  return formatWithUnit(
    value,
    label,
    formatsTag,
    numerals: CalmNumerals.auto,
    decimalDigits: 2,
  );
}
