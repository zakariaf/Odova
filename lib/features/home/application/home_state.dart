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
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/features/home/domain/home_view_model.dart';

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
    this.estimate,
    this.lastFillUp,
    this.consumption,
    this.otherVehicleNeedingAttention,
  });

  /// The active vehicle. Its name is the app-bar title.
  final Vehicle vehicle;

  /// The due stack, already ordered and capped.
  final HomeStack stack;

  /// Whether the title is a control at all.
  ///
  /// §9: "Chevron and tap target only when ≥ 2 vehicles exist; otherwise plain
  /// text — the garage is invisible until it is real."
  final bool showsSwitcher;

  /// The current odometer, however Odova knows it. Null before any reading.
  final OdometerEstimate? estimate;

  /// The most recent fill-up, for the 56pt row under the tiles.
  final FillUp? lastFillUp;

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
