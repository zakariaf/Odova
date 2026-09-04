// What a brand-new install's units, currency, calendar, digits and week start
// are set to.
//
// SPEC.md §5's table, and the sentence under it that is the whole point:
// "The last five columns are defaults, not properties of the language: they
// resolve from the device REGION, and each is a separate setting." English is
// the one of the six whose speakers are split across three unit systems, and
// reading "English -> miles" off the language row is how an Australian gets a
// fuel log in gallons.
//
// **A seed, not a live reference.** `firstrun.language`'s Continue writes these
// eight values once (SPEC.md §8) and nothing reads this file again. That is
// deliberate and it is not the "derived values are never persisted" rule being
// broken: a derived value is recomputed from data that still exists, while a
// seed is a starting point the user then owns. If these resolved live, a
// fortnight in Ireland would silently turn a British driver's miles into
// kilometres and their history into a chart with a step in it.
//
// Pure Dart, no Flutter import.
import 'package:meta/meta.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/locale_resolution.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/volume.dart';

/// The eight settings a first run seeds.
@immutable
class FormatDefaults {
  /// Creates a set of defaults.
  const FormatDefaults({
    required this.distance,
    required this.volume,
    required this.consumption,
    required this.currency,
    required this.calendar,
    required this.numerals,
    required this.firstDayOfWeek,
  });

  /// `Settings.distance_unit`.
  final DistanceUnit distance;

  /// `Settings.volume_unit`.
  final VolumeUnit volume;

  /// `Settings.consumption_unit`.
  final ConsumptionUnit consumption;

  /// `Settings.currency_default`.
  final Currency currency;

  /// `Settings.calendar`.
  final CalmCalendar calendar;

  /// `Settings.numerals` — never [CalmNumerals.auto].
  final CalmNumerals numerals;

  /// `Settings.first_day_of_week`.
  final Weekday firstDayOfWeek;
}

/// The eight defaults for a device whose FORMATS tag is [formatsTag].
///
/// The formats tag, not the strings tag: `pt-BR` reads English and formats
/// Brazilian, so it gets kilometres and reais rather than the miles and dollars
/// its English strings would imply.
FormatDefaults formatDefaultsFor(String formatsTag) {
  final region = regionOf(formatsTag);
  final language = languageOf(formatsTag);

  final measures = region == null
      // No region to go on, so SPEC's language row is the best available —
      // which is why a bare `en` is American and a bare `de` is metric.
      ? _byLanguage[language] ?? _metric
      : _imperialRegions[region] ?? _metric;

  return FormatDefaults(
    distance: measures.distance,
    volume: measures.volume,
    consumption: measures.consumption,
    currency: Currency.tryParse(_currencyFor(region, language))!,
    // Not reimplemented: three resolvers already own these answers, and a
    // second copy is a second answer waiting to disagree with the first.
    calendar: resolveCalendar(null, formatsTag),
    numerals: resolveNumerals(CalmNumerals.auto, formatsTag),
    firstDayOfWeek: firstDayOfWeek(formatsTag),
  );
}

/// Distance, volume and consumption travel together or not at all.
///
/// A separate `distanceFor` and `volumeFor` is how a car ends up logging miles
/// and litres and reporting mpg, which is a number in no unit system at all.
typedef _Measures = ({
  DistanceUnit distance,
  VolumeUnit volume,
  ConsumptionUnit consumption,
});

const _Measures _metric = (
  distance: DistanceUnit.km,
  volume: VolumeUnit.l,
  consumption: ConsumptionUnit.lPer100km,
);

const _Measures _usCustomary = (
  distance: DistanceUnit.mi,
  volume: VolumeUnit.galUs,
  consumption: ConsumptionUnit.mpgUs,
);

const _Measures _imperial = (
  distance: DistanceUnit.mi,
  volume: VolumeUnit.galUk,
  // 4.546 L to the gallon against the US 3.785. A different unit, not a
  // variant, and conflating them overstates a British car's economy by 20%.
  consumption: ConsumptionUnit.mpgUk,
);

/// The regions that are not metric. Everywhere else on earth is.
///
/// Stated as the exception rather than as a world-sized table of "km", because
/// the exception is short, stable and checkable, and the rule is not.
const _imperialRegions = <String, _Measures>{
  'US': _usCustomary,
  'GB': _imperial,
  // Both still post road distances in miles.
  'MM': _usCustomary,
  'LR': _usCustomary,
};

/// SPEC.md §5's six language rows, for a tag that carries no region.
const _byLanguage = <String, _Measures>{
  'en': _usCustomary,
  'de': _metric,
  'fr': _metric,
  'fa': _metric,
  'ar': _metric,
  'ckb': _metric,
};

/// The currency of a region, by ISO 4217.
///
/// SPEC.md §5 writes two open lists — `en-AU/en-IN/en-ZA/en-IE` as "local
/// currency" and `ar-*` as "region (SAR/AED/EGP…)" — and this is where the
/// ellipses are enumerated. Every entry is an ISO fact about a country rather
/// than a preference, which is what separates this table from the endonym table
/// EPIC-09's F-9.8 refused to write: a wrong currency code is visible on screen
/// and one tap from fixed, and it is checkable by anyone.
///
/// It covers the regions where the app's six languages are actually spoken plus
/// the largest economies. It is deliberately not exhaustive — there is no
/// version of this table that is — and [_currencyFor] says what happens off the
/// end of it.
const _regionCurrency = <String, String>{
  // The six languages' own regions, and everything SPEC names.
  'US': 'USD', 'GB': 'GBP', 'IE': 'EUR', 'AU': 'AUD', 'NZ': 'NZD',
  'CA': 'CAD', 'IN': 'INR', 'ZA': 'ZAR', 'SG': 'SGD', 'NG': 'NGN',
  'DE': 'EUR', 'AT': 'EUR', 'CH': 'CHF', 'LI': 'CHF', 'LU': 'EUR',
  'FR': 'EUR', 'BE': 'EUR', 'MC': 'EUR',
  'IR': 'IRR', 'AF': 'AFN',
  'IQ': 'IQD',
  // Arabic-speaking regions — SPEC's "SAR/AED/EGP…", written out.
  'SA': 'SAR', 'AE': 'AED', 'EG': 'EGP', 'MA': 'MAD', 'DZ': 'DZD',
  'TN': 'TND', 'LY': 'LYD', 'KW': 'KWD', 'QA': 'QAR', 'BH': 'BHD',
  'OM': 'OMR', 'JO': 'JOD', 'LB': 'LBP', 'SY': 'SYP', 'YE': 'YER',
  'SD': 'SDG', 'MR': 'MRU', 'SO': 'SOS', 'DJ': 'DJF', 'KM': 'KMF',
  'PS': 'ILS',
  // The rest of the euro zone and the larger economies beside it.
  'ES': 'EUR', 'IT': 'EUR', 'NL': 'EUR', 'PT': 'EUR', 'GR': 'EUR',
  'FI': 'EUR', 'EE': 'EUR', 'LV': 'EUR', 'LT': 'EUR', 'SK': 'EUR',
  'SI': 'EUR', 'CY': 'EUR', 'MT': 'EUR', 'HR': 'EUR',
  'SE': 'SEK', 'NO': 'NOK', 'DK': 'DKK', 'PL': 'PLN', 'CZ': 'CZK',
  'HU': 'HUF', 'RO': 'RON', 'BG': 'BGN', 'TR': 'TRY', 'UA': 'UAH',
  'RU': 'RUB', 'BR': 'BRL', 'MX': 'MXN', 'AR': 'ARS', 'CL': 'CLP',
  'CO': 'COP', 'PE': 'PEN', 'JP': 'JPY', 'CN': 'CNY', 'KR': 'KRW',
  'TW': 'TWD', 'HK': 'HKD', 'TH': 'THB', 'VN': 'VND', 'ID': 'IDR',
  'MY': 'MYR', 'PH': 'PHP', 'PK': 'PKR', 'BD': 'BDT', 'LK': 'LKR',
  'IL': 'ILS', 'KE': 'KES', 'GH': 'GHS', 'ET': 'ETB', 'TZ': 'TZS',
  'UG': 'UGX',
};

/// SPEC.md §5's language rows, for a region the table above does not carry.
const _languageCurrency = <String, String>{
  'en': 'USD',
  'de': 'EUR',
  'fr': 'EUR',
  'fa': 'IRR',
  'ckb': 'IQD',
  // SPEC writes `ar` as "region (…)" and gives it no language-level answer,
  // because there is no such thing as the Arabic currency. Saudi Arabia is the
  // largest of the twenty-odd, so a region-less `ar` lands there — and, unlike
  // the units, this is a preference rather than a fact, which is why it is
  // named here rather than buried.
  'ar': 'SAR',
};

/// The currency for [region], falling back to [language] and then to USD.
///
/// The last fallback is reached only by a tag whose region is not in the table
/// AND whose language is not one of the six — a device the app has already
/// decided to show English strings to. A consistent "we do not know you"
/// default is more honest there than a guess dressed as knowledge, and the user
/// changes it in one tap on `settings.units`.
String _currencyFor(String? region, String language) =>
    (region == null ? null : _regionCurrency[region]) ??
    _languageCurrency[language] ??
    'USD';
