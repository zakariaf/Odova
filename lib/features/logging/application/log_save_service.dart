// Save, as three steps in one order.
//
// SPEC.md §10 *Save*: "One transaction: the record, its `OdometerReading` if it
// carries one, then a recompute of due states and a notification reschedule."
//
// The ORDER is the contract, and it is the whole reason this is a named thing
// rather than three lines inside a form. A reschedule that ran before the
// recompute would build notifications from due states the write had already
// invalidated — and the user would be reminded, that evening, about the work
// they had just finished logging.
//
// The transaction itself is the REPOSITORY's: `FillUpRepository.save` and
// `ServiceRepository.saveRecord` each write their record and its derived
// odometer reading together or not at all, and this must never open a second
// one around them.
import 'package:odova/core/result.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/data/failures/persist_failure.dart';

/// The three steps a save takes, in the order it takes them.
///
/// An interface so the ORDER can be asserted without a database: the thing
/// worth testing here is the sequence and the early exit, and a fake that
/// records three strings tests both.
abstract interface class LogSaveSteps {
  /// Writes the record and its reading, in one transaction.
  Future<Result<void, PersistFailure>> persist();

  /// Recomputes the vehicle's due states from facts.
  Future<void> recompute();

  /// Cancels and rebuilds that vehicle's pending notifications.
  Future<void> reschedule();
}

/// Runs [steps] in §10's order, stopping at the first failure.
///
/// Returns the failure unchanged: §10 keeps the modal open "with everything
/// intact" and shows one sentence, and it cannot do either from a swallowed
/// exception.
Future<Result<void, PersistFailure>> saveLogEntry(LogSaveSteps steps) async {
  final written = await steps.persist();
  // STOPS here on a failure. Recomputing after a failed write would recompute
  // from rows that were never written, and the reschedule would then fire
  // notifications for them.
  if (written is Err<void, PersistFailure>) return written;

  await steps.recompute();
  await steps.reschedule();
  return const Ok(null);
}

/// How many of the three quantity forms [quantity] fills.
///
/// The `fill_ups` CHECK is `(quantity_ml IS NOT NULL) + (quantity_g IS NOT
/// NULL) + (energy_wh IS NOT NULL) = 1`, so a draft producing none or two is
/// refused by SQL. This exists so the FORM can be asserted against the same
/// rule, where the error is still one a user can act on.
int quantityFormsSet(FuelQuantity? quantity) => quantity == null ? 0 : 1;
