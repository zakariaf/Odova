// SPEC.md §6 §8's four exports and their pickers.
@TestOn('vm')
library;

import 'package:odova/features/backup/domain/export_target.dart';
import 'package:test/test.dart';

void main() {
  test('the Export screen offers exactly four outputs', () {
    // §6 §8 lists five and one of them — the `.ics` snapshot — lives on
    // `settings.notifications`. An export screen that offered a calendar file
    // would be a second place to look for it.
    expect(ExportKind.values, hasLength(4));
    expect(
      ExportKind.values.map((k) => k.name),
      ['backup', 'fillUpsCsv', 'costsCsv', 'serviceHistoryPdf'],
    );
    expect(
      ExportKind.values.map((k) => k.name).join(),
      isNot(contains('ics')),
    );
  });

  test('the backup never asks which vehicle', () {
    // It is the whole store, and a per-vehicle backup would be a file that
    // cannot restore the phone it came from.
    expect(ExportKind.backup.needsVehicle, isFalse);
    expect(
      needsVehiclePicker(ExportKind.backup, vehicleCount: 4),
      isFalse,
    );
  });

  test('only the costs CSV offers All vehicles', () {
    // A pivot over a household is what a household wants. A fill-ups CSV
    // across two vehicles would put a van's litres and a bike's litres in one
    // column with nothing but a name to tell them apart, and the PDF is a
    // document about ONE car that a buyer reads.
    expect(ExportKind.costsCsv.offersAllVehicles, isTrue);
    expect(ExportKind.fillUpsCsv.offersAllVehicles, isFalse);
    expect(ExportKind.serviceHistoryPdf.offersAllVehicles, isFalse);
    expect(ExportKind.backup.offersAllVehicles, isFalse);
  });

  test('one vehicle goes straight through', () {
    // A sheet that asks a question with one answer is a tap the user makes to
    // tell the app something it already knows.
    for (final kind in ExportKind.values) {
      expect(
        needsVehiclePicker(kind, vehicleCount: 1),
        isFalse,
        reason: kind.name,
      );
    }
  });

  test('two vehicles open the picker for the three that need one', () {
    expect(needsVehiclePicker(ExportKind.fillUpsCsv, vehicleCount: 2), isTrue);
    expect(needsVehiclePicker(ExportKind.costsCsv, vehicleCount: 2), isTrue);
    expect(
      needsVehiclePicker(ExportKind.serviceHistoryPdf, vehicleCount: 2),
      isTrue,
    );
  });

  test('an empty garage opens no picker', () {
    // There is nothing to pick, and the Export screen hides the CSV and PDF
    // rows on an empty store anyway — but a picker that opened on nothing
    // would be a modal the user has to dismiss to get back.
    for (final kind in ExportKind.values) {
      expect(
        needsVehiclePicker(kind, vehicleCount: 0),
        isFalse,
        reason: kind.name,
      );
    }
  });
}
