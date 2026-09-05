// Every sentence Home says, and the rule that no card says more than the data
// supports.
//
// SPEC.md §9 *The card* and *Marking an estimate as an estimate*. The hard one
// is the last row of that table: at `confidence = default` there is NO date and
// NO figure — the card asks for a reading instead. A screen that guesses and
// looks certain is the failure §1 rule 3 exists to prevent.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/home/ui/home_copy.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

import '../../../support/source_tree.dart';

DueAssessment _assessment({
  required DueState state,
  required DueDriver driver,
  RateConfidence confidence = RateConfidence.measured,
  int? remainingMetres,
  int? remainingDays,
}) => DueAssessment(
  state: state,
  driver: driver,
  confidence: confidence,
  progress: 1,
  remainingMetres: remainingMetres,
  remainingDays: remainingDays,
);

void main() {
  late AppLocalizations en;

  setUpAll(() async {
    await initializeDateFormatting();
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  String status(DueAssessment a, {String tag = 'en-GB'}) =>
      stripBidi(homeStatusLine(en, tag, a, DistanceUnit.km));

  test('overdue by distance reads a positive overshoot', () {
    // Never "in −1,400 km". §9: overdue "uses its own positive string".
    expect(
      status(
        _assessment(
          state: DueState.overdue,
          driver: DueDriver.distance,
          remainingMetres: -const Distance.fromKm(1400).metres,
        ),
      ),
      'Overdue by 1,400 km',
    );
  });

  test('overdue by time reads a positive overshoot', () {
    expect(
      status(
        _assessment(
          state: DueState.overdue,
          driver: DueDriver.time,
          remainingDays: -21,
        ),
      ),
      'Overdue by 3 weeks',
    );
  });

  test('overdue on both axes leads with the distance', () {
    // §9: "distance phrasing wins when both axes are overdue, because a
    // kilometre figure is checkable against the dash and a date is not."
    expect(
      status(
        _assessment(
          state: DueState.overdue,
          driver: DueDriver.both,
          remainingMetres: -const Distance.fromKm(1400).metres,
          remainingDays: -21,
        ),
      ),
      'Overdue by 1,400 km and 3 weeks',
    );
  });

  test('due reads Due now, with no number', () {
    expect(
      status(_assessment(state: DueState.due, driver: DueDriver.time)),
      'Due now',
    );
  });

  test('dueSoon by time uses the bucketed relative formatter', () {
    String soon(int days) => status(
      _assessment(
        state: DueState.dueSoon,
        driver: DueDriver.time,
        remainingDays: days,
      ),
    );

    // Every bucket boundary §5 defines, from the same function the past side
    // uses — one vocabulary, both directions.
    expect(soon(0), 'Today');
    expect(soon(1), 'Tomorrow');
    expect(soon(5), 'in 5 days');
    expect(soon(13), 'in 13 days');
    expect(soon(14), 'in about 2 weeks');
    expect(soon(55), 'in about 8 weeks');
    expect(soon(56), 'in about 2 months');
  });

  test('dueSoon by distance at default confidence asks for a reading', () {
    // The row of §9's table that matters most: "No date and no figure."
    final a = _assessment(
      state: DueState.dueSoon,
      driver: DueDriver.distance,
      confidence: RateConfidence.defaulted,
      remainingMetres: const Distance.fromKm(5000).metres,
    );

    expect(status(a), en.homeDueSoonNoConfidence);
    expect(status(a), isNot(contains('5')), reason: 'no figure at all');
    expect(homeActionKey(a), HomeAction.updateOdometer);
  });

  test('dueSoon by distance above default carries the figure', () {
    expect(
      status(
        _assessment(
          state: DueState.dueSoon,
          driver: DueDriver.distance,
          confidence: RateConfidence.assumed,
          remainingMetres: const Distance.fromKm(5000).metres,
        ),
      ),
      'in about 5,000 km',
    );
  });

  test('needsOdometer reads a request, not an accusation', () {
    final a = _assessment(
      state: DueState.needsOdometer,
      driver: DueDriver.distance,
    );
    expect(status(a), 'Needs an odometer reading');
    expect(homeActionKey(a), HomeAction.updateOdometer);
  });

  test('every other state offers Log it', () {
    for (final state in [DueState.overdue, DueState.due, DueState.dueSoon]) {
      expect(
        homeActionKey(
          _assessment(state: state, driver: DueDriver.time),
        ),
        HomeAction.logIt,
        reason: '$state',
      );
    }
  });

  test('every message resolves in all six locales', () {
    // Not "does it translate" — does it RESOLVE. A key missing from a locale
    // falls back to English silently, and the six-ARB rule is the only thing
    // that catches it.
    for (final code in ['en', 'de', 'fr', 'fa', 'ar', 'ckb']) {
      final l10n = lookupAppLocalizations(Locale(code));
      for (final message in [
        l10n.homeDueSoonNoConfidence,
        l10n.homeDueNow,
        l10n.homeNeedsOdometer,
        l10n.homeUnknownTitle,
        l10n.homeUnknownHint,
        l10n.actionLogIt,
        l10n.actionUpdateOdometer,
        l10n.remindersDisclaimer,
      ]) {
        expect(message, isNotEmpty, reason: code);
      }
      expect(l10n.homeMoreDue(0, '0'), isNotEmpty, reason: code);
      expect(l10n.homeUnknownMore(0, '0'), isNotEmpty, reason: code);
      expect(l10n.remindersSeeAll(0, '0'), isNotEmpty, reason: code);
    }
  });

  test('counts carry an explicit zero case', () {
    // §8's RTL note and §5: Arabic's `zero` category IS n=0, so a count that
    // relies on `other` reads wrong there — and "See all reminders (0)" is a
    // row that should not be drawn at all.
    expect(en.remindersSeeAll(0, '0'), isNot(contains('0')));
    expect(en.homeMoreDue(0, '0'), isNot(contains('0')));
    expect(en.homeUnknownMore(0, '0'), isNot(contains('0')));
  });

  test('the figure and its unit travel in one bidi isolate', () {
    // §9's RTL rule: `۱٬۴۰۰ کیلومتر` never splits across the mirror.
    final line = homeStatusLine(
      en,
      'fa-IR',
      _assessment(
        state: DueState.overdue,
        driver: DueDriver.distance,
        remainingMetres: -const Distance.fromKm(1400).metres,
      ),
      DistanceUnit.km,
    );
    // Written as ESCAPES: a literal U+2068 in source reorders the code a
    // reviewer reads, which is the same class of problem the isolate exists to
    // solve in the first place.
    expect(line, contains('\u2068'));
    expect(line, contains('\u2069'));
  });

  test('no user sentence is a Dart literal under lib/features/home/', () {
    // SPEC.md §2: a sentence built in Dart is a sentence no translator can
    // reorder, and one WRITTEN in Dart is one five translators never see. The
    // grep is over the words most likely to be typed straight into a widget.
    expect(
      bannedPatternOffenders(const {
        "'Odova needs a reading":
            'every user sentence is an ICU message in six ARB files',
        "'Overdue by": 'the same',
        "'Due now'": 'the same',
        "'Needs an odometer": 'the same',
        "'See all": 'the same',
        "'Log it'": 'the same',
        "'Update odometer'": 'the same',
      }, path: 'lib/features/home'),
      isEmpty,
    );
  });
}
