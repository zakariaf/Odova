// SPEC.md §12's `report.service`.
//
// "The preview IS the document, rendered as native list rows, and the toggles
// change it live. A PDF viewer in the app would be a second renderer to keep in
// sync with the first."
//
// So there is no preview widget separate from the document model: every row
// below reads `ServiceReportDocument`, the same object the PDF writer and the
// clipboard renderer read. What is on screen is what will be in the file,
// because it is built from the same value.
//
// The reference (`design/reference/calm/report.service-*.png`) differs from
// §12's ASCII sketch in one respect and the reference wins, per the epic's
// inherited rule 4: the four toggles are CHIPS, not switches, and the header is
// the one inverse card in the app. The sketch's switch column is not what was
// designed.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/app/today.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/report/service_report.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/report/application/report_notifier.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/money_format.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_card.dart';
import 'package:odova/ui/calm/calm_chip.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

/// §12's service report.
class ReportServiceScreen extends ConsumerWidget {
  /// Creates the screen.
  const ReportServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(todayProvider);
    final vehicleId = ref.watch(activeVehicleIdProvider);

    // Behind `ensureLoaded`, which is idempotent and defers to a microtask: a
    // widget's `build` may not modify a provider, and this is the seam EPIC-10
    // settled on for every screen needing a read before its first frame.
    if (vehicleId != null && today != null) {
      ref
          .read(reportProvider.notifier)
          .ensureLoaded(vehicleId.body, today: today);
    }

    final state = ref.watch(reportProvider);
    final doc = state.document;

    return CalmScaffold(
      appBar: CalmAppBar(
        title: l10n.reportTitle,
        actions: [
          // §12's overflow: "Copy as text. Paper size. Nothing else."
          CalmAppBarAction(
            label: l10n.reportCopyAsText,
            icon: Icons.more_horiz,
            onTap: () {},
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalmButton(
            label: l10n.reportSharePdf,
            icon: Icons.ios_share,
            block: true,
            disabledBecause: state.canShare
                ? null
                : l10n.reportShareDisabledReason,
            onPressed: state.canShare ? () {} : null,
          ),
          // §12: "reason under it, not in a toast." The user is already
          // stressed, and a toast is a reason that leaves before it is read.
          // `CalmButton` asserts a disabled button HAS a reason; this is the
          // widget that puts it on screen, and the two are separate so the
          // assertion cannot be satisfied by a string nobody renders.
          if (!state.canShare)
            CalmButtonExplain(reason: l10n.reportShareDisabledReason),
        ],
      ),
      children: [
        if (doc != null) ...[
          _HeaderCard(doc: doc),
          _IncludeChips(options: state.options, today: today!),
          if (state.canShare) _Preview(doc: doc) else _EmptyPreview(l10n: l10n),
          _Footer(doc: doc),
        ],
      ],
    );
  }
}

/// §12's header block, on the one inverse card in the app.
class _HeaderCard extends ConsumerWidget {
  const _HeaderCard({required this.doc});

  final ServiceReportDocument doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    // The vehicle's own unit, not the settings default: §12's document is
    // about one car, and a miles car's history reads in miles.
    final vehicleId = ref.watch(activeVehicleIdProvider);
    final unit = effectiveDistanceUnit(
      ref
          .watch(vehiclesProvider)
          .value
          ?.where((v) => v.id == vehicleId)
          .firstOrNull,
      ref.watch(settingsProvider).value,
    );
    final header = doc.header;

    return CalmCard(
      variant: CalmCardVariant.inverse,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `.report__mast` in `design/calm/odova.css`: a column with a
          // `space-1` gap and `space-4` of padding under it. Taken from the
          // design system rather than eyeballed off the PNG — the CSS is the
          // same source the reference was rendered from.
          Text(header.name, style: type.titleLg),
          SizedBox(height: space.s1),
          Text(
            [
              if (header.model != null) header.model!,
              if (header.year != null)
                // Ungrouped: a model year is a label, not a quantity, and
                // "2 016" is not a year anybody recognises.
                formatForDisplay(
                  header.year!,
                  tag,
                  numerals: CalmNumerals.auto,
                  decimalDigits: 0,
                  grouped: false,
                ),
              if (header.fuelKind != null)
                vehicleFuelLabel(l10n, header.fuelKind!),
            ].join(' · '),
            style: type.body.copyWith(color: colors.ink3),
          ),
          SizedBox(height: space.s5),
          // A hairline drawn from a token, not Material's `Divider`.
          // `check_calm_layering.sh` refuses raw Material in a feature and is
          // right to: `Divider` carries a Material theme's colour, indent and
          // thickness, none of which are Calm's.
          //
          // `width: double.infinity` is the load-bearing part. Inside a
          // `crossAxisAlignment: start` column a `SizedBox` with only a height
          // takes its intrinsic width, which is ZERO — the line was being
          // drawn and was one pixel wide. `--color-divider` is #E6D9C6 in the
          // light theme and the card is #2C241E, so it is a pale line on a
          // dark surface and correct as it stands; it was never a colour
          // problem.
          SizedBox(
            height: 1,
            child: ColoredBox(color: colors.divider),
          ),
          SizedBox(height: space.s4),
          if (header.ownedFrom != null)
            _HeaderRow(
              // Open-ended: "Owned since March 2018", never "… – 2 September
              // 2026". A document printed in September and read in November
              // must not claim the span ended in September.
              //
              // Month and year, not a day. The reference reads "March 2018",
              // and a purchase DAY is a precision the seller did not offer and
              // the buyer has no use for.
              label: l10n.reportOwnedSince(
                formatMonthYear(header.ownedFrom!, tag),
              ),
              value: _duration(l10n, tag, header),
            ),
          if (header.latestOdometer != null)
            _HeaderRow(
              label: _span(l10n, tag, unit, header),
              value: _distance(l10n, tag, unit, header.distanceUnderOwner),
            ),
          // Present only when §12's toggle put them in the DOCUMENT. Read off
          // `header`, never off the vehicle: the toggle was applied when the
          // document was built and nothing here can apply it differently.
          if (header.plate != null)
            // Verbatim, and never digit-shaped: §12 calls a plate "a picture
            // of a plate, not a number".
            _HeaderRow(label: header.plate!, value: ''),
          if (header.vin != null)
            // Forced LTR even on an RTL page — a VIN is a serial number, and
            // mirrored it is a different serial number.
            _HeaderRow(
              label: header.vin!,
              value: '',
              forceLtr: true,
            ),
          if (doc.summary != null)
            _HeaderRow(
              label: l10n.reportServiceCount(
                doc.summary!.serviceCount,
                formatForDisplay(
                  doc.summary!.serviceCount,
                  tag,
                  numerals: CalmNumerals.auto,
                  decimalDigits: 0,
                ),
              ),
              // Grouped, never summed. §12 prints "6,842 € · £310".
              value: doc.summary!.totals.values
                  .map((m) => _money(tag, m))
                  .join(' · '),
              big: true,
            ),
        ],
      ),
    );
  }

  /// §12's "8 yr 6 mo", from the purchase date to the end of the span.
  ///
  /// Whole months through `CivilDate`, never `DateTime.difference().inDays`
  /// divided by thirty: across a leap year that arithmetic drops a month, and
  /// the figure it produces is one a buyer would check against the logbook.
  static String _duration(
    AppLocalizations l10n,
    String tag,
    ServiceReportHeader header,
  ) {
    final from = CivilDate.tryParseOrNull(header.ownedFrom ?? '');
    final until =
        CivilDate.tryParseOrNull(header.ownedUntil ?? '') ?? header.today;
    if (from == null) return '';

    final months = from.monthsUntil(until);
    if (months < 0) return '';

    String n(int v) => formatForDisplay(
      v,
      tag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
    );
    return l10n.reportOwnershipSpan(n(months ~/ 12), n(months % 12));
  }

  static String _span(
    AppLocalizations l10n,
    String tag,
    DistanceUnit unit,
    ServiceReportHeader header,
  ) {
    final to = _distance(l10n, tag, unit, header.latestOdometer);
    final from = header.purchaseOdometer;
    // Only the second half carries the unit. "62,400 km – 187,412 km" says the
    // unit twice on one line, for no reader who did not already know it.
    return from == null
        ? to
        : l10n.reportOdometerSpan(
            formatForDisplay(
              from.inUnit(unit),
              tag,
              numerals: CalmNumerals.auto,
              decimalDigits: 0,
            ),
            to,
          );
  }
}

/// A distance with its unit, through the app's one distance formatter.
///
/// `formatDistanceFigure` isolates the figure and places the estimate mark;
/// `estimated: false` here is not a shortcut but §12's rule — the header
/// carries an ENTERED reading and never a projection, so there is no mark to
/// place.
String _distance(
  AppLocalizations l10n,
  String tag,
  DistanceUnit unit,
  Distance? d,
) =>
    d == null ? '' : formatDistanceFigure(l10n, tag, d, unit, estimated: false);

/// Through the app's ONE money formatter, never a symbol concatenated here.
///
/// `formatMoney` returns a single bidi isolate — `FSI … PDI` — and handles the
/// toman display §18 leaves open. Splitting the number from its symbol is what
/// puts `€` on the wrong side of a Persian sentence, and this is a document
/// that ships in three RTL locales.
String _money(String tag, Money m) =>
    formatMoney(m, tag, numerals: CalmNumerals.auto);

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.label,
    required this.value,
    this.forceLtr = false,
    this.big = false,
  });

  final String label;
  final String value;

  /// Pins the run left-to-right regardless of the page direction.
  ///
  /// Only the VIN uses it. §12: "VIN is forced LTR with start-of-line
  /// alignment even on an RTL page."
  final bool forceLtr;

  /// `.kv__v--big` in `design/calm/odova.css` — headline size instead of body.
  ///
  /// Exactly one row is big: the money. The design system makes the other two
  /// body-semibold, and rendering all three at headline size makes the card a
  /// third taller than the reference, which is what the parity band profile
  /// caught.
  final bool big;

  @override
  Widget build(BuildContext context) {
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    return Padding(
      // `.kv` in the CSS: a `space-3` gap between rows.
      padding: EdgeInsetsDirectional.only(bottom: space.s3),
      child: Row(
        // `.kv__row` aligns on the BASELINE, not the centre: the value is
        // headline-sized beside a body-sized key, and centring them puts the
        // two texts on two invisible lines.
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: forceLtr
                ? Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      label,
                      style: type.body.copyWith(color: colors.ink3),
                    ),
                  )
                : Text(label, style: type.body.copyWith(color: colors.ink3)),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              // `.kv__v`: body at `--fw-semi`, and `--fs-headline` only for
              // the one row marked big.
              style: big
                  ? type.headline
                  : type.body.copyWith(fontWeight: type.semi),
            ),
        ],
      ),
    );
  }
}

/// §12's four toggles, as the reference draws them: chips, not switches.
class _IncludeChips extends ConsumerWidget {
  const _IncludeChips({required this.options, required this.today});

  final ServiceReportOptions options;

  /// Today, from the clock provider — never `DateTime.now()`. §3 validates the
  /// clock and this screen must use the same one the due engine does.
  final CivilDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    void set(ServiceReportOptions next) =>
        ref.read(reportProvider.notifier).setOptions(next, today: today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.reportIncludeHeading, style: type.label),
        SizedBox(height: space.s3),
        CalmChipBar(
          wrap: true,
          chips: [
            CalmChip(
              label: l10n.reportToggleCosts,
              selected: options.costs,
              icon: options.costs ? Icons.check : null,
              onTap: () => set(
                ServiceReportOptions(
                  plateAndVin: options.plateAndVin,
                  costs: !options.costs,
                  fuelSummary: options.fuelSummary,
                  notes: options.notes,
                ),
              ),
            ),
            CalmChip(
              label: l10n.reportToggleFuel,
              selected: options.fuelSummary,
              icon: options.fuelSummary ? Icons.check : null,
              onTap: () => set(
                ServiceReportOptions(
                  plateAndVin: options.plateAndVin,
                  costs: options.costs,
                  fuelSummary: !options.fuelSummary,
                  notes: options.notes,
                ),
              ),
            ),
            CalmChip(
              label: l10n.reportTogglePlateVin,
              selected: options.plateAndVin,
              icon: options.plateAndVin ? Icons.check : null,
              onTap: () => set(
                ServiceReportOptions(
                  plateAndVin: !options.plateAndVin,
                  costs: options.costs,
                  fuelSummary: options.fuelSummary,
                  notes: options.notes,
                ),
              ),
            ),
            CalmChip(
              label: l10n.reportToggleNotes,
              selected: options.notes,
              icon: options.notes ? Icons.check : null,
              onTap: () => set(
                ServiceReportOptions(
                  plateAndVin: options.plateAndVin,
                  costs: options.costs,
                  fuelSummary: options.fuelSummary,
                  notes: !options.notes,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: space.s3),
        // Shown whether or not the toggle is on. A warning that appears only
        // after the switch is flipped is a warning shown after the decision it
        // was meant to inform.
        Text(
          l10n.reportNotesWarning,
          style: type.caption.copyWith(color: colors.ink3),
        ),
      ],
    );
  }
}

/// What fraction of the screen the preview window occupies.
///
/// It needs a BOUND, because a list without a viewport builds every one of its
/// children and §12 requires this one virtualised at four hundred services.
/// But a fixed pixel height is the wrong bound: the reference draws the
/// preview running off the bottom of the screen, clipped by the Share button,
/// so the card's height is "whatever is left" — and a constant tuned against
/// one device is a card that ends mid-screen on a taller one and overlaps the
/// button on a shorter.
const double kPreviewViewportFraction = 0.42;

/// The preview, which is the document.
class _Preview extends StatelessWidget {
  const _Preview({required this.doc});

  final ServiceReportDocument doc;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);

    // Flattened once, so the list is a single index space. §12 virtualises
    // this: a `Column` of four hundred rows builds every one of them off
    // screen and janks the screen §12 says is opened "at the moment of highest
    // stakes and lowest patience".
    final rows = <Widget>[
      for (final year in doc.years) ...[
        _YearHeading(year: year),
        for (final record in year.records)
          ReportRecordRow(
            record: record,
            showCosts: doc.summary != null,
          ),
      ],
      if (doc.noRecordItemIds.isNotEmpty)
        Padding(
          padding: EdgeInsetsDirectional.only(top: space.s5),
          child: Text(
            AppLocalizations.of(context).reportNoRecordHeading,
            style: CalmType.of(context).label,
          ),
        ),
    ];

    // BOUNDED, and scrolling on its own. §12 virtualises this preview, and a
    // `shrinkWrap: true` list under `NeverScrollableScrollPhysics` builds
    // every one of its children — four hundred rows constructed off screen on
    // the screen §12 says is opened "at the moment of highest stakes and
    // lowest patience". The reference shows the card clipped mid-row at the
    // viewport edge, which is exactly this.
    return CalmCard(
      variant: CalmCardVariant.flat,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * kPreviewViewportFraction,
        child: ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, i) => rows[i],
        ),
      ),
    );
  }
}

class _YearHeading extends ConsumerWidget {
  const _YearHeading({required this.year});

  final ServiceReportYear year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = CalmType.of(context);
    final space = CalmSpace.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: space.s4),
      child: Row(
        children: [
          Expanded(child: Text('${year.year}', style: type.label)),
          // Absent when Costs is off, because the map is empty then — not
          // zeroed, which would say the year's work was free.
          Text(
            year.subtotals.values.map((m) => _money(tag, m)).join(' · '),
            style: type.label,
          ),
        ],
      ),
    );
  }
}

/// One service, as the document prints it.
class ReportRecordRow extends ConsumerWidget {
  /// Creates the row.
  const ReportRecordRow({
    required this.record,
    required this.showCosts,
    super.key,
  });

  /// The record, as the document holds it.
  final ServiceRecord record;

  /// Whether §12's Costs toggle is on.
  final bool showCosts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;

    // The record total §12 prints, summed from its own lines and in their own
    // currency. Null when Costs is off, so nothing renders rather than a zero.
    final total = showCosts
        ? record.lines.fold<int>(0, (sum, l) => sum + l.amount.amountMinor)
        : null;
    final currency = record.lines.isEmpty
        ? null
        : record.lines.first.amount.currency;

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: space.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatLongDate(record.occurredOn, tag),
                  style: type.headline,
                ),
              ),
              if (total != null && currency != null)
                Text(
                  _money(tag, Money(total, currency)),
                  style: type.headline,
                ),
            ],
          ),
          SizedBox(height: space.s2),
          Text(
            record.lines.map((l) => l.label).join(', '),
            style: type.body,
          ),
          // Vendor, odometer and invoice reference, joined — §12 lists all
          // three on the record row, and the invoice number is the one a buyer
          // can take to the workshop and verify.
          if (_secondary(context, ref, record).isNotEmpty) ...[
            SizedBox(height: space.s1),
            Text(
              _secondary(context, ref, record),
              style: type.caption.copyWith(color: colors.ink3),
            ),
          ],
        ],
      ),
    );
  }
}

/// The vendor, odometer and invoice line under a record.
String _secondary(BuildContext context, WidgetRef ref, ServiceRecord record) {
  final tag = ref.read(resolvedLocaleTagsProvider).formats;
  final odometer = record.odometer;
  return [
    if (record.vendor != null) record.vendor!,
    if (odometer != null)
      // `estimated` goes into the formatter, never a `~` concatenated here.
      formatDistanceFigure(
        AppLocalizations.of(context),
        tag,
        odometer,
        record.odometerUnit,
        estimated: record.odometerEstimated,
      ),
    if (record.invoiceRef != null)
      AppLocalizations.of(context).reportInvoiceRef(record.invoiceRef!),
  ].join(' · ');
}

/// §12's no-records preview.
class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    return CalmCard(
      variant: CalmCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reportEmptyTitle, style: type.headline),
          SizedBox(height: space.s2),
          // Not an apology. §12: "one documented cambelt change is worth
          // printing."
          Text(
            l10n.reportEmptyBody,
            style: type.body.copyWith(color: colors.ink3),
          ),
        ],
      ),
    );
  }
}

/// §12's unremovable footer.
class _Footer extends StatelessWidget {
  const _Footer({required this.doc});

  final ServiceReportDocument doc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final note in doc.footnotes)
          Text(
            switch (note) {
              ServiceReportFootnote.estimatedOdometer =>
                l10n.reportEstimatedFootnote,
            },
            style: type.caption.copyWith(color: colors.ink3),
          ),
        Text(
          // Both dates. A Jalali date alone is unreadable to the buyer's
          // insurer; an ISO date alone to the seller who generated it.
          l10n.reportGeneratedFooter(
            doc.generatedOn.toString(),
            doc.generatedOn.toString(),
          ),
          style: type.caption.copyWith(color: colors.ink3),
        ),
      ],
    );
  }
}
