// SPEC.md §12's toggles, as state.
//
// The rule the tests below exist for: "the preview IS the document, and the
// toggles change it live." So the notifier REBUILDS the document on every
// toggle rather than patching what it holds. A patched preview and a freshly
// built PDF are two renderings that agree until the day they do not — and the
// day they do not is the day somebody hands a buyer a file that does not match
// what they checked on screen.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/report/service_report.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/features/report/application/report_notifier.dart';

import '../../../support/report_fake_repository.dart';

final CivilDate _today = CivilDate.tryParse('2026-09-02')!;

ProviderContainer _container({int services = 3}) {
  final container = ProviderContainer(
    overrides: [
      reportRepositoryProvider.overrideWithValue(
        FakeReportRepository(serviceCount: services),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<ReportNotifier> _loaded(
  ProviderContainer container, {
  int services = 3,
}) async {
  final notifier = container.read(reportProvider.notifier)
    ..ensureLoaded('veh_1', today: _today);
  await Future<void>.delayed(Duration.zero);
  return notifier;
}

void main() {
  test(
    "the defaults are §12's: costs and fuel on, identity and notes off",
    () {
      final state = _container().read(reportProvider);

      expect(state.options.costs, isTrue);
      expect(state.options.fuelSummary, isTrue);
      expect(state.options.plateAndVin, isFalse);
      expect(state.options.notes, isFalse);
    },
  );

  test('there is no document until the read lands', () {
    // A document built from nothing would render a header for a vehicle whose
    // name has not arrived, then replace it — a flash of the wrong car.
    expect(_container().read(reportProvider).document, isNull);
  });

  test('loading builds the document once', () async {
    final container = _container();
    await _loaded(container);

    expect(container.read(reportProvider).document, isNotNull);
    expect(container.read(reportProvider).canShare, isTrue);
  });

  test('ensureLoaded is idempotent', () async {
    // It is called from `build`, which runs on every rebuild — a screen that
    // re-reads the whole vehicle on each frame would be unusable at 400
    // services.
    final container = _container();
    final notifier = await _loaded(container);
    final first = container.read(reportProvider).document;

    notifier
      ..ensureLoaded('veh_1', today: _today)
      ..ensureLoaded('veh_1', today: _today);
    await Future<void>.delayed(Duration.zero);

    expect(identical(container.read(reportProvider).document, first), isTrue);
  });

  test('a toggle rebuilds the document SYNCHRONOUSLY', () async {
    // Not on the next microtask. §12's "live" means the preview and the state
    // never disagree within a frame — anything else is a preview that is
    // briefly lying about what the file will contain.
    final container = _container();
    final notifier = await _loaded(container);

    expect(container.read(reportProvider).document!.summary, isNotNull);

    notifier.setOptions(
      const ServiceReportOptions(costs: false),
      today: _today,
    );

    expect(
      container.read(reportProvider).document!.summary,
      isNull,
      reason: 'no await between the toggle and the new document',
    );
  });

  test('a toggle before the read lands does not invent a document', () {
    final container = _container();
    container
        .read(reportProvider.notifier)
        .setOptions(
          const ServiceReportOptions(plateAndVin: true),
          today: _today,
        );

    final state = container.read(reportProvider);
    expect(state.options.plateAndVin, isTrue, reason: 'the toggle is kept');
    expect(state.document, isNull, reason: 'and nothing is fabricated');
  });

  test(
    'canShare is false with no services, whatever the toggles say',
    () async {
      // §12 disables Share PDF for an empty history. A report of no services is
      // a header and a footer, and the app does not produce one.
      final container = _container(services: 0);
      final notifier = await _loaded(container, services: 0);

      expect(container.read(reportProvider).canShare, isFalse);

      notifier.setOptions(
        const ServiceReportOptions(plateAndVin: true, notes: true),
        today: _today,
      );

      expect(container.read(reportProvider).canShare, isFalse);
    },
  );
}
