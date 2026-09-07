// The 48pt floor, and the harness that enforces it.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y_harness.dart';

void main() {
  testWidgets('a 24pt target fails', (tester) async {
    await pumpA11y(
      tester,
      const A11yCase(),
      // CENTRED. A bare SizedBox is stretched by the scaffold, so the
      // semantics node is the full viewport and the assertion passes on a
      // target that is genuinely 24pt on screen.
      Center(
        child: Semantics(
          label: 'Delete',
          button: true,
          child: GestureDetector(
            onTap: () {},
            child: const SizedBox(width: 24, height: 24),
          ),
        ),
      ),
    );

    await expectLater(expectTapTargets(tester), throwsA(isA<TestFailure>()));
  });

  testWidgets('a 48pt target passes', (tester) async {
    await pumpA11y(
      tester,
      const A11yCase(),
      Center(
        child: Semantics(
          label: 'Delete',
          button: true,
          child: GestureDetector(
            onTap: () {},
            child: const SizedBox(width: 48, height: 48),
          ),
        ),
      ),
    );

    await expectTapTargets(tester);
  });

  testWidgets('a wide but short target still fails', (tester) async {
    // Height and width are both floors, not an area. A 60x18 link is easy to
    // hit horizontally and easy to miss vertically, and vertical is the axis a
    // thumb is worst at.
    await pumpA11y(
      tester,
      const A11yCase(),
      Center(
        child: Semantics(
          label: 'Terms of use',
          button: true,
          child: GestureDetector(
            onTap: () {},
            child: const SizedBox(width: 60, height: 18),
          ),
        ),
      ),
    );

    await expectLater(expectTapTargets(tester), throwsA(isA<TestFailure>()));
  });
}
