// Policy tests over analysis_options.yaml.
//
// A lint config is the one file that can be completely wrong and completely
// silent: an `include:` that resolves to nothing analyses zero rules and
// reports green, and an `errors:` entry for a rule the base set never enabled
// is a line that does nothing at all. Both are tested here rather than trusted.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/analysis_options_source.dart';

/// The resolved `include:` target, from the one resolver.
///
/// `tools/check_lint_include.sh --print-path` does the work. Resolving through
/// `.dart_tool/package_config.json` a second time in Dart would mean finding
/// out twice, in two languages, that `rootUri` is sometimes relative to
/// `.dart_tool/` and sometimes a percent-encoded `file:` URI.
File _resolvedIncludeFile() {
  final result = Process.runSync('bash', [
    'tools/check_lint_include.sh',
    '--print-path',
  ]);
  expect(
    result.exitCode,
    0,
    reason: 'check_lint_include.sh failed: ${result.stderr}',
  );
  return File((result.stdout as String).trim());
}

/// The lint names in [text]'s own `linter: rules:` block.
Set<String> _declaredRules(String text) {
  // The `rules:` block is a YAML list of bare lint names, one per line.
  final block = RegExp(
    r'^\s*rules:\s*$\n((?:\s*-\s*\w+\s*$\n?)+)',
    multiLine: true,
  ).firstMatch(text);
  if (block == null) return {};

  return {
    for (final line in const LineSplitter().convert(block.group(1)!))
      ?RegExp(r'-\s*(\w+)').firstMatch(line)?.group(1),
  };
}

/// Every lint name enabled by [file], following its own `include:` chain.
Set<String> _enabledRules(File file) {
  final text = file.readAsStringSync();
  final rules = _declaredRules(text);

  final nested = RegExp(
    r'^include:\s*(\S+)$',
    multiLine: true,
  ).firstMatch(text);
  if (nested != null) {
    final target = nested.group(1)!;
    if (!target.startsWith('package:')) {
      rules.addAll(_enabledRules(File.fromUri(file.uri.resolve(target))));
    }
  }
  return rules;
}

void main() {
  final analysisOptions = File(analysisOptionsPath).readAsStringSync();

  test('every rule promoted under errors: is enabled by the base ruleset', () {
    // `errors:` RE-RANKS a diagnostic the ruleset already produces. It cannot
    // turn an off rule on, so promoting a rule very_good_analysis does not
    // enable is a line that reads like a gate and is not one.
    final errorsBlock = RegExp(
      r'^  errors:\s*$\n((?:^    \w+:.*$\n?)+)',
      multiLine: true,
    ).firstMatch(analysisOptions);
    expect(errorsBlock, isNotNull, reason: 'no analyzer.errors: block');

    final promoted = RegExp(
      r'^\s+(\w+):',
      multiLine: true,
    ).allMatches(errorsBlock!.group(1)!).map((m) => m.group(1)!).toList();
    expect(promoted, isNotEmpty);

    // The EFFECTIVE ruleset: what the include brings, plus anything this repo
    // switches on itself. close_sinks is the second kind — VGA never enables
    // it, so promoting it without the `linter:` block would do nothing.
    final enabled = _enabledRules(_resolvedIncludeFile())
      ..addAll(_declaredRules(analysisOptions));
    expect(
      enabled.length,
      greaterThan(50),
      reason:
          'the resolved ruleset parsed as almost nothing — the parser, not '
          'the config, is what failed',
    );

    for (final rule in promoted) {
      expect(
        enabled,
        contains(rule),
        reason:
            "'$rule' is promoted to error but nothing in the effective "
            'config enables it, so the promotion does nothing',
      );
    }
  });

  test('the coverage filter reads the excludes, never a copy', () {
    // The behaviour, not the spelling. A grep for the glob strings only proves
    // nobody typed one particular string; it fires on a README that mentions
    // one in prose, and it misses a consumer that retypes `lib/l10n/gen/`
    // without the `**`. This drives the filter from a DIFFERENT options file
    // and asserts the output follows it.
    final workspace = Directory.systemTemp.createTempSync('odova_excludes');
    addTearDown(() => workspace.deleteSync(recursive: true));

    final options = File('${workspace.path}/analysis_options.yaml')
      ..writeAsStringSync('''
analyzer:
  exclude:
    - '**/*.invented.dart'
''');
    final lcov = File('${workspace.path}/lcov.info')
      ..writeAsStringSync(
        'SF:lib/main.dart\nDA:1,1\nend_of_record\n'
        'SF:lib/thing.invented.dart\nDA:1,1\nend_of_record\n'
        // Excluded by the REAL options file, and by nothing in the temporary
        // one — so it must survive, or the filter is not reading the argument.
        'SF:lib/l10n/gen/app_localizations.dart\nDA:1,1\nend_of_record\n',
      );

    final result = Process.runSync('bash', [
      'tools/strip_generated_from_lcov.sh',
      lcov.path,
      options.path,
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');

    expect(
      RegExp(
        r'^SF:(.+)$',
        multiLine: true,
      ).allMatches(lcov.readAsStringSync()).map((m) => m.group(1)!).toList(),
      ['lib/main.dart', 'lib/l10n/gen/app_localizations.dart'],
    );
  });

  test('exactly one Dart parser reads the analyzer excludes', () {
    // The list has one home; so does the code that reads it. A second parser
    // is how two callers end up disagreeing about what `lib/l10n/gen/**` means.
    final parsers =
        [
              ...Directory('lib').listSync(recursive: true).whereType<File>(),
              ...Directory('test').listSync(recursive: true).whereType<File>(),
            ]
            .where((f) => f.path.endsWith('.dart'))
            // Split so this file does not match its own needle.
            .where(
              (f) => f.readAsStringSync().contains(
                'exclude:'
                r'\s*$',
              ),
            )
            .map((f) => f.path)
            .toList();

    expect(parsers, ['test/support/analysis_options_source.dart']);
  });
}
