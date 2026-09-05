// Turning one reminder off, and putting it back.
//
// SPEC.md §9's card overflow: "**Turn this off** (`is_active = false`, snackbar
// with **Undo**)". Both halves are here — a write with no Undo beside it is the
// version of this feature that loses somebody's timing-belt reminder because
// they meant to tap Snooze.
//
// A notifier rather than a call from the widget, for the reason every other
// write in `lib/features/` is one: it is the seam a test overrides, and it is
// what keeps `ServiceRepository` the single write path rather than one of two.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';

/// Sets `is_active` on a service item.
///
/// No state of its own: the answer is the row, and the row arrives back through
/// `serviceItemsProvider`. A copy held here would be a second opinion about a
/// value the screen already watches.
class ReminderActivation extends Notifier<void> {
  @override
  void build() {}

  /// Turns [item] on or off.
  Future<Result<void, PersistFailure>> setActive(
    ServiceItem item, {
    required bool active,
  }) => _write(item.id, active: active);

  /// Puts back what [setActive] changed.
  ///
  /// It takes the id and the PREVIOUS value rather than re-reading the row: an
  /// undo that reads first would restore whatever the row says now, which after
  /// a second change is not what the user is undoing.
  Future<Result<void, PersistFailure>> undo(
    ServiceItemId id, {
    required bool wasActive,
  }) => _write(id, active: wasActive);

  Future<Result<void, PersistFailure>> _write(
    ServiceItemId id, {
    required bool active,
  }) => ref
      .read(serviceRepositoryProvider)
      .setItemActive(
        id,
        isActive: active,
        updatedAtUtcMs: ref.read(clockProvider).now().millisecondsSinceEpoch,
      );
}

/// The one way a screen turns a reminder off.
final NotifierProvider<ReminderActivation, void> reminderActivationProvider =
    NotifierProvider<ReminderActivation, void>(ReminderActivation.new);
