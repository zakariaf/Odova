// The one navigation graph.
//
// SPEC.md §7. `navigation-and-routing`'s first rule is that there is exactly
// one `GoRouter` in the app, and `route_table_test.dart` greps `lib/` to prove
// it: two routers is two graphs, and the second one is always the one the bug
// is in.
//
// The paths are NOT written here — they come from `routes.dart`, which is the
// single registry `kScreenRoutes` and EPIC-18's parity harness also read. This
// file only says what each path builds, and which navigator it builds it on.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/routing/app_shell.dart';
import 'package:odova/app/routing/launch_gate.dart';
import 'package:odova/app/routing/page_kinds.dart';
import 'package:odova/app/routing/placeholder_screen.dart';
import 'package:odova/app/routing/route_not_found_screen.dart';
import 'package:odova/app/routing/routes.dart';

/// The root navigator.
///
/// A route declared with this key is pushed ABOVE the shell, which is what puts
/// a log form over the tab bar instead of inside a tab. Every route without it
/// belongs to a branch and keeps the bar.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// The app's router.
///
/// A provider rather than a global, because the router grows a redirect that
/// reads whether a vehicle exists (task 8.6) and a global cannot watch
/// anything. Never re-created while the app runs: rebuilding the router would
/// throw away all four tab stacks.
final routerProvider = Provider<GoRouter>((ref) {
  // `read`, not `watch`, for the initial location: the router is built once
  // and re-creating it would throw away all four tab stacks. The redirect below
  // reads the CURRENT facts on every navigation, and `refreshListenable` is
  // what re-runs it when they change.
  final listenable = launchFactsListenable(ref);
  return buildRouter(
    initialLocation: initialLocationFor(ref.read(launchFactsProvider)),
    redirect: (location) =>
        appRedirect(ref.read(launchFactsProvider), location),
    refreshListenable: listenable,
  );
});

/// Builds the router.
///
/// Public so a test can build one without a `ProviderContainer`. There is still
/// exactly one in a running app — this is the constructor, `routerProvider` is
/// the instance.
GoRouter buildRouter({
  String initialLocation = Routes.home,
  String? Function(String location)? redirect,
  Listenable? refreshListenable,
}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    // The gate is a pure function of three facts and a location; the closure
    // is what supplies the facts. Keeping the read OUT of `appRedirect` is what
    // makes the loop-freedom property testable over the whole route table.
    redirect: redirect == null
        ? null
        : (context, state) => redirect(state.matchedLocation),
    // Not left to default: go_router's default is a red-on-white exception
    // page, a screen no designer drew and no translator saw.
    errorBuilder: (context, state) =>
        RouteNotFoundScreen(location: state.uri.toString()),
    routes: _routes,
  );
}

/// Every route in the app.
///
/// Two levels, and the LEVEL is the whole difference between a modal and a
/// screen: a route inside a branch sits under the tab bar, and a route out here
/// covers it. Decided by the shape of this list rather than at the call site,
/// so `context.push` cannot get it wrong.
///
/// These five carried `parentNavigatorKey: rootNavigatorKey` until a mutation
/// proved it changed nothing — a route declared outside the shell is already on
/// the root navigator, so the argument was a comment wearing the costume of
/// code. [rootNavigatorKey] earns its keep on the router itself and on any
/// future route that has to live INSIDE a branch and still cover the bar.
final List<RouteBase> _routes = [
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        AppShell(navigationShell: navigationShell),
    branches: _branches,
  ),
  GoRoute(
    path: Routes.vehicleSwitcher,
    pageBuilder: (context, state) => PageKind.sheet.page(
      context,
      state,
      const PlaceholderScreen(screenId: 'vehicle.switcher'),
    ),
  ),
  GoRoute(
    path: '/log/:type',
    pageBuilder: (context, state) => PageKind.modal.page(
      context,
      state,
      _logScreen(state),
    ),
    routes: [
      GoRoute(
        path: ':entryId',
        pageBuilder: (context, state) => PageKind.modal.page(
          context,
          state,
          _logScreen(state),
        ),
      ),
    ],
  ),
  // First run is outside the shell on purpose: it has no tab to belong to, and
  // showing a tab bar over a screen the user cannot leave yet offers four
  // destinations that all refuse.
  GoRoute(
    path: Routes.firstRunLanguage,
    pageBuilder: (context, state) => PageKind.push.page(
      context,
      state,
      const PlaceholderScreen(screenId: 'firstrun.language'),
    ),
  ),
  GoRoute(
    path: Routes.firstRunVehicle,
    pageBuilder: (context, state) => PageKind.push.page(
      context,
      state,
      const PlaceholderScreen(screenId: 'firstrun.vehicle'),
    ),
  ),
];

/// One branch per tab, in `Routes.tabRoots` order.
///
/// Four branches and four `Navigator`s, all four kept mounted by
/// `indexedStack`. That is the whole reason for it: switching tabs moves an
/// index, so coming back to Settings finds the user where they left it rather
/// than at the tab's root.
final List<StatefulShellBranch> _branches = [
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) => PageKind.push.page(
          context,
          state,
          const PlaceholderScreen(screenId: 'home'),
        ),
        routes: [
          GoRoute(
            path: 'reminders',
            pageBuilder: (context, state) => PageKind.push.page(
              context,
              state,
              const PlaceholderScreen(screenId: 'reminders.list'),
            ),
            routes: [
              GoRoute(
                path: ':reminderId',
                pageBuilder: (context, state) => PageKind.push.page(
                  context,
                  state,
                  PlaceholderScreen(
                    screenId: 'reminders.edit',
                    // From the PATH. A cold start from a deep link has a null
                    // `state.extra`, so identity that travels in `extra` is
                    // identity that vanishes when the OS restarts the app.
                    detail: state.pathParameters['reminderId'],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: Routes.history,
        pageBuilder: (context, state) => PageKind.push.page(
          context,
          state,
          const PlaceholderScreen(screenId: 'history'),
        ),
        routes: [
          GoRoute(
            path: 'report',
            pageBuilder: (context, state) => PageKind.push.page(
              context,
              state,
              const PlaceholderScreen(screenId: 'report.service'),
            ),
          ),
        ],
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: Routes.costs,
        pageBuilder: (context, state) => PageKind.push.page(
          context,
          state,
          const PlaceholderScreen(screenId: 'costs'),
        ),
        routes: [
          GoRoute(
            path: 'fuel',
            pageBuilder: (context, state) => PageKind.push.page(
              context,
              state,
              const PlaceholderScreen(screenId: 'costs.fuel'),
            ),
          ),
          GoRoute(
            path: 'trips',
            pageBuilder: (context, state) => PageKind.push.page(
              context,
              state,
              const PlaceholderScreen(screenId: 'trips.list'),
            ),
            routes: [
              GoRoute(
                path: ':tripId',
                pageBuilder: (context, state) => PageKind.push.page(
                  context,
                  state,
                  PlaceholderScreen(
                    screenId: 'trips.edit',
                    detail: state.pathParameters['tripId'],
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            // The second `history` instance. SPEC.md §7: a cross-tab data jump
            // pushes into the CURRENT tab, because the app never switches tabs
            // under the user's finger — so "show me the fill-ups behind this
            // figure" pushes here rather than throwing away where they were.
            path: 'history',
            pageBuilder: (context, state) => PageKind.push.page(
              context,
              state,
              const PlaceholderScreen(screenId: 'history'),
            ),
          ),
        ],
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: Routes.settings,
        pageBuilder: (context, state) => PageKind.push.page(
          context,
          state,
          const PlaceholderScreen(screenId: 'settings'),
        ),
        routes: [
          GoRoute(
            path: 'vehicles',
            pageBuilder: (context, state) => PageKind.push.page(
              context,
              state,
              const PlaceholderScreen(screenId: 'vehicles'),
            ),
            routes: [
              GoRoute(
                path: ':vehicleId',
                pageBuilder: (context, state) => PageKind.push.page(
                  context,
                  state,
                  PlaceholderScreen(
                    screenId: 'vehicle.edit',
                    detail: state.pathParameters['vehicleId'],
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'language',
            pageBuilder: (context, state) => PageKind.push.page(
              context,
              state,
              const PlaceholderScreen(screenId: 'settings.language'),
            ),
          ),
          GoRoute(
            path: 'units',
            pageBuilder: (context, state) => PageKind.push.page(
              context,
              state,
              const PlaceholderScreen(screenId: 'settings.units'),
            ),
          ),
          GoRoute(
            path: 'notifications',
            pageBuilder: (context, state) => PageKind.push.page(
              context,
              state,
              const PlaceholderScreen(screenId: 'settings.notifications'),
            ),
          ),
          GoRoute(
            path: 'backup',
            pageBuilder: (context, state) => PageKind.push.page(
              context,
              state,
              const PlaceholderScreen(screenId: 'settings.backup'),
            ),
            routes: [
              GoRoute(
                path: 'import',
                pageBuilder: (context, state) => PageKind.push.page(
                  context,
                  state,
                  const PlaceholderScreen(screenId: 'settings.import'),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'about',
            pageBuilder: (context, state) => PageKind.push.page(
              context,
              state,
              const PlaceholderScreen(screenId: 'settings.about'),
            ),
          ),
        ],
      ),
    ],
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
    screenId: type.screenId,
    detail: state.pathParameters['entryId'],
  );
}
