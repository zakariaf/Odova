// The app has no exchange rate, and never will by accident.
//
// SPEC.md §12 Ground rules and §2. Odova has no network, so any rate it used
// would be invented — and a made-up rate silently rewrites the resale value of
// somebody's service history. A total across currencies groups; it never sums.
//
// This is a grep, and a grep is the right shape here: the thing being forbidden
// is a FUNCTION somebody adds in good faith, three epics from now, because a
// screen wanted one number. It will not look like a mistake in review.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import '../support/source_tree.dart';

/// The names a currency conversion would have to be given.
///
/// Top level, and read by BOTH the gate and its self-test. When they were two
/// copies, editing one left the other asserting against the old patterns.
final _banned = <RegExp, String>{
  RegExp(r'\bexchangeRate\b'): 'an exchange rate',
  RegExp(r'\bfxRate\b|\bFxRate\b'): 'an FX rate',
  RegExp(r'\bconversionRate\b'): 'a conversion rate',
  RegExp(r'\bconvertCurrency\b|\btoCurrency\b'): 'a currency conversion',
  RegExp(r'\bcurrencyRate\b'): 'a currency rate',
};

void main() {
  test('no exchange-rate concept exists anywhere in lib/', () {
    // Named narrowly. `rate` on its own is a real word this app uses — the
    // odometer's daily rate, a consumption rate — so the pattern is the
    // currency sense of it.
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib')) {
      final source = sourceWithoutLineComments(file);
      for (final MapEntry(key: pattern, value: what) in _banned.entries) {
        if (pattern.hasMatch(source)) offenders.add('${file.path}: $what');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'the app has no network, so any rate it used would be invented. '
          'Group with MoneyTotal instead.',
    );
  });

  test('IRT appears nowhere', () {
    // Not an ISO 4217 code. The toman is a DISPLAY divide-by-ten over a stored
    // IRR amount; a non-ISO code in a backup would fail the file's own
    // validation, and the user's history would not import into their next
    // phone.
    final offenders = <String>[];
    for (final file in [...dartFilesUnder('lib'), ...dartFilesUnder('test')]) {
      if (file.path.endsWith('no_currency_conversion_test.dart')) continue;
      if (file.path.endsWith('money_and_units_test.dart')) continue;
      if (RegExp('''['"]IRT['"]''').hasMatch(sourceWithoutLineComments(file))) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('no money signature takes or returns a double', () {
    // SPEC.md §3: money is integer minor units. A `double` in a money
    // signature is where 0.1 + 0.2 gets in, and a fuel log adds hundreds of
    // amounts.
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib/core/money')) {
      final source = sourceWithoutLineComments(file);
      for (final match in RegExp(
        r'^\s*(?:static\s+)?(double|num)\s+\w+|'
        r'\((?:[^)]*\b)(double|num)\s+\w+',
        multiLine: true,
      ).allMatches(source)) {
        offenders.add('${file.path}: ${match.group(0)!.trim()}');
      }
    }
    expect(offenders, isEmpty);
  });

  test('the matchers recognise the shapes they claim to', () {
    // Guard the guard, over the SAME map the gate above uses.
    //
    // This test used to retype the four patterns as literals. Editing the real
    // map then left the self-test green against the old copy — the guard
    // stopped guarding the thing it names, which is the one failure mode a
    // guard-the-guard test exists to prevent.
    for (final offending in [
      'final exchangeRate = 1.1;',
      'Money convertCurrency(Money m)',
      'const fxRate = 0.86;',
      'double conversionRate() => 1;',
      'final currencyRate = read();',
    ]) {
      expect(
        _banned.keys.any((p) => p.hasMatch(offending)),
        isTrue,
        reason: offending,
      );
    }

    // And not on the rates this app legitimately has.
    for (final legitimate in [
      'final metresPerDay = distance ~/ days;',
      'ConsumptionRate rate;',
      'final dailyRate = 41;',
    ]) {
      for (final pattern in _banned.keys) {
        expect(pattern.hasMatch(legitimate), isFalse, reason: legitimate);
      }
    }
  });
}
