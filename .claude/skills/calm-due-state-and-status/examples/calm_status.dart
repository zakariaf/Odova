// lib/theme/calm/calm_status.dart
//
// The ONE place a DueState becomes a colour, a silhouette, a word and an action.
// Nothing else in the app may switch on DueState to pick any of those four —
// scripts/check_status_encoding.sh enforces it.
//
// Colour slots (CalmColors) are owned by `calm-tokens`; this file only resolves
// them. The mark geometry below is normative in odova.css §12 but has no entry in
// tokens.json, so it is declared here — inside lib/theme/**, the one directory
// `design-system-structure` allows a literal.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:odova/theme/calm/calm_colors.dart';

/// The product's due states. Exactly six, exactly these (SPEC §3).
///
/// `paused` is NOT here: it is `ServiceItem.is_active == false`, filtered before
/// the engine runs, so it has no card to style. `snoozed` is not here either —
/// a snoozed item keeps its real state and gains a fourth line.
enum DueState { overdue, due, dueSoon, ok, unknown, needsOdometer }

/// Which axis produced the worst status. Selects the copy pattern, never colour.
enum DueDriver { distance, time, both, none }

/// How much the projection engine actually knows. `default` is a Dart keyword,
/// hence `defaulted`; do not alias it anywhere else.
enum DueConfidence { measured, assumed, defaulted }

/// Signal 1 — geometry. Values are odova.css §12, which is normative:
/// `.statusdot` 12px, `.statusdot--sm`/`--due-soon` 8px, `--due` a 3px inset
/// ring, `--unknown`/`--needs-odometer` a 2px inset ring, `--unknown` at 0.7.
@immutable
class CalmStatusMark {
  const CalmStatusMark({
    required this.diameter,
    required this.strokeWidth,
    required this.opacity,
  });

  /// Outer diameter in logical pixels.
  final double diameter;

  /// 0 means a filled disc; anything else is an inset ring of that thickness.
  final double strokeWidth;

  /// Applied to `base` when painting. Only `unknown` is below 1.
  final double opacity;

  bool get isFilled => strokeWidth == 0;

  static const CalmStatusMark filledLarge =
      CalmStatusMark(diameter: 12, strokeWidth: 0, opacity: 1);
  static const CalmStatusMark filledSmall =
      CalmStatusMark(diameter: 8, strokeWidth: 0, opacity: 1);
  static const CalmStatusMark ringHeavy =
      CalmStatusMark(diameter: 12, strokeWidth: 3, opacity: 1);
  static const CalmStatusMark ringLight =
      CalmStatusMark(diameter: 12, strokeWidth: 2, opacity: 1);
  static const CalmStatusMark ringLightFaded =
      CalmStatusMark(diameter: 12, strokeWidth: 2, opacity: 0.7);

  @override
  bool operator ==(Object other) =>
      other is CalmStatusMark &&
      other.diameter == diameter &&
      other.strokeWidth == strokeWidth &&
      other.opacity == opacity;

  @override
  int get hashCode => Object.hash(diameter, strokeWidth, opacity);

  @override
  String toString() =>
      'CalmStatusMark(${diameter}px, stroke $strokeWidth, opacity $opacity)';
}

/// Signal 2 — the word. The app's generated `AppLocalizations` implements this,
/// so every label is one ICU message and no widget concatenates a status string.
/// Kept as an interface (not a Map<DueState, String>) so a missing translation
/// is a compile error rather than a null at a fuel pump.
abstract interface class CalmStatusStrings {
  String get statusOverdue;
  String get statusDue;
  String get statusDueSoon;
  String get statusOk;
  String get statusUnknown;
  String get statusNeedsOdometer;
}

/// A state resolved against the current theme: four colours plus a silhouette.
/// Built once per card by [of]; hold it, do not re-resolve per line.
@immutable
class CalmStatusStyle {
  const CalmStatusStyle({
    required this.state,
    required this.base,
    required this.ink,
    required this.tint,
    required this.edge,
    required this.mark,
  });

  final DueState state;

  /// Paints the mark and the progress fill. >= 3:1 on its ground (non-text).
  final Color base;

  /// The only slot text uses. >= 4.5:1 on both [tint] and the card surface.
  final Color ink;

  /// Badge ground and the primary card's gradient top stop.
  final Color tint;

  /// Hairline separator ONLY — 1.23–1.34:1 on [tint]. It cannot signify.
  final Color edge;

  final CalmStatusMark mark;

  /// The two states that mean "we do not know". Neither may carry a figure and
  /// neither may borrow the ok or overdue palette (SPEC §1).
  bool get isUncertain =>
      state == DueState.unknown || state == DueState.needsOdometer;

  /// `ok` is rendered as CalmAllClear instead of a card; see calm-layout-and-motion.
  bool get showsOnHome => state != DueState.ok;

  /// Signal 4. `unknown` and `needsOdometer` ask for a reading; nothing else does.
  String get actionKey => switch (state) {
        DueState.unknown || DueState.needsOdometer => 'action.updateOdometer',
        DueState.overdue ||
        DueState.due ||
        DueState.dueSoon ||
        DueState.ok =>
          'action.logIt',
      };

  String label(CalmStatusStrings s) => switch (state) {
        DueState.overdue => s.statusOverdue,
        DueState.due => s.statusDue,
        DueState.dueSoon => s.statusDueSoon,
        DueState.ok => s.statusOk,
        DueState.unknown => s.statusUnknown,
        DueState.needsOdometer => s.statusNeedsOdometer,
      };

  /// The public entry point. Anything holding a [BuildContext] calls this.
  static CalmStatusStyle of(BuildContext context, DueState state) =>
      resolve(CalmColors.of(context), state);

  /// The single switch. Exhaustive, so a seventh state is a compile error here
  /// and nowhere else. Kept public for tests and for callers that already hold
  /// the extension; everything with a context uses [of].
  static CalmStatusStyle resolve(CalmColors c, DueState state) =>
      switch (state) {
        DueState.overdue => CalmStatusStyle(
            state: state,
            base: c.overdue.base,
            ink: c.overdue.ink,
            tint: c.overdue.tint,
            edge: c.overdue.edge,
            mark: CalmStatusMark.filledLarge,
          ),
        DueState.due => CalmStatusStyle(
            state: state,
            base: c.due.base,
            ink: c.due.ink,
            tint: c.due.tint,
            edge: c.due.edge,
            mark: CalmStatusMark.ringHeavy,
          ),
        DueState.dueSoon => CalmStatusStyle(
            state: state,
            base: c.dueSoon.base,
            ink: c.dueSoon.ink,
            tint: c.dueSoon.tint,
            edge: c.dueSoon.edge,
            mark: CalmStatusMark.filledSmall,
          ),
        DueState.ok => CalmStatusStyle(
            state: state,
            base: c.ok.base,
            ink: c.ok.ink,
            tint: c.ok.tint,
            edge: c.ok.edge,
            mark: CalmStatusMark.filledLarge,
          ),
        DueState.unknown => CalmStatusStyle(
            state: state,
            base: c.unknown.base,
            ink: c.unknown.ink,
            tint: c.unknown.tint,
            edge: c.unknown.edge,
            mark: CalmStatusMark.ringLightFaded,
          ),
        DueState.needsOdometer => CalmStatusStyle(
            state: state,
            base: c.needsOdometer.base,
            ink: c.needsOdometer.ink,
            tint: c.needsOdometer.tint,
            edge: c.needsOdometer.edge,
            mark: CalmStatusMark.ringLight,
          ),
      };
}

/// Whether a figure (a distance, a projected date) may appear at all.
/// At `defaulted` the surface reads `home.dueSoonNoConfidence` and nothing else —
/// no date, no distance, in the app or in a notification (SPEC §1.4).
bool mayShowFigure(DueState state, DueConfidence confidence) =>
    confidence != DueConfidence.defaulted &&
    state != DueState.unknown &&
    state != DueState.needsOdometer;
