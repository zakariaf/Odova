// The three groups, and what decides which one a row is in.
//
// SPEC.md §9 *Groups, in order*. Pure Dart on both sides: the grouping is a
// partition and a sort, and a boundary is cheap to assert here and expensive to
// reach through a screen.
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/features/reminders/domain/reminders_groups.dart';

import '../../home/home_fixture.dart';

List<String> _labels(List<ReminderRow> rows) => [
  for (final row in rows) row.item.label ?? '',
];

void main() {
  test('a row is untracked, then paused, then active — in that order', () {
    // The order of the CHECKS matters: an item that is both untracked and
    // inactive belongs in *Not tracked*, because §9 excludes an untracked row
    // from the engine entirely and "paused" is a thing you do to a reminder you
    // have.
    final both = homeItem('Coolant', isTracked: false, isActive: false);
    final groups = groupReminders(items: [both], assessed: const []);

    expect(_labels(groups.notTracked), ['Coolant']);
    expect(groups.paused, isEmpty);
    expect(groups.active, isEmpty);
  });

  test(
    'the first group sorts by projected due date, exactly as Home sorts',
    () {
      final oil = homeItem('Oil and filter');
      final inspection = homeItem('Inspection', suffix: 'B');
      final brakes = homeItem('Brake pads', suffix: 'C');

      final groups = groupReminders(
        items: [inspection, brakes, oil],
        assessed: [
          (inspection, homeAssessment(dueOn: '2027-03-14')),
          (brakes, homeAssessment(dueOn: '2026-10-20')),
          (oil, homeAssessment(state: DueState.overdue, dueOn: '2026-08-12')),
        ],
      );

      expect(_labels(groups.active), [
        'Oil and filter',
        'Brake pads',
        'Inspection',
      ]);
    },
  );

  test('an active row the engine did not assess sorts last, by label', () {
    // The app has nothing to order it by, and putting it first would put the
    // row it knows least about at the top of the screen — the same rule
    // `compareDueDates` applies to a missing date.
    final known = homeItem('Oil and filter');
    final zed = homeItem('Zed', suffix: 'B');
    final abel = homeItem('Abel', suffix: 'C');

    final groups = groupReminders(
      items: [zed, known, abel],
      assessed: [(known, homeAssessment(dueOn: '2027-03-14'))],
    );

    expect(_labels(groups.active), ['Oil and filter', 'Abel', 'Zed']);
  });

  test('only a tracked, active row carries an assessment', () {
    // §3 excludes both from the engine, so a row that carried one would be
    // showing a status nothing computed. The fixture supplies assessments for
    // all three on purpose: the guard has to be the GROUPING's, not the
    // caller's.
    final oil = homeItem('Oil and filter');
    final belt = homeItem('Timing belt', suffix: 'B', isActive: false);
    final plugs = homeItem('Spark plugs', suffix: 'C', isTracked: false);

    final groups = groupReminders(
      items: [oil, belt, plugs],
      assessed: [
        (oil, homeAssessment()),
        (belt, homeAssessment()),
        (plugs, homeAssessment()),
      ],
    );

    expect(groups.active.single.assessment, isNotNull);
    expect(groups.paused.single.assessment, isNull);
    expect(groups.notTracked.single.assessment, isNull);
  });

  test('isEmpty is every group empty; allPaused is about the TRACKED ones', () {
    expect(
      groupReminders(items: const [], assessed: const []).isEmpty,
      isTrue,
    );

    final paused = groupReminders(
      items: [homeItem('Timing belt', isActive: false)],
      assessed: const [],
    );
    expect(paused.allPaused, isTrue);

    // A vehicle whose whole catalogue is UNTRACKED has not turned anything
    // off. It has not turned anything on, which is first run and a different
    // sentence.
    final untracked = groupReminders(
      items: [homeItem('Spark plugs', isTracked: false)],
      assessed: const [],
    );
    expect(untracked.allPaused, isFalse);
    expect(untracked.isEmpty, isFalse);
  });

  test('the two greyed groups keep the order they arrived in', () {
    // §9 gives them no sort, and inventing one would be a second answer about
    // a list nobody is scanning for urgency.
    final groups = groupReminders(
      items: [
        homeItem('Zed', isActive: false),
        homeItem('Abel', suffix: 'B', isActive: false),
      ],
      assessed: const [],
    );

    expect(_labels(groups.paused), ['Zed', 'Abel']);
  });
}
