// SPEC.md §13's `settings.units`, built against
// `design/reference/calm/settings.units-*.png`.
//
// The screen that makes the Persian build real. Seven rows in two groups, and
// above them a preview that changes in the same frame as any row below it —
// which is the reason this is not a list of dropdowns. §5's rules interact,
// nobody can hold them in their head, and a user can look at
// `۲ شهریور ۱۴۰۵ · ۱۸۷٬۴۱۲ کیلومتر` and know at once whether it is right.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/settings/data/settings_writer.dart';
import 'package:odova/features/settings/domain/format_preview.dart';
import 'package:odova/features/settings/domain/units_catalogue.dart';
import 'package:odova/features/settings/presentation/currency_sheet.dart';
import 'package:odova/features/settings/presentation/units_labels.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_sheet.dart';
import 'package:odova/ui/calm/calm_surface.dart';

/// The pairing the app last filled the consumption row in from, or null.
///
/// A `ValueNotifier` rather than screen state, because the write that triggers
/// it is `async` and the rebuild that follows comes from the settings stream —
/// a `setState` in between would be a second source of truth for one row.
final ValueNotifier<({DistanceUnit distance, VolumeUnit volume})?>
_suggestionShown = ValueNotifier(null);

/// §13's units and formats screen.
class UnitsScreen extends ConsumerWidget {
  /// Creates the screen.
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    final settings = ref.watch(settingsProvider).value;
    final writer = ref.read(settingsWriterProvider);

    final distance = settings?.distanceUnit ?? DistanceUnit.km;
    final volume = settings?.volumeUnit ?? VolumeUnit.l;
    final consumption = settings?.consumptionUnit ?? ConsumptionUnit.lPer100km;
    final currency = settings?.currencyDefault ?? Currency.tryParse('EUR')!;
    final calendar = CalmCalendar.fromWire(settings?.calendar);
    final numerals = CalmNumerals.fromWire(settings?.numerals);

    final hundred = shapeDigits('100', resolveNumerals(numerals, tag));
    final preview = buildFormatPreview(
      formats: SettingsFormats(
        currency: currency,
        numerals: numerals,
        calendar: calendar,
        distanceUnit: distance,
        volumeUnit: volume,
        consumptionUnit: consumption,
        currencyDisplay: settings?.currencyDisplay ?? 'none',
      ),
      formatsTag: tag,
      labels: formatLabelsFor(l10n, distance, volume, consumption, hundred),
    );

    /// Applies a unit change and, where §13's pairing rule has an opinion,
    /// the consumption unit that goes with it.
    ///
    /// Reads the settings back AFTER the write rather than closing over the
    /// values this build rendered. The closure version looked right and was
    /// wrong the moment a user changed two rows in a row: switching to miles
    /// and then to US gallons asked the pairing rule about (km, gal) and then
    /// about (mi, L), neither of which has an answer — so the suggestion
    /// never fired and the screen sat on `L/100 km` under miles and gallons.
    Future<void> applyPairing() async {
      // Through the REPOSITORY, not `settingsProvider.value`. The watched
      // stream is asynchronous: reading it immediately after a write gives the
      // row as it was before, so the pairing rule was asked about the previous
      // pairing and never fired.
      final read = await ref.read(settingsRepositoryProvider).read();
      final now = read is Ok<AppSettings, PersistFailure> ? read.value : null;
      final nextDistance = now?.distanceUnit ?? distance;
      final nextVolume = now?.volumeUnit ?? volume;
      final current = now?.consumptionUnit ?? consumption;

      final suggested = suggestConsumptionUnit(
        distance: nextDistance,
        volume: nextVolume,
        // A value NO pairing implies is one the user picked, and it survives.
        // The rule this replaced compared against what the previous pairing
        // implied, which is path-dependent: pick `km/L` on km and litres,
        // switch volume to gallons (nothing happens, correctly), then switch
        // distance to miles — the previous pairing implied null, the app read
        // that as "not chosen", and overwrote the choice. §13: never override
        // an explicit choice again.
        chosen: !kSuggestibleConsumptionUnits.contains(current),
      );

      if (suggested != null && suggested != current) {
        await writer.setConsumptionUnit(suggested);
        // And SAY so. `unitsConsumptionSuggested` was translated into all six
        // ARB files and rendered by nothing, while the row changed under the
        // user's hand — which its own ARB description names as the failure:
        // "a value that changed without being touched reads as a bug".
        _suggestionShown.value = (
          distance: nextDistance,
          volume: nextVolume,
        );
      }
    }

    Future<void> setDistance(DistanceUnit next) async {
      await writer.setDistanceUnit(next);
      await applyPairing();
    }

    Future<void> setVolume(VolumeUnit next) async {
      await writer.setVolumeUnit(next);
      await applyPairing();
    }

    return CalmScaffold(
      appBar: CalmAppBar.pushed(
        title: l10n.settingsUnitsRow,
        startLabel: l10n.commonBack,
        onStart: () => Navigator.of(context).maybePop(),
      ),
      children: [
        _PreviewCard(preview: preview, label: l10n.unitsPreviewLabel),
        SizedBox(height: space.s5),
        Text(
          l10n.unitsGroupMeasurement,
          style: type.label.copyWith(color: colors.ink2),
        ),
        SizedBox(height: space.s3),
        CalmRowGroup(
          rows: [
            _OptionRow<DistanceUnit>(
              title: l10n.unitsRowDistance,
              current: distance,
              options: DistanceUnit.values,
              labelFor: (u) => distanceOptionLabel(l10n, u),
              onChanged: (u) => unawaited(setDistance(u)),
            ),
            _OptionRow<VolumeUnit>(
              title: l10n.unitsRowVolume,
              current: volume,
              options: VolumeUnit.values,
              labelFor: (u) => volumeOptionLabel(l10n, u),
              onChanged: (u) => unawaited(setVolume(u)),
            ),
            _OptionRow<ConsumptionUnit>(
              title: l10n.unitsRowConsumption,
              current: consumption,
              options: ConsumptionUnit.values,
              labelFor: (u) => consumptionOptionLabel(l10n, u, hundred),
              // A DELIBERATE choice clears the note: the row no longer changed
              // by itself, so the sentence explaining that it did would be
              // explaining something that did not happen.
              onChanged: (u) {
                _suggestionShown.value = null;
                unawaited(writer.setConsumptionUnit(u));
              },
              subtitle: _suggestionShown.value == null
                  ? null
                  : l10n.unitsConsumptionSuggested(
                      distanceOptionLabel(
                        l10n,
                        _suggestionShown.value!.distance,
                      ),
                      volumeOptionLabel(l10n, _suggestionShown.value!.volume),
                    ),
            ),
            CalmListRow(
              title: l10n.unitsRowCurrency,
              value: currencyRowLabel(currency),
              showChevron: true,
              // A SHEET, not a push. §7 allows no branch in this app three
              // levels deep, and the currency list is long enough to need a
              // search field — which a pushed screen would put a navigation
              // level away from the preview it changes.
              onTap: () => unawaited(
                showCurrencySheet(
                  context,
                  current: currency,
                  onSelected: (next) =>
                      unawaited(writer.setCurrencyDefault(next)),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: space.s5),
        Text(
          l10n.unitsGroupDatesNumbers,
          style: type.label.copyWith(color: colors.ink2),
        ),
        SizedBox(height: space.s3),
        CalmRowGroup(
          rows: [
            _OptionRow<CalmCalendar>(
              title: l10n.unitsRowCalendar,
              current: calendar,
              options: CalmCalendar.values,
              labelFor: (c) => calendarOptionLabel(l10n, c),
              onChanged: (c) => unawaited(writer.setCalendar(c.wire)),
            ),
            _OptionRow<CalmNumerals>(
              title: l10n.unitsRowNumerals,
              current: numerals,
              options: numeralOptionsFor(
                tag,
                stringsTag: ref.watch(resolvedLocaleTagsProvider).strings,
              ),
              labelFor: (n) => numeralsOptionLabel(l10n, n, tag),
              onChanged: (n) => unawaited(writer.setNumerals(n)),
            ),
            _OptionRow<int>(
              title: l10n.unitsRowFirstDay,
              current: settings?.firstDayOfWeek ?? DateTime.monday,
              // SATURDAY too, and it is not a nicety: `calendar.dart` seeds
              // Saturday for IR, IQ, EG, AE, KW, QA, BH, OM, JO, SY, YE and
              // PS, and §5's table gives it for `fa`, `ar` and `ckb`. With
              // Monday and Sunday alone, an Iranian user opened a row reading
              // `شنبه`, found neither option ticked, and could not set it back
              // whatever they tapped — the whole RTL audience locked out of a
              // row by its own default.
              options: const [
                DateTime.saturday,
                DateTime.sunday,
                DateTime.monday,
              ],
              labelFor: (d) => weekdayName(tag, d),
              onChanged: (d) => unawaited(writer.setFirstDayOfWeek(d)),
            ),
          ],
        ),
        SizedBox(height: space.s4),
        // §13's footer, and it belongs BEFORE the tap rather than after:
        // somebody about to change their currency needs to know that nothing
        // already entered is rewritten and no rate is applied — §2 forbids a
        // rate anywhere in this app — while they are still deciding.
        Text(
          l10n.unitsFooter,
          style: type.caption.copyWith(color: colors.ink3),
        ),
      ],
    );
  }
}

/// The live preview, as the reference draws it: a tinted card, a label, and
/// two lines.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview, required this.label});

  final FormatPreview preview;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    // `CalmSurface`, not a hand-built `BoxDecoration`: only `lib/ui/calm/`
    // builds a decoration, and `check_component_hygiene.sh` is the gate that
    // keeps a feature from quietly inventing its own card.
    return CalmSurface(
      color: colors.surface2,
      radius: shapes.radiusXl,
      padding: EdgeInsetsDirectional.all(space.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: type.label.copyWith(color: colors.ink3)),
          SizedBox(height: space.s2),
          Text(
            preview.dateAndDistance,
            style: type.headline.copyWith(fontWeight: type.semi),
          ),
          SizedBox(height: space.s1),
          Text(
            preview.quantities,
            style: type.body.copyWith(color: colors.ink2),
          ),
        ],
      ),
    );
  }
}

/// One row that opens a sheet of choices.
///
/// A sheet and not a push, for every one of them: §7 allows no branch three
/// levels deep, and seven pushed sub-screens would put each choice a
/// navigation level away from the preview that exists to explain it.
class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.title,
    required this.current,
    required this.options,
    required this.labelFor,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final T current;
  final List<T> options;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;

  /// Why this row's value changed without being touched, where it did.
  final String? subtitle;

  @override
  Widget build(BuildContext context) => CalmListRow(
    title: title,
    subtitle: subtitle,
    value: labelFor(current),
    showChevron: true,
    onTap: () => unawaited(
      CalmSheet.show<void>(
        context,
        builder: (sheetContext) => CalmSheet(
          title: title,
          children: [
            CalmRowGroup(
              rows: [
                for (final option in options)
                  CalmListRow(
                    title: labelFor(option),
                    selected: option == current,
                    end: option == current
                        ? Icon(
                            Icons.check,
                            size: CalmSpace.of(sheetContext).iconMd,
                            color: CalmColors.of(sheetContext).brand,
                          )
                        : null,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onChanged(option);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
