// Policy tests over .github/workflows/ci.yml.
//
// The workflow states its own rules in its header — every gate maps to a named
// contract, the runner is pinned, the two Flutter jobs read one pin. Those are
// comments until something checks them, and a comment is what the twelfth step
// gets added underneath.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final String _workflow = File('.github/workflows/ci.yml').readAsStringSync();

/// The lines of the `job` block, without its `  <name>:` header.
List<String> _job(String name) {
  final lines = _workflow.split('\n');
  final start = lines.indexWhere((l) => l.startsWith('  $name:'));
  expect(start, isNot(-1), reason: 'no job named $name');

  final rest = lines.sublist(start + 1);
  final end = rest.indexWhere((l) => RegExp('^  [a-z_]+:').hasMatch(l));
  return end == -1 ? rest : rest.sublist(0, end);
}

void main() {
  test('the app and build jobs pin the same Flutter version, read from '
      '.flutter-version', () {
    for (final job in ['app', 'build']) {
      final body = _job(job).join('\n');
      expect(
        body,
        contains(r'$(cat .flutter-version)'),
        reason: 'the $job job does not read the pin from .flutter-version',
      );
      expect(
        RegExp(r'flutter-version:\s*[0-9]').hasMatch(body),
        isFalse,
        reason:
            'the $job job hardcodes a Flutter version. Two records of one '
            'fact drift, and this one drifts silently: the jobs would build '
            'and test against different toolchains.',
      );
    }
  });

  test('no job uses runs-on: ubuntu-latest', () {
    // Image drift moves the toolchain with no diff to review, so a build that
    // passed on Tuesday fails on Wednesday for a reason nobody can bisect.
    expect(_workflow, isNot(contains('runs-on: ubuntu-latest')));
    expect(
      RegExp(r'runs-on: \S+-latest').hasMatch(_workflow),
      isFalse,
      reason: 'a floating runner image is a floating toolchain',
    );
  });

  test('no gate carries continue-on-error', () {
    // A gate that cannot block is not a gate.
    expect(_workflow, isNot(contains('continue-on-error')));
  });

  test('every step in the repo job has a Contract: comment above it', () {
    // The workflow's own stated rule: "a check with no contract behind it is
    // gate-sprawl and does not belong here". This is what keeps that true when
    // somebody adds the twelfth step.
    final uncontracted = <String>[];
    final comment = StringBuffer();
    String? step;

    for (final line in _job('repo')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#')) {
        comment.writeln(trimmed);
        continue;
      }
      if (trimmed.startsWith('- ')) {
        step = trimmed;
        if (!comment.toString().contains('Contract:')) uncontracted.add(step);
        comment.clear();
        continue;
      }
      // A blank line does not separate a comment from the step it documents;
      // any other content does.
      if (trimmed.isNotEmpty && step == null) comment.clear();
    }

    expect(
      uncontracted,
      isEmpty,
      reason: 'each of these steps needs one sentence saying what it enforces',
    );
  });
}
