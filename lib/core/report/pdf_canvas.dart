// The seam between §12's layout decisions and whatever draws them.
//
// A PDF library is a dependency that has to be audited for a network path
// (SPEC.md §2 refuses any package that transitively opens a socket), and it is
// not the thing that should be deciding which rows go on which page, where the
// repeating header sits, or which edge the date column occupies in Persian.
// Those are §12's decisions. Behind this interface they are assertable in
// milliseconds against a recording fake, and swapping the library later cannot
// silently move them.
//
// Pure Dart: no Flutter, no dart:io, no library import. The implementation
// lives above `lib/core/` and is injected.
import 'package:meta/meta.dart';
import 'package:odova/core/report/service_report_pdf.dart';

/// Where on the page a run of text belongs.
///
/// LOGICAL slots, never `left`/`right`. §5 forbids physical edges in layout
/// and this is layout: a writer that knew about left and right would have to
/// be written twice, and the second version is the one nobody tests.
enum PdfSlot {
  /// The document title.
  title,

  /// The vehicle's name and identity block.
  header,

  /// The plate, which prints verbatim.
  plate,

  /// The VIN, which is forced LTR even on an RTL page.
  vin,

  /// A column heading in the repeating table header.
  columnHeader,

  /// A year heading with its subtotal.
  yearHeading,

  /// A record's date.
  recordDate,

  /// A record's odometer.
  recordOdometer,

  /// What was done — free text, first-strong direction from its own content.
  recordWork,

  /// A record's cost.
  recordCost,

  /// A footnote.
  footnote,

  /// `Page 2 of 4`.
  pageNumber,

  /// §12's unremovable footer.
  footer,
}

/// One page's fixed properties.
@immutable
class PdfPageSpec {
  /// Creates the spec.
  const PdfPageSpec({required this.paper, required this.rtl});

  /// A4 or US Letter — the same on every page of one document.
  final PaperSize paper;

  /// Whether the page's direction is right-to-left.
  ///
  /// A property of the PAGE and not of each run: §12 mirrors the document
  /// completely, and a per-run flag is how half a table ends up mirrored.
  final bool rtl;
}

/// What a PDF backend has to be able to do.
///
/// Three operations, which is the whole surface. Anything richer would be the
/// layout leaking back out of `service_report_writer.dart` and into whatever
/// draws it.
abstract interface class PdfCanvas {
  /// Starts a new page.
  void beginPage(PdfPageSpec spec);

  /// Draws [text] in [slot] on the current page.
  void drawText(String text, {required PdfSlot slot});

  /// Embeds [family]'s glyphs in the file itself.
  ///
  /// §12: "embedded, not referenced, because the file must render on a
  /// stranger's phone." A referenced font is a document that shows boxes to
  /// the buyer, who concludes the seller sent a broken file.
  void embedFont(String family);
}
