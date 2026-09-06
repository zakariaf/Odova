// One page of the vehicle's timeline.
//
// SPEC.md §11 *Pagination*: "Keyset, never offset … Offset pagination would
// renumber the list the moment a backdated 2019 entry is saved." That is not a
// performance note — a user scrolling eight years of history while a restore
// writes rows underneath them is this screen's ordinary case, and an offset
// query shows them the same row twice and skips another.
//
// The union lives in SQL and not in Dart, for the same reason. Six `SELECT`s
// merged in memory would each need their own page size, and the merge would
// have to over-fetch from all six to fill sixty rows — which is exactly the
// full-table read the keyset exists to avoid.
//
// Two exclusions are the QUERY's, never the UI's:
//
//   1. **Derived odometer readings.** §3 makes every record carrying an
//      odometer emit one, so a fill-up would appear twice — once as itself and
//      once as the reading it implied. `source = 'manual'` is the whole rule.
//   2. **Soft-deleted rows.** §3's delete is "immediate and permanent to the
//      user". A row dropped in Dart has still cost a slot in a page of sixty.
import 'package:drift/drift.dart' show Variable;
import 'package:odova/core/history/history_cursor.dart';
import 'package:odova/core/history/history_entry.dart';
import 'package:odova/core/history/history_filter.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/guard.dart';

/// One row of money on a date, before it is grouped into a month.
///
/// `minorUnits` and not `amountMinor`: that name is reserved by
/// `no_conversion_on_write_test` for the minor half of a `Money` being
/// unwrapped into a column, and this is the opposite direction — a raw column
/// READ that never stops travelling beside its currency. Borrowing the gate's
/// vocabulary for a different meaning is how a gate stops meaning anything.
typedef _MoneyRow = ({String occurredOn, int? minorUnits, String? currency});

/// Reads the timeline.
class HistoryRepository {
  /// Creates a repository over [_db].
  const HistoryRepository(this._db);

  final AppDatabase _db;

  /// One page of [vehicleId]'s timeline, newest first.
  ///
  /// [after] resumes a previous page; null starts at the top. §11 fixes the
  /// page at 60 rows, and [limit] exists so a test can prove the paging rather
  /// than seed 130 rows to see two pages.
  Future<Result<HistoryPage, PersistFailure>> page({
    required String vehicleId,
    required HistoryFilter filter,
    HistoryCursor? after,
    int limit = 60,
  }) => guardPersist(() async {
    final rows = await _select(
      vehicleId: vehicleId,
      filter: filter,
      after: after,
      // ONE more than asked for. Whether another page exists is answered by
      // finding a 61st row, not by comparing the page's length to the limit:
      // a history that ends exactly on a page boundary is not the end of the
      // list, and treating it as one truncates the user's records at row 60.
      limit: limit + 1,
    );
    final hasMore = rows.length > limit;
    return Ok(
      HistoryPage(
        entries: hasMore ? rows.sublist(0, limit) : rows,
        hasMore: hasMore,
      ),
    );
  });

  /// A fresh page anchored at the top of [year]-[month].
  ///
  /// §11's year scrubber: "release runs a fresh keyset query anchored there and
  /// DISCARDS the loaded window, so memory stays flat at 40 records or 4,000."
  /// The anchor is the last instant of that month, so the month itself is the
  /// first thing on screen and nothing newer comes with it.
  Future<Result<HistoryPage, PersistFailure>> pageAnchoredAt({
    required String vehicleId,
    required HistoryFilter filter,
    required int year,
    required int month,
    int limit = 60,
  }) {
    final last = _lastDayOf(year, month);
    return page(
      vehicleId: vehicleId,
      filter: filter,
      // A cursor one tick PAST the end of the month, so the month's own newest
      // row is included rather than skipped by a strict comparison.
      after: HistoryCursor(
        occurredOn: last,
        createdAtUtcMs: _farFuture,
        id: _highestId,
      ),
      limit: limit,
    );
  }

  /// The month index: a header's count and subtotals, with no entry loaded.
  ///
  /// §11: "Eight years is ~96 rows, and it drives the header subtotal, the
  /// year scrubber and the 'no entries in 2021' empty state without loading an
  /// entry row. Folding totals out of the loaded window instead would give a
  /// subtotal that grows as you scroll, because the bottom month is
  /// half-loaded."
  ///
  /// So this is an AGGREGATE over the whole vehicle, and the grouping happens
  /// in Dart rather than in SQL for one reason: the month depends on the
  /// user's calendar (§5), and SQLite cannot do Jalali. What it returns is one
  /// row per (date, currency, amount) — bounded by the number of ENTRIES, not
  /// by their contents — which is folded here.
  Future<Result<List<MonthIndexEntry>, PersistFailure>> monthIndex({
    required String vehicleId,
    required HistoryFilter filter,
    required CalmCalendar calendar,
  }) => guardPersist(() async {
    final rows = await _moneyRows(vehicleId: vehicleId, filter: filter);

    final counts = <MonthKey, int>{};
    final totals = <MonthKey, Map<String, int>>{};
    for (final row in rows) {
      final key = monthKeyOrNull(row.occurredOn, calendar);
      if (key == null) continue;
      counts[key] = (counts[key] ?? 0) + 1;
      // A trip contributes no money: §11's month total is what was PAID, and
      // a trip's costs are the fills and expenses already counted under it.
      // Adding them again would double every business month.
      if (row.currency == null || row.minorUnits == null) continue;
      final byCurrency = totals.putIfAbsent(key, () => <String, int>{});
      byCurrency[row.currency!] =
          (byCurrency[row.currency!] ?? 0) + row.minorUnits!;
    }

    final keys = counts.keys.toList()..sort(compareMonthKeysNewestFirst);
    return Ok([
      // Months with no entries are ABSENT, not present at zero: §11's
      // "no entries in 2021" empty state is the scrubber finding nothing here,
      // and a zero-count row would draw an empty header instead.
      for (final key in keys)
        MonthIndexEntry(
          monthKey: key,
          count: counts[key]!,
          totals: Map.unmodifiable(totals[key] ?? const <String, int>{}),
        ),
    ]);
  });

  Future<List<_MoneyRow>> _moneyRows({
    required String vehicleId,
    required HistoryFilter filter,
  }) async {
    final variables = <Variable<Object>>[];
    final union = <String>[];

    void add(HistoryEntryKind kind, String sql) {
      if (!filter.allows(kind)) return;
      union.add(sql);
      variables.add(Variable<String>(vehicleId));
    }

    add(
      HistoryEntryKind.fillUp,
      'SELECT occurred_on, total_cost_minor AS amount, currency '
      'FROM fill_ups WHERE vehicle_id = ? AND deleted_at_utc_ms IS NULL',
    );
    add(
      HistoryEntryKind.service,
      // A record's cost is the sum of its LINES — §10 gives it no second cost
      // field — so the money comes from the join, not from the record.
      'SELECT r.occurred_on, SUM(l.amount_minor) AS amount, l.currency '
      'FROM service_records r JOIN service_lines l '
      'ON l.service_record_id = r.id '
      'WHERE r.vehicle_id = ? AND r.deleted_at_utc_ms IS NULL '
      'GROUP BY r.id, l.currency',
    );
    add(
      HistoryEntryKind.expense,
      // Counted in the month it was PAID. History is cash, not accrual — the
      // coverage window spreads a policy across months on EPIC-13's cost
      // dashboard, and letting that leak here would make a September total
      // disagree with the September rows under it.
      'SELECT occurred_on, amount_minor AS amount, currency '
      'FROM expenses WHERE vehicle_id = ? AND deleted_at_utc_ms IS NULL',
    );
    add(
      HistoryEntryKind.trip,
      'SELECT started_on AS occurred_on, NULL AS amount, NULL AS currency '
      'FROM trips WHERE vehicle_id = ? AND deleted_at_utc_ms IS NULL',
    );
    add(
      HistoryEntryKind.odometer,
      'SELECT occurred_on, NULL AS amount, NULL AS currency '
      'FROM odometer_readings WHERE vehicle_id = ? '
      "AND source = 'manual' AND deleted_at_utc_ms IS NULL",
    );

    if (union.isEmpty) return const [];

    var sql =
        'SELECT occurred_on, amount, currency FROM '
        '(${union.join(' UNION ALL ')})';
    if (filter.year case final int year) {
      sql += ' WHERE occurred_on >= ? AND occurred_on <= ?';
      variables
        ..add(Variable<String>('$year-01-01'))
        ..add(Variable<String>('$year-12-31'));
    }

    final rows = await _db.customSelect(sql, variables: variables).get();
    return [
      for (final row in rows)
        (
          occurredOn: row.read<String>('occurred_on'),
          minorUnits: row.readNullable<int>('amount'),
          currency: row.readNullable<String>('currency'),
        ),
    ];
  }

  Future<List<HistoryEntry>> _select({
    required String vehicleId,
    required HistoryFilter filter,
    required HistoryCursor? after,
    required int limit,
  }) async {
    final variables = <Variable<Object>>[];
    final union = <String>[];

    void add(HistoryEntryKind kind, String sql) {
      if (!filter.allows(kind)) return;
      union.add(sql);
      variables.add(Variable<String>(vehicleId));
    }

    // Every arm selects the SAME column list, in the same order, because a
    // UNION matches by position and not by name. Six arms drifting by one
    // column is a silent type error that reads back as a station in the
    // currency slot.
    add(
      HistoryEntryKind.fillUp,
      "SELECT 'fillUp' AS kind, id, occurred_on, created_at_utc_ms, "
      'total_cost_minor AS minor, currency, odometer_m, '
      'COALESCE(quantity_ml, quantity_g, energy_wh) AS quantity, '
      "CASE WHEN quantity_ml IS NOT NULL THEN 'ml' "
      "WHEN quantity_g IS NOT NULL THEN 'g' "
      "WHEN energy_wh IS NOT NULL THEN 'wh' END AS quantity_form, "
      'station AS label, grade AS label2, is_full_tank, chain_broken '
      'FROM fill_ups WHERE vehicle_id = ? AND deleted_at_utc_ms IS NULL',
    );
    add(
      HistoryEntryKind.service,
      // The cost is the sum of the LINES — §10 gives a record no second cost
      // field — and the label is the first line's, which §11's row then joins
      // with the rest.
      "SELECT 'service' AS kind, r.id, r.occurred_on, r.created_at_utc_ms, "
      'SUM(l.amount_minor) AS minor, MIN(l.currency) AS currency, '
      'r.odometer_m, NULL AS quantity, NULL AS quantity_form, '
      'MIN(l.label) AS label, r.vendor AS label2, 1 AS is_full_tank, '
      '0 AS chain_broken '
      'FROM service_records r JOIN service_lines l '
      'ON l.service_record_id = r.id '
      'WHERE r.vehicle_id = ? AND r.deleted_at_utc_ms IS NULL '
      'GROUP BY r.id',
    );
    add(
      HistoryEntryKind.expense,
      "SELECT 'expense' AS kind, id, occurred_on, created_at_utc_ms, "
      'amount_minor AS minor, currency, odometer_m, NULL AS quantity, '
      'NULL AS quantity_form, COALESCE(label, category) AS label, '
      'vendor AS label2, 1 AS is_full_tank, 0 AS chain_broken '
      'FROM expenses WHERE vehicle_id = ? AND deleted_at_utc_ms IS NULL',
    );
    add(
      HistoryEntryKind.trip,
      // Dated by when it STARTED. §11 lists it among the five row types on one
      // reverse-chronological axis, and an open trip has no end date at all.
      "SELECT 'trip' AS kind, id, started_on AS occurred_on, "
      'created_at_utc_ms, NULL AS minor, NULL AS currency, '
      'start_odometer_m AS odometer_m, NULL AS quantity, '
      'NULL AS quantity_form, title AS label, purpose AS label2, '
      '1 AS is_full_tank, 0 AS chain_broken '
      'FROM trips WHERE vehicle_id = ? AND deleted_at_utc_ms IS NULL',
    );
    add(
      HistoryEntryKind.odometer,
      // MANUAL only. Everything else on this list already carries its own
      // odometer, and §3 has the fan-out emit a reading for each of them.
      "SELECT 'odometer' AS kind, id, occurred_on, created_at_utc_ms, "
      'NULL AS minor, NULL AS currency, odometer_m, NULL AS quantity, '
      'NULL AS quantity_form, NULL AS label, NULL AS label2, '
      '1 AS is_full_tank, 0 AS chain_broken '
      'FROM odometer_readings WHERE vehicle_id = ? '
      "AND source = 'manual' AND deleted_at_utc_ms IS NULL",
    );
    add(
      HistoryEntryKind.correction,
      // Dated by the READING it corrects, not by when the swap was recorded —
      // §11 puts the divider "at their from_reading position", because it
      // changes how the numbers either side of it are read.
      "SELECT 'correction' AS kind, c.id, r.occurred_on, "
      'c.created_at_utc_ms, NULL AS minor, NULL AS currency, '
      'c.new_m AS odometer_m, NULL AS quantity, NULL AS quantity_form, '
      'c.reason AS label, NULL AS label2, 1 AS is_full_tank, '
      '0 AS chain_broken '
      'FROM odometer_corrections c '
      'JOIN odometer_readings r ON r.id = c.from_reading_id '
      'WHERE c.vehicle_id = ? AND c.deleted_at_utc_ms IS NULL',
    );

    if (union.isEmpty) return const [];

    final where = <String>[];
    if (filter.year case final int year) {
      where.add('occurred_on >= ? AND occurred_on <= ?');
      variables
        ..add(Variable<String>('$year-01-01'))
        ..add(Variable<String>('$year-12-31'));
    }
    if (after != null) {
      // The tuple comparison, spelled out. SQLite supports row values, but
      // writing it long-hand keeps it readable next to `HistoryCursor` — and
      // one `=` in the wrong place here either repeats the boundary row on
      // every page or drops it entirely, neither of which is visible in sixty.
      where.add(
        '(occurred_on < ? OR (occurred_on = ? AND '
        '(created_at_utc_ms < ? OR (created_at_utc_ms = ? AND id < ?))))',
      );
      variables
        ..add(Variable<String>(after.occurredOn))
        ..add(Variable<String>(after.occurredOn))
        ..add(Variable<int>(after.createdAtUtcMs))
        ..add(Variable<int>(after.createdAtUtcMs))
        ..add(Variable<String>(after.id));
    }

    final sql =
        'SELECT * FROM '
        '(${union.join(' UNION ALL ')}) '
        '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')} '}'
        'ORDER BY occurred_on DESC, created_at_utc_ms DESC, id DESC '
        'LIMIT ?';
    variables.add(Variable<int>(limit));

    final rows = await _db.customSelect(sql, variables: variables).get();
    return [
      for (final row in rows)
        HistoryEntry(
          kind: _kindOf(row.read<String>('kind')),
          id: row.read<String>('id'),
          occurredOn: row.read<String>('occurred_on'),
          createdAtUtcMs: row.read<int>('created_at_utc_ms'),
          minorUnits: row.readNullable<int>('minor'),
          currency: row.readNullable<String>('currency'),
          odometerM: row.readNullable<int>('odometer_m'),
          quantity: row.readNullable<int>('quantity'),
          quantityForm: row.readNullable<String>('quantity_form'),
          label: row.readNullable<String>('label'),
          secondaryLabel: row.readNullable<String>('label2'),
          isFullTank: (row.readNullable<int>('is_full_tank') ?? 1) == 1,
          chainBroken: (row.readNullable<int>('chain_broken') ?? 0) == 1,
        ),
    ];
  }

  static HistoryEntryKind _kindOf(String wire) =>
      HistoryEntryKind.values.firstWhere((k) => k.name == wire);

  static String _lastDayOf(int year, int month) {
    const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    final leap =
        month == 2 && (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
    final day = leap ? 29 : lengths[month - 1];
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }

  /// Past any real `created_at`, so a month anchor includes its newest row.
  static const int _farFuture = 1 << 62;

  /// An id that sorts above every real one.
  ///
  /// Lowercase, because §3's ids are Crockford base-32 and therefore UPPERCASE
  /// — so every `z` here is above every character a ULID can hold. The first
  /// version used `'~'`, which is higher still and also the estimate mark;
  /// `check_status_encoding.sh` refuses a tilde built in Dart, and it is right
  /// to refuse one it cannot tell apart from a displayed estimate.
  static const String _highestId = 'zzzzzzzzzzzzzzzzzzzzzzzzzz';
}
