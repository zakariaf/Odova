// The locale, as state the app can change without restarting.
//
// SPEC.md §5 *No restart*: changing language, direction, digits, calendar,
// units or currency rebuilds from the root and re-renders IN PLACE, preserving
// in-progress form input. Somebody halfway through an odometer reading at a
// pump, who realises the app is in the wrong language, must not lose the
// digits they already typed.
//
// The resolution itself is not here — it is a pure function in
// lib/core/l10n/locale_resolution.dart with no Flutter import and no device.
// This file is the seam between that decision and the widget tree.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/core/l10n/locale_resolution.dart';

/// What changed. The notification reschedule and the cached-layout
/// invalidation hang off this.
///
/// SPEC.md §5 puts "cancel all, re-render, re-schedule" on the other end:
/// notification bodies are baked into the OS at schedule time, so a language
/// change makes every scheduled body stale in a way nothing else detects.
enum LocaleAffectingChange {
  /// `Settings.language`.
  language,

  /// `Settings.numerals` — the digit block.
  numerals,

  /// `Settings.calendar` — Gregorian or Jalali.
  calendar,

  /// `Settings.units` — km/mi, L/gal.
  units,

  /// `Settings.currencyDisplay` — rial or toman.
  currency,
}

/// The device's locale preference list, in order.
///
/// A provider rather than a direct `PlatformDispatcher` read so a test can
/// state the device it is pretending to be. The default reads the real one.
final deviceLocalesProvider = Provider<List<Locale>>(
  (ref) => WidgetsBinding.instance.platformDispatcher.locales,
);

/// One locale-affecting change: what changed, and how many have happened.
///
/// The `sequence` is load-bearing rather than diagnostic. Riverpod notifies on
/// a value CHANGE, so a bare `LocaleAffectingChange` state would go silent the
/// second time the same kind fired — de to fr is a language change, and so is
/// fr to fa, and a listener that only saw the first would leave every
/// notification body baked in the previous language.
typedef LocaleChangeEvent = ({LocaleAffectingChange kind, int sequence});

/// The last locale-affecting change, or null before any.
///
/// Broadcast by [LocaleController]; consumed by whatever has to be torn down
/// and rebuilt when the language moves. A `Notifier` rather than a
/// `StateProvider`, which Riverpod 3 removed.
class LocaleAffectingChanges extends Notifier<LocaleChangeEvent?> {
  @override
  LocaleChangeEvent? build() => null;

  /// Announces [change] to everything that has to react to it.
  void emit(LocaleAffectingChange change) =>
      state = (kind: change, sequence: (state?.sequence ?? 0) + 1);
}

/// The last locale-affecting change.
final localeAffectingChangeProvider =
    NotifierProvider<LocaleAffectingChanges, LocaleChangeEvent?>(
      LocaleAffectingChanges.new,
    );

/// `Settings.language` and what it resolves to.
///
/// Restored BEFORE the first frame by `bootstrap`, which is the only way a
/// locale the OS cannot select — `ckb` on most devices — is ever reachable.
class LocaleController extends Notifier<String> {
  @override
  String build() => systemLanguage;

  /// Sets the persisted language, or [systemLanguage] to follow the device.
  ///
  /// A no-op when the value is unchanged: an event per call rather than per
  /// change would cancel and re-schedule every notification on a settings
  /// screen rebuild.
  void setLanguage(String language) {
    assert(
      localeOverrideValues.contains(language),
      '"$language" is not one of the seven rows',
    );
    if (state == language) return;
    state = language;
    ref
        .read(localeAffectingChangeProvider.notifier)
        .emit(LocaleAffectingChange.language);
  }
}

/// The setting.
final localeControllerProvider = NotifierProvider<LocaleController, String>(
  LocaleController.new,
);

/// The strings tag and the formats tag, resolved together.
///
/// One provider because it is one decision. Both halves come out of a single
/// [resolveLocaleTags] call over the same two inputs, and running it twice
/// invites the two answers to drift apart on the day somebody edits one call
/// site — which is the bug that would show as German words with American
/// separators and be blamed on `intl`.
final resolvedLocaleTagsProvider = Provider<ResolvedLocale>(
  (ref) => resolveLocaleTags(
    ref.watch(localeControllerProvider),
    ref.watch(deviceLocalesProvider).map((l) => l.toLanguageTag()).toList(),
  ),
);

/// The locale whose STRINGS the app should load.
///
/// Formats come from [resolvedFormatsLocaleProvider], and they are not the
/// same answer: `de-AT` reads German and formats Austrian, `pt-BR` reads
/// English and formats Brazilian.
final resolvedLocaleProvider = Provider<Locale>(
  (ref) => Locale(ref.watch(resolvedLocaleTagsProvider).strings),
);

/// The locale whose FORMATS the app should use — digits, dates, money, week
/// start. Always derived from the device, whatever language the user reads in.
final resolvedFormatsLocaleProvider = Provider<Locale>((ref) {
  final tag = ref.watch(resolvedLocaleTagsProvider).formats;
  final region = regionOf(tag);
  return region == null
      ? Locale(languageOf(tag))
      : Locale(languageOf(tag), region);
});
