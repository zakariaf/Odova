// The 31-bit int Android speaks, and the 7 days that stop it churning.
//
// SPEC.md §4.2.2 rules 1 and 2.
import 'package:odova/core/time/civil_date.dart';

/// One past the largest id Android accepts.
const int kIdSpace = 1 << 31;

/// SPEC.md §4.2.2 rule 2: a fire time moving less than this is left alone.
///
/// A projection wanders by a day or two every time a reading lands. Without
/// hysteresis, buying fuel cancels and re-adds every pending notification the
/// household has — thirty OS calls for an estimate that moved by an afternoon.
const int kHysteresisDays = 7;

/// A stable id for one notification.
///
/// Folds in the RESOLVED FIRE INSTANT and the BODY, not only [key], and that is
/// the whole design. `getPending()` returns ids and nothing else, so an id
/// derived from the key alone would be unchanged when the delivery hour moves
/// from 09:00 to 14:00 on the same date — the reconcile's cancel loop and its
/// schedule loop would BOTH skip it, and it would fire at the old time forever.
/// Folding the instant in makes an edit produce a new id: old cancelled, new
/// scheduled. Unchanged input still maps to the same id, so a reconcile over
/// unchanged data stays a no-op, which is rule 2's whole point.
///
/// [taken] linear-probes past ids already in use, per rule 1. [seed] is for
/// testing the wrap at the top of the range and should not be passed otherwise.
int deterministicId({
  required String key,
  required String fireAtLocal,
  required String body,
  Set<int> taken = const {},
  int? seed,
}) {
  // `Object.hash` is seeded per isolate in some Dart versions, which would give
  // two devices — and two launches — different ids for the same notification.
  // A written-out FNV-1a is deterministic by construction and costs nothing.
  var id = seed ?? _fnv1a('$key $fireAtLocal $body') % kIdSpace;

  // Bounded by the set itself: a `taken` that somehow held every id would
  // otherwise spin forever inside a pure function on the cold-launch path.
  var probes = 0;
  while (taken.contains(id) && probes < taken.length + 1) {
    // Wraps rather than growing past 31 bits. Running off the top is where an
    // off-by-one becomes a platform exception on one user's phone and nowhere
    // in the test suite.
    id = (id + 1) % kIdSpace;
    probes++;
  }
  return id;
}

/// Whether a pending notification whose time moved from [from] to [to] should
/// be cancelled and re-added.
///
/// ABSOLUTE difference. Subtracting one from the other and comparing against 7
/// silently never reschedules anything that moved EARLIER, and earlier is the
/// direction that matters — it is the one where a late notification means a
/// missed service.
///
/// An unreadable time reschedules. Failing toward doing the work is right here:
/// a row whose stored time cannot be parsed is a row we know nothing about, and
/// leaving it pending is how a notification fires carrying a body from four
/// months ago.
bool shouldReschedule({required String from, required String to}) {
  // A changed TIME OF DAY always reschedules, whatever the date did.
  //
  // The hysteresis exists for a PROJECTION that wanders — §4.2.2 rule 2's
  // "a projection wandering +/-2 days never reaches the threshold". A delivery
  // time moving 09:00 -> 14:00 is not wander, it is the user editing a setting,
  // and comparing only the date made that edit unreachable: `reconcile` saw a
  // 0-day move, skipped it, and every pending notification kept firing at 09:00
  // forever — while `deterministicId` above dutifully computed a new id that
  // was then thrown away. That is precisely the bug its own doc comment claims
  // to prevent, defeated one layer up.
  //
  // A delivery-time change is not one of §6.2's full-rebuild triggers, so there
  // is no other path that would have caught it.
  if (_timeOf(from) != _timeOf(to)) return true;

  final a = _dayOf(from);
  final b = _dayOf(to);
  if (a == null || b == null) return true;
  return a.daysUntil(b).abs() >= kHysteresisDays;
}

/// The `HH:MM` half, or the whole string when there is no `T`.
String _timeOf(String wallClock) {
  final t = wallClock.indexOf('T');
  return t == -1 ? '' : wallClock.substring(t + 1);
}

CivilDate? _dayOf(String wallClock) {
  final t = wallClock.indexOf('T');
  return CivilDate.tryParse(t == -1 ? wallClock : wallClock.substring(0, t));
}

/// FNV-1a over the UTF-16 code units, in 32 bits.
int _fnv1a(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    // The FNV prime, written as shifts so the multiply cannot overflow into
    // Dart's arbitrary-precision integers on the VM and behave differently
    // from the web's doubles.
    hash =
        (hash +
            (hash << 1) +
            (hash << 4) +
            (hash << 7) +
            (hash << 8) +
            (hash << 24)) &
        0xffffffff;
  }
  return hash;
}
