// Everything the app has persisted, as domain models, at one instant.
//
// It exists because a backup is the only operation in the app that reads the
// WHOLE store. Every other read is per-vehicle and streamed, because every
// other read feeds a screen that shows one vehicle. Export shows no screen: it
// walks nine tables front to back, and a per-vehicle stream composed nine times
// over N vehicles is both slower and wrong at the edges — a vehicle deleted
// between the fourth stream and the fifth would leave orphan children in the
// file.
//
// Deliberately a plain bundle with no behaviour. The reader fills it, the
// writer projects it, and the importer (EPIC-15 task 15.4) rebuilds one from a
// parsed document and swaps it in. Giving it methods would make it a third
// model beside `records.dart` and the file format, and SPEC.md §6 §2.4 is
// explicit that the mapping is a mapping and never a second model.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';

/// The whole store, as domain models.
///
/// Soft-deleted rows are absent by construction: SPEC.md §3 makes a deleted row
/// invisible to every query, and §6 §7 keeps it out of the file. The lists
/// arrive sorted by id, which for a ULID is creation order.
@immutable
class StoreSnapshot {
  /// Creates a snapshot. Every list defaults to empty so a test that cares
  /// about one table does not have to name the other eight.
  const StoreSnapshot({
    required this.settings,
    this.vehicles = const [],
    this.reminders = const [],
    this.odometerReadings = const [],
    this.odometerCorrections = const [],
    this.fillUps = const [],
    this.services = const [],
    this.expenses = const [],
    this.trips = const [],
  });

  /// The single settings row.
  final AppSettings settings;

  /// Every vehicle, including archived and sold ones.
  ///
  /// An archived vehicle's history is exactly the history a person is most
  /// afraid of losing — it belongs to the car they no longer own and can no
  /// longer look at.
  final List<Vehicle> vehicles;

  /// Every service item.
  final List<ServiceItem> reminders;

  /// Standalone odometer readings only.
  final List<OdometerReading> odometerReadings;

  /// Every odometer correction.
  final List<OdometerCorrection> odometerCorrections;

  /// Every fill-up.
  final List<FillUp> fillUps;

  /// Every service record, each with its lines already attached.
  final List<ServiceRecord> services;

  /// Every expense.
  final List<Expense> expenses;

  /// Every trip.
  final List<Trip> trips;
}
