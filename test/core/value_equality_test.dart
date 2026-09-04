// One list, read by both halves.
//
// The failure this exists to prevent is silent in the direction that matters: a
// field added to `==` and forgotten in `hashCode` gives two "equal" objects
// different hashes, which corrupts a Set and a Map key rather than throwing.
import 'package:odova/core/value_equality.dart';
import 'package:test/test.dart';

class _Point with ValueEquality {
  _Point(this.x, this.y, {this.label});
  final int x;
  final int y;
  final String? label;

  @override
  List<Object?> get props => [x, y, label];
}

/// Deliberately the SAME props list as [_Point], length included.
///
/// A first version of this class had two props against _Point's three, so
/// `_listEquals` returned false on the length alone and the runtimeType check
/// could be deleted without the test noticing. That is the shape of test the
/// TDD rule exists to catch: it passed, it was named for the right thing, and
/// it asserted nothing.
class _OtherPoint with ValueEquality {
  _OtherPoint(this.x, this.y, this.label);
  final int x;
  final int y;
  final String? label;

  @override
  List<Object?> get props => [x, y, label];
}

void main() {
  test('same props means equal, and equal means same hash', () {
    expect(_Point(1, 2), _Point(1, 2));
    expect(_Point(1, 2).hashCode, _Point(1, 2).hashCode);
  });

  test('a different value in any position is not equal', () {
    expect(_Point(1, 2), isNot(_Point(1, 3)));
    expect(_Point(1, 2, label: 'a'), isNot(_Point(1, 2, label: 'b')));
    expect(_Point(1, 2), isNot(_Point(1, 2, label: 'a')));
  });

  test('a null in the list is a value, not an absence', () {
    // `[1, 2, null]` and `[1, 2]` must not collapse to the same thing, or an
    // optional field silently stops mattering.
    expect(_Point(1, 2), _Point(1, 2));
    expect(_Point(1, 2).props, hasLength(3));
    expect(_Point(1, 2).props.last, isNull);
  });

  test('two different types with identical props are not equal', () {
    // Without the runtimeType check, a Vehicle and a Trip with the same three
    // leading fields would compare equal — and a Map keyed on either would
    // return the other one.
    final a = _Point(1, 2);
    final b = _OtherPoint(1, 2, null);
    // `Object` on both sides: the analyzer flags `_Point == _OtherPoint` as
    // an unrelated-type comparison, which is exactly the mistake this test
    // asserts the mixin does not make.
    expect(a == (b as Object), isFalse);
    expect(b == (a as Object), isFalse);
    expect(a.hashCode, isNot(b.hashCode));
  });

  test('a value works as a Set member and a Map key', () {
    // The actual consequence of == and hashCode disagreeing, asserted rather
    // than described.
    final set = {_Point(1, 2), _Point(1, 2), _Point(3, 4)};
    expect(set, hasLength(2));

    final map = {_Point(1, 2): 'a'};
    expect(map[_Point(1, 2)], 'a');
  });

  test('identical is the fast path and still correct', () {
    final point = _Point(1, 2);
    expect(point == point, isTrue);
  });
}
