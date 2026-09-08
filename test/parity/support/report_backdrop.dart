/// `report.service` under the artboard's own data.
///
/// The reference draws a specific VW Golf VII — 62,400 → 187,412 km, 34
/// services, €6,842, and an August and a June 2026 in the preview. The capture
/// needs exactly those, so this is a fake repository rather than a seeded
/// store: a drift stream never delivers inside a widget test's fake async, and
/// the capture would photograph the pre-data frame.
library;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/report/application/report_notifier.dart';
import 'package:odova/features/report/presentation/report_service_screen.dart';
import 'package:odova/l10n/locale_controller.dart';

import '../../features/home/home_fixture.dart';
import 'parity_capture.dart';

/// The report screen, ready to be a capture's `child`.
Widget reportBackdrop({required bool rtl, required Locale locale}) =>
    ProviderScope(
      overrides: <Override>[
        settingsProvider.overrideWith(
          (ref) => Stream.value(homeSettings(golfId)),
        ),
        vehiclesProvider.overrideWith(
          (ref) => Stream.value([
            homeVehicle(golfId, rtl ? 'گلف' : 'VW Golf VII'),
          ]),
        ),
        reportRepositoryProvider.overrideWithValue(
          _ArtboardReportRepository(rtl: rtl),
        ),
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 9, 2, 12)),
        ),
        deviceLocalesProvider.overrideWithValue(
          artboardDeviceLocales(locale),
        ),
      ],
      child: const ReportServiceScreen(),
    );

/// The history the reference draws.
class _ArtboardReportRepository implements ReportRepository {
  const _ArtboardReportRepository({required this.rtl});

  final bool rtl;

  static const String _ulid = '01K1C4V2H9B8N3Q7ZE5RY6TMW';
  static const String _abc = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  static String _body(int i) => '$_ulid${_abc[i % 32]}';

  @override
  Future<ReportInputs> read(String vehicleId) async {
    final id = VehicleId.tryParse('veh_${_ulid}0')!;
    final eur = Currency.tryParse('EUR')!;

    ServiceRecord service(int i, String on, int km, int cents, String label) =>
        ServiceRecord(
          id: ServiceRecordId.tryParse('srv_${_body(i)}')!,
          vehicleId: id,
          occurredOn: on,
          odometer: Distance.fromKm(km),
          odometerUnit: DistanceUnit.km,
          vendor: 'Bosch Car Service',
          invoiceRef: '26-1184',
          lines: [
            ServiceLine(
              id: ServiceLineId.tryParse('lin_${_body(i)}')!,
              serviceRecordId: ServiceRecordId.tryParse('srv_${_body(i)}')!,
              label: label,
              amount: Money(cents, eur),
            ),
          ],
          createdAtUtcMs: 1000 + i,
          updatedAtUtcMs: 1000 + i,
        );

    return ReportInputs(
      vehicle: Vehicle(
        id: id,
        name: rtl ? 'گلف' : 'VW Golf VII',
        vehicleType: VehicleType.car,
        fuelKindDefault: FuelKind.diesel,
        status: VehicleStatus.active,
        model: '1.6 TDI',
        year: 2016,
        // The artboard's own date. March 2018 to September 2026 is the
        // "8 yr 6 mo" the reference prints, and the 1st is what puts the
        // anniversary inside September rather than two days after the capture.
        purchaseDate: '2018-03-01',
        purchaseOdometer: const Distance.fromKm(62400),
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
      records: [
        service(1, '2026-08-06', 186650, 9250, 'Air filter, cabin filter'),
        service(2, '2026-06-14', 174300, 18450, 'Oil and filter, cabin filter'),
        service(3, '2026-02-02', 168110, 41200, 'Front brake pads and discs'),
      ],
      items: const [],
      // The reference's header reads `62,400 → 187,412 km`, so the capture
      // needs a reading to be the second half of it. §12 uses the latest
      // ENTERED one and never a projection, which is why this is a reading
      // rather than a due-engine estimate.
      series: ReadingSeries.from([
        OdometerReading(
          id: OdometerReadingId.tryParse('odo_${_ulid}1')!,
          vehicleId: id,
          occurredOn: '2026-06-14',
          odometer: const Distance.fromKm(187412),
          odometerUnit: DistanceUnit.km,
          source: OdometerSource.manual,
          createdAtUtcMs: 2000,
          updatedAtUtcMs: 2000,
        ),
      ], const []),
    );
  }
}
