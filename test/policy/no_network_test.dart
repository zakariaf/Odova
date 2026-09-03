// SPEC.md §2: "The app ships with no networking code and no network permission
// it can avoid."
//
// tools/audit_deps.sh walks the dependency graph, and there is a whole class of
// violation it structurally cannot see: `dart:io` hands you `HttpClient`,
// `Socket`, `RawDatagramSocket` and `HttpServer` with no dependency at all.
// This is the gate for the code we write ourselves, and it is the one that
// matters most — the promise is kept by having no client, not by policy.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Identifiers that only appear in code that opens a socket.
///
/// Each is matched on a word boundary: `Socket` would otherwise fire on
/// `SocketException` in a comment, and a gate people learn to work around by
/// renaming a variable is not a gate.
const _networkApis = {
  'HttpClient': 'dart:io HTTP client',
  'HttpServer': 'dart:io HTTP server',
  r'\bSocket\b': 'dart:io TCP socket',
  'RawSocket': 'dart:io raw socket',
  'RawDatagramSocket': 'dart:io UDP socket',
  'SecureSocket': 'dart:io TLS socket',
  'WebSocket': 'a web socket',
  'InternetAddress': 'a resolved host',
  'NetworkInterface': 'the network stack',
  'dart:html': 'the browser network stack',
  'package:http/': 'an HTTP client package',
};

void main() {
  test('no file under lib/ reaches for a network API', () {
    final offenders = <String>[];

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        // Generated localizations are not hand-written and cannot contain one.
        .where((f) => !f.path.startsWith('lib/l10n/gen/'));
    expect(files, isNotEmpty, reason: 'the walk found no source at all');

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final MapEntry(key: pattern, value: what) in _networkApis.entries) {
        if (RegExp(pattern).hasMatch(source)) {
          offenders.add('${file.path}: $what');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'the store listing claims zero network calls, and that has to be '
          'true by construction rather than by policy',
    );
  });
}
