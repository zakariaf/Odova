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

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/app/pdf/pdf_document_canvas.dart';
import 'package:odova/app/share/share_service.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/report/service_report.dart';
import 'package:odova/core/report/service_report_pdf.dart';
import 'package:odova/core/report/service_report_text.dart';
import 'package:odova/core/report/service_report_writer.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:path_provider/path_provider.dart';

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
    this.isBuilding = false,
    this.shareFailureCode,
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

  /// Set while §12's blocking "Building your report…" is on screen.
  ///
  /// Only above 200 records — §12 makes generation synchronous below that,
  /// because a progress dialog for work that takes 12 ms is a flash the user
  /// reads as a fault.
  final bool isBuilding;

  /// Why the last share did not happen, or null.
  ///
  /// A CODE, never a sentence: §2 keeps user-facing strings out of failures so
  /// they can be translated, mirrored and digit-shaped at the edge.
  final String? shareFailureCode;

  /// A copy with [options] applied.
  ReportState copyWith({
    ServiceReportOptions? options,
    ServiceReportDocument? document,
    bool? isBuilding,
    // A sentinel rather than `String?`, so clearing the failure and leaving it
    // alone are different calls. `null` meaning "unchanged" is why a retry
    // would keep showing the error it just cleared.
    bool clearFailure = false,
  }) => ReportState(
    options: options ?? this.options,
    document: document ?? this.document,
    isBuilding: isBuilding ?? this.isBuilding,
    shareFailureCode: clearFailure ? null : shareFailureCode,
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

  /// Builds §12's PDF and hands it to the OS share sheet.
  ///
  /// The blocking "Building your report…" is raised only above §12's 200-record
  /// threshold. A progress dialog for work that takes twelve milliseconds is a
  /// flash the user reads as a fault; a frozen button for work that takes two
  /// seconds is an app they force-quit.
  Future<void> sharePdf({
    required String vehicleName,
    required int positionalIndex,
    required ServiceReportPdfStrings strings,
    required ReportFormatters formatters,
    required bool rtl,
    String? region,
    PaperSize? paperOverride,
  }) async {
    final doc = state.document;
    if (doc == null) return;

    final records = doc.years.expand((y) => y.records).length;
    final blocking = needsProgressUi(recordCount: records);
    // Cleared FIRST, so a retry does not sit under a failure it has already
    // superseded — the user would read that as failing twice.
    state = state.copyWith(isBuilding: blocking, clearFailure: true);

    try {
      final canvas = PdfDocumentCanvas(fontBytes: await loadReportFont());
      writeServiceReportPdf(
        doc,
        canvas: canvas,
        paper: paperFor(region, override: paperOverride),
        rtl: rtl,
        scriptFamily: 'Vazirmatn',
        strings: strings,
        formatDate: formatters.date,
        formatDistance: formatters.distance,
        formatMoney: formatters.money,
      );

      final shared = await ref
          .read(shareServiceProvider)
          .shareFile(
            bytes: await canvas.save(),
            fileName: reportFileName(
              vehicleName: vehicleName,
              on: doc.generatedOn,
              positionalIndex: positionalIndex,
            ),
            mimeType: 'application/pdf',
          );

      state = ReportState(
        options: state.options,
        document: state.document,
        shareFailureCode: switch (shared) {
          Ok() => null,
          Err(:final failure) => failure.code,
        },
      );
    } finally {
      // In a `finally`, so a throw from the writer cannot leave the blocking
      // overlay on screen forever with no way past it.
      if (state.isBuilding) state = state.copyWith(isBuilding: false);
    }
  }

  /// §12's Cancel: abandons generation and deletes the temp file.
  ///
  /// A cancelled report that leaves a copy of somebody's service history in a
  /// cache directory is the leak §2 exists to prevent.
  Future<void> cancelShare() async {
    await ref.read(shareServiceProvider).discard();
    state = state.copyWith(isBuilding: false, clearFailure: true);
  }

  /// §12's Copy as text — the same document, as plain text on the clipboard.
  Future<void> copyAsText({
    required ServiceReportTextStrings strings,
    required ReportFormatters formatters,
  }) async {
    final doc = state.document;
    if (doc == null) return;

    await Clipboard.setData(
      ClipboardData(
        text: renderServiceReportText(
          doc,
          strings: strings,
          formatDate: formatters.date,
          formatDistance: formatters.distance,
          formatMoney: formatters.money,
          formatNumber: formatters.number,
        ),
      ),
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

/// The three formatters §12's document is rendered through.
///
/// REQUIRED, with no fallback. An earlier version defaulted them to stubs that
/// built a distance as `'\${estimated ? '~' : ''}\${metres ~/ 1000}'`, and
/// `check_status_encoding.sh` refused it — correctly, and for the third time
/// in this epic. The estimate mark belongs inside the app's real formatter,
/// which places it in a bidi isolate; a tilde concatenated in Dart lands on the
/// wrong side of the number on an RTL page.
///
/// The deeper problem with the stubs was not the tilde. A default formatter is
/// one that SHIPS the day a caller forgets to pass the real one, and it would
/// ship Latin digits into a Persian document. Making them required means that
/// mistake is a compile error.
@immutable
class ReportFormatters {
  /// Creates the set.
  const ReportFormatters({
    required this.date,
    required this.distance,
    required this.money,
    required this.number,
  });

  /// An ISO date as the display calendar renders it.
  final String Function(String isoDate) date;

  /// A distance with its unit, and the estimate mark placed by the formatter.
  final String Function(Distance, {required bool estimated}) distance;

  /// Money, isolated, in its own currency.
  final String Function(Money) money;

  /// A whole number in the locale's numerals. `grouped: false` for a year.
  final String Function(int, {required bool grouped}) number;
}

/// The share port, overridden in tests.
///
/// A temp directory, never a place the app chooses to keep: §12's file is
/// written, offered, and forgotten. On Android the manifest's FileProvider
/// exposes `cache/` and nothing else, which is why the app asks for no storage
/// permission at all.
final Provider<ShareService> shareServiceProvider = Provider<ShareService>(
  (ref) => PlatformShareService(directory: getTemporaryDirectory),
);

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
