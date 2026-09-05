// `firstrun.vehicle`'s draft, its one validation, and the transaction.
//
// SPEC.md §8: one vehicle and one odometer reading in the database in under
// thirty seconds, with one thing to type. Everything on this screen has a
// default except the odometer, and the odometer is the whole tax — six digits,
// read off a dash, possibly at a pump in the rain.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/l10n/format_defaults.dart';
import 'package:odova/core/odometer/odometer_entry.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/vehicles/annual_band.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';

/// Everything `firstrun.vehicle` collects, plus what is wrong with it.
@immutable
class FirstRunVehicleDraft {
  /// Creates a draft.
  const FirstRunVehicleDraft({
    required this.odometer,
    this.type = VehicleType.car,
    this.fuel = FuelKind.petrol,
    this.band = AnnualBand.defaultBand,
    this.name,
    this.saving = false,
    this.saveFailed = false,
    this.startRefused = false,
  });

  /// The one thing the user has to type, and what it means.
  ///
  /// The whole reading lives in `lib/core/`, shared with `vehicle.edit`'s
  /// create mode, which asks for the same number under SPEC.md §8. Two copies
  /// of the implausible rule is one copy that keeps the bug.
  final OdometerEntry odometer;

  /// Which of the three tiles. Decides the seeded set and the name prefill.
  final VehicleType type;

  /// What it burns.
  final FuelKind fuel;

  /// Roughly how far a year.
  final AnnualBand band;

  /// The name, once the user has edited it.
  ///
  /// Null means "still following the type tile", which is what lets tapping Van
  /// change `My car` to `My van` and lets one keystroke stop it forever.
  final String? name;

  /// A create is in flight.
  final bool saving;

  /// The last create failed. Only a disk write can fail here.
  final bool saveFailed;

  /// Start has been pressed while it was disabled.
  ///
  /// This is what makes SPEC.md §8's "tapping it flashes the odometer hint"
  /// mean something. Until it happens the field says nothing — a form that
  /// scolds you before you have typed is a form that is angry at you for
  /// arriving — and §8 puts its empty message under "Empty on Save", which is
  /// precisely this moment.
  final bool startRefused;

  /// What is wrong with the odometer, or null.
  OdometerProblem? get problem => odometer.problem;

  /// The reading in metres, or null when it does not parse.
  int? get odometerMetres => odometer.metres;

  /// The unit the odometer is typed in — SPEC.md §8's prefill.
  DistanceUnit get unit => odometer.unit;

  /// The name to save: what the user typed, or the tile's prefill.
  ///
  /// The prefill is an ARB key, so the draft cannot resolve it — it names WHICH
  /// prefill and the screen supplies the string. [name] being null is the
  /// signal, and the screen writes the resolved default in before saving.
  String get displayName => name ?? '';

  /// Whether Start may be pressed.
  ///
  /// The deliberate exception to "Save is never disabled", scoped by SPEC.md
  /// §8 to one required field with an always-visible hint — and scoped no
  /// further than that. It asks whether the field holds a READING, not whether
  /// the app likes it.
  ///
  /// So it is not `problem == null`, which is what it used to be. That spelling
  /// quietly promoted [OdometerProblem.implausible] into a block, and §8 says
  /// the opposite in as many words: "a warning with a 'Use it anyway'
  /// affordance, never a block". A truck that really has done three million
  /// kilometres could not be entered without first arguing with the app, and
  /// "never a block" is not "one extra tap".
  bool get canStart => odometer.usable;

  /// A copy with the given changes.
  FirstRunVehicleDraft copyWith({
    OdometerEntry? odometer,
    VehicleType? type,
    FuelKind? fuel,
    AnnualBand? band,
    String? name,
    bool? saving,
    bool? saveFailed,
    bool? startRefused,
  }) => FirstRunVehicleDraft(
    odometer: odometer ?? this.odometer,
    type: type ?? this.type,
    fuel: fuel ?? this.fuel,
    band: band ?? this.band,
    name: name ?? this.name,
    saving: saving ?? this.saving,
    saveFailed: saveFailed ?? this.saveFailed,
    startRefused: startRefused ?? this.startRefused,
  );
}

/// Holds the draft, and writes it once.
class FirstRunVehicleNotifier extends Notifier<FirstRunVehicleDraft> {
  @override
  FirstRunVehicleDraft build() {
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    return FirstRunVehicleDraft(
      // The unit the odometer is typed in comes from the DEVICE REGION, the
      // same source `firstrun.language`'s Continue seeded the settings from —
      // and it has to, because that write has not happened yet the first time
      // this screen is built after a fresh install.
      odometer: OdometerEntry(
        unit: formatDefaultsFor(tag).distance,
        groupingSeparator: groupingSeparatorFor(tag),
      ),
    );
  }

  /// Chooses a vehicle type.
  ///
  /// Two side effects SPEC.md §8 asks for and one it does not. The name prefill
  /// follows the tile, and a van turns `is_business` on — that one is a DATA
  /// rule that survived the switch being dropped from this screen (F-9.9).
  /// What does not happen is the name being overwritten once the user has
  /// typed: [FirstRunVehicleDraft.name] is null until they do, and after that
  /// the tile stops touching it.
  void chooseType(VehicleType type) => state = state.copyWith(type: type);

  /// Chooses a fuel kind, from the three chips or the More… sheet.
  void chooseFuel(FuelKind fuel) => state = state.copyWith(fuel: fuel);

  /// Chooses an annual band.
  void chooseBand(AnnualBand band) => state = state.copyWith(band: band);

  /// Records what the user typed into the odometer, exactly.
  void typeOdometer(String text) =>
      // A new number is a new question, so a warning accepted about the old one
      // does not carry: "Use it anyway" applied to 30,000,001 must not silently
      // apply to the 300,000,001 typed after it.
      state = state.copyWith(
        odometer: state.odometer.copyWith(text: text),
        // A new number is a new attempt: the refusal was about the old one.
        startRefused: false,
      );

  /// Renames the vehicle. The first call stops the type tile touching it.
  void rename(String name) => state = state.copyWith(name: name);

  /// Records that Start was pressed while it was disabled.
  void refuseStart() => state = state.copyWith(startRefused: true);

  /// Accepts the implausible-odometer warning.
  void useItAnyway() => state = state.copyWith(
    odometer: state.odometer.copyWith(warningAccepted: true),
  );

  /// Writes the vehicle, its first reading, its seeded items and the settings.
  ///
  /// One transaction, and `VehicleRepository.create` is where that promise
  /// lives: a crash between the vehicle row and the reading row would leave a
  /// vehicle the due engine can never project from, which the domain contract
  /// forbids.
  Future<bool> save() async {
    if (state.saving || !state.canStart) return false;
    state = state.copyWith(saving: true, saveFailed: false);

    final clock = ref.read(clockProvider).now();
    final draft = state;
    final written = await ref
        .read(vehicleRepositoryProvider)
        .create(
          VehicleDraft(
            name: draft.displayName,
            vehicleType: draft.type,
            fuelKindDefault: draft.fuel,
            odometer: Distance(draft.odometerMetres!),
            odometerUnit: draft.unit,
            occurredOn: _today(clock),
            isBusiness: draft.type == VehicleType.van,
            expectedAnnual: Distance(draft.band.metresFor(draft.unit)),
            // Not asked, and F-9.15 says why: SPEC.md §4.8.3 seeds `coolant`
            // only on a liquid-cooled motorcycle, Odova stores no cooling
            // field, and the artboard has no control for it. A MISSING reminder
            // is covered by §4.8's own header — "your handbook wins, edit
            // anything here" — while a coolant reminder on an air-cooled bike
            // teaches the user the app makes things up.
          ),
          nowUtcMs: clock.millisecondsSinceEpoch,
          // SPEC.md §8's fourth Data-out line, in the same transaction:
          // `UPDATE Settings { active_vehicle_id, onboarding_done: true }`.
          // This screen is the only place onboarding finishes — `settings
          // .language`'s Continue deliberately leaves the flag false so a kill
          // between the two steps replays from the language step rather than
          // opening an app with no car.
          asFirstVehicle: true,
        );

    final ok = written is Ok;
    state = state.copyWith(saving: false, saveFailed: !ok);
    return ok;
  }

  /// `YYYY-MM-DD`, in the device's own day.
  ///
  /// Through `CivilDate`, which owns the format. A clock with no four-digit
  /// year falls back to the epoch's date rather than writing a reading the
  /// database cannot store — the odometer is required and losing it would leave
  /// a vehicle the domain contract forbids.
  static String _today(DateTime now) =>
      (CivilDate.fromDateTime(now) ?? CivilDate.fromDateTime(DateTime(1970))!)
          .toString();
}

/// The first-run vehicle draft.
final firstRunVehicleProvider =
    NotifierProvider<FirstRunVehicleNotifier, FirstRunVehicleDraft>(
      FirstRunVehicleNotifier.new,
    );
