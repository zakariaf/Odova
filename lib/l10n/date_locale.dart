// The locale a DATE formatter is given — which is not the one a NUMBER
// formatter is given, and that distinction is the whole file.
//
// `numberFormatLocale` borrows SYMBOLS. It maps `ckb` to `fa` because `intl`
// has no Kurdish number symbols, and Maghreb Arabic to `de` because `intl`
// carries no European-separator Arabic at all. Both borrows are correct for
// what they do, and `calendar.dart` states the principle they rest on:
// **separators are shapes and month names are words.**
//
// Handing those borrows to `DateFormat` imports the donor's WORDS. Measured,
// before this existed: a Moroccan Arabic user's history rows read `Mi., 2.
// Sept.` — German — and a Kurdish user's read `چهارشنبه ۲ سپتامبر`, which is
// Persian. Three of the six shipped locales were affected.
//
// So date formatting resolves its own way: the tag if `intl` has it, else the
// language, else English. No donors.
import 'package:intl/intl.dart';
import 'package:odova/core/l10n/locale_resolution.dart';

/// The locale to hand `DateFormat` for [formatsTag].
///
/// SPEC.md §5: a device locale the app does not ship gets ENGLISH words with
/// that region's separators. The separators come from `numberFormatLocale`;
/// the words come from here, and the fallback to `en` is what makes a Tibetan
/// or Kabyle phone render a report instead of throwing.
String dateFormatLocale(String formatsTag) {
  final normalised = formatsTag.replaceAll('-', '_');

  // `DateFormat.localeExists` rather than a try/catch around a construction:
  // it is the same predicate `initializeDateFormatting` populates, so this
  // asks the question directly instead of provoking the error.
  if (DateFormat.localeExists(normalised)) return normalised;

  final language = languageOf(formatsTag);
  if (DateFormat.localeExists(language)) return language;

  // `en` is always present — `initializeDateFormatting` seeds it — so this is
  // a real floor rather than one more hopeful lookup.
  return 'en';
}
