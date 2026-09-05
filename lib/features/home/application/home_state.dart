// What Home draws, as one immutable value.
//
// SPEC.md §9's anatomy in the order it renders: the vehicle's name, the
// odometer strip, the due stack, the see-all row, three glance tiles, the last
// fill-up, and the other-vehicles row. Everything here is DERIVED at read time
// — §2 forbids persisting a due date, a status or a monthly total, and this
// class is what "computed on the way to the screen" looks like.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/features/home/domain/home_strips.dart';
import 'package:odova/features/home/domain/home_view_model.dart';

/// The all-clear card's contents, as facts rather than sentences.
///
/// SPEC.md §9's *Nothing due*: the mark, the headline, "the next item with its
/// date, plus a since-last-service line (distance and time since the most
/// recent `ServiceRecord`, whatever it was)". Everything here is raw; the
/// formatting is `home_states.dart`'s, because a locale is a presentation
/// input and this is not the presentation layer.
typedef HomeAllClear = ({
  /// The soonest item, whatever its state. Null when nothing is tracked.
  AssessedItem? next,

  /// The most recent service record, for the receipt line.
  ServiceRecord? lastService,

  /// Metres since that record, or null when either odometer is unknown.
  int? sinceMetres,

  /// Days since it, or null when the date will not parse.
  int? sinceDays,
});

/// Another vehicle with work on it, and how much.
///
/// A record rather than a bare `Vehicle`: §9's row reads `Van · 1 overdue`, so
/// the count and the WORD are both part of the answer, and recovering them at
/// the widget would mean the widget reading a second vehicle's snapshot.
typedef OtherVehicleAttention = ({Vehicle vehicle, int count, bool overdue});

/// Everything one build of Home needs.
@immutable
class HomeState {
  /// Creates the state.
  const HomeState({
    required this.vehicle,
    required this.stack,
    required this.showsSwitcher,
    this.strips = const [],
    this.storeUnreadable = false,
    this.allClear,
    this.estimate,
    this.rate,
    this.lastFillUp,
    this.consumption,
    this.otherVehicleNeedingAttention,
  });

  /// The active vehicle. Its name is the app-bar title.
  final Vehicle vehicle;

  /// The due stack, already ordered and capped.
  final HomeStack stack;

  /// The conditional strips to draw, already ordered and capped at two.
  ///
  /// §9: "A conditional strip pushes the tiles below the fold, never the cards
  /// — strips are capped at two, and the primary card is never displaced." The
  /// cap is applied in `home_strips.dart`; carrying the RESULT here is what
  /// keeps the screen from re-deciding it.
  final List<HomeStripKind> strips;

  /// Whether the title is a control at all.
  ///
  /// §9: "Chevron and tap target only when ≥ 2 vehicles exist; otherwise plain
  /// text — the garage is invisible until it is real."
  final bool showsSwitcher;

  /// The current odometer, however Odova knows it. Null before any reading.
  final OdometerEstimate? estimate;

  /// The vehicle's daily distance, for §9's "Estimated from about {rate} a
  /// day" popover. Null when the engine could not answer.
  final DailyDistance? rate;

  /// The most recent fill-up, for the 56pt row under the tiles.
  final FillUp? lastFillUp;

  /// Whether the store could not be read at all.
  ///
  /// §9's *Error*: "If the store cannot be read, Home renders no cards and one
  /// full-width message." It is a different fact from "the engine found
  /// nothing", which is the all-clear, and from "the engine has not answered
  /// yet", which is the skeleton — and drawing any of the three for another is
  /// the failure this flag exists to prevent.
  final bool storeUnreadable;

  /// The all-clear's facts, when nothing is due.
  ///
  /// Null whenever a card is drawn. §9 makes the two states exclusive: the
  /// all-clear replaces the stack, it does not sit under it.
  final HomeAllClear? allClear;

  /// The vehicle's lifetime average consumption, or null when there is none.
  ///
  /// **Always null in EPIC-10.** The tile ROW is built and the `—` explains
  /// itself; what is deferred is the composition from fill-ups, readings and
  /// corrections into `FillUpPoint`s, which belongs with `costPerDistance` and
  /// `monthlyCost` in EPIC-13 — one place that turns rows into running-cost
  /// figures, rather than this screen growing a second one.
  final Consumption? consumption;

  /// Another vehicle with a `due` or `overdue` item, if any.
  ///
  /// §9: one line, "only when another vehicle has a due or overdue item", and
  /// it opens the switcher. "Home shows *whose* problem it is, not *what* it
  /// is" — naming the item would make the row a second due card for a car the
  /// user is not looking at.
  final OtherVehicleAttention? otherVehicleNeedingAttention;
}
