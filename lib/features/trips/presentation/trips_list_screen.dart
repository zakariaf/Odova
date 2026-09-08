// SPEC.md §12's `trips.list`, built against
// `design/reference/calm/trips.list-*.png`.
//
// The reference: a three-up tile strip, an open trip pinned in its own card
// with End this trip, then an `Earlier` header and a row group. Two deliberate
// divergences from §12's prose, both because epics/README.md rule 4 makes the
// reference the authority:
//
//   * The purpose is a word in the row's meta line, not a chip beside the
//     title. §12's prose says chips and worries about German ones wrapping;
//     the reference draws `1–2 Aug · 145 km · business`, which has the same
//     information and no wrapping problem to solve.
//   * The count sits at the end edge of the `Earlier` header rather than in
//     the tile strip, which is where the reference puts it (`See all 14`) and
//     where §12's fourth header fact therefore lands. It is a LABEL and not a
//     link: this screen already lists every trip, and §7 forbids a third push
//     in this tab for it to lead to.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/trips/application/trips_list_model.dart';
import 'package:odova/features/trips/presentation/trip_labels.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_all_clear.dart';
import 'package:odova/ui/calm/calm_badge.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_card.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_tile.dart';

/// §12's trips list.
class TripsListScreen extends ConsumerWidget {
  /// Creates the screen.
  const TripsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    final vehicleId = ref.watch(activeVehicleIdProvider);
    final vehicle = ref
        .watch(vehiclesProvider)
        .value
        ?.where((v) => v.id == vehicleId)
        .firstOrNull;
    final unit = effectiveDistanceUnit(
      vehicle,
      ref.watch(settingsProvider).value,
    );

    final model = vehicleId == null
        ? TripsListModel.loading
        : ref.watch(tripsListProvider(vehicleId));

    void openTrip(String? tripId) => unawaited(
      context.push(tripId == null ? Routes.tripNew : Routes.tripEdit(tripId)),
    );

    return CalmScaffold(
      appBar: CalmAppBar.pushed(
        title: l10n.tripsTitle,
        actions: [
          CalmAppBarAction(
            label: l10n.tripsAddAction,
            icon: Icons.add,
            onTap: () => openTrip(null),
          ),
        ],
      ),
      children: [
        if (model.isEmpty)
          _TripsEmpty(l10n: l10n, onAdd: () => openTrip(null))
        else ...[
          _HeaderStrip(model: model, formatsTag: tag, unit: unit),
          for (final row in model.open) ...[
            SizedBox(height: space.s5),
            _OpenTripCard(
              row: row,
              formatsTag: tag,
              unit: unit,
              onEnd: () => openTrip(row.trip.id.toString()),
            ),
          ],
          if (model.earlier.isNotEmpty) ...[
            SizedBox(height: space.s6),
            _EarlierHeader(count: model.summary.tripCount, formatsTag: tag),
            SizedBox(height: space.s3),
            _EarlierRows(
              rows: model.earlier,
              formatsTag: tag,
              unit: unit,
              onOpen: openTrip,
            ),
          ],
        ],
      ],
    );
  }
}

/// The three tiles over the range.
class _HeaderStrip extends StatelessWidget {
  const _HeaderStrip({
    required this.model,
    required this.formatsTag,
    required this.unit,
  });

  final TripsListModel model;
  final String formatsTag;
  final DistanceUnit unit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final summary = model.summary;
    final percent = summary.businessPercent;

    // `IntrinsicHeight` so the three tiles are the same height whatever their
    // labels wrap to — a `stretch` Row alone asks for infinite height inside
    // the scaffold's scroll view, and three tiles of three different heights
    // is what the reference does not draw.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CalmTile(
              value: formatForDisplay(
                summary.loggedDistance.inUnit(unit),
                formatsTag,
                numerals: CalmNumerals.auto,
                decimalDigits: 0,
              ),
              // "km logged", not "km": §12 insists the figure says "across
              // logged trips", because this is NOT the car's distance.
              label: l10n.tripsLoggedLabel(distanceUnitLabel(l10n, unit)),
            ),
          ),
          SizedBox(width: space.s3),
          Expanded(
            child: CalmTile(
              // An em dash, not `0%`. Zero is a claim — it says none of the
              // driving was business — and §1 forbids the app making one it
              // cannot support.
              value: percent == null
                  ? '—'
                  : l10n.tripsBusinessValue(
                      formatForDisplay(
                        percent,
                        formatsTag,
                        numerals: CalmNumerals.auto,
                        decimalDigits: 0,
                        grouped: false,
                      ),
                    ),
              label: l10n.tripsBusinessLabel,
              // The one accent in the row. It is the figure that goes on a tax
              // form, and the point of a scarce accent is that it is scarce.
              brand: true,
            ),
          ),
          SizedBox(width: space.s3),
          Expanded(
            child: CalmTile(
              value: tripCostLabel(summary.cost, formatsTag) ?? '—',
              label: l10n.tripsCostsLabel,
            ),
          ),
        ],
      ),
    );
  }
}

/// The open trip, pinned above the list.
class _OpenTripCard extends StatelessWidget {
  const _OpenTripCard({
    required this.row,
    required this.formatsTag,
    required this.unit,
    required this.onEnd,
  });

  final TripsListRow row;
  final String formatsTag;
  final DistanceUnit unit;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final trip = row.trip;
    final date = formatShortDayMonth(trip.startedOn, formatsTag);
    final start = trip.startOdometer;

    return CalmCard(
      variant: CalmCardVariant.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A `Wrap` and not a `Row`: at 200% scale the badge and a German
          // title do not share a line, and shrinking either is not on offer.
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: space.s3,
            runSpacing: space.s2,
            children: [
              CalmBadge(label: l10n.tripsOpenBadge),
              Text(
                trip.title ??
                    tripDateRange(trip.startedOn, trip.endedOn, formatsTag),
                style: type.headline,
              ),
            ],
          ),
          SizedBox(height: space.s3),
          Text(
            start == null
                ? l10n.tripsStartedOn(date)
                : l10n.tripsStartedFrom(
                    date,
                    tripDistanceLabel(l10n, formatsTag, start, unit),
                  ),
            style: type.body.copyWith(color: colors.ink3),
          ),
          SizedBox(height: space.s4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: space.s4,
            runSpacing: space.s2,
            children: [
              CalmButton(
                label: l10n.tripsFinishAction,
                variant: CalmButtonVariant.secondary,
                onPressed: onEnd,
              ),
              Text(
                l10n.tripsNoEndReading,
                style: type.body.copyWith(color: colors.ink3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `Earlier` on the start edge, the trip count on the end edge.
class _EarlierHeader extends StatelessWidget {
  const _EarlierHeader({required this.count, required this.formatsTag});

  final int count;
  final String formatsTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final type = CalmType.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(l10n.tripsEarlier, style: type.label),
        ),
        Text(
          l10n.tripsCount(
            count,
            formatForDisplay(
              count,
              formatsTag,
              numerals: CalmNumerals.auto,
              decimalDigits: 0,
            ),
          ),
          style: type.label.copyWith(color: colors.ink3),
        ),
      ],
    );
  }
}

/// The rows, with a separator wherever the year changes.
class _EarlierRows extends StatelessWidget {
  const _EarlierRows({
    required this.rows,
    required this.formatsTag,
    required this.unit,
    required this.onOpen,
  });

  final List<TripsListRow> rows;
  final String formatsTag;
  final DistanceUnit unit;
  final void Function(String tripId) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // The rows are newest-first, so a year separator goes ABOVE the first row
    // of each year after the first. §12 calls it "a separator every January";
    // keying on the change rather than on the month is the same rule and it
    // still fires for somebody who logged nothing in January.
    final widgets = <Widget>[];
    String? previousYear;
    for (final row in rows) {
      final year = row.trip.startedOn.split('-').first;
      if (previousYear != null && year != previousYear) {
        widgets.add(_YearSeparator(year: year, formatsTag: formatsTag));
      }
      previousYear = year;

      final distance = row.distance;
      // Once. It was computed twice per row with identical arguments, and
      // each call builds one or two `intl` `DateFormat`s — a pattern parse
      // and a symbol lookup apiece.
      final dates = tripDateRange(
        row.trip.startedOn,
        row.trip.endedOn,
        formatsTag,
      );
      final meta = [
        dates,
        if (distance != null)
          tripDistanceLabel(l10n, formatsTag, distance, unit),
        tripPurposeLabel(l10n, row.trip.purpose),
      ].join(kTripsSeparator);

      widgets.add(
        CalmListRow(
          title: row.trip.title ?? dates,
          subtitle: meta,
          value: tripCostLabel(row.cost, formatsTag),
          showChevron: true,
          onTap: () => onOpen(row.trip.id.toString()),
        ),
      );
    }

    return CalmRowGroup(rows: widgets);
  }
}

/// A year, drawn between two rows.
class _YearSeparator extends StatelessWidget {
  const _YearSeparator({required this.year, required this.formatsTag});

  final String year;
  final String formatsTag;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: space.s4,
        vertical: space.s3,
      ),
      child: Text(
        // A YEAR, not a number: no grouping separator, and shaped to the
        // locale's digits like every other figure on the screen.
        formatYear(year, formatsTag),
        style: type.label.copyWith(color: colors.ink3),
      ),
    );
  }
}

/// §12's empty state.
///
/// `CalmEmptyState` and not a hand-rolled Column: the component supplies the
/// `Semantics(header: true)`, the centred body width and the neutral art, and
/// three screens rolling their own is three quiet divergences from the design
/// system that no gate catches.
class _TripsEmpty extends StatelessWidget {
  const _TripsEmpty({required this.l10n, required this.onAdd});

  final AppLocalizations l10n;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => CalmEmptyState(
    icon: Icons.route,
    title: l10n.tripsEmptyTitle,
    body: l10n.tripsEmptyBody,
    action: CalmButton(label: l10n.tripsAddAction, onPressed: onAdd),
  );
}
