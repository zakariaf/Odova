// The frame on a tablet, where the phone layout stops being a layout.
//
// `ios/Runner.xcodeproj` declares `TARGETED_DEVICE_FAMILY = "1,2"`, so the app
// runs on iPad and Apple asks for an iPad screenshot set before it will accept
// a version. Rendered as-is, that set is a phone screen stretched to 1024pt: a
// due card a thousand points wide with eight words in it, and the three cost
// tiles at three different widths because a Row with no cap distributes the
// slack unevenly.
//
// Nothing about that is a rendering bug — every widget did what it was told —
// and every one of the app's 5000-odd tests passes on it, because they all
// measure a 390pt phone. This file is the one that measures the other case.
//
// The remedy is a cap, not a tablet layout. SPEC.md has no split view, no
// sidebar and no iPad-specific screen in it, and inventing one to fill space
// would be a feature nobody asked for. A capped, centred column is the same
// design the artboards specify, drawn at the width it was designed for.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

import '../../support/pump_app.dart';

/// A 13-inch iPad in portrait, in logical pixels.
const _tablet = Size(1024, 1366);

/// The reference phone. Nothing may change at this width.
const _phone = Size(390, 844);

Future<void> _pumpAt(WidgetTester tester, Size size, {Widget? footer}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await pumpApp(
    tester,
    CalmScaffold(
      appBar: const CalmAppBar(title: 'Home'),
      footer: footer,
      children: const [Text('body')],
    ),
  );
}

void main() {
  testWidgets('the body is capped and centred on a tablet', (tester) async {
    await _pumpAt(tester, _tablet);

    final body = tester.getRect(find.byType(ListView));
    expect(
      body.width,
      lessThanOrEqualTo(kCalmMaxContentWidth),
      reason: 'the body spans the whole tablet instead of being capped',
    );
    // CENTRED, not merely narrow. A capped column pinned to the leading edge
    // is the same defect with a different silhouette, and a width assertion
    // alone passes on it.
    expect(
      body.center.dx,
      moreOrLessEquals(_tablet.width / 2, epsilon: 0.5),
      reason: 'the capped body is not centred',
    );
  });

  testWidgets('the footer is capped with the body it belongs to', (
    tester,
  ) async {
    // The pinned primary action. Left uncapped it is a 1024pt button under a
    // 640pt column, which is the most visible way a half-applied cap shows up.
    await _pumpAt(tester, _tablet, footer: const Text('Save'));

    final footer = tester.getRect(find.text('Save'));
    expect(footer.width, lessThanOrEqualTo(kCalmMaxContentWidth));
    expect(
      footer.center.dx,
      moreOrLessEquals(_tablet.width / 2, epsilon: 0.5),
    );
  });

  testWidgets('the phone is untouched', (tester) async {
    // The cap must not bind at the reference width, or all 112 parity captures
    // and every golden move at once — and they would move to something the
    // reference set does not describe.
    await _pumpAt(tester, _phone);

    expect(tester.getRect(find.byType(ListView)).width, _phone.width);
  });
}
