// `firstrun.vehicle` — the screen half of first run's second step.
//
// The number lives in `first_run_vehicle_notifier_test.dart`. This file is
// about the pixels and the gestures: what is disabled, what a tap on it does,
// what the tile renames, and what the back edge means here as against on
// `firstrun.language`.
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/file_picker.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/features/first_run/first_run_vehicle_notifier.dart';
import 'package:odova/features/first_run/presentation/first_run_vehicle_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_chip.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_segmented.dart';

import '../../../parity/support/parity_capture.dart'
    show kReferenceDpr, kReferencePhysical;
import '../../../support/pump_app.dart';

/// A picker that records what was asked of it, and always cancels.
class _FakePicker {
  int calls = 0;

  Future<PickedFile?> call() async {
    calls++;
    return null;
  }
}

List<Override> _device(String tag, {_FakePicker? picker}) {
  final parts = tag.split('-');
  return [
    deviceLocalesProvider.overrideWithValue([
      Locale(parts.first, parts.length > 1 ? parts[1] : null),
    ]),
    clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026, 9, 4))),
    if (picker != null) filePickerProvider.overrideWithValue(picker.call),
  ];
}

/// Pumps at the size the design was drawn at — see the language screen's test.
Future<void> _pump(
  WidgetTester tester, {
  List<Override> overrides = const [],
  Locale? locale,
  Key? key,
}) async {
  tester.view.physicalSize = kReferencePhysical;
  tester.view.devicePixelRatio = kReferenceDpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await pumpApp(
    tester,
    FirstRunVehicleScreen(key: key),
    overrides: overrides.isEmpty ? _device('de-DE') : overrides,
    locale: locale,
  );
}

BuildContext _ctx(WidgetTester tester) =>
    tester.element(find.byType(FirstRunVehicleScreen));

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(_ctx(tester));

/// Start — found by SIZE, not by position.
///
/// It is the screen's one `lg` button. `find.byType(CalmButton).first` was
/// wrong the moment the implausible warning put a quiet button above it in the
/// body, and it failed by testing the wrong button rather than by not finding
/// one.
CalmButton _start(WidgetTester tester) => tester
    .widgetList<CalmButton>(find.byType(CalmButton))
    .firstWhere((b) => b.size == CalmButtonSize.lg);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(CalmField).last, text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Start is visibly disabled until the odometer parses', (
    tester,
  ) async {
    // SPEC.md §8's deliberate exception to "Save is never disabled", scoped to
    // one required field with an always-visible hint. The hint is what stands
    // in for the explanation a disabled button would otherwise owe.
    await _pump(tester);
    expect(_start(tester).onPressed, isNull);
    expect(
      _start(tester).disabledBecause,
      isNotNull,
      reason: 'a disabled Start must name what explains it',
    );
    expect(find.text(_l10n(tester).odometerFirstRunHint), findsOneWidget);

    await _type(tester, '187412');
    expect(_start(tester).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a disabled Start surfaces the error, and writes '
      'nothing', (tester) async {
    // A disabled CalmPressable is wrapped in an IgnorePointer, so the button
    // cannot hear its own tap; the listener is outside it. Without that, SPEC's
    // "tapping it flashes the odometer hint" is unbuildable and the user taps a
    // dead rectangle.
    await _pump(tester);
    final l10n = _l10n(tester);

    // Nothing yet: the field has not been typed in and has not been asked for.
    expect(find.text(l10n.odometerEmptyError), findsNothing);

    await tester.tap(find.byWidget(_start(tester)));
    await tester.pumpAndSettle();

    // SPEC.md §8's "Empty on Save" message, which is what "flashes the
    // odometer hint" amounts to on a field that is empty. Without the listener
    // outside the button this assertion is unreachable: a disabled
    // CalmPressable is wrapped in an IgnorePointer and hears nothing.
    expect(find.text(l10n.odometerEmptyError), findsOneWidget);

    final container = ProviderScope.containerOf(_ctx(tester));
    expect(container.read(firstRunVehicleProvider).saving, isFalse);
    expect(_start(tester).onPressed, isNull);
    expect(tester.takeException(), isNull);

    // And typing clears the refusal itself, not merely the condition. Emptying
    // the field again must NOT bring the message back: the user has been told
    // once and is now mid-edit, and a message that reappears as they delete
    // their last character is nagging rather than helping.
    await _type(tester, '1000');
    expect(find.text(l10n.odometerEmptyError), findsNothing);
    await _type(tester, '');
    expect(find.text(l10n.odometerEmptyError), findsNothing);

    // Pressing Start again on the now-empty field asks again, and is answered.
    await tester.tap(find.byWidget(_start(tester)));
    await tester.pumpAndSettle();
    expect(find.text(l10n.odometerEmptyError), findsOneWidget);
  });

  testWidgets('the type tile renames the field until the user types', (
    tester,
  ) async {
    // SPEC.md §8: the name is prefilled "My car" / "My motorbike" / "My van",
    // "following the type tile". And it stops following the moment somebody
    // types, or a user who names it "Dad's Volvo" and then corrects the tile
    // loses the name.
    await _pump(tester);
    final l10n = _l10n(tester);
    expect(find.text(l10n.vehicleNameDefaultCar), findsOneWidget);

    await tester.tap(find.text(l10n.vehicleTypeVan));
    await tester.pumpAndSettle();
    expect(find.text(l10n.vehicleNameDefaultVan), findsOneWidget);

    await tester.enterText(find.byType(CalmField).first, 'Dad’s Volvo');
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.vehicleTypeMotorcycle));
    await tester.pumpAndSettle();
    expect(find.text('Dad’s Volvo'), findsOneWidget);
    expect(find.text(l10n.vehicleNameDefaultMotorcycle), findsNothing);
  });

  testWidgets(
    'the name prefill is pre-selected, so one keystroke replaces it',
    (
      tester,
    ) async {
      await _pump(tester);
      final field = tester.widget<CalmField>(find.byType(CalmField).first);
      final controller = field.controller;
      expect(controller.selection.baseOffset, 0);
      expect(controller.selection.extentOffset, controller.text.length);
      expect(controller.text, _l10n(tester).vehicleNameDefaultCar);
    },
  );

  testWidgets('focus is not auto-placed in the odometer field', (tester) async {
    // SPEC.md §8 is explicit: a keyboard over two thirds of the screen reads as
    // a form to fill, not a question to answer.
    await _pump(tester);
    for (final field in tester.widgetList<CalmField>(find.byType(CalmField))) {
      expect(field.focusNode?.hasFocus ?? false, isFalse);
    }
    expect(
      FocusManager.instance.primaryFocus?.hasPrimaryFocus ?? false,
      isTrue,
    );
    expect(
      tester.testTextInput.isVisible,
      isFalse,
      reason: 'no keyboard on arrival',
    );
  });

  testWidgets('an implausible reading warns and offers Use it anyway', (
    tester,
  ) async {
    await _pump(tester);
    await _type(tester, '3000001');
    final l10n = _l10n(tester);

    expect(find.text(l10n.odometerImplausibleWarning), findsOneWidget);
    expect(find.text(l10n.commonUseItAnyway), findsOneWidget);
    expect(_start(tester).onPressed, isNull);

    await tester.tap(find.text(l10n.commonUseItAnyway));
    await tester.pumpAndSettle();

    // A warning, never a block: the number is accepted exactly as typed.
    expect(find.text(l10n.odometerImplausibleWarning), findsNothing);
    expect(_start(tester).onPressed, isNotNull);
  });

  testWidgets('an unparseable reading says Digits only, and an empty one '
      'says nothing yet', (tester) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    // Nothing typed: no error. A form that scolds you before you have typed is
    // a form that is angry at you for arriving.
    expect(find.text(l10n.odometerNotANumberError), findsNothing);

    await _type(tester, 'abc');
    expect(find.text(l10n.odometerNotANumberError), findsOneWidget);
  });

  testWidgets('there is no Cancel, no back, and system back is swallowed', (
    tester,
  ) async {
    // The OPPOSITE of `firstrun.language`, which exits the app. Dismissing this
    // one lands in an app with no data.
    await _pump(tester);
    expect(find.byType(BackButton), findsNothing);
    for (final label in ['Cancel', 'Abbrechen', 'Skip', 'Überspringen']) {
      expect(find.text(label), findsNothing, reason: label);
    }

    final guard =
        tester
                .widgetList(
                  find.descendant(
                    of: find.byType(FirstRunVehicleScreen),
                    matching: find.byWidgetPredicate((w) => w is PopScope),
                  ),
                )
                .first
            as PopScope<Object?>;
    expect(guard.canPop, isFalse);

    // And it does NOT ask the OS to leave, which is what the language screen
    // does with the same gesture.
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    guard.onPopInvokedWithResult?.call(false, null);
    await tester.pump();
    expect(calls.map((c) => c.method), isNot(contains('SystemNavigator.pop')));
  });

  testWidgets('the backup link opens the picker and writes nothing on cancel', (
    tester,
  ) async {
    final picker = _FakePicker();
    await _pump(tester, overrides: _device('de-DE', picker: picker));

    await tester.tap(find.text(_l10n(tester).firstRunHaveBackup));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(find.byType(FirstRunVehicleScreen), findsOneWidget);
    final container = ProviderScope.containerOf(_ctx(tester));
    expect(container.read(firstRunVehicleProvider).odometerText, isEmpty);
  });

  testWidgets('the band chips carry no unit and the label carries it', (
    tester,
  ) async {
    // EPIC-09 F-9.12: the unit moved off the chips and into the label, which is
    // what makes a `maxChars` budget unnecessary in German.
    await _pump(tester);
    final l10n = _l10n(tester);
    expect(find.text(l10n.annualBandLabelKm), findsOneWidget);

    final bands = tester
        .widgetList<CalmSegmentedOption>(find.byType(CalmSegmentedOption))
        // The first three are the vehicle-type tiles.
        .skip(3)
        .map((o) => o.label)
        .toList();
    expect(bands, hasLength(4));
    for (final label in bands) {
      expect(label, isNot(contains('km')), reason: label);
      expect(label, isNot(contains('Meilen')), reason: label);
      expect(label.split(' ').length, lessThanOrEqualTo(2), reason: label);
    }
  });

  testWidgets('a miles device labels the bands in miles', (tester) async {
    // The bands are defined per unit system and are not converted, so an
    // American device offers `under 6` and not `under 10` with a converted
    // number behind it.
    await _pump(
      tester,
      overrides: _device('en-US'),
      locale: const Locale('en'),
    );
    expect(find.text(_l10n(tester).annualBandLabelMi), findsOneWidget);
    expect(find.text('under 6'), findsOneWidget);
    expect(find.text('over 18'), findsOneWidget);
  });

  testWidgets('the fuel More… chip opens a sheet of the other four', (
    tester,
  ) async {
    // EPIC-09 F-9.13: a sheet, because four values picked one at a time with
    // nothing to type is what every other pick-one list in the app uses a
    // sheet for.
    await _pump(tester);
    final l10n = _l10n(tester);

    // Scrolled to, not merely tapped. `.chipbar` is `overflow: hidden` in the
    // stylesheet and `CalmChipBar` is a horizontal scroll view, and in German
    // — Benzin / Diesel / Elektro / Mehr… — the fourth chip is past the right
    // edge of a 390pt phone at text scale 1. The reference is English and fits,
    // so this is a case the parity capture cannot see.
    await tester.scrollUntilVisible(
      find.text(l10n.commonMore),
      120,
      scrollable: find.descendant(
        of: find.byType(CalmChipBar),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text(l10n.commonMore));
    await tester.pumpAndSettle();

    for (final label in [
      l10n.fuelLpg,
      l10n.fuelCng,
      l10n.fuelHybrid,
      l10n.fuelOther,
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }

    await tester.tap(find.text(l10n.fuelHybrid));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(_ctx(tester));
    expect(container.read(firstRunVehicleProvider).fuel, FuelKind.hybrid);
  });

  testWidgets('a rebuild keeps the form and writes no draft row', (
    tester,
  ) async {
    // SPEC.md §8: "Backgrounded mid-entry — form state survives in memory;
    // nothing is written. A cold kill loses it and replays this screen — six
    // digits is an acceptable loss, a draft row for a vehicle that does not
    // exist is not."
    // The "writes no draft row" half is asserted in
    // `first_run_vehicle_notifier_test.dart`, from a plain `test`. A drift
    // future never completes under `testWidgets` — the widget binding's fake
    // async does not run its timers — and the symptom is a ten-minute hang with
    // no output rather than a failure. `provider_harness.dart` says so; this
    // test learned it the expensive way.
    await _pump(tester);
    await tester.enterText(find.byType(CalmField).first, 'The Golf');
    await _type(tester, '187412');

    // A NEW KEY, not a new pump of nothing. Changing the key throws the State
    // away and builds a fresh one — which is what coming back from the
    // background does — while the `ProviderScope` above it is reused, so the
    // draft survives exactly as it would on a device. Unmounting the whole tree
    // instead destroys the container too, and then the test proves only that a
    // cold start is a cold start.
    await _pump(tester, key: const ValueKey('rebuilt'));
    await tester.pumpAndSettle();

    expect(find.text('The Golf'), findsOneWidget);
    expect(find.text('187412'), findsOneWidget);
  });
}
