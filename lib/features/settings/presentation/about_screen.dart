// SPEC.md §13's `settings.about` — the privacy promise, two numbers, and the
// licences.
//
// The promise is the point of the screen and it is a promise, not a legal
// notice: §2 makes "no network, by construction" true by refusing every
// dependency that opens a socket, and the store listing claims it. Broken into
// bullets under a heading it would read like terms nobody reads.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/app_version.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

/// §13's about screen.
class AboutScreen extends ConsumerWidget {
  /// Creates the screen.
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return CalmScaffold(
      appBar: CalmAppBar.pushed(
        title: l10n.settingsAboutRow,
        startLabel: l10n.commonBack,
        onStart: () => Navigator.of(context).maybePop(),
      ),
      children: [
        Text(l10n.appTitle, style: type.display),
        SizedBox(height: space.s2),
        // LATIN digits and their own isolate, whatever `numerals` says. §13:
        // a version string is an identifier a support conversation quotes
        // back, and Eastern Arabic-Indic digits in a bug report help nobody.
        Text(
          isolateLtr(l10n.aboutVersion(kAppVersion, kAppBuild)),
          style: type.body.copyWith(color: colors.ink2),
        ),
        Text(
          // From `kSupportedFormatVersion` — the SAME constant the backup
          // writer writes. Two copies is how the number on this screen and
          // the number in the file drift apart, which is a support
          // conversation nobody can resolve.
          isolateLtr(l10n.aboutBackupFormat('$kSupportedFormatVersion')),
          style: type.body.copyWith(color: colors.ink2),
        ),
        SizedBox(height: space.s6),
        // ONE block, no fixed height, no ellipsis: §13 says it renders in full
        // at 200% scale in all six locales, and a promise that has to be
        // scrolled inside its own box is a promise with something hidden.
        Text(l10n.aboutPrivacy, style: type.body),
        SizedBox(height: space.s4),
        // The sentence a future PR will quietly delete, which is why the test
        // asserts it by name. §1: the history is worth money and no server
        // holds a copy — the honest consequence has to be said out loud.
        Text(
          l10n.aboutBackupWarning,
          style: type.body.copyWith(color: colors.ink2),
        ),
        SizedBox(height: space.s6),
        CalmRowGroup(
          rows: [
            CalmListRow(
              title: l10n.aboutLicencesRow,
              showChevron: true,
              onTap: () => unawaited(context.push(Routes.settingsLicences)),
            ),
          ],
        ),
      ],
    );
  }
}
