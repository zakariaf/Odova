// There is ONE service-report renderer, and both callers use it.
//
// SPEC.md §6 §8.2 defers the document's contents to §12 → `report.service`,
// and the epic states the rule directly: "No screen may reimplement a document
// another screen owns." Two renderers would drift on the first change to
// either, and the one that drifted would be the one nobody re-read — the
// export somebody hands to a buyer.
@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

/// Every Dart file under `lib/`, generated output excluded.
Iterable<File> _sources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart') && !f.path.contains('/gen/'));

void main() {
  test('only one file draws pages', () {
    // `beginPage` is the verb that starts a document. A second file calling it
    // is a second renderer, whatever it is named.
    final drawers = [
      for (final file in _sources())
        if (file.readAsStringSync().contains('canvas.beginPage')) file.path,
    ];

    expect(drawers, ['lib/core/report/service_report_writer.dart']);
  });

  test('the renderer is in core, reachable by every feature', () {
    // In `lib/core/report/` and not in `lib/features/report/`, which is what
    // makes it callable from the backup feature at all: `structure_test`
    // refuses one feature importing another, so a renderer that lived in the
    // report feature would force the export screen to build a second one.
    expect(
      File('lib/core/report/service_report_writer.dart').existsSync(),
      isTrue,
    );
    expect(
      Directory('lib/features/report')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.dart') &&
                f.readAsStringSync().contains('void writeServiceReportPdf'),
          ),
      isEmpty,
    );
  });
}
