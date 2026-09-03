// The golden comparator, set once for every test in the tree.
//
// `matchesGoldenFile` compares byte-exactly, and byte-exactness is not
// achievable across machines. On the SAME OS, two Skia builds rasterise a 1px
// hairline and a glyph edge differently: 70 of the 88 specimen goldens differ
// between the machine that authored them and a macos-15 runner, by 1 to 21
// pixels out of roughly four million — reported as 0.00%.
//
// So the comparison is bounded rather than exact. Two things make that a gate
// rather than a fudge:
//
//   * the bound is stated in the same units the failure is, and it is ~100x
//     the observed cross-machine noise and ~1000x under anything a person can
//     see. A one-shade token change moves whole regions, not twenty pixels.
//   * it has been SEEN to fail. `tools/check_goldens_selftest.sh` shifts one
//     palette value by a single step, asserts the lane goes red, and restores
//     it — the same both-arms rule every other gate in this repo is held to.
//
// CLAUDE.md §7 forbids widening a tolerance to make a failing check pass. This
// is the opposite case: an exact comparison across machines does not measure
// the design at all, and a gate that goes red for the host is a gate that gets
// switched off.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The largest fraction of differing pixels a golden may carry and still pass.
///
/// 0.05%. The observed cross-machine noise is 0.0005% at its worst.
const double kCalmGoldenTolerance = 0.0005;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  goldenFileComparator = _CalmGoldenComparator(
    (goldenFileComparator as LocalFileComparator).basedir,
  );
  await testMain();
}

class _CalmGoldenComparator extends LocalFileComparator {
  _CalmGoldenComparator(Uri basedir)
    : super(Uri.parse('${basedir}placeholder_test.dart'));

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= kCalmGoldenTolerance) {
      result.dispose();
      return true;
    }
    // Writes the actual/expected/diff triple next to the golden, which is what
    // the CI job uploads on failure.
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    // What LocalFileComparator itself throws, and what flutter_test's matcher
    // catches.
    throw FlutterError(error);
  }
}
