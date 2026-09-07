// The open-source licences, offline.
//
// SPEC.md §2 forbids a network call, so there is nothing to link out to — the
// text comes from Flutter's own `LicenseRegistry`, which every package
// registers into at build time, plus the bundled font's OFL entry.
//
// A licence page that fetched anything would be the one screen in the app that
// broke the promise the About screen above it makes.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

/// Every registered licence, as one block of text per package.
///
/// Read through `LicenseRegistry`, which is where `flutter_gen` and every
/// dependency put theirs — including Vazirmatn's SIL OFL 1.1, registered by
/// the app's own bootstrap. Bundling a hand-maintained copy would be a file
/// that goes stale the first time a dependency is bumped.
final FutureProvider<List<LicenceEntry>> licenceEntriesProvider =
    FutureProvider<List<LicenceEntry>>((ref) async {
      final entries = <LicenceEntry>[];
      await for (final entry in LicenseRegistry.licenses) {
        entries.add((
          packages: entry.packages.toList()..sort(),
          text: entry.paragraphs.map((p) => p.text).join('\n\n'),
        ));
      }
      entries.sort((a, b) => a.packages.join().compareTo(b.packages.join()));
      return entries;
    });

/// One licence: which packages it covers, and its text.
typedef LicenceEntry = ({List<String> packages, String text});

/// §13's offline licence view.
class LicencesScreen extends ConsumerWidget {
  /// Creates the screen.
  const LicencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final entries = ref.watch(licenceEntriesProvider).value ?? const [];

    return CalmScaffold(
      appBar: CalmAppBar(title: l10n.aboutLicencesRow),
      children: [
        for (final entry in entries) ...[
          Text(
            entry.packages.join(', '),
            style: type.body.copyWith(fontWeight: type.semi),
          ),
          SizedBox(height: space.s2),
          // The licence text VERBATIM, and never localised: a translated
          // licence is a different licence, and the whole point of showing it
          // is that it is the one the package shipped.
          Text(
            entry.text,
            style: type.caption.copyWith(color: colors.ink2),
          ),
          SizedBox(height: space.s5),
        ],
      ],
    );
  }
}
