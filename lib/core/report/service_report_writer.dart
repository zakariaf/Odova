// SPEC.md §12's document, laid out onto pages.
//
// Pure over `PdfCanvas`, so every decision here is assertable against a
// recording fake: which rows land on which page, that the table header repeats,
// that `Page 2 of 4` has both numbers, that the VIN does not mirror.
//
// The one rule that shapes the whole file: it emits LOGICAL slots and a page
// direction, never a physical edge. §12 mirrors the document completely in
// fa/ar/ckb — "table columns reversed, date at the right edge" — and a writer
// that knew about left and right would have to be written twice, with the
// second version the one nobody looks at.
import 'package:meta/meta.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/report/pdf_canvas.dart';
import 'package:odova/core/report/service_report.dart';
import 'package:odova/core/report/service_report_pdf.dart';
import 'package:odova/core/units/distance.dart';

/// The localised strings the writer needs.
///
/// Passed in, because this file is Flutter-free and the sentences are the l10n
/// layer's. `{n}`, `{total}`, `{date}` and `{iso}` are substituted here.
@immutable
class ServiceReportPdfStrings {
  /// Creates the strings.
  const ServiceReportPdfStrings({
    required this.title,
    required this.pageOf,
    required this.columnDate,
    required this.columnOdometer,
    required this.columnWork,
    required this.columnCost,
    required this.footer,
    required this.estimatedFootnote,
  });

  /// "Service history".
  final String title;

  /// "Page {n} of {total}".
  final String pageOf;

  /// The four column headings, which repeat on every page.
  final String columnDate;

  /// The odometer column.
  final String columnOdometer;

  /// The work column.
  final String columnWork;

  /// The cost column.
  final String columnCost;

  /// §12's unremovable footer, with `{date}` and `{iso}`.
  final String footer;

  /// The estimated-odometer note.
  final String estimatedFootnote;
}

/// Writes [doc] onto [canvas].
///
/// [scriptFamily] is embedded once for the whole document — §12's "embedded,
/// not referenced". Once, not once per page: a font embedded twelve times is a
/// twelve-megabyte file for a document nobody will read twice.
void writeServiceReportPdf(
  ServiceReportDocument doc, {
  required PdfCanvas canvas,
  required PaperSize paper,
  required bool rtl,
  required String scriptFamily,
  required ServiceReportPdfStrings strings,
  required String Function(String isoDate) formatDate,
  required String Function(Distance, {required bool estimated}) formatDistance,
  required String Function(Money) formatMoney,
}) {
  canvas.embedFont(scriptFamily);

  final rows = [
    for (final year in doc.years)
      for (final record in year.records) (year, record),
  ];

  final pageCount = pageCountFor(recordCount: rows.length);
  final spec = PdfPageSpec(paper: paper, rtl: rtl);

  var index = 0;
  var lastYear = -1;
  for (var page = 0; page < pageCount; page++) {
    canvas.beginPage(spec);

    if (page == 0) {
      canvas
        ..drawText(strings.title, slot: PdfSlot.title)
        ..drawText(doc.header.name, slot: PdfSlot.header);

      // Both read off the DOCUMENT. The toggle was applied when it was built,
      // and there is nothing here that could apply it differently.
      final plate = doc.header.plate;
      // Verbatim, and never digit-shaped: §12 calls a plate "a picture of a
      // plate, not a number", and `M-AB 1234` in Persian digits is a plate
      // that does not exist. It reaches the canvas exactly as it was typed.
      if (plate != null) canvas.drawText(plate, slot: PdfSlot.plate);

      final vin = doc.header.vin;
      // Forced LTR by its SLOT rather than by a marker character embedded in
      // the string. A VIN is a serial number, mirrored it is a different
      // serial number, and it is the field a buyer types into a history check.
      if (vin != null) canvas.drawText(vin, slot: PdfSlot.vin);

      // §12's private notes, only when toggled on. Read off the DOCUMENT, so
      // the toggle cannot be applied differently here than on the screen.
      final notes = doc.header.notes;
      if (notes != null) canvas.drawText(notes, slot: PdfSlot.header);
    }

    // §12's repeating table header, on EVERY page. A reader who turns to page
    // four otherwise sees four columns of numbers with nothing saying which is
    // the odometer and which is the cost.
    for (final heading in [
      strings.columnDate,
      strings.columnOdometer,
      strings.columnWork,
      strings.columnCost,
    ]) {
      canvas.drawText(heading, slot: PdfSlot.columnHeader);
    }

    final budget = page == 0 ? kFirstPageRowBudget : kPageRowBudget;
    final end = (index + budget).clamp(0, rows.length);
    for (; index < end; index++) {
      final (year, record) = rows[index];

      // The year heading repeats when a year spans a page break, for the same
      // reason the column header does.
      if (year.year != lastYear) {
        lastYear = year.year;
        canvas.drawText(
          '${year.year}'
          '${year.subtotals.isEmpty ? '' : ' — '
                    '${year.subtotals.values.map(formatMoney).join(' · ')}'}',
          slot: PdfSlot.yearHeading,
        );
      }

      canvas.drawText(formatDate(record.occurredOn), slot: PdfSlot.recordDate);
      final odometer = record.odometer;
      if (odometer != null) {
        // `estimated` goes INTO the formatter. A `~` concatenated here lands
        // on the wrong side of the number on an RTL page, and
        // `check_status_encoding.sh` refuses it for that reason.
        canvas.drawText(
          formatDistance(odometer, estimated: record.odometerEstimated),
          slot: PdfSlot.recordOdometer,
        );
      }
      final work = record.lines.map((l) => l.label).join(', ');
      if (work.isNotEmpty) canvas.drawText(work, slot: PdfSlot.recordWork);

      // Suppressed with the whole Costs toggle, per line and not only in
      // total: an amount left behind by a "hide the totals" implementation is
      // a price list the seller believed they had turned off.
      if (doc.summary != null) {
        for (final line in record.lines) {
          canvas.drawText(formatMoney(line.amount), slot: PdfSlot.recordCost);
        }
      }
    }

    canvas.drawText(
      strings.pageOf
          .replaceAll('{n}', '${page + 1}')
          .replaceAll('{total}', '$pageCount'),
      slot: PdfSlot.pageNumber,
    );

    if (page == pageCount - 1) {
      for (final note in doc.footnotes) {
        canvas.drawText(
          switch (note) {
            ServiceReportFootnote.estimatedOdometer =>
              strings.estimatedFootnote,
          },
          slot: PdfSlot.footnote,
        );
      }

      // §12: "… on ۱۱ شهریور ۱۴۰۵ (2026-09-02) …". Both dates, always. A
      // Jalali date alone is unreadable to the buyer's insurer; an ISO date
      // alone is unreadable to the seller who generated it.
      canvas.drawText(
        strings.footer
            .replaceAll('{date}', formatDate(doc.generatedOn.toString()))
            .replaceAll('{iso}', doc.generatedOn.toString()),
        slot: PdfSlot.footer,
      );
    }
  }
}
