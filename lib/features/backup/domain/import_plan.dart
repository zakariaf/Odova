// What a file would do to the phone, decided before anything is written.
//
// SPEC.md §6 §5: the reader's whole job is to produce one of these or a typed
// refusal, and to do it WITHOUT touching the store. The preview screen renders
// it, the user confirms it, and only then does task 15.4's importer act on it.
//
// It carries the counts as well as the store because §5.2's messages are made
// of them — "Imported. 3 vehicles and 1,204 records restored." and "Odova could
// read 812 of your 1,204 records" are the same two numbers seen from either
// side of the blast-radius threshold.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/features/backup/domain/import_warning.dart';

/// A validated backup file, ready to be confirmed and applied.
@immutable
class ImportPlan {
  /// Creates a plan.
  const ImportPlan({
    required this.store,
    required this.warnings,
    required this.recordsRead,
    required this.recordsInFile,
    this.preferredActiveVehicleId,
  });

  /// Everything that will replace what is on the phone.
  final StoreSnapshot store;

  /// What was odd about the file. Every one of these still imports.
  final List<ImportWarning> warnings;

  /// How many records survived record-level validation.
  final int recordsRead;

  /// How many records the file contained, readable or not.
  final int recordsInFile;

  /// The vehicle the exporting phone was looking at, if the file named one.
  ///
  /// Carried here rather than inside [store] because selecting a vehicle has
  /// to reset the tab stack, and exactly one place in the app is allowed to do
  /// that. Task 15.4 applies it through `setActiveVehicle` after the swap.
  final VehicleId? preferredActiveVehicleId;

  /// How many records will not be imported.
  int get recordsSkipped => recordsInFile - recordsRead;
}
