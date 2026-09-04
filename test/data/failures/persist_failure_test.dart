// The failure family, and the one property a compiler can guarantee.
//
// `error-handling-typed-results` rule 4: switch exhaustively with NO
// `default:`. That is not a style preference — it is the only compiler-grade
// safety net in the error path. Adding a variant becomes a compile error at
// every call site, instead of a case that falls silently into a generic
// "something went wrong" that no user can act on.
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:test/test.dart';

/// A switch over every variant, with no `default:`.
///
/// This function IS the test. If a variant is added to `PersistFailure` and not
/// added here, this file stops compiling — which is what "exhaustive" buys.
String describe(PersistFailure failure) => switch (failure) {
  WriteFailed(:final detail) => 'write:$detail',
  ConstraintViolated(:final constraint) => 'constraint:$constraint',
  NotFound(:final id) => 'not_found:$id',
  OdometerWouldGoBackwards(:final previousCumulativeM) =>
    'backwards:$previousCumulativeM',
  DerivedReadingNotEditable(:final source) => 'derived:$source',
  OrphanReference(:final field) => 'orphan:$field',
  // Added in task 5.11, and the analyzer refused to compile this file until it
  // was — which is the whole value of a sealed switch with no `default:`. A
  // `default:` here would have silently mapped a read-only store to whatever
  // generic message the last case produced.
  StoreReadOnly(:final atVersion) => 'read_only:$atVersion',
};

void main() {
  const all = <PersistFailure>[
    WriteFailed('disk full'),
    ConstraintViolated('currency length'),
    NotFound('veh_1'),
    OdometerWouldGoBackwards(
      previousCumulativeM: 180000000,
      previousOccurredOn: '2026-01-01',
      attemptedCumulativeM: 170000000,
    ),
    DerivedReadingNotEditable(readingId: 'odo_1', source: 'fillup'),
    OrphanReference(field: 'vehicle_id', target: 'veh_gone'),
    StoreReadOnly(atVersion: 1, expectedVersion: 2),
  ];

  test('every variant has a distinct, stable code', () {
    // The code is what the presentation edge switches on to choose a message,
    // and what a diagnostics log carries. Two variants sharing one would make
    // them indistinguishable to both.
    final codes = all.map((f) => f.code).toList();
    expect(codes.toSet(), hasLength(codes.length));
    for (final code in codes) {
      expect(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(code), isTrue, reason: code);
    }
  });

  test('the exhaustive switch covers all of them', () {
    for (final failure in all) {
      expect(describe(failure), isNotEmpty);
    }
  });

  test('two failures of the same shape are equal', () {
    // So a test asserts on the failure it expects rather than on a runtime
    // type, and so a Riverpod state holding one does not rebuild on every
    // identical error.
    expect(const NotFound('veh_1'), const NotFound('veh_1'));
    expect(const NotFound('veh_1'), isNot(const NotFound('veh_2')));
    expect(
      const OdometerWouldGoBackwards(
        previousCumulativeM: 1,
        previousOccurredOn: '2026-01-01',
        attemptedCumulativeM: 0,
      ),
      const OdometerWouldGoBackwards(
        previousCumulativeM: 1,
        previousOccurredOn: '2026-01-01',
        attemptedCumulativeM: 0,
      ),
    );
  });

  test('a backwards-odometer failure carries what the UI has to say', () {
    // SPEC.md §3 offers three resolutions — fix the typo, record a
    // correction, accept it as backdated — and the copy for all three names
    // the conflicting reading AND its date. A failure that carried only a code
    // would leave the user with "that number is wrong" and nothing else.
    const failure = OdometerWouldGoBackwards(
      previousCumulativeM: 180000000,
      previousOccurredOn: '2026-01-01',
      attemptedCumulativeM: 170000000,
    );

    expect(failure.previousCumulativeM, 180000000);
    expect(failure.previousOccurredOn, '2026-01-01');
    expect(failure.attemptedCumulativeM, 170000000);
  });

  test('every variant is a Failure and therefore usable in a Result', () {
    for (final failure in all) {
      expect(failure, isA<Failure>());
      expect(
        Err<int, PersistFailure>(failure),
        isA<Err<int, PersistFailure>>(),
      );
    }
  });
}
