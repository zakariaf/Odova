/// Walking this repo's own source, for the policy tests.
///
/// **Flutter-free, and it has to stay that way.** `test/core` is run twice: by
/// `flutter test` with everything else, and by `dart test test/core` on the
/// plain VM, which is the gate that proves the domain layer needs no Flutter.
/// A helper here that imports `flutter_test` breaks the second run with
/// `Dart library 'dart:ui' is not available on this platform` — which is
/// exactly what happened when this file was first shared with a `test/core`
/// gate. So it throws rather than calling `fail`, and it returns rather than
/// calling `expect`.
///
/// Every grep-style gate needs the same three things: the list of hand-written
/// Dart files, a way to skip generated code that does not retype which paths
/// are generated, and a guard that fails when the walk found nothing. The third
/// is the one that gets forgotten, and a gate that visits zero files passes
/// while proving nothing.
library;

import 'dart:io';

import 'analysis_options_source.dart';

/// Directories under `lib/` that are legitimately empty of Dart today.
///
/// [dartFilesUnder] fails on an empty walk unless the directory is named here,
/// so "this gate currently checks nothing" is a decision written down rather
/// than an accident. Each entry names the epic that fills it.
const knownEmptyLibDirectories = {
  'lib/features', // EPIC-09 — first run and the garage
};

/// Every hand-written `.dart` file under [path].
///
/// Generated code is skipped by reading `analyzer: exclude:` from
/// `analysis_options.yaml` — BOTH forms of it. The directory globs
/// (`lib/l10n/gen/**`) and the suffix globs (`**/*.g.dart`) are separate
/// entries there, and this used to honour only the first: every gate that
/// walked `lib/` was reading `app_database.g.dart` and reporting generated
/// code as source. Fails the test when the walk returns nothing and [path] is
/// not in [knownEmptyLibDirectories].
List<File> dartFilesUnder(String path) {
  final directory = Directory(path);
  if (!directory.existsSync()) throw StateError('$path does not exist');

  final excluded = excludedDirectories();
  final suffixes = excludedSuffixes();
  final files = directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where(
        (f) => !excluded.any(
          (e) => f.path == e || f.path.startsWith('$e/'),
        ),
      )
      .where((f) => !suffixes.any(f.path.endsWith))
      .toList();

  if (files.isEmpty && !knownEmptyLibDirectories.contains(path)) {
    throw StateError(
      '$path holds no Dart file, so the gate that walked it asserted nothing. '
      'If that is expected, add it to knownEmptyLibDirectories with the epic '
      'that fills it.',
    );
  }
  return files;
}

/// [file]'s source with every whole-line `//` comment removed.
///
/// A doc comment that names the thing a gate forbids — in order to explain why
/// it is forbidden — must not trip that gate. The reasoning is the most
/// valuable thing in the file and a gate that punishes writing it down teaches
/// people not to. Only WHOLE lines go, so a trailing comment and every string
/// literal still count.
String sourceWithoutLineComments(File file) => file
    .readAsLinesSync()
    .where((line) => !line.trimLeft().startsWith('//'))
    .join('\n');

/// Every `import`/`export` URI in [source].
Iterable<String> importUrisIn(String source) => RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
).allMatches(source).map((m) => m.group(1)!);

/// Every file under [path] that contains one of [banned]'s patterns.
///
/// Returns rather than asserting, so this library stays Flutter-free — see the
/// note at the top. Callers `expect(…, isEmpty)`.
///
/// Keys are regular expressions; values say why the identifier is refused, and
/// end up in the failure message where somebody can act on them.
///
/// **Whole comment lines are stripped first.** A doc comment that names
/// `ColorScheme.fromSeed` in order to explain why Calm cannot use it must not
/// trip the gate that forbids it — the reasoning is the most valuable thing in
/// the file, and a gate that punishes writing it down teaches people not to.
/// `check_raw_values.sh` strips comments for exactly this reason. Only whole
/// lines go, so a trailing comment and every string literal still count.
List<String> bannedPatternOffenders(
  Map<String, String> banned, {
  String path = 'lib',
}) {
  final offenders = <String>[];
  for (final file in dartFilesUnder(path)) {
    final source = sourceWithoutLineComments(file);
    for (final MapEntry(key: pattern, value: why) in banned.entries) {
      if (RegExp(pattern).hasMatch(source)) {
        offenders.add('${file.path}: $why');
      }
    }
  }
  return offenders;
}
