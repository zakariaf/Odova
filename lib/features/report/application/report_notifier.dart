// SPEC.md §12's `report.service`, as state.
//
// One notifier holding the four toggles and the document they produce. The
// document is REBUILT on every toggle rather than patched, because §12's
// promise is that "the preview IS the document" — a patched preview and a
// freshly built PDF are two renderings that agree until the day they do not,
// and the day they do not is the day someone hands a buyer a file that does
// not match what they checked on screen.
//
// Rebuilding is affordable: `buildServiceReport` is pure arithmetic over rows
// already in memory, and EPIC-12's recompute budget measured 5,000 rows at
// 3.6 ms.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/report/service_report.dart';
import 'package:odova/core/time/civil_date.dart';

/// Everything `report.service` reads, in one shot.
///
/// A whole-vehicle read rather than a paged one: §12 says the screen is
/// "opened once or twice in the life of the car", and the document is the
/// entire history by definition. Paging it would mean a report that depended
/// on how far the user had scrolled.
@immutable
class ReportInputs {
  /// Creates the inputs.
  const ReportInputs({
    required this.vehicle,
    required this.records,
    required this.items,
    required this.series,
    this.fuel,
  });

  /// The vehicle the report is about.
  final Vehicle vehicle;

  /// Every service record it has.
  final List<ServiceRecord> records;

  /// Its tracked items, for *Maintenance at a glance*.
  final List<ServiceItem> items;

  /// Its entered readings.
  final ReadingSeries series;

  /// The fuel summary, or null when there are no tanks.
  final FuelSummaryFacts? fuel;
}

/// What the screen renders.
@immutable
class ReportState {
  /// Creates the state.
  const ReportState({
    this.options = const ServiceReportOptions(),
    this.document,
  });

  /// The four toggles.
  final ServiceReportOptions options;

  /// The document, or null while the inputs are still loading.
  final ServiceReportDocument? document;

  /// Whether §12 lets Share PDF be pressed.
  ///
  /// A report of no services is a page with a header and a footer, and §12
  /// disables the button rather than producing one — with the reason under it,
  /// never in a toast.
  bool get canShare =>
      document?.years.expand((y) => y.records).isNotEmpty ?? false;

  /// A copy with [options] applied.
  ReportState copyWith({
    ServiceReportOptions? options,
    ServiceReportDocument? document,
  }) => ReportState(
    options: options ?? this.options,
    document: document ?? this.document,
  );
}

/// Reads a vehicle's whole history for the report.
///
/// An interface rather than a function type, and the lint is silenced for it:
/// this is a PORT, the fake that stands in for it carries its own fixture, and
/// a typedef would make every override an inline closure with no name in a
/// stack trace. `CrashSink` in `lib/app/error_handlers.dart` is the same
/// shape for the same reason.
// ignore: one_member_abstracts
abstract interface class ReportRepository {
  /// Everything §12's document is built from.
  Future<ReportInputs> read(String vehicleId);
}

/// The report screen's state.
class ReportNotifier extends Notifier<ReportState> {
  ReportInputs? _inputs;
  var _loading = false;

  @override
  ReportState build() => const ReportState();

  /// Loads the vehicle's history once.
  ///
  /// Called from the screen's `build` behind a microtask — a widget's build
  /// may not modify a provider, and this is the seam EPIC-10 settled on for
  /// every screen that needs a read before its first frame.
  void ensureLoaded(String vehicleId, {required CivilDate today}) {
    if (_loading || _inputs != null) return;
    _loading = true;
    unawaited(
      Future.microtask(() async {
        final inputs = await ref.read(reportRepositoryProvider).read(vehicleId);
        _inputs = inputs;
        state = state.copyWith(document: _build(inputs, state.options, today));
      }),
    );
  }

  /// Applies [options] and rebuilds the document in the same frame.
  ///
  /// Synchronous on purpose. §12: "the toggles change it live" — a preview
  /// that lags by a frame is a preview that is briefly lying about what the
  /// file will contain.
  void setOptions(ServiceReportOptions options, {required CivilDate today}) {
    final inputs = _inputs;
    state = ReportState(
      options: options,
      document: inputs == null ? null : _build(inputs, options, today),
    );
  }

  static ServiceReportDocument _build(
    ReportInputs inputs,
    ServiceReportOptions options,
    CivilDate today,
  ) => buildServiceReport(
    vehicle: inputs.vehicle,
    records: inputs.records,
    items: inputs.items,
    series: inputs.series,
    fuel: inputs.fuel,
    options: options,
    today: today,
  );
}

/// The report screen's provider.
final NotifierProvider<ReportNotifier, ReportState> reportProvider =
    NotifierProvider<ReportNotifier, ReportState>(ReportNotifier.new);

/// The store this feature reads through.
///
/// Overridden in tests. There is no default implementation yet: the whole-
/// vehicle read spans five tables and belongs with the other repositories,
/// and wiring a half-built one here would be a second query to keep in step
/// with `history_repository.dart`.
final Provider<ReportRepository> reportRepositoryProvider =
    Provider<ReportRepository>(
      (ref) => throw UnimplementedError(
        'reportRepositoryProvider must be overridden until EPIC-12 wires the '
        'whole-vehicle read.',
      ),
    );
