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
  await loadVazirmatn(alsoAs: const ['Roboto']);
}

/// Registers the app's one bundled face, and optionally under other names.
///
/// [alsoAs] exists for the golden lane's Vazirmatn-as-Roboto substitution; the
/// parity lane wants the real Roboto and so passes nothing.
Future<void> loadVazirmatn({List<String> alsoAs = const []}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = await File('assets/fonts/Vazirmatn[wght].ttf').readAsBytes();
  for (final family in ['Vazirmatn', ...alsoAs]) {
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}

/// Registers a font family from the Flutter SDK's own cache.
///
/// Returns false when the file is not there, which is a real possibility on a
/// machine that has never run `flutter precache`. The caller decides whether
/// that is fatal.
Future<bool> loadSdkFont(String family, String fileName) async {
  final file = File(
    '${flutterRoot()}/bin/cache/artifacts/material_fonts/$fileName',
  );
  if (!file.existsSync()) return false;
  final bytes = await file.readAsBytes();
  await (FontLoader(
    family,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  return true;
}

/// Where the Flutter SDK is installed.
///
/// `FLUTTER_ROOT` first, because that is what CI sets; otherwise four
/// directories up from the Dart binary, which lives in the SDK's own cache.
String flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) return env;
  return File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
}
