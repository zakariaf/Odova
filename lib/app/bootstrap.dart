import 'package:clock/clock.dart';
// Override lives in misc.dart in Riverpod 3.x, not the root library.
import 'package:flutter_riverpod/misc.dart';
import 'package:odova/app/error_handlers.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/theme/calm/font_licences.dart';

/// Builds the real infrastructure once and returns it as provider overrides.
///
/// The composition root. Everything with a side effect — the database, the
/// clock, the crash sink, the notification scheduler — is constructed here and
/// injected; nothing constructs its own. That is what makes a fake a
/// one-line override in a test rather than a global somebody has to remember
/// to reset.
///
/// [crashSink] is the sink `main()` already installed into the error handlers,
/// passed in rather than rebuilt so the handlers and the app agree on where an
/// error goes.
///
/// This function does not install a zone. See [installErrorHandlers].
Future<List<Override>> bootstrap({required CrashSink crashSink}) async {
  // SIL OFL 1.1 obliges the licence to travel with the font. Registering is
  // lazy — the stream is only pulled if somebody opens the licences page — so
  // this costs nothing on the cold-launch path SPEC.md §17 budgets at 2.0s.
  registerFontLicences();

  return [
    crashSinkProvider.overrideWithValue(crashSink),
    clockProvider.overrideWithValue(const Clock()),
  ];
}
