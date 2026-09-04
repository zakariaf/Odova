// The one navigation graph.
//
// SPEC.md §7. `navigation-and-routing`'s first rule is that there is exactly
// one `GoRouter` in the app, and `route_table_test.dart` greps `lib/` to prove
// it: two routers is two graphs, and the second one is always the one the bug
// is in.
//
// The paths are NOT written here — they come from `routes.dart`, which is the
// single registry `kScreenRoutes` and EPIC-18's parity harness also read. This
// file only says what each path builds.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/routing/placeholder_screen.dart';
import 'package:odova/app/routing/route_not_found_screen.dart';
import 'package:odova/app/routing/routes.dart';

/// The root navigator.
///
/// Held here rather than created inside [buildRouter] so a modal can be pushed
/// ABOVE the shell — which is what puts a log form over the tab bar instead of
/// inside it.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// The app's router.
///
/// A provider rather than a global, because the router will grow a redirect
/// that reads whether a vehicle exists (task 8.6) and a global cannot watch
/// anything. `keepAlive`: rebuilding the router would throw away every tab's
/// stack.
final routerProvider = Provider<GoRouter>((ref) => buildRouter());

/// Builds the router.
///
/// Public so a test can build one without a `ProviderContainer`. There is still
/// exactly one in a running app — this is the constructor, `routerProvider` is
/// the instance.
GoRouter buildRouter({String initialLocation = Routes.home}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    // Not `errorPageBuilder`, and not left to default: without this go_router
    // renders its own red-on-white exception page, which is a screen no
    // designer drew and no translator saw.
    errorBuilder: (context, state) =>
        RouteNotFoundScreen(location: state.uri.toString()),
    routes: _routes,
  );
}

/// Every route in the app.
///
/// Flat for now. Task 8.2 wraps the four tab roots in a
/// `StatefulShellRoute.indexedStack` without changing a single path — a branch
/// keeps its root's absolute path, so `/settings/units` is `/settings/units`
/// either way and this table stays the source of truth.
final List<RouteBase> _routes = [
  GoRoute(
    path: Routes.home,
    builder: (context, state) => const PlaceholderScreen(screenId: 'home'),
  ),
  GoRoute(
    path: Routes.vehicleSwitcher,
    builder: (context, state) =>
        const PlaceholderScreen(screenId: 'vehicle.switcher'),
  ),
  GoRoute(
    path: Routes.reminders,
    builder: (context, state) =>
        const PlaceholderScreen(screenId: 'reminders.list'),
    routes: [
      GoRoute(
        path: ':reminderId',
        builder: (context, state) => PlaceholderScreen(
          screenId: 'reminders.edit',
          // From the PATH. A cold start from a deep link has a null
          // `state.extra`, so identity that travels in `extra` is identity
          // that vanishes when the OS restarts the app.
          detail: state.pathParameters['reminderId'],
        ),
      ),
    ],
  ),
  GoRoute(
    path: '/log/:type',
    builder: (context, state) => _logScreen(state),
    routes: [
      GoRoute(
        path: ':entryId',
        builder: (context, state) => _logScreen(state),
      ),
    ],
  ),
  GoRoute(
    path: Routes.history,
    builder: (context, state) => const PlaceholderScreen(screenId: 'history'),
    routes: [
      GoRoute(
        path: 'report',
        builder: (context, state) =>
            const PlaceholderScreen(screenId: 'report.service'),
      ),
    ],
  ),
  GoRoute(
    path: Routes.costs,
    builder: (context, state) => const PlaceholderScreen(screenId: 'costs'),
    routes: [
      GoRoute(
        path: 'fuel',
        builder: (context, state) =>
            const PlaceholderScreen(screenId: 'costs.fuel'),
      ),
      GoRoute(
        path: 'trips',
        builder: (context, state) =>
            const PlaceholderScreen(screenId: 'trips.list'),
        routes: [
          GoRoute(
            path: ':tripId',
            builder: (context, state) => PlaceholderScreen(
              screenId: 'trips.edit',
              detail: state.pathParameters['tripId'],
            ),
          ),
        ],
      ),
      GoRoute(
        // The second `history` instance. SPEC.md §7: a cross-tab data jump
        // pushes into the CURRENT tab, so it needs its own location inside
        // Costs rather than switching the user to the History tab.
        path: 'history',
        builder: (context, state) =>
            const PlaceholderScreen(screenId: 'history'),
      ),
    ],
  ),
  GoRoute(
    path: Routes.settings,
    builder: (context, state) => const PlaceholderScreen(screenId: 'settings'),
    routes: [
      GoRoute(
        path: 'vehicles',
        builder: (context, state) =>
            const PlaceholderScreen(screenId: 'vehicles'),
        routes: [
          GoRoute(
            path: ':vehicleId',
            builder: (context, state) => PlaceholderScreen(
              screenId: 'vehicle.edit',
              detail: state.pathParameters['vehicleId'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: 'language',
        builder: (context, state) =>
            const PlaceholderScreen(screenId: 'settings.language'),
      ),
      GoRoute(
        path: 'units',
        builder: (context, state) =>
            const PlaceholderScreen(screenId: 'settings.units'),
      ),
      GoRoute(
        path: 'notifications',
        builder: (context, state) =>
            const PlaceholderScreen(screenId: 'settings.notifications'),
      ),
      GoRoute(
        path: 'backup',
        builder: (context, state) =>
            const PlaceholderScreen(screenId: 'settings.backup'),
        routes: [
          GoRoute(
            path: 'import',
            builder: (context, state) =>
                const PlaceholderScreen(screenId: 'settings.import'),
          ),
        ],
      ),
      GoRoute(
        path: 'about',
        builder: (context, state) =>
            const PlaceholderScreen(screenId: 'settings.about'),
      ),
    ],
  ),
  GoRoute(
    path: Routes.firstRunLanguage,
    builder: (context, state) =>
        const PlaceholderScreen(screenId: 'firstrun.language'),
  ),
  GoRoute(
    path: Routes.firstRunVehicle,
    builder: (context, state) =>
        const PlaceholderScreen(screenId: 'firstrun.vehicle'),
  ),
];

/// The log modal, on whichever segment the URL names.
///
/// An unknown `:type` is a 404 rather than a silent fall back to Fill-up: a
/// notification from an older build carrying a renamed segment would otherwise
/// open the wrong form, pre-filled with the wrong fields, and look deliberate.
Widget _logScreen(GoRouterState state) {
  final type = LogType.tryParse(state.pathParameters['type'] ?? '');
  if (type == null) {
    return RouteNotFoundScreen(location: state.uri.toString());
  }
  return PlaceholderScreen(
    screenId: 'log.${type.wire}',
    detail: state.pathParameters['entryId'],
  );
}
