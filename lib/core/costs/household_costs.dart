// SPEC.md §12's all-vehicles comparison — the household view for someone with
// a second car, or a plumber with two vans.
//
// The rule is the one that shapes every total on these screens: "Money never
// mixes." A household with a euro car and a pound car has two subtotals and
// not one sum, because there is no rate and no network to fetch one.
//
// That rule reaches the SORT as well as the arithmetic. Comparing 30,000 minor
// euros against 30,000 minor pounds as though they were the same quantity is
// the forbidden sum wearing a comparison instead of an addition — so rows are
// ordered within their own currency, and the currencies are ordered against
// each other by nothing at all.
import 'package:meta/meta.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/money/money_total.dart';

/// One vehicle's line in the household list.
@immutable
class HouseholdVehicle {
  /// Creates a line.
  const HouseholdVehicle({
    required this.vehicleId,
    required this.name,
    required this.perMonth,
    this.hasCost = true,
    this.isArchived = false,
    this.isSold = false,
  });

  /// Which vehicle. NOT a route target — §12 says these rows are not tappable,
  /// because vehicle selection lives only in `vehicle.switcher`.
  final String vehicleId;

  /// Its name.
  final String name;

  /// Its cost per completed month.
  final Money perMonth;

  /// Whether [perMonth] is a figure at all.
  ///
  /// False where the engine could not produce an exact one — no completed
  /// month, no records in range. The row is still LISTED, because §12's
  /// trailing line counts what is hidden and a vehicle dropped from the list
  /// entirely is neither shown nor counted; the caller draws a dash instead of
  /// the zero this carries. §1: zero is a claim, and this is not one.
  final bool hasCost;

  /// Whether it is archived.
  final bool isArchived;

  /// Whether it has been sold.
  final bool isSold;

  /// Whether §12 hides it unless the user asks.
  bool get isInactive => isArchived || isSold;
}

/// §12's household view.
@immutable
class HouseholdCosts {
  /// Creates the view.
  const HouseholdCosts({
    required this.rows,
    required this.totals,
    required this.hiddenCount,
  });

  /// The included vehicles, most expensive per month first.
  final List<HouseholdVehicle> rows;

  /// Per-currency household totals. Grouped, never summed across.
  final MoneyTotal totals;

  /// How many were left out, for §12's trailing line. A hidden vehicle the
  /// user is not told about is a household total they cannot reconcile.
  final int hiddenCount;
}

/// §12's household aggregation.
HouseholdCosts buildHousehold({
  required List<HouseholdVehicle> vehicles,
  required bool includeInactive,
}) {
  final included =
      [
        for (final v in vehicles)
          if (includeInactive || !v.isInactive) v,
      ]..sort((a, b) {
        // WITHIN a currency. Two currencies have no order between them that is
        // not a conversion, so they are grouped by code first — arbitrary, but
        // stable, which is what a list a user scans twice needs.
        final byCurrency = a.perMonth.currency.code.compareTo(
          b.perMonth.currency.code,
        );
        if (byCurrency != 0) return byCurrency;

        final byCost = b.perMonth.amountMinor.compareTo(a.perMonth.amountMinor);
        // The name breaks a tie, so two identical costs do not swap places
        // between builds and make the list look alive when nothing changed.
        return byCost != 0 ? byCost : a.name.compareTo(b.name);
      });

  return HouseholdCosts(
    rows: included,
    totals: MoneyTotal([for (final v in included) v.perMonth]),
    hiddenCount: vehicles.length - included.length,
  );
}
