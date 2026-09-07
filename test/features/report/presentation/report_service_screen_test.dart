// SPEC.md §12's `report.service`, as the seller meets it.
//
// "The preview IS the document, rendered as native list rows, and the toggles
// change it live. A PDF viewer in the app would be a second renderer to keep in
// sync with the first."
//
// So the tests below are not about a preview WIDGET. They are about whether
// what is on screen is the same thing that will be in the file — which is why
// the toggle tests assert on the preview's content and not on a switch's
// state.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/app/share/share_service.dart';
import 'package:odova/core/result.dart';
import 'package:odova/features/report/application/report_notifier.dart';
import 'package:odova/features/report/presentation/report_service_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_chip.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../support/device.dart';
import '../../../support/report_fake_repository.dart';
import '../../home/home_fixture.dart';

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(ReportServiceScreen)));

/// A share port that records instead of sharing.
///
/// Held at library scope so a test can assert on what the SCREEN handed it —
/// the point being that the button reaches the port at all.
class _SpyShare implements ShareService {
  final List<({String fileName, String mimeType, int bytes})> shared = [];

  @override
  Future<Result<void, ShareFailure>> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    shared.add((
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes.length,
    ));
    return const Ok(null);
  }

  @override
  Future<Result<void, ShareFailure>> shareWrittenFile({
    required File file,
    required String mimeType,
  }) async {
    // §12's report renders to bytes in memory and never takes this path. The
    // backup export does (EPIC-15 task 15.5); a fake that quietly returned Ok
    // here would be a fake that lies about the port it implements.
    fail('the report shares bytes, never a written file');
  }

  @override
  Future<Result<void, ShareFailure>> discard() async => const Ok(null);
}

/// Typed as the fake rather than `ShareService`: the assertions are about
/// what it RECORDED, and the interface has no `shared` list to read.
// ignore: library_private_types_in_public_api
late _SpyShare shareSpy;

Future<void> _pump(
  WidgetTester tester, {
  int services = 3,
  Locale? locale = const Locale('en'),
}) async {
  tester.useDevice(Device.tallForm);
  await pumpShell(
    tester,
    Routes.serviceReport,
    locale: locale,
    settings: homeSettings(golfId),
    vehicles: [homeVehicle(golfId, 'The Golf')],
    overrides: <Override>[
      reportRepositoryProvider.overrideWithValue(
        FakeReportRepository(serviceCount: services),
      ),
      shareServiceProvider.overrideWithValue(shareSpy = _SpyShare()),
    ],
  );
  await tester.pumpAndSettle();
}

Finder _chip(WidgetTester tester, String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(CalmChip),
);

bool _selected(WidgetTester tester, String label) =>
    tester.widget<CalmChip>(_chip(tester, label)).selected;

void main() {
  testWidgets('the screen is reachable and titled', (tester) async {
    await _pump(tester);

    expect(find.byType(ReportServiceScreen), findsOneWidget);
    expect(find.text(_l10n(tester).reportTitle), findsWidgets);
  });

  testWidgets('Costs and Fuel summary start on; Plate/VIN and notes start off', (
    tester,
  ) async {
    // §12's defaults, and the two that are OFF are the ones that matter: "the
    // identity fields are the buyer's to ask for, not the app's to leak into a
    // group chat."
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(_selected(tester, l10n.reportToggleCosts), isTrue);
    expect(_selected(tester, l10n.reportToggleFuel), isTrue);
    expect(_selected(tester, l10n.reportTogglePlateVin), isFalse);
    expect(_selected(tester, l10n.reportToggleNotes), isFalse);
  });

  testWidgets('the notes warning is shown BEFORE the toggle is turned on', (
    tester,
  ) async {
    // A warning that appears only after the switch is flipped is a warning
    // shown after the decision it was meant to inform.
    await _pump(tester);

    expect(find.text(_l10n(tester).reportNotesWarning), findsOneWidget);
  });

  testWidgets('toggling Costs off removes the money in the same frame', (
    tester,
  ) async {
    // §12: "the toggles change it live." Not after a rebuild, not after a
    // round-trip — the preview is the document, and a preview that lags is a
    // preview that is briefly lying about what the file will contain.
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.textContaining('€'), findsWidgets);

    await tester.tap(_chip(tester, l10n.reportToggleCosts));
    await tester.pump();

    expect(find.textContaining('€'), findsNothing);
    expect(_selected(tester, l10n.reportToggleCosts), isFalse);
  });

  testWidgets('turning Plate and VIN on puts them in the preview', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.text(kFakePlate), findsNothing);

    await tester.tap(_chip(tester, l10n.reportTogglePlateVin));
    await tester.pump();

    expect(find.text(kFakePlate), findsOneWidget);
  });

  testWidgets('the footer is on screen and cannot be toggled away', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    Finder footer() => find.textContaining('Not verified by a third party');
    expect(footer(), findsOneWidget);

    for (final label in [
      l10n.reportToggleCosts,
      l10n.reportToggleFuel,
      l10n.reportTogglePlateVin,
      l10n.reportToggleNotes,
    ]) {
      await tester.tap(_chip(tester, label));
      await tester.pump();
    }

    expect(footer(), findsOneWidget, reason: '§12 calls it unremovable');
  });

  testWidgets(
    'with no services the header still renders and Share is disabled',
    (tester) async {
      // §12: "Header card still renders. Preview replaced… Share PDF disabled,
      // reason under it, not in a toast."
      await _pump(tester, services: 0);
      final l10n = _l10n(tester);

      expect(find.text('The Golf'), findsWidgets, reason: 'header survives');
      expect(find.text(l10n.reportEmptyTitle), findsOneWidget);

      final share = tester.widget<CalmButton>(
        find.ancestor(
          of: find.text(l10n.reportSharePdf),
          matching: find.byType(CalmButton),
        ),
      );
      expect(share.onPressed, isNull);
      expect(share.disabledBecause, l10n.reportShareDisabledReason);
      expect(
        find.text(l10n.reportShareDisabledReason),
        findsOneWidget,
        reason: 'under the button, not in a toast',
      );
    },
  );

  testWidgets('one record is a full document with no apology', (tester) async {
    // §12: "No apology: one documented cambelt change is worth printing."
    await _pump(tester, services: 1);

    expect(find.text(_l10n(tester).reportEmptyTitle), findsNothing);
  });

  testWidgets('over 200 records the preview is virtualised', (tester) async {
    // Asserts the BUILT row count, not the model's. A `Column` of 400 rows
    // renders every one of them off-screen and janks the screen §12 says is
    // opened "at the moment of highest stakes and lowest patience".
    await _pump(tester, services: 400);

    // `ListView.builder` builds a viewport's worth plus a cache extent. Four
    // hundred would mean a `Column`, which builds every row off screen.
    expect(
      tester.widgetList(find.byType(ReportRecordRow)).length,
      lessThan(60),
      reason: 'a viewport of rows, not four hundred of them',
    );
  });

  testWidgets('it mirrors in Persian without a layout overflow', (
    tester,
  ) async {
    await _pump(tester, locale: const Locale('fa'));

    expect(
      Directionality.of(tester.element(find.byType(ReportServiceScreen))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Share PDF and Copy as text are actually wired', (tester) async {
    // The defect this exists to catch: both actions shipped as `() {}` under a
    // commit titled "wire Share PDF and Copy as text". The notifier tests
    // drove the notifier directly, so a dead primary action on §12's most
    // important screen was invisible to the whole suite.
    //
    // Asserting the callback is NON-NULL is not enough — `() {}` is non-null.
    // So this taps them and asserts the effect: the share port receives a
    // file, and the clipboard receives the document.
    await _pump(tester);
    final l10n = _l10n(tester);

    final share = tester.widget<CalmButton>(
      find.ancestor(
        of: find.text(l10n.reportSharePdf),
        matching: find.byType(CalmButton),
      ),
    );
    expect(share.onPressed, isNotNull);
    // Invoked directly. The button lives in the scaffold's footer under a
    // bottom inset, so a hit-test tap is fragile here — and what this test is
    // about is whether the CALLBACK reaches the port, not whether the footer
    // is hittable, which the parity capture covers.
    share.onPressed!();
    await tester.pumpAndSettle();

    expect(
      shareSpy.shared,
      hasLength(1),
      reason: 'the button reached the share port',
    );
    expect(shareSpy.shared.single.mimeType, 'application/pdf');
  });

  testWidgets('Copy as text puts the document on the clipboard', (
    tester,
  ) async {
    await _pump(tester);

    final copied = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') copied.add(call);
        return null;
      },
    );

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(copied, hasLength(1));
    final text =
        (copied.single.arguments as Map<Object?, Object?>)['text']! as String;
    expect(text, contains('The Golf'));
    expect(
      text,
      contains('Bosch Car Service'),
      reason: 'the RECORDS, not just the header',
    );
  });
}
