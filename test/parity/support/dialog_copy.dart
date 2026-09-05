/// The strings the three dialog references draw.
///
/// Hand-transcribed from `design/calm/screens.html`'s `data-en` / `data-fa`
/// attributes rather than pulled from the ARB files, and deliberately so: a
/// capture must reproduce the REFERENCE, and a string that has since been
/// reworded in the ARB would silently change the band profile.
///
/// **Test-only. Never shipped** — `test/policy/structure_test.dart` asserts
/// nothing under `lib/` imports this file.
///
/// This file used to hold two more things: `HomeBackdrop` and
/// `VehiclesBackdrop`, hand-built compositions standing in for the screens the
/// dialogs were shot over, because in EPIC-08 neither screen existed. EPIC-09
/// built `vehicles` and EPIC-10 built `home`, so the captures use the real
/// screens now (`home_backdrop.dart`, `vehicles_backdrop.dart`) and the
/// stand-ins are gone. What they were worth is recorded in EPIC-10's progress
/// file under F-8.2 — both were lying, the `vehicles` one by a whole tab bar.
library;

import 'package:flutter/widgets.dart';
import 'package:odova/core/time/civil_date.dart';

/// The strings a dialog reference draws, per direction.
class ParityCopy {
  /// Creates the transcription for a direction.
  const ParityCopy({required this.rtl});

  /// Reads the direction from the capture.
  ///
  /// One authority for all three overlays: they name the same car, and two
  /// transcriptions would let them disagree without anything failing.
  factory ParityCopy.of(BuildContext context) =>
      ParityCopy(rtl: Directionality.of(context) == TextDirection.rtl);

  /// Whether the capture is right-to-left.
  final bool rtl;

  String _t(String latin, String persian) => rtl ? persian : latin;

  /// A number, in the artboard's numerals.
  ///
  /// A lookup rather than a formatter: these are the exact figures the pictures
  /// carry, and EPIC-04's formatters have their own tests.
  String number(int n) =>
      rtl ? '$n'.split('').map((d) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(d)]).join() : '$n';

  /// A snooze date, exactly as the artboard writes it.
  String artboardDate(CivilDate date) => switch ((date.month, date.day)) {
    (9, 6) => _t('6 Sep', '۱۵ شهریور'),
    (9, 10) => _t('10 Sep', '۱۹ شهریور'),
    (10, 3) => _t('3 Oct', '۱۱ مهر'),
    _ => _t('${date.day}/${date.month}', '${date.day}/${date.month}'),
  };

  /// A distance, exactly as the artboard writes it.
  String artboardDistance(int metres) => switch (metres) {
    500000 => _t('500 km', '۵۰۰ کیلومتر'),
    187912000 => _t('187,912 km', '۱۸۷٬۹۱۲ کیلومتر'),
    _ => _t('${metres ~/ 1000} km', '${metres ~/ 1000} کیلومتر'),
  };

  /// The discard dialog's summary half.
  String get discardSummary => _t(
    'a 15,000 km interval and a new baseline',
    'بازه ۱۵٬۰۰۰ کیلومتری و مبنای جدید',
  );

  /// The confirm-delete dialog's safe alternative.
  String get keepItMarkSold => _t(
    'Keep it — mark it sold',
    'نگهش دار — فروخته‌شده علامت بزن',
  );

  /// The vehicle all three dialogs are about.
  String get vehicle => _t('The Golf', 'گلف');

  /// The item the snooze and discard dialogs name.
  String get oil => _t('Oil and filter', 'روغن و فیلتر');
}
