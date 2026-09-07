// Every file in this directory imports, and does what its sidecar says.
//
// SPEC.md §6 §3.1 rule 3: a migration ships with a real file from the previous
// version in the corpus, checked in. THE CORPUS ONLY GROWS. The directory is
// WALKED rather than enumerated in code, so adding a file adds a case and
// nobody has to remember to register it — which is the failure mode of every
// hand-maintained fixture list.
//
// A red corpus is a release blocker, not a flaky test. It is the only place
// where the reader meets a whole file rather than a fixture built to exercise
// one branch.
//
// Every file here is SYNTHETIC. `CLAUDE.md` forbids committing a real backup as
// a fixture, and a real one would carry somebody's plate and their address.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:odova/core/result.dart';
import 'package:odova/features/backup/domain/backup_reader.dart';
import 'package:odova/features/backup/domain/import_failure.dart';
import 'package:odova/features/backup/domain/import_plan.dart';
import 'package:test/test.dart';

final Directory _corpus = Directory('test/corpus');

/// Every `foo.json` in the corpus. Walked, so adding a file adds a case.
List<File> _corpusFiles() =>
    (_corpus.listSync()..sort((a, b) => a.path.compareTo(b.path)))
        .whereType<File>()
        .where(
          (f) => f.path.endsWith('.json') && !f.path.endsWith('.expected.json'),
        )
        .toList();

File _sidecarOf(File file) =>
    File(file.path.replaceFirst('.json', '.expected.json'));

void main() {
  test('the corpus is not empty and every file has a sidecar', () {
    // Guard the guard: a walk over an empty directory passes silently, and a
    // deleted corpus would look exactly like a green one.
    final files = _corpusFiles();
    expect(files, hasLength(greaterThanOrEqualTo(13)));
    for (final file in files) {
      expect(
        _sidecarOf(file).existsSync(),
        isTrue,
        reason:
            '${file.path} has no .expected.json — a corpus file with no '
            'stated outcome is one nobody can tell has regressed',
      );
    }
  });

  for (final file in _corpusFiles()) {
    final name = file.uri.pathSegments.last;
    final expected =
        json.decode(_sidecarOf(file).readAsStringSync())
            as Map<String, Object?>;

    test('$name — ${expected['why']}', () async {
      final before = file.readAsBytesSync();
      final result = await const BackupReader().read(file);

      // On every path, refusal included: the reader writes nothing.
      expect(file.readAsBytesSync(), before, reason: 'the file was modified');

      switch (expected['outcome']) {
        case 'ok':
          final plan = switch (result) {
            Ok(:final value) => value,
            Err(:final failure) => fail('refused with ${failure.code}'),
          };
          expect(plan.recordsInFile, expected['records']);
          expect(
            plan.warnings.map((w) => w.code).toSet(),
            (expected['warnings']! as List).cast<String>().toSet(),
          );
        case 'refused':
          final failure = switch (result) {
            Ok() => fail('imported, but the sidecar says it must be refused'),
            Err(:final failure) => failure,
          };
          expect(failure.code, expected['failure']);
        case final other:
          fail('unknown outcome "$other" in ${file.path}');
      }
    });
  }

  test('the big trades file reads in one pass, not many', () async {
    // §9's size case. A soft floor on the test host: it catches an accidental
    // O(n²) — a re-scan per record, a list rebuilt inside the loop — which is
    // the only kind of slowness that turns a plumber's ten years into a hang.
    final file = File('test/corpus/trades-three-vans-ten-years.json');
    expect(file.lengthSync(), greaterThan(4 * 1000 * 1000));

    final started = DateTime.now();
    final result = await const BackupReader().read(file);
    final elapsed = DateTime.now().difference(started);

    expect(result, isA<Ok<ImportPlan, ImportFailure>>());
    expect(elapsed, lessThan(const Duration(seconds: 10)));
  });
}
