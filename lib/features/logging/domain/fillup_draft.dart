// One visit to a pump or a charger, as the form holds it.
//
// SPEC.md §10 `log.fillup`: 2–6× a month per vehicle, ten times more often
// than anything else, which is why it is the default segment and why every
// rule here is about getting out of the user's way.
//
// The two rules worth stating up front:
//
//   1. **Two of the three** money/volume fields must carry a value. The trio's
//      arithmetic lives in `price_trio.dart`; what lives here is the refusal.
//   2. **Over tank capacity is a WARNING, never a refusal.** The app does not
//      know the tank was replaced, the vehicle is towing a jerrycan, or the
//      capacity in its own database came from a spec sheet for a different
//      trim. Refusing the save would lose a real fill-up to a number the user
//      never entered.
import 'package:meta/meta.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/features/logging/domain/decimal_input.dart';
import 'package:odova/features/logging/domain/price_trio.dart';

/// What is wrong with the draft, in the order §10's form reads.
enum FillUpProblem {
  /// Fewer than two of the three money/volume fields carry a value.
  trioIncomplete,

  /// Quantity is zero or negative. Zero fuel is not a fill-up.
  quantityNotPositive,

  /// Price per unit is below zero.
  priceNegative,

  /// Total is below zero. Zero is legal — a free fill-up is 0.
  totalNegative,

  /// The date is after today.
  futureDate,
}

/// What is odd about the draft but does not stop it being saved.
enum FillUpWarning {
  /// More fuel than the tank holds, by more than the tolerance.
  overTank,
}

/// How far over the tank's stated capacity is still not worth mentioning.
///
/// SPEC.md §10 sets it at 1.15. A tank's usable volume exceeds its nominal one
/// — filler neck included — and a capacity figure that came from a spec sheet
/// is not a measurement of THIS vehicle.
const double kTankCapacityTolerance = 1.15;

/// The fill-up form's state, as one immutable value.
@immutable
class FillUpDraft {
  /// Creates a draft.
  const FillUpDraft({
    this.trio = const PriceTrio(),
    this.isFullTank = true,
    this.occurredOn = '',
    this.station = '',
    this.grade = '',
    this.notes = '',
    this.chainBroken = false,
  });

  /// Quantity, price per unit and total, and which of them is computed.
  final PriceTrio trio;

  /// §10's prefill is **Filled it up**; a part fill is a deliberate change.
  final bool isFullTank;

  /// The date of the fill-up.
  final String occurredOn;

  /// Where it was bought. Never auto-filled — §10 offers recents as chips.
  final String station;

  /// The grade, as typed.
  final String grade;

  /// Free text.
  final String notes;

  /// "I missed logging a fill-up before this."
  ///
  /// §10 puts it under More with its own explanation, because it silently
  /// changes what the next full tank means: consumption starts fresh from here
  /// rather than spanning a gap the app cannot see.
  final bool chainBroken;

  /// Whether the user has put anything into this draft.
  ///
  /// §10's dirty rule is "any field differs from its prefill". `isFullTank` is
  /// the one field with a non-empty prefill, so it compares rather than tests
  /// for content.
  bool get isDirty =>
      trio.isDirty ||
      !isFullTank ||
      chainBroken ||
      station.trim().isNotEmpty ||
      grade.trim().isNotEmpty ||
      notes.trim().isNotEmpty;

  /// Everything that stops this being saved, in §10's field order.
  ///
  /// [today] and [tankCapacity] are passed IN rather than read: a draft that
  /// reads a clock answers differently depending on when it is asked, and one
  /// that reads a vehicle needs a repository to be a value object.
  List<FillUpProblem> problems({String? today, Volume? tankCapacity}) {
    final problems = <FillUpProblem>[];

    if (_filled.length < 2) problems.add(FillUpProblem.trioIncomplete);

    final quantity = _valueOf(TrioField.quantity);
    if (quantity != null && quantity <= 0) {
      problems.add(FillUpProblem.quantityNotPositive);
    }
    final price = _valueOf(TrioField.pricePerUnit);
    if (price != null && price < 0) problems.add(FillUpProblem.priceNegative);
    final total = _valueOf(TrioField.total);
    if (total != null && total < 0) problems.add(FillUpProblem.totalNegative);

    final on = CivilDate.tryParse(occurredOn);
    final now = CivilDate.tryParse(today ?? '');
    if (on != null && now != null && on > now) {
      problems.add(FillUpProblem.futureDate);
    }
    return problems;
  }

  /// Amber lines that do not stop the save.
  ///
  /// Empty when [tankCapacity] is null, and that is the point: SPEC.md §2 says
  /// the app never guesses in a way that looks like fact, and "more than your
  /// tank holds" is a claim about a tank whose size it does not know.
  List<FillUpWarning> warnings({Volume? tankCapacity}) {
    if (tankCapacity == null) return const [];
    final millilitres = trio.quantityMillilitres;
    if (millilitres == null) return const [];
    // Compared in whole millilitres, so the tolerance is exact arithmetic and
    // not a float that puts one fill-up either side of the line by rounding.
    final ceiling = (tankCapacity.millilitres * kTankCapacityTolerance).round();
    return millilitres > ceiling ? const [FillUpWarning.overTank] : const [];
  }

  /// The trio fields that carry a usable number.
  Set<TrioField> get _filled => {
    for (final field in TrioField.values)
      if (_valueOf(field) != null) field,
  };

  double? _valueOf(TrioField field) {
    final text = switch (field) {
      TrioField.quantity => trio.quantity,
      TrioField.pricePerUnit => trio.pricePerUnit,
      TrioField.total => trio.total,
    };
    final read = parseDecimal(
      text,
      groupingSeparator: trio.groupingSeparator,
    );
    return read is DecimalOk ? read.value : null;
  }

  /// A copy with [trio] replaced.
  FillUpDraft withTrio(PriceTrio next) => _copy(trio: next);

  /// A copy with the full/part switch set.
  FillUpDraft withFullTank({required bool full}) => _copy(isFullTank: full);

  /// A copy with the station replaced.
  FillUpDraft withStation(String value) => _copy(station: value);

  /// A copy with the grade replaced.
  FillUpDraft withGrade(String value) => _copy(grade: value);

  /// A copy with the notes replaced.
  FillUpDraft withNotes(String value) => _copy(notes: value);

  /// A copy with the broken-chain checkbox set.
  FillUpDraft withChainBroken({required bool broken}) =>
      _copy(chainBroken: broken);

  FillUpDraft _copy({
    PriceTrio? trio,
    bool? isFullTank,
    String? occurredOn,
    String? station,
    String? grade,
    String? notes,
    bool? chainBroken,
  }) => FillUpDraft(
    trio: trio ?? this.trio,
    isFullTank: isFullTank ?? this.isFullTank,
    occurredOn: occurredOn ?? this.occurredOn,
    station: station ?? this.station,
    grade: grade ?? this.grade,
    notes: notes ?? this.notes,
    chainBroken: chainBroken ?? this.chainBroken,
  );
}
