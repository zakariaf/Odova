// Every screen in SPEC.md §7 has a URL, one router owns all of them, and an
// unknown link lands somewhere designed.
//
// The coverage test reads `design/calm/screens.html` rather than a hand-copied
// list, so the day a designer adds an artboard nobody routed, this goes red —
// which is the only moment anyone would notice before a feature epic tried to
// navigate to it three months later.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/routing/app_router.dart';
import 'package:odova/app/routing/placeholder_screen.dart';
import 'package:odova/app/routing/route_not_found_screen.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_theme.dart';

import '../../support/source_tree.dart';

/// The ids the design system actually draws.
Set<String> _designScreenIds() {
  final html = File('design/calm/screens.html').readAsStringSync();
  return RegExp(
    'data-screen="([^"]+)"',
  ).allMatches(html).map((m) => m.group(1)!).toSet();
}

/// A `:param` path with something concrete in every slot.
///
/// The ids are shaped like real ones — `veh_` plus Crockford characters — so a
/// route that ever grows a pattern constraint keeps being exercised by this
/// test rather than quietly matching nothing.
String _concrete(String path) => path
    .replaceAll(':reminderId', 'rem_01JQ0000000000000000000000')
    .replaceAll(':vehicleId', 'veh_01JQ0000000000000000000000')
    .replaceAll(':tripId', 'trp_01JQ0000000000000000000000')
    .replaceAll(':entryId', 'fil_01JQ0000000000000000000000')
    .replaceAll(':type', LogType.fillUp.wire);

void main() {
  test('every data-screen id in the design file is in kScreenRoutes', () {
    final drawn = _designScreenIds();
    expect(drawn, hasLength(28), reason: 'the design file itself changed');

    expect(
      drawn.difference(kScreenRoutes.keys.toSet()),
      isEmpty,
      reason: 'these screens are drawn and cannot be navigated to',
    );
    expect(
      kScreenRoutes.keys.toSet().difference(drawn),
      isEmpty,
      reason: 'these routes lead to screens the design does not have',
    );
  });

  test('the four log segments are the four log screens, and nothing else', () {
    // `LogType.wire` is `name.toLowerCase()` rather than a declared string, so
    // that this file declares no second copy of `fillup`/`service`/`expense` —
    // `OdometerSource` already declares those and
    // `test/policy/one_money_type_test.dart` refuses two vocabularies for one
    // setting. Deriving it moves the risk to the derivation, and this is where
    // that risk is held: a member whose name is not a single lower-case word
    // produces a screen id the design file has never heard of, and says so
    // here rather than at a URL.
    final logIds = kScreenRoutes.keys
        .where((k) => k.startsWith('log.'))
        .toSet();

    expect(LogType.values.map((t) => t.screenId).toSet(), logIds);
    expect(logIds, hasLength(LogType.values.length));
    for (final type in LogType.values) {
      expect(kScreenRoutes[type.screenId], isA<ScreenLocation>());
      expect(
        (kScreenRoutes[type.screenId]! as ScreenLocation).path,
        Routes.log(type),
        reason: '${type.name}: the registry and the builder disagree',
      );
      expect(LogType.tryParse(type.wire), type);
    }
    expect(LogType.tryParse('trip'), isNull);
  });

  test('every route in kScreenRoutes resolves to a non-error match', () {
    // A typo in a path is caught here, not in a feature epic three months
    // later. `findMatch` is the router's own resolution, not a reimplementation
    // of it.
    final router = buildRouter();

    for (final MapEntry(key: id, value: route) in kScreenRoutes.entries) {
      if (route is! ScreenLocation) continue;

      final location = _concrete(route.path);
      final match = router.configuration.findMatch(Uri.parse(location));

      expect(match.error, isNull, reason: '$id -> $location: ${match.error}');
      expect(match.routes, isNotEmpty, reason: '$id -> $location matched none');
    }
  });

  test('the three global dialogs are declared as dialogs, not locations', () {
    // A dialog returns a DECISION to its caller, and a URL cannot carry one
    // back. A deep link into "discard changes?" is meaningless besides: on a
    // cold start there is nothing to discard.
    const dialogs = {'dialog.discard', 'dialog.confirmDelete', 'dialog.snooze'};

    for (final id in dialogs) {
      expect(kScreenRoutes[id], isA<ScreenDialog>(), reason: id);
    }
    // These three and no others — the test names them so a fourth id quietly
    // moved to the dialog side of the map has to be argued for here.
    expect(
      kScreenRoutes.entries
          .where((e) => e.value is ScreenDialog)
          .map((e) => e.key)
          .toSet(),
      dialogs,
    );
  });

  test('no path is more than two segments deep below its tab root', () {
    // §7's architectural limit, asserted over the table so a third push is a
    // red test rather than a design review comment.
    for (final MapEntry(key: id, value: route) in kScreenRoutes.entries) {
      if (route is! ScreenLocation) continue;
      if (Routes.tabRoots.contains(route.path)) continue;

      final depth = Uri.parse(route.path).pathSegments.length;
      // A tab root contributes one segment — none, for Home — so two pushes
      // below it is at most three.
      expect(
        depth,
        lessThanOrEqualTo(3),
        reason: '$id is $depth segments deep: ${route.path}',
      );
    }
  });

  testWidgets('an id-bearing route reads its id from pathParameters', (
    tester,
  ) async {
    // A cold start from a deep link has a null `state.extra`, so identity that
    // travels in `extra` is identity that vanishes when the OS restarts the
    // app. The placeholder renders whatever the route read, so the assertion is
    // that the id reached the screen — not that a particular field was touched.
    const idBearing = {
      '/reminders/:reminderId': 'reminders.edit',
      '/costs/trips/:tripId': 'trips.edit',
      '/settings/vehicles/:vehicleId': 'vehicle.edit',
      '/log/:type/:entryId': 'log.fillup',
    };

    for (final MapEntry(key: path, value: screenId) in idBearing.entries) {
      final location = _concrete(path);
      final id = Uri.parse(location).pathSegments.last;

      // Keyed by location: without it the second pump reuses the first
      // harness's State — and its router — and every case after the first
      // asserts against the first one's screen while looking like it passed
      // its own.
      await tester.pumpWidget(
        _Harness(key: ValueKey(location), location: location),
      );
      await tester.pumpAndSettle();

      final screen = tester.widget<PlaceholderScreen>(
        find.byType(PlaceholderScreen),
      );
      expect(screen.screenId, screenId, reason: path);
      expect(screen.detail, id, reason: '$path did not read $id from the path');
    }

    // And the graph declares exactly these four. A fifth added without a test
    // is a fifth nobody proved reads its path.
    expect(idBearing, hasLength(4));
  });

  testWidgets('an unknown location renders the error screen', (tester) async {
    await tester.pumpWidget(const _Harness(location: '/nope'));
    await tester.pumpAndSettle();

    expect(find.byType(RouteNotFoundScreen), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets('the error screen offers one way back to Home', (tester) async {
    // A dead end is worse than a wrong turn.
    await tester.pumpWidget(const _Harness(location: '/nope'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go to Home'));
    await tester.pumpAndSettle();

    expect(find.byType(RouteNotFoundScreen), findsNothing);
    final screen = tester.widget<PlaceholderScreen>(
      find.byType(PlaceholderScreen),
    );
    expect(screen.screenId, 'home');
  });

  test('there is exactly one GoRouter in lib/', () {
    // The rule `navigation-and-routing` states first. Two routers is two
    // navigation graphs, and the second one is always the one the bug is in.
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib')) {
      final source = sourceWithoutLineComments(file);
      if (RegExp(r'\bGoRouter\s*\(').hasMatch(source)) {
        offenders.add(file.path);
      }
    }
    expect(offenders, ['lib/app/routing/app_router.dart']);
  });
}

/// A `MaterialApp.router` over the real graph, at a chosen starting location.
///
/// Deliberately not `OdovaApp`: task 8.2 mounts the router there, and pinning
/// this test to that wiring would make it fail for a reason that has nothing to
/// do with the route table.
class _Harness extends StatefulWidget {
  const _Harness({required this.location, super.key});

  final String location;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late final GoRouter _router = buildRouter(initialLocation: widget.location);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: _router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildCalmTheme(Brightness.light),
  );
}
