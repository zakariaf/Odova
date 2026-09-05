// `reminders.edit`'s state: one draft, the facts around it, and the write.
//
// SPEC.md §9 `reminders.edit` → *Data*. The VALIDATION is not here — it is a
// pure function over the draft in `domain/reminder_draft.dart`, so the four
// rules can be asserted at their boundaries without a widget, and so a screen
// cannot be the only place that knows them.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:odova/app/id_provider.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/reminders/domain/reminder_draft.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';

/// What the editor is doing.
sealed class ReminderEditState {
  const ReminderEditState();
}

/// Reading the row. The form has nothing to draw yet.
final class ReminderEditLoading extends ReminderEditState {
  /// Creates the loading state.
  const ReminderEditLoading();
}

/// The row could not be read — deleted while the form was opening.
final class ReminderEditMissing extends ReminderEditState {
  /// Creates the missing state.
  const ReminderEditMissing();
}

/// The form, with everything it draws.
final class ReminderEditReady extends ReminderEditState {
  /// Creates the ready state.
  const ReminderEditReady(
    this.draft, {
    required this.vehicle,
    this.item,
    this.records = const [],
    this.lineCount = 0,
    this.firstReading,
    this.problems = const [],
    this.saving = false,
  });

  /// What the form holds.
  final ReminderDraft draft;

  /// The vehicle it belongs to — for the unit and the notice window.
  final Vehicle vehicle;

  /// The row being edited, or null in create mode.
  final ServiceItem? item;

  /// The five newest records naming this item, newest first.
  ///
  /// §9: "the evidence behind the anchor, so a user who thinks the app is wrong
  /// can check instead of argue."
  final List<ServiceRecord> records;

  /// How many service LINES name it. Non-zero makes it undeletable.
  final int lineCount;

  /// The vehicle's earliest reading, for the baseline rule.
  final Distance? firstReading;

  /// What the last refused Save objected to, and empty until one happens.
  ///
  /// §9: "Save is never silently disabled." So the messages appear when Save is
  /// PRESSED, not while the user is still typing — a form that scolds you
  /// before you have finished is a form that is angry at you for arriving.
  ///
  /// keeping only "there were some"; the form re-ran the identical validation
  /// in `build` to find out what they were, against a second reading of the
  /// clock taken at a different moment. Two answers to one question, and only
  /// one of them decided whether the row was written.
  final List<ReminderProblem> problems;

  /// A write is in flight.
  final bool saving;

  /// Whether this item may be deleted outright.
  ///
  /// §9: an item referenced by a `ServiceLine` "is not deletable"; the control
  /// becomes **Turn this reminder off**, and the records stay.
  bool get deletable => item != null && lineCount == 0;

  /// A copy with the given changes.
  ReminderEditReady copyWith({
    ReminderDraft? draft,
    ServiceItem? item,
    List<ReminderProblem>? problems,
    bool? saving,
  }) => ReminderEditReady(
    draft ?? this.draft,
    vehicle: vehicle,
    item: item ?? this.item,
    records: records,
    lineCount: lineCount,
    firstReading: firstReading,
    problems: problems ?? this.problems,
    saving: saving ?? this.saving,
  );
}

/// One reminder's editor.
///
/// The id is a raw STRING, `new` included: it comes from the path, and
/// `reminders.edit` is one route in two modes told apart by `kNewRecordId` —
/// the same shape `vehicle.edit` uses, and the reason no id may ever be the
/// word "new".
class RemindersEditNotifier extends Notifier<ReminderEditState> {
  /// Creates a notifier for [rawId].
  RemindersEditNotifier(this.rawId);

  /// The path segment: a `rem_<ULID>`, or `new`.
  final String rawId;

  @override
  ReminderEditState build() {
    // LISTENED to, not watched. `_load` awaits both futures, and a
    // `StreamProvider` with no subscriber never delivers — so a bare
    // `ref.read(...future)` would hang for ever, which is what the empty
    // editor body was. `listen` subscribes without re-running this build:
    // the form is read ONCE, because a form that re-read its own row would
    // discard the user's half-typed interval the moment anything else in the
    // app touched the item — and the save below is one of those things.
    ref
      ..listen(settingsProvider, (_, _) {})
      ..listen(vehiclesProvider, (_, _) {});

    unawaited(_load(rawId));
    return const ReminderEditLoading();
  }

  Future<void> _load(String rawId) async {
    // AWAITED, not read. `build()` runs on the first frame, when the garage
    // stream has not delivered — and a `.value` read there is null, which this
    // turned into `Missing`: the editor reported that the reminder did not
    // exist, on every open, before anything had been read at all.
    final settings = await ref.read(settingsProvider.future);
    final vehicles = await ref.read(vehiclesProvider.future);
    if (!ref.mounted) return;

    final vehicle = vehicles
        .where((v) => v.id == settings?.activeVehicleId)
        .firstOrNull;
    if (vehicle == null) {
      state = const ReminderEditMissing();
      return;
    }

    final unit = effectiveDistanceUnit(vehicle, settings);
    final separator = groupingSeparatorFor(
      ref.read(resolvedLocaleTagsProvider).formats,
    );

    if (rawId == kNewRecordId) {
      state = ReminderEditReady(
        ReminderDraft(unit: unit, groupingSeparator: separator),
        vehicle: vehicle,
        firstReading: _firstReading(await _readings(vehicle.id)),
      );
      return;
    }

    final id = ServiceItemId.tryParse(rawId);
    if (id == null) {
      state = const ReminderEditMissing();
      return;
    }

    // All four STARTED before any of them is awaited. None depends on
    // another's result — `countLinesFor` needs only the parsed id — and awaited
    // in turn they were four serialised round trips with an empty scaffold on
    // screen for the sum of them. The two stream reads do not even open their
    // subscription until their turn comes, so they cannot overlap by accident.
    // `bootstrap.dart` already starts its facts and its UI state this way.
    final repository = ref.read(serviceRepositoryProvider);
    final itemRead = repository.findItemById(id);
    final linesRead = repository.countLinesFor(id);
    final recordsRead = _records(vehicle.id);
    final readingsRead = _readings(vehicle.id);

    final read = await itemRead;
    if (!ref.mounted) return;
    if (read is! Ok<ServiceItem, PersistFailure>) {
      state = const ReminderEditMissing();
      return;
    }
    final item = read.value;
    final lines = await linesRead;
    final records = await recordsRead;
    final readings = await readingsRead;
    if (!ref.mounted) return;

    state = ReminderEditReady(
      ReminderDraft.of(item, unit: unit, groupingSeparator: separator),
      vehicle: vehicle,
      item: item,
      records: _recentRecords(records, id),
      lineCount: lines is Ok<int, PersistFailure> ? lines.value : 0,
      firstReading: _firstReading(readings),
    );
  }

  /// The vehicle's records, subscribed and awaited.
  ///
  /// `listen` then `read(...future)`: a `StreamProvider` with no subscriber
  /// never delivers, so a bare `.future` hangs and a bare `.value` is null for
  /// ever. The subscription is opened HERE rather than in `build`, because the
  /// vehicle id is not known until settings have arrived.
  Future<List<ServiceRecord>> _records(VehicleId vehicleId) {
    ref.listen(serviceRecordsProvider(vehicleId), (_, _) {});
    return ref.read(serviceRecordsProvider(vehicleId).future);
  }

  /// The vehicle's readings, subscribed and awaited. See [_records].
  Future<List<OdometerReading>> _readings(VehicleId vehicleId) {
    ref.listen(odometerReadingsProvider(vehicleId), (_, _) {});
    return ref.read(odometerReadingsProvider(vehicleId).future);
  }

  /// The five newest records naming the item, newest first.
  List<ServiceRecord> _recentRecords(
    List<ServiceRecord> all,
    ServiceItemId id,
  ) {
    final mine = [
      for (final record in all)
        if (record.lines.any((l) => l.serviceItemId == id)) record,
    ]..sort((a, b) => b.occurredOn.compareTo(a.occurredOn));
    return List.unmodifiable(mine.take(5));
  }

  Distance? _firstReading(List<OdometerReading> readings) {
    if (readings.isEmpty) return null;
    // The RAW earliest, not a cumulative one. The baseline field is a dash
    // number the user types, and comparing it to a correction-adjusted value
    // would reject a reading that matches the dash exactly.
    var lowest = readings.first.odometer;
    for (final reading in readings) {
      if (reading.odometer.metres < lowest.metres) lowest = reading.odometer;
    }
    return lowest;
  }

  /// Replaces the draft.
  void edit(ReminderDraft Function(ReminderDraft) change) {
    final current = state;
    if (current is! ReminderEditReady) return;
    state = current.copyWith(draft: change(current.draft));
  }

  /// Validates and writes, or surfaces the problems.
  ///
  /// Returns the item on success and null on refusal, so the caller can pop
  /// only when something was written.
  Future<ServiceItem?> save() async {
    final current = state;
    if (current is! ReminderEditReady || current.saving) return null;

    final today = CivilDate.fromDateTime(ref.read(clockProvider).now());
    final problems = validateReminderDraft(
      current.draft,
      today: today ?? CivilDate.epoch,
      firstReading: current.firstReading,
    );
    if (problems.isNotEmpty) {
      state = current.copyWith(problems: problems);
      return null;
    }

    state = current.copyWith(saving: true);
    final now = ref.read(clockProvider).now().millisecondsSinceEpoch;
    final existing = current.item;
    final draft = current.draft;

    final item = ServiceItem(
      id: existing?.id ?? ServiceItemId.mint(ref.read(ulidFactoryProvider)),
      vehicleId: current.vehicle.id,
      kind: draft.kind,
      label: draft.label.trim().isEmpty ? null : draft.label.trim(),
      intervalDistance: draft.intervalDistanceValue,
      intervalDistanceUnit: draft.intervalDistanceValue == null
          ? null
          : draft.unit,
      intervalMonths: draft.intervalMonthsValue,
      targetOdometer: draft.targetOdometerValue,
      targetDate: draft.targetDate?.toString(),
      baselineDate: draft.baselineDate?.toString(),
      baselineOdometer: draft.baselineOdometerValue,
      noticeDistance: draft.noticeDistanceValue,
      noticeDays: draft.noticeDaysValue,
      priority: draft.priority,
      rollover: draft.rollover,
      // A new item is TRACKED. §9's `+ Track` and the `+` both mean "remind me
      // about this", and an untracked new row would be invisible to the engine
      // the moment it was saved.
      isTracked: existing?.isTracked ?? true,
      isActive: existing?.isActive ?? true,
      notify: draft.notify,
      repeats: draft.repeats,
      // §9: "Editing any interval or baseline resets `snooze_count` to 0."
      // A snooze is a decision about the OLD schedule; carrying its count into
      // a new one silently escalates a reminder nobody snoozed.
      snoozedUntil: _scheduleChanged(existing, draft)
          ? null
          : existing?.snoozedUntil,
      snoozeUntilOdometer: _scheduleChanged(existing, draft)
          ? null
          : existing?.snoozeUntilOdometer,
      snoozeCount: _scheduleChanged(existing, draft)
          ? 0
          : (existing?.snoozeCount ?? 0),
      notes: draft.notes.trim().isEmpty ? null : draft.notes.trim(),
      createdAtUtcMs: existing?.createdAtUtcMs ?? now,
      updatedAtUtcMs: now,
    );

    final written = await ref.read(serviceRepositoryProvider).saveItem(item);
    // Read the state AGAIN. `current` was captured before the await, so
    // writing it back discarded anything typed during the write and restored
    // the problems a previous refused Save had left on it — an error line
    // under a field on the row that had just been written successfully. And
    // without the guard, a Cancel while the write is in flight disposes this
    // auto-dispose notifier and `state =` throws.
    if (!ref.mounted) return null;
    final live = state;
    if (live is ReminderEditReady) {
      // The saved ITEM goes back on the state. In create mode it was null and
      // stayed null, so a second Save — after one that succeeded without
      // popping, which is what a deep link opened as the first route does —
      // minted a fresh id and inserted a DUPLICATE reminder.
      state = live.copyWith(
        item: written is Ok<ServiceItem, PersistFailure> ? item : null,
        problems: const [],
        saving: false,
      );
    }
    return written is Ok<ServiceItem, PersistFailure> ? item : null;
  }

  /// Whether the schedule or the baseline moved.
  ///
  /// Compared as the FORM shows them, not as the row stores them. §9 resets
  /// `snooze_count`, `snoozed_until` and `snooze_until_odometer_m` when the
  /// schedule changes, so this decides whether a user's deferral survives — and
  /// it must answer "did they change anything?", not "does the round trip
  /// agree?".
  ///
  /// Those are different questions the moment a metric interval is shown on a
  /// miles vehicle. 10,000 km is 6,214 mi to the nearest whole mile, and
  /// 6,214 mi is 10,000,463 m — so opening the editor, touching nothing and
  /// pressing Save compared 10,000,000 against 10,000,463, called it a change,
  /// and silently threw away a snooze the user had set. Re-rendering the stored
  /// row through the same draft the form was built from makes the comparison
  /// exact in the only representation the user ever saw.
  bool _scheduleChanged(ServiceItem? existing, ReminderDraft draft) {
    if (existing == null) return false;
    final stored = ReminderDraft.of(
      existing,
      unit: draft.unit,
      groupingSeparator: draft.groupingSeparator,
    );
    return stored.intervalDistance != draft.intervalDistance ||
        stored.intervalMonths != draft.intervalMonths ||
        stored.targetOdometer != draft.targetOdometer ||
        stored.targetDate != draft.targetDate ||
        stored.baselineDate != draft.baselineDate ||
        stored.baselineOdometer != draft.baselineOdometer;
  }

  /// The banner's **Start tracking** and **Turn back on**.
  ///
  /// Owned here, and the state updated in place, because the screen used to
  /// write through the list notifier and then `ref.invalidate` this provider.
  /// That re-ran `_load` and replaced the DRAFT from the database while
  /// `_controllers` — a `putIfAbsent` map on the State — kept whatever the user
  /// had typed. The field went on showing `15000` while the draft behind it had
  /// reverted, and Save then wrote the stored value and threw the typing away.
  /// `build`'s own comment says the form is read ONCE for exactly this reason.
  ///
  /// Only the ITEM changes here, which is all the two banners read.
  Future<Result<void, PersistFailure>> setFlags({
    bool? tracked,
    bool? active,
  }) async {
    final current = state;
    final item = current is ReminderEditReady ? current.item : null;
    if (item == null) return const Err(NotFound('no item'));

    final now = ref.read(clockProvider).now().millisecondsSinceEpoch;
    final repository = ref.read(serviceRepositoryProvider);
    final written = tracked != null
        ? await repository.setItemTracked(
            item.id,
            isTracked: tracked,
            updatedAtUtcMs: now,
          )
        : await repository.setItemActive(
            item.id,
            isActive: active!,
            updatedAtUtcMs: now,
          );
    if (!ref.mounted || written is! Ok) return written;

    // Re-read the ROW, not the whole screen. `ServiceItem` has no `copyWith`
    // and inventing one here would be a second place that knows which columns
    // a flag write touches. One targeted query; the draft is untouched.
    final read = await repository.findItemById(item.id);
    if (!ref.mounted) return written;
    final live = state;
    if (live is ReminderEditReady && read is Ok<ServiceItem, PersistFailure>) {
      state = live.copyWith(item: read.value);
    }
    return written;
  }

  /// §9's delete: outright, with an Undo, and only when nothing names it.
  Future<Result<void, PersistFailure>> delete() async {
    final current = state;
    if (current is! ReminderEditReady || !current.deletable) {
      return const Err(NotFound('not deletable'));
    }
    return ref
        .read(serviceRepositoryProvider)
        .deleteItem(
          current.item!.id,
          deletedAtUtcMs: ref.read(clockProvider).now().millisecondsSinceEpoch,
        );
  }

  /// Puts back what [delete] removed.
}

/// One editor per reminder id, `new` included.
///
/// AUTO-DISPOSED, like `vehicleEditProvider`: one live notifier per reminder
/// ever edited is a leak the length of a session.
final NotifierProviderFamily<RemindersEditNotifier, ReminderEditState, String>
remindersEditProvider = NotifierProvider.autoDispose
    .family<RemindersEditNotifier, ReminderEditState, String>(
      RemindersEditNotifier.new,
    );
