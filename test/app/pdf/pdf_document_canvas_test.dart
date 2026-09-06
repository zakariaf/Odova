// The platform side of §12's PDF: the port's one real implementation.
//
// `service_report_writer_test.dart` owns the LAYOUT decisions against a
// recording fake. This file owns the two things a fake cannot prove: that the
// bytes are a PDF a stranger's viewer will open, and that the font travelled
// with them.
//
// SPEC.md §12: "Arabic-script locales embed the same Vazirmatn subset the app
// ships — embedded, not referenced, because the file must render on a
// stranger's phone." A referenced font is a document that shows boxes to the
// buyer, who concludes the seller sent a broken file.
@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/pdf/pdf_document_canvas.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/report/pdf_canvas.dart';
import 'package:odova/core/report/service_report.dart';
import 'package:odova/core/report/service_report_pdf.dart';
import 'package:odova/core/report/service_report_writer.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';

/// Reads the bytes back as text, which is enough to see a PDF's structure:
/// the header, the page objects and the font descriptors are all ASCII.
String _ascii(Uint8List bytes) =>
    String.fromCharCodes(bytes.where((b) => b >= 32 && b < 127));

Future<Uint8List> _render(void Function(PdfCanvas) draw) async {
  final canvas = PdfDocumentCanvas(fontBytes: await loadReportFont());
  draw(canvas);
  return canvas.save();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bytes are a PDF a viewer will open', () async {
    final bytes = await _render((c) {
      c
        ..beginPage(const PdfPageSpec(paper: PaperSize.a4, rtl: false))
        ..drawText('Service history', slot: PdfSlot.title);
    });

    expect(bytes.length, greaterThan(500));
    expect(_ascii(bytes), startsWith('%PDF-'));
    expect(_ascii(bytes), contains('%%EOF'));
  });

  test('a document with no pages is still a valid file', () async {
    // A viewer shown zero pages reports a corrupt file, and the user blames
    // the app rather than the empty history.
    final bytes = await _render((_) {});

    expect(_ascii(bytes), startsWith('%PDF-'));
  });

  test('each beginPage adds a page', () async {
    final bytes = await _render((c) {
      for (var i = 0; i < 3; i++) {
        c
          ..beginPage(const PdfPageSpec(paper: PaperSize.a4, rtl: false))
          ..drawText('page', slot: PdfSlot.recordDate);
      }
    });

    expect('/Type /Page\n'.allMatches(_ascii(bytes)).length, 0);
    expect(_ascii(bytes), contains('/Count 3'));
  });

  test('A4 and US Letter produce different page boxes', () async {
    // §12 gives US, CA, MX and PH Letter and everywhere else A4. If both came
    // out the same size the paper rule would be a setting with no effect.
    Future<String> box(PaperSize paper) async => _ascii(
      await _render(
        (c) => c
          ..beginPage(PdfPageSpec(paper: paper, rtl: false))
          ..drawText('x', slot: PdfSlot.title),
      ),
    );

    expect(await box(PaperSize.a4), isNot(await box(PaperSize.usLetter)));
  });

  test('the font is EMBEDDED, not referenced', () async {
    // The assertion §12 actually cares about. A referenced font names the
    // family and stops; an embedded one carries a FontFile stream, and only
    // the second renders on a phone that has never heard of Vazirmatn.
    final bytes = await _render((c) {
      c
        ..embedFont('Vazirmatn')
        ..beginPage(const PdfPageSpec(paper: PaperSize.a4, rtl: true))
        ..drawText('گزارش سرویس', slot: PdfSlot.title);
    });

    final text = _ascii(bytes);
    expect(text, contains('/FontFile2'));
    expect(text, contains('/FontDescriptor'));
  });

  test('an RTL page carries its own direction, not the default', () async {
    final ltr = await _render(
      (c) => c
        ..beginPage(const PdfPageSpec(paper: PaperSize.a4, rtl: false))
        ..drawText('Service history', slot: PdfSlot.title),
    );
    final rtl = await _render(
      (c) => c
        ..beginPage(const PdfPageSpec(paper: PaperSize.a4, rtl: true))
        ..drawText('Service history', slot: PdfSlot.title),
    );

    expect(ltr, isNot(rtl), reason: 'the mirrored page is a different page');
  });

  test('drawing before beginPage does not throw', () async {
    // A writer bug should not become a crash on the screen §12 says is opened
    // "at the moment of highest stakes and lowest patience". The text is
    // dropped and the file still saves.
    final bytes = await _render(
      (c) => c.drawText('orphan', slot: PdfSlot.footer),
    );

    expect(_ascii(bytes), startsWith('%PDF-'));
  });

  test('the same input twice differs only in the document /ID', () async {
    // Not full determinism, and it is worth naming exactly what moves. It is
    // NOT a creation date — `pdf` writes no `/CreationDate` at all unless the
    // document is given a title or author, and this one is not. The single
    // varying field is `/ID`, the PDF file identifier, which the library
    // derives per save.
    //
    // Everything else — the page tree, the content stream, the embedded font
    // programme, the widths array — is byte-identical across two saves of the
    // same input. So the app's own output is deterministic and the library
    // stamps one opaque identifier on top, which is the honest version of the
    // claim. The consequence worth recording is that a `matchesGoldenFile`
    // over these bytes would flake on that field alone, which is why there is
    // not one.
    void draw(PdfCanvas c) => c
      ..beginPage(const PdfPageSpec(paper: PaperSize.a4, rtl: false))
      ..drawText('Service history', slot: PdfSlot.title)
      ..drawText('14 June 2026', slot: PdfSlot.recordDate);

    String masked(Uint8List bytes) => _ascii(
      bytes,
    ).replaceAll(RegExp(r'/ID\[<[0-9a-f]+><[0-9a-f]+>\]'), '/ID[]');

    final a = await _render(draw);
    final b = await _render(draw);

    expect(a, isNot(b), reason: 'the identifier really does move');
    expect(masked(a), masked(b));
  });

  test(
    "the writer and the real canvas produce §12's document end to end",
    () async {
      // The two halves have only ever been tested apart: the writer against a
      // recording fake, the canvas against hand-made calls. This is the join —
      // a real document, through the real layout, onto the real backend — and
      // it is where a mismatch between them would show up as a file with no
      // pages or no text.
      final doc = buildServiceReport(
        vehicle: Vehicle(
          id: VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!,
          name: 'VW Golf VII',
          vehicleType: VehicleType.car,
          fuelKindDefault: FuelKind.diesel,
          status: VehicleStatus.active,
          createdAtUtcMs: 1,
          updatedAtUtcMs: 1,
        ),
        records: [
          for (var i = 0; i < 34; i++)
            ServiceRecord(
              id: ServiceRecordId.tryParse(
                'srv_01JQ8ZK3M7F0R6XN2E9TB4HC${_two(i)}',
              )!,
              vehicleId: VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!,
              occurredOn: '2026-${(i % 12 + 1).toString().padLeft(2, '0')}-14',
              odometer: Distance.fromKm(180000 - i * 400),
              odometerUnit: DistanceUnit.km,
              vendor: 'Bosch Car Service',
              lines: const [],
              createdAtUtcMs: 1 + i,
              updatedAtUtcMs: 1 + i,
            ),
        ],
        items: const [],
        series: ReadingSeries.from(const [], const []),
        options: const ServiceReportOptions(),
        today: CivilDate.tryParse('2026-09-02')!,
      );

      final canvas = PdfDocumentCanvas(fontBytes: await loadReportFont());
      writeServiceReportPdf(
        doc,
        canvas: canvas,
        paper: PaperSize.a4,
        rtl: false,
        scriptFamily: 'Vazirmatn',
        strings: const ServiceReportPdfStrings(
          title: 'Service history',
          pageOf: 'Page {n} of {total}',
          columnDate: 'Date',
          columnOdometer: 'Odometer',
          columnWork: 'What was done',
          columnCost: 'Cost',
          footer: 'Generated by Odova on {date} ({iso}).',
          estimatedFootnote: '~ odometer estimated at the time.',
        ),
        formatDate: (d) => d,
        formatDistance: (d, {required estimated}) => '${d.metres ~/ 1000} km',
        formatMoney: (m) => '${m.amountMinor}',
      );

      final bytes = await canvas.save();
      final text = _ascii(bytes);

      expect(text, startsWith('%PDF-'));
      // §12: "34 services is 2–3 pages."
      expect(text, contains('/Count 3'));
      expect(text, contains('/FontFile2'), reason: 'embedded, not referenced');
      expect(bytes.length, greaterThan(2000));
    },
  );
}

/// Two ULID characters from an index, so 34 records are 34 distinct ids.
String _two(int i) {
  const abc = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  return '${abc[i ~/ 32 % 32]}${abc[i % 32]}';
}
