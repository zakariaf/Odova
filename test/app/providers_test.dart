// The composition model, decided once.
//
// Riverpod 3.x is state AND dependency injection here. A second injection
// mechanism arriving in epic seven is how an app ends up with two answers to
// "where does this service come from", so the alternatives are a grep test
// rather than a convention.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// Override lives in misc.dart in Riverpod 3.x, not the root library.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/app.dart';
import 'package:odova/app/providers.dart';

import '../support/source_tree.dart';

/// Every placeholder provider, and how to read it.
///
/// Kept as data so the test below can assert this list covers every
/// `_unwired(...)` call site in lib/app/providers.dart.
final placeholderReads = <String, Object Function(ProviderContainer)>{
  'crashSinkProvider': (c) => c.read(crashSinkProvider),
  'clockProvider': (c) => c.read(clockProvider),
};

void main() {
  test('every placeholder provider throws until overridden', () {
    final container = ProviderContainer.test();

    for (final MapEntry(key: name, value: read) in placeholderReads.entries) {
      expect(
        () => read(container),
        // Riverpod 3 wraps whatever a provider throws in a ProviderException.
        // That wrapping is why lib/app/error_handlers.dart unwraps before
        // logging: without it every entry reads ProviderException and the
        // name below — the only part anybody needs — is buried.
        throwsA(
          isA<ProviderException>().having(
            (e) => e.exception,
            'exception',
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains(name),
            ),
          ),
        ),
        reason:
            'a forgotten wiring must fail loudly at startup, naming '
            'itself — never return null and surface three screens later',
      );
    }
  });

  test(
    'the placeholder list in this test covers every placeholder in lib/',
    () {
      // Guard the guard. A placeholder added without a line here would be a
      // provider nothing proves fails loudly.
      final declared = RegExp(r"_unwired\('(\w+)'\)")
          .allMatches(File('lib/app/providers.dart').readAsStringSync())
          .map((m) => m.group(1)!)
          .toSet();

      expect(declared, isNotEmpty);
      expect(placeholderReads.keys.toSet(), declared);
    },
  );

  testWidgets('the root ProviderScope disables retry', (tester) async {
    await tester.pumpWidget(const OdovaRoot());

    final scope = tester.widget<ProviderScope>(find.byType(ProviderScope));

    // Riverpod 3 retries a failing provider on an exponential backoff for
    // roughly 38 seconds. Odova's only provider failures are local bugs — a
    // corrupt database, a missing file — and none of them get better by
    // waiting. A bug behind a spinner is worse than a bug on screen.
    expect(scope.retry, isNotNull);
    expect(scope.retry!(1, StateError('x')), isNull);
    expect(scope.retry!(9, StateError('x')), isNull);
  });

  test(
    'no get_it, no package:provider, no legacy StateNotifierProvider '
    'anywhere in lib/',
    () {
      expectNoBannedPatterns(const {
        'package:get_it': 'get_it — a second injection mechanism',
        'package:provider/': 'package:provider — a second injection mechanism',
        'StateNotifierProvider': 'the Riverpod 1.x model, removed in 3.x',
        'ChangeNotifierProvider': 'the same, via Flutter',
      });
    },
  );
}
