// The whole app, in one command.
//
// 28 screens x light/dark x ltr/rtl. Every combination writes a PNG into
// `build/parity/` for `check_parity.sh` to compare against
// `design/reference/calm/`.
//
// It replaces 28 separate `<screen>_parity_test.dart` files. Those caught
// per-screen drift and nothing else — a gap that is `s4` on six screens and
// `s5` on the seventh passes every one of them, because each screen is only
// ever compared with itself.
@Tags(['parity'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'parity_screens.dart';
import 'support/parity_capture.dart';

void main() {
  setUpAll(() async {
    await loadParityFonts();
    // The output directory is CLEARED first. Without it, a capture that threw
    // after its PNG was written leaves the previous run's image on disk, and
    // both the "wrote no file" guard below and `check_parity.sh` then read a
    // screen from a build nobody made — the same shape of lie as a cancelled
    // CI run reported as green.
    final out = Directory(kParityOutDir);
    if (out.existsSync()) out.deleteSync(recursive: true);
  });

  for (final screen in kParityScreens) {
    for (final config in kParityCases) {
      testWidgets('${screen.id} ${config.theme}/${config.dir}', (tester) async {
        await screen.capture(tester, config);

        // The file, not the absence of an exception. A capture that threw
        // inside `runAsync` after the image was taken leaves no PNG and no
        // failure — `check_parity.sh` then reports the screen as missing,
        // three steps away from the test that was supposed to write it.
        final file = File(
          '$kParityOutDir/${screen.id}-${config.theme}-${config.dir}.png',
        );
        expect(file.existsSync(), isTrue, reason: 'the capture wrote no file');

        // 780x1688, which is what `tools/shoot_design.mjs` shot the references
        // at. A capture whose `physicalSize` was not pinned is a DIFFERENT
        // phone, and the band profile then differs for a reason that has
        // nothing to do with the screen — the one failure most likely to be
        // chased into the widget rather than into the harness.
        expect(
          _pngSize(file.readAsBytesSync()),
          kReferencePhysical,
          reason: 'the capture is not the reference device',
        );
      });
    }
  }
}

/// The dimensions in a PNG's IHDR, without decoding the image.
///
/// Bytes 16..24 of every PNG are width then height, big-endian. Reading them
/// directly keeps this test free of an image package and free of the async a
/// real decode needs inside `runAsync`.
Size _pngSize(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  return Size(
    data.getUint32(16).toDouble(),
    data.getUint32(20).toDouble(),
  );
}
