// §13's export flow: asked once, and only when there is more than one answer.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/features/backup/domain/export_target.dart';
import 'package:odova/features/backup/presentation/export_vehicle_picker_sheet.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

import '../../../support/pump_app.dart';

Vehicle _vehicle(String id, String name) => Vehicle(
  id: VehicleId.tryParse(id)!,
  name: name,
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);

final Vehicle _golf = _vehicle('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', 'Golf');
final Vehicle _van = _vehicle('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVE', 'The van');
final Vehicle _arabic = _vehicle('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVF', 'سيارة');

Future<AppLocalizations> _l10n() =>
    AppLocalizations.delegate.load(const Locale('en'));

Future<void> _pumpSheet(
  WidgetTester tester, {
  required ExportKind kind,
  required List<Vehicle> vehicles,
  required void Function(ExportTarget) onChoice,
}) => pumpApp(
  tester,
  ExportVehiclePickerSheet(
    kind: kind,
    vehicles: vehicles,
    onChoice: onChoice,
  ),
);

void main() {
  testWidgets('the costs CSV offers All vehicles', (tester) async {
    await _pumpSheet(
      tester,
      kind: ExportKind.costsCsv,
      vehicles: [_golf, _van],
      onChoice: (_) {},
    );
    final l10n = await _l10n();

    expect(find.text('Golf'), findsOneWidget);
    expect(find.text('The van'), findsOneWidget);
    expect(find.text(l10n.backupAllVehicles), findsOneWidget);
  });

  testWidgets('the fill-ups CSV and the PDF do not', (tester) async {
    // A fill-ups CSV across two vehicles would put a van's litres and a bike's
    // litres in one column with nothing but a name to tell them apart, and the
    // PDF is a document about ONE car that a buyer reads.
    for (final kind in [ExportKind.fillUpsCsv, ExportKind.serviceHistoryPdf]) {
      await _pumpSheet(
        tester,
        kind: kind,
        vehicles: [_golf, _van],
        onChoice: (_) {},
      );
      final l10n = await _l10n();

      expect(find.text(l10n.backupAllVehicles), findsNothing, reason: '$kind');
      expect(find.text('Golf'), findsOneWidget);
    }
  });

  testWidgets("the choice carries the vehicle's ONE-BASED position", (
    tester,
  ) async {
    // A name written only in Arabic script transliterates to nothing, and the
    // filename falls back to `vehicle-2` by list position — so the position
    // has to travel with the choice rather than being recomputed later by
    // whoever builds the filename.
    ExportTarget? chosen;
    await _pumpSheet(
      tester,
      kind: ExportKind.fillUpsCsv,
      vehicles: [_golf, _arabic],
      onChoice: (target) => chosen = target,
    );

    await tester.tap(find.text('سيارة'));
    await tester.pumpAndSettle();

    expect(chosen, isA<SingleVehicleTarget>());
    expect((chosen! as SingleVehicleTarget).positionalIndex, 2);
    expect((chosen! as SingleVehicleTarget).vehicleId, _arabic.id);
  });

  testWidgets('All vehicles answers with the all-vehicles target', (
    tester,
  ) async {
    ExportTarget? chosen;
    await _pumpSheet(
      tester,
      kind: ExportKind.costsCsv,
      vehicles: [_golf, _van],
      onChoice: (target) => chosen = target,
    );
    final l10n = await _l10n();

    await tester.tap(find.text(l10n.backupAllVehicles));
    await tester.pumpAndSettle();

    expect(chosen, isA<AllVehiclesTarget>());
  });

  testWidgets('it renders in Arabic without overflowing', (tester) async {
    await pumpApp(
      tester,
      ExportVehiclePickerSheet(
        kind: ExportKind.costsCsv,
        vehicles: [_golf, _arabic],
        onChoice: (_) {},
      ),
      locale: const Locale('ar'),
    );

    expect(find.byType(ExportVehiclePickerSheet), findsOneWidget);
  });
}
