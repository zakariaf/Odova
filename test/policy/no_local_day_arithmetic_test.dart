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
import 'package:flutter_test/flutter_test.dart';

import '../support/source_gates.dart';

void main() {
  test('no day count in lib/ is measured with a Duration', () {
    expectNoBannedPatterns(const {
      // `RelativeDateBucket.inDays` is a bucket NAME, not a duration, and its
      // declaration carries no dot. Everything else that reaches `.inDays` got
      // there through `DateTime.difference`.
      r'(?<!RelativeDateBucket)\.inDays':
          'a calendar day is not 24 hours across a DST change: count days '
          'with CivilDate.daysUntil, which has no timezone on its path',
    });
  });
}
