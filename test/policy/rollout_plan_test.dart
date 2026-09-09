// A halt criterion exists, with a number and a name on it.
//
// The failure this prevents is not subtle: a rollout with no written criterion
// is a rollout nobody halts, because halting is a judgement call somebody has
// to make alone at the moment it is hardest. A number written a week earlier is
// a decision that has already been made.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _plan() => File('release/rollout-1.0.0.md').readAsStringSync();

void main() {
  test('it names a threshold, a window and a floor', () {
    final plan = _plan();

    expect(
      plan,
      matches(RegExp(r'\d+(\.\d+)?%')),
      reason: 'no crash-free threshold',
    );
    // The floor is what stops day one of a phased release — 1% of users on a
    // new listing — from tripping the criterion on three sessions.
    expect(
      plan.toLowerCase(),
      contains('sessions'),
      reason: 'the threshold has no session floor, so it fires on noise',
    );
  });

  test('somebody is named as the watcher', () {
    expect(
      _plan(),
      // `[^|\s]`, not `\S`. The first version used `\S+`, which matches the
      // NEXT TABLE PIPE — so an empty watcher cell passed it, and a mutation
      // that blanked the name survived.
      matches(RegExp(r'\*\*Watcher\*\*\s*\|\s*[^|\s]')),
      reason: 'no named watcher — a criterion nobody is watching is a note',
    );
  });

  test('it says what happens after the halt', () {
    // The platform decision's consequence. Pausing stops the build reaching
    // MORE users; everyone who has it keeps it, and the only way back is a new
    // build through review. A plan that says "halt" and stops there has not
    // planned the part that takes days.
    final plan = _plan().toLowerCase();

    expect(
      plan,
      contains('expedite'),
      reason:
          'the plan halts and stops — but an approved iOS build cannot be '
          'withdrawn, so the fix is a new build through review',
    );
    expect(
      plan,
      contains('cannot be un-shipped'),
      reason: 'the plan does not say why a halt is only a pause',
    );
  });

  test('data loss is a halt on its own', () {
    // §1: "Losing eight years of service history is the worst bug this app can
    // have." There is no percentage at which one of those is acceptable, and
    // it never appears in a crash graph.
    // Scoped to THE CRITERION section, not to the document. The phrase also
    // appears further down where the plan discusses which signal to trust, and
    // a whole-document `contains` passed while the criterion itself had lost
    // it — which is the only place it does any work.
    final plan = _plan();
    final criterion = plan.substring(
      plan.indexOf('## The criterion'),
      plan.indexOf('## The halt is a pause'),
    );

    expect(
      criterion.toLowerCase(),
      contains('data loss'),
      reason: 'the worst bug this app can have is not in the halt criterion',
    );
  });
}
