// SPEC.md §12: "Written to a temp file and handed to the OS share sheet. The
// app never picks a destination, asks for storage permission, remembers where
// the file went, or generates in the background."
//
// Four promises, and three of them are about what the app does NOT do. That is
// what makes a port worth having here: "never asks for storage permission" is
// a property of the code, and the way to keep it is to have no code that could.
// The channel carries a path and a mime type and has no other verbs.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/share/share_service.dart';
import 'package:odova/core/result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  late Directory temp;

  setUp(() async {
    calls = [];
    temp = await Directory.systemTemp.createTemp('odova_share_test');
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kShareChannel, null);
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  void mock({Object? Function(MethodCall)? handler}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kShareChannel, (call) async {
          calls.add(call);
          return handler?.call(call);
        });
  }

  ShareService service() => PlatformShareService(directory: () async => temp);

  test(
    'the file is written to a temp path and handed to the channel',
    () async {
      mock();
      final result = await service().shareFile(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        fileName: 'odova-service-history-golf-2026-09-02.pdf',
        mimeType: 'application/pdf',
      );

      expect(result, isA<Ok<void, ShareFailure>>());
      expect(calls.single.method, 'shareFile');

      final args = calls.single.arguments as Map<Object?, Object?>;
      expect(args['mimeType'], 'application/pdf');
      expect(
        args['path'],
        startsWith(temp.path),
        reason: 'a temp path, not a place the app chose to keep',
      );
      expect(
        args['path'],
        endsWith('odova-service-history-golf-2026-09-02.pdf'),
      );
      expect(File(args['path']! as String).readAsBytesSync(), [1, 2, 3, 4]);
    },
  );

  test('the channel carries a path and a mime type only', () async {
    // §12: the app never picks a destination or remembers where the file went.
    // A channel with a `destination` or `remember` argument is one somebody
    // will use.
    mock();
    await service().shareFile(
      bytes: Uint8List.fromList([1]),
      fileName: 'a.pdf',
      mimeType: 'application/pdf',
    );

    expect(
      (calls.single.arguments as Map<Object?, Object?>).keys.toSet(),
      {'path', 'mimeType'},
    );
  });

  test('a platform refusal comes back as a value, not an exception', () async {
    // It renders inline under the button with Try again — §12: "No dialog —
    // the user is already stressed." A thrown `PlatformException` reaching the
    // widget layer is a red screen instead.
    mock(
      handler: (_) => throw PlatformException(code: 'no_activity'),
    );

    final result = await service().shareFile(
      bytes: Uint8List.fromList([1]),
      fileName: 'a.pdf',
      mimeType: 'application/pdf',
    );

    expect(result, isA<Err<void, ShareFailure>>());
    expect(
      (result as Err<void, ShareFailure>).failure.code,
      'share_refused',
    );
  });

  test('a full disk comes back as its own failure', () async {
    // A different sentence to the user: "There may not be enough space on the
    // device" is actionable, "couldn't share" is not.
    mock();
    final result =
        await PlatformShareService(
          directory: () async => Directory('/definitely/not/a/directory'),
        ).shareFile(
          bytes: Uint8List.fromList([1]),
          fileName: 'a.pdf',
          mimeType: 'application/pdf',
        );

    expect((result as Err<void, ShareFailure>).failure.code, 'share_write');
    expect(calls, isEmpty, reason: 'nothing was handed over');
  });

  test('the temp file is deleted when the share is abandoned', () async {
    // §12's Cancel: "abandons generation and deletes the temp file." A
    // cancelled report that leaves a copy of someone's service history in a
    // world-readable cache is the leak §2 exists to prevent.
    mock();
    final s = service();
    await s.shareFile(
      bytes: Uint8List.fromList([1]),
      fileName: 'a.pdf',
      mimeType: 'application/pdf',
    );
    final path =
        (calls.single.arguments as Map<Object?, Object?>)['path']! as String;
    expect(File(path).existsSync(), isTrue);

    await s.discard();

    expect(File(path).existsSync(), isFalse);
  });

  test('discard with nothing written is a no-op, not a crash', () async {
    mock();
    expect(await service().discard(), isA<Ok<void, ShareFailure>>());
  });

  test(
    'a second share replaces the first file rather than accumulating',
    () async {
      // The screen is opened twice a decade but the button can be pressed twice
      // a minute, and every press writes a copy of the whole service history.
      //
      // DIFFERENT filenames on purpose. The first version of this test reused
      // one name, so three writes overwrote each other and it passed against a
      // service that never discarded anything — the mutation that removes the
      // discard survived it. §12's filename carries the generation date, so two
      // shares either side of midnight really are two names.
      mock();
      final s = service();
      for (var i = 0; i < 3; i++) {
        await s.shareFile(
          bytes: Uint8List.fromList([i]),
          fileName: 'odova-service-history-golf-2026-09-0$i.pdf',
          mimeType: 'application/pdf',
        );
      }

      expect(
        temp.listSync().whereType<File>().length,
        1,
        reason: 'one temp file, not three',
      );
    },
  );
}
