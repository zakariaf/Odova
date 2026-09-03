import 'package:flutter/material.dart';
import 'package:odova/app/app.dart';
import 'package:odova/app/bootstrap.dart';
import 'package:odova/app/error_handlers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Order is the whole point. The sink exists, then the handlers are
  // installed, and only then does anything run that can throw — bootstrap()
  // opens files, and a crash before this line reaches nobody at all.
  const crashSink = DebugPrintCrashSink();
  installErrorHandlers(crashSink);

  final overrides = await bootstrap(crashSink: crashSink);

  runApp(OdovaRoot(overrides: overrides));
}
