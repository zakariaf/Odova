// A typed odometer reading, and the one thing that can be wrong with it.
//
// Two screens collect this: `firstrun.vehicle`, where it is the only thing the
// user has to type, and `vehicle.edit` in create mode, where SPEC.md §8 turns
// the read-only odometer row into an input. Both need the same three answers —
// does it parse, is it plausible, what is it in metres — and the second one is
// where the rule that is easiest to get wrong lives: the three-million-
// kilometre warning is a WARNING and never a block.
//
// Pure Dart, no Flutter import, so it tests in milliseconds.
import 'package:meta/meta.dart';
import 'package:odova/core/l10n/numeric_input.dart';
import 'package:odova/core/units/distance.dart';

/// What is wrong with a typed odometer, or nothing.
enum OdometerProblem {
  /// Nothing was typed. SPEC.md §8: "Enter the number on your dash."
  empty,

  /// It cannot be read as a whole number. "That doesn't look like a number.
  /// Digits only." A fraction lands here too: an odometer is an integer, and
  /// German's `1,234` means one-point-two-three-four, which is not a reading.
  notANumber,

  /// Above three million kilometres.
  ///
  /// A WARNING and never a block — SPEC.md §8 pairs it with "Use it anyway".
  /// The app doubts the number; it does not refuse it, because the one thing
  /// worse than a wrong odometer is a user who cannot enter their real one.
  /// [OdometerEntry.usable] is what a Save button asks, and it says yes here.
  implausible,
}

/// The three million kilometres beyond which a reading is doubted.
const kImplausibleOdometre = Distance(3000000000);

/// What the user typed into an odometer field, and what it means.
@immutable
class OdometerEntry {
  /// Creates an entry.
  const OdometerEntry({
    required this.unit,
    required this.groupingSeparator,
    this.text = '',
    this.warningAccepted = false,
  });

  /// The unit the field is showing, and therefore the unit [text] is in.
  final DistanceUnit unit;

  /// The grouping separator of the locale the user is typing in.
  ///
  /// Carried rather than looked up, because a value object that reads a locale
  /// is a value object that answers differently in Tehran and Toronto —
  /// SPEC.md §3's rule about hidden inputs, which `lib/l10n/money_format.dart`
  /// learned the hard way.
  final String groupingSeparator;

  /// Exactly what the user typed, unnormalised.
  ///
  /// The raw string, not a number: the field echoes back what was typed until
  /// blur, and SPEC.md §5 says an Iranian user typing `۱۸۷۴۱۲` sees their own
  /// digits while they type them.
  final String text;

  /// Whether "Use it anyway" has been pressed on the implausible warning.
  final bool warningAccepted;

  /// What is wrong with [text], or null.
  ///
  /// [OdometerProblem.implausible] disappears once the warning is accepted,
  /// because at that point nothing is wrong with it any more.
  OdometerProblem? get problem {
    final read = metres;
    if (read == null) {
      return text.trim().isEmpty
          ? OdometerProblem.empty
          : OdometerProblem.notANumber;
    }
    if (read > kImplausibleOdometre.metres && !warningAccepted) {
      return OdometerProblem.implausible;
    }
    return null;
  }

  /// The reading in metres, or null when it does not parse to a whole number.
  int? get metres {
    final read = normalizeNumericInput(
      text,
      groupingSeparator: groupingSeparator,
    );
    if (read is! NumericInputOk) return null;
    // An odometer is a whole number of km or miles. A fractional reading is
    // not a dash reading, it is a decimal separator read the other way round.
    if (read.value < 0 || read.value != read.value.roundToDouble()) return null;
    final whole = read.value.round();
    return unit == DistanceUnit.mi
        ? Distance.fromMiles(whole).metres
        : Distance.fromKm(whole).metres;
  }

  /// Whether this reading may be saved.
  ///
  /// It asks whether the field holds a READING, not whether the app likes it.
  /// So it is not `problem == null`: that spelling quietly promotes
  /// [OdometerProblem.implausible] into a block, and SPEC.md §8 says the
  /// opposite in as many words — "a warning with a 'Use it anyway' affordance,
  /// never a block". A truck that really has done three million kilometres
  /// could not be entered without first arguing with the app, and "never a
  /// block" is not "one extra tap".
  bool get usable => metres != null;

  /// A copy with the given changes.
  ///
  /// New [text] clears [warningAccepted] and the caller does not get to keep
  /// it: a new number is a new question, and "Use it anyway" applied to
  /// 30,000,001 must not silently apply to the 300,000,001 typed after it.
  OdometerEntry copyWith({
    DistanceUnit? unit,
    String? text,
    bool? warningAccepted,
  }) => OdometerEntry(
    unit: unit ?? this.unit,
    groupingSeparator: groupingSeparator,
    text: text ?? this.text,
    warningAccepted: text == null && (warningAccepted ?? false),
  );
}
