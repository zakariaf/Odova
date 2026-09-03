// The typed-error spine. Flutter-free, zero dependencies.
//
// `error-handling-typed-results` rules 1-4. Recoverable failures are VALUES
// that flow through the layers and are switched on exhaustively; only genuine
// bugs throw. The whole app shares one vocabulary so a pure function and a
// repository return the same shape and a caller writes one switch.
import 'package:meta/meta.dart';

/// One recoverable failure.
///
/// Carries a stable [code] and typed parameters, and NEVER a user-facing
/// string. A baked-in message cannot be translated, mirrored or digit-shaped,
/// and this app ships in six languages of which three are right-to-left — so
/// the presentation edge localises from the code and the failure stays a fact
/// about what happened.
@immutable
abstract class Failure {
  /// Creates a failure.
  const Failure();

  /// A stable identifier for this failure, unique within its family.
  ///
  /// Stable in the sense that renaming it is a breaking change: it appears in
  /// diagnostics and it is what a `switch` at the presentation edge maps to a
  /// message.
  String get code;
}

/// The outcome of an operation that can fail for a reason the caller handles.
///
/// Sealed, so a `switch` over it needs no `default:` — and adding a variant
/// becomes a compile error rather than a case that falls through silently.
sealed class Result<T, F extends Failure> {
  /// Creates a result.
  const Result();
}

/// A successful outcome.
@immutable
final class Ok<T, F extends Failure> extends Result<T, F> {
  /// Creates a successful outcome carrying [value].
  const Ok(this.value);

  /// The value.
  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T, F> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

/// A failed outcome.
@immutable
final class Err<T, F extends Failure> extends Result<T, F> {
  /// Creates a failed outcome carrying [failure].
  const Err(this.failure);

  /// Why it failed.
  final F failure;

  @override
  bool operator ==(Object other) =>
      other is Err<T, F> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err, failure);

  @override
  String toString() => 'Err($failure)';
}

/// The two combinators worth having.
///
/// Deliberately two. A larger algebra invites a chain nobody can read, and the
/// exhaustive `switch` is the idiom this codebase reaches for first.
extension ResultX<T, F extends Failure> on Result<T, F> {
  /// Collapses both arms to one type.
  R fold<R>(R Function(T value) onOk, R Function(F failure) onErr) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final failure) => onErr(failure),
      };

  /// Transforms the value, passing a failure through untouched.
  Result<R, F> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };
}
