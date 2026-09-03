// SPEC.md §5's locale-selection table, as executable rules.
//
// Pure Dart on purpose: this is the one piece of the localisation layer that
// is a decision rather than a rendering, and it runs under `dart test` in
// milliseconds with no binding, no device and no clock.
//
// The rule people get wrong is the `ku` row, and it is worth stating why it is
// not an oversight: Kurmanji is a different language written in Latin script,
// so serving it Sorani in Arabic script is worse for a Kurmanji speaker than
// serving them English.
import 'package:odova/core/l10n/locale_resolution.dart';
import 'package:test/test.dart';

void main() {
  group('an explicit setting wins', () {
    test('over the device list entirely', () {
      final resolved = resolveLocaleTags('de', const ['fa-IR', 'en-US']);
      expect(resolved.strings, 'de');
      // Formats still follow the DEVICE: someone reading German in Tehran
      // wants German words and Iranian dates.
      expect(resolved.formats, 'fa-IR');
    });

    test('and `system` is not one of them', () {
      // It is a value of the setting, not a seventh string set.
      expect(resolveLocaleTags('system', const ['fr-CA']).strings, 'fr');
    });
  });

  group('the device list is matched on the language subtag, in order', () {
    test('the first supported tag wins, not the first tag', () {
      final resolved = resolveLocaleTags('system', const [
        'pt-BR',
        'fr-CA',
        'en-US',
      ]);
      expect(resolved.strings, 'fr');
      expect(resolved.formats, 'fr-CA');
    });

    test('strings come from the subtag, formats from the full tag', () {
      final austrian = resolveLocaleTags('system', const ['de-AT']);
      expect(austrian.strings, 'de');
      expect(austrian.formats, 'de-AT');
    });

    test('an unsupported language keeps its region for formats', () {
      // pt-BR gets ENGLISH strings but km, L/100 km, BRL and Monday. Falling
      // back to `en` formats too is the failure this pins: it would put a
      // Brazilian on US date order and dollars.
      final brazilian = resolveLocaleTags('system', const ['pt-BR']);
      expect(brazilian.strings, 'en');
      expect(brazilian.formats, 'pt-BR');
    });

    test('no device locales at all resolves to en', () {
      final none = resolveLocaleTags('system', const []);
      expect(none.strings, 'en');
      expect(none.formats, 'en');
    });
  });

  group("SPEC.md §5's four aliasing rows", () {
    test('every Sorani tag resolves to ckb', () {
      for (final tag in ['ckb', 'ckb-IQ', 'ckb-IR', 'ckb-Arab-IQ']) {
        expect(resolveLocaleTags('system', [tag]).strings, 'ckb', reason: tag);
      }
    });

    test('Kurmanji resolves to en, in Latin script, left to right', () {
      // The row people get wrong. `ku` is not a dialect of `ckb`; it is a
      // different language in a different script, and Sorani would be worse
      // for that reader than English.
      for (final tag in ['ku', 'kmr', 'ku-TR', 'ku-Latn-TR']) {
        final resolved = resolveLocaleTags('system', [tag]);
        expect(resolved.strings, 'en', reason: tag);
        expect(resolved.formats, tag, reason: tag);
      }
    });

    test('Dari resolves to fa', () {
      for (final tag in ['fa-AF', 'prs', 'prs-AF']) {
        expect(resolveLocaleTags('system', [tag]).strings, 'fa', reason: tag);
      }
    });

    test('every Arabic region resolves to the one MSA string set', () {
      for (final tag in ['ar', 'ar-EG', 'ar-MA', 'ar-SA']) {
        final resolved = resolveLocaleTags('system', [tag]);
        expect(resolved.strings, 'ar', reason: tag);
        // Region survives into formats: it is what decides ١٢٣ vs 123.
        expect(resolved.formats, tag, reason: tag);
      }
    });
  });

  test('fa, ar and ckb are right to left; the rest are not', () {
    for (final tag in ['fa', 'ar', 'ckb', 'fa-AF', 'ar-MA', 'ckb-IR']) {
      expect(isRightToLeft(tag), isTrue, reason: tag);
    }
    for (final tag in ['en', 'de', 'fr', 'pt-BR', 'ku', 'kmr', 'ku-TR']) {
      expect(isRightToLeft(tag), isFalse, reason: tag);
    }
  });

  group('the override list', () {
    test('is seven rows: system plus the six', () {
      expect(localeOverrideValues, hasLength(7));
      expect(localeOverrideValues.first, 'system');
      expect(localeOverrideValues.skip(1).toList(), [
        'en',
        'de',
        'fr',
        'fa',
        'ar',
        'ckb',
      ]);
    });

    test('each of the six names itself in its own language and script', () {
      // Never translated into the current UI language: someone stuck in the
      // wrong language has to be able to find their own.
      expect(localeEndonym('en'), 'English');
      expect(localeEndonym('de'), 'Deutsch');
      expect(localeEndonym('fr'), 'Français');
      expect(localeEndonym('fa'), 'فارسی');
      expect(localeEndonym('ar'), 'العربية');
      expect(localeEndonym('ckb'), 'کوردیی ناوەندی');
    });

    test('the endonyms are not English words', () {
      // Guard the guard: a table that quietly fell back to English would still
      // have seven rows and still pass the test above.
      for (final tag in ['fa', 'ar', 'ckb']) {
        expect(
          RegExp('[A-Za-z]').hasMatch(localeEndonym(tag)),
          isFalse,
          reason: '$tag is named in Latin script',
        );
      }
    });
  });

  group('the not-translated note', () {
    test('is needed only when the device language is none of the six', () {
      expect(needsNotTranslatedNote('system', const ['pt-BR']), isTrue);
      expect(needsNotTranslatedNote('system', const ['fr-CA']), isFalse);
      expect(needsNotTranslatedNote('system', const ['ku-TR']), isTrue);
    });

    test('is never shown when the user chose a language explicitly', () {
      // They are not stranded; they picked it.
      expect(needsNotTranslatedNote('de', const ['pt-BR']), isFalse);
    });
  });
}
