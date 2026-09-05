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
import 'package:odova/core/time/civil_date.dart';
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
  int? dueAtOdometerMetres,
  String? dueOn,
  String? projectedDueDate,
}) => DueAssessment(
  state: state,
  driver: driver,
  confidence: confidence,
  progress: 1,
  remainingMetres: remainingMetres,
  remainingDays: remainingDays,
  dueAtOdometerMetres: dueAtOdometerMetres,
  dueOn: dueOn == null ? null : CivilDate.tryParse(dueOn),
  projectedDueDate: projectedDueDate == null
      ? null
      : CivilDate.tryParse(projectedDueDate),
);

void main() {
  late AppLocalizations en;

  setUpAll(() async {
    await initializeDateFormatting();
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  String status(DueAssessment a, {String tag = 'en-GB'}) =>
      stripBidi(homeStatusLine(en, tag, a, DistanceUnit.km));

  String? anchor(DueAssessment a, {String tag = 'en-GB'}) {
    final line = homeAnchorLine(en, tag, a, DistanceUnit.km);
    return line == null ? null : stripBidi(line);
  }

  group('the anchor line — what the status is measured against', () {
    // SPEC.md §9's card table, one row at a time. The anchor is the card's
    // THIRD line and its only checkable fact: "Overdue by 900 km" is a claim
    // and "Was due at 186,512 km" is the number a user can compare against
    // their own dash.
    test('overdue by distance names the odometer', () {
      expect(
        anchor(
          _assessment(
            state: DueState.overdue,
            driver: DueDriver.distance,
            remainingMetres: -900000,
            dueAtOdometerMetres: 186512000,
          ),
        ),
        'Was due at 186,512 km',
      );
    });

    test('overdue by time names the date', () {
      expect(
        anchor(
          _assessment(
            state: DueState.overdue,
            driver: DueDriver.time,
            remainingDays: -24,
            dueOn: '2026-08-12',
          ),
        ),
        'Was due 12 August 2026',
      );
    });

    test('overdue on both axes names both, distance first', () {
      // The ORDER is the assertion. §9 puts the distance first for the same
      // reason the status line does, and a message that reversed them would
      // read correctly and mean something slightly different.
      expect(
        anchor(
          _assessment(
            state: DueState.overdue,
            driver: DueDriver.both,
            remainingMetres: -900000,
            remainingDays: -24,
            dueAtOdometerMetres: 186512000,
            dueOn: '2026-08-12',
          ),
        ),
        'Was due at 186,512 km · 12 August 2026',
      );
    });

    test('due reads in the present tense', () {
      expect(
        anchor(
          _assessment(
            state: DueState.due,
            driver: DueDriver.both,
            dueAtOdometerMetres: 192000000,
            dueOn: '2026-10-10',
          ),
        ),
        'At 192,000 km · 10 October 2026',
      );
    });

    test('dueSoon by time is the plain date, with no hedge', () {
      // Calendar arithmetic, not a guess — §9: "Exact and plain: 10 October."
      // The word "around" belongs to a PROJECTION and nowhere else.
      expect(
        anchor(
          _assessment(
            state: DueState.dueSoon,
            driver: DueDriver.time,
            remainingDays: 21,
            dueOn: '2026-10-10',
          ),
        ),
        '10 October 2026',
      );
    });

    test('dueSoon by distance carries a fuzzy date only at measured', () {
      DueAssessment soon(RateConfidence confidence) => _assessment(
        state: DueState.dueSoon,
        driver: DueDriver.distance,
        confidence: confidence,
        remainingMetres: 5000000,
        projectedDueDate: '2026-10-22',
      );

      expect(anchor(soon(RateConfidence.measured)), 'around 22 October 2026');
      // At `assumed` and `default` the projection is the app's own guess about
      // a car it barely knows. §9 gives `assumed` a MONTH-precision phrase
      // ("around mid-October") which nothing formats yet, and `default` no
      // date at all — so both answer nothing rather than dressing a guess up
      // as a day. See epics/progress/EPIC-10.md.
      expect(anchor(soon(RateConfidence.assumed)), isNull);
      expect(anchor(soon(RateConfidence.defaulted)), isNull);
    });

    test('needsOdometer states what the app has, not what it wants', () {
      expect(
        anchor(
          _assessment(
            state: DueState.needsOdometer,
            driver: DueDriver.distance,
            dueOn: '2026-07-12',
          ),
        ),
        'Last entered 12 July 2026',
      );
    });

    test('an assessment with nothing to point at has no anchor line', () {
      // §9's `default` confidence row "gives the card no date and no number",
      // and an anchor line would smuggle one back under a different heading.
      expect(
        anchor(
          _assessment(state: DueState.overdue, driver: DueDriver.distance),
        ),
        isNull,
      );
    });
  });

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
