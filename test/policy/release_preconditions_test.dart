// The release gate is self-tested, and the self-test is what proves it.
//
// **This file used to grep `tools/release.sh` for strings** — that each
// precondition's name appeared, that "REFUSED" came before `flutter build`.
// Two things were wrong with that. It tested the implementation: rewording a
// message broke a green suite while behaviour was unchanged. And it did not
// work: a mutation replacing a `grep` with `false` survived, because the
// filename was still named one line above, and the fix applied at the time was
// to match a *longer* string — the same altitude, one notch tighter.
//
// The repo already owns the right mechanism. `tools/check_gates_selftest.sh`
// plants a real violation for each gate, asserts red, removes it, asserts
// green — and `release.sh` now has five arms in it, driving `--dry-run` over a
// scratch tree with one precondition broken at a time. A dry run that exits 0
// provably checked everything and built nothing; one that exits 1 provably
// refused, whatever the message said.
//
// So all this file asserts is that the arms exist. It is the link between the
// `flutter` lane, which people watch, and the `repo` lane, where the real proof
// runs.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release.sh has self-test arms, one per precondition', () {
    final selftest = File(
      'tools/check_gates_selftest.sh',
    ).readAsStringSync();

    expect(
      selftest,
      contains('release.sh --dry-run is green'),
      reason: 'nothing proves the gate passes when it should',
    );

    // The arm LIST, which is what the loop iterates. Asserting the
    // interpolated labels would be asserting `release.sh refuses on: signoff`
    // — a string that never appears, because the arms are a loop over a list
    // and the label is built at run time. That mistake is what this assertion
    // caught on its own first run.
    //
    // The clean tree and the hygiene gate are deliberately not in the list: a
    // self-test run dirties the tree by construction, and the hygiene gate has
    // its own arms above.
    final arms = RegExp(
      r'for arm in ([\w ]+); do',
    ).firstMatch(selftest)?.group(1);

    expect(
      arms?.split(' ').toSet(),
      {'signoff', 'override', 'buildnumber', 'checks', 'changelog'},
      reason: 'the self-test does not plant every precondition',
    );
  });

  test('building over an unsigned review needs the decision on record', () {
    // THE DEADLOCK, and why the sign-off no longer blocks the build.
    //
    // `SIGNOFF-2026-09-08.md` lists five things that must happen before it can
    // be signed, and the fourth is "run design-review-workflow's four lenses
    // ON A RELEASE BUILD and produce design/review/shots/". Its Build flavour
    // row reads "none — debug widget captures only". So the sign-off cannot be
    // earned until a release build exists, and `release.sh` would not make one
    // until the sign-off was earned. Neither side could move first.
    //
    // The gate is not removed, it is re-aimed. An unsigned review still refuses
    // to build — unless the owner has written down, in a tracked file, that
    // they are building over it and what is unfinished. That keeps the thing a
    // gate is for (nobody does this by accident, and the decision is reviewed
    // like any other diff) and drops the thing that was wrong with it (a
    // precondition that could never be satisfied).
    //
    // Signing the document instead would have cleared the gate in one `sed` and
    // put a false statement in the only record of what was reviewed.
    final record = File('release/UNSIGNED-BUILD.md');
    expect(
      record.existsSync(),
      isTrue,
      reason:
          'release.sh builds over an unsigned design review only when '
          'release/UNSIGNED-BUILD.md records the decision',
    );

    final text = record.readAsStringSync();
    // The sign-off it overrides, BY NAME. A record that does not name one is a
    // blank cheque that outlives the review it was written against — the next
    // sign-off would inherit an override nobody wrote for it.
    final signoff = Directory('design/review')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .firstWhere((n) => n.startsWith('SIGNOFF-'));
    expect(
      text,
      contains(signoff),
      reason: 'the record does not name the sign-off it overrides',
    );
  });
}
