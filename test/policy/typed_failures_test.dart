// A Failure carries a code, never a message.
//
// `error-handling-typed-results` rule 3, and the reason it is a gate rather
// than a convention: a `String message` on a failure compiles, reads naturally
// at the call site, and produces an English sentence on an Arabic screen. It is
// invisible until somebody who does not read English opens the app.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/source_tree.dart';

void main() {
  test('no Failure subtype carries a user-facing string', () {
    // Matches a field or getter named like something a person READS. Not
    // every String on a failure is a defect — `MalformedId.offered` is the
    // input that failed to parse, which is exactly the typed param rule 3
    // asks for — so the list is the names that mean "show this to the user"
    // and not the names that mean "a string was involved". `code` is the
    // sanctioned one and is not in the list.
    final banned = RegExp(
      r'\b(?:final\s+String|String\s+get)\s+'
      r'(message|userMessage|localizedMessage|displayText|label|sentence)\b',
    );

    final offenders = <String>[];
    for (final file in dartFilesUnder('lib')) {
      final source = sourceWithoutLineComments(file);
      if (!source.contains('extends Failure')) continue;
      for (final match in banned.allMatches(source)) {
        offenders.add('${file.path}: ${match.group(1)}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a Failure with a message is a Failure that cannot be '
          'translated, mirrored or digit-shaped. Carry a code and typed '
          'params; localise at the presentation edge.',
    );
  });

  test('the spine itself is Flutter-free', () {
    // It is shared by pure domain code and by repositories, so a Flutter
    // import here would pull the widget layer into the due engine.
    final source = File('lib/core/result.dart').readAsStringSync();
    for (final uri in importUrisIn(source)) {
      expect(
        uri,
        isNot(anyOf(startsWith('package:flutter'), equals('dart:ui'))),
      );
    }
  });
}
