// Why there is no number.
//
// SPEC.md §3 Fuel maths (hard cases), §12 Ground rules, CLAUDE.md rule 7: the
// app never guesses in a way that looks like fact, and "a wrong consumption
// number is worse than none, because the user will believe it".
//
// Each reason is a typed value with a stable `code` and its own parameters, and
// NEVER a user-facing string — the sentence is localised from the code at the
// presentation edge, because this app ships in six languages of which three are
// right-to-left.
//
// Sealed, so a `switch` needs no `default:` and a new reason is a compile error
// at every call site rather than a case that silently renders the generic one.
import 'package:meta/meta.dart';
import 'package:odova/core/value_equality.dart';

/// Why a consumption figure could not be computed.
@immutable
sealed class ConsumptionUnavailable with ValueEquality {
  const ConsumptionUnavailable();

  /// A stable identifier. The UI localises the sentence from this.
  String get code;

  /// The fills the user should be shown, where there are any.
  ///
  /// Empty rather than null when the reason is not about specific rows, so a
  /// caller can always iterate.
  List<String> get flaggedFillUpIds => const [];
}

/// There is only one fill so far.
///
/// SPEC.md §3: "your first figure arrives at your next full fill" beats a
/// number derived from an unknown starting tank level. The very first fill
/// opens a segment and produces nothing, ever.
final class FirstFill extends ConsumptionUnavailable {
  /// Creates the reason.
  const FirstFill();

  @override
  String get code => 'first_fill';

  @override
  List<Object?> get props => const [];
}

/// A fill is marked `chain_broken`: the user missed one.
///
/// The segment that would have closed there is DISCARDED — not averaged, not
/// pro-rated. Averaging across a gap produces a figure that looks like a
/// measurement and is not one.
final class ChainBroken extends ConsumptionUnavailable {
  /// Creates the reason.
  const ChainBroken(this.atFillUpId);

  /// The fill that broke the chain.
  final String atFillUpId;

  @override
  String get code => 'chain_broken';

  @override
  List<String> get flaggedFillUpIds => [atFillUpId];

  @override
  List<Object?> get props => [atFillUpId];
}

/// A fill has no odometer reading.
///
/// Treated as a chain break, with the same consequence: without the reading
/// there is no distance, and a distance guessed from the neighbours is an
/// invention.
final class MissingOdometer extends ConsumptionUnavailable {
  /// Creates the reason.
  const MissingOdometer(this.atFillUpId);

  /// The fill with no reading.
  final String atFillUpId;

  @override
  String get code => 'missing_odometer';

  @override
  List<String> get flaggedFillUpIds => [atFillUpId];

  @override
  List<Object?> get props => [atFillUpId];
}

/// Two fills at the same odometer, or a distance that runs backwards.
///
/// A data error, and the segment is discarded with BOTH fills flagged — never
/// a 0 L/100 km, which is a number the user would believe.
final class NonPositiveDistance extends ConsumptionUnavailable {
  /// Creates the reason.
  const NonPositiveDistance({
    required this.fromFillUpId,
    required this.toFillUpId,
  });

  /// The fill that opened the segment.
  final String fromFillUpId;

  /// The fill that would have closed it.
  final String toFillUpId;

  @override
  String get code => 'non_positive_distance';

  @override
  List<String> get flaggedFillUpIds => [fromFillUpId, toFillUpId];

  @override
  List<Object?> get props => [fromFillUpId, toFillUpId];
}

/// An EV whose charges are never marked full.
///
/// SPEC.md §3: the app shows cost per distance only and SAYS SO; it does not
/// invent an energy figure from partial charges. "Full" for an EV means the
/// driver's usual charge target, which only they can say.
final class NoFullCharge extends ConsumptionUnavailable {
  /// Creates the reason.
  const NoFullCharge();

  @override
  String get code => 'no_full_charge';

  @override
  List<Object?> get props => const [];
}

/// There are not enough segments for this particular figure.
///
/// Carries how many there are and how many are needed, because the UI's
/// sentence is "three more full fills" and not "not enough data".
final class InsufficientData extends ConsumptionUnavailable {
  /// Creates the reason.
  const InsufficientData({required this.have, required this.need});

  /// How many valid segments exist.
  final int have;

  /// How many this figure needs.
  final int need;

  @override
  String get code => 'insufficient_data';

  @override
  List<Object?> get props => [have, need];
}

/// The amounts span more than one currency.
///
/// SPEC.md §12: money never mixes, and the app has no rate to mix it with.
final class MixedCurrency extends ConsumptionUnavailable {
  /// Creates the reason.
  const MixedCurrency(this.currencyCodes);

  /// Which currencies were present, sorted.
  final List<String> currencyCodes;

  @override
  String get code => 'mixed_currency';

  @override
  List<Object?> get props => currencyCodes;
}
