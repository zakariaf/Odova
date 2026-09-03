// The cold-launch error net.
//
// SPEC.md §2: data survives app updates. The first thing that will ever throw
// on the startup path is opening the database, and a crash before the handlers
// are installed is invisible forever — no log, no screen, no report, because
// there is no server to send one to.
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/error_handlers.dart';

/// A sink that records what it was handed.
class _RecordingSink implements CrashSink {
  final entries = <String>[];

  @override
  void write(String entry) => entries.add(entry);
}

/// A sink that fails the way a full disk does.
class _ThrowingSink implements CrashSink {
  @override
  void write(String entry) => throw const FileSystemException('disk full');
}

void main() {
  late FlutterExceptionHandler? originalFlutterOnError;
  late ErrorCallback? originalPlatformOnError;

  setUp(() {
    originalFlutterOnError = FlutterError.onError;
    originalPlatformOnError = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    FlutterError.onError = originalFlutterOnError;
    PlatformDispatcher.instance.onError = originalPlatformOnError;
  });

  test('installErrorHandlers sets both FlutterError.onError and '
      'PlatformDispatcher.onError', () {
    FlutterError.onError = FlutterError.presentError;
    PlatformDispatcher.instance.onError = null;

    installErrorHandlers(_RecordingSink());

    expect(FlutterError.onError, isNotNull);
    expect(
      FlutterError.onError,
      isNot(same(FlutterError.presentError)),
      reason: 'the framework default only prints; nothing reaches the sink',
    );
    expect(PlatformDispatcher.instance.onError, isNotNull);
  });

  test('PlatformDispatcher.onError returns true unconditionally', () {
    installErrorHandlers(_RecordingSink());

    // Returning false routes the error to the embedder fallback, where the
    // process may exit or hang. There is nothing upstream of us that handles
    // it better, so we always claim it.
    expect(
      PlatformDispatcher.instance.onError!(StateError('x'), StackTrace.empty),
      isTrue,
    );
  });

  test(
    'an error handler that is handed a throwing sink does not itself throw',
    () {
      installErrorHandlers(_ThrowingSink());

      // Without the bare catch inside the handler, the handler's own failure is
      // reported through the handler, which reports it through the handler.
      expect(
        () => PlatformDispatcher.instance.onError!(
          StateError('x'),
          StackTrace.empty,
        ),
        returnsNormally,
      );
      expect(
        () => FlutterError.onError!(
          FlutterErrorDetails(exception: StateError('x')),
        ),
        returnsNormally,
      );
    },
  );

  test('the sink is handed the underlying error, not its Riverpod wrapper', () {
    // Riverpod wraps whatever a provider threw. A real one is produced here
    // rather than constructed: ProviderException's constructor is @internal,
    // and a hand-built stand-in would not prove the unwrapping works on the
    // object the framework actually hands over.
    final container = ProviderContainer.test();
    final broken = Provider<int>((ref) => throw StateError('the real cause'));

    Object? wrapper;
    try {
      container.read(broken);
    } on Object catch (error) {
      wrapper = error;
    }
    expect(wrapper, isA<ProviderException>());

    final sink = _RecordingSink();
    installErrorHandlers(sink);
    PlatformDispatcher.instance.onError!(wrapper!, StackTrace.empty);

    expect(sink.entries.single, contains('the real cause'));
    expect(
      sink.entries.single,
      isNot(contains('ProviderException')),
      reason:
          'unwrapped, or every entry in the log leads with the wrapper and '
          'buries what actually failed',
    );
  });

  test('main installs no zone', () {
    // Two handlers cover every path. A zone with no crash SDK behind it buys
    // nothing and costs a documented mismatch footgun: an error caught by the
    // zone but not by PlatformDispatcher.onError is reported twice, or not at
    // all, depending on the order they were installed.
    for (final path in ['lib/main.dart', 'lib/app/bootstrap.dart']) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains('runZonedGuarded')),
        reason: '$path installs a zone',
      );
    }
  });
}
