// SPEC.md §13's live format preview, as golden vectors.
//
// Byte-for-byte, in six locales, because the preview is the only thing on
// `settings.units` that tells a user whether their choices are right — and
// every rule it composes (§5's numerals, calendars, separators, currency
// placement and exponent) is one a person cannot hold in their head.
import 'package:intl/date_symbol_data_local.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/features/settings/domain/format_preview.dart';
import 'package:odova/features/settings/domain/units_catalogue.dart';
import 'package:test/test.dart';

final Currency _eur = Currency.tryParse('EUR')!;
final Currency _usd = Currency.tryParse('USD')!;
final Currency _irr = Currency.tryParse('IRR')!;

/// The consumption label's `100` is a PLACEHOLDER, shaped like every other
/// number on the screen — never a baked literal.
///
/// The property test below is what makes that load-bearing: a hard-coded
/// `L/100 km` puts Latin digits into a line whose figure is Arabic-Indic, and
/// the mixed render is the exact failure §5 forbids. `glance_tiles.dart`
/// already passes a shaped hundred for the same reason.
String _hundred(CalmNumerals numerals, String tag) =>
    shapeDigits('100', resolveNumerals(numerals, tag));

FormatLabels _enLabels([
  CalmNumerals numerals = CalmNumerals.auto,
  String tag = 'en-GB',
]) => (
  distance: 'km',
  volume: 'L',
  consumption: 'L/${_hundred(numerals, tag)} km',
  separator: ' · ',
);

FormatLabels _faLabels([
  CalmNumerals numerals = CalmNumerals.extendedArabicIndic,
  String tag = 'fa-IR',
]) => (
  distance: 'کیلومتر',
  volume: 'لیتر',
  consumption: 'لیتر/${_hundred(numerals, tag)} کیلومتر',
  separator: ' · ',
);

final FormatLabels _en = _enLabels();
final FormatLabels _fa = _faLabels();

FormatPreview _preview({
  required String tag,
  required FormatLabels labels,
  SettingsFormats? formats,
}) => buildFormatPreview(
  formats: formats ?? SettingsFormats(currency: _eur),
  formatsTag: tag,
  labels: labels,
);

/// The digit blocks §5 ships, so a render can be checked for mixing.
const Map<String, String> _blocks = {
  'latin': '0123456789',
  'arabicIndic': '٠١٢٣٤٥٦٧٨٩',
  'extendedArabicIndic': '۰۱۲۳۴۵۶۷۸۹',
};

Set<String> _blocksIn(String text) => {
  for (final entry in _blocks.entries)
    if (text.split('').any(entry.value.contains)) entry.key,
};

void main() {
  // The ICU locale tables the date formatters read. `dateFormatLocale` asks
  // `DateFormat.localeExists`, which throws rather than answering false until
  // they are loaded — and a pure-Dart test gets none of the loading a widget
  // test does for free.
  setUpAll(initializeDateFormatting);

  test('en-GB renders the date, the distance and the tankful', () {
    final preview = _preview(tag: 'en-GB', labels: _en);

    expect(preview.dateAndDistance, contains('12'));
    expect(preview.dateAndDistance, contains('187,412'));
    expect(preview.dateAndDistance, contains('km'));
    expect(preview.quantities, contains('42.8'));
    expect(preview.quantities, contains('6.4'));
  });

  test('de-DE uses its own group and decimal separators', () {
    final preview = _preview(tag: 'de-DE', labels: _en);

    expect(preview.dateAndDistance, contains('187.412'));
    expect(preview.quantities, contains('42,8'));
  });

  test('fr-FR groups with U+202F, asserted as a codepoint', () {
    // The narrow no-break space, not "a space that looks narrow". A plain
    // U+0020 here is a line break waiting to happen between a number and its
    // own thousands, and the two are indistinguishable in a diff.
    final preview = _preview(tag: 'fr-FR', labels: _en);

    expect(preview.dateAndDistance, contains('187\u202F412'));
    expect(preview.dateAndDistance, isNot(contains('187 412')));
  });

  test('fa with Persian digits and the Jalali calendar', () {
    // The reference's sample under the Jalali calendar: 2 September 2026 is
    // 11 Shahrivar 1405.
    final preview = _preview(
      tag: 'fa-IR',
      labels: _fa,
      formats: SettingsFormats(
        currency: _irr,
        numerals: CalmNumerals.extendedArabicIndic,
        calendar: CalmCalendar.persian,
      ),
    );

    expect(preview.dateAndDistance, contains('۱۸۷٬۴۱۲'));
    expect(preview.dateAndDistance, contains('۱۴۰۵'));
    expect(preview.dateAndDistance, contains('کیلومتر'));
  });

  test('ar-EG renders Arabic-Indic and ar-MA renders Latin', () {
    // §5's Maghreb fork: the same language, two digit sets, and getting it
    // wrong makes every figure in the app look foreign to one of them.
    expect(
      _blocksIn(_preview(tag: 'ar-EG', labels: _en).dateAndDistance),
      {'arabicIndic'},
    );
    expect(
      _blocksIn(_preview(tag: 'ar-MA', labels: _en).dateAndDistance),
      {'latin'},
    );
  });

  test('one numbering system per render, over every combination', () {
    // A property test, because the failure is a mixed line — `12 March 2026 ·
    // ۱۴۲٬۳۸۰ کیلومتر` — which reads as a rendering fault rather than as a
    // setting the user can fix.
    for (final tag in ['en-GB', 'de-DE', 'fr-FR', 'fa-IR', 'ar-EG', 'ar-MA']) {
      for (final numerals in CalmNumerals.values) {
        for (final calendar in CalmCalendar.values) {
          final preview = buildFormatPreview(
            formats: SettingsFormats(
              currency: _eur,
              numerals: numerals,
              calendar: calendar,
            ),
            formatsTag: tag,
            labels: _enLabels(numerals, tag),
          );

          for (final line in [preview.dateAndDistance, preview.quantities]) {
            expect(
              _blocksIn(line).length,
              lessThanOrEqualTo(1),
              reason: '$tag/$numerals/$calendar: "$line"',
            );
          }
        }
      }
    }
  });

  test('a number and its unit are one isolate, never two', () {
    // §5: a figure and its unit are one atomic run. Split, `km` ends up on the
    // far side of a Persian line from the number it belongs to.
    const fsi = '\u2068';
    const pdi = '\u2069';
    final line = _preview(tag: 'fa-IR', labels: _fa).dateAndDistance;
    final distance = line.split(' · ').last;

    // FSI, not LRI: `isolate()` uses first-strong so the run takes its
    // direction from its own content rather than being forced either way.
    expect(distance.startsWith(fsi), isTrue);
    expect(distance.endsWith(pdi), isTrue);
    // And nothing between the digits and the word — one atomic run, so `km`
    // cannot end up on the far side of the line from its number.
    final inside = distance.substring(1, distance.length - 1);
    expect(inside, isNot(contains(fsi)));
    expect(inside, isNot(contains(pdi)));
  });

  test('the separator comes from the labels, not from the code', () {
    // Which mark joins two facts is a translation decision. A `' · '` literal
    // in the builder takes it away from the translator.
    final preview = buildFormatPreview(
      formats: SettingsFormats(currency: _eur),
      formatsTag: 'en-GB',
      labels: (
        distance: 'km',
        volume: 'L',
        consumption: 'L/100 km',
        separator: ' — ',
      ),
    );

    expect(preview.dateAndDistance, contains(' — '));
    expect(preview.dateAndDistance, isNot(contains(' · ')));
  });

  test('unit words come from the labels, never from the platform', () {
    // §13: unit abbreviations come from our ARB files. ICU's unit formatter
    // has its own opinion and it is not always ours.
    final preview = _preview(tag: 'fa-IR', labels: _fa);

    expect(preview.dateAndDistance, contains('کیلومتر'));
    expect(preview.dateAndDistance, isNot(contains('km')));
  });

  test('toman renders its own word and never an ISO code', () {
    final preview = _preview(
      tag: 'fa-IR',
      labels: _fa,
      formats: SettingsFormats(
        currency: _irr,
        currencyDisplay: 'toman',
        numerals: CalmNumerals.extendedArabicIndic,
      ),
    );

    expect(preview.quantities, contains('تومان'));
    // And no ISO code beside it. The stored currency is still rials — the
    // toman is a display convention worth ten of them and not a currency —
    // and `no_currency_conversion_test.dart` keeps the non-ISO code out of
    // the tree entirely, which is why this asserts on the code that DOES
    // exist rather than naming the one that must not.
    expect(preview.quantities, isNot(contains('IRR')));
  });

  test('the US pairing suggests mpg; an explicit choice is left alone', () {
    expect(
      suggestConsumptionUnit(
        distance: DistanceUnit.mi,
        volume: VolumeUnit.galUs,
        chosen: false,
      ),
      ConsumptionUnit.mpgUs,
    );
    expect(
      suggestConsumptionUnit(
        distance: DistanceUnit.km,
        volume: VolumeUnit.l,
        chosen: false,
      ),
      ConsumptionUnit.lPer100km,
    );
    // A rideshare driver in the US who prefers L/100 km picked it on purpose.
    expect(
      suggestConsumptionUnit(
        distance: DistanceUnit.mi,
        volume: VolumeUnit.galUs,
        chosen: true,
      ),
      isNull,
    );
    // And a pairing with no conventional unit gets no invention.
    expect(
      suggestConsumptionUnit(
        distance: DistanceUnit.mi,
        volume: VolumeUnit.l,
        chosen: false,
      ),
      isNull,
    );
  });

  test(
    'a Persian speaker on a British phone can still choose their digits',
    () {
      // §5 keeps FORMATS with the region and STRINGS with the language, so this
      // user reads Persian words and British numbers. Keying the local row on
      // the formats tag alone would offer them Latin and Latin — no way to
      // choose Persian digits at all.
      expect(numeralOptionsFor('en-GB', stringsTag: 'fa'), [
        CalmNumerals.auto,
        CalmNumerals.latin,
        CalmNumerals.extendedArabicIndic,
      ]);
    },
  );

  test('the numeral rows are three, and Local only where it differs', () {
    // A German user offered a "Local" row that renders the same digits as the
    // row above it is being asked a question with one answer.
    expect(numeralOptionsFor('de-DE'), [
      CalmNumerals.auto,
      CalmNumerals.latin,
    ]);
    expect(numeralOptionsFor('fa-IR'), [
      CalmNumerals.auto,
      CalmNumerals.latin,
      CalmNumerals.extendedArabicIndic,
    ]);
    expect(numeralOptionsFor('ar-EG'), [
      CalmNumerals.auto,
      CalmNumerals.latin,
      CalmNumerals.arabicIndic,
    ]);
    // The Maghreb fork again: `ar-MA`'s default IS Latin.
    expect(numeralOptionsFor('ar-MA'), [
      CalmNumerals.auto,
      CalmNumerals.latin,
    ]);
  });

  test('exactly two calendars are offered', () {
    // §5 ships one alternative, not a catalogue: a list of twelve would be a
    // list eleven of which nobody has checked a single date against.
    expect(CalmCalendar.values, hasLength(2));
  });

  test('the consumption figure converts with the unit beside it', () {
    // A bare `6.4` was the bug: the distance and the volume both went through
    // `inUnit` and this did not, so choosing miles and US gallons gave
    // `11.3 gal · €74.20 · 6.4 mpg` over `116,452 mi` — three figures of which
    // one was in a unit nobody had selected. This is the one card on the
    // screen whose entire job is showing what the settings produce.
    final metric = buildFormatPreview(
      formats: SettingsFormats(currency: _eur),
      formatsTag: 'en-GB',
      labels: _en,
    );
    final imperial = buildFormatPreview(
      formats: SettingsFormats(
        currency: _usd,
        distanceUnit: DistanceUnit.mi,
        volumeUnit: VolumeUnit.galUs,
        consumptionUnit: ConsumptionUnit.mpgUs,
      ),
      formatsTag: 'en-US',
      labels: _en,
    );

    expect(metric.quantities, contains('6.4'));
    // 6.4 L/100 km is about 36.8 mpg US.
    expect(imperial.quantities, contains('36.8'));
    expect(imperial.quantities, isNot(contains('6.4')));
  });
}
