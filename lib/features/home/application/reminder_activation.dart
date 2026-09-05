// Turning one reminder off or on, and putting it back.
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

  /// Sets `is_active` on [id].
  ///
  /// ONE method, and the Undo is the same call with the previous value. It was
  /// three — `setActive(ServiceItem, {active})`, `undo(id, {wasActive})` and a
  /// private `_write(id, {active})` they both forwarded to — which is two names
  /// and two signatures for one UPDATE. The sibling notifier on
  /// `reminders.list` has had exactly this signature all along and uses it for
  /// its own Undo.
  ///
  /// The id and not the row: an undo that re-read the item would restore
  /// whatever it says NOW, which after a second change is not what the user is
  /// undoing.
  Future<Result<void, PersistFailure>> setActive(
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
