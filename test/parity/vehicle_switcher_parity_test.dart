// `vehicle.switcher`, in all four combinations.
//
// The reference shoots the sheet OVER `home`, with its scrim — so the band
// check runs against the whole 390x844 frame the artboard drew, not against a
// sheet floating on nothing. `HomeBackdrop` is EPIC-08's stand-in for the home
// screen, and EPIC-10 replaces it with the real one; if this capture's result
// changes when it does, the stand-in was lying (F-8.2).
@Tags(['parity'])
library;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/clock_suspicion.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/due/vehicle_due_snapshot.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/presentation/vehicle_switcher_sheet.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/theme/calm/calm_colors.dart';

import 'support/dialog_backdrop.dart';
import 'support/parity_capture.dart';

const _golf = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';
const _transit = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVB';
const _cb500x = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVC';

VehicleId _id(String raw) => VehicleId.tryParse(raw)!;

Vehicle _vehicle(
  String id,
  String name, {
  VehicleType type = VehicleType.car,
  bool business = false,
  int sortOrder = 0,
}) => Vehicle(
  id: _id(id),
  name: name,
  vehicleType: type,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  isBusiness: business,
  sortOrder: sortOrder,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

VehicleDueSnapshot _snapshot({
  required DueState? worst,
  required int km,
  String? label,
}) => VehicleDueSnapshot(
  assessments: const [],
  summary: DueSummary(
    counts: worst == null ? const {} : {worst: 1},
    worstItem: label == null
        ? null
        : ServiceItem(
            id: ServiceItemId.tryParse('rem_01JQ8ZK3M7F0R6XN2E9TB4HCVA')!,
            vehicleId: _id(_golf),
            kind: ServiceKind.custom,
            label: label,
            priority: ServicePriority.safety,
            rollover: ServiceRollover.fromActual,
            createdAtUtcMs: 1000,
            updatedAtUtcMs: 1000,
          ),
    worst: worst == null
        ? null
        : DueAssessment(
            state: worst,
            driver: DueDriver.distance,
            confidence: RateConfidence.measured,
            progress: 0.9,
          ),
  ),
  rate: const DailyDistance(
    metresPerDay: 40000,
    confidence: RateConfidence.measured,
  ),
  estimate: OdometerEstimate(
    metres: km * 1000,
    asOf: CivilDate.tryParse('2026-09-03')!,
    projection: OdometerProjection.entered,
    staleDays: 0,
  ),
  clock: ClockSuspicion(
    isSuspect: false,
    observedToday: CivilDate.tryParse('2026-09-03')!,
  ),
);

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('vehicle.switcher ${config.theme}/${config.dir}', (
      tester,
    ) async {
      final rtl = config.dir == 'rtl';
      // The artboard's own three vehicles, translated the way the artboard
      // translates them. The app never renames a user's car; the capture has to
      // compare like with like.
      final garage = [
        _vehicle(_golf, rtl ? 'گلف' : 'The Golf'),
        _vehicle(
          _transit,
          rtl ? 'ترنزیت' : 'Transit',
          type: VehicleType.van,
          business: true,
          sortOrder: 1,
        ),
        _vehicle(
          _cb500x,
          'CB500X',
          type: VehicleType.motorcycle,
          sortOrder: 2,
        ),
      ];

      await captureParity(
        tester,
        screen: 'vehicle.switcher',
        config: config,
        tab: 0,
        child: const HomeBackdrop(),
        overlay: ProviderScope(
          overrides: <Override>[
            clockProvider.overrideWithValue(
              Clock.fixed(DateTime.utc(2026, 9, 3)),
            ),
            deviceLocalesProvider.overrideWithValue([
              Locale(
                config.locale.languageCode,
                config.locale.languageCode == 'en' ? 'GB' : 'DE',
              ),
            ]),
            vehiclesProvider.overrideWith((ref) => Stream.value(garage)),
            settingsProvider.overrideWith(
              (ref) => Stream.value(
                AppSettings(
                  schemaVersion: 1,
                  currencyDefault: Currency.tryParse('EUR')!,
                  activeVehicleId: _id(_golf),
                  createdAtUtcMs: 1000,
                  updatedAtUtcMs: 1000,
                ),
              ),
            ),
            vehicleDueSnapshotProvider(_id(_golf)).overrideWithValue(
              _snapshot(
                worst: DueState.overdue,
                km: 187412,
                label: rtl ? 'روغن' : 'oil',
              ),
            ),
            vehicleDueSnapshotProvider(_id(_transit)).overrideWithValue(
              _snapshot(worst: DueState.ok, km: 96400),
            ),
            vehicleDueSnapshotProvider(_id(_cb500x)).overrideWithValue(
              _snapshot(worst: null, km: 23905),
            ),
          ],
          // `SizedBox.expand`, and it is the whole reason this capture works.
          // `CalmSheet` puts its body in a `Flexible`, which needs a BOUNDED
          // height — the modal route gives it one, and a `Stack`'s
          // non-positioned child gets LOOSE constraints, so the first version
          // of this file photographed a sheet measuring 390x0 at the very
          // bottom of the frame. Not `Positioned.fill`: that has to be a direct
          // child of the Stack, and this one is two widgets down.
          child: Builder(
            builder: (context) => SizedBox.expand(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: CalmColors.of(context).scrim),
                  ),
                  // `SafeArea(top: false)` is what the real route supplies:
                  // `CalmSheet.show` passes `useSafeArea: true`, so on device
                  // the sheet sits above the home indicator. There is no route
                  // here, so nothing adds it — and the whole sheet sat 34pt
                  // lower than the reference, which the band profile read as
                  // every edge inside it being absent.
                  const SafeArea(
                    top: false,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: VehicleSwitcherSheet(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
