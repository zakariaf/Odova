/// Walking this repo's own source, for the policy tests.
///
/// Every grep-style gate needs the same three things: the list of hand-written
/// Dart files, a way to skip generated code that does not retype which paths
/// are generated, and a guard that fails when the walk found nothing. The third
/// is the one that gets forgotten, and a gate that visits zero files passes
/// while proving nothing.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'analysis_options_source.dart';

/// Directories under `lib/` that are legitimately empty of Dart today.
///
/// [dartFilesUnder] fails on an empty walk unless the directory is named here,
/// so "this gate currently checks nothing" is a decision written down rather
/// than an accident. Each entry names the epic that fills it.
const knownEmptyLibDirectories = {
  'lib/core', // EPIC-06 — units, money and the fuel engine
  'lib/data', // EPIC-05 — persistence, schema and migrations
  'lib/features', // EPIC-09 — first run and the garage
  'lib/ui', // EPIC-03 — the Calm component library
};

/// Every hand-written `.dart` file under [path].
///
/// Generated directories are skipped by reading `analyzer: exclude:` from
/// `analysis_options.yaml`. Fails the test when the walk returns nothing and
/// [path] is not in [knownEmptyLibDirectories].
List<File> dartFilesUnder(String path) {
  final directory = Directory(path);
  expect(directory.existsSync(), isTrue, reason: '$path does not exist');

  final excluded = excludedDirectories();
  final files = directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where(
        (f) => !excluded.any(
          (e) => f.path == e || f.path.startsWith('$e/'),
        ),
      )
      .toList();

  if (files.isEmpty && !knownEmptyLibDirectories.contains(path)) {
    fail(
      '$path holds no Dart file, so the gate that walked it asserted nothing. '
      'If that is expected, add it to knownEmptyLibDirectories with the epic '
      'that fills it.',
    );
  }
  return files;
}

/// Every `import`/`export` URI in [source].
Iterable<String> importUrisIn(String source) => RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
).allMatches(source).map((m) => m.group(1)!);

/// Fails if any file under [path] contains one of [banned]'s patterns.
///
/// Keys are regular expressions; values say why the identifier is refused, and
/// end up in the failure message where somebody can act on them.
void expectNoBannedPatterns(
  Map<String, String> banned, {
  String path = 'lib',
  String? reason,
}) {
  final offenders = <String>[];
  for (final file in dartFilesUnder(path)) {
    final source = file.readAsStringSync();
    for (final MapEntry(key: pattern, value: why) in banned.entries) {
      if (RegExp(pattern).hasMatch(source)) {
        offenders.add('${file.path}: $why');
      }
    }
  }
  expect(offenders, isEmpty, reason: reason);
}
