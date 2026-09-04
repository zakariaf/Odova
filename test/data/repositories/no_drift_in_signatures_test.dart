// No Drift type reaches a repository's public signature.
//
// `tools/check_drift_confinement.sh` proves no file above `lib/data/` IMPORTS
// drift. This proves the other half, which the grep cannot see: that nothing
// inside `lib/data/` hands a Drift type UP. A repository returning a
// `VehicleRow` compiles, passes the confinement gate — the caller never writes
// the import, it comes through the return type — and makes every screen and
// every test above the data layer need a database to exist.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import '../../support/source_tree.dart';

/// The Drift shapes that must not appear in a signature.
///
/// The generated names are matched by SUFFIX rather than listed: a table added
/// in a later task produces `FooRow`, `FooCompanion` and `$FooTable` without
/// anybody editing this test.
/// A generated table class is `$FooTable`, and `$` is not a word character —
/// so a leading `\b` before it never matches after a space. It sits outside
/// the word-bounded group for that reason, which the guard test below is what
/// found.
final _driftShapes = RegExp(
  // The @DataClassName this repo gives every table, plus drift's own shapes.
  r'[$]\w*Table'
  r'|\b('
  r'\w*Companion|\w*Row|TableInfo|QueryRow'
  '|Selectable|SimpleSelectStatement|GeneratedColumn|Value'
  r')\b',
);

/// The signature of every PUBLIC member of a PUBLIC class in [source].
///
/// Block-based rather than line-based, because `dart format` wraps a long
/// signature across several lines and a line scanner then sees a return type
/// on one line and a name on the next — which is how the first version of this
/// test reported three private helpers as public API. A signature runs from a
/// declaration at two-space indent to the first `{`, `=>` or `;`.
Iterable<String> publicMemberSignatures(String source) sync* {
  final lines = source.split('\n');
  // Null until the first class. A top-level function's WRAPPED parameter list
  // is indented two spaces and looks exactly like a member declaration, so
  // `watch.dart` — which has no class at all and legitimately takes a
  // `Selectable` — reported three violations. The rule is about what a
  // REPOSITORY exposes; a file with no class exposes no members.
  bool? inPublicClass;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    final classMatch = RegExp(
      r'^(?:final |abstract |sealed |base |interface )*class (\w+)',
    ).firstMatch(line);
    if (classMatch != null) {
      inPublicClass = !classMatch.group(1)!.startsWith('_');
      continue;
    }
    if (inPublicClass != true) continue;

    // A member declaration starts at exactly two spaces of indent.
    if (!RegExp(r'^  \S').hasMatch(line)) continue;
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//') || trimmed.startsWith('@')) continue;
    // A wrapped argument list closes at two-space indent too: `) => Foo(`.
    // That is a continuation, not a declaration.
    if (RegExp(r'^[)\]},]').hasMatch(trimmed)) continue;

    // Accumulate to the end of the signature.
    final buffer = StringBuffer(line);
    var end = i;
    while (end < lines.length - 1 &&
        !RegExp(r'(\{|=>|;)\s*$').hasMatch(lines[end])) {
      end++;
      buffer.write(' ${lines[end].trim()}');
    }

    // Truncate at the body. An expression-bodied member wraps as
    // `watchAll() => watchList(` — the `=>` is not at the end of a line, so
    // accumulating to the terminator swallowed the whole body and matched
    // every Drift type inside it.
    var signature = buffer.toString();
    final body = RegExp(r'=>|\{').firstMatch(signature);
    if (body != null) signature = signature.substring(0, body.start);
    // Private members are internal to the data layer and may hold a row type.
    if (RegExp(r'\b_\w+\s*[(<=]').hasMatch(signature)) continue;
    yield signature;
  }
}

void main() {
  test('no repository exposes a Drift type', () {
    final offenders = <String>[];

    for (final file in dartFilesUnder('lib/data/repositories')) {
      final source = sourceWithoutLineComments(file);
      for (final signature in publicMemberSignatures(source)) {
        final match = _driftShapes.firstMatch(signature);
        if (match != null) {
          offenders.add('${file.path}: ${signature.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a Drift type in a public signature makes every caller need a '
          'database. Map rows to the models in lib/core/domain/models/.',
    );
  });

  test('a top-level function is not read as a class member', () {
    // `watch.dart` has no class and legitimately takes a `Selectable` — it is
    // the shared query helper INSIDE the data layer, not something handing a
    // row type upward. Its wrapped parameter list is indented two spaces and
    // looked exactly like a member declaration.
    const source = '''
Stream<List<T>> watchList<R, T>(
  Selectable<R> rows,
  T Function(R row) toModel,
) => rows.watch();
''';
    expect(publicMemberSignatures(source), isEmpty);
  });

  test('an expression body is not read as part of the signature', () {
    // `watchAll() => watchList(` puts the `=>` mid-line, so accumulating to
    // the terminator swallowed the whole body and matched every Drift type
    // inside it.
    const source = '''
class Repository {
  Stream<List<Vehicle>> watchAll() => watchList(
    _db.select(_db.vehicles)..orderBy([(v) => OrderingTerm(expression: v.id)]),
    vehicleFromRow,
  );
}
''';
    final signature = publicMemberSignatures(source).single;
    expect(signature, contains('watchAll'));
    expect(signature, isNot(contains('OrderingTerm')));
  });

  test('a wrapped private signature is not read as public API', () {
    // The bug the first version of this file had: `dart format` breaks a long
    // return type onto its own line, so a line scanner saw
    // `SimpleSelectStatement<$OdometerReadingsTable, OdometerReadingRow>` with
    // no name attached and reported a private helper as public API.
    const source = r'''
class Repository {
  Stream<List<FillUp>> watchForVehicle(VehicleId id) => throw '';

  SimpleSelectStatement<$FillUpsTable, FillUpRow>
  _query(VehicleId id) => throw '';

  FillUpsCompanion _companionFor(FillUp f) => throw '';
}

class _State {
  final Map<String, FillUpRow> rowsById = const {};
}
''';

    final signatures = publicMemberSignatures(source).toList();
    expect(signatures, hasLength(1));
    expect(signatures.single, contains('watchForVehicle'));
  });

  test('the matcher recognises the shapes it claims to', () {
    // Guard the guard. This test greps for patterns, and a pattern that
    // matches nothing passes over a file full of violations.
    for (final signature in [
      '  Future<VehicleRow> findById(String id);',
      '  VehiclesCompanion companionFor(Vehicle v);',
      r'  $VehiclesTable get table;',
      '  Selectable<int> countAll();',
    ]) {
      expect(
        _driftShapes.hasMatch(signature),
        isTrue,
        reason: signature,
      );
    }

    // And does not fire on the domain types that are the whole point.
    for (final signature in [
      '  Future<Result<Vehicle, PersistFailure>> save(Vehicle vehicle);',
      '  Stream<List<FillUp>> watchForVehicle(VehicleId vehicleId);',
    ]) {
      expect(_driftShapes.hasMatch(signature), isFalse, reason: signature);
    }
  });

  test('the walk visited every repository', () {
    // A gate that visits zero files passes while proving nothing.
    final files = dartFilesUnder('lib/data/repositories');
    expect(files, hasLength(greaterThanOrEqualTo(4)));
  });
}
