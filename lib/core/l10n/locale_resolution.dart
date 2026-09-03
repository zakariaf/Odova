// SPEC.md §5's locale selection, as a pure function.
//
// No Flutter import, no clock, no device: given the persisted setting and the
// device's locale list, this returns which strings to load and which formats
// to use. Those are two different answers and the difference is the whole
// point — `de-AT` gets German words and Austrian dates; `pt-BR` gets English
// words and Brazilian everything else.

/// The six languages Odova ships strings for.
const supportedLanguages = <String>['en', 'de', 'fr', 'fa', 'ar', 'ckb'];

/// The three written right to left.
const rightToLeftLanguages = <String>{'fa', 'ar', 'ckb'};

/// The sentinel `Settings.language` uses for "follow the device".
///
/// A value of the setting, not a seventh string set.
const systemLanguage = 'system';

/// The rows `settings.language` renders: the sentinel, then the six.
const localeOverrideValues = <String>[systemLanguage, ...supportedLanguages];

/// Language subtags that mean one of the six under another name.
///
/// `ku` is deliberately absent, and that absence is the rule people get wrong:
/// Kurmanji is a different language written in LATIN script, so serving it
/// Sorani in Arabic script is worse for that reader than serving them English.
const _aliases = <String, String>{
  // Dari is mutually intelligible with Persian in writing.
  'prs': 'fa',
};

/// What the app resolved to: which strings, and which formats.
typedef ResolvedLocale = ({String strings, String formats});

/// The language subtag of a BCP 47 tag: `de-AT` -> `de`.
String languageOf(String tag) => tag.split(RegExp('[-_]')).first.toLowerCase();

/// Whether [tag]'s language is written right to left.
bool isRightToLeft(String tag) =>
    rightToLeftLanguages.contains(_stringsFor(tag));

/// SPEC.md §5's three-step selection.
///
/// [settingLanguage] is `Settings.language`: one of the six, or
/// [systemLanguage]. [deviceTags] is the device's preference list, in order.
ResolvedLocale resolveLocaleTags(
  String settingLanguage,
  List<String> deviceTags,
) {
  // Formats always come from the device, whatever the strings do: someone
  // reading German in Tehran wants German words and Iranian dates.
  final formats = deviceTags.isEmpty ? 'en' : deviceTags.first;

  // 1. An explicit setting wins outright.
  if (settingLanguage != systemLanguage &&
      supportedLanguages.contains(settingLanguage)) {
    return (strings: settingLanguage, formats: formats);
  }

  // 2. The device list, in order, matched on the LANGUAGE SUBTAG.
  for (final tag in deviceTags) {
    final strings = _stringsFor(tag);
    if (strings != null) return (strings: strings, formats: tag);
  }

  // 3. English strings, region-derived formats. Not `en` formats: falling back
  // to those as well would put a Brazilian on US date order and dollars.
  return (strings: 'en', formats: formats);
}

/// Whether the "not translated yet" note belongs under the override list.
///
/// Only when the device language is none of the six AND the user has not
/// chosen one — someone who picked a language is not stranded in it.
bool needsNotTranslatedNote(String settingLanguage, List<String> deviceTags) =>
    settingLanguage == systemLanguage &&
    !deviceTags.any((tag) => _stringsFor(tag) != null);

/// Each language's name in its own language and script.
///
/// Never translated into the current UI language. Someone who has ended up in
/// a language they cannot read has to be able to find their own by shape.
String localeEndonym(String language) => switch (language) {
  'en' => 'English',
  'de' => 'Deutsch',
  'fr' => 'Français',
  'fa' => 'فارسی',
  'ar' => 'العربية',
  'ckb' => 'کوردیی ناوەندی',
  _ => throw ArgumentError.value(language, 'language', 'not one of the six'),
};

/// Which of the six [tag] should read, or null if none of them.
String? _stringsFor(String tag) {
  final language = languageOf(tag);
  if (supportedLanguages.contains(language)) return language;
  return _aliases[language];
}
