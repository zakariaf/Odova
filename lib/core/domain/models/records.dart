// The things a driver logs, as everything above the data layer sees them.
//
// Canonical integers with the unit in the NAME — `odometerM`, `quantityMl`,
// `totalCostMinor` + `currency`. EPIC-06 swaps these for `Distance`, `Volume`
// and `Money` value objects at the repository boundary in one pass; until then
// the suffix is what stops a metre being added to a mile, and it is the only
// thing that does.
//
// Every one of these is immutable and compares by value, so a watched stream
// can skip a rebuild when nothing changed.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/value_equality.dart';

/// The reminder definition: the thing that comes due.
class ServiceItem with ValueEquality {
  /// Creates a service item.
  const ServiceItem({
    required this.id,
    required this.vehicleId,
    required this.kind,
    required this.priority,
    required this.rollover,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    this.label,
    this.intervalDistanceM,
    this.intervalDistanceUnit,
    this.intervalMonths,
    this.targetOdometerM,
    this.targetDate,
    this.baselineDate,
    this.baselineOdometerM,
    this.noticeDistanceM,
    this.noticeDays,
    this.isTracked = false,
    this.isActive = true,
    this.notify = true,
    this.repeats = true,
    this.snoozedUntil,
    this.snoozeUntilOdometerM,
    this.snoozeCount = 0,
    this.notes,
  });

  /// `rem_<ULID>`.
  final ServiceItemId id;

  /// The vehicle.
  final VehicleId vehicleId;

  /// Which catalogue item, or `custom`.
  final ServiceKind kind;

  /// What to call it. Required when [kind] is [ServiceKind.custom].
  final String? label;

  /// Distance interval in metres. Null = not distance-based.
  final int? intervalDistanceM;

  /// The unit the interval was entered in. Display fidelity only.
  final DistanceUnit? intervalDistanceUnit;

  /// Time interval in months. Null = not time-based.
  final int? intervalMonths;

  /// A one-off target odometer, in metres.
  final int? targetOdometerM;

  /// A one-off target date.
  final String? targetDate;

  /// "Last done March 2024".
  final String? baselineDate;

  /// The odometer at [baselineDate], in metres.
  final int? baselineOdometerM;

  /// Per-item distance notice window override, in metres.
  final int? noticeDistanceM;

  /// Per-item time notice window override, in days.
  final int? noticeDays;

  /// False = seeded but never adopted; invisible to the due engine.
  final bool isTracked;

  /// False = the user paused it.
  final bool isActive;

  /// Whether it may raise a notification.
  final bool notify;

  /// How it sorts when several are due at once.
  final ServicePriority priority;

  /// What the next due date is measured from when it completes late.
  final ServiceRollover rollover;

  /// False = completes once and retires.
  final bool repeats;

  /// Snoozed until this date.
  final String? snoozedUntil;

  /// Snoozed until this odometer, in metres.
  final int? snoozeUntilOdometerM;

  /// How many times it has been snoozed.
  final int snoozeCount;

  /// Free text.
  final String? notes;

  /// When the row was written.
  final int createdAtUtcMs;

  /// When it was last changed.
  final int updatedAtUtcMs;

  /// Whether the distance axis applies.
  ///
  /// DERIVED from the fields, never stored. SPEC.md §3: there is no `mode`
  /// column, because a stored mode is a second answer to a question the data
  /// already answers.
  bool get hasDistanceAxis =>
      intervalDistanceM != null || targetOdometerM != null;

  /// Whether the time axis applies. Derived, for the same reason.
  bool get hasTimeAxis => intervalMonths != null || targetDate != null;

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    kind,
    label,
    intervalDistanceM,
    intervalDistanceUnit,
    intervalMonths,
    targetOdometerM,
    targetDate,
    baselineDate,
    baselineOdometerM,
    noticeDistanceM,
    noticeDays,
    isTracked,
    isActive,
    notify,
    priority,
    rollover,
    repeats,
    snoozedUntil,
    snoozeUntilOdometerM,
    snoozeCount,
    notes,
    createdAtUtcMs,
    updatedAtUtcMs,
  ];

  @override
  String toString() => 'ServiceItem($id, ${kind.wire})';
}

/// One line of a service record.
class ServiceLine with ValueEquality {
  /// Creates a service line.
  const ServiceLine({
    required this.id,
    required this.serviceRecordId,
    required this.label,
    required this.amountMinor,
    required this.currency,
    this.serviceItemId,
    this.partNumber,
    this.notes,
  });

  /// `lin_<ULID>`.
  final ServiceLineId id;

  /// The record this belongs to.
  final ServiceRecordId serviceRecordId;

  /// Which reminder this line resets, or null.
  ///
  /// Null after the item is deleted — the line keeps its [label] and
  /// [amountMinor], because SPEC.md §3 says history is never destroyed to tidy
  /// a reminder list.
  final ServiceItemId? serviceItemId;

  /// What it was.
  final String label;

  /// The amount in minor units. Never negative; zero means "not recorded".
  final int amountMinor;

  /// The currency, ISO 4217.
  final String currency;

  /// The part fitted.
  final String? partNumber;

  /// Free text.
  final String? notes;

  @override
  List<Object?> get props => [
    id,
    serviceRecordId,
    serviceItemId,
    label,
    amountMinor,
    currency,
    partNumber,
    notes,
  ];

  @override
  String toString() => 'ServiceLine($id, $label)';
}

/// A job that was actually done.
class ServiceRecord with ValueEquality {
  /// Creates a service record.
  const ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.occurredOn,
    required this.odometerUnit,
    required this.lines,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    this.odometerM,
    this.odometerEstimated = false,
    this.costEstimated = false,
    this.vendor,
    this.invoiceRef,
    this.warrantyUntil,
    this.notes,
  });

  /// `srv_<ULID>`.
  final ServiceRecordId id;

  /// The vehicle.
  final VehicleId vehicleId;

  /// The day the work happened.
  final String occurredOn;

  /// The odometer at the time, in metres.
  final int? odometerM;

  /// The unit it was entered in.
  final DistanceUnit odometerUnit;

  /// True = the app filled the odometer in, so it is drawn with a `~`.
  final bool odometerEstimated;

  /// True = no cost was recorded. Contributes 0 and prints `—`.
  final bool costEstimated;

  /// Who did the work.
  final String? vendor;

  /// The workshop's reference.
  final String? invoiceRef;

  /// When the workshop's warranty expires.
  final String? warrantyUntil;

  /// Free text.
  final String? notes;

  /// At least one, always.
  final List<ServiceLine> lines;

  /// When the row was written.
  final int createdAtUtcMs;

  /// When it was last changed.
  final int updatedAtUtcMs;

  /// The cost, in minor units.
  ///
  /// DERIVED — there is no total column. SPEC.md §3: cost is always the sum of
  /// the lines, and a stored total drifts the first time one is edited.
  int get totalMinor => lines.fold(0, (sum, line) => sum + line.amountMinor);

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    occurredOn,
    odometerM,
    odometerUnit,
    odometerEstimated,
    costEstimated,
    vendor,
    invoiceRef,
    warrantyUntil,
    notes,
    ...lines,
    createdAtUtcMs,
    updatedAtUtcMs,
  ];

  @override
  String toString() => 'ServiceRecord($id, $occurredOn, ${lines.length} lines)';
}

/// A fill-up.
class FillUp with ValueEquality {
  /// Creates a fill-up.
  const FillUp({
    required this.id,
    required this.vehicleId,
    required this.occurredOn,
    required this.odometerUnit,
    required this.fuelKind,
    required this.quantityUnit,
    required this.totalCostMinor,
    required this.currency,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    this.odometerM,
    this.quantityMl,
    this.quantityG,
    this.energyWh,
    this.isFullTank = true,
    this.chainBroken = false,
    this.grade,
    this.station,
    this.tripId,
    this.notes,
  });

  /// `fil_<ULID>`.
  final FillUpId id;

  /// The vehicle. Carried directly even when [tripId] is set.
  final VehicleId vehicleId;

  /// The day it happened.
  final String occurredOn;

  /// The odometer, in metres.
  final int? odometerM;

  /// The unit it was entered in.
  final DistanceUnit odometerUnit;

  /// What went in.
  final FuelKind fuelKind;

  /// Millilitres, for a liquid.
  final int? quantityMl;

  /// Grams, for CNG.
  final int? quantityG;

  /// Watt-hours, for electricity.
  final int? energyWh;

  /// The unit the quantity was entered in.
  final VolumeUnit quantityUnit;

  /// What it cost, in minor units.
  final int totalCostMinor;

  /// The currency, ISO 4217.
  final String currency;

  /// Whether the tank was filled.
  final bool isFullTank;

  /// "I forgot to log one before this."
  final bool chainBroken;

  /// "95", "Diesel B7", "DC 150kW".
  final String? grade;

  /// Where.
  final String? station;

  /// The trip, if any.
  final TripId? tripId;

  /// Free text.
  final String? notes;

  /// When the row was written.
  final int createdAtUtcMs;

  /// When it was last changed.
  final int updatedAtUtcMs;

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    occurredOn,
    odometerM,
    odometerUnit,
    fuelKind,
    quantityMl,
    quantityG,
    energyWh,
    quantityUnit,
    totalCostMinor,
    currency,
    isFullTank,
    chainBroken,
    grade,
    station,
    tripId,
    notes,
    createdAtUtcMs,
    updatedAtUtcMs,
  ];

  @override
  String toString() => 'FillUp($id, $occurredOn)';
}

/// A payment.
class Expense with ValueEquality {
  /// Creates an expense.
  const Expense({
    required this.id,
    required this.vehicleId,
    required this.occurredOn,
    required this.category,
    required this.amountMinor,
    required this.currency,
    required this.odometerUnit,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    this.tripId,
    this.label,
    this.coversFrom,
    this.coversTo,
    this.odometerM,
    this.vendor,
    this.notes,
  });

  /// `exp_<ULID>`.
  final ExpenseId id;

  /// The vehicle.
  final VehicleId vehicleId;

  /// The trip, if any.
  final TripId? tripId;

  /// The day it was PAID.
  final String occurredOn;

  /// What it was for.
  final ExpenseCategory category;

  /// Required when [category] is [ExpenseCategory.other].
  final String? label;

  /// The amount in minor units.
  ///
  /// **May be negative** — a refund, a warranty reimbursement, an insurance
  /// payout. The only money field in the app that may.
  final int amountMinor;

  /// The currency, ISO 4217.
  final String currency;

  /// The start of an optional coverage window.
  final String? coversFrom;

  /// The end of it.
  final String? coversTo;

  /// The odometer, in metres.
  final int? odometerM;

  /// The unit it was entered in.
  final DistanceUnit odometerUnit;

  /// Who was paid.
  final String? vendor;

  /// Free text.
  final String? notes;

  /// When the row was written.
  final int createdAtUtcMs;

  /// When it was last changed.
  final int updatedAtUtcMs;

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    tripId,
    occurredOn,
    category,
    label,
    amountMinor,
    currency,
    coversFrom,
    coversTo,
    odometerM,
    odometerUnit,
    vendor,
    notes,
    createdAtUtcMs,
    updatedAtUtcMs,
  ];

  @override
  String toString() => 'Expense($id, ${category.wire})';
}

/// A trip.
class Trip with ValueEquality {
  /// Creates a trip.
  const Trip({
    required this.id,
    required this.vehicleId,
    required this.purpose,
    required this.startedOn,
    required this.odometerUnit,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    this.title,
    this.endedOn,
    this.startOdometerM,
    this.endOdometerM,
    this.manualDistanceM,
    this.notes,
  });

  /// `trp_<ULID>`.
  final TripId id;

  /// The vehicle.
  final VehicleId vehicleId;

  /// What to call it.
  final String? title;

  /// Why it was taken.
  final TripPurpose purpose;

  /// The day it began.
  final String startedOn;

  /// The day it ended, or null for an open trip.
  final String? endedOn;

  /// The odometer at the start, in metres.
  final int? startOdometerM;

  /// The odometer at the end, in metres.
  final int? endOdometerM;

  /// A distance typed by hand.
  final int? manualDistanceM;

  /// The unit the readings were entered in.
  final DistanceUnit odometerUnit;

  /// Free text.
  final String? notes;

  /// When the row was written.
  final int createdAtUtcMs;

  /// When it was last changed.
  final int updatedAtUtcMs;

  /// The distance, in metres, or null when neither source is available.
  ///
  /// DERIVED. The odometer endpoints win; [manualDistanceM] is used ONLY when
  /// both are absent, per SPEC.md §3 — a trip is never the source of truth for
  /// total distance, because people log some trips and not all.
  int? get distanceM {
    final start = startOdometerM;
    final end = endOdometerM;
    if (start != null && end != null) return end - start;
    return manualDistanceM;
  }

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    title,
    purpose,
    startedOn,
    endedOn,
    startOdometerM,
    endOdometerM,
    manualDistanceM,
    odometerUnit,
    notes,
    createdAtUtcMs,
    updatedAtUtcMs,
  ];

  @override
  String toString() => 'Trip($id, ${purpose.wire})';
}

/// An odometer reading.
class OdometerReading with ValueEquality {
  /// Creates a reading.
  const OdometerReading({
    required this.id,
    required this.vehicleId,
    required this.occurredOn,
    required this.odometerM,
    required this.odometerUnit,
    required this.source,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    this.sourceId,
    this.notes,
  });

  /// `odo_<ULID>`.
  final OdometerReadingId id;

  /// The vehicle.
  final VehicleId vehicleId;

  /// The day the dash showed this.
  final String occurredOn;

  /// The RAW dash number, in metres. The cumulative value is a function.
  final int odometerM;

  /// The unit it was entered in.
  final DistanceUnit odometerUnit;

  /// Which record produced it.
  final OdometerSource source;

  /// The row that produced it, if any.
  final String? sourceId;

  /// Free text.
  final String? notes;

  /// When the row was written.
  final int createdAtUtcMs;

  /// When it was last changed.
  final int updatedAtUtcMs;

  /// Whether this reading follows a parent record rather than standing alone.
  ///
  /// A derived reading is not directly editable — editing it would leave the
  /// reading and the record that produced it disagreeing, with nothing to say
  /// which is right.
  bool get isDerived => source != OdometerSource.manual;

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    occurredOn,
    odometerM,
    odometerUnit,
    source,
    sourceId,
    notes,
    createdAtUtcMs,
    updatedAtUtcMs,
  ];

  @override
  String toString() => 'OdometerReading($id, $occurredOn, $odometerM m)';
}

/// An odometer correction.
class OdometerCorrection with ValueEquality {
  /// Creates a correction.
  const OdometerCorrection({
    required this.id,
    required this.vehicleId,
    required this.fromReadingId,
    required this.previousM,
    required this.newM,
    required this.odometerUnit,
    required this.reason,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    this.notes,
  });

  /// `cor_<ULID>`.
  final OdometerCorrectionId id;

  /// The vehicle.
  final VehicleId vehicleId;

  /// The first reading on the new scale.
  final OdometerReadingId fromReadingId;

  /// What the old cluster last showed, in metres.
  final int previousM;

  /// What the new cluster shows, in metres.
  final int newM;

  /// The unit both sides were entered in.
  final DistanceUnit odometerUnit;

  /// Why. Three reasons, not four — see [OdometerCorrectionReason].
  final OdometerCorrectionReason reason;

  /// Free text.
  final String? notes;

  /// When the row was written.
  final int createdAtUtcMs;

  /// When it was last changed.
  final int updatedAtUtcMs;

  /// The metres this correction adds to every reading at or after it.
  int get offsetM => previousM - newM;

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    fromReadingId,
    previousM,
    newM,
    odometerUnit,
    reason,
    notes,
    createdAtUtcMs,
    updatedAtUtcMs,
  ];

  @override
  String toString() => 'OdometerCorrection($id, ${reason.wire}, $offsetM m)';
}
