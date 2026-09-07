// Two hundred and forty things that want attention, and about thirty-four
// chances to ask for it.
//
// SPEC.md §4.3 is the rule this file exists to keep:
//
//   Never more than 2 notifications in any rolling 7 days, and never more than
//   1 in a calendar day, across every vehicle and every reminder combined —
//   nudges included.
//
// "Not a preference — the product." A household with five cars and twelve
// reminders each generates 240 stage-and-item combinations, and the difference
// between an app somebody keeps and one they mute is entirely in what happens
// to the other two hundred.
//
// PURE, and that is not an aesthetic choice. The cap is a claim about a SET —
// "at most two in any rolling seven days" — and a device can only ever show you
// one delivery. There is no on-device test of this rule. This function is
// therefore the only place it can be checked, which is why it takes a `today`
// instead of reading a clock and returns a list instead of calling a gateway.
//
// It also cannot throw. It runs on the cold-launch path and on a boot receiver,
// and every degenerate input — no candidates, a date in 1999, a date in 2999 —
// returns a list.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/notifications/delivery_slot.dart';
import 'package:odova/core/notifications/notification_stage.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/value_equality.dart';

/// 46 = 48 − 2. SPEC.md §6.1.
///
/// iOS silently keeps only the 64 soonest pending notifications and discards
/// the rest with no error, so the cross-platform budget is 48 and two are held
/// back for the keeper and whatever §6.2 needs to add out of band. The number
/// appears ONCE, here.
///
/// In practice the cap reaches this almost never: 120 days at two a week is
/// about 34. It is a backstop against an arithmetic mistake somewhere else,
/// which is exactly the kind of bug that ships silently on iOS.
const int kPendingBudget = 46;

/// 21 days. SPEC.md §4.3 step 3.
///
/// Past this an item is DROPPED rather than deferred again: "a notification
/// arriving a month late is noise". Affordable only because the home screen
/// still shows the item — the in-app list is the primary channel and §6.4 says
/// no feature may depend on delivery.
const int kMaxDeferralDays = 21;

/// Two of the next four weeks' slots. SPEC.md §4.3 step 4.
const int kReservedSlots = 2;

/// The window those slots are reserved within.
const int kReserveWindowDays = 28;

/// One thing that wants a notification on one day.
@immutable
class ReminderCandidate with ValueEquality {
  /// Creates a candidate.
  const ReminderCandidate({
    required this.vehicleId,
    required this.reminderId,
    required this.stage,
    required this.stageDate,
    required this.priority,
    required this.projectedDue,
    required this.vehicleName,
    required this.label,
  });

  /// The vehicle it belongs to.
  final String vehicleId;

  /// The item, or null for a nudge — which is about the vehicle.
  final String? reminderId;

  /// Which of §4.4.1's stages this is.
  final NotificationStage stage;

  /// The day the stage wants, before quiet hours and the weekday shift.
  final CivilDate stageDate;

  /// Safety, normal or low — the within-tier tie-break.
  final ServicePriority priority;

  /// The item's projected due date, for the last tie-break.
  final CivilDate projectedDue;

  /// The vehicle's name, for the title.
  final String vehicleName;

  /// The item's label, for a grouped body.
  final String label;

  @override
  List<Object?> get props => [
    vehicleId,
    reminderId,
    stage,
    stageDate,
    priority,
    projectedDue,
    vehicleName,
    label,
  ];

  @override
  String toString() =>
      'ReminderCandidate($vehicleId/$reminderId, ${stage.name})';
}

/// One notification, decided but not yet worded.
///
/// The scheduler stops HERE rather than returning a `ScheduledNotification`.
/// The remaining step — the title, the body and the deterministic id — needs
/// the locale, and this file must not: §4.2's copy is six languages of ICU with
/// numeral shaping, and pulling that in would make the one function that can
/// prove §4.3 depend on a localisation lookup.
///
/// The epic's task text asks `compute` to return `List<ScheduledNotification>`.
/// It returns this instead, and the render step is a separate, thin function —
/// so the hard rules stay testable with plain data and the easy part stays
/// where the strings are.
@immutable
class PlannedNotification with ValueEquality {
  /// Creates a plan.
  const PlannedNotification({required this.slot, required this.candidates});

  /// When it goes out.
  final DeliverySlot slot;

  /// What it is about. More than one means a grouped notification.
  final List<ReminderCandidate> candidates;

  /// Whether it names more than one vehicle.
  bool get isMultiVehicle =>
      candidates.map((c) => c.vehicleId).toSet().length > 1;

  /// The vehicle routing opens.
  ///
  /// §4.4.2: "the first vehicle named in the body when several are grouped".
  /// The first CANDIDATE and not, say, the alphabetically first: the body is
  /// written in this order, so a user who taps "Passat and the van" has to
  /// land on the Passat.
  String get vehicleId => candidates.first.vehicleId;

  /// The reminder this pins, or null when it names several.
  String? get reminderId =>
      candidates.length == 1 ? candidates.single.reminderId : null;

  /// §4.4.2's `kind`.
  DeepLinkKind get payloadKind => candidates.length == 1
      ? candidates.single.stage.payloadKind
      : DeepLinkKind.reminderGrouped;

  // SPREAD, not `[slot, candidates]`. `valuesEqual` compares props
  // element-by-element with `==`, and `==` on two distinct Lists is identity —
  // so a nested list makes every instance unequal to every other, including an
  // identical one. That is what "the same inputs produce the same list" caught:
  // the scheduler was deterministic and its output type could not say so.
  @override
  List<Object?> get props => [slot, ...candidates];

  @override
  String toString() =>
      'PlannedNotification(${slot.wallClock}, ${candidates.length} item(s))';
}

/// Turns everything wanting attention into the few notifications §4.3
/// allows.
abstract final class ReminderScheduler {
  /// The plan, in delivery order.
  static List<PlannedNotification> compute({
    required List<ReminderCandidate> candidates,
    required CivilDate today,
    required SchedulePreferences prefs,
    int budget = kPendingBudget,
  }) {
    // §4.4.4: a low-priority item gets ONE notification, at `due`. Filtered
    // before anything else so a wipers reminder cannot occupy an early slot and
    // then lose it again — which would be three passes deciding the same thing.
    final eligible = [
      for (final c in candidates)
        if (withinHorizon(today: today, stage: c.stageDate) &&
            !(c.priority == ServicePriority.low &&
                c.stage != NotificationStage.due))
          c,
    ];

    // §4.3 step 1 — COALESCE FIRST, and the order of the three steps is the
    // whole design. Items landing in the same slot merge into one grouped
    // notification BEFORE anything competes, because one notification carrying
    // five items is one notification. Prioritising first and coalescing after
    // would make five items due on one Tuesday spend five slots and then throw
    // three away, which is how a household with two cars goes silent.
    final byWantedDate = <String, List<ReminderCandidate>>{};
    for (final candidate in eligible) {
      final wanted = resolveSlot(date: candidate.stageDate, prefs: prefs);
      (byWantedDate[wanted.date] ??= []).add(candidate);
    }

    // Inside a group the order IS the body's order, and §4.4.2 makes the first
    // vehicle named the one a tap opens — so it has to be the most urgent one
    // rather than whichever was read first.
    for (final group in byWantedDate.values) {
      group.sort(_contention);
    }

    // §4.3 step 2 — then prioritise. The competition is between SLOTS, not
    // between items: each group carries the rank of its best member, because a
    // slot holding one overdue safety item and four early ones is an overdue
    // slot.
    final groups = byWantedDate.entries.toList()
      ..sort((a, b) {
        final byBest = _contention(a.value.first, b.value.first);
        // The date breaks a tie between two groups whose best members are
        // indistinguishable. Without it the answer depends on map iteration
        // order, and §4.3 promises the same inputs give the same list.
        return byBest != 0 ? byBest : a.key.compareTo(b.key);
      });

    final taken = <String, PlannedNotification>{};

    for (final MapEntry(key: wantedDate, value: group) in groups) {
      var slot = resolveSlot(
        date: CivilDate.tryParse(wantedDate)!,
        prefs: prefs,
      );
      var deferred = 0;

      // §4.3 step 3 — then defer, one day at a time, until the cap allows it.
      while (!_isFree(taken.keys, slot, group.first, today) &&
          deferred <= kMaxDeferralDays) {
        slot = resolveSlot(
          date: CivilDate.tryParse(slot.date)!.addDays(1),
          prefs: prefs,
        );
        deferred = group.first.stageDate.daysUntil(
          CivilDate.tryParse(slot.date)!,
        );
      }

      // Past 21 days it is DROPPED and not queued forever — "a notification
      // arriving a month late is noise". Also dropped when deferral pushed it
      // past the horizon: something four months out, arriving three weeks
      // late, is noise twice over. Affordable in both cases only because the
      // home screen still shows the item; §6.4 says no feature may depend on
      // delivery.
      if (deferred > kMaxDeferralDays ||
          !withinHorizon(today: today, stage: CivilDate.tryParse(slot.date)!)) {
        continue;
      }

      taken[slot.date] = PlannedNotification(slot: slot, candidates: group);
    }

    final plan = taken.values.toList()
      ..sort((a, b) => a.slot.compareTo(b.slot));

    // §6.1's last line: take the first `budget` and mark the rest unscheduled.
    // The NEAREST ones, because iOS keeps the soonest 64 and discards the rest
    // silently — so anything that has to go should be the far future, which
    // will be recomputed before it arrives anyway.
    return plan.length <= budget ? plan : plan.sublist(0, budget);
  }

  /// §4.3 step 2's order: stage, then priority, then nearest due, then id.
  ///
  /// The final id comparison is not decoration. Without it two candidates with
  /// the same stage, priority and due date compare equal, and which of them
  /// takes the slot is then decided by the sort's stability — an implementation
  /// detail that would make the same household produce different schedules on
  /// two devices, which §4.3 forbids in as many words.
  static int _contention(ReminderCandidate a, ReminderCandidate b) {
    final byStage = a.stage.rank.compareTo(b.stage.rank);
    if (byStage != 0) return byStage;

    final byPriority = _priorityRank(a.priority).compareTo(
      _priorityRank(b.priority),
    );
    if (byPriority != 0) return byPriority;

    final byDue = a.projectedDue.compareTo(b.projectedDue);
    if (byDue != 0) return byDue;

    final byVehicle = a.vehicleId.compareTo(b.vehicleId);
    if (byVehicle != 0) return byVehicle;

    return (a.reminderId ?? '').compareTo(b.reminderId ?? '');
  }

  static int _priorityRank(ServicePriority p) => switch (p) {
    ServicePriority.safety => 0,
    ServicePriority.normal => 1,
    ServicePriority.low => 2,
  };

  /// Whether [slot] may be used, given what is already taken.
  ///
  /// Both halves of §4.3, plus step 4's reserve. The reserve is checked LAST
  /// because it only ever refuses — it can turn a free slot into a taken one
  /// for a candidate that may not claim it, and never the other way round.
  static bool _isFree(
    Iterable<String> taken,
    DeliverySlot slot,
    ReminderCandidate candidate,
    CivilDate today,
  ) {
    // §4.3's "never more than 1 in a calendar day".
    //
    // A mutation removing this line leaves every test green, and the reason is
    // worth knowing rather than fixing: `taken` is keyed BY DATE, so a second
    // group landing on an occupied day would overwrite the first rather than
    // join it. The map makes the one-a-day rule structural — but the failure
    // mode without this guard is a notification that vanishes silently instead
    // of one that duplicates, which no assertion about the OUTPUT can see.
    // The guard stays because it is the line that makes the loop's intent
    // legible, and because the day somebody swaps the map for a list is the day
    // the silent overwrite becomes a visible duplicate.
    if (taken.contains(slot.date)) return false;

    final day = CivilDate.tryParse(slot.date);
    if (day == null) return false;

    // Two in any rolling seven days means: with this one added, no window of
    // seven consecutive days may hold three. Checking the six days either side
    // is equivalent and cheaper than walking every window.
    var neighbours = 0;
    for (final other in taken) {
      final o = CivilDate.tryParse(other);
      if (o == null) continue;
      if (day.daysUntil(o).abs() <= 6) neighbours++;
    }
    if (neighbours >= 2) return false;

    // §4.3 step 4 — two of the next four weeks' slots are held for overdue and
    // nudge, so a queue full of early warnings cannot starve an urgent item.
    //
    // **Currently unreachable, and kept deliberately.** A mutation deleting the
    // refusal below leaves every test green, because the queue is sorted by
    // stage rank BEFORE anything is placed: every overdue and every nudge has
    // already taken its slot by the time the first `early` is considered, so
    // there is no urgent item left to starve. Step 4 is the fix for a scheduler
    // that places in DATE order, and §4.2.1's "recompute everything, always"
    // means this one never does.
    //
    // It stays because SPEC.md wins over the code until a deliberate PR changes
    // it (CLAUDE.md §3), and because the assumption that makes it inert — the
    // priority sort — is one line that a future change could reverse without
    // noticing. Raised as a spec question rather than deleted quietly; its only
    // effect today is to leave up to two slots of the next four weeks unused,
    // which makes the app quieter and never louder.
    if (!candidate.stage.claimsReservedSlot) {
      final withinReserve = today.daysUntil(day) <= kReserveWindowDays;
      if (withinReserve) {
        final usedInWindow = taken
            .map(CivilDate.tryParse)
            .whereType<CivilDate>()
            .where((x) => today.daysUntil(x) <= kReserveWindowDays)
            .length;
        // Four weeks holds at most eight slots at two a week; two of them are
        // not for this candidate.
        const capacity = (kReserveWindowDays ~/ 7) * 2;
        if (usedInWindow >= capacity - kReservedSlots) return false;
      }
    }

    return true;
  }
}
