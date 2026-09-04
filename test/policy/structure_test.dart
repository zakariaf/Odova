// Policy tests over the physical shape of lib/.
//
// Layering is not a convention here, it is a gate. `lib/core` being pure Dart
// is what lets the due engine, the fuel maths and the projection test in
// milliseconds without a widget harness; feature isolation is what stops the
// twelfth screen importing the third one's private state. Neither survives
// twelve epics on good intentions.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/analysis_options_source.dart';
import '../support/source_tree.dart';

/// The seven directories `lib/` is allowed to hold, and their owners.
const _sanctioned = {
  'app', // composition root, router, service ports
  'core', // pure Dart domain — no Flutter, ever
  'data', // schema, DAOs, repositories
  'features', // one directory per feature, composition only
  'l10n', // ARB sources and the generated delegates
  'theme', // Calm tokens and ThemeData
  'ui', // the design-system component layer
};

/// Names that mean "I could not decide where this goes".
const _junkDrawers = {'utils', 'helpers', 'common', 'misc', 'shared'};

String _name(FileSystemEntity entity) => entity.path.split('/').last;

Iterable<Directory> _directoriesUnder(String path) =>
    Directory(path).listSync(recursive: true).whereType<Directory>();

void main() {
  test('lib/ contains exactly the seven sanctioned directories', () {
    final children = Directory('lib').listSync();

    // A new top-level folder is a deliberate decision. Making it here, with a
    // README naming its owner, is the whole cost of the rule.
    expect(children.whereType<Directory>().map(_name).toSet(), _sanctioned);
    expect(children.whereType<File>().map(_name).toSet(), {'main.dart'});
  });

  // `lib/core imports no Flutter` used to live here, checking three of the
  // five banned prefixes against UNSTRIPPED source. It is now one rule in one
  // place: `test/policy/core_is_pure_test.dart` (all five, comments stripped)
  // and `tools/check_core_purity.sh` (the same five, in the toolchain-free CI
  // lane). Two statements of a rule are two chances to tighten only one.

  test('test/core imports no Flutter, transitively', () {
    // The mirror of the gate above, on the test side, and it is the one that
    // actually broke. `.github/workflows/ci.yml` runs `dart test test/core` on
    // the plain VM to prove the domain layer needs no Flutter — and a shared
    // test helper that imported `flutter_test` put `dart:ui` on the import
    // graph of a file that lane compiles, which fails with `Dart library
    // 'dart:ui' is not available on this platform` and a hundred lines of
    // framework paths that say nothing about the cause.
    //
    // TRANSITIVELY, which is the whole point: the offending file imported a
    // helper, and the helper imported flutter_test. Checking only direct
    // imports would have passed.
    final offenders = <String>[];

    Set<String> reachableFrom(File file) {
      final seen = <String>{};
      final queue = <File>[file];
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        for (final uri in importUrisIn(current.readAsStringSync())) {
          if (!seen.add(uri)) continue;
          if (uri.startsWith('package:') || uri.startsWith('dart:')) continue;
          // Resolved by hand rather than with package:path, which is not a
          // declared dependency and does not become one for a test helper.
          final base = current.uri.resolve(uri);
          final resolved = File.fromUri(base);
          if (resolved.existsSync()) queue.add(resolved);
        }
      }
      return seen;
    }

    for (final file in dartFilesUnder('test/core')) {
      for (final uri in reachableFrom(file)) {
        if (uri.startsWith('package:flutter/') ||
            uri.startsWith('package:flutter_test/') ||
            uri == 'dart:ui') {
          offenders.add('${file.path} reaches $uri');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'test/core runs twice — under flutter test and under '
          '`dart test test/core` on the plain VM. The second run is what '
          'proves lib/core needs no Flutter, and anything reachable from '
          'these files that imports Flutter breaks it. Put the assertion half '
          'of a shared helper in test/support/source_gates.dart.',
    );
  });

  test('no feature imports another feature', () {
    final features = Directory(
      'lib/features',
    ).listSync().whereType<Directory>().map(_name).toList();

    final offenders = <String>[];
    for (final feature in features) {
      for (final file in dartFilesUnder('lib/features/$feature')) {
        for (final uri in importUrisIn(file.readAsStringSync())) {
          for (final other in features) {
            if (other != feature && uri.contains('features/$other/')) {
              offenders.add('${file.path} -> $uri');
            }
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'two features share code by lifting it down to core/ or data/, '
          'or they meet via a route — never by importing each other',
    );
  });

  test('no junk-drawer directory', () {
    final offenders = _directoriesUnder(
      'lib',
    ).map((d) => d.path).where((p) => _junkDrawers.contains(p.split('/').last));

    expect(
      offenders,
      isEmpty,
      reason:
          'a directory named utils/helpers/common/misc/shared is a place '
          'code goes to stop being owned by anybody',
    );
  });

  test('every lib/ directory has a mirror under test/', () {
    final excluded = excludedDirectories();
    expect(excluded, isNotEmpty, reason: 'the exclude parser found nothing');

    final unmirrored = <String>[];
    for (final directory in [
      'lib',
      ..._directoriesUnder('lib').map((d) => d.path),
    ]) {
      // Generated code is exempt for the same reason the analyzer skips it.
      if (excluded.any((e) => directory == e || directory.startsWith('$e/'))) {
        continue;
      }

      final holdsDart = Directory(
        directory,
      ).listSync().whereType<File>().any((f) => f.path.endsWith('.dart'));
      if (!holdsDart) continue;

      final mirror = directory.replaceFirst('lib', 'test');
      if (!Directory(mirror).existsSync()) unmirrored.add(mirror);
    }

    expect(
      unmirrored,
      isEmpty,
      reason:
          'code with no mirrored test directory is code nobody has decided '
          'how to test',
    );
  });

  test('every directory listed as knownEmpty really is empty', () {
    // dartFilesUnder() fails a walk that finds nothing, unless the directory is
    // on that list. A stale entry would silently disarm the gate that walks it
    // on the day the directory gains its first file.
    for (final directory in knownEmptyLibDirectories) {
      final dartFiles = Directory(directory)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      expect(
        dartFiles,
        isEmpty,
        reason:
            '$directory now holds Dart. Remove it from '
            'knownEmptyLibDirectories so the gates that walk it start '
            'asserting something.',
      );
    }
  });
}
