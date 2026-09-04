// Diffs `test/core/due/fixtures/due_matrix.json` against current behaviour.
//
// **It does not regenerate what it checks.** Without `--bless` it computes the
// engine's answer for every fixture and reports the rows that differ, exiting
// non-zero; CI runs it that way. `--bless` is the only path that writes, and it
// exists for a DELIBERATE behaviour change, made by a person who then says in
// the PR what changed and why.
//
// `seeded-determinism-and-golden-vectors`: a gate never regenerates what it
// checks. A tool that rewrites the file on every run turns a golden file into a
// transcript of whatever the code does today, which is worse than no golden
// file, because it carries the authority of one.
//
// The fixture itself was hand-authored from SPEC.md §3 and §4.1 through an
// independent implementation of the prose. This tool has never written it.
//
// The scenario is decoded by `test/support/due_case.dart`, which
// `due_matrix_test.dart` also uses. They used to construct it separately, and
// that is worse than ordinary duplication because THIS is a gate: if the two
// constructions drift, the gate green-lights a different scenario from the one
// the test asserts and neither goes red. They had already drifted — the test
// honoured `is_active` and this did not.
import 'dart:convert';
import 'dart:io';

import '../test/support/due_case.dart';

const _path = 'test/core/due/fixtures/due_matrix.json';

void main(List<String> args) {
  final bless = args.contains('--bless');
  final file = File(_path);
  final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final cases = (doc['cases']! as List).cast<Map<String, dynamic>>();

  final drifted = <String>[];
  // ROWS, not fields. `drifted` gains one entry per mismatched field, so a
  // single row differing in five of them reported as "5 rows changed".
  var changedRows = 0;
  for (final fixture in cases) {
    final expected = fixture['expect'] as Map<String, dynamic>?;
    final actual = runDueCase(fixture);

    // `--bless` writes whatever the engine now says, INCLUDING a row that has
    // become eligible or stopped being so. The first version returned early on
    // both mismatches, so blessing an eligibility change left the stale
    // `expect` block behind and the next unblessed run failed again.
    if (expected == null || actual == null) {
      if (expected != actual) {
        final what = expected == null
            ? 'expected no assessment, got one'
            : 'expected an assessment, got none';
        drifted.add('${fixture['name']}: $what');
        changedRows++;
      }
      if (bless) fixture['expect'] = actual;
      continue;
    }

    var rowChanged = false;
    for (final key in expected.keys) {
      final want = expected[key];
      final got = actual[key];
      final same = want is num && got is num
          ? (want - got).abs() < 1e-6
          : want == got;
      if (!same) {
        drifted.add('${fixture['name']}: $key want $want, got $got');
        rowChanged = true;
      }
    }
    if (rowChanged) changedRows++;
    if (bless) fixture['expect'] = actual;
  }

  if (bless) {
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(doc)}\n',
    );
    stdout.writeln('blessed $_path ($changedRows rows changed)');
    return;
  }

  if (drifted.isEmpty) {
    stdout.writeln('ok    $_path matches the engine (${cases.length} rows)');
    return;
  }

  stdout
    ..writeln('FAIL  $_path disagrees with the engine:')
    ..writeAll(drifted.map((d) => '        $d\n'))
    ..writeln()
    ..writeln('      The fixture is hand-authored from SPEC.md. If the ENGINE')
    ..writeln('      is right, this is a deliberate behaviour change: run with')
    ..writeln('      --bless and say in the PR what changed and why. If the')
    ..writeln('      FIXTURE is right, the engine has a bug.');
  exitCode = 1;
}
