// The repositories, as providers.
//
// One `Provider` each over the single `appDatabaseProvider`, plus an
// `autoDispose.family` StreamProvider for every scoped watch. The family key is
// always the vehicle: SPEC.md §3 scopes everything but settings and the garage
// list to one vehicle, and a stream that is not scoped recomputes for a write
// to a car the user is not looking at.
//
// `autoDispose` because a scoped stream belongs to the screen that asked for
// it. Without it, opening four vehicles' histories in a session leaves four
// live queries on the database for the rest of the launch.
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `StreamProviderFamily` is only exported from misc.dart. It is named here
// because `specify_nonobvious_property_types` wants the annotation, and an
// inferred family type reads as a `dynamic` argument at every call site.
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:odova/app/id_provider.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/repositories/log_repositories.dart';
import 'package:odova/data/repositories/odometer_repository.dart';
import 'package:odova/data/repositories/service_repository.dart';
import 'package:odova/data/repositories/settings_repository.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';

/// Vehicles.
final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => VehicleRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(ulidFactoryProvider),
  ),
);

/// Service items, records and lines.
final serviceRepositoryProvider = Provider<ServiceRepository>(
  (ref) => ServiceRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(ulidFactoryProvider),
  ),
);

/// Fill-ups.
final fillUpRepositoryProvider = Provider<FillUpRepository>(
  (ref) => FillUpRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(ulidFactoryProvider),
  ),
);

/// Expenses.
final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(ulidFactoryProvider),
  ),
);

/// Trips.
final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => TripRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(ulidFactoryProvider),
  ),
);

/// Odometer readings and corrections.
final odometerRepositoryProvider = Provider<OdometerRepository>(
  (ref) => OdometerRepository(ref.watch(appDatabaseProvider)),
);

/// The settings singleton.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

/// Every live vehicle, in garage order.
///
/// Not `autoDispose`: the garage list is read by the app shell for the whole
/// session, so disposing it would tear the query down and rebuild it on every
/// tab change.
final StreamProvider<List<Vehicle>> vehiclesProvider = StreamProvider(
  (ref) => ref.watch(vehicleRepositoryProvider).watchAll(),
);

/// The settings, or null before first run has written them.
final StreamProvider<AppSettings?> settingsProvider = StreamProvider(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// One vehicle's service items.
final StreamProviderFamily<List<ServiceItem>, VehicleId> serviceItemsProvider =
    StreamProvider.autoDispose.family(
      (ref, vehicleId) =>
          ref.watch(serviceRepositoryProvider).watchItems(vehicleId),
    );

/// One vehicle's service records, newest first.
final StreamProviderFamily<List<ServiceRecord>, VehicleId>
serviceRecordsProvider = StreamProvider.autoDispose.family(
  (ref, vehicleId) =>
      ref.watch(serviceRepositoryProvider).watchRecords(vehicleId),
);

/// One vehicle's fill-ups, newest first.
final StreamProviderFamily<List<FillUp>, VehicleId> fillUpsProvider =
    StreamProvider.autoDispose.family(
      (ref, vehicleId) =>
          ref.watch(fillUpRepositoryProvider).watchForVehicle(vehicleId),
    );

/// One vehicle's newest fill-up, or null.
///
/// Separate from [fillUpsProvider] rather than derived from it: Home draws one
/// row and this is a `LIMIT 1`, so the whole history is neither read nor kept
/// live to render it.
final StreamProviderFamily<FillUp?, VehicleId> latestFillUpProvider =
    StreamProvider.autoDispose.family(
      (ref, vehicleId) =>
          ref.watch(fillUpRepositoryProvider).watchLatestForVehicle(vehicleId),
    );

/// One vehicle's expenses, newest first.
final StreamProviderFamily<List<Expense>, VehicleId> expensesProvider =
    StreamProvider.autoDispose.family(
      (ref, vehicleId) =>
          ref.watch(expenseRepositoryProvider).watchForVehicle(vehicleId),
    );

/// One vehicle's trips, newest first.
final StreamProviderFamily<List<Trip>, VehicleId> tripsProvider = StreamProvider
    .autoDispose
    .family(
      (ref, vehicleId) =>
          ref.watch(tripRepositoryProvider).watchForVehicle(vehicleId),
    );

/// One vehicle's odometer readings, in SPEC.md §3's order.
final StreamProviderFamily<List<OdometerReading>, VehicleId>
odometerReadingsProvider = StreamProvider.autoDispose.family(
  (ref, vehicleId) =>
      ref.watch(odometerRepositoryProvider).watchReadings(vehicleId),
);

/// One vehicle's odometer corrections.
final StreamProviderFamily<List<OdometerCorrection>, VehicleId>
odometerCorrectionsProvider = StreamProvider.autoDispose.family(
  (ref, vehicleId) =>
      ref.watch(odometerRepositoryProvider).watchCorrections(vehicleId),
);
