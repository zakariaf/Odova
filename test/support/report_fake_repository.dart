/// A `ReportRepository` with a generated history and no database.
///
/// §12's screen reads a whole vehicle at once — the document IS the entire
/// history — so there is no paging to fake and no cursor to get wrong. What
/// this does have to be able to produce is the three states §12 separates: no
/// services, one service, and hundreds.
library;

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/report/application/report_notifier.dart';

const String _ulid = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
const String _abc = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// The plate the fake vehicle carries, so a test can assert it is absent.
const String kFakePlate = 'M-AB 1234';

/// And its VIN.
const String kFakeVin = 'WVWZZZ1KZAW000001';

String _body(int i) =>
    '${_ulid.substring(0, 20)}'
    '${_abc[i ~/ 1024 % 32]}${_abc[i ~/ 32 % 32]}${_abc[i % 32]}'
    '${_abc[0]}${_abc[0]}${_abc[0]}';

/// A repository over a generated service history.
class FakeReportRepository implements ReportRepository {
  /// Creates a fake holding [serviceCount] services.
  FakeReportRepository({required this.serviceCount});

  /// How many services the "vehicle" has.
  final int serviceCount;

  @override
  Future<ReportInputs> read(String vehicleId) async {
    final id = VehicleId.tryParse('veh_${_ulid.substring(0, 26)}')!;
    final currency = Currency.tryParse('EUR')!;

    return ReportInputs(
      vehicle: Vehicle(
        id: id,
        name: 'The Golf',
        vehicleType: VehicleType.car,
        fuelKindDefault: FuelKind.diesel,
        status: VehicleStatus.active,
        model: '1.6 TDI',
        year: 2016,
        plate: kFakePlate,
        vin: kFakeVin,
        purchaseDate: '2018-03-04',
        purchaseOdometer: const Distance.fromKm(62400),
        createdAtUtcMs: 1,
        updatedAtUtcMs: 1,
      ),
      records: [
        for (var i = 0; i < serviceCount; i++)
          ServiceRecord(
            id: ServiceRecordId.tryParse('srv_${_body(i)}')!,
            vehicleId: id,
            // Spread across years, so the year headings and their subtotals
            // are exercised rather than assumed.
            occurredOn:
                '${2026 - i ~/ 6}-'
                '${(i % 12 + 1).toString().padLeft(2, '0')}-14',
            odometer: Distance.fromKm(180000 - i * 400),
            odometerUnit: DistanceUnit.km,
            vendor: 'Bosch Car Service',
            lines: [
              ServiceLine(
                id: ServiceLineId.tryParse('lin_${_body(i)}')!,
                serviceRecordId: ServiceRecordId.tryParse('srv_${_body(i)}')!,
                label: 'Oil and filter',
                amount: Money(18450, currency),
              ),
            ],
            createdAtUtcMs: 1 + i,
            updatedAtUtcMs: 1 + i,
          ),
      ],
      items: const [],
      series: ReadingSeries.from(const [], const []),
    );
  }
}
