// The eight vehicle paints, and the one swatch that is not a paint.
//
// SPEC.md §8's colour row. These are PAINT colours, not theme colours: they do
// not change between light and dark, because a silver car is silver at night.
// That is why they sit beside the palette rather than inside `CalmColors`,
// which is a `ThemeExtension` and therefore a thing with two values.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/vehicles/vehicle_colour.dart';
import 'package:odova/theme/calm/vehicle_swatch.dart';

void main() {
  test('the eight paints are the artboard values, to the digit', () {
    // Copied from `design/calm/screens.html`'s inline `style="background:…"`.
    // Nothing here was chosen by an engineer, which is the same rule
    // `CalmPalette` states at the top of itself.
    expect(calmVehicleSwatch(VehicleColour.white), const Color(0xFFFFFFFF));
    expect(calmVehicleSwatch(VehicleColour.silver), const Color(0xFFC9CBCC));
    expect(calmVehicleSwatch(VehicleColour.grey), const Color(0xFF6E7376));
    expect(calmVehicleSwatch(VehicleColour.black), const Color(0xFF232323));
    expect(calmVehicleSwatch(VehicleColour.red), const Color(0xFFA8362C));
    expect(calmVehicleSwatch(VehicleColour.blue), const Color(0xFF2E5C86));
    expect(calmVehicleSwatch(VehicleColour.green), const Color(0xFF3F6B4A));
    expect(calmVehicleSwatch(VehicleColour.yellow), const Color(0xFFD2A63A));
  });

  test('other is not a paint', () {
    // EPIC-09 F-9.18. An outlined swatch with no fill is the honest drawing of
    // "not one of these"; a colour here would be a ninth paint invented to sit
    // beside eight hand-tuned ones.
    expect(calmVehicleSwatch(VehicleColour.other), isNull);
  });

  test('every colour is answered, so a tenth cannot be forgotten', () {
    // The switch is exhaustive over the enum, so adding a value is a compile
    // error here rather than a swatch that silently draws nothing.
    for (final colour in VehicleColour.values) {
      final paint = calmVehicleSwatch(colour);
      expect(
        paint == null,
        colour == VehicleColour.other,
        reason: '$colour',
      );
    }
  });

  test('a paint is fully opaque, in both themes, because paint is', () {
    // A translucent swatch would take the ground's colour, and the ground has
    // two values. A silver car is silver at night.
    for (final colour in VehicleColour.values) {
      final paint = calmVehicleSwatch(colour);
      if (paint == null) continue;
      expect(paint.a, 1.0, reason: '$colour');
    }
  });
}
