// Policy tests over .github/workflows/ci.yml.
//
// The workflow states its own rules in its header — every gate maps to a named
// contract, the runner is pinned, the toolchain version has one home. Those are
// comments until something checks them, and a comment is what the twelfth step
// gets added underneath.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final String _workflow = File('.github/workflows/ci.yml').readAsStringSync();

/// The names of every job in the workflow, in file order.
List<String> _jobNames() => RegExp(r'^  ([a-z][a-z_]*):$', multiLine: true)
    .allMatches(_workflow.substring(_workflow.indexOf('\njobs:')))
    .map((m) => m.group(1)!)
    .toList();

/// The lines of the `job` block, without its `  <name>:` header.
List<String> _job(String name) {
  final lines = _workflow.split('\n');
  final start = lines.indexWhere((l) => l == '  $name:');
  expect(start, isNot(-1), reason: 'no job named $name');

  final rest = lines.sublist(start + 1);
  final end = rest.indexWhere((l) => RegExp('^  [a-z_]+:').hasMatch(l));
  return end == -1 ? rest : rest.sublist(0, end);
}

void main() {
  test('.flutter-version is read once, and every job resolves from it', () {
    // The decision is "one record of the toolchain version". Asserting that
    // each job contains `$(cat .flutter-version)` would pin the shell idiom
    // instead — and would fail the better arrangement, which is what this
    // workflow now does: the repo job reads the file and publishes it as an
    // output, and the two Flutter jobs consume that.
    expect(
      RegExp(r'cat \.flutter-version').allMatches(_workflow),
      hasLength(1),
      reason: 'the pin is read in more than one place',
    );
    expect(
      RegExp(r'flutter-version:\s*[0-9]').hasMatch(_workflow),
      isFalse,
      reason: 'a job hardcodes a Flutter version literal',
    );

    for (final job in ['app', 'build']) {
      expect(
        _job(job).join('\n'),
        contains(r'flutter-version: ${{ needs.repo.outputs.flutter_version }}'),
        reason: 'the $job job does not resolve the pin from the repo job',
      );
    }
  });

  test('no job uses a floating runner image', () {
    // Image drift moves the toolchain with no diff to review, so a build that
    // passed on Tuesday fails on Wednesday for a reason nobody can bisect.
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

  test('every step in every job has a Contract: comment above it', () {
    // The workflow's own stated rule, applied to the whole file rather than to
    // the one job that happens to comply: "a check with no contract behind it
    // is gate-sprawl and does not belong here".
    final jobs = _jobNames();
    expect(jobs, containsAll(['repo', 'app', 'build']));

    final uncontracted = <String>[];
    for (final job in jobs) {
      final comment = StringBuffer();
      for (final line in _job(job)) {
        final trimmed = line.trim();
        if (trimmed.startsWith('#')) {
          comment.writeln(trimmed);
          continue;
        }
        if (trimmed.startsWith('- ')) {
          if (!comment.toString().contains('Contract:')) {
            uncontracted.add('$job: $trimmed');
          }
          comment.clear();
          continue;
        }
        // A blank line still belongs to the comment above it; anything else
        // separates the comment from whatever follows.
        if (trimmed.isNotEmpty) comment.clear();
      }
    }

    expect(
      uncontracted,
      isEmpty,
      reason: 'each of these steps needs one sentence saying what it enforces',
    );
  });
}
