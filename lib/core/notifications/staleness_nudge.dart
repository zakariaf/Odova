// Asking for a reading, without becoming the app that nags.
//
// SPEC.md §4.3. `odo_now`'s error grows linearly with the age of the last
// reading, so at some point the app has to ask. Every rule here exists because
// asking is expensive: a user who is asked twice and ignores it has answered,
// and a third ask is the one that gets the app muted — after which it cannot
// tell them their timing belt is due either.
//
// TWO CHANNELS, and they are not the same decision.
//
// The in-app card is free. No permission, no interruption, one line at the top
// of the vehicle screen, and §4.3.2 calls it "the whole feature". It is
// warranted by the drift alone.
//
// The notification is a backstop that costs one of two slots a week and can be
// revoked forever by a reflex. So it needs the card to have been ignored first,
// it is capped twice over, and it gives up after three.
//
// The card is by construction the WEAKER condition: a notification is never
// warranted where a card is not. A test pins that, because the inverse — a
// notification about a vehicle the app is not even showing a line for — is the
// shape this would fail in.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/notifications/notification_stage.dart';
import 'package:odova/core/value_equality.dart';

/// 15% of the smallest active distance interval. SPEC.md §4.3.1.
///
/// The SMALLEST, not the average or the nearest: a car with a 10,000 km oil
/// change and a 100,000 km timing belt is asked at 1,500 km of drift, because
/// the tightest interval is the one the estimate has to be good enough for.
const double kNudgeDriftFraction = 0.15;

/// Nothing due beyond this is worth asking about. SPEC.md §4.3.1.
///
/// The SAME 120 as the scheduling horizon, and referenced rather than repeated:
/// §4.3.1 and §6.1 state it separately, but a reading that sharpens an estimate
/// nothing is scheduled against is a question with no purpose, so if one moves
/// the other has to.
const int kNudgeHorizonDays = kHorizonDays;

/// The escalation window — due this soon and a reading this old asks anyway.
const int kNudgeEscalationDays = 21;

/// No nudge in a vehicle's first fortnight.
///
/// There is no rate worth sharpening yet, and the user has just done a lot of
/// typing to add the car.
const int kNudgeMinVehicleAgeDays = 14;

/// At most one nudge per vehicle per 30 days.
const int kNudgePerVehicleDays = 30;

/// At most one nudge across ALL vehicles per 14 days.
///
/// A household with five cars must not receive five nudges in a week because
/// each is individually inside its own 30-day cap.
const int kNudgeAcrossVehiclesDays = 14;

/// Three ignored, and the app stops asking.
const int kNudgeGiveUpCount = 3;

/// For this long. The card stays; only the notification stops.
const int kNudgeGiveUpDays = 180;

/// The card must have been seen and unactioned across this many app opens.
const int kNudgeCardOpens = 2;

/// Or the app must not have been opened for this long.
const int kNudgeAwayDays = 21;

/// Everything the decision reads, for one vehicle.
@immutable
class NudgeFacts with ValueEquality {
  /// Creates the facts.
  const NudgeFacts({
    required this.metresPerDay,
    required this.daysSinceLastReading,
    required this.smallestIntervalMetres,
    required this.nearestDistanceDueDays,
    required this.status,
    required this.vehicleAgeDays,
    required this.daysSinceLastNudge,
    required this.daysSinceAnyNudge,
    required this.consecutiveIgnored,
    required this.daysSinceGaveUp,
    required this.cardSeenOpens,
    required this.daysSinceAppOpened,
  });

  /// The rate the projection is using.
  final int metresPerDay;

  /// How stale the last entered reading is.
  final int daysSinceLastReading;

  /// The smallest interval on an ACTIVE distance-driven item, or null when the
  /// vehicle has none — in which case there is nothing to sharpen.
  final int? smallestIntervalMetres;

  /// Days until the nearest active distance-driven item is projected due, or
  /// null when there is none.
  final int? nearestDistanceDueDays;

  /// Archived and sold vehicles are never nudged.
  final VehicleStatus status;

  /// How long the vehicle has existed.
  final int vehicleAgeDays;

  /// Since the last nudge for THIS vehicle, or null if never.
  final int? daysSinceLastNudge;

  /// Since the last nudge for ANY vehicle, or null if never.
  final int? daysSinceAnyNudge;

  /// Consecutive nudges with no reading logged within 7 days of each.
  final int consecutiveIgnored;

  /// Since the give-up rule fired, or null if it has not.
  final int? daysSinceGaveUp;

  /// App opens where the card was visible and not acted on.
  final int cardSeenOpens;

  /// Since the app was last opened.
  final int daysSinceAppOpened;

  @override
  List<Object?> get props => [
    metresPerDay,
    daysSinceLastReading,
    smallestIntervalMetres,
    nearestDistanceDueDays,
    status,
    vehicleAgeDays,
    daysSinceLastNudge,
    daysSinceAnyNudge,
    consecutiveIgnored,
    daysSinceGaveUp,
    cardSeenOpens,
    daysSinceAppOpened,
  ];
}

/// Whether to show the card, whether to send the notification, and how far off
/// the estimate has drifted.
@immutable
class NudgeDecision with ValueEquality {
  /// Creates a decision.
  const NudgeDecision({
    required this.warrantsCard,
    required this.warrantsNotification,
    required this.driftMetres,
    required this.isEscalated,
  });

  /// The in-app line. Free, always available, and the primary channel.
  final bool warrantsCard;

  /// The OS notification. Costs a slot and can be revoked.
  final bool warrantsNotification;

  /// `rate x days`, for picking between vehicles and for the card's wording.
  final int driftMetres;

  /// Whether §4.3.1's escalation is what warranted this rather than the
  /// formula.
  final bool isEscalated;

  @override
  List<Object?> get props => [
    warrantsCard,
    warrantsNotification,
    driftMetres,
    isEscalated,
  ];
}

/// SPEC.md §4.3, for one vehicle.
NudgeDecision shouldNudge(NudgeFacts facts) {
  final drift = facts.metresPerDay * facts.daysSinceLastReading;

  final never =
      facts.status != VehicleStatus.active ||
      facts.vehicleAgeDays < kNudgeMinVehicleAgeDays ||
      facts.smallestIntervalMetres == null ||
      facts.nearestDistanceDueDays == null ||
      facts.nearestDistanceDueDays! > kNudgeHorizonDays;

  if (never) {
    return NudgeDecision(
      warrantsCard: false,
      warrantsNotification: false,
      driftMetres: drift,
      isEscalated: false,
    );
  }

  final overThreshold =
      drift > kNudgeDriftFraction * facts.smallestIntervalMetres!;

  // §4.3.1's escalation: due soon AND the reading is old, regardless of the
  // formula. Being wrong about a date three weeks out is the case where being
  // wrong costs money, and 900 km of drift on a 10,000 km interval is under
  // threshold while being plenty to move a due date across a fortnight.
  final escalated =
      facts.nearestDistanceDueDays! <= kNudgeEscalationDays &&
      facts.daysSinceLastReading > kNudgeEscalationDays;

  final card = overThreshold || escalated;

  // The card has been visible and ignored, OR the user is not seeing cards at
  // all — which is exactly the user this notification exists for, and the one
  // who can never satisfy the two-opens rule.
  final cardWasIgnored =
      facts.cardSeenOpens >= kNudgeCardOpens ||
      facts.daysSinceAppOpened >= kNudgeAwayDays;

  final perVehicleOk =
      facts.daysSinceLastNudge == null ||
      facts.daysSinceLastNudge! >= kNudgePerVehicleDays;

  final acrossVehiclesOk =
      facts.daysSinceAnyNudge == null ||
      facts.daysSinceAnyNudge! >= kNudgeAcrossVehiclesDays;

  // §4.3.3's give-up rule. Silences the NOTIFICATION and never the card: the
  // card costs the user nothing, and the app degrades to hedged language
  // rather than going quiet about a stale estimate it is still using.
  final gaveUp =
      facts.consecutiveIgnored >= kNudgeGiveUpCount &&
      (facts.daysSinceGaveUp ?? 0) < kNudgeGiveUpDays;

  return NudgeDecision(
    warrantsCard: card,
    warrantsNotification:
        card && cardWasIgnored && perVehicleOk && acrossVehiclesOk && !gaveUp,
    driftMetres: drift,
    isEscalated: escalated,
  );
}

/// Which vehicle gets the one nudge, or null when none of them warrants one.
///
/// §4.3.3: "pick the vehicle with the largest drift". Largest DRIFT, not the
/// oldest reading — a van doing 200 km a day drifts further in a week than a
/// second car does in a month, and drift is what the estimate's error actually
/// is.
///
/// A tie breaks on the id so two runs agree. Without it the answer depends on
/// map iteration order, and the same household would nudge about a different
/// car on two devices.
String? pickNudgeVehicle(Map<String, NudgeFacts> byVehicle) {
  String? best;
  var bestDrift = -1;

  final ids = byVehicle.keys.toList()..sort();
  for (final id in ids) {
    final decision = shouldNudge(byVehicle[id]!);
    if (!decision.warrantsNotification) continue;
    if (decision.driftMetres > bestDrift) {
      best = id;
      bestDrift = decision.driftMetres;
    }
  }
  return best;
}
