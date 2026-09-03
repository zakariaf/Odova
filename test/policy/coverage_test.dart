// Coverage is a published report, never a gate.
//
// It still has to be honest. analysis_options.yaml's own header states the
// contract: "excludes and coverage filters that drift apart lie the coverage
// number upward". Generated code is large and fully covered by whatever calls
// it, so leaving lib/l10n/gen/ in the report inflates the total by thousands of
// lines nobody wrote.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the coverage filter and the analyzer excludes are the same list', () {
    final workspace = Directory.systemTemp.createTempSync('odova_lcov');
    addTearDown(() => workspace.deleteSync(recursive: true));

    // One record per glob in analysis_options.yaml, plus one that must survive.
    const lcov = '''
SF:lib/main.dart
DA:1,1
end_of_record
SF:lib/l10n/gen/app_localizations.dart
DA:1,1
end_of_record
SF:lib/data/database.g.dart
DA:1,0
end_of_record
SF:lib/core/due.freezed.dart
DA:1,0
end_of_record
SF:lib/data/schema.drift.dart
DA:1,0
end_of_record
''';
    final file = File('${workspace.path}/lcov.info')..writeAsStringSync(lcov);

    final result = Process.runSync('bash', [
      'tools/strip_generated_from_lcov.sh',
      file.path,
    ]);
    expect(
      result.exitCode,
      0,
      reason: 'strip_generated_from_lcov.sh failed: ${result.stderr}',
    );

    final sourceFiles = RegExp(
      r'^SF:(.+)$',
      multiLine: true,
    ).allMatches(file.readAsStringSync()).map((m) => m.group(1)!).toList();

    expect(
      sourceFiles,
      ['lib/main.dart'],
      reason:
          'every glob analysis_options.yaml excludes must be stripped, and '
          'nothing else may be',
    );
  });

  test('the filter reads the globs from analysis_options.yaml', () {
    // The functional test above would still pass if the script carried its own
    // hardcoded copy of the four globs. It must not: that copy is what drifts.
    expect(
      File('tools/strip_generated_from_lcov.sh').readAsStringSync(),
      contains('analysis_options.yaml'),
    );
  });

  test('no coverage threshold exists anywhere in CI', () {
    // A threshold turns a report into a gate, and the first thing a threshold
    // gate produces is a test written to raise a number.
    final workflow = File('.github/workflows/ci.yml').readAsStringSync();

    for (final pattern in [
      'min-coverage',
      'coverage-threshold',
      'fail_under',
    ]) {
      expect(workflow, isNot(contains(pattern)));
    }
  });
}
