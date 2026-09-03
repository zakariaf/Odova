// Wire values that were withdrawn, and must not come back.
//
// A gate that walks the source tree is a policy test, not a domain unit test.
// It lived in `test/core/l10n/numerals_test.dart` first, which put a
// `flutter_test`-importing helper on the import graph of a file that
// `dart test test/core` runs on the plain VM — and that lane exists precisely
// to prove the domain layer needs no Flutter. It failed with `Dart library
// 'dart:ui' is not available on this platform`, which is the gate working.
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/l10n/numerals.dart';

import '../support/source_tree.dart';

void main() {
  test('the withdrawn NUMERAL name `persian` appears nowhere', () {
    // `persian` is alive as a CALENDAR value and dead as a numeral one, so a
    // blanket grep over lib/ is wrong — it fires on CalmCalendar.persian,
    // which is correct code. The rule is narrower and this states it twice:
    // no CalmNumerals value is spelled that way, and no file that DEFINES a
    // numbering system mentions it.
    expect(
      CalmNumerals.values.map((n) => n.wire),
      isNot(contains('persian')),
    );

    // The word is alive as a CALENDAR value and dead as a numeral one, so
    // neither a blanket grep nor a whole-file allowlist is the rule. The first
    // version skipped any file not mentioning `CalmNumerals`, which reads it
    // backwards — a dead wire value comes back in a settings map, a migration
    // or an import validator working in raw strings, and none of those name
    // the enum. The second allowed it only where `CalmCalendar` appears, and
    // then the settings TABLE arrived, whose `calendar` CHECK legitimately
    // lists it. A fixed window around each occurrence does not work either:
    // in that table the `calendar` and `numerals` columns are adjacent, so any
    // window wide enough to see one sees both.
    //
    // So: read backwards from each occurrence to the NEAREST of the two words.
    // `CHECK (calendar IN ('gregorian', 'persian'))` answers calendar; a
    // `{'numerals': 'persian'}` map answers numerals; `CalmCalendar.persian`
    // answers calendar. It is the enclosing subject, whatever the syntax.
    final subject = RegExp('calendar|numeral', caseSensitive: false);

    final offenders = <String>[];
    for (final file in dartFilesUnder('lib')) {
      final source = sourceWithoutLineComments(file);
      for (final match in RegExp("""['"]persian['"]""").allMatches(source)) {
        final before = source.substring(0, match.start);
        final nearest = subject.allMatches(before).lastOrNull;
        final aboutCalendars =
            nearest != null && nearest.group(0)!.toLowerCase() == 'calendar';
        if (!aboutCalendars) offenders.add('${file.path}:${match.start}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'the literal `persian` outside the calendar enum is a numeral '
          'wire value coming back from the dead',
    );
  });
}
