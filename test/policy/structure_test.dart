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

  test('lib/core imports no Flutter', () {
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib/core')) {
      for (final uri in importUrisIn(file.readAsStringSync())) {
        if (uri.startsWith('package:flutter/') ||
            uri == 'dart:ui' ||
            uri == 'dart:io') {
          offenders.add('${file.path} -> $uri');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'lib/core is pure Dart. If it needs a BuildContext, a canvas or '
          'a filesystem, the layering is wrong and the code belongs in '
          'lib/data or lib/features.',
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
