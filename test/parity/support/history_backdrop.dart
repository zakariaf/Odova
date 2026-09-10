/// `history` under the artboard's own data.
///
/// The reference draws a September and an August with real rows, so the
/// capture needs a repository holding exactly those — a fake rather than a
/// seeded store, because a drift stream never delivers inside a widget test's
/// fake async and the capture would photograph the pre-data frame.
library;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/history/history_cursor.dart';
import 'package:odova/core/history/history_entry.dart';
import 'package:odova/core/history/history_filter.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/history_repository.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/history/application/history_notifier.dart';
import 'package:odova/features/history/presentation/history_screen.dart';
import 'package:odova/l10n/locale_controller.dart';

import '../../features/home/home_fixture.dart';
import 'parity_capture.dart';

/// The timeline, ready to be a capture's `child`.
Widget historyBackdrop({required bool rtl, required Locale locale}) =>
    ProviderScope(
      overrides: <Override>[
        settingsProvider.overrideWith(
          (ref) => Stream.value(homeSettings(golfId)),
        ),
        vehiclesProvider.overrideWith(
          (ref) => Stream.value([
            homeVehicle(golfId, rtl ? 'گلف' : 'The Golf'),
          ]),
        ),
        historyRepositoryProvider.overrideWithValue(
          const _ArtboardHistoryRepository(),
        ),
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 9, 2, 12)),
        ),
        deviceLocalesProvider.overrideWithValue(
          artboardDeviceLocales(locale),
        ),
      ],
      child: const HistoryScreen(),
    );

/// The rows the reference draws.
class _ArtboardHistoryRepository implements HistoryRepository {
  const _ArtboardHistoryRepository();

  static const List<HistoryEntry> _entries = [
    HistoryEntry(
      kind: HistoryEntryKind.fillUp,
      id: 'fil_01K1C4V2H9B8N3Q7ZE5RY6TMW1',
      occurredOn: '2026-09-02',
      createdAtUtcMs: 9000,
      minorUnits: 7420,
      currency: 'EUR',
      odometerM: 187412000,
      quantity: 42800,
      quantityForm: 'ml',
      label: 'Shell A61',
    ),
    HistoryEntry(
      kind: HistoryEntryKind.expense,
      id: 'exp_01K1C4V2H9B8N3Q7ZE5RY6TMW2',
      occurredOn: '2026-09-01',
      createdAtUtcMs: 8000,
      minorUnits: 61200,
      currency: 'EUR',
      label: 'Insurance',
      secondaryLabel: 'Allianz',
    ),
    HistoryEntry(
      kind: HistoryEntryKind.fillUp,
      id: 'fil_01K1C4V2H9B8N3Q7ZE5RY6TMW3',
      occurredOn: '2026-08-12',
      createdAtUtcMs: 7000,
      minorUnits: 7830,
      currency: 'EUR',
      odometerM: 186743000,
      quantity: 44800,
      quantityForm: 'ml',
      label: 'Aral',
    ),
    HistoryEntry(
      kind: HistoryEntryKind.service,
      id: 'srv_01K1C4V2H9B8N3Q7ZE5RY6TMW4',
      occurredOn: '2026-08-06',
      createdAtUtcMs: 6000,
      minorUnits: 9250,
      currency: 'EUR',
      odometerM: 186650000,
      label: 'Air and cabin filter',
      secondaryLabel: 'Bosch',
    ),
    HistoryEntry(
      kind: HistoryEntryKind.trip,
      id: 'trp_01K1C4V2H9B8N3Q7ZE5RY6TMW5',
      occurredOn: '2026-08-01',
      createdAtUtcMs: 5000,
      minorUnits: 2650,
      currency: 'EUR',
      odometerM: 145000,
      label: 'München – Salzburg',
      secondaryLabel: 'business',
    ),
  ];

  @override
  Future<Result<HistoryPage, PersistFailure>> page({
    required String vehicleId,
    required HistoryFilter filter,
    HistoryCursor? after,
    int limit = 60,
  }) async => const Ok(HistoryPage(entries: _entries, hasMore: false));

  @override
  Future<Result<HistoryPage, PersistFailure>> pageAnchoredAt({
    required String vehicleId,
    required HistoryFilter filter,
    required MonthKey month,
    int limit = 60,
  }) async => const Ok(HistoryPage(entries: _entries, hasMore: false));

  @override
  Future<Result<List<MonthIndexEntry>, PersistFailure>> monthIndex({
    required String vehicleId,
    required HistoryFilter filter,
    required CalmCalendar calendar,
  }) async => Ok([
    MonthIndexEntry(
      monthKey: MonthKey(calendar: calendar, year: 2026, month: 9),
      count: 2,
      totals: const {'EUR': 68620},
    ),
    MonthIndexEntry(
      monthKey: MonthKey(calendar: calendar, year: 2026, month: 8),
      count: 5,
      totals: const {'EUR': 19730},
    ),
  ]);
}
