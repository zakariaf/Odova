// Counting days with a `Duration` is counting ELAPSED TIME, and a calendar day
// is not 24 hours twice a year.
//
// `CivilDate.daysUntil` documents the failure it was written to end: two dates
// two calendar days apart across a European spring-forward differ by 47 hours,
// and `.inDays` truncates that to 1. `monotonicity.dart` shipped it once and
// `vehicle.edit`'s odometer row shipped it again — "3 days ago" rendered as "2
// days ago" for everyone in Europe on the last Sunday in March, and for
// everyone in North America a fortnight earlier.
//
// The reason this is a GATE rather than a test is in that same dartdoc: **a
// suite running in UTC cannot catch it**, which is what CI does. Removing the
// `.utc` from `daysUntil` and running its own file under `TZ=UTC` passes every
// assertion in it. So the fix is not a better test; it is having no timezone on
// the path at all, and the only way to keep it that way is to refuse the
// spelling.
//
// The SPELLING, and the limit is worth stating: `.inHours ~/ 24` walks
// straight past this. The gate refuses the one that actually shipped, twice,
// which is what a gate can do — it does not refuse the class. A day counted off
// a `Duration` by any route is the same bug.
import 'package:flutter_test/flutter_test.dart';

import '../support/source_gates.dart';

/// `RelativeDateBucket.inDays` is a bucket NAME, not a duration — it selects
/// the `dateInDays` ARB message, and its five siblings are named after their
/// five keys the same way. Everything else that reaches `.inDays` got there
/// through a `Duration`.
const _banned = r'(?<!RelativeDateBucket)\.inDays';

void main() {
  test('no day count in lib/ is measured with a Duration', () {
    expectNoBannedPatterns(const {
      _banned:
          'a calendar day is not 24 hours across a DST change: count days '
          'with CivilDate.daysUntil, which has no timezone on its path',
    });
  });

  test('the matcher recognises the shapes it claims to', () {
    // Guard the guard. CLAUDE.md §4: a gate that has only ever been green is a
    // comment that runs — and this one greps a tree it currently finds nothing
    // in, so without this it has never been observed doing either half of its
    // job.
    final banned = RegExp(_banned);

    // The two spellings that actually shipped, and the shape they shipped in.
    for (final bad in [
      'DateUtils.dateOnly(now).difference(then).inDays',
      '.inDays,',
      'final age = now.difference(reading).inDays;',
      'duration.inDays',
    ]) {
      expect(banned.hasMatch(bad), isTrue, reason: bad);
    }

    // And the one name that must survive it. A carve-out that stopped matching
    // would fail the gate on a file that is doing nothing wrong, and the
    // cheapest way to get green would be to delete the gate.
    for (final good in [
      'RelativeDateBucket.inDays',
      'return (bucket: RelativeDateBucket.inDays, count: days);',
      // The declaration carries no dot at all.
      '  inDays,',
    ]) {
      expect(banned.hasMatch(good), isFalse, reason: good);
    }
  });
}
