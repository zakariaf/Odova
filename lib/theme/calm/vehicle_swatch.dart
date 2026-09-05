// The eight vehicle paints, and the one swatch that is not a paint.
//
// SPEC.md §8's colour row, copied from `design/calm/screens.html`'s inline
// `style="background:…"`. Nothing here was chosen by an engineer — the same
// rule `CalmPalette` states at the top of itself, for the same reason.
//
// **Not in `CalmColors`, and not a token.** A `ThemeExtension` is a thing with
// two values, and these have one: a silver car is silver at night. They are
// facts about paint rather than about the interface, so they live beside the
// palette rather than inside it, and `check_raw_values.sh` is satisfied because
// this is `lib/theme/calm/`.
import 'package:flutter/painting.dart' show Color;
import 'package:odova/core/vehicles/vehicle_colour.dart';

/// The paint for [colour], or null when it has none.
///
/// Null is [VehicleColour.other], which EPIC-09 F-9.18 keeps as an OUTLINED
/// swatch with no fill: the design supplied eight colours, and a ninth chosen
/// to sit beside eight hand-tuned ones is design work rather than engineering.
/// The caller draws the outline; this function does not invent a colour to
/// avoid returning null.
Color? calmVehicleSwatch(VehicleColour colour) => switch (colour) {
  VehicleColour.white => const Color(0xFFFFFFFF),
  VehicleColour.silver => const Color(0xFFC9CBCC),
  VehicleColour.grey => const Color(0xFF6E7376),
  VehicleColour.black => const Color(0xFF232323),
  VehicleColour.red => const Color(0xFFA8362C),
  VehicleColour.blue => const Color(0xFF2E5C86),
  VehicleColour.green => const Color(0xFF3F6B4A),
  VehicleColour.yellow => const Color(0xFFD2A63A),
  VehicleColour.other => null,
};

/// The ink that reads on [paint].
///
/// Chosen by the PAINT's own luminance, not by the theme: a silhouette on a
/// white car needs dark ink in both themes and one on a black car needs light
/// ink in both. A `CalmColors` slot would flip with the brightness and put
/// near-black on a black car every night.
///
/// The two values are the ends of Calm's own ink range rather than pure black
/// and white — `#232323` is what the system uses for ink on a light ground and
/// `#FFF9F1` is `on-brand`. They are raw here because `lib/theme/calm/` is the
/// one directory allowed to name a colour, which is exactly the reason this
/// function is here and not in the garage row that used to inline them.
Color calmVehicleSwatchInk(Color paint) => paint.computeLuminance() > 0.5
    ? const Color(0xFF232323)
    : const Color(0xFFFFF9F1);
