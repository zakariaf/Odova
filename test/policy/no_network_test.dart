// SPEC.md §2: "The app ships with no networking code and no network permission
// it can avoid."
//
// tools/audit_deps.sh walks the dependency graph, and there is a whole class of
// violation it structurally cannot see: `dart:io` hands you `HttpClient`,
// `Socket`, `RawDatagramSocket` and `HttpServer` with no dependency at all.
// This is the gate for the code we write ourselves, and it is the one that
// matters most — the promise is kept by having no client, not by policy.
import 'package:flutter_test/flutter_test.dart';

import '../support/source_tree.dart';

/// Identifiers that only appear in code that opens a socket.
///
/// `Socket` is matched on a word boundary; without it the pattern fires on
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
    expectNoBannedPatterns(
      _networkApis,
      reason:
          'the store listing claims zero network calls, and that has to be '
          'true by construction rather than by policy',
    );
  });
}
