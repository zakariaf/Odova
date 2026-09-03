// The two things every Calm widget test does.
//
// Both were written eleven and three times respectively before they were
// written once. The cost of the copies was not the lines: each one hard-coded
// WHICH container widget the implementation happens to paint through, so a
// `DecoratedBox` that later gains an `AnimatedContainer` wrapper fails with a
// cast error rather than a colour mismatch — a failure that says nothing about
// what changed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The first decoration painted inside [of], whatever widget carries it.
///
/// Matches `DecoratedBox`, `Container` and `AnimatedContainer` alike, so an
/// assertion says "this surface is `surface2`" rather than "this surface is
/// `surface2` and is painted by an AnimatedContainer".
D calmDecorationOf<D extends Decoration>(WidgetTester tester, Finder of) {
  for (final widget in tester.widgetList(
    find.descendant(of: of, matching: find.byWidgetPredicate(_paints)),
  )) {
    final decoration = switch (widget) {
      DecoratedBox() => widget.decoration,
      Container() => widget.decoration,
      AnimatedContainer() => widget.decoration,
      _ => null,
    };
    if (decoration is D) return decoration;
  }
  throw StateError('no $D painted inside ${of.describeMatch(Plurality.one)}');
}

bool _paints(Widget w) =>
    w is DecoratedBox || w is Container || w is AnimatedContainer;

/// The focus ring's shape, or null when nothing is focused.
///
/// `CalmPressable` draws it as a `ShapeDecoration` with a stroked
/// `OutlinedBorder` — a `StadiumBorder` above the pill sentinel, a
/// `RoundedRectangleBorder` below it. Returning the SHAPE rather than the side
/// lets a caller assert either; `calmFocusRing(tester)?.side` is the stroke.
OutlinedBorder? calmFocusRing(WidgetTester tester) {
  for (final box in tester.widgetList<DecoratedBox>(
    find.byType(DecoratedBox),
  )) {
    final decoration = box.decoration;
    if (decoration is ShapeDecoration && decoration.shape is OutlinedBorder) {
      final shape = decoration.shape as OutlinedBorder;
      if (shape.side != BorderSide.none) return shape;
    }
  }
  return null;
}
