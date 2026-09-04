// A destination a later epic owns.
//
// One widget for all of them, naming its own `data-screen` id on screen, so a
// wrong route in a manual run is obvious rather than a blank rectangle that
// could be any of twenty-five screens. It is deleted a screen at a time as the
// feature epics land; when `kScreenRoutes` has no placeholder left, this file
// goes with it.
//
// Not localised, and it must not be: these strings are scaffolding for a
// developer, never copy for a user. Putting them in the ARB files would make
// six translators translate a screen id.

import 'package:flutter/widgets.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';

/// Stands in for a screen a later epic builds.
class PlaceholderScreen extends StatelessWidget {
  /// Creates the placeholder for [screenId].
  const PlaceholderScreen({required this.screenId, super.key, this.detail});

  /// The `data-screen` id from `design/calm/screens.html`.
  final String screenId;

  /// Whatever the route read out of its path.
  ///
  /// Rendered, because the point of an id-bearing placeholder is to prove the
  /// id arrived. A route that read its id from `state.extra` shows nothing here
  /// after a cold start from a deep link, which is the failure this makes
  /// visible.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final type = CalmType.of(context);
    final space = CalmSpace.of(context);

    return ColoredBox(
      color: colors.bg,
      child: Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(space.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                screenId,
                textAlign: TextAlign.center,
                style: type.title.copyWith(color: colors.ink),
              ),
              if (detail case final detail?) ...[
                SizedBox(height: space.s2),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: type.caption.copyWith(color: colors.ink3),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
