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

    // The filter is on the LEGITIMATE owner, not on the suspect. The first
    // version skipped any file that did not mention `CalmNumerals`, which
    // reads the rule backwards: the place a dead wire value comes back is a
    // settings map, a migration or an import validator working in raw
    // strings, and none of those need name the enum. EPIC-05 is full of
    // exactly that code.
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib')) {
      final source = sourceWithoutLineComments(file);
      if (!RegExp('''['"]persian['"]''').hasMatch(source)) continue;
      // `CalmCalendar` is the one thing in the app allowed to spell it.
      if (!source.contains('CalmCalendar')) offenders.add(file.path);
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
