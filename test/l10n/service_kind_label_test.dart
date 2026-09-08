// Every catalogue item has a name.
//
// SPEC.md §8 gives `ServiceItem.label` meaning only when `kind = custom`, so a
// seeded item is named by its KIND — and until this shipped, those 28 names did
// not exist. Two places in the code pointed at "the 28 kind strings EPIC-10
// owns"; EPIC-10 shipped without them, and a manual pass on a device found
// `reminders.list` drawing seven rows all reading "Service", Home reading
// "Next: Service", and the service form offering `+ Other` and nothing else.
//
// Nothing caught it because every test either supplied a label explicitly or
// asserted the generic fallback — the fallback was the tested path.
@TestOn('vm')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/service_kind_label.dart';
import 'package:odova/l10n/supported_locales.dart';

void main() {
  test('every kind is named in every locale, and no two collide', () async {
    for (final locale in odovaSupportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      final names = <String, ServiceKind>{};

      for (final kind in ServiceKind.values) {
        final name = serviceKindLabel(l10n, kind);
        expect(
          name.trim(),
          isNotEmpty,
          reason: '${locale.languageCode}: ${kind.name} has no name',
        );

        // DISTINCT, which is the whole point. Twenty-eight items that all read
        // "Service" is what this replaced, and two that read the same is the
        // same defect at a smaller scale — a user cannot tell which reminder
        // they are turning off.
        final clash = names[name];
        expect(
          clash,
          isNull,
          reason:
              '${locale.languageCode}: ${kind.name} and ${clash?.name} are '
              'both "$name"',
        );
        names[name] = kind;
      }
    }
  });

  test('a custom item keeps its own words', () async {
    // §8: the label carries meaning for exactly one kind, and it is the user's
    // own text. Overriding it with "Custom item" would rename their entry.
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(
      serviceItemLabel(l10n, kind: ServiceKind.custom, label: 'Ceramic coat'),
      'Ceramic coat',
    );
  });

  test('and a seed falls through to its kind', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    // Null and blank both, because the catalogue stores null and a form that
    // has been opened and cleared stores ''.
    for (final label in [null, '', '   ']) {
      expect(
        serviceItemLabel(l10n, kind: ServiceKind.timingBelt, label: label),
        l10n.serviceKindTimingBelt,
        reason: 'label ${label == null ? 'null' : '"$label"'}',
      );
    }
  });

  test('the RTL locales are not the English strings', () async {
    // The cheapest check that a translation actually happened. A copied
    // English name renders left-to-right inside a Persian list and is the
    // failure mode a six-locale ARB gate cannot see, because the key IS
    // present in all six.
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    for (final tag in ['fa', 'ar', 'ckb']) {
      final l10n = await AppLocalizations.delegate.load(Locale(tag));
      final copied = [
        for (final kind in ServiceKind.values)
          if (serviceKindLabel(l10n, kind) == serviceKindLabel(en, kind))
            kind.name,
      ];

      expect(copied, isEmpty, reason: '$tag still reads English for: $copied');
    }
  });
}
