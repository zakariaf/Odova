// The ONE place a DueState becomes a colour, a silhouette, a word and an
// action.
// Nothing else in the app may switch on DueState to pick any of those four —
// scripts/check_status_encoding.sh enforces it.
//
// Colour slots (CalmColors) are owned by `calm-tokens`; this file only resolves
// them. The mark geometry below is normative in odova.css §12 but has no entry
// in
// tokens.json, so it is declared here — inside lib/theme/**, the one directory
// `design-system-structure` allows a literal.
import 'package:flutter/widgets.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/theme/calm/calm_colors.dart';

// The three enums are pure Dart and live in lib/core/due/, because EPIC-07's
// due engine returns them and may not import Flutter. Re-exported so a widget
// that imports this file gets everything it needs from one place.
export 'package:odova/core/due/due_state.dart';

/// Signal 1 — geometry. Values are odova.css §12, which is normative:
/// `.statusdot` 12px, `.statusdot--sm`/`--due-soon` 8px, `--due` a 3px inset
/// ring, `--unknown`/`--needs-odometer` a 2px inset ring, `--unknown` at 0.7.
@immutable
class CalmStatusMark {
  /// Creates a mark from its measured geometry.
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

  /// Whether the mark is a filled disc rather than an inset ring.
  bool get isFilled => strokeWidth == 0;

  /// A 12px filled disc: `overdue` and `ok`.
  static const CalmStatusMark filledLarge = CalmStatusMark(
    diameter: 12,
    strokeWidth: 0,
    opacity: 1,
  );

  /// An 8px filled disc: `dueSoon`.
  static const CalmStatusMark filledSmall = CalmStatusMark(
    diameter: 8,
    strokeWidth: 0,
    opacity: 1,
  );

  /// A 12px ring with a 3px stroke: `due`.
  static const CalmStatusMark ringHeavy = CalmStatusMark(
    diameter: 12,
    strokeWidth: 3,
    opacity: 1,
  );

  /// A 12px ring with a 2px stroke: `needsOdometer`.
  static const CalmStatusMark ringLight = CalmStatusMark(
    diameter: 12,
    strokeWidth: 2,
    opacity: 1,
  );

  /// [ringLight] at 70% opacity: `unknown`, the faintest mark in the set.
  static const CalmStatusMark ringLightFaded = CalmStatusMark(
    diameter: 12,
    strokeWidth: 2,
    opacity: 0.7,
  );

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
/// so every label is one ICU message and no widget concatenates a status
/// string.
/// Kept as an interface rather than a map keyed on [DueState], so a missing
/// translation is a compile error rather than a null at a fuel pump.
abstract interface class CalmStatusStrings {
  /// The word for [DueState.overdue].
  String get statusOverdue;

  /// The word for [DueState.due].
  String get statusDue;

  /// The word for [DueState.dueSoon].
  String get statusDueSoon;

  /// The word for [DueState.ok].
  String get statusOk;

  /// The word for [DueState.unknown].
  String get statusUnknown;

  /// The word for [DueState.needsOdometer].
  String get statusNeedsOdometer;
}

/// A state resolved against the current theme: four colours plus a silhouette.
/// Built once per card by [of]; hold it, do not re-resolve per line.
@immutable
class CalmStatusStyle {
  /// Creates a resolved style. Use [of] or [resolve] rather than this.
  const CalmStatusStyle({
    required this.state,
    required this.ramp,
    required this.mark,
  });

  /// The state this style resolves.
  final DueState state;

  /// The four rungs of this state's family.
  ///
  /// Held whole rather than copied out. Four separate fields would let
  /// [resolve] pair `overdue.base` with `due.ink` and nothing would notice —
  /// a class of bug that cannot exist if the family arrives in one piece.
  final CalmRamp ramp;

  /// Signal 3: the graphic colour — the mark, the progress fill, the chart
  /// stroke. Held to 3:1 as a non-text graphic. Several bases are under 4.5:1
  /// and MUST NOT carry text.
  Color get base => ramp.base;

  /// The only slot text uses. At least 4.5:1 on both [tint] and the card
  /// surface, in both themes.
  Color get ink => ramp.ink;

  /// The badge ground, and the primary card's gradient top stop.
  Color get tint => ramp.tint;

  /// A hairline separator only — 1.23–1.34:1 on [tint]. It cannot signify.
  Color get edge => ramp.edge;

  /// Signal 1: the silhouette, which is what survives grayscale.
  final CalmStatusMark mark;

  /// The two states that mean "we do not know". Neither may carry a figure and
  /// neither may borrow the ok or overdue palette (SPEC §1).
  ///
  /// Through `isUncertainState` in `lib/core/due/`, because the due engine
  /// needs the same pair to resolve a severity tie between its two axes — and
  /// two spellings of "we do not know" is how one of them gains a third member.
  bool get isUncertain => isUncertainState(state);

  /// `ok` is rendered as CalmAllClear instead of a card; see
  /// calm-layout-and-motion.
  bool get showsOnHome => state != DueState.ok;

  /// Signal 4: the one action this card offers.
  ///
  /// Takes the [RateConfidence] because the state alone does not decide it.
  /// SPEC.md §9's estimate table: *"Date from the distance axis,
  /// `confidence = default` → **No date and no figure.** The card reads
  /// `Odova needs a reading to say when` and its action is **Update
  /// odometer**"*. A `dueSoon` item the engine is guessing at gets the same
  /// action as an `unknown` one, because "log it" is the one action that
  /// cannot resolve the state — the app does not know when it is due, and
  /// logging the job does not tell it.
  ///
  /// `calm-due-state-and-status`' own examples switch on the state alone;
  /// where a skill and the spec disagree, CLAUDE.md §3 says the spec is the
  /// product decision.
  String actionKey(RateConfidence confidence) =>
      isUncertain || confidence == RateConfidence.defaulted
      ? 'action.updateOdometer'
      : 'action.logIt';

  /// Signal 2: the word for this state, from the app's localizations.
  String label(CalmStatusStrings s) => switch (state) {
    DueState.overdue => s.statusOverdue,
    DueState.due => s.statusDue,
    DueState.dueSoon => s.statusDueSoon,
    DueState.ok => s.statusOk,
    DueState.unknown => s.statusUnknown,
    DueState.needsOdometer => s.statusNeedsOdometer,
  };

  /// The public entry point. Anything holding a [BuildContext] calls this.
  ///
  /// A named constructor would read as "make me a style", and the point of
  /// this API is that a caller does not get to choose the colours.
  /// `CalmStatusStyle.of(context, state)` says the state is resolved AGAINST
  /// the theme, which is the contract check_status_encoding.sh enforces — and
  /// it matches every other `of` in the Calm layer.
  static CalmStatusStyle of(BuildContext context, DueState state) =>
      resolve(CalmColors.of(context), state);

  /// The single switch. Exhaustive, so a seventh state is a compile error here
  /// and nowhere else. Kept public for tests and for callers that already hold
  /// the extension; everything with a context uses [of].
  ///
  /// A named constructor would read as "make me a style", and the point of the
  /// API is that a caller does not get to choose the colours — a resolved
  /// style is derived from the theme, never constructed.
  // ignore: prefer_constructors_over_static_methods
  static CalmStatusStyle resolve(CalmColors c, DueState state) {
    // One switch, one line per state, and the ramp travels whole. Exhaustive
    // over DueState with no `default:`, so a seventh state is a compile error
    // here and nowhere else.
    final (ramp, mark) = switch (state) {
      DueState.overdue => (c.overdue, CalmStatusMark.filledLarge),
      DueState.due => (c.due, CalmStatusMark.ringHeavy),
      DueState.dueSoon => (c.dueSoon, CalmStatusMark.filledSmall),
      DueState.ok => (c.ok, CalmStatusMark.filledLarge),
      // The two "we do not know" states. Neither may borrow ok's sage or
      // overdue's terracotta, and their marks are the faintest in the set —
      // an app that cannot say when must not look like one making an
      // accusation (SPEC.md §1).
      DueState.unknown => (c.unknown, CalmStatusMark.ringLightFaded),
      DueState.needsOdometer => (c.needsOdometer, CalmStatusMark.ringLight),
    };

    return CalmStatusStyle(state: state, ramp: ramp, mark: mark);
  }
}

/// Whether a figure (a distance, a projected date) may appear at all.
/// At `defaulted` the surface reads `home.dueSoonNoConfidence` and nothing
/// else —
/// no date, no distance, in the app or in a notification (SPEC §1.4).
bool mayShowFigure(DueState state, RateConfidence confidence) =>
    confidence != RateConfidence.defaulted &&
    state != DueState.unknown &&
    state != DueState.needsOdometer;
