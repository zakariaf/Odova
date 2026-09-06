// The panel a mark-done save shows instead of dismissing.
//
// SPEC.md §10: "A panel and not a snackbar because both the resulting due date
// and the due odometer have to be visible."
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/logging/ui/service_confirmation_panel.dart';

import '../../../support/pump_app.dart';

Future<void> _pump(
  WidgetTester tester, {
  String? nextOdometer,
  String? nextDate,
}) => pumpApp(
  tester,
  ServiceConfirmationPanel(
    itemLabel: 'Oil and filter',
    facts: '2 September 2026 · 187,412 km · 92.50 €',
    nextOdometer: nextOdometer,
    nextDate: nextDate,
    onClose: () {},
  ),
);

void main() {
  testWidgets('names the item, the facts and BOTH halves of the pair', (
    tester,
  ) async {
    await _pump(tester, nextOdometer: '197,412 km', nextDate: 'September 2027');

    expect(find.textContaining('Oil and filter'), findsWidgets);
    expect(find.textContaining('187,412 km'), findsOneWidget);
    expect(find.textContaining('197,412 km'), findsOneWidget);
    expect(find.textContaining('September 2027'), findsOneWidget);
  });

  testWidgets('a distance-only item names one axis', (tester) async {
    // §10 forbids inventing the other: a date for an item with no month
    // interval would be a fact the app made up, and this panel is where a user
    // reads the consequence as a promise.
    await _pump(tester, nextOdometer: '197,412 km');

    expect(find.textContaining('197,412 km'), findsOneWidget);
    expect(find.textContaining('whichever'), findsNothing);
  });

  testWidgets('a time-only item names the other', (tester) async {
    await _pump(tester, nextDate: 'September 2027');

    expect(find.textContaining('September 2027'), findsOneWidget);
    expect(find.textContaining('whichever'), findsNothing);
  });

  testWidgets('an item with neither axis shows no next-due line at all', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.textContaining('Next due'), findsNothing);
  });

  testWidgets('a fuzzy projection is passed through, not re-rendered', (
    tester,
  ) async {
    // §10: "if the projection's confidence is not `measured`, the projected
    // half is fuzzy — 'around September 2027' — and never an exact date." The
    // fuzzing is the CALLER's, so the panel cannot accidentally sharpen it.
    await _pump(tester, nextDate: 'around September 2027');

    expect(find.textContaining('around September 2027'), findsOneWidget);
  });
}
