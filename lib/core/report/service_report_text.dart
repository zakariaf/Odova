// SPEC.md §12: "Copy as text — the same content as plain text on the
// clipboard, for pasting into a classifieds listing, which is how cars are
// actually sold on Divar, Willhaben, Leboncoin and Marketplace."
//
// "The same content" is the whole specification and the whole risk. A text
// renderer that drifts from the PDF makes two documents out of one model, and
// the one the seller pastes into a public advert is the one nobody proof-read.
// So this renders from `ServiceReportDocument` and from nothing else — the
// same object the preview and the PDF read. It can omit LAYOUT; it may not
// decide CONTENT.
//
// The clipboard is also the leakiest of the three renderers: the PDF goes to a
// person, the preview goes nowhere, and this goes into a public listing. A
// toggle honoured by the other two and forgotten here is an identity leak in
// the one place it is irreversible — which is why the plate, the VIN and the
// notes are read off the DOCUMENT rather than off the vehicle. The toggle was
// applied when the document was built, and there is nothing here that could
// apply it differently.
import 'package:meta/meta.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/report/service_report.dart';
import 'package:odova/core/units/distance.dart';

/// The localised strings the text renderer needs.
///
/// Passed in rather than looked up: this file is Flutter-free, and the
/// sentences belong to the l10n layer. A record of six rather than an
/// `AppLocalizations` so the renderer can be tested without a widget binding.
@immutable
class ServiceReportTextStrings {
  /// Creates the strings.
  const ServiceReportTextStrings({
    required this.title,
    required this.owned,
    required this.servicesLabel,
    required this.noRecordHeading,
    required this.footer,
    required this.estimatedFootnote,
  });

  /// "Service history".
  final String title;

  /// "Owned".
  final String owned;

  /// "services", for the summary line.
  final String servicesLabel;

  /// "No record in this app".
  final String noRecordHeading;

  /// §12's unremovable footer, with `{date}` for the generation date.
  final String footer;

  /// "~ odometer estimated at the time, not read from the car."
  final String estimatedFootnote;
}

/// Renders [doc] as the plain text §12 puts on the clipboard.
///
/// The formatters are injected for the reason every number in this app is
/// formatted at the edge: a Persian seller's document carries Persian digits
/// and a Jalali date, and this file has no way to know either.
String renderServiceReportText(
  ServiceReportDocument doc, {
  required ServiceReportTextStrings strings,
  required String Function(String isoDate) formatDate,
  required String Function(Distance, {required bool estimated}) formatDistance,
  required String Function(Money) formatMoney,

  /// A whole number, shaped in the locale's numerals.
  ///
  /// `grouped: false` for a YEAR — a year is a label, not a quantity, and
  /// "2,026" is a formatting bug that reads as a number of things.
  required String Function(int, {required bool grouped}) formatNumber,
}) {
  final out = StringBuffer()
    ..writeln(doc.header.name)
    ..writeln(strings.title);

  final from = doc.header.ownedFrom;
  if (from != null) {
    final until = doc.header.ownedUntil;
    out.writeln(
      '${strings.owned} ${formatDate(from)}'
      '${until == null ? '' : ' – ${formatDate(until)}'}',
    );
  }

  final latest = doc.header.latestOdometer;
  if (latest != null) {
    final on = doc.header.latestOdometerReadOn;
    out.writeln(
      // Never estimated: §12 forbids a projection in the header, and
      // `ServiceReportHeader` does not model one.
      '${formatDistance(latest, estimated: false)}'
      '${on == null ? '' : ' (${formatDate(on)})'}',
    );
  }

  // Read off the DOCUMENT, never off a vehicle. The toggle was applied when it
  // was built; nothing here can apply it differently.
  final plate = doc.header.plate;
  if (plate != null) out.writeln(plate);
  final vin = doc.header.vin;
  if (vin != null) out.writeln(vin);

  final summary = doc.summary;
  if (summary != null) {
    out.writeln(
      // Through the formatter. A bare `int` renders Latin digits, which is
      // wrong in four of the six shipped locales.
      '${formatNumber(summary.serviceCount, grouped: true)} '
      '${strings.servicesLabel}'
      // Grouped, never summed. §12 prints "6,842 € · £310" and this is that
      // line: one formatted amount per currency, joined.
      '${summary.totals.isEmpty ? '' : ' · '
                '${summary.totals.values.map(formatMoney).join(' · ')}'}',
    );
  }

  for (final year in doc.years) {
    out
      ..writeln()
      ..writeln(
        '${formatNumber(year.year, grouped: false)}'
        // Absent when Costs is off, because the map is empty then — not
        // zeroed, which would say the year's work was free.
        '${year.subtotals.isEmpty ? '' : ' — '
                  '${year.subtotals.values.map(formatMoney).join(' · ')}'}',
      );

    for (final record in year.records) {
      final odometer = record.odometer;
      out.writeln(
        [
          formatDate(record.occurredOn),
          if (odometer != null)
            // `estimated` goes INTO the formatter; the `~` is never
            // concatenated here. `check_status_encoding.sh` refuses a tilde
            // written in Dart, and it is right to: the app's real formatter is
            // `formatDistanceFigure`, which places the mark inside a bidi
            // isolate — and a `'~' + figure` on an RTL page puts the tilde on
            // the wrong side of the number.
            formatDistance(odometer, estimated: record.odometerEstimated),
        ].join('  '),
      );

      final labels = record.lines.map((l) => l.label).join(', ');
      if (labels.isNotEmpty) out.writeln(labels);
      final vendor = record.vendor;
      if (vendor != null) out.writeln(vendor);

      // Per line and in its own currency. §12: "Line costs print in their own
      // currency." Suppressed entirely when Costs is off — a per-line amount
      // left behind by a "hide the totals" implementation is a price list the
      // seller believed they had turned off.
      if (doc.summary != null) {
        for (final line in record.lines) {
          out.writeln('  ${line.label}: ${formatMoney(line.amount)}');
        }
      }
    }
  }

  if (doc.noRecordItemIds.isNotEmpty) {
    out
      ..writeln()
      ..writeln(strings.noRecordHeading);
  }

  // One per distinct cause. The note explains the mark; repeating it under a
  // document is noise.
  if (doc.footnotes.isNotEmpty) {
    out.writeln();
    for (final note in doc.footnotes) {
      out.writeln(switch (note) {
        ServiceReportFootnote.estimatedOdometer => strings.estimatedFootnote,
      });
    }
  }

  out
    ..writeln()
    ..writeln(
      // BOTH placeholders, and `{date}` through the formatter. This printed a
      // literal "{iso}" in every locale and gave `{date}` the raw ISO string,
      // so a Persian seller's clipboard carried no Jalali date — the same
      // defect the on-screen footer had, in the renderer that goes into a
      // public classifieds advert.
      strings.footer
          .replaceAll('{date}', formatDate(doc.generatedOn.toString()))
          .replaceAll('{iso}', doc.generatedOn.toString()),
    );

  // No trim on the way out. The footer is unremovable and is always the last
  // line written, so the buffer already ends in exactly one newline — a
  // `trimRight` here would be code no test could tell from its absence, which
  // is how a guard becomes a comment that runs.
  return out.toString();
}
