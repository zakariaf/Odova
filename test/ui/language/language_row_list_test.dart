// The seven language rows, shared by two screens.
//
// What it does NOT own is the write: the two frames apply a language
// differently — first run commits on Continue, settings applies on tap — so
// `onSelect` is required and this asserts the list reports the tap rather than
// acting on it.
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/l10n/locale_resolution.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/language/language_row_list.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('seven rows, in SPEC.md §5 order, each in its own script', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const CalmRowGroup(rows: [LanguageRowList(onSelect: _ignore)]),
    );
    await tester.pumpAndSettle();

    final titles = tester
        .widgetList<CalmListRow>(find.byType(CalmListRow))
        .map((r) => r.title)
        .toList();

    expect(titles, hasLength(localeOverrideValues.length));
    // The six endonyms, after the `System (…)` row.
    expect(titles.sublist(1), [
      'English',
      'Deutsch',
      'Français',
      'فارسی',
      'العربية',
      'کوردیی ناوەندی',
    ]);
  });

  testWidgets('a tap reports the value and writes nothing', (tester) async {
    final tapped = <String>[];
    await pumpApp(
      tester,
      CalmRowGroup(rows: [LanguageRowList(onSelect: tapped.add)]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(tapped, ['de']);
  });

  testWidgets('each Arabic-script row carries its own language', (
    tester,
  ) async {
    // So a screen reader switches voice mid-list, and so the three
    // Arabic-script names render in the bundled family rather than as empty
    // boxes under a Latin UI.
    await pumpApp(
      tester,
      const CalmRowGroup(rows: [LanguageRowList(onSelect: _ignore)]),
    );
    await tester.pumpAndSettle();

    final rows = tester
        .widgetList<CalmListRow>(find.byType(CalmListRow))
        .toList();

    expect(rows[4].nativeTitleLanguage, 'fa');
    expect(rows[5].nativeTitleLanguage, 'ar');
    expect(rows[6].nativeTitleLanguage, 'ckb');
  });
}

void _ignore(String _) {}
