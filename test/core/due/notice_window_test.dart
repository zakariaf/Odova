// How much warning an item gets before it is due, and how much forgiveness
// after.
//
// SPEC.md §3 *Notice window* and *The due engine* (`grace_m`, `grace_days`);
// §2's one-lead-time rule.
//
// The distinction that costs money if it is lost: NOTICE is the warning before
// the due point and GRACE is the tolerance after it. They are computed by the
// same formula and they are not the same setting. A user who asks for 2,000 km
// of warning has asked to be told earlier — not to be forgiven longer, which
// would move the point at which their car reads `overdue` and is the opposite
// of what they wanted.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/notice_window.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

const _id = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';

ServiceItem item({
  int? intervalKm,
  int? intervalMonths,
  int? targetKm,
  String? targetDate,
  int? noticeKm,
  int? noticeDays,
}) => ServiceItem(
  id: ServiceItemId.tryParse('rem_$_id')!,
  vehicleId: VehicleId.tryParse('veh_$_id')!,
  kind: ServiceKind.oilAndFilter,
  intervalDistance: intervalKm == null ? null : Distance.fromKm(intervalKm),
  intervalMonths: intervalMonths,
  targetOdometer: targetKm == null ? null : Distance.fromKm(targetKm),
  targetDate: targetDate,
  noticeDistance: noticeKm == null ? null : Distance.fromKm(noticeKm),
  noticeDays: noticeDays,
  priority: ServicePriority.normal,
  rollover: ServiceRollover.fromActual,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

Vehicle vehicle({int? noticeKm, int? noticeDays}) => Vehicle(
  id: VehicleId.tryParse('veh_$_id')!,
  name: 'The Golf',
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  noticeDistance: noticeKm == null ? null : Distance.fromKm(noticeKm),
  noticeDays: noticeDays,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

AppSettings settings({int? noticeKm, int? noticeDays}) => AppSettings(
  schemaVersion: 1,
  currencyDefault: Currency.tryParse('EUR')!,
  noticeDistance: noticeKm == null ? null : Distance.fromKm(noticeKm),
  noticeDays: noticeDays,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

NoticeWindow windowFor(
  ServiceItem forItem, {
  Vehicle? onVehicle,
  AppSettings? withSettings,
}) => noticeWindow(
  item: forItem,
  vehicle: onVehicle ?? vehicle(),
  settings: withSettings ?? settings(),
);

void main() {
  group('the computed distance window is 10% of the interval, clamped', () {
    test('20,000 km gives 2,000 km, clamped down to the 1,000 km ceiling', () {
      final window = windowFor(item(intervalKm: 20000));
      expect(window.noticeDistanceMetres, kNoticeDistanceCeilingMetres);
    });

    test('an 800 km chain lube gives 80 km, clamped up to 200 km', () {
      // A motorcycle chain. 80 km of warning is one commute; the floor exists
      // so a short interval still gives a usable heads-up.
      final window = windowFor(item(intervalKm: 800));
      expect(window.noticeDistanceMetres, kNoticeDistanceFloorMetres);
    });

    test('5,000 km gives 500 km, inside the clamp and untouched', () {
      final window = windowFor(item(intervalKm: 5000));
      expect(window.noticeDistanceMetres, const Distance.fromKm(500).metres);
    });
  });

  group('the computed time window is 10% of the interval in days, clamped', () {
    test('twelve months gives 36.5 days, clamped down to 30', () {
      // 0.10 x 12 x 30.44 = 36.528.
      final window = windowFor(item(intervalMonths: 12));
      expect(window.noticeDays, kNoticeDaysCeiling);
    });

    test('six months gives 18 days — 18.264, rounded half away from zero', () {
      final window = windowFor(item(intervalMonths: 6));
      expect(window.noticeDays, 18);
    });

    test('one month gives 3.044 days, clamped up to the 7-day floor', () {
      final window = windowFor(item(intervalMonths: 1));
      expect(window.noticeDays, kNoticeDaysFloor);
    });
  });

  group('a one-off target has no percentage, so it gets the ceiling', () {
    test('a target odometer gets 1,000 km', () {
      final window = windowFor(item(targetKm: 150000));
      expect(window.noticeDistanceMetres, kNoticeDistanceCeilingMetres);
    });

    test('a target date gets 30 days', () {
      final window = windowFor(item(targetDate: '2027-01-01'));
      expect(window.noticeDays, kNoticeDaysCeiling);
    });
  });

  group('an explicit override is used as written and NOT clamped', () {
    test('a 2,000 km item override survives the 1,000 km ceiling', () {
      // §3: "the clamp defines the computed default only, which is why
      // settings.notifications may offer 2,000 km".
      final window = windowFor(item(intervalKm: 10000, noticeKm: 2000));
      expect(window.noticeDistanceMetres, const Distance.fromKm(2000).metres);
    });

    test('a 3-day override survives the 7-day floor', () {
      final window = windowFor(item(intervalMonths: 12, noticeDays: 3));
      expect(window.noticeDays, 3);
    });
  });

  group('four levels of resolution, most specific first', () {
    final oil = item(intervalKm: 10000, intervalMonths: 12);

    test('the item override wins over everything', () {
      final window = windowFor(
        item(intervalKm: 10000, noticeKm: 1500),
        onVehicle: vehicle(noticeKm: 800),
        withSettings: settings(noticeKm: 400),
      );
      expect(window.noticeDistanceMetres, const Distance.fromKm(1500).metres);
    });

    test('then the vehicle override', () {
      final window = windowFor(
        oil,
        onVehicle: vehicle(noticeKm: 800),
        withSettings: settings(noticeKm: 400),
      );
      expect(window.noticeDistanceMetres, const Distance.fromKm(800).metres);
    });

    test('then Settings', () {
      final window = windowFor(oil, withSettings: settings(noticeKm: 400));
      expect(window.noticeDistanceMetres, const Distance.fromKm(400).metres);
    });

    test('then the computed default', () {
      final window = windowFor(oil);
      expect(window.noticeDistanceMetres, const Distance.fromKm(1000).metres);
    });

    test('the two axes resolve their overrides independently', () {
      // A vehicle-level distance override and a Settings-level day override.
      final window = windowFor(
        oil,
        onVehicle: vehicle(noticeKm: 800),
        withSettings: settings(noticeKm: 400, noticeDays: 21),
      );
      expect(window.noticeDistanceMetres, const Distance.fromKm(800).metres);
      expect(window.noticeDays, 21);
    });
  });

  group('grace is NOT the notice override', () {
    test('an overridden notice leaves grace at the computed default', () {
      // The finding this test exists for. A user who asks for 2,000 km of
      // warning has asked to be told EARLIER. Reading that as 2,000 km of
      // forgiveness moves the point at which their car reads `overdue`
      // outward by a kilometre for every kilometre of extra warning — the
      // opposite of what they asked for, and silent.
      final window = windowFor(item(intervalKm: 10000, noticeKm: 2000));

      expect(window.noticeDistanceMetres, const Distance.fromKm(2000).metres);
      expect(
        window.graceDistanceMetres,
        const Distance.fromKm(1000).metres,
        reason: '10% of 10,000 km, clamped — the computed default',
      );
    });

    test('and the same on the time axis', () {
      final window = windowFor(item(intervalMonths: 6, noticeDays: 45));

      expect(window.noticeDays, 45);
      expect(window.graceDays, 18, reason: '10% of 6 months, computed');
    });

    test('with no override at all the two coincide, which is the default', () {
      final window = windowFor(item(intervalKm: 5000, intervalMonths: 6));

      expect(window.noticeDistanceMetres, window.graceDistanceMetres);
      expect(window.noticeDays, window.graceDays);
    });
  });

  test('the constants are the ones SPEC.md §3 states', () {
    expect(kNoticeDistanceFloorMetres, 200000);
    expect(kNoticeDistanceCeilingMetres, 1000000);
    expect(kNoticeDaysFloor, 7);
    expect(kNoticeDaysCeiling, 30);
    expect(kDaysPerMonth, 30.44);
    expect(kNoticeFraction, 0.10);
  });
}
