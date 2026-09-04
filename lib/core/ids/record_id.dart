// `<prefix>_<ULID>`: the id in the database, in the export file and in every
// notification payload.
//
// SPEC.md §3 Identity. Nine prefixes, one per entity, and the type system
// carries which is which — so passing a fill-up id where a vehicle id is
// expected is a compile error rather than a foreign key that finds nothing at
// runtime. The two that get confused are worth naming: the service ITEM (the
// reminder) is `rem_` and the service RECORD is `srv_`. `svc_` is nobody's.
import 'package:meta/meta.dart';
import 'package:odova/core/ids/ulid.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/value_equality.dart';

/// The nine entities that own an id, and the prefix each one writes.
enum RecordIdKind {
  /// A vehicle.
  vehicle('veh_'),

  /// A service item — the thing that becomes a reminder. `rem_`, not `svc_`.
  serviceItem('rem_'),

  /// A service record: the work that was actually done.
  serviceRecord('srv_'),

  /// One line of a service record.
  serviceLine('lin_'),

  /// A fill-up.
  fillUp('fil_'),

  /// An expense.
  expense('exp_'),

  /// A trip.
  trip('trp_'),

  /// An odometer reading.
  odometerReading('odo_'),

  /// An odometer correction.
  odometerCorrection('cor_');

  const RecordIdKind(this.prefix);

  /// The four characters this kind's ids start with, trailing `_` included.
  final String prefix;
}

/// Why an id could not be read.
sealed class IdFailure extends Failure with ValueEquality {
  const IdFailure();
}

/// The text does not have the shape `<prefix>_<26 Crockford characters>`.
final class MalformedId extends IdFailure {
  /// Creates the failure.
  const MalformedId(this.offered);

  /// The text that was offered, kept for diagnostics.
  ///
  /// A typed param, not a message: it is the INPUT, and the presentation edge
  /// decides whether and how to show it.
  final String offered;

  @override
  String get code => 'malformed_id';

  @override
  List<Object?> get props => [offered];
}

/// The id is well-formed, but belongs to a different entity.
final class WrongPrefix extends IdFailure {
  /// Creates the failure.
  const WrongPrefix({required this.expected, required this.actual});

  /// The kind the caller asked for.
  final RecordIdKind expected;

  /// The kind the text carries.
  final RecordIdKind actual;

  @override
  String get code => 'wrong_prefix';

  @override
  List<Object?> get props => [expected, actual];
}

/// An entity's identity.
///
/// Sealed over the nine kinds. Two ids are equal when their text is equal, so
/// a repository can key a map on one and a test can assert on the value rather
/// than on the runtime type.
@immutable
sealed class RecordId {
  const RecordId(this.body);

  /// The 26-character ULID, without the prefix.
  final String body;

  /// Which entity this id belongs to.
  RecordIdKind get kind;

  /// Reads any of the nine, deciding the kind from the prefix.
  ///
  /// Used where the entity is not known statically — an import file, a
  /// notification payload. Where it IS known, prefer the type's own `parse`,
  /// which refuses another entity's id.
  static Result<RecordId, IdFailure> parse(String text) {
    for (final kind in RecordIdKind.values) {
      if (!text.startsWith(kind.prefix)) continue;
      final body = text.substring(kind.prefix.length);
      if (!isUlid(body)) return Err(MalformedId(text));
      return Ok(_construct(kind, body));
    }
    return Err(MalformedId(text));
  }

  static RecordId _construct(RecordIdKind kind, String body) => switch (kind) {
    RecordIdKind.vehicle => VehicleId._(body),
    RecordIdKind.serviceItem => ServiceItemId._(body),
    RecordIdKind.serviceRecord => ServiceRecordId._(body),
    RecordIdKind.serviceLine => ServiceLineId._(body),
    RecordIdKind.fillUp => FillUpId._(body),
    RecordIdKind.expense => ExpenseId._(body),
    RecordIdKind.trip => TripId._(body),
    RecordIdKind.odometerReading => OdometerReadingId._(body),
    RecordIdKind.odometerCorrection => OdometerCorrectionId._(body),
  };

  /// Reads [text] as [kind], refusing another entity's id.
  static Result<RecordId, IdFailure> _parseAs(String text, RecordIdKind kind) {
    final parsed = parse(text);
    return switch (parsed) {
      Err(:final failure) => Err(failure),
      Ok(:final value) when value.kind != kind => Err(
        WrongPrefix(expected: kind, actual: value.kind),
      ),
      Ok(:final value) => Ok(value),
    };
  }

  // Hand-rolled rather than `ValueEquality`, deliberately: that mixin compares
  // `runtimeType` first, and a `RecordId` returned by the kind-agnostic
  // `RecordId.parse` must equal the `VehicleId` a caller minted. The kind IS
  // the type here, and comparing it directly is what makes the two paths agree.
  @override
  bool operator ==(Object other) =>
      other is RecordId && other.kind == kind && other.body == body;

  @override
  int get hashCode => Object.hash(kind, body);

  @override
  String toString() => '${kind.prefix}$body';
}

/// A vehicle's id.
final class VehicleId extends RecordId {
  const VehicleId._(super.body);

  /// Mints a new one.
  factory VehicleId.mint(UlidFactory factory) => VehicleId._(factory.next());

  /// Reads [text], refusing another entity's id.
  static Result<VehicleId, IdFailure> parse(String text) =>
      _cast(RecordId._parseAs(text, RecordIdKind.vehicle));

  /// Reads [text], or null.
  static VehicleId? tryParse(String text) =>
      parse(text).fold((v) => v, (_) => null);

  @override
  RecordIdKind get kind => RecordIdKind.vehicle;
}

/// A service item's id. `rem_`, because it is the thing that reminds.
final class ServiceItemId extends RecordId {
  const ServiceItemId._(super.body);

  /// Mints a new one.
  factory ServiceItemId.mint(UlidFactory factory) =>
      ServiceItemId._(factory.next());

  /// Reads [text], refusing another entity's id.
  static Result<ServiceItemId, IdFailure> parse(String text) =>
      _cast(RecordId._parseAs(text, RecordIdKind.serviceItem));

  /// Reads [text], or null.
  static ServiceItemId? tryParse(String text) =>
      parse(text).fold((v) => v, (_) => null);

  @override
  RecordIdKind get kind => RecordIdKind.serviceItem;
}

/// A service record's id.
final class ServiceRecordId extends RecordId {
  const ServiceRecordId._(super.body);

  /// Mints a new one.
  factory ServiceRecordId.mint(UlidFactory factory) =>
      ServiceRecordId._(factory.next());

  /// Reads [text], refusing another entity's id.
  static Result<ServiceRecordId, IdFailure> parse(String text) =>
      _cast(RecordId._parseAs(text, RecordIdKind.serviceRecord));

  /// Reads [text], or null.
  static ServiceRecordId? tryParse(String text) =>
      parse(text).fold((v) => v, (_) => null);

  @override
  RecordIdKind get kind => RecordIdKind.serviceRecord;
}

/// A service line's id.
final class ServiceLineId extends RecordId {
  const ServiceLineId._(super.body);

  /// Mints a new one.
  factory ServiceLineId.mint(UlidFactory factory) =>
      ServiceLineId._(factory.next());

  /// Reads [text], refusing another entity's id.
  static Result<ServiceLineId, IdFailure> parse(String text) =>
      _cast(RecordId._parseAs(text, RecordIdKind.serviceLine));

  /// Reads [text], or null.
  static ServiceLineId? tryParse(String text) =>
      parse(text).fold((v) => v, (_) => null);

  @override
  RecordIdKind get kind => RecordIdKind.serviceLine;
}

/// A fill-up's id.
final class FillUpId extends RecordId {
  const FillUpId._(super.body);

  /// Mints a new one.
  factory FillUpId.mint(UlidFactory factory) => FillUpId._(factory.next());

  /// Reads [text], refusing another entity's id.
  static Result<FillUpId, IdFailure> parse(String text) =>
      _cast(RecordId._parseAs(text, RecordIdKind.fillUp));

  /// Reads [text], or null.
  static FillUpId? tryParse(String text) =>
      parse(text).fold((v) => v, (_) => null);

  @override
  RecordIdKind get kind => RecordIdKind.fillUp;
}

/// An expense's id.
final class ExpenseId extends RecordId {
  const ExpenseId._(super.body);

  /// Mints a new one.
  factory ExpenseId.mint(UlidFactory factory) => ExpenseId._(factory.next());

  /// Reads [text], refusing another entity's id.
  static Result<ExpenseId, IdFailure> parse(String text) =>
      _cast(RecordId._parseAs(text, RecordIdKind.expense));

  /// Reads [text], or null.
  static ExpenseId? tryParse(String text) =>
      parse(text).fold((v) => v, (_) => null);

  @override
  RecordIdKind get kind => RecordIdKind.expense;
}

/// A trip's id.
final class TripId extends RecordId {
  const TripId._(super.body);

  /// Mints a new one.
  factory TripId.mint(UlidFactory factory) => TripId._(factory.next());

  /// Reads [text], refusing another entity's id.
  static Result<TripId, IdFailure> parse(String text) =>
      _cast(RecordId._parseAs(text, RecordIdKind.trip));

  /// Reads [text], or null.
  static TripId? tryParse(String text) =>
      parse(text).fold((v) => v, (_) => null);

  @override
  RecordIdKind get kind => RecordIdKind.trip;
}

/// An odometer reading's id.
final class OdometerReadingId extends RecordId {
  const OdometerReadingId._(super.body);

  /// Mints a new one.
  factory OdometerReadingId.mint(UlidFactory factory) =>
      OdometerReadingId._(factory.next());

  /// Reads [text], refusing another entity's id.
  static Result<OdometerReadingId, IdFailure> parse(String text) =>
      _cast(RecordId._parseAs(text, RecordIdKind.odometerReading));

  /// Reads [text], or null.
  static OdometerReadingId? tryParse(String text) =>
      parse(text).fold((v) => v, (_) => null);

  @override
  RecordIdKind get kind => RecordIdKind.odometerReading;
}

/// An odometer correction's id.
final class OdometerCorrectionId extends RecordId {
  const OdometerCorrectionId._(super.body);

  /// Mints a new one.
  factory OdometerCorrectionId.mint(UlidFactory factory) =>
      OdometerCorrectionId._(factory.next());

  /// Reads [text], refusing another entity's id.
  static Result<OdometerCorrectionId, IdFailure> parse(String text) =>
      _cast(RecordId._parseAs(text, RecordIdKind.odometerCorrection));

  /// Reads [text], or null.
  static OdometerCorrectionId? tryParse(String text) =>
      parse(text).fold((v) => v, (_) => null);

  @override
  RecordIdKind get kind => RecordIdKind.odometerCorrection;
}

/// Narrows a `Result<RecordId, …>` whose kind has already been checked.
///
/// The cast is safe because `_parseAs` returns `Err` for every kind but the
/// one asked for, and it is here rather than repeated nine times.
Result<T, IdFailure> _cast<T extends RecordId>(
  Result<RecordId, IdFailure> result,
) => switch (result) {
  Ok(:final value) => Ok(value as T),
  Err(:final failure) => Err(failure),
};
