// The platform side of SPEC.md §12's PDF — the one real `PdfCanvas`.
//
// Everything that DECIDES anything lives in `lib/core/report/`: which rows go
// on which page, that the table header repeats, which edge the date column
// occupies in Persian. This file only draws, and that division is the reason
// the layout is assertable in milliseconds against a recording fake while this
// is checked once for the two things a fake cannot prove — that the bytes are
// a PDF a stranger's viewer opens, and that the font travelled with them.
//
// The `pdf` package was audited before it was added. Its whole transitive tree
// is `archive`, `image`, `xml`, `barcode`, `qr`, `bidi` and `path` — local
// processing — and its only `dart:io` use is `zlib.encode` and
// `Platform.environment`. There is no `HttpClient`, `Socket` or `WebSocket`
// anywhere in its source. `share_plus` was considered for the hand-off and
// refused: it drags in `url_launcher_web`/`_linux`/`_windows`, and §2's claim
// is that "zero network calls" is true BY CONSTRUCTION rather than by which
// platform happens to ship.
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:odova/core/report/pdf_canvas.dart';
import 'package:odova/core/report/service_report_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// The face §12 embeds, as bytes.
///
/// Vazirmatn covers Latin as well as the Arabic script, so one face serves all
/// six locales and the file carries one font rather than two.
Future<Uint8List> loadReportFont() async {
  final data = await rootBundle.load('assets/fonts/Vazirmatn[wght].ttf');
  return data.buffer.asUint8List();
}

/// Draws §12's document into a real PDF.
class PdfDocumentCanvas implements PdfCanvas {
  /// Creates a canvas that embeds [fontBytes].
  PdfDocumentCanvas({required Uint8List fontBytes})
    : _font = pw.Font.ttf(fontBytes.buffer.asByteData()),
      // No title or author, so `pdf` writes no `/CreationDate` and there is
      // no clock in the output. Two saves of the same input differ in exactly
      // one field — `/ID`, the file identifier the library derives per save —
      // and are byte-identical everywhere else, which
      // `pdf_document_canvas_test.dart` asserts with that field masked. The
      // consequence: a golden over these bytes would flake on `/ID` alone, so
      // there is not one.
      _document = pw.Document();

  final pw.Font _font;
  final pw.Document _document;

  final List<_Page> _pages = [];
  _Page? _current;

  @override
  void embedFont(String family) {
    // Nothing to do: the face is embedded by USE. `pdf` writes a FontFile2
    // stream for any font a page actually draws with, and this canvas draws
    // every run with `_font`. The port keeps the call because the DECISION —
    // "embed, do not reference" — belongs to the writer, and a port that
    // silently ignored it would let a future backend reference instead.
  }

  @override
  void beginPage(PdfPageSpec spec) {
    _current = _Page(spec);
    _pages.add(_current!);
  }

  @override
  void drawText(String text, {required PdfSlot slot}) {
    // A run before any page is DROPPED rather than thrown. A writer bug should
    // not become a crash on a screen §12 says is opened "at the moment of
    // highest stakes and lowest patience"; the file still saves and the
    // omission is visible.
    _current?.runs.add((text, slot));
  }

  /// The finished bytes.
  Future<Uint8List> save() async {
    for (final page in _pages) {
      _document.addPage(
        pw.Page(
          pageFormat: _formatOf(page.spec.paper),
          // The page's own direction, so §12's "the document mirrors
          // completely" is one property rather than a flag on every run.
          textDirection: page.spec.rtl
              ? pw.TextDirection.rtl
              : pw.TextDirection.ltr,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final (text, slot) in page.runs) _run(text, slot),
            ],
          ),
        ),
      );
    }
    return Uint8List.fromList(await _document.save());
  }

  pw.Widget _run(String text, PdfSlot slot) {
    // The VIN is the one run that does not take the page's direction. §12:
    // "VIN is forced LTR with start-of-line alignment even on an RTL page" —
    // it is a serial number, and mirrored it is a different serial number.
    if (slot == PdfSlot.vin) {
      return pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Text(text, style: _styleOf(slot)),
      );
    }
    return pw.Text(text, style: _styleOf(slot));
  }

  pw.TextStyle _styleOf(PdfSlot slot) => pw.TextStyle(
    font: _font,
    fontSize: switch (slot) {
      PdfSlot.title => 20,
      PdfSlot.header => 15,
      PdfSlot.yearHeading || PdfSlot.recordDate => 12,
      PdfSlot.footnote || PdfSlot.pageNumber || PdfSlot.footer => 8,
      _ => 10,
    },
  );

  static PdfPageFormat _formatOf(PaperSize paper) => switch (paper) {
    PaperSize.a4 => PdfPageFormat.a4,
    PaperSize.usLetter => PdfPageFormat.letter,
  };
}

class _Page {
  _Page(this.spec);

  final PdfPageSpec spec;
  final List<(String, PdfSlot)> runs = [];
}
