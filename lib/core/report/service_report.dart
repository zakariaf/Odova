// SPEC.md §12: "Turn eight years of records into one document a buyer will
// believe."
//
// Pure, and with no `BuildContext` anywhere near it. The preview IS the
// document — §12 refuses a second renderer — so this model is read by the
// screen, by the PDF writer and by the clipboard writer, and any of the three
// disagreeing with the others is a document that does not match its preview.
//
// Two sentences govern every decision below.
//
// "Never a projection: a document handed to a buyer contains no estimates."
// Everywhere else in this app an estimated odometer is a legitimate answer with
// a `~` on it. Here it is not an answer at all — the header carries the latest
// ENTERED reading and the date it was entered, and a stale one stays stale.
// The exception is a record whose odometer WAS estimated at the time, which is
// a fact about the record rather than a guess made now, and which carries §12's
// footnote instead of being hidden: "a small lie the app has no business
// telling."
//
// "A fine on a sales document is an own goal." §12's exclusion list — fines,
// parking, tolls, washes, fuel receipts, insurance premiums, trip logs — is
// enforced by CONSTRUCTION rather than by a filter: this function takes
// `ServiceRecord`s and a fuel summary, and there is no parameter an expense
// could arrive through.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/money/money_total.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';

/// The four toggles, and their defaults.
///
/// Plate/VIN and notes default OFF and the defaults are the point: §12 calls
/// the identity fields "the buyer's to ask for, not the app's to leak into a
/// group chat", and notes "say things like 'cheaper than the dealer wanted'".
/// A default that leaked either would be discovered by the person it hurt.
@immutable
class ServiceReportOptions {
  /// Creates the options.
  const ServiceReportOptions({
    this.plateAndVin = false,
    this.costs = true,
    this.fuelSummary = true,
    this.notes = false,
  });

  /// Whether the plate and VIN print.
  final bool plateAndVin;

  /// Whether money prints at all.
  final bool costs;

  /// Whether the consumption summary prints.
  final bool fuelSummary;

  /// Whether the owner's private notes print.
  final bool notes;

  /// A copy with the named toggles changed.
  ///
  /// Here so a caller flipping ONE toggle does not respell the other three.
  /// The screen used to rebuild all four fields at each of four chips, and a
  /// transposition there — `fuelSummary: options.notes` — compiles, renders,
  /// and is invisible until somebody's plate turns up in a document.
  ServiceReportOptions copyWith({
    bool? plateAndVin,
    bool? costs,
    bool? fuelSummary,
    bool? notes,
  }) => ServiceReportOptions(
    plateAndVin: plateAndVin ?? this.plateAndVin,
    costs: costs ?? this.costs,
    fuelSummary: fuelSummary ?? this.fuelSummary,
    notes: notes ?? this.notes,
  );
}

/// The document's header block.
@immutable
class ServiceReportHeader {
  /// Creates the header.
  const ServiceReportHeader({
    required this.name,
    required this.ownedFrom,
    required this.today,
    this.make,
    this.model,
    this.year,
    this.fuelKind,
    this.colour,
    this.ownedUntil,
    this.purchaseOdometer,
    this.latestOdometer,
    this.latestOdometerReadOn,
    this.plate,
    this.vin,
    this.notes,
  });

  /// The vehicle's name.
  final String name;

  /// What the document was generated on.
  ///
  /// Here as well as on the document because the ownership span is computed
  /// from it — and it must be the CLOCK's today, never `DateTime.now()`: §3
  /// validates the clock, and a span measured against an unvalidated one is
  /// the projection §12 forbids arriving by a side door.
  final CivilDate today;

  /// Identity, as far as it is known.
  final String? make;

  /// The model.
  final String? model;

  /// The model year.
  final int? year;

  /// What it burns. §12's identity line reads "1.6 TDI · 2016 · Diesel".
  final FuelKind? fuelKind;

  /// The colour.
  final String? colour;

  /// When this owner bought it.
  final String? ownedFrom;

  /// When they sold it, or null while they still have it — which renders as
  /// "today" rather than as today's DATE, because a document printed in
  /// September and read in November should not claim the span ended in
  /// September.
  final String? ownedUntil;

  /// The odometer at purchase.
  final Distance? purchaseOdometer;

  /// The latest ENTERED reading.
  ///
  /// Never a projection, and there is deliberately no `isEstimated` flag
  /// beside it: a flag would imply the other case exists. §12 forbids it, so
  /// the type does not model it.
  final Distance? latestOdometer;

  /// The date that reading was taken, which §12 prints beside it.
  final String? latestOdometerReadOn;

  /// Distance under this owner, or null when either end is unknown.
  ///
  /// Never zero as a stand-in. Zero is a claim — it says the car has not moved
  /// since it was bought — and §2 would rather say nothing.
  Distance? get distanceUnderOwner {
    final from = purchaseOdometer;
    final to = latestOdometer;
    if (from == null || to == null) return null;
    return Distance(to.metres - from.metres);
  }

  /// The plate, only when toggled on.
  final String? plate;

  /// The VIN, only when toggled on.
  final String? vin;

  /// The owner's notes, only when toggled on.
  final String? notes;
}

/// One line of *Maintenance at a glance*.
@immutable
class ServiceGlanceRow {
  /// Creates the row.
  const ServiceGlanceRow({
    required this.itemId,
    required this.lastDoneOn,
    this.lastDoneOdometer,
    this.distanceSince,
  });

  /// Which item.
  final ServiceItemId itemId;

  /// When it was last done.
  final String lastDoneOn;

  /// And at what odometer.
  final Distance? lastDoneOdometer;

  /// How far ago — null when there is no current reading to measure to,
  /// rather than zero, which would read as "done just now".
  final Distance? distanceSince;
}

/// One year of the full history.
@immutable
class ServiceReportYear {
  /// Creates the year.
  const ServiceReportYear({
    required this.year,
    required this.records,
    required this.subtotals,
  });

  /// The calendar year.
  final int year;

  /// Its records, newest first.
  final List<ServiceRecord> records;

  /// Per currency, and EMPTY when Costs is off.
  ///
  /// Empty rather than zeroed: a subtotal of `0 €` on a document says the
  /// year's work was free.
  final Map<Currency, Money> subtotals;
}

/// §12's summary line: "34 services · 6,842 €".
@immutable
class ServiceReportSummary {
  /// Creates the summary.
  const ServiceReportSummary({
    required this.serviceCount,
    required this.totals,
  });

  /// How many SERVICES — records, not lines. A record with four lines is one
  /// visit to a workshop, and "137 services" over eight years is a number a
  /// buyer would not believe.
  final int serviceCount;

  /// Per currency, grouped and never summed. Adding them would invent an
  /// exchange rate the app has never had and cannot get offline.
  final Map<Currency, Money> totals;
}

/// §12's fuel line: "Average 6.4 L/100 km over 231 tanks and 118,400 km".
@immutable
class FuelSummaryFacts {
  /// Creates the facts.
  const FuelSummaryFacts({
    required this.metresPerUnit,
    required this.tankCount,
    required this.distance,
  });

  /// Metres per millilitre or per gram — canonical, unformatted, and converted
  /// at the presentation edge like every other figure in this app.
  final double metresPerUnit;

  /// How many tanks the average is over.
  final int tankCount;

  /// And over what distance.
  final Distance distance;
}

/// The footnotes a document can carry.
///
/// An enum rather than strings, because the model is Flutter-free and the
/// sentence is the l10n layer's.
enum ServiceReportFootnote {
  /// "~ odometer estimated at the time, not read from the car."
  estimatedOdometer,
}

/// Everything the preview, the PDF and the clipboard render.
@immutable
class ServiceReportDocument {
  /// Creates the document.
  const ServiceReportDocument({
    required this.header,
    required this.glance,
    required this.noRecordItemIds,
    required this.years,
    required this.footnotes,
    required this.generatedOn,
    this.summary,
    this.fuel,
  });

  /// The header block.
  final ServiceReportHeader header;

  /// Every tracked item with at least one completion.
  final List<ServiceGlanceRow> glance;

  /// And the tracked items with none.
  ///
  /// §12 lists them explicitly "because an absent row reads as a hidden row" —
  /// a buyer scanning the document cannot tell a timing belt that was never
  /// done from one the seller removed.
  final List<ServiceItemId> noRecordItemIds;

  /// The full history, newest year first.
  final List<ServiceReportYear> years;

  /// Null when Costs is off.
  final ServiceReportSummary? summary;

  /// Null when the toggle is off or there are no tanks.
  final FuelSummaryFacts? fuel;

  /// One per DISTINCT cause, never one per occurrence: the note explains the
  /// mark, and repeating it under a document is noise.
  final List<ServiceReportFootnote> footnotes;

  /// The date in §12's unremovable footer.
  final CivilDate generatedOn;
}

/// Builds the document. Pure: reads nothing, writes nothing, no `BuildContext`.
@useResult
ServiceReportDocument buildServiceReport({
  required Vehicle vehicle,
  required List<ServiceRecord> records,
  required List<ServiceItem> items,
  required ReadingSeries series,
  required ServiceReportOptions options,
  required CivilDate today,
  FuelSummaryFacts? fuel,
}) {
  // The latest ENTERED reading, which is what `ReadingSeries` holds: it is
  // built from `odometer_readings` and knows nothing about projection. Asking
  // the due engine for the current odometer here would return an estimate on a
  // stale vehicle, which is the one thing §12 forbids.
  final latest = _latestEntered(series);

  final newestFirst = [...records]
    ..sort((a, b) {
      final byDate = b.occurredOn.compareTo(a.occurredOn);
      return byDate != 0
          ? byDate
          : b.createdAtUtcMs.compareTo(a.createdAtUtcMs);
    });

  // Maintenance at a glance. Tracked items only — an untracked one is not a
  // maintenance obligation this vehicle has, and listing it under "no record"
  // invents one the owner never took on.
  final tracked = items.where((i) => i.isTracked).toList();
  final glance = <ServiceGlanceRow>[];
  final noRecord = <ServiceItemId>[];
  for (final it in tracked) {
    final completion = newestFirst
        .where((r) => r.lines.any((l) => l.serviceItemId == it.id))
        .firstOrNull;
    if (completion == null) {
      noRecord.add(it.id);
      continue;
    }
    final at = completion.odometer;
    glance.add(
      ServiceGlanceRow(
        itemId: it.id,
        lastDoneOn: completion.occurredOn,
        lastDoneOdometer: at,
        distanceSince: at == null || latest == null
            ? null
            : Distance(latest.$1.metres - at.metres),
      ),
    );
  }

  // The full history, grouped by year. Insertion order over a sorted list is
  // already newest-year-first, so no second sort is needed and none is done —
  // a second sort here is a second tie-break rule to keep in step with the
  // first.
  final byYear = <int, List<ServiceRecord>>{};
  for (final r in newestFirst) {
    final year = int.tryParse(r.occurredOn.split('-').first);
    if (year == null) continue;
    (byYear[year] ??= []).add(r);
  }

  final years = [
    for (final entry in byYear.entries)
      ServiceReportYear(
        year: entry.key,
        records: List.unmodifiable(entry.value),
        subtotals: options.costs ? _totals(entry.value) : const {},
      ),
  ];

  final estimated = records.any((r) => r.odometerEstimated);

  return ServiceReportDocument(
    header: ServiceReportHeader(
      name: vehicle.name,
      today: today,
      make: vehicle.make,
      model: vehicle.model,
      year: vehicle.year,
      fuelKind: vehicle.fuelKindDefault,
      colour: vehicle.colour,
      ownedFrom: vehicle.purchaseDate,
      ownedUntil: vehicle.soldOn,
      purchaseOdometer: vehicle.purchaseOdometer,
      latestOdometer: latest?.$1,
      latestOdometerReadOn: latest?.$2,
      plate: options.plateAndVin ? vehicle.plate : null,
      vin: options.plateAndVin ? vehicle.vin : null,
      notes: options.notes ? vehicle.notes : null,
    ),
    glance: List.unmodifiable(glance),
    noRecordItemIds: List.unmodifiable(noRecord),
    years: List.unmodifiable(years),
    summary: options.costs
        ? ServiceReportSummary(
            // `records.length`, not a map built to be measured. Ids are
            // unique, so the map was `records.length` with a hash table in
            // front of it — allocated on every chip tap, and thrown away
            // entirely when Costs is off.
            serviceCount: records.length,
            totals: _totals(records),
          )
        : null,
    fuel: options.fuelSummary ? fuel : null,
    footnotes: List.unmodifiable([
      if (estimated) ServiceReportFootnote.estimatedOdometer,
    ]),
    generatedOn: today,
  );
}

/// The newest entered reading and the date it was entered.
///
/// From `ReadingSeries`, which is built from `odometer_readings` and knows
/// nothing about projection. Its `cumulative` is correction-aware, which is
/// the number a buyer's document should carry: a post-cluster-swap car's raw
/// dash reading is not the distance it has covered.
(Distance, String)? _latestEntered(ReadingSeries series) {
  final points = series.points;
  if (points.isEmpty) return null;
  final newest = points.last;
  return (newest.cumulative, newest.date.toString());
}

/// Per-currency totals over every line of [records].
///
/// Through `MoneyTotal`, which already owns this grouping — §12 groups and
/// never sums, and a second accumulate-by-currency loop is a second place for
/// that rule to be broken. `MoneyTotal` also sorts its currencies, which a
/// document needs: the same records must print their amounts in the same
/// order every time they are rendered.
Map<Currency, Money> _totals(List<ServiceRecord> records) {
  final total = MoneyTotal(records.expand((r) => r.lines).map((l) => l.amount));
  return {
    for (final e in total.byCurrency.entries) e.key: Money(e.value, e.key),
  };
}
