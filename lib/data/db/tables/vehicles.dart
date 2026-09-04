// The vehicle. Everything else in the app hangs off one.
//
// SPEC.md §3 Entities (`Vehicle`), §3 Enums, §3 Scope: global vs per vehicle.
//
// Every enum is a `CHECK` in the schema rather than a validation in Dart,
// because an invariant enforced at the call site is one an import, a migration
// or a future repository walks straight past. The lists are literals here so
// drift's generator can read them; `test/data/db/tables/enum_checks_test.dart`
// reconstructs each list from the Dart enum and compares it against
// `sqlite_schema`, which is what keeps the two from drifting.
import 'package:drift/drift.dart';
import 'package:odova/data/db/tables/audit_columns.dart';

/// A vehicle.
@DataClassName('VehicleRow')
class Vehicles extends Table with AuditColumns {
  /// What the user calls it: "The Golf", "Van".
  TextColumn get name => text()();

  /// Manufacturer.
  TextColumn get make => text().nullable()();

  /// Model.
  TextColumn get model => text().nullable()();

  /// Model year.
  IntColumn get year => integer().nullable()();

  /// Registration plate. Stored verbatim — an Iranian plate legitimately
  /// contains Persian digits and a Persian letter, so it is transcribed and
  /// never shaped or folded.
  TextColumn get plate => text().nullable()();

  /// Vehicle identification number.
  TextColumn get vin => text().nullable()();

  /// Drives the icon and which catalogue items seed.
  TextColumn get vehicleType => text()
      .named('vehicle_type')
      .customConstraint(
        'NOT NULL CHECK (vehicle_type IN '
        "('car', 'van', 'motorcycle', 'truck', 'other'))",
      )();

  /// Drives the business/personal cost split.
  BoolColumn get isBusiness =>
      boolean().named('is_business').withDefault(const Constant(false))();

  /// What it burns. Decides which of a fill-up's three quantity columns is
  /// the non-null one.
  TextColumn get fuelKindDefault => text()
      .named('fuel_kind_default')
      .customConstraint(
        'NOT NULL CHECK (fuel_kind_default IN '
        "('petrol', 'diesel', 'lpg', 'cng', 'electric', 'hybrid', 'other'))",
      )();

  /// Tank size in millilitres. A sanity check on a fill-up, never used in
  /// maths — SPEC.md §3 says so explicitly, because a "full tank" that
  /// exceeds it is a typo worth querying and not a number worth trusting.
  IntColumn get tankCapacityMl => integer()
      .named('tank_capacity_ml')
      .customConstraint(
        'CHECK (tank_capacity_ml IS NULL OR '
        'tank_capacity_ml > 0)',
      )
      .nullable()();

  /// When it was bought.
  TextColumn get purchaseDate => text().named('purchase_date').nullable()();

  /// The odometer at purchase, in metres.
  IntColumn get purchaseOdometerM =>
      integer().named('purchase_odometer_m').nullable()();

  /// What it cost, in minor units.
  IntColumn get purchasePriceMinor =>
      integer().named('purchase_price_minor').nullable()();

  /// The currency [purchasePriceMinor] is in.
  TextColumn get purchasePriceCurrency => text()
      .named('purchase_price_currency')
      .customConstraint(
        'CHECK (purchase_price_currency IS NULL OR '
        'length(purchase_price_currency) = 3)',
      )
      .nullable()();

  /// Where it is in its life with the user.
  TextColumn get status => text().customConstraint(
    "NOT NULL CHECK (status IN ('active', 'archived', 'sold'))",
  )();

  /// When it was sold.
  TextColumn get soldOn => text().named('sold_on').nullable()();

  /// What it sold for, in minor units.
  IntColumn get soldPriceMinor =>
      integer().named('sold_price_minor').nullable()();

  /// The currency [soldPriceMinor] is in.
  TextColumn get soldPriceCurrency => text()
      .named('sold_price_currency')
      .customConstraint(
        'CHECK (sold_price_currency IS NULL OR '
        'length(sold_price_currency) = 3)',
      )
      .nullable()();

  /// Expected annual distance in metres, asked once at onboarding.
  ///
  /// Feeds the rate fallback: a vehicle with two readings a year apart has no
  /// usable rate, and this is what the projection uses instead of inventing
  /// one.
  IntColumn get expectedAnnualM =>
      integer().named('expected_annual_m').nullable()();

  /// A swatch key. v1 has no vehicle photo.
  TextColumn get colour => text().nullable()();

  /// Free text.
  TextColumn get notes => text().nullable()();

  /// Where it sits in the garage list.
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();

  /// Whether this vehicle's reminders are silenced.
  BoolColumn get notificationsMuted => boolean()
      .named('notifications_muted')
      .withDefault(const Constant(false))();

  // ---- Per-vehicle overrides of Settings. NULL MEANS INHERIT. ----
  //
  // None of these carries a default, and that is the point. A default here
  // would freeze a vehicle's units at the moment it was created, so a later
  // change in Settings would silently not apply to it — and the user would
  // have no way to see why one car reads in miles.

  /// Overrides `settings.currency_default`.
  /// `withLength` is a DART-side validator that emits nothing into the
  /// schema, so a two-letter code written by an import or a migration was
  /// accepted — and the exponent that turns 4599 into 45.99 comes from the
  /// code. The check has to be in SQL.
  TextColumn get currency => text()
      .customConstraint('CHECK (currency IS NULL OR length(currency) = 3)')
      .nullable()();

  /// Overrides `settings.distance_unit`.
  TextColumn get distanceUnit => text()
      .named('distance_unit')
      .customConstraint("CHECK (distance_unit IN ('km', 'mi'))")
      .nullable()();

  /// Overrides `settings.volume_unit`.
  TextColumn get volumeUnit => text()
      .named('volume_unit')
      .customConstraint("CHECK (volume_unit IN ('l', 'gal_us', 'gal_uk'))")
      .nullable()();

  /// Overrides `settings.consumption_unit`.
  TextColumn get consumptionUnit => text()
      .named('consumption_unit')
      .customConstraint(
        "CHECK (consumption_unit IN ('l_100km', 'km_l', 'mpg_us', 'mpg_uk', "
        "'kwh_100km', 'mi_kwh'))",
      )
      .nullable()();

  /// Overrides the computed distance notice window, in metres.
  IntColumn get noticeDistanceM =>
      integer().named('notice_distance_m').nullable()();

  /// Overrides the computed time notice window, in days.
  IntColumn get noticeDays => integer().named('notice_days').nullable()();
}
