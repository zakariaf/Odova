// `firstrun.language`'s two jobs.
//
// SPEC.md §8: tapping a row "sets `Settings.language` in memory and re-renders
// the app from the root immediately, this screen included", and Continue writes
// eight settings in ONE transaction. §13's numbered list reads as though
// applying a language also seeds the format defaults; §8's "Data out — one
// write on Continue" is the one that survives a kill, and it is what this
// implements. Nothing is on disk until the user has said Continue.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/l10n/format_defaults.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/schema_version.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/l10n/locale_controller.dart';

/// What the language step is doing.
enum FirstRunLanguageStatus {
  /// The only entry state. SPEC.md §8: "Loaded (the only entry state)".
  ready,

  /// A Continue is in flight. Its whole purpose is that a second tap on a slow
  /// disk does not become a second write.
  saving,

  /// The write failed. Only a disk write can fail on this screen.
  failed,
}

/// Applies a language, and commits the first-run settings once.
class FirstRunLanguageNotifier extends Notifier<FirstRunLanguageStatus> {
  @override
  FirstRunLanguageStatus build() => FirstRunLanguageStatus.ready;

  /// Applies [language] to the running app. Writes nothing.
  ///
  /// The selection lives in [LocaleController] rather than in this notifier's
  /// state, because `MaterialApp.locale` already watches that and a second copy
  /// here would be a second answer to "what language is this". SPEC.md §13: the
  /// user has to see the result while the list is still on screen.
  void select(String language) =>
      ref.read(localeControllerProvider.notifier).setLanguage(language);

  /// Writes the eight settings SPEC.md §8 lists, in one transaction.
  ///
  /// Returns whether the app may advance. A second call while the first is in
  /// flight is a double tap rather than a second intention, so it is refused —
  /// and refused with the SAME answer, because reporting a failure would put an
  /// error on a screen where nothing failed.
  Future<bool> commit() async {
    if (state == FirstRunLanguageStatus.saving) return true;
    state = FirstRunLanguageStatus.saving;

    final defaults = formatDefaultsFor(
      ref.read(resolvedLocaleTagsProvider).formats,
    );
    final now = ref.read(clockProvider).now().millisecondsSinceEpoch;

    // The row may already exist: a kill after Continue and before a vehicle
    // exists replays this screen, because `onboarding_done` is still false. Its
    // `created_at` is the install's, not this pass's.
    final existing = await ref.read(settingsRepositoryProvider).read();
    final createdAt = switch (existing) {
      Ok(:final value) => value.createdAtUtcMs,
      _ => now,
    };

    final written = await ref
        .read(settingsRepositoryProvider)
        .save(
          AppSettings(
            schemaVersion: kLatestSchemaVersion,
            currencyDefault: defaults.currency,
            createdAtUtcMs: createdAt,
            updatedAtUtcMs: now,
            language: ref.read(localeControllerProvider),
            calendar: defaults.calendar.wire,
            numerals: defaults.numerals.wire,
            firstDayOfWeek: defaults.firstDayOfWeek,
            distanceUnit: defaults.distance,
            volumeUnit: defaults.volume,
            consumptionUnit: defaults.consumption,
            // SPEC.md §8 spells both out. `onboarding_done` stays false until a
            // vehicle exists, so a kill between the two first-run screens
            // replays from here rather than opening an app with no car.
          ),
        );

    final ok = written is Ok;
    state = ok ? FirstRunLanguageStatus.ready : FirstRunLanguageStatus.failed;
    return ok;
  }
}

/// The language step.
final firstRunLanguageProvider =
    NotifierProvider<FirstRunLanguageNotifier, FirstRunLanguageStatus>(
      FirstRunLanguageNotifier.new,
    );
