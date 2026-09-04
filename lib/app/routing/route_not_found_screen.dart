// Where an unknown link lands.
//
// SPEC.md §7: an unknown location renders a designed screen, not a red box. A
// dead end is worse than a wrong turn, so this screen carries exactly one way
// out and it goes to Home — the one location that always exists and always has
// something to say.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

/// The 404.
class RouteNotFoundScreen extends StatelessWidget {
  /// Creates the screen.
  const RouteNotFoundScreen({super.key, this.location});

  /// The location that did not resolve.
  ///
  /// Not shown. Kept so a `debugPrint` in a manual run and a widget test can
  /// both say WHICH link failed — putting a raw URL on screen would be handing
  /// the user a string they cannot act on, in a language they did not choose.
  final String? location;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    return CalmScaffold(
      appBar: CalmAppBar(title: l10n.routeNotFoundTitle),
      children: [
        SizedBox(height: space.s7),
        Text(
          l10n.routeNotFoundBody,
          textAlign: TextAlign.center,
          style: CalmType.of(context).body.copyWith(color: colors.ink2),
        ),
        SizedBox(height: space.s6),
        CalmButton(
          label: l10n.routeNotFoundGoHome,
          block: true,
          // `go`, not `push`: the user is somewhere that does not exist, and
          // pushing Home on top of it leaves system back pointing at the 404.
          onPressed: () => context.go(Routes.home),
        ),
      ],
    );
  }
}
