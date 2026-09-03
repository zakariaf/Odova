import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers the app's bundled fonts so a golden renders glyphs.
///
/// Written here rather than taken from `golden_toolkit`: that package is
/// discontinued, and `dependency-hygiene` will not take a dependency for
/// fifteen lines. Vazirmatn is the only family Odova bundles — SPEC.md §5 puts
/// `en`, `de` and `fr` on the platform font — so the Latin specimens render in
/// the test font, which is deterministic and which is what a golden needs. The
/// RTL specimens render in the real face, which is the half that has glyph
/// joining to get wrong.
/// It is registered TWICE: once as `Vazirmatn`, which is what
/// `CalmType.arabicScript` asks for, and once as `Roboto`, which is what an
/// unnamed style resolves to in a test. Without the second registration every
/// Latin string renders in the test's fallback face, whose glyphs are square
/// ems — roughly twice as wide as any real font — and an overflow matrix run
/// against it is measuring a font nobody ships. It reports failures the design
/// does not have and would force the layout to be redrawn around them.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = await File('assets/fonts/Vazirmatn[wght].ttf').readAsBytes();
  for (final family in ['Vazirmatn', 'Roboto']) {
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}
