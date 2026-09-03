// The two decisions in this epic that are not engineering decisions.
//
// SPEC.md §18 keeps 26 genuinely unsettled questions, and items 8 and 9 are
// the two this epic had to answer in order to compile. A third came out of the
// work itself and has no §18 number yet: the Sorani month names. All three are
// answered — the app does something specific today — but the answers are
// PLACEHOLDERS awaiting a native Sorani reader, and this file is what makes
// that visible.
//
// Failing one of these tests is how a reviewer's answer lands: change one line
// of product code, change one line here, and the reason is in the diff.
import 'dart:io';

import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:test/test.dart';

void main() {
  test('SPEC §18.8 — ckb defaults to extarab, awaiting a native ckb-IQ '
      'reader', () {
    // The question: Kurdish Sorani numerals — extarab `۰۱۲۳` or arab `٠١٢٣`?
    //
    // Today: extarab, matching Persian, because Sorani shares Persian's
    // letterforms and the app already borrows Persian for the framework
    // chrome and the number symbols.
    //
    // The alternative: arab, which is CLDR's own default for ckb and is common
    // in Iraqi Kurdistan print.
    //
    // Cost if wrong: a Sorani reader in Iraq sees Persian digit shapes where
    // they expect Arabic ones. One settings row fixes it for them.
    expect(
      resolveNumerals(CalmNumerals.auto, 'ckb-IQ'),
      CalmNumerals.extendedArabicIndic,
    );
    expect(
      resolveNumerals(CalmNumerals.auto, 'ckb-IR'),
      CalmNumerals.extendedArabicIndic,
    );
  });

  test('SPEC §18.9 — ckb-IR defaults to Jalali, awaiting one native check', () {
    // The question: should `ckb-IR` default to the Jalali calendar, or do
    // Sorani speakers in Iran expect Gregorian in a KURDISH-language app?
    //
    // Today: Jalali, because Iran runs on it and a date that disagrees with
    // every other date the reader sees that day is worse than an unexpected
    // one.
    //
    // The alternative is a question about identity rather than about
    // calendars, and only a native reader can settle it.
    //
    // Cost if wrong: a Sorani reader in Iran opens the app on a calendar they
    // did not expect. One settings row fixes it.
    expect(resolveCalendar(null, 'ckb-IR'), CalmCalendar.persian);
    expect(resolveCalendar(null, 'ckb-IQ'), CalmCalendar.gregorian);
  });

  test('the Sorani month names are a placeholder too, with no §18 number', () {
    // The question, raised by this epic rather than by SPEC.md: are the
    // Rojhelat (Iranian Kurdish) Jalali month names the right set for every
    // Sorani reader, or does a reader in Iraq expect something else?
    //
    // Today: the Rojhelat set, because it is the one a Jalali-calendar Sorani
    // user reads, and `ckb-IR` is the tag that gets the Jalali calendar at all.
    //
    // Cost if wrong: a Sorani reader sees an unfamiliar month name. Unlike the
    // other two, NO settings row fixes this one — which is why it is listed
    // here rather than treated as settled, and why it wants an answer before
    // launch rather than after.
    expect(kurdishJalaliMonthNames, hasLength(12));
    expect(
      projectDate(
        DateTime.utc(2026, 10, 14),
        CalmCalendar.persian,
        'ckb-IR',
      ).monthName,
      'ڕەزبەر',
    );
    // Not the Persian words, which is the mistake this table exists to undo.
    expect(
      kurdishJalaliMonthNames.toSet().intersection(jalaliMonthNames.toSet()),
      isEmpty,
    );
  });

  test('neither default is load-bearing: one settings row overrides each', () {
    // The reason a placeholder answer is acceptable at all. A user who
    // disagrees is one row away from the other behaviour, so the wrong default
    // is an annoyance rather than a wall.
    expect(
      resolveNumerals(CalmNumerals.arabicIndic, 'ckb-IQ'),
      CalmNumerals.arabicIndic,
    );
    expect(
      resolveCalendar(CalmCalendar.gregorian, 'ckb-IR'),
      CalmCalendar.gregorian,
    );
  });

  test('both questions are named by number in the code that answers them', () {
    // So the next reader finds the question at the line that implements it,
    // rather than in a spec section nobody opened.
    expect(
      File('lib/core/l10n/numerals.dart').readAsStringSync(),
      contains('SPEC.md §18 question 8'),
    );
    expect(
      File('lib/core/l10n/calendar.dart').readAsStringSync(),
      contains('SPEC.md §18 question 9'),
    );
    // The third has no number, so it is pinned by the §18 reference that says
    // it is unsettled.
    expect(
      File('lib/core/l10n/calendar.dart').readAsStringSync(),
      contains('SPEC.md §18 flags Sorani quality'),
    );
  });
}
