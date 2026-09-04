// The typed-error spine every boundary in the app shares.
//
// `error-handling-typed-results` rule 1: anything that fails for a runtime
// reason the caller must handle returns a value, not an exception. Rule 3: a
// failure carries a stable CODE and typed params, never a user-facing string —
// a baked-in message cannot be translated, mirrored or shaped, and this app
// ships in six languages, three of them right-to-left.
import 'package:odova/core/result.dart';
import 'package:test/test.dart';

/// A failure family for the test, standing in for a real boundary's.
sealed class _TestFailure extends Failure {
  const _TestFailure();
}

final class _NotFound extends _TestFailure {
  const _NotFound(this.id);
  final String id;
  @override
  String get code => 'not_found';
}

final class _Busy extends _TestFailure {
  const _Busy();
  @override
  String get code => 'busy';
}

void main() {
  test('Ok carries the value and Err carries the failure', () {
    const ok = Ok<int, _TestFailure>(7);
    const err = Err<int, _TestFailure>(_NotFound('veh_1'));

    expect(ok.value, 7);
    expect(err.failure, isA<_NotFound>());
  });

  test('a switch over Result needs no default', () {
    // The point of `sealed`. Adding a third variant would make this a compile
    // error rather than a case that silently falls through, which is the only
    // compiler-grade safety net in the error path.
    String describe(Result<int, _TestFailure> r) => switch (r) {
      Ok(:final value) => 'ok $value',
      Err(:final failure) => 'err ${failure.code}',
    };

    expect(describe(const Ok(7)), 'ok 7');
    expect(describe(const Err(_Busy())), 'err busy');
  });

  test('a failure carries a code and typed params, never a message', () {
    // Rule 3. The presentation edge localises FROM the code; if a `String
    // message` lived here, five translators could not reach it and an Arabic
    // user would read English.
    const failure = _NotFound('veh_1');
    expect(failure.code, 'not_found');
    expect(failure.id, 'veh_1');

    // `code` is what a caller switches on and what the presentation edge
    // localises from. The rule that no subtype adds a `String message` is a
    // source-level gate — test/policy/typed_failures_test.dart — because Dart
    // cannot ask a type what fields it has without mirrors.
  });

  test('fold collapses both arms to one type', () {
    int lengthOf(Result<String, _TestFailure> r) =>
        r.fold((v) => v.length, (f) => -1);

    expect(lengthOf(const Ok('abcd')), 4);
    expect(lengthOf(const Err(_Busy())), -1);
  });

  test('map transforms Ok and passes Err through untouched', () {
    const err = Err<int, _TestFailure>(_Busy());
    expect((const Ok<int, _TestFailure>(3).map((v) => v * 2) as Ok).value, 6);
    expect((err.map((v) => v * 2) as Err).failure, isA<_Busy>());
  });

  test('two failures of the same shape are equal', () {
    // So a test can assert on the failure it expects rather than on its
    // runtime type, and so a Riverpod state holding one does not rebuild on
    // every identical error.
    expect(const _NotFound('veh_1'), const _NotFound('veh_1'));
    expect(const _NotFound('veh_1'), isNot(const _NotFound('veh_2')));
  });
}
