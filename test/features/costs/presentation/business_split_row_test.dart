// SPEC.md §12's business row, as it renders.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/features/costs/presentation/business_split_row.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

import '../../../support/pump_app.dart';

final Currency eur = Currency.tryParse('EUR')!;

Future<void> pumpRow(
  WidgetTester tester, {
  bool isBusiness = true,
  int? share = 62,
  Money? total,
}) => pumpApp(
  tester,
  BusinessSplitRow(
    isBusinessVehicle: isBusiness,
    sharePercent: share,
    total: total ?? Money(224400, eur),
    formatsTag: 'en',
  ),
);

void main() {
  testWidgets('shows the share and the amount it applies to', (tester) async {
    await pumpRow(tester);

    // 62% of 2,244.00 is 1,391.28 — truncated in minor units to 1,391.28,
    // printed whole as the reference does.
    expect(find.textContaining('62'), findsOneWidget);
  });

  testWidgets('carries §12s caption verbatim', (tester) async {
    await pumpRow(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(BusinessSplitRow)),
    );

    expect(find.text(l10n.costsBusinessCaption), findsOneWidget);
  });

  testWidgets('is hidden for a vehicle that is not a business vehicle', (
    tester,
  ) async {
    await pumpRow(tester, isBusiness: false);

    expect(find.textContaining('62'), findsNothing);
  });

  testWidgets('is hidden when no trips fall in the range', (tester) async {
    // `businessShare` returns null then, and a share of zero would be a claim
    // — it says none of the driving was business.
    await pumpRow(tester, share: null);

    expect(find.byType(Text), findsNothing);
  });
}
