/// Reads `analysis_options.yaml`, which is the single record of which paths in
/// this repo hold generated code.
///
/// Its own header states the contract — "excludes and coverage filters that
/// drift apart lie the coverage number upward" — so the analyzer, the coverage
/// filter and every policy test read the list from there rather than keeping a
/// copy. This is the one Dart parser; `test/policy/lint_test.dart` asserts
/// there is no second one.
library;

import 'dart:convert';
import 'dart:io';

/// The path to the options file. A test may point this at a temporary file to
/// prove a consumer really reads it rather than carrying its own copy.
const analysisOptionsPath = 'analysis_options.yaml';

/// The globs under `analyzer: exclude:` in [path], in file order.
List<String> analyzerExcludes({String path = analysisOptionsPath}) {
  final block = RegExp(
    r'^  exclude:\s*$\n((?:^    - .*$\n?)+)',
    multiLine: true,
  ).firstMatch(File(path).readAsStringSync());

  if (block == null) {
    throw StateError('$path has no analyzer.exclude block');
  }

  return [
    for (final line in const LineSplitter().convert(block.group(1)!))
      if (line.trim().isNotEmpty)
        line.trim().substring(1).trim().replaceAll(RegExp("['\"]"), ''),
  ];
}

/// The excluded globs that name a whole directory, with the `/**` removed.
///
/// `lib/l10n/gen/**` becomes `lib/l10n/gen`. Callers that walk the source tree
/// use this to skip generated directories for the same reason the analyzer
/// skips them.
Set<String> excludedDirectories({String path = analysisOptionsPath}) => {
  for (final glob in analyzerExcludes(path: path))
    if (RegExp(r'^([^*]+)/\*\*$').firstMatch(glob) case final match?)
      match.group(1)!,
};
