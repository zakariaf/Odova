/// The assertion half of the source-tree gates.
///
/// Split from `source_tree.dart` because that file must stay Flutter-free:
/// `test/core` runs twice, once under `flutter test` and once under
/// `dart test test/core` on the plain VM, and the second run is the gate that
/// proves the domain layer needs no Flutter. Anything reachable from a
/// `test/core` file that imports `flutter_test` fails it with `Dart library
/// 'dart:ui' is not available on this platform`.
///
/// So the walking and the matching live there and return values; the
/// `expect` lives here.
library;

import 'package:flutter_test/flutter_test.dart';

import 'source_tree.dart';

/// Fails if any file under [path] contains one of [banned]'s patterns.
///
/// Keys are regular expressions; values say why the identifier is refused, and
/// end up in the failure message where somebody can act on them.
void expectNoBannedPatterns(
  Map<String, String> banned, {
  String path = 'lib',
  String? reason,
}) => expect(
  bannedPatternOffenders(banned, path: path),
  isEmpty,
  reason: reason,
);
