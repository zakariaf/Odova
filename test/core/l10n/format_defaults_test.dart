// SPEC.md §5's defaults table, which is a table of REGIONS wearing language
// labels.
//
// "The last five columns are defaults, not properties of the language: they
// resolve from the device region, and each is a separate setting." The bug
// this file exists to catch is the obvious reading — that English means
// miles — which is true in Baltimore and false in Brisbane.
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/format_defaults.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/volume.dart';
import 'package:test/test.dart';

void main() {
  group("SPEC.md §5's table, row by row", () {
    test('the six language rows', () {
      for (final (tag, distance, consumption, currency) in [
        ('en', DistanceUnit.mi, ConsumptionUnit.mpgUs, 'USD'),
        ('de', DistanceUnit.km, ConsumptionUnit.lPer100km, 'EUR'),
        ('fr', DistanceUnit.km, ConsumptionUnit.lPer100km, 'EUR'),
        ('fa', DistanceUnit.km, ConsumptionUnit.lPer100km, 'IRR'),
        ('ckb', DistanceUnit.km, ConsumptionUnit.lPer100km, 'IQD'),
      ]) {
        final d = formatDefaultsFor(tag);
        expect(d.distance, distance, reason: tag);
        expect(d.consumption, consumption, reason: tag);
        expect(d.currency.code, currency, reason: tag);
      }
    });
  });

  group('the region overrides SPEC spells out', () {
    test('English is not one setting — en-US, en-GB and en-AU differ', () {
      // The whole point of the table. `en` is the only one of the six whose
      // speakers are split across three different unit systems, and reading
      // "English -> miles" off the language row is how an Australian gets a
      // fuel log in gallons.
      final us = formatDefaultsFor('en-US');
      expect(us.distance, DistanceUnit.mi);
      expect(us.volume, VolumeUnit.galUs);
      expect(us.consumption, ConsumptionUnit.mpgUs);
      expect(us.currency.code, 'USD');

      final gb = formatDefaultsFor('en-GB');
      expect(gb.distance, DistanceUnit.mi);
      // An imperial gallon is 4.546 L and a US one is 3.785. Two enum values,
      // never one plus a flag.
      expect(gb.volume, VolumeUnit.galUk);
      expect(gb.consumption, ConsumptionUnit.mpgUk);
      expect(gb.currency.code, 'GBP');

      for (final (tag, code) in [
        ('en-AU', 'AUD'),
        ('en-IN', 'INR'),
        ('en-ZA', 'ZAR'),
        ('en-IE', 'EUR'),
      ]) {
        final d = formatDefaultsFor(tag);
        expect(d.distance, DistanceUnit.km, reason: tag);
        expect(d.volume, VolumeUnit.l, reason: tag);
        expect(d.consumption, ConsumptionUnit.lPer100km, reason: tag);
        expect(d.currency.code, code, reason: tag);
      }
    });

    test('fa-AF is Dari: Persian strings, Jalali, AFN', () {
      final d = formatDefaultsFor('fa-AF');
      expect(d.currency.code, 'AFN');
      expect(d.calendar, CalmCalendar.persian);
    });

    test('ckb-IR takes Iran, ckb-IQ and an unknown region take Iraq', () {
      expect(formatDefaultsFor('ckb-IR').currency.code, 'IRR');
      expect(formatDefaultsFor('ckb-IR').calendar, CalmCalendar.persian);
      expect(formatDefaultsFor('ckb-IQ').currency.code, 'IQD');
      expect(formatDefaultsFor('ckb-IQ').calendar, CalmCalendar.gregorian);
      expect(formatDefaultsFor('ckb').currency.code, 'IQD');
    });

    test('every Arabic region gets its own currency, not one for all', () {
      // SPEC writes this as "region (SAR/AED/EGP…)" and leaves the list open.
      // These are ISO 4217 country facts, not preferences.
      for (final (tag, code) in [
        ('ar-SA', 'SAR'),
        ('ar-AE', 'AED'),
        ('ar-EG', 'EGP'),
        ('ar-IQ', 'IQD'),
        ('ar-MA', 'MAD'),
        ('ar-KW', 'KWD'),
        ('ar-JO', 'JOD'),
        ('ar-DZ', 'DZD'),
        ('ar-TN', 'TND'),
        ('ar-LY', 'LYD'),
      ]) {
        expect(formatDefaultsFor(tag).currency.code, code, reason: tag);
      }
    });
  });

  group('the parts that are already somebody else', () {
    test('calendar, numerals and week start come from the resolvers', () {
      // Not reimplemented here. `resolveCalendar`, `resolveNumerals` and
      // `firstDayOfWeek` already own these, and a second copy is a second
      // answer waiting to disagree.
      expect(formatDefaultsFor('fa-IR').calendar, CalmCalendar.persian);
      expect(formatDefaultsFor('ar-EG').numerals, CalmNumerals.arabicIndic);
      // The Maghreb writes Arabic with Latin digits.
      expect(formatDefaultsFor('ar-MA').numerals, CalmNumerals.latin);
      expect(formatDefaultsFor('en-US').firstDayOfWeek, sunday);
      expect(formatDefaultsFor('de-DE').firstDayOfWeek, monday);
      expect(formatDefaultsFor('ar-EG').firstDayOfWeek, saturday);
    });

    test('numerals is never auto — a seeded setting is a concrete value', () {
      // `auto` means "ask the locale", and writing it would make the seeded
      // setting move under the user the day they fly somewhere.
      for (final tag in [
        'en-US',
        'de-DE',
        'fa-IR',
        'ar-EG',
        'ar-MA',
        'ckb-IQ',
      ]) {
        expect(
          formatDefaultsFor(tag).numerals,
          isNot(CalmNumerals.auto),
          reason: tag,
        );
      }
    });
  });

  test('an unknown region falls back on the language, never on nothing', () {
    // A device set to a tag nobody anticipated still has to produce eight
    // usable settings — the first-run screen has no other source and cannot
    // show a dash.
    for (final tag in ['en-XK', 'de-LI', 'ar-ZZ', 'fa-XX', 'pt-BR']) {
      final d = formatDefaultsFor(tag);
      expect(d.currency.code, matches(RegExp(r'^[A-Z]{3}$')), reason: tag);
      expect(d.numerals, isNot(CalmNumerals.auto), reason: tag);
    }
    // A language outside the six reads English and formats its OWN region —
    // SPEC.md §5: "pt-BR reads English and formats Brazilian". Brazil is
    // metric and spends reais, and neither fact depends on which of the six
    // string sets the reader ended up with.
    expect(formatDefaultsFor('pt-BR').distance, DistanceUnit.km);
    expect(formatDefaultsFor('pt-BR').currency.code, 'BRL');
  });
}
