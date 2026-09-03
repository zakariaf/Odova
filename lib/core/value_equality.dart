// Value equality from one list, so `==` and `hashCode` cannot disagree.
//
// `dart3-idioms-and-coding-standards` wants both written for a value type. Hand
// rolling them per class means writing every field twice, and the failure is
// silent in the direction that matters: a field added to `==` and forgotten in
// `hashCode` gives two "equal" objects different hashes, which corrupts a Set
// and a Map key rather than throwing.
//
// One list, read by both. Flutter-free, so domain models stay testable without
// a harness. No package: `equatable` is a dependency for eleven lines, and
// `freezed` is a code generator for a project that already commits generated
// Drift output and does not need a second one.
import 'package:meta/meta.dart';

/// Structural equality over [props].
@immutable
mixin ValueEquality {
  /// The fields that make this value what it is, in a stable order.
  ///
  /// Include every field that a caller could distinguish. Leave out anything
  /// derived — it is a function of the others, so it can only agree.
  List<Object?> get props;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is ValueEquality &&
          valuesEqual(other.props, props);

  @override
  int get hashCode => Object.hashAll([runtimeType, ...props]);
}

/// Whether two lists hold equal values, element by element.
///
/// Public because the repositories' watch streams use it as a `distinct`
/// predicate: drift's stream invalidation is TABLE-level, so any write re-runs
/// every query over that table, and this is what turns "the query ran again"
/// into "nothing changed, do not rebuild".
bool valuesEqual(List<Object?> a, List<Object?> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
