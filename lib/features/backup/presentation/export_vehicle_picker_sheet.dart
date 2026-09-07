// "Which vehicle?" — §13's export flow, asked once and only when it has to be.
//
// One vehicle never sees this sheet. A modal that asks a question with one
// answer is a tap the user makes to tell the app something it already knows,
// and this app's whole promise is under a minute a month.
//
// "All vehicles" appears for the all-costs CSV and for nothing else. §6 §8.1
// calls that file the one somebody opens to build a pivot table, and a pivot
// over a household is what a household wants — where a fill-ups CSV across two
// vehicles would put a van's litres and a bike's litres in one column with
// nothing but a name to tell them apart.
import 'package:flutter/material.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/features/backup/domain/export_target.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_sheet.dart';

/// Asks which vehicle [kind] is about, or answers without asking.
///
/// Returns null when the user dismissed the sheet — an ordinary answer, not an
/// error, and the caller writes nothing.
Future<ExportTarget?> pickExportTarget(
  BuildContext context, {
  required ExportKind kind,
  required List<Vehicle> vehicles,
}) async {
  if (!needsVehiclePicker(kind, vehicleCount: vehicles.length)) {
    if (vehicles.isEmpty) return null;
    return SingleVehicleTarget(vehicles.first.id, positionalIndex: 1);
  }

  return CalmSheet.show<ExportTarget>(
    context,
    builder: (context) => ExportVehiclePickerSheet(
      kind: kind,
      vehicles: vehicles,
      onChoice: (target) => Navigator.of(context).pop(target),
    ),
  );
}

/// The sheet itself, without the route.
///
/// Public so a test pumps the SHIPPED widget rather than a hand-built copy of
/// it — a test that photographs its own composition stays green while the real
/// sheet reorders its rows.
class ExportVehiclePickerSheet extends StatelessWidget {
  /// Creates the sheet.
  const ExportVehiclePickerSheet({
    required this.kind,
    required this.vehicles,
    required this.onChoice,
    super.key,
  });

  /// Which export is asking.
  final ExportKind kind;

  /// The garage, in its own order.
  final List<Vehicle> vehicles;

  /// What to do with the answer.
  final ValueChanged<ExportTarget> onChoice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CalmSheet(
      title: l10n.backupPickVehicle,
      children: [
        CalmRowGroup(
          rows: [
            for (var i = 0; i < vehicles.length; i++)
              CalmListRow(
                title: vehicles[i].name,
                onTap: () => onChoice(
                  // ONE-BASED, and it travels with the choice: a name written
                  // only in Arabic script transliterates to nothing, and the
                  // filename falls back to `vehicle-2` by list position.
                  SingleVehicleTarget(
                    vehicles[i].id,
                    positionalIndex: i + 1,
                  ),
                ),
              ),
            if (kind.offersAllVehicles)
              CalmListRow(
                title: l10n.backupAllVehicles,
                onTap: () => onChoice(const AllVehiclesTarget()),
              ),
          ],
        ),
      ],
    );
  }
}
