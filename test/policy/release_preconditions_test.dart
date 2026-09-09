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
      {'signoff', 'buildnumber', 'checks', 'changelog'},
      reason: 'the self-test does not plant every precondition',
    );
  });
}
