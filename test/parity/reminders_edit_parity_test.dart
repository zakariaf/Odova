// `reminders.edit`, in all four combinations.
//
// The artboard's own reminder: a 10,000 km / 12-month oil change with a
// baseline, so the notice placeholder has an interval to be a tenth of and the
// *Last done* block has evidence in it.
@Tags(['parity'])
library;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/reminders/application/reminders_edit_notifier.dart';
import 'package:odova/features/reminders/domain/reminder_draft.dart';
import 'package:odova/features/reminders/ui/reminders_edit_screen.dart';
import 'package:odova/l10n/locale_controller.dart';

import '../features/home/home_fixture.dart';
import 'support/parity_capture.dart';

const _oilId = 'rem_01JQ8ZK3M7F0R6XN2E9TB4HCVA';

ServiceItem _item({required bool rtl}) => ServiceItem(
  id: ServiceItemId.tryParse(_oilId)!,
  vehicleId: golfId,
  kind: ServiceKind.custom,
  label: rtl ? 'روغن و فیلتر' : 'Oil and filter',
  priority: ServicePriority.normal,
  rollover: ServiceRollover.fromActual,
  intervalDistance: const Distance.fromKm(10000),
  intervalDistanceUnit: DistanceUnit.km,
  intervalMonths: 12,
  baselineDate: '2026-05-05',
  baselineOdometer: const Distance.fromKm(184292),
  isTracked: true,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('reminders.edit ${config.theme}/${config.dir}', (tester) async {
      final rtl = config.dir == 'rtl';
      final vehicle = homeVehicle(golfId, rtl ? 'گلف' : 'The Golf');
      final item = _item(rtl: rtl);

      await captureParity(
        tester,
        screen: 'reminders.edit',
        config: config,
        child: ProviderScope(
          overrides: <Override>[
            settingsProvider.overrideWith(
              (ref) => Stream.value(homeSettings(golfId)),
            ),
            vehiclesProvider.overrideWith((ref) => Stream.value([vehicle])),
            // The STATE, synchronously. `captureParity` takes a single frame
            // and the notifier's load awaits two streams — a capture that let
            // it run would photograph the empty modal head, which is a real
            // state and not this one.
            remindersEditProvider(_oilId).overrideWith(
              () => _ReadyNotifier(
                ReminderEditReady(
                  ReminderDraft.of(
                    item,
                    unit: DistanceUnit.km,
                    groupingSeparator: rtl ? '٬' : ',',
                  ),
                  vehicle: vehicle,
                  item: item,
                ),
              ),
            ),
            clockProvider.overrideWithValue(
              Clock.fixed(DateTime.utc(2026, 9, 5, 12)),
            ),
            deviceLocalesProvider.overrideWithValue([
              Locale(
                config.locale.languageCode,
                config.locale.languageCode == 'en' ? 'GB' : 'DE',
              ),
            ]),
          ],
          child: const RemindersEditScreen(reminderId: _oilId),
        ),
      );
    });
  }
}

/// A notifier that is already loaded.
class _ReadyNotifier extends RemindersEditNotifier {
  _ReadyNotifier(this._ready) : super(_oilId);

  final ReminderEditReady _ready;

  @override
  ReminderEditState build() => _ready;
}
