// Policy tests over analysis_options.yaml.
//
// A lint config is the one file that can be completely wrong and completely
// silent: an `include:` that resolves to nothing analyses zero rules and
// reports green, and an `errors:` entry for a rule the base set never enabled
// is a line that does nothing at all. Both are tested here rather than trusted.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The `include:` target of [analysisOptions], resolved to a file on disk via
/// `.dart_tool/package_config.json`.
File _resolvedIncludeFile(String analysisOptions) {
  final include = RegExp(
    r'^include:\s*package:(\w+)/(\S+)$',
    multiLine: true,
  ).firstMatch(analysisOptions);
  expect(include, isNotNull, reason: 'analysis_options.yaml has no include:');

  final packageName = include!.group(1)!;
  final relativePath = include.group(2)!;

  final config =
      jsonDecode(
            File('.dart_tool/package_config.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final packages = (config['packages'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final package = packages.firstWhere(
    (p) => p['name'] == packageName,
    orElse: () => throw StateError(
      "'$packageName' is not in the resolved package config — the include "
      'names a package that is not a dependency, so it adds no rules at all.',
    ),
  );

  // rootUri may be relative to .dart_tool/, and carries no trailing slash —
  // without one, resolve() replaces the last path segment instead of
  // descending into it.
  final root = Uri.file(
    '${Directory.current.path}/.dart_tool/',
  ).resolve('${package['rootUri']}/');
  return File.fromUri(root.resolve('${package['packageUri']}/$relativePath'));
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
  final analysisOptions = File('analysis_options.yaml').readAsStringSync();

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
    final enabled = _enabledRules(_resolvedIncludeFile(analysisOptions))
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
            "'$rule' is promoted to error but the base ruleset never "
            'enables it, so the promotion does nothing',
      );
    }
  });

  test('the generated-code excludes are read from analysis_options.yaml, '
      'never retyped', () {
    final excludes = RegExp(r"^    - '?([^'\n]+)'?$", multiLine: true)
        .allMatches(
          RegExp(
            r'^  exclude:\s*$\n((?:^    - .*$\n?)+)',
            multiLine: true,
          ).firstMatch(analysisOptions)!.group(1)!,
        )
        .map((m) => m.group(1)!)
        .toList();
    expect(excludes, hasLength(4));

    // Anything that needs this list parses this file. A second copy in a
    // coverage filter drifts, and excludes that drift lie the coverage number
    // upward — which is why analysis_options.yaml says so in its own header.
    final searched = [
      ...Directory('tools').listSync(recursive: true).whereType<File>(),
      ...Directory('.github').listSync(recursive: true).whereType<File>(),
      ...Directory('lib').listSync(recursive: true).whereType<File>(),
      ...Directory('test').listSync(recursive: true).whereType<File>(),
    ].where((f) => f.path != 'test/policy/lint_test.dart');
    expect(searched, isNotEmpty);

    for (final file in searched) {
      if (file.path.contains('node_modules')) continue;
      final String text;
      try {
        text = file.readAsStringSync();
      } on FileSystemException {
        continue; // a binary asset
      }
      for (final glob in excludes) {
        expect(
          text,
          isNot(contains(glob)),
          reason:
              "${file.path} retypes the exclude '$glob' instead of "
              'reading it from analysis_options.yaml',
        );
      }
    }
  });
}
