// A fill-up.
//
// SPEC.md §3 Entities (`FillUp`), §3 Invariants.
//
// **Unit price is not stored.** The form takes any two of {total, quantity,
// price per unit} and computes the third; only total and quantity persist.
// Store all three and they will one day disagree, and then nobody knows which
// one is the receipt.
import 'package:drift/drift.dart';
import 'package:odova/data/db/tables/audit_columns.dart';

/// A fill-up.
@DataClassName('FillUpRow')
class FillUps extends Table with AuditColumns {
  /// The vehicle. Carried directly even when [tripId] is set.
  TextColumn get vehicleId => text()
      .named('vehicle_id')
      .customConstraint(
        'NOT NULL REFERENCES vehicles (id) ON DELETE CASCADE',
      )();

  /// The day it happened.
  TextColumn get occurredOn => text()
      .named('occurred_on')
      .customConstraint(
        'NOT NULL CHECK (occurred_on GLOB '
        "'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
      )();

  /// The odometer, in metres. Null only from an import; the entry form
  /// requires it.
  IntColumn get odometerM => integer()
      .named('odometer_m')
      .customConstraint('CHECK (odometer_m IS NULL OR odometer_m >= 0)')
      .nullable()();

  /// The unit the reading was entered in.
  TextColumn get odometerUnit => text()
      .named('odometer_unit')
      .customConstraint("NOT NULL CHECK (odometer_unit IN ('km', 'mi'))")();

  /// What went in. Decides which quantity column is the non-null one.
  TextColumn get fuelKind => text()
      .named('fuel_kind')
      .customConstraint(
        "NOT NULL CHECK (fuel_kind IN ('petrol', 'diesel', 'lpg', 'cng', "
        "'electric', 'hybrid', 'other'))",
      )();

  /// Millilitres, for a liquid.
  IntColumn get quantityMl => integer()
      .named('quantity_ml')
      .customConstraint('CHECK (quantity_ml IS NULL OR quantity_ml > 0)')
      .nullable()();

  /// Grams, for CNG — which is sold by mass.
  IntColumn get quantityG => integer()
      .named('quantity_g')
      .customConstraint('CHECK (quantity_g IS NULL OR quantity_g > 0)')
      .nullable()();

  /// Watt-hours, for electricity — which is sold by energy.
  IntColumn get energyWh => integer()
      .named('energy_wh')
      .customConstraint('CHECK (energy_wh IS NULL OR energy_wh > 0)')
      .nullable()();

  /// The unit the quantity was entered in.
  TextColumn get quantityUnit => text()
      .named('quantity_unit')
      .customConstraint(
        "NOT NULL CHECK (quantity_unit IN ('l', 'gal_us', 'gal_uk'))",
      )();

  /// What it cost, in minor units. Zero is allowed — a free fill is a fact.
  IntColumn get totalCostMinor => integer()
      .named('total_cost_minor')
      .customConstraint('NOT NULL CHECK (total_cost_minor >= 0)')();

  /// The currency, ISO 4217.
  TextColumn get currency => text().customConstraint(
    'NOT NULL CHECK (length(currency) = 3)',
  )();

  /// Whether the tank was filled. Only full-to-full segments give a
  /// trustworthy consumption figure.
  BoolColumn get isFullTank =>
      boolean().named('is_full_tank').withDefault(const Constant(true))();

  /// "I forgot to log one before this." Breaks the consumption segment rather
  /// than averaging across the gap — SPEC.md §2: a broken segment is
  /// discarded, never averaged.
  BoolColumn get chainBroken =>
      boolean().named('chain_broken').withDefault(const Constant(false))();

  /// "95", "Diesel B7", "DC 150kW".
  TextColumn get grade => text().nullable()();

  /// Where.
  TextColumn get station => text().nullable()();

  /// The trip this belongs to, if any.
  TextColumn get tripId => text()
      .named('trip_id')
      .customConstraint('REFERENCES trips (id) ON DELETE SET NULL')
      .nullable()();

  /// Free text.
  TextColumn get notes => text().nullable()();

  /// Exactly one of the three quantity columns is non-null.
  ///
  /// SQLite counts a boolean as 0 or 1, so summing the three `IS NOT NULL`
  /// tests and requiring 1 says "exactly one" in one expression. Two is a row
  /// that means two things; none is a fill-up with no fuel in it, and both
  /// break the consumption maths silently rather than loudly.
  static const _exactlyOneQuantity =
      'CHECK ((quantity_ml IS NOT NULL) + (quantity_g IS NOT NULL) '
      '+ (energy_wh IS NOT NULL) = 1)';

  /// The quantity column matches the fuel kind.
  ///
  /// CNG is sold by mass and electricity by energy; everything else by volume.
  /// Without this an electric fill-up could carry millilitres, and the
  /// consumption figure would be litres per 100 km for a car with no tank.
  static const _quantityMatchesFuelKind =
      "CHECK (CASE fuel_kind WHEN 'electric' THEN energy_wh IS NOT NULL "
      "WHEN 'cng' THEN quantity_g IS NOT NULL "
      'ELSE quantity_ml IS NOT NULL END)';

  @override
  List<String> get customConstraints => [
    _exactlyOneQuantity,
    _quantityMatchesFuelKind,
  ];
}
