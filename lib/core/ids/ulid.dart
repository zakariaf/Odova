// ULID: 48 bits of millisecond timestamp, 80 bits of randomness, Crockford
// base-32.
//
// SPEC.md §3 picks it over UUIDv7 for two properties this app actually uses.
// It is time-sortable AS A PLAIN STRING, so history pagination gets a
// deterministic tiebreak for free and the database index is in insertion
// order. And it is readable: a human opening an export file or a bug report
// can compare two ids by eye, which is why Crockford drops I, L, O and U — the
// characters that get confused with 1 and 0.
import 'dart:math';

import 'package:clock/clock.dart';

/// Crockford's base-32 alphabet: the digits, then the letters minus I, L, O
/// and U.
const crockfordAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// The length of a ULID's text form: 10 characters of time, 16 of randomness.
const ulidLength = 26;

/// Whether [text] is a well-formed ULID body.
///
/// Length and alphabet only. Every 26-character Crockford string is a valid
/// ULID — there is no checksum to verify and inventing one would make ids
/// minted by a future version unreadable by this one.
bool isUlid(String text) {
  if (text.length != ulidLength) return false;
  for (final unit in text.codeUnits) {
    if (!crockfordAlphabet.codeUnits.contains(unit)) return false;
  }
  return true;
}

/// Mints ULIDs from an injected clock and an injected random source.
///
/// Both are arguments, never ambient. `clock.now()` is what lets the due
/// engine's tests fix a date, and one seeded [Random] is what makes a failing
/// test reproducible — `seeded-determinism-and-golden-vectors` names an
/// ambient `Random()` on a generation path as the thing that turns a failure
/// into a story about a machine.
class UlidFactory {
  /// Creates a factory.
  UlidFactory({required this.clock, required this.random});

  /// Where the timestamp comes from.
  final Clock clock;

  /// Where the 80 bits come from.
  final Random random;

  int? _lastMillis;
  late List<int> _lastRandomness;

  /// Mints the next ULID.
  ///
  /// Within a single millisecond the randomness is INCREMENTED rather than
  /// redrawn, so two ids minted in the same millisecond still sort in mint
  /// order. Without that they order by their random bits, and history
  /// pagination returns rows in an order that changes between runs.
  String next() {
    final millis = clock.now().toUtc().millisecondsSinceEpoch;

    if (millis == _lastMillis) {
      _incrementRandomness();
    } else {
      _lastMillis = millis;
      _lastRandomness = [for (var i = 0; i < 16; i++) random.nextInt(32)];
    }

    return _encodeTime(millis) + _encode(_lastRandomness);
  }

  /// Adds one to the 80-bit randomness, base 32, least significant last.
  ///
  /// An overflow past all-Z would need 2^80 ids inside one millisecond, so it
  /// wraps rather than carrying into the timestamp — corrupting the time half
  /// to preserve monotonicity would trade a impossible problem for a real one.
  void _incrementRandomness() {
    for (var i = _lastRandomness.length - 1; i >= 0; i--) {
      if (_lastRandomness[i] < 31) {
        _lastRandomness[i]++;
        return;
      }
      _lastRandomness[i] = 0;
    }
  }

  /// The 48-bit timestamp as ten Crockford characters, most significant first.
  static String _encodeTime(int millis) {
    final digits = List<int>.filled(10, 0);
    var remaining = millis;
    for (var i = 9; i >= 0; i--) {
      digits[i] = remaining % 32;
      remaining ~/= 32;
    }
    return _encode(digits);
  }

  static String _encode(List<int> digits) =>
      String.fromCharCodes(digits.map((d) => crockfordAlphabet.codeUnitAt(d)));
}
