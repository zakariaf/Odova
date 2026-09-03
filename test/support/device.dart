import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A test surface described in LOGICAL size + DPR.
///
/// `view.physicalSize` is in PHYSICAL pixels, so it must be multiplied by the
/// DPR: `Size(320, 640)` at the default test DPR of 3.0 is a 107x213 logical
/// surface, which is not a phone and will overflow everything.
///
/// Presets are named by their measured size, not by a marketing model — a
/// golden called `iphone_se` stops being true the year the model changes.
class Device {
  /// Creates a surface preset.
  const Device(this.name, this.logicalSize, this.dpr);

  /// Used in test names and golden filenames.
  final String name;

  /// The logical size the app lays out against.
  final Size logicalSize;

  /// The device pixel ratio.
  final double dpr;

  /// 320x640 — the tightest surface Odova supports, and where German at 200%
  /// text scale breaks first.
  static const compact = Device('compact_320', Size(320, 640), 2);

  /// 360x800 — the commonest Android width.
  static const small = Device('small_360', Size(360, 800), 3);

  /// 412x915 — a current flagship.
  static const medium = Device('medium_412', Size(412, 915), 2.625);

  /// A tall surface for a SPECIMEN sheet, which stacks every state of one
  /// widget in a column and is not a phone.
  ///
  /// The sheets scroll, and a `SingleChildScrollView` lays its child out
  /// unbounded — so `getSize` and `didExceedMaxLines` see every state whether
  /// or not it is on screen, and the viewport height only decides what a
  /// golden frames.
  ///
  /// Here rather than as three hand-rolled `view.physicalSize` assignments in
  /// three matrix files, each with its own height and its own chance to forget
  /// `addTearDown(view.reset)` — which the doc on [CalmDeviceHarness.useDevice]
  /// warns poisons every later test in the file.
  static const specimenSheet = Device('specimen_430', Size(430, 1400), 3);

  /// The matrix iterates this list. [specimenSheet] is deliberately NOT in it:
  /// it is a sheet, not a device.
  static const all = <Device>[compact, small, medium];

  @override
  String toString() => name;
}

/// Surface pinning for widget tests.
extension CalmDeviceHarness on WidgetTester {
  /// Pins the surface. Call BEFORE `pumpApp`, always as a pair — a leaked view
  /// size poisons every later test in the file.
  void useDevice(Device device) {
    view.devicePixelRatio = device.dpr;
    view.physicalSize = device.logicalSize * device.dpr;
    // One call, not resetPhysicalSize + resetDevicePixelRatio.
    addTearDown(view.reset);
  }
}
